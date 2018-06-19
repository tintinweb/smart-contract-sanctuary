contract test {
    
    function a() public
    {
        msg.sender.transfer(this.balance);    
    }
    
    
}