"""Handlers for `components/GuestbookPanel.cl.jac`."""

impl GuestbookPanel.loadMessages -> None {
    result = root spawn ListMessages();
    messages = result.reports;
}

impl GuestbookPanel.postMessage -> None {
    if not author.strip() or not text.strip() {
        return;
    }
    result = root spawn PostMessage(author=author, text=text);
    messages = messages + [result.reports[0]];
    text = "";
}
