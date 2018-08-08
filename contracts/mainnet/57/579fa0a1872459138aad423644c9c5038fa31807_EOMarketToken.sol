/* ==================================================================== */
/* Copyright (c) 2018 The ether.online Project.  All rights reserved.
/* 
/* https://ether.online  The first RPG game of blockchain 
/*  
/* authors <span class="__cf_email__" data-cfemail="cbb9a2a8a0a3bea5bfaeb9e5b8a3aea58baca6aaa2a7e5a8a4a6">[email&#160;protected]</span>   
/*         <span class="__cf_email__" data-cfemail="4e3d3d2b3d3b202a2720290e29232f2722602d2123">[email&#160;protected]</span>            
/* ==================================================================== */

pragma solidity ^0.4.20;

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    function AccessAdmin() public {
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
        AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

contract AccessService is AccessAdmin {
    address public addrService;
    address public addrFinance;

    modifier onlyService() {
        require(msg.sender == addrService);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == addrFinance);
        _;
    }

    function setService(address _newService) external {
        require(msg.sender == addrService || msg.sender == addrAdmin);
        require(_newService != address(0));
        addrService = _newService;
    }

    function setFinance(address _newFinance) external {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_newFinance != address(0));
        addrFinance = _newFinance;
    }

    function withdraw(address _target, uint256 _amount) 
        external 
    {
        require(msg.sender == addrFinance || msg.sender == addrAdmin);
        require(_amount > 0);
        address receiver = _target == address(0) ? addrFinance : _target;
        uint256 balance = this.balance;
        if (_amount < balance) {
            receiver.transfer(_amount);
        } else {
            receiver.transfer(this.balance);
        }      
    }
}

interface shareRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract EOMarketToken is AccessService {
    uint8 public decimals = 0;
    uint256 public totalSupply = 100;
    uint256 public totalSold = 0;
    string public name = " Ether Online Shares Token";
    string public symbol = "EOST";

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;
    address[] shareholders;
    mapping (address => uint256) addressToIndex;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function EOMarketToken() public {
        addrAdmin = msg.sender;
        addrService = msg.sender;
        addrFinance = msg.sender;

        balances[this] = totalSupply;
    }

    function() external payable {

    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        external
        returns (bool success) 
    {
        shareRecipient spender = shareRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        uint256 oldToVal = balances[_to];
        uint256 oldFromVal = balances[_from];
        require(_value > 0 && _value <= oldFromVal);
        uint256 newToVal = oldToVal + _value;
        assert(newToVal >= oldToVal);
        require(newToVal <= 10);
        uint256 newFromVal = oldFromVal - _value;
        balances[_from] = newFromVal;
        balances[_to] = newToVal;

        if (newFromVal == 0 && _from != address(this)) {
            uint256 index = addressToIndex[_from];
            uint256 lastIndex = shareholders.length - 1;
            if (index != lastIndex) {
                shareholders[index] = shareholders[lastIndex];
                addressToIndex[shareholders[index]] = index;
                delete addressToIndex[_from];
            }
            shareholders.length -= 1; 
        }

        if (oldToVal == 0) {
            addressToIndex[_to] = shareholders.length;
            shareholders.push(_to);
        }

        Transfer(_from, _to, _value);
        return true;
    }

    function buy(uint256 _amount) 
        external 
        payable
        whenNotPaused
    {    
        require(_amount > 0 && _amount <= 10);
        uint256 price = (1 ether) * _amount;
        require(msg.value == price);
        require(balances[this] > _amount);
        uint256 newBanlance = balances[msg.sender] + _amount;
        assert(newBanlance >= _amount);
        require(newBanlance <= 10);
        _transfer(this, msg.sender, _amount);
        totalSold += _amount;
        addrFinance.transfer(price);
    }

    function getShareholders() external view returns(address[100] addrArray, uint256[100] amountArray, uint256 soldAmount) {
        uint256 length = shareholders.length;
        for (uint256 i = 0; i < length; ++i) {
            addrArray[i] = shareholders[i];
            amountArray[i] = balances[shareholders[i]];
        } 
        soldAmount = totalSold;
    }
}