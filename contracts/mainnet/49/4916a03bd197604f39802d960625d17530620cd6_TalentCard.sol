/* ==================================================================== */
/* Copyright (c) 2018 The TokenTycoon Project.  All rights reserved.
/* 
/* https://tokentycoon.io
/*  
/* authors <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dcaeb5bfb7b4a9b2a8b9aef2afb4b9b29cbbb1bdb5b0f2bfb3b1">[email&#160;protected]</a>   
/*         <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0a79796f797f646e63646d4a6d676b636624696567">[email&#160;protected]</a>            
/* ==================================================================== */

pragma solidity ^0.4.23;

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract TalentCard is AccessAdmin {
    uint8 public decimals = 0;
    uint256 public totalSupply = 1000000000;
    string public name = "Token Tycoon Talent Card";
    string public symbol = "TTTC";

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;
    /// @dev Trust contract
    mapping (address => bool) safeContracts;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
        addrAdmin = msg.sender;

        balances[this] = totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);     
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        uint256 oldFromVal = balances[_from];
        require(_value > 0 && oldFromVal >= _value);
        uint256 oldToVal = balances[_to];
        uint256 newToVal = oldToVal + _value;
        require(newToVal > oldToVal);
        uint256 newFromVal = oldFromVal - _value;
        balances[_from] = newFromVal;
        balances[_to] = newToVal;

        assert((oldFromVal + oldToVal) == (newFromVal + newToVal));
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        external
        returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function setSafeContract(address _actionAddr, bool _useful) external onlyAdmin {
        safeContracts[_actionAddr] = _useful;
    }

    function getSafeContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return safeContracts[_actionAddr];
    }

    function safeSendCard(uint256 _amount, address _to) external {
        require(safeContracts[msg.sender]);
        require(balances[address(this)] >= _amount);
        require(_to != address(0));

        _transfer(address(this), _to, _amount);
    }
}