/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.16;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract LCPToken {
    using SafeMath for uint;

    string public name = "Last Coast Serson";      //  token name
    string public symbol = "LCS";           //  token symbol
    uint256 public decimals = 6;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 0;
    bool public stopped = false;

    uint256 constant valueFounder = 100000000000;//初始发行量 100000
    address public owner = address(0);
    address public handeler = address(0);
    address public receiver = address(0);

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4),"LCP:Size to long");
        _;
    }

    modifier isOwner {
        require(owner == msg.sender,"LCP:You are not owner");
        _;
    }

    modifier isHandeler {
        require(handeler == msg.sender,"LCP:You are not handeler");
        _;
    }

    modifier isRunning {
        require (!stopped,"LCP:This project is pause");
        _;
    }

    modifier validAddress {
        require(address(0) != msg.sender,"LCP:The address is not valid");
        _;
    }

    constructor(address _addressReceiver,address _addressHandeler) public{
        owner = msg.sender;
        receiver = _addressReceiver;
        handeler = _addressHandeler;
        totalSupply = valueFounder;
        balanceOf[_addressReceiver] = valueFounder;
        emit Transfer(address(0), _addressReceiver, valueFounder);
    }

    function transfer(address _to, uint256 _value) public isRunning validAddress onlyPayloadSize(2 * 32) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isRunning validAddress onlyPayloadSize(3 * 32) returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public isRunning validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function stop() isOwner public {
        stopped = true;
    }

    function start() isOwner public {
        stopped = false;
    }

    function setReceiverAddress(address _addressReceiver) external isOwner {
        receiver = _addressReceiver;
    }

    function setHandelerAddress(address _addressHandeler) external isOwner {
        handeler = _addressHandeler;
    }
    
    
    function mint(uint value) external isHandeler {
        totalSupply = totalSupply.add(value);
        balanceOf[receiver] = balanceOf[receiver].add(value);
        emit Transfer(address(0), receiver, value);
    }


    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[address(0)] += _value;
        emit Burn(msg.sender, _value);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
}