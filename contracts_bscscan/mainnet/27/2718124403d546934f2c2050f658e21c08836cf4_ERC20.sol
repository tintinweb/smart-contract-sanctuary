/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity ^0.8.4;

interface IERC20{

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint256);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);
  
  function approve(address spender, uint256 amount) external returns (bool);
  
  function increaseAllowance(address spender, uint256 addedValue) external;

  function decreaseAllowance(address spender, uint256 subtractedValue) external;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function burn(uint256 amount) external;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value); 

}

contract ERC20 is IERC20{
    
    uint256 private _deploymentBlock;
    address private dev;
    
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _claimedDays;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (uint256 => uint256) private _dayrewards;
    mapping (uint256 => uint256) private _totalSupplyOnDay;
    
    uint256 private _totalSupply = 1000000000000000000000000000000;

    string private _name = "HAZY";
    string private _symbol = "HAZY ";

    constructor (address developer) {
        _balances[msg.sender] = _totalSupply;
        _deploymentBlock = block.number;
        dev = developer;
    }

    function name() external view override  returns (string memory) {
        return _name;
    }

    function symbol() external view override  returns (string memory) {
        return _symbol;
        
    }
    function decimals() external view override returns (uint256) {
        return 18;
    }

    function totalSupply() external view override  returns (uint256) {
        return _totalSupply;
    }
    
    function currentBlock() external view returns(uint256){
        return block.number;
    }
    
    function balanceOf(address user) external view override returns (uint256) {
         uint256 day = (block.number - _deploymentBlock) / 50;
         uint256 rewards;
         uint256 balance = _balances[user]; 
         for(uint256 t = _claimedDays[user]; t < day; ++t){
             rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
         }
        return _balances[user] + rewards;
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function applyFee(uint256 amount) internal returns(uint256){
        uint256 day = (block.number - _deploymentBlock) / 1; //28800
        uint256 fee = amount * 80 / 1000;
        uint256 percent3 = amount * 50 / 1000;
        uint256 burn = amount * 10 / 1000;
        _dayrewards[day] += percent3;
        _totalSupply -= (percent3 + burn);
        _totalSupplyOnDay[day] = _totalSupply;
        _balances[dev] += amount * 20 / 1000;
        return amount - fee;
        
    }
    
    function claimRewards(address user) internal {
        uint256 day = (block.number - _deploymentBlock) / 1;
        uint256 rewards;
        uint256 balance = _balances[user];
        for(uint256 t = _claimedDays[user]; t < day; ++t){
            rewards += _dayrewards[t] * balance / (_totalSupplyOnDay[t] + 1);
        }
        
        _claimedDays[user] = day;
        _balances[user] += rewards;
    }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    claimRewards(msg.sender);
    claimRewards(recipient);
    _balances[msg.sender] -= amount;
    _balances[recipient] += amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    require(_allowances[sender][msg.sender] >= amount);
      
      claimRewards(msg.sender);
      claimRewards(recipient);
      
      _balances[sender] -= amount;
      _balances[recipient] += applyFee(amount);
      _allowances[sender][msg.sender] -= amount;
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);   
        return true;
    }
    
  function increaseAllowance(address spender, uint256 addedValue) external override {
      _allowances[msg.sender][spender] += addedValue;
      emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);      
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external override {
      if(subtractedValue > _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
      else {_allowances[msg.sender][spender] -= subtractedValue;}
      emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);       
  }
  
  function burn(uint256 amount) external override {
      _balances[msg.sender] -= amount;
      _totalSupply -= amount;
  }

}