/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);
    
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
  function balanceOf(address _owner) external constant returns (uint256 );
  function transferFrom(address _from, address _to, uint256 _value) external ;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Airdrop is Ownable {
    
    event GasSendFinish(address _sender, uint256 _value);
    
    constructor () public payable {
        emit GasSendFinish(msg.sender, msg.value);
    }

    function transfer(address _token, address[] _dsts, uint256[] _values) public onlyOwner payable {
        require(_dsts.length == _values.length);
        Token token = Token(_token);
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transferFrom(owner, _dsts[i], _values[i]);
        }
    }
    
    function sendGas() public payable {
        emit GasSendFinish(msg.sender, msg.value);
    } 
    
}