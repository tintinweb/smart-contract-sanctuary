/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract Ownable {
    address public owner;

    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transferOwnership(address _newOwner) public restricted {
        require(_newOwner != address(0), "Invalid address: should not be 0x0");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    constructor() {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
}

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        if (_totalSupply > 0) {
            balanceOf[msg.sender] = _totalSupply;
            emit Transfer(address(0), msg.sender, _totalSupply);
        }
    }
}

contract TokenMintable is Token, Ownable {
    mapping(address => bool) public isIssuer;

    event IssuerRights(address indexed issuer, bool value);

    modifier issuerOnly {
        require(isIssuer[msg.sender], "You do not have issuer rights");
        _;
    }

    function mint(address _to, uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount) public issuerOnly returns (bool success) {
        allowance[_from][msg.sender] -= _amount;
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function setIssuerRights(address _issuer, bool _value) public restricted {
        isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) Token(_name, _symbol, _decimals, _totalSupply) {}
}