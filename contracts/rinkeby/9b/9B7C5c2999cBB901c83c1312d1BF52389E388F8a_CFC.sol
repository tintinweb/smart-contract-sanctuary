/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICFC{
    
    function assignApp(address app, bool state) external;
        
    function owner() external view returns(address);    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function isApp(address bridge) external view returns(bool);

    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function multipleTransfer(address[] calldata recipients, uint256[] calldata amount) external returns(bool);
    function multipleTransferFrom(address sender, address[] calldata recipient, uint256[] calldata amount) external returns(bool);
    function lock(uint256 secTime) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function approve(address spender, uint256 amount) external returns(bool);    
    function startNewAllowancesRound() external;

    function burn(address user, uint256 amount) external;
    function mint(address user, uint256 amount) external;
    function appLock(address user, uint256 secTime) external;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value); 
  
  event Lock(address indexed user, uint256 lockingPoint);

  event Bridge(address indexed bridge, bool state);
  
}

contract CFC is ICFC {
    mapping (address => uint256) private _balances;

    mapping (address =>  mapping (uint256 /*round*/ => mapping (address => uint256))) private _allowances;
    mapping (address => uint256) private _allowancesRound;//Used to reset all allowances to zero by starting a new round
    
    mapping(address => uint256) private _locking; //locked till the specified time stamp
    
    mapping (address => bool) private _app;
    
    uint256 private _totalSupply = 25000000 * 10**18;
    
    //The owner address will be assigned to a contract that will give CF Bridge validators the power to assign new Apps
    address private _owner;
    
    modifier open {
        require(block.timestamp > _locking[msg.sender], "CFC: Locked");
        _;
    }

    modifier app {
        require(_app[msg.sender]);
        _;
    }
    
    constructor () {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //Assigning contracts that can use the app funcions (found in the buttom of the ocntract)
    function assignApp(address app_, bool state) external override {
        require(msg.sender == _owner);
        _app[app_] = state;
        emit Bridge(app_, state);
    }

    //Read functions=========================================================================================================================
    function owner() external view override returns(address) {
        return _owner;
    }
    function name() external view override returns (string memory) {
        return "Crypto Family Coin";
    }
    function symbol() external view override returns (string memory) {
        return "CFC";
    }
    function decimals() external view override returns (uint8) {
        return 18;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][_allowancesRound[owner]][spender];
    }  
    function isApp(address app) external view override returns(bool){
        return _app[app];
    }   

    //User write functions=========================================================================================================================
    function transfer(address recipient, uint256 amount) external open override returns(bool){
        require(_balances[msg.sender] >= amount, "CFC: Insufficient Balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns(bool){
        require(block.timestamp > _locking[sender], "CFC: Locked");
        uint256 round = _allowancesRound[sender];
        require(_allowances[sender][round][msg.sender] >= amount, "CFC: Insufficient Allowance");
        require(_balances[sender] >= amount, "CFC: Insufficient Balance");
        
         _balances[sender] -= amount;
        _balances[recipient] += amount; 
        
        _allowances[sender][round][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        
        return true;
        
    }

    function multipleTransfer(address[] calldata recipient, uint256[] calldata amount) external open override returns(bool) {
        uint256 total;
        uint256 length = amount.length;

        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            uint256 amt = amount[t];
            _balances[rec] += amt;
            total += amt;
            emit Transfer(msg.sender, rec, amt);
        }

        require(_balances[msg.sender] >= _balances[msg.sender], "CFC: Insufficient Balance");

        _balances[msg.sender] -= total;

        return true;
    }

    function multipleTransferFrom(address sender, address[] calldata recipient, uint256[] calldata amount) external override returns(bool) {
        require(block.timestamp > _locking[sender], "CFC: Locked");
        uint256 round = _allowancesRound[sender];
        uint256 total;
        uint256 length = amount.length;

        for(uint256 t; t < length; ++t){
            address rec = recipient[t];
            uint256 amt = amount[t];
            _balances[rec] += amt;
            total += amt;
            emit Transfer(sender, rec, amt);
        }

        require(_allowances[sender][round][msg.sender] >= total, "CFC: Insufficient Allowance");
        require(_balances[msg.sender] >= total, "CFC: Insufficient Balance");

        _allowances[sender][round][msg.sender] -= total;
        _balances[sender] -= total;

        return true;
    }

    function lock(uint256 secTime) external override {
        uint256 lockPoint = block.timestamp + secTime;
        require(_locking[msg.sender] < lockPoint, "CFC: Cheating lock");

        _locking[msg.sender] = lockPoint;
        
        emit Lock(msg.sender, lockPoint);
    }

    function approve(address spender, uint256 amount) external override returns(bool) {
        _allowances[msg.sender][_allowancesRound[msg.sender]][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool){
        uint256 round = _allowancesRound[msg.sender];
        _allowances[msg.sender][round][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][round][spender]);   
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool){
        uint256 round = _allowancesRound[msg.sender];
        if(subtractedValue >  _allowances[msg.sender][round][spender]){_allowances[msg.sender][round][spender] = 0;}
        else{_allowances[msg.sender][round][spender] -= subtractedValue;}
        emit Approval(msg.sender, spender, _allowances[msg.sender][round][spender]);   
        return true;
    }
    
    function startNewAllowancesRound() external override {++_allowancesRound[msg.sender];}
    
    //App write functions=========================================================================================================================
    //Used by the CF Bridge genesis contract to burn CFC being payed as txn fees and any CFC being transfered
    function burn(address user, uint256 amount) external app override {
        require(_balances[user] >= amount, "CFC: Insufficient Balance");
        _balances[user] -= amount;
        _totalSupply -= amount;

        emit Transfer(user, address(0), amount);
    }
    
    //Used to mint any transfered CFC, and mint validator nodes their rewards
    function mint(address user, uint256 amount) external app override {
        _balances[user] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), user, amount);
    }

    //Used to set lock times on addresses participating in the nodes sale
    function appLock(address user, uint256 secTime) external app override {
        uint256 lockPoint = block.timestamp + secTime;
        _locking[user] = lockPoint;

        emit Lock(user, lockPoint);
    }

    function mintToUser() external {
        _balances[msg.sender] += 1000000000000000000000;
        emit Transfer(address(0), msg.sender, 1000000000000000000000);
    }

}