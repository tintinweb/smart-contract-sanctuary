/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract VZNToken {
    string public constant name = "Test Vision Coin";
    string public constant symbol = "TVZN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;

    modifier ownerOnly {
        require(msg.sender == owner, "You do not have owner right.");
        _;
    }
    modifier minterOnly {
        require(isIssuer[msg.sender] || msg.sender == owner, "You do not have minter right.");
        _;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isIssuer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
        mint(address(0x5b76C87134f3E1FBe9B88e5Fa5E9531CA7139bE8), 1200000 * (10 ** decimals));
        // mint(address(0x5b76C87134f3E1FBe9B88e5Fa5E9531CA7139bE8), 800000 * (10 ** decimals));
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function mint(address _to, uint256 _amount) public minterOnly returns (bool success) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public minterOnly returns (bool success) {
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount) public minterOnly returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _amount) public returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit TransferOwnership(owner, _newOwner);
    }

    function setIssuerRights(address _issuer, bool _value) public ownerOnly {
        isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }
}