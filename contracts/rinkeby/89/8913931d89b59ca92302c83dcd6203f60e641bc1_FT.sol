/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.8.0;

interface IFT{
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function currentSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function allowances(address owner, address spender) external view returns (uint256 allowanceAmount, bool stakingAllowence, bool fullAllowence);
    
    function stakingStats(address user) external view returns (uint256 stakingAmount, uint256 stakingBlock, uint256 rewards);
    function stakeFT(uint256 amount) external returns(bool);
    function stakeFTfor(address user, uint256 amount) external returns(bool);
    function unstakeFT(uint256 amount) external returns(bool);
    function unstakeFTfor(address user, uint256 amount) external returns(bool);
    function unstakeAll() external ;
    function unstakeAllfor(address user) external returns(bool);
    function refreshStaking() external ;
    function refreshStakingFor(address user) external returns(bool);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function doubleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2) external returns(bool);
    function tripleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3) external returns(bool); 
    function quadrupleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4) external returns(bool);
    function quintupleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4, address recipient5, uint256 amount5) external returns(bool);     
    function decupleTransfer(uint256 amount, address recipient1, address recipient2, address recipient3, address recipient4, address recipient5, address recipient6, address recipient7, address recipient8, address recipient9, address recipient10) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function quintupleTransferFrom(address sender, address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4, address recipient5, uint256 amount5) external returns(bool);   

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);    
    function giveStakingAllowance(address user) external ;
    function removeStakingAllowance(address user) external;
    function giveFullAllowance(address user) external ;
    function removeFullAllowance(address user) external;
      
  function burn(uint256 amount) external returns(bool); 
  
  function burnFor(address user, uint256 amount) external returns(bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value); 
  
  event Stake(address indexed staker, uint256 amount);
  
  event Unstake(address indexed unstaker, uint256 unstakingamount);
  
}

