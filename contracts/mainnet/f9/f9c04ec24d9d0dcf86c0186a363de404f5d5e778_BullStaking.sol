/**
 *Submitted for verification at Etherscan.io on 2020-09-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;


    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

}


contract BullStaking is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _stakes;

    address public owner = msg.sender;
    address  public tokenAddress;
    uint public stakingStarts;
    uint public stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint256 public stakedTotal;
    uint256 public stakingCap;
    uint256 public totalReward;
    uint256 public earlyWithdrawReward;
    uint256 public rewardBalance;
    uint256 public stakedBalance;

    address payable ethFund = 0xB205238e2eCb8462d5D826E28DCd2aCe0BF811a4;

    ERC20 public ERC20Interface;
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);
    event PaidOut(address indexed token, address indexed staker_, uint256 amount_, uint256 reward_);
    event Refunded(address indexed token, address indexed staker_, uint256 amount_);

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public price;
    uint256 public sold = 0;

    bool public distributionFinished = false;

    bool public distribution_ongoing = false;

    uint256 public tokensPerEth = 60000e18;

    constructor (string memory name, string memory symbol, address payable _ethFund, uint256 _tokensPerEth) public {
        tokensPerEth = _tokensPerEth*1e18;
        price = SafeMath.div(1e18, SafeMath.div(tokensPerEth, 1e18));
        _name = name;
        _symbol = symbol;
        ethFund = _ethFund;
        _decimals = 18;
        _totalSupply = 100000000e18;
        owner = msg.sender;
        _balances[owner] = _balances[owner].add(_totalSupply);
    }

    modifier saleHappening {
      require(distribution_ongoing == true, "distribution started");
      require(sold <= _totalSupply, "tokens sold out");
      _;
    }

    function tokenSaleStarted() public view returns (bool) {
        return distribution_ongoing;
    }

    function startSale() public
    onlyOwner {
      distribution_ongoing = true;
    }

    function endSale() public
    onlyOwner {
      distribution_ongoing = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;

        return true;
    }

    function distr(address _to, uint256 _amount) canDistr private returns (bool) {

        _balances[owner] = _balances[owner].sub(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        return true;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }


    receive ()
      external
      payable
      saleHappening
    {
      
      uint excessAmount = msg.value % price;

      uint purchaseAmount = SafeMath.sub(msg.value, excessAmount);

      uint tokenPurchase = SafeMath.div(SafeMath.mul(purchaseAmount,1e18), price);

      uint total_token = tokenPurchase;

      sold= SafeMath.add(sold, total_token);

      assert(sold <= _totalSupply);

      ethFund.transfer(msg.value);
      assert(distr(msg.sender, total_token));

    }


    function init_staking(
        address tokenAddress_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint256 stakingCap_
    )

    public onlyOwner {

        require(tokenAddress_ != address(0), "BullStaking: 0 address");
        tokenAddress = tokenAddress_;

        stakingStarts = now;

        require(stakingEnds_ > 0, "BullStaking: staking end must be positive");
        stakingEnds = now + stakingEnds_;

        require(withdrawStarts_ >= stakingEnds_, "Bulltaking: withdrawStarts must be after staking ends");
        withdrawStarts = withdrawStarts_;

        withdrawEnds = withdrawStarts + 180 days; // 6 months to withdraw reward

        require(stakingCap_ > 0, "BullStaking: stakingCap must be positive");
        stakingCap = stakingCap_;
    }

    function addReward(uint256 rewardAmount, uint256 withdrawableAmount)
    public

    returns (bool) {
        require(rewardAmount > 0, "BullStaking: reward must be positive");
        require(withdrawableAmount >= 0, "BullStaking: withdrawable amount cannot be negative");
        require(withdrawableAmount <= rewardAmount, "BullStaking: withdrawable amount must be less than or equal to the reward amount");
        address from = msg.sender;
        if (!_payMe(from, rewardAmount)) {
            return false;
        }

        totalReward = totalReward.add(rewardAmount);
        rewardBalance = totalReward;
        earlyWithdrawReward = earlyWithdrawReward.add(withdrawableAmount);
        return true;
    }

    function stakeOf(address account) public view returns (uint256) {
        return _stakes[account];
    }

    function stake(uint256 amount)
    public
    _positive(amount)
    _realAddress(msg.sender)
    returns (bool) {
        address from = msg.sender;
        return _stake(from, amount);
    }

    function withdraw(uint256 amount)
    public
    _after(withdrawStarts)
    _positive(amount)
    _realAddress(msg.sender)
    returns (bool) {
        address from = msg.sender;
        require(amount <= _stakes[from], "BullStaking: not enough balance");
        if (now < withdrawEnds) {
            return _withdrawEarly(from, amount);
        } else {
            return _withdrawAfterClose(from, amount);
        }
    }

    function _withdrawEarly(address from, uint256 amount)
    private
    _realAddress(from)
    returns (bool) {
        // The formula to calculate reward:
        // r = (earlyWithdrawReward / stakedTotal) * (now - stakingEnds) / (withdrawEnds - stakingEnds)
        // w = (1+r) * a
        uint256 denom = (withdrawEnds.sub(stakingEnds)).mul(stakedTotal);
        uint256 reward = (
        ( (now.sub(stakingEnds)).mul(earlyWithdrawReward) ).mul(amount)
        ).div(denom);
        uint256 payOut = amount.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        stakedBalance = stakedBalance.sub(amount);
        _stakes[from] = _stakes[from].sub(amount);
        if (_payDirect(from, payOut)) {
            emit PaidOut(tokenAddress, from, amount, reward);
            return true;
        }
        return false;
    }

    function _withdrawAfterClose(address from, uint256 amount)
    private
    _realAddress(from)
    returns (bool) {
        uint256 reward = (rewardBalance.mul(amount)).div(stakedBalance);
        uint256 payOut = amount.add(reward);
        _stakes[from] = _stakes[from].sub(amount);
        if (_payDirect(from, payOut)) {
            emit PaidOut(tokenAddress, from, amount, reward);
            return true;
        }
        return false;
    }

    function _stake(address staker, uint256 amount)
    private
    _after(stakingStarts)
    _before(stakingEnds)
    _positive(amount)
    returns (bool) {
        amount = amount*1e18;
        uint256 remaining = amount;
        if (remaining > (stakingCap.sub(stakedBalance))) {
            remaining = stakingCap.sub(stakedBalance);
        }

        require(remaining > 0, "BullStaking: Staking cap is filled");
        require((remaining + stakedTotal) <= stakingCap, "BullStaking: this will increase staking amount pass the cap");
        if (!_payMe(staker, remaining)) {
            return false;
        }
        emit Staked(tokenAddress, staker, amount, remaining);

        if (remaining < amount) {

            uint256 refund = amount.sub(remaining);
            if (_payTo(staker, staker, refund)) {
                emit Refunded(tokenAddress, staker, refund);
            }
        }

        stakedBalance = stakedBalance.add(remaining);
        stakedTotal = stakedTotal.add(remaining);
        _stakes[staker] = _stakes[staker].add(remaining);
        return true;
    }

    function _payMe(address payer, uint256 amount)
    private
    returns (bool) {
        return _payTo(payer, address(this), amount);
    }

    function _payTo(address allower, address receiver, uint256 amount)
    private
    returns (bool) {

        ERC20Interface = ERC20(tokenAddress);
        return ERC20Interface.transferFrom(allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount)
    private
    _positive(amount)
    returns (bool) {
        ERC20Interface = ERC20(tokenAddress);
        return ERC20Interface.transfer(to, amount);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "BullStaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount >= 0, "BullStaking: negative amount");
        _;
    }

    modifier _after(uint eventTime) {
        require(now >= eventTime, "BullStaking: bad timing for the request");
        _;
    }

    modifier _before(uint eventTime) {
        require(now < eventTime, "BullStaking: bad timing for the request");
        _;
    }

}