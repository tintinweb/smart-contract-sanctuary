pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract BetCaller is Owned {
    address public caller_contranct_address;
    
    function setContractAddress(address _contract_address) public onlyOwner{
        caller_contranct_address = _contract_address;
    }
    
    function BetSetAnswer( uint256 _answer) public{
        require(caller_contranct_address!=0x0);
        caller_contranct_address.call(bytes4(keccak256("setAnswer(uint256)")),_answer);
    }
    
    function transfer(address _to, uint256 _value) public payable onlyOwner{
        _to.transfer(_value);
    }
  
}