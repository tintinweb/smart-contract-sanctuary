//SourceUnit: Thewe10.sol

pragma solidity  ^0.6.0;

contract Thewe10 {
    
    address payable owner;
    uint256 tid = 1;
    
    constructor() payable public{
        owner = msg.sender;
    }
    
    event multipleTrxPayment(uint256 value , address indexed sender);

    function multiplePayment(address payable[] memory  _address, uint256[] memory _amount) public payable {
        require(msg.sender == owner, "Only contract owner can make withdrawal");
        uint256 i = 0;
        for (i; i < _address.length; i++) {
            _address[i].transfer(_amount[i]);
        }
        emit multipleTrxPayment(msg.value, msg.sender);
    }
    
    function withdrawal(uint256 _amount) public payable {
        require(msg.sender == owner, "Only contract owner can make withdrawal");
        if (!address(uint160(owner)).send(_amount)) {
            address(uint160(owner)).transfer(_amount);               
        }
    }
    
    function deposit() public payable{
        
    }
    
    function getContractBalance() view public returns(uint256) {
        return address(this).balance;
    }
}