pragma solidity ^0.4.24;

contract Wallet {
    
    mapping (address => uint256) public tokenBalance; //mapping of token address
    mapping (address => uint256) public myEthBalance; // profit ethereum balance
    address[] public msg_sender;
    address[] public tokenmsg_sender;
    address public contract_address;
    
    constructor() public {
        
    }
    
    function () payable public {
        
    }
    
    function setMyEthBalance(address _user, uint256 _amount) public {
       msg_sender.push(msg.sender);
       myEthBalance[_user] = _amount;
    }
    
    function setMyTokenBalance(address _user, uint256 _amount) public {
      tokenmsg_sender.push(msg.sender);
      tokenBalance[_user] = _amount;
    }
    
    function setContractAddress(address _addr) public {
        contract_address = _addr;    
    }
    
    function getMsgSender() public view returns(address[]) {
        return msg_sender;
    }
    
    function getMytokenBalance(address _user) public view returns(uint256) {
        return tokenBalance[_user];
    }
    
    function getMyEthBalance(address _user) public view returns(uint256) {
        return myEthBalance[_user];
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}