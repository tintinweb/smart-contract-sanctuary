/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
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

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract FITToken is ERC20, Ownable {

  using SafeMath for uint256;

  uint256 public constant INITIAL_TOKEN_PRICE = 0.01 ether;
  uint256 public constant INITIAL_SUPPLY_PRICE = 60000 ether;
  uint256 public constant MIN_PRICE = 0.01 ether;

  uint256 public constant TOKEN_PRICE_INCREASING_MONTHLY_PERCENT = 100;
  uint256 public constant TOKEN_PRICE_INCREASING_PERIOD = 30 days;

  uint256 public BUY_TOKENS_MARKUP_PERCENT = 20;
  uint256 public REINVEST_TOKENS_MARKUP_PERCENT = 10;
  uint256 public SELL_TOKENS_DISCOUNT_PERCENT = 20;

  uint256[6] public REFERRAL_PERCENTS = [5, 3, 2, 1, 1, 1]; 
  uint256 public REFERRAL_TOTAL_PERCENT;

  uint256 public constant SERVICE_PERCENT = 10;
  uint256 public constant LIQUIDITY_PERCENT = 3;
  address payable public serviceAddress;

  address payable public constant DEFAULT_REFERRER = payable(0xda002E82937f0b31b63e1721701E6A6BfE4D81d5);
  address payable public constant INITIAL_LIQUIDITY = payable(0xa28cb54105F31B9B504CA510b37E4A9e5b3FA81f);

  uint256 public totalPlayers;
  uint256 public totalInvested;
  uint256 public totalPayout;
  uint256 public totalTokensBought;

  uint256 public totalReferralReward;

  struct Player {
    uint256 time;
    uint256 balance;
    uint256 deposit;
    uint256 payout;

    address referrer;
    uint256 referralReward;
    uint256[6] referralNumbers;
  }

  mapping(address => Player) public players;

  uint256 private periodStartTime;
  uint256 private periodStartPrice = INITIAL_TOKEN_PRICE;

  uint256 constant public TIME_STEP = 1 days;
  uint256 constant public PERCENTS_DIVIDER = 10000;

  address public flipTokenContractAddress = address(0x0);

  struct Stake {
    uint256 amount;
    uint256 checkpoint;
    uint256 checkpointHold;
    uint256 accumulatedReward;
    uint256 withdrawnReward;
  }
  mapping (address => Stake) stakes;

  
  uint256 constant public HOLD_BONUS_PERCENT_STAKE = 500; 
  uint256 constant public HOLD_BONUS_PERCENT_LIMIT = 10000; 

  
  uint256 constant public USER_DEPOSITS_STEP_STAKE = 1500 ether; 
  uint256 constant public VIP_BONUS_PERCENT_STAKE = 100; 
  uint256 constant public VIP_BONUS_PERCENT_LIMIT = 10000; 

  uint256 public MULTIPLIER = 2;
  uint256 public DIVIDER = 10;

  event PriceChange(uint256 oldPrice, uint256 newPrice, uint256 time);

  
  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event RewardWithdrawn(address indexed user, uint256 reward);

  event NewReferral(address indexed user, address indexed referral, uint256 amount, uint256 time);

  constructor() ERC20("Fractal Investment Token", "FIT") {
    serviceAddress = DEFAULT_REFERRER;
    players[serviceAddress].time = block.timestamp;
    periodStartTime = block.timestamp;
    register(serviceAddress, serviceAddress);
    _mint(INITIAL_LIQUIDITY, INITIAL_SUPPLY_PRICE.mul(10 ** uint256(decimals())).div(INITIAL_TOKEN_PRICE));

    
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      REFERRAL_TOTAL_PERCENT = REFERRAL_TOTAL_PERCENT.add(REFERRAL_PERCENTS[i]);
    }
  }

  function register(address _addr, address _referrer) private {
    Player storage player = players[_addr];
    player.referrer = _referrer;

    address ref = _referrer;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      if (ref == serviceAddress) {
        break;
      }
      players[ref].referralNumbers[i] = players[ref].referralNumbers[i].add(1);

      ref = players[ref].referrer;
    }
  }

  function buy(address _referredBy) public payable {
    require(msg.value >= MIN_PRICE, "Invalid buy price");
    Player storage player = players[msg.sender];

    if (player.time == 0) {
      player.time = block.timestamp;
      totalPlayers++;
      if (_referredBy != address(0x0) && players[_referredBy].deposit > 0){
        register(msg.sender, _referredBy);

        emit NewReferral(msg.sender, _referredBy, msg.value, block.timestamp);
      } else {
        register(msg.sender, serviceAddress);
      }
    }
    player.deposit = player.deposit.add(msg.value);

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    uint256 tokensAmount = msg.value
      .mul(10 ** uint256(decimals()))
      .div(buyPrice());
    _mint(msg.sender, tokensAmount);

    distributeRef(msg.value, player.referrer);

    totalInvested = totalInvested.add(msg.value);
    totalTokensBought = totalTokensBought.add(tokensAmount);

    payable(owner()).transfer(msg.value.mul(SERVICE_PERCENT).div(100));
    payable(INITIAL_LIQUIDITY).transfer(msg.value.mul(LIQUIDITY_PERCENT).div(100));
  }

  
  function sell(uint256 _amount) public {
    require(balanceOf(msg.sender) >= _amount, "Not enough tokens on the balance");
    Player storage player = players[msg.sender];
    if (player.time == 0) {
      player.time = block.timestamp;
      totalPlayers++;
      register(msg.sender, serviceAddress);
    }

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    player.balance = player.balance.add(
      _amount
        .mul(sellPrice())
        .div(10 ** uint256(decimals()))
    );
    _burn(msg.sender, _amount);
  }

  
  function reinvest() public {
    require(players[msg.sender].time > 0, "You didn't buy tokens yet");
    Player storage player = players[msg.sender];

    require(player.balance > 0, "Nothing to reinvest");

    if (block.timestamp.sub(periodStartTime) >= TOKEN_PRICE_INCREASING_PERIOD) {
      uint256 oldPrice = price();
      periodStartPrice = periodStartPrice.mul(2);
      periodStartTime = block.timestamp;
      emit PriceChange(oldPrice, price(), block.timestamp);
    }

    uint256 trxAmount = player.balance;
    uint256 tokensAmount = trxAmount
      .mul(10 ** uint256(decimals()))
      .div(reinvestPrice());
    player.balance = 0;
    _mint(msg.sender, tokensAmount);

    distributeRef(trxAmount, player.referrer);

    totalInvested = totalInvested.add(trxAmount);
    player.deposit = player.deposit.add(trxAmount);
    totalTokensBought = totalTokensBought.add(tokensAmount);

    payable(owner()).transfer(trxAmount.mul(SERVICE_PERCENT).div(100));
  }

  
  function withdraw() public {
    require(players[msg.sender].time > 0, "You didn't buy tokens yet");
    require(players[msg.sender].balance > 0, "Nothing to withdraw");
    Player storage player = players[msg.sender];
    
    uint256 amount = player.balance;
    player.balance = 0;
    player.payout = player.payout.add(amount);

    totalPayout = totalPayout.add(amount);

    payable(msg.sender).transfer(amount);
  }

  
  function price() public view returns (uint256) {
    return periodStartPrice.add(
      periodStartPrice
        .mul(TOKEN_PRICE_INCREASING_MONTHLY_PERCENT)
        .mul(block.timestamp.sub(periodStartTime))
        .div(TOKEN_PRICE_INCREASING_PERIOD)
        .div(100)
    );
  }

  function buyPrice() public view returns (uint256) {
    return price()
      .mul(100 + BUY_TOKENS_MARKUP_PERCENT)
      .div(100);
  }

  function reinvestPrice() public view returns (uint256) {
    return price()
      .mul(100 + REINVEST_TOKENS_MARKUP_PERCENT)
      .div(100);
  }

  function sellPrice() public view returns (uint256) {
    return price()
      .mul(100 - SELL_TOKENS_DISCOUNT_PERCENT)
      .div(100);
  }

  
  function distributeRef(uint256 _amount, address _referrer) private {
    uint256 totalReward = (_amount.mul(REFERRAL_TOTAL_PERCENT)).div(100);

    address ref = _referrer;
    uint256 refReward;
    for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
      refReward = _amount.mul(REFERRAL_PERCENTS[i]).div(100);
      totalReward = totalReward.sub(refReward);

      players[ref].referralReward = players[ref].referralReward.add(refReward);
      totalReferralReward = totalReferralReward.add(refReward);

      if (refReward > 0) {
        if (ref != address(0x0)) {
          payable(ref).transfer(refReward);
        } else {
          serviceAddress.transfer(refReward);
        }
      }

      ref = players[ref].referrer;
    }

    if (totalReward > 0) {
      serviceAddress.transfer(totalReward);
    }
  }

  

  function changeServiceAddress(address payable _address) public onlyOwner {
    require(_address != address(0x0), "Invalid address");
    require(_address != serviceAddress, "Nothing to change");

    serviceAddress = _address;
    players[serviceAddress].time = block.timestamp;
    register(serviceAddress, serviceAddress);
  }

  

  function getStatistics() public view returns (uint256[9] memory) {
    return [
      totalPlayers,
      totalInvested,
      totalPayout,
      totalTokensBought,

      totalReferralReward,

      price(),
      buyPrice(),
      reinvestPrice(),
      sellPrice()
    ];
  }

  function getReferralNumbersByLevels(address _address) public view returns(uint256[6] memory) {
    return players[_address].referralNumbers;
  }

  

  function setFlipTokenContractAddress(address _flipTokenContractAddress) external onlyOwner {
    require(flipTokenContractAddress == address(0x0), "LP token address already configured");
    require(isContract(_flipTokenContractAddress), "Provided address is not an LP token contract address");

    flipTokenContractAddress = _flipTokenContractAddress;
  }

  function getStakeVIPBonusRate(address userAddress) public view returns (uint256) {
    uint256 vipBonusRate = stakes[userAddress].amount.div(USER_DEPOSITS_STEP_STAKE).mul(VIP_BONUS_PERCENT_STAKE);

    if (vipBonusRate > VIP_BONUS_PERCENT_LIMIT) {
      return VIP_BONUS_PERCENT_LIMIT;
    }

    return vipBonusRate;
  }

  function getStakeHOLDBonusRate(address userAddress) public view returns (uint256) {
    if (stakes[userAddress].checkpointHold == 0) {
      return 0;
    }

    uint256 holdBonusRate = (block.timestamp.sub(stakes[userAddress].checkpointHold)).div(TIME_STEP).mul(HOLD_BONUS_PERCENT_STAKE);

    if (holdBonusRate > HOLD_BONUS_PERCENT_LIMIT) {
      return HOLD_BONUS_PERCENT_LIMIT;
    }

    return holdBonusRate;
  }

  function getUserStakePercentRate(address userAddress) public view returns (uint256) {
    return getStakeVIPBonusRate(userAddress)
      .add(getStakeHOLDBonusRate(userAddress));
  }

  function stake(uint256 _amount) external returns (bool) {
    require(_amount > 0, "Invalid tokens amount value");

    if (!IERC20(flipTokenContractAddress).transferFrom(msg.sender, address(this), _amount)) {
      return false;
    }

    uint256 reward = availableReward(msg.sender);
    if (reward > 0) {
      stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
    }

    stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
    stakes[msg.sender].checkpoint = block.timestamp;
    if (stakes[msg.sender].checkpointHold == 0) {
      stakes[msg.sender].checkpointHold = block.timestamp;
    }

    emit Staked(msg.sender, _amount);

    return true;
  }

  function availableReward(address userAddress) public view returns (uint256) {
    return (stakes[userAddress].amount
      .mul(PERCENTS_DIVIDER.add(getUserStakePercentRate(userAddress))).div(PERCENTS_DIVIDER))
      .mul(MULTIPLIER)
      .mul(block.timestamp.sub(stakes[userAddress].checkpoint))
      .div(DIVIDER)
      .div(TIME_STEP);
  }

  function withdrawReward() external {
    uint256 reward = stakes[msg.sender].accumulatedReward
      .add(availableReward(msg.sender));

    if (reward > 0) {
      
      stakes[msg.sender].checkpoint = block.timestamp;
      stakes[msg.sender].accumulatedReward = 0;
      stakes[msg.sender].withdrawnReward = stakes[msg.sender].withdrawnReward.add(reward);

      _mint(msg.sender, reward);

      emit RewardWithdrawn(msg.sender, reward);
    }
  }

  function unstake(uint256 _amount) external {
    require(_amount > 0, "Invalid tokens amount value");
    require(_amount <= stakes[msg.sender].amount, "Not enough tokens on the stake balance");

    uint256 reward = availableReward(msg.sender);
    if (reward > 0) {
      stakes[msg.sender].accumulatedReward = stakes[msg.sender].accumulatedReward.add(reward);
    }

    stakes[msg.sender].amount = stakes[msg.sender].amount.sub(_amount);
    stakes[msg.sender].checkpoint = block.timestamp;
    if (stakes[msg.sender].amount > 0) {
      stakes[msg.sender].checkpointHold = block.timestamp;
    } else {
      stakes[msg.sender].checkpointHold = 0; 
    }

    require(IERC20(flipTokenContractAddress).transfer(msg.sender, _amount));

    emit Unstaked(msg.sender, _amount);
  }

  function getUserStakeStats(address _userAddress) public view
    returns (uint256, uint256, uint256, uint256, uint256)
  {
    return (
      stakes[_userAddress].amount,
      stakes[_userAddress].accumulatedReward,
      stakes[_userAddress].withdrawnReward,
      getStakeVIPBonusRate(_userAddress),
      getStakeHOLDBonusRate(_userAddress)
    );
  }

  function getUserStakeTimeCheckpoints(address _userAddress) public view returns (uint256, uint256) {
    return (
      stakes[_userAddress].checkpoint,
      stakes[_userAddress].checkpointHold
    );
  }

  function updateMultiplier(uint256 multiplier) external onlyOwner {
    require(multiplier > 0 && multiplier <= 50, "Multiplier is out of range");

    MULTIPLIER = multiplier;
  }

  function updateDivider(uint256 divider) external onlyOwner {
    require(divider > 0, "Divider is out of range");

    DIVIDER = divider;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  function buy() external payable {
    payable(msg.sender).transfer(msg.value);
  }

}