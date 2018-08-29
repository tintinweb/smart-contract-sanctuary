pragma solidity ^0.4.24;

contract MultiEthSender {
    
    event Send(uint256 _amount, address indexed _receiver);
    
    constructor() payable public {
        
    }
    
    function multiSendEth(uint256 amount, address[] list) public payable returns (bool) {
        uint balanceBeforeTransfer = address(this).balance;
        
        for(uint i=0;i<list.length;i++){
            list[i].transfer(amount);
            emit Send(amount, list[i]);
        }
        assert(address(this).balance == balanceBeforeTransfer - amount*list.length);
        return true;
    }
    
    function getBalance() constant public returns(uint){
        return address(this).balance;
    }
    
    function() public payable{
        
    }
    
}