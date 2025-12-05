import os

import graphene
from django.core.exceptions import ValidationError

from .....account.error_codes import AccountErrorCode
from .....account.throttling import authenticate_with_throttling
from .....core.jwt import create_access_token, create_refresh_token
from ....core import ResolveInfo
from ....core.doc_category import DOC_CATEGORY_AUTH
from ....core.mutations import BaseMutation
from ....core.types import AccountError
from ....site.dataloaders import get_site_promise
from ...types import User
from .utils import _get_new_csrf_token, update_user_last_login_if_required


def is_sso_only_enabled() -> bool:
    """Check if SSO-only mode is enabled via environment variable."""
    return os.environ.get("SSO_ONLY_ENABLED", "").lower() in ("true", "1", "yes")


class CreateToken(BaseMutation):
    """Mutation that authenticates a user and returns token and user data."""

    class Arguments:
        email = graphene.String(required=True, description="Email of a user.")
        password = graphene.String(required=True, description="Password of a user.")
        audience = graphene.String(
            required=False,
            description=(
                "The audience that will be included to JWT tokens with "
                "prefix `custom:`."
            ),
        )

    class Meta:
        description = "Create JWT token."
        doc_category = DOC_CATEGORY_AUTH
        error_type_class = AccountError
        error_type_field = "account_errors"

    token = graphene.String(description="JWT token, required to authenticate.")
    refresh_token = graphene.String(
        description="JWT refresh token, required to re-generate access token."
    )
    csrf_token = graphene.String(
        description="CSRF token required to re-generate access token."
    )
    user = graphene.Field(User, description="A user instance.")

    @classmethod
    def get_user(cls, info: ResolveInfo, email, password):
        user = authenticate_with_throttling(info.context, email, password)
        if not user:
            raise ValidationError(
                {
                    "email": ValidationError(
                        "Please, enter valid credentials",
                        code=AccountErrorCode.INVALID_CREDENTIALS.value,
                    )
                }
            )

        site_settings = get_site_promise(info.context).get().settings
        if (
            not user.is_confirmed
            and not site_settings.allow_login_without_confirmation
            and site_settings.enable_account_confirmation_by_email
        ):
            raise ValidationError(
                {
                    "email": ValidationError(
                        "Account needs to be confirmed via email.",
                        code=AccountErrorCode.ACCOUNT_NOT_CONFIRMED.value,
                    )
                }
            )

        if not user.is_active:
            raise ValidationError(
                {
                    "email": ValidationError(
                        "Account inactive.",
                        code=AccountErrorCode.INACTIVE.value,
                    )
                }
            )
        return user

    @classmethod
    def perform_mutation(  # type: ignore[override]
        cls, _root, info: ResolveInfo, /, *, audience=None, email, password
    ):
        # Block password-based authentication when SSO-only mode is enabled
        if is_sso_only_enabled():
            raise ValidationError(
                {
                    "email": ValidationError(
                        "Password authentication is disabled. Please use SSO to login.",
                        code=AccountErrorCode.INVALID_CREDENTIALS.value,
                    )
                }
            )

        additional_paylod = {}

        csrf_token = _get_new_csrf_token()
        refresh_additional_payload = {
            "csrfToken": csrf_token,
        }
        if audience:
            additional_paylod["aud"] = f"custom:{audience}"
            refresh_additional_payload["aud"] = f"custom:{audience}"

        user = cls.get_user(info, email, password)
        access_token = create_access_token(user, additional_payload=additional_paylod)
        refresh_token = create_refresh_token(
            user, additional_payload=refresh_additional_payload
        )
        setattr(info.context, "refresh_token", refresh_token)
        info.context.user = user
        info.context._cached_user = user
        update_user_last_login_if_required(user)
        return cls(
            errors=[],
            user=user,
            token=access_token,
            refresh_token=refresh_token,
            csrf_token=csrf_token,
        )
