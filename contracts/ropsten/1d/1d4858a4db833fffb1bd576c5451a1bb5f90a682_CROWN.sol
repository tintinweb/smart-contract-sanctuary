/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity ^0.8.0 ; //SPDX-License-Identifier: UNLICENSED

interface IERCToken {
    function totalSupply() external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function transferTokenFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CROWN is Ownable, ERC20 {
    
    constructor(string memory symbol, string memory name, uint256 totalSupply) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply*10**decimals());
    }
    
    mapping(address => uint256) private stakes;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private dividends;
    mapping(address => bool) public isStaking; //new one
    address[] internal stakeholders;
    uint256 public stableCoinPriceIn100Unit = 100;
    uint256 public crownPriceIn100Unit = 100;
    uint256 public dividendRateIn100Unit = 400;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public decimalStableCoin = 6;
    address public stableCoinAddress;
    
    event AddStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event RemoveStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event DividenPaid(address indexed stakeholder, uint256 amount, uint256 timestamp);
    
    modifier validAddress(address account){    
        require(account == address(account),"Invalid address");
        require(account != address(0));
        _;
    }
    
    function setDividendRate(uint256 newRateIn100Unit) public onlyOwner {
        dividendRateIn100Unit = newRateIn100Unit;
        for (uint256 s; s< stakeholders.length ; s+=1){ //new one
               address stakeholder = stakeholders[s];//new one
               updateReward(stakeholder);//new one
        }
    }

    function setStableCoin(address addressOfStableCoin) public validAddress(addressOfStableCoin) onlyOwner returns (bool){
        IERC20Metadata stableCoin = IERC20Metadata(addressOfStableCoin);
        decimalStableCoin = stableCoin.decimals();
        stableCoinAddress = addressOfStableCoin;
        return true;
    }
    
    function transferStableCoin(address receiver,uint256 numTokens) public validAddress(receiver) returns(bool) {
        require(stableCoinAddress != address(0), "Not specified stable coin's contract address yet(transferStableCoin error)");
        IERC20 myStableCoin = IERC20(stableCoinAddress);
        myStableCoin.transfer(receiver,numTokens);
        return true;
    }
    
    //multiple transfer the CWT token.
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i] == address(receivers[i]));
            transfer(receivers[i], amounts[i]);
        }
    }
    
