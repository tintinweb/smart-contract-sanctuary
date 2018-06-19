contract TakeMyEther {
    function() {
        selfdestruct(msg.sender);
    }
}