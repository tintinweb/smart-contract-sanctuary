contract coba{
    function withdraw(){
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        msg.sender.transfer(etherBalance);
    }
}