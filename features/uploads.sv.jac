"""File uploads: multipart UploadFile fields, auth and pub variants.

Bodies in `features/impl/uploads.impl.jac`. The `fastapi` import stays on the
decl: `UploadFile` is part of the field signature the router reads."""

import from fastapi { UploadFile }

walker UploadDoc {
    has document: UploadFile;
    has notes: str = "";

    can go with Root entry;
}

walker:pub UploadPublic {
    has attachment: UploadFile;

    can go with Root entry;
}