//------------------------------------------------------------------------------------------------
//-------------------------------- Staking Functions ---------------------------------------------
//------------------------------------------------------------------------------------------------
    
   function setStakingPeriod (uint256 periodInDay) public onlyOwner returns(bool) {
        startDate = block.timestamp;
        endDate = startDate + (periodInDay * 1 minutes);
        return true;
   }

   function isStakeholder(address _address) public view validAddress(_address) returns(bool, uint256) {
    //   for (uint256 i = 0; i < stakeholders.length; i += 1){ //old one
    //       if (_address == stakeholders[i]) return (true, i);//old one
    //   }//old one
    //   return (false, 0); //old one
        for (uint256 s = 0; s < stakeholders.length; s += 1){
               if (_address == stakeholders[s] && isStaking[_address] ==true){
                   return (true, s);
               } 
           }
           return (false, 0); //new one
   }

   function addStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
    //   (bool _isStakeholder, ) = isStakeholder(stakeHolder);
    //   if (!_isStakeholder) stakeholders.push(stakeHolder); old one.
        bool _isStaking = isStaking[stakeHolder];
        if(!_isStaking) {
           stakeholders.push(stakeHolder);
           isStaking[stakeHolder] = true;
       } //new one
   }

   function removeStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
    //   (bool _isStakeholder, uint256 i) = isStakeholder(stakeHolder);
    //   if (_isStakeholder){
    //       stakeholders[i] = stakeholders[stakeholders.length - 1];
    //       stakeholders.pop();
    //   } //old one.
        bool _isStaking = isStaking[stakeHolder];
        if(_isStaking){
           isStaking[stakeHolder] = false;
        } // new one.
   }

   function stakeOf(address stakeHolder) public view validAddress(stakeHolder) returns (uint256) {
       return stakes[stakeHolder];
   }
   
   function dividendOf(address stakeHolder) public view validAddress(stakeHolder) returns (uint256) {
       return dividends[stakeHolder];
   }

   function totalStakes() public view returns (uint256) {
       uint256 _totalStakes = 0;
       for (uint256 i = 0; i < stakeholders.length; i += 1){//new one >> consider checking if stakes[stakeholders[i]] > 0 before +=
           _totalStakes += (stakes[stakeholders[i]]);
       }
       return _totalStakes;
   }

   function addStake(address stakeHolder, uint256 stakeAmount) public validAddress(stakeHolder) {
       require(startDate > 0 && endDate > 0, "Invalid stake end date!");
       require(block.timestamp >= startDate && block.timestamp <= endDate, "Please stake in the staking period!");
       require(stakeAmount > 0, "Can not stake zero token");
       require(balanceOf(stakeHolder) >= stakeAmount,"Not enough token to stake!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       //approve(address(this), stakeAmount); // a new one.
       //transferFrom(stakeHolder,address(this), stakeAmount); the new one.    //transfer(address(this), stakeAmount); the old one.
       _transfer(stakeHolder, address(this), stakeAmount);//for testing 
       if (stakes[stakeHolder] == 0) addStakeholder(stakeHolder);
       stakes[stakeHolder] += stakeAmount;
       emit AddStake(stakeHolder, stakeAmount, block.timestamp);
       updateReward(stakeHolder);
   }

   function removeStake(address stakeHolder, uint256 stakeAmount) public validAddress(stakeHolder) {
       require(startDate > 0 && endDate > 0, "Invalid stake end date!");
       require(block.timestamp >= endDate, "Please wait until the stake removal date!");
       require(stakes[stakeHolder] >= stakeAmount, "Not enough staking to be removed!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       _transfer(address(this), stakeHolder, stakeAmount); 
       stakes[stakeHolder] -= stakeAmount;
       if (stakes[stakeHolder] == 0) removeStakeholder(stakeHolder);
       emit RemoveStake(stakeHolder, stakeAmount, block.timestamp);
   }

   function rewardOf(address stakeHolder) public view validAddress(stakeHolder) returns (uint256) {
       return rewards[stakeHolder];
   }

   function totalRewards() public view returns(uint256) {
       uint256 _totalRewards = 0;
       for (uint256 i = 0; i < stakeholders.length; i += 1){ //consider adding if rewards[stakeholders[i]] >0
           _totalRewards += rewards[stakeholders[i]];
       }
       return _totalRewards;
   }

   function calculateReward(address stakeHolder) internal view validAddress(stakeHolder) returns (uint256) { //public view returns; old one
       uint256 rewardCWT = (stakes[stakeHolder] * dividendRateIn100Unit) / 10000;
       return rewardCWT;
   }
   
   function priceFeeding(uint256 _stableCoinPriceIn100Unit, uint256 _crownPriceIn100Unit) public onlyOwner {
       require(_stableCoinPriceIn100Unit >0 && _crownPriceIn100Unit>0,"price must be more than 0"); //new one.
       stableCoinPriceIn100Unit = _stableCoinPriceIn100Unit;
       crownPriceIn100Unit = _crownPriceIn100Unit;
   }

   function updateReward(address stakeHolder) private { 
       rewards[stakeHolder] = calculateReward(stakeHolder);
       dividends[stakeHolder] = calculateRewardToStableCoin(stakeHolder);
   }
   
   function calculateRewardToStableCoin(address stakeHolder) internal view returns (uint256) { //public view returns; old one
       uint256 rewardInCWT = calculateReward(stakeHolder);//calculateReward(stakeHolder); old one
       require(crownPriceIn100Unit > 0 && stableCoinPriceIn100Unit > 0, "No price feeding found!");
       uint256 rewardInStableCoin = ((rewardInCWT * crownPriceIn100Unit * stableCoinPriceIn100Unit) / 10000) / ((10**18) / (10**decimalStableCoin));
       return rewardInStableCoin;
   }
   
   function distributeRewards() public onlyOwner {
        require(startDate > 0 && endDate > 0, "Invalid stake end date!");
        require(block.timestamp >= endDate, "Please wait until the reward removal date.");
        require(stableCoinAddress != address(0), "Not specified stable coin's contract yet!");
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
           address stakeholder = stakeholders[i];
           uint256 reward = rewards[stakeholder];  
           uint256 dividend = dividends[stakeholder];//the new one.
           if (reward > 0) {
               uint256 rewardStableCoin = dividend; //uint256 rewardStableCoin = calculateRewardToStableCoin(stakeholder); old one
               IERCToken(stableCoinAddress).transfer(stakeholder, rewardStableCoin);
               
               //stakes[stakeholder] -= stakes[stakeholder] ;//new one
               rewards[stakeholder] -= reward;
               dividends[stakeholder] -= dividend;//dividends[stakeholder] -= rewardStableCoin; old one
               
               removeStake(stakeholder,stakes[stakeholder]); //new one.

               emit DividenPaid(stakeholder, reward, block.timestamp); //consider adding dividend in event
           }
        }
   }
   
   function withdrawReward(address stakeHolder) public validAddress(stakeHolder) {
       require(startDate > 0 && endDate > 0, "Invalid stake end date!");
       require(block.timestamp >= endDate, "Please wait until the reward removal date.");
       require(stableCoinAddress != address(0), "Not specified stable coin's contract yet!");
       require(rewards[stakeHolder] > 0,"You don't have the reward to withdraw."); //new one.
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       uint256 reward = rewards[stakeHolder];
       uint256 dividend = dividends[stakeHolder];//the new one.
       if (reward > 0) {
           uint256 rewardStableCoin = dividend; //uint256 rewardStableCoin = calculateRewardToStableCoin(stakeHolder); old one
           IERCToken(stableCoinAddress).transfer(stakeHolder, rewardStableCoin);
           rewards[stakeHolder] -= reward;
           dividends[stakeHolder] -= dividend;//dividends[stakeHolder] -= rewardStableCoin; old one
           removeStake(stakeHolder,stakes[stakeHolder]); //new one.
           emit DividenPaid(stakeHolder, reward, block.timestamp); 
       }
   }
}