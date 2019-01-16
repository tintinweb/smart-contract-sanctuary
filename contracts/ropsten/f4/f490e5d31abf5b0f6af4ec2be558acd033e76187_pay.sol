contract pay {
    mapping(address => uint256) public amnt;
    
    function getEther() payable public{
        amnt[msg.sender] +=  msg.value;
    }
    
    function getBack() public {
        uint256 val = amnt[msg.sender];
        require(val > 0);
        msg.sender.transfer(val);    
    }
    
}