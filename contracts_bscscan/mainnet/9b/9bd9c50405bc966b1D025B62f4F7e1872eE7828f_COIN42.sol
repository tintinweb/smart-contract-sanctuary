/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract COIN42 {
    string public constant name = "42";
    string public constant symbol = "42";
    uint8 public constant decimals = 8;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 42e8;

    address private _owner;
    modifier restricted {
        require(msg.sender == _owner, "This function is restricted to owner");
        _;
    }
    modifier issuerOnly {
        require(_isIssuer[msg.sender], "You do not have issuer rights");
        _;
    }
    modifier isNotZeroAddress (address _address) {
        require(_address != address(0), "ERC20: Zero address");
        _;
    }
    modifier isNotZELWIN (address _address) {
        require(_address != address(this), "ERC20: ZELWIN Token address");
        _;
    }

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;
    mapping(address => bool) private _isIssuer;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event IssuerRights(address indexed issuer, bool value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    function getOwner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return _balanceOf[_user];
    }

    function allowance(address _user, address _spender) public view returns (uint256){
        return _allowance[_user][_spender];
    }

    function isIssuer(address _user) public view returns (bool) {
        return _isIssuer[_user];
    }

    function mint(address _to, uint256 _amount) public issuerOnly isNotZeroAddress(_to) isNotZELWIN(_to) returns (bool success) {
        totalSupply += _amount;
        require(totalSupply <= MAX_SUPPLY, "Minting overflows total supply limit");
        _balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public issuerOnly returns (bool success) {
        totalSupply -= _amount;
        _balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount) public issuerOnly returns (bool success) {
        _allowance[_from][msg.sender] -= _amount;
        _balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public isNotZeroAddress(_spender) returns (bool success) {
        _allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public isNotZeroAddress(_to) returns (bool success) {
        _balanceOf[msg.sender] -= _amount;
        _balanceOf[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _amount) public isNotZeroAddress(_to) isNotZELWIN(_to) returns (bool success) {
        _allowance[_from][msg.sender] -= _amount;
        _balanceOf[_from] -= _amount;
        _balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function transferOwnership(address _newOwner) public restricted isNotZeroAddress(_newOwner) {
        emit TransferOwnership(_owner, _newOwner);
        _owner = _newOwner;
    }

    function setIssuerRights(address _issuer, bool _value) public restricted isNotZeroAddress(_issuer) {
        _isIssuer[_issuer] = _value;
        emit IssuerRights(_issuer, _value);
    }

    constructor() {
        _owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }
}