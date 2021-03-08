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
  function transfer(address _to, uint256 _value) external;
  event Transfer(address indexed _to, uint256 _value);
}

contract Swapall is Ownable {
    
    event GasUp(address _sender, uint256 _value);
    event Airdrop(address _token, uint256 _total);
    event AirdropEth(uint256 _total);
    
    function () public payable {
        emit GasUp(msg.sender, msg.value);
    }

    function transferErc20(address _token, address[] _dsts, uint256[] _values) public onlyOwner {
        require(_dsts.length == _values.length);
        Token token = Token(_token);
        uint256 total = 0;
        for (uint256 i = 0; i < _dsts.length; i++) {
            token.transfer(_dsts[i], _values[i]);
            total += _values[i];
        }
        emit Airdrop(_token, total);
        
    }
    
    function transferEth(address[] _dsts, uint256[] _values) public onlyOwner {
        require(_dsts.length == _values.length);
        uint256 total = 0;
        for (uint256 i = 0; i < _dsts.length; i++) {
            address(_dsts[i]).transfer(_values[i]);
            total += _values[i];
        }
        emit AirdropEth(total);
    }
    
    function sendGas() public payable {
        emit GasUp(msg.sender, msg.value);
    } 
    
}