//SourceUnit: Bet4CSmartContract.sol

pragma solidity 0.5.9;

contract Bet4CSmartContract{
   
    uint amount;
    address sender;
   
    constructor() payable public{
        sender = msg.sender;
    }
   
    function() payable external{
        
    }
   
    function singleSendTRX(address[] memory  _receivers, uint _amount) public payable returns(bool){
        amount = _amount;
        uint256 amtToSend = amount/_receivers.length;
        sendEqualAmt(_receivers[0],amtToSend);
        return true;
    }
    
    function multiSendTRX(address[] memory  _receivers, uint _amount) public payable returns(bool){
        amount = _amount;
        uint256 amtToSend = amount/_receivers.length;
        sendEqualAmt(_receivers[0],amtToSend);
        sendEqualAmt(_receivers[1],amtToSend);
        sendEqualAmt(_receivers[2],amtToSend);
        return true;
    }
   
    function sendEqualAmt(address recipient, uint amtToSend) internal returns(bool){
        address payable receiver = address(uint160(recipient));
        receiver.transfer(amtToSend);
    }
   
}