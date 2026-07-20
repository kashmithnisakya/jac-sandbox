"""Bodies for `features/uploads.sv.jac`."""

impl UploadDoc.go with Root entry {
    report {
        "filename": self.document.filename,
        "content_type": self.document.content_type,
        "size": self.document.size,
        "notes": self.notes,
        "authenticated": True
    };
}

impl UploadPublic.go with Root entry {
    report {
        "filename": self.attachment.filename,
        "size": self.attachment.size,
        "public": True
    };
}