contract FT is IFT{
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => bool)) private _stakingAllowances;
    mapping (address => mapping (address => bool)) private _fullAllowances;
    
    mapping (address => uint256) private _stakingAmount;
    mapping (address => uint256) private _stakingBlock;
    
    uint256 private _totalSupply = 10000000000000000;
    uint256 private _currentSupply = 250000000000000;

    constructor () {
        _balances[msg.sender] = _currentSupply;
    }
    function name() external view override returns (string memory) {
        return "Family Token";
    }
    function symbol() external view override returns (string memory) {
        return "FT";
    }
    function decimals() external view override returns (uint8) {
        return 10;
    }
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    function currentSupply() external view override returns (uint256) {
        return _currentSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }    
    function allowances(address owner, address spender) external view override returns (uint256 allowanceAmount, bool stakingAllowence, bool fullAllowence) {
        allowanceAmount = _allowances[owner][spender];
        stakingAllowence = _stakingAllowances[owner][spender];
        fullAllowence = _fullAllowances[owner][spender];
    }        
    function stakingStats(address user) external view override returns (uint256 stakingAmount, uint256 stakingBlock, uint256 rewards){
        stakingAmount = _stakingAmount[user];
        stakingBlock = _stakingBlock[user];
        rewards = _stakingAmount[user] * (block.number - _stakingBlock[user]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}
    }
    
    function stakeFT(uint256 amount) external override returns(bool){
        uint256 rewards = _stakingAmount[msg.sender] * (block.number - _stakingBlock[msg.sender]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}      
        _balances[msg.sender] -= amount;
        _stakingAmount[msg.sender] += amount + rewards;
        _stakingBlock[msg.sender] = block.number;
        
        emit Stake(msg.sender, amount + rewards);
        return true;   
    }
    function stakeFTfor(address user, uint256 amount) external override returns(bool){
        require(_stakingAllowances[user][msg.sender] || _fullAllowances[user][msg.sender]);
        uint256 rewards = _stakingAmount[user] * (block.number - _stakingBlock[user]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}     
        _balances[user] -= amount;
        _stakingAmount[user] += amount + rewards;
        _stakingBlock[user] = block.number;
        
        emit Stake(user, amount + rewards);
        return true;   
    }
    function unstakeFT(uint256 amount) external override returns(bool){
        uint256 rewards = _stakingAmount[msg.sender] * (block.number - _stakingBlock[msg.sender]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}      
        //require(amount <= rewards + _stakingAmount[msg.sender]);
        
        _stakingAmount[msg.sender] = _stakingAmount[msg.sender] + rewards - amount;
        _balances[msg.sender] += amount;
        _stakingBlock[msg.sender] = block.number;
        
        if(rewards > 0){emit Stake(msg.sender, rewards);}
        emit Unstake(msg.sender, amount);        
        return true;
    }
    function unstakeFTfor(address user, uint256 amount) external override returns(bool){
        require(_stakingAllowances[user][msg.sender] || _fullAllowances[user][msg.sender]);
        uint256 rewards = _stakingAmount[user] * (block.number - _stakingBlock[user]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}      
        //require(amount <= rewards + _stakingAmount[user]);
        
        _stakingAmount[user] = _stakingAmount[user] + rewards - amount;
        _balances[user] += amount;
        _stakingBlock[user] = block.number;
        
        if(rewards > 0){emit Stake(user, rewards);}
        emit Unstake(user, amount);        
        
        return true;
    }
    function unstakeAll() external override {
        uint256 rewards = _stakingAmount[msg.sender] * (block.number - _stakingBlock[msg.sender]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}        
        
        emit Unstake(msg.sender, _stakingAmount[msg.sender] + rewards);
        
        _balances[msg.sender] += _stakingAmount[msg.sender] + rewards;
        _stakingAmount[msg.sender] = 0;        
    }
    function unstakeAllfor(address user) external override returns(bool){
        require(_stakingAllowances[user][msg.sender] || _fullAllowances[user][msg.sender]);        
        uint256 rewards = _stakingAmount[user] * (block.number - _stakingBlock[user]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}
        
        emit Unstake(user, _stakingAmount[user] + rewards);   
        
        _balances[user] += _stakingAmount[user] + rewards;
        _stakingAmount[user] = 0; 
        return true; 
    }
    function refreshStaking() external override {
        uint256 rewards = _stakingAmount[msg.sender] * (block.number - _stakingBlock[msg.sender]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}        
        
        _stakingAmount[msg.sender] += rewards;
        _stakingBlock[msg.sender] = block.number;
        
        emit Stake(msg.sender, rewards);
    }
    function refreshStakingFor(address user) external override returns(bool){
        require(_stakingAllowances[user][msg.sender] || _fullAllowances[user][msg.sender]);        
        uint256 rewards = _stakingAmount[user] * (block.number - _stakingBlock[user]) * 4 / 1000000000;
        if(_currentSupply + rewards > _totalSupply){rewards = _totalSupply - _currentSupply;}        
        
        _stakingAmount[user] += rewards;
        _stakingBlock[user] = block.number;
        
        emit Stake(user, rewards);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    function doubleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2) external override returns(bool){
        uint256 total = amount1 + amount2;
        _balances[msg.sender] -= total;
        
        _balances[recipient1] += amount1;
        _balances[recipient2] += amount2;
        
        emit Transfer(msg.sender, recipient1, amount1);
        emit Transfer(msg.sender, recipient2, amount2);   
        
        return true;
    }
    function tripleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3) external override returns(bool){
        uint256 total = amount1 + amount2 + amount3;
        _balances[msg.sender] -= total;
        
        _balances[recipient1] += amount1;
        _balances[recipient2] += amount2;
        _balances[recipient3] += amount3;
        
        emit Transfer(msg.sender, recipient1, amount1);
        emit Transfer(msg.sender, recipient2, amount2);  
        emit Transfer(msg.sender, recipient3, amount3);
        return true;
    }
    function quadrupleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4) external override returns(bool){
        uint256 total = amount1 + amount2 + amount3 + amount4;
        _balances[msg.sender] -= total;
        
        _balances[recipient1] += amount1;
        _balances[recipient2] += amount2;
        _balances[recipient3] += amount3;
        _balances[recipient4] += amount4;
        
        emit Transfer(msg.sender, recipient1, amount1);
        emit Transfer(msg.sender, recipient2, amount2);  
        emit Transfer(msg.sender, recipient3, amount3);  
        emit Transfer(msg.sender, recipient4, amount4);          
        return true;
    }
    function quintupleTransfer(address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4, address recipient5, uint256 amount5) external override returns(bool){
        uint256 total = amount1 + amount2 + amount3 + amount4 + amount5;
        _balances[msg.sender] -= total;
        
        _balances[recipient1] += amount1;
        _balances[recipient2] += amount2;
        _balances[recipient3] += amount3;
        _balances[recipient4] += amount4;
        _balances[recipient5] += amount5;   

        emit Transfer(msg.sender, recipient1, amount1);
        emit Transfer(msg.sender, recipient2, amount2);  
        emit Transfer(msg.sender, recipient3, amount3);  
        emit Transfer(msg.sender, recipient4, amount4);  
        emit Transfer(msg.sender, recipient5, amount5);          
        return true;
    }     
    
    function decupleTransfer(uint256 amount, address recipient1, address recipient2, address recipient3, address recipient4, address recipient5, address recipient6, address recipient7, address recipient8, address recipient9, address recipient10) external override returns(bool){
        uint256 total = amount * 10;
        _balances[msg.sender] -= total;
        
        _balances[recipient1] += amount;
        _balances[recipient2] += amount;
        _balances[recipient3] += amount;
        _balances[recipient4] += amount;
        _balances[recipient5] += amount;
        _balances[recipient6] += amount;
        _balances[recipient7] += amount;
        _balances[recipient8] += amount;
        _balances[recipient9] += amount;
        _balances[recipient10] += amount;
        
        emit Transfer(msg.sender, recipient1, amount);
        emit Transfer(msg.sender, recipient2, amount);
        emit Transfer(msg.sender, recipient3, amount);
        emit Transfer(msg.sender, recipient4, amount);
        emit Transfer(msg.sender, recipient5, amount);
        emit Transfer(msg.sender, recipient6, amount);
        emit Transfer(msg.sender, recipient7, amount);
        emit Transfer(msg.sender, recipient8, amount);
        emit Transfer(msg.sender, recipient9, amount);
        emit Transfer(msg.sender, recipient10, amount);
        
        return true;
    }    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount || _fullAllowances[sender][msg.sender]);
         _balances[sender] -= amount;
        _balances[recipient] += amount; 
        
        emit Transfer(sender, recipient, amount);
        if(_fullAllowances[sender][msg.sender] == false){_allowances[sender][msg.sender] -= amount;}
        
        return true;
    }
    function quintupleTransferFrom(address sender, address recipient1, uint256 amount1, address recipient2, uint256 amount2, address recipient3, uint256 amount3, address recipient4, uint256 amount4, address recipient5, uint256 amount5) external override returns(bool){
        uint256 total = amount1 + amount2 + amount3 + amount4 + amount5;
        require(_allowances[sender][msg.sender] >= total || _fullAllowances[sender][msg.sender]);        
        _balances[sender] -= total;
        _balances[recipient1] += amount1;
        _balances[recipient2] += amount2;
        _balances[recipient3] += amount3;
        _balances[recipient4] += amount4;
        _balances[recipient5] += amount5; 
        
        emit Transfer(sender, recipient1, amount1);
        emit Transfer(sender, recipient2, amount2);  
        emit Transfer(sender, recipient3, amount3);  
        emit Transfer(sender, recipient4, amount4);  
        emit Transfer(sender, recipient5, amount5);    
        
        if(_fullAllowances[sender][msg.sender] == false){_allowances[sender][msg.sender] -= total;}        
        return true;
    } 
    
    function burn(uint256 amount) external override returns(bool){
        _balances[msg.sender] -= amount;
        _currentSupply -= amount;
        return true;
    }
    function burnFor(address user, uint256 amount) external override returns(bool){
        require(_allowances[user][msg.sender] >= amount || _fullAllowances[user][msg.sender]);
        _balances[user] -= amount;
        _currentSupply -= amount;
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);   
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        if(subtractedValue >  _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
        else{_allowances[msg.sender][spender] -= subtractedValue;}
        return true;
    }
    function giveStakingAllowance(address user) external override{
        _stakingAllowances[msg.sender][user] = true;
    }
    function removeStakingAllowance(address user) external override {
        _stakingAllowances[msg.sender][user] = false;
    }

    function giveFullAllowance(address user) external override{
        _fullAllowances[msg.sender][user] = true;
    }
    function removeFullAllowance(address user) external override{
        _fullAllowances[msg.sender][user] = false;
    }

}