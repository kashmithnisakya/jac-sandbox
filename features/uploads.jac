"""File uploads: multipart UploadFile fields, auth and pub variants."""

import from fastapi { UploadFile }

walker UploadDoc {
    has document: UploadFile;
    has notes: str = "";

    can go with Root entry {
        report {
            "filename": self.document.filename,
            "content_type": self.document.content_type,
            "size": self.document.size,
            "notes": self.notes,
            "authenticated": True
        };
    }
}

walker:pub UploadPublic {
    has attachment: UploadFile;

    can go with Root entry {
        report {
            "filename": self.attachment.filename,
            "size": self.attachment.size,
            "public": True
        };
    }
}
