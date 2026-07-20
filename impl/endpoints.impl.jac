"""Bodies for `endpoints.sv.jac`.

Root-level shared impl folder: `impl/<module>.impl.jac` resolves against the
`<module>.sv.jac` head the same way `features/impl/` does for the features."""

impl PostMessage.post with Root entry {
    report here ++> Message(author=self.author, text=self.text);
}

impl ListMessages.collect with Root entry {
    visit [-->];
}

impl ListMessages.gather with Message entry {
    report here;
}
