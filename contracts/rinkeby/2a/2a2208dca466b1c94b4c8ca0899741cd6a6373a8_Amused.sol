/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Amused is Ownable, IERC20Metadata {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint256 public cashbackPercentage;
    uint256 public cashbackInterval;
    uint256 public taxPercentage;

    uint256 public distributionRewardPool;
    uint256 public liquidityRewardPool;
    uint256 public referralRewardPool;


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public excluded;
    mapping(address => Cashback) public cashbacks;

    struct Cashback {
        address user;
        uint256 totalClaimedCashback;
        uint256 timestamp;
    }

    constructor() {
        _name = "Amused.Finance";
        _symbol = "AMD";

        taxPercentage = 10;
        cashbackPercentage = 2;
        cashbackInterval = 5 minutes;


        uint256 _initalSupply = 10000000 ether;
        uint256 _deployerAmount = (_initalSupply * 70) / 100;

        _mint(_msgSender(), _deployerAmount);
        _mint(address(this),  _initalSupply - _deployerAmount);
        distributionRewardPool =  _initalSupply - _deployerAmount;

        cashbacks[_msgSender()] = Cashback(_msgSender(), 0, block.timestamp);

        // exclude certain address from paying tax
        excluded[address(this)] = true;
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
        uint256 _initalBalance = _balances[account];
        uint256 _cashback = calculateCashback(account);
        uint256 _finalBalance = _initalBalance + _cashback;
        return _finalBalance;
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

        (uint256 _finalAmount, uint256 _tax) = _beforeTokenTransfer(sender, recipient, amount);

        // transfer cashback rewards
        _claimCashback(sender);
        _claimCashback(recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += _finalAmount;
        _balances[address(this)] += _tax;
        _distibuteTax(_tax);

        // Update cashback state
        if(cashbacks[sender].timestamp == 0) cashbacks[sender].timestamp = block.timestamp;
        if(cashbacks[recipient].timestamp == 0) cashbacks[recipient].timestamp = block.timestamp;

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

    function _beforeTokenTransfer(address, address, uint256 amount) internal virtual returns(uint256 _finalAmount, uint256 _tax) {
        if(taxPercentage == 0 || excluded[_msgSender()]) return(amount, 0);

        _tax = (amount * taxPercentage) / 100;
        _finalAmount = amount - _tax;
        return(_finalAmount, _tax);
    }

    // Untracked
    function _distibuteTax(uint256 _tax) internal  returns(uint8) {
        if(_tax == 0) return 0;
        uint256 _splitedTax = _tax / 4;

        distributionRewardPool += _splitedTax;
        liquidityRewardPool += (_splitedTax * 2);
        referralRewardPool += _splitedTax;
        return 1;
    }

    function exclude(address _account, bool _status) external onlyOwner {
        excluded[_account] = _status;
    }

    function _isContract(address account) internal view returns(bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    // Start Cashback Logics
    function calculateDailyCashback(address _account) public view returns(uint256) {
        if(_balances[_account] == 0) return 0;
        uint256 _balance = _balances[_account];
        uint256 _rewards = (_balance * cashbackPercentage) / 100;
        return _rewards;
    }

    function calculateCashback(address _account) public view returns(uint256 _rewards) {
        if(_balances[_account] == 0 || cashbacks[_account].timestamp == 0 || _isContract(_account)) return 0;
        uint256 _lastClaimed = cashbacks[_account].timestamp;

        uint256 _unclaimedDays = (block.timestamp - _lastClaimed) / cashbackInterval;
        _rewards = _unclaimedDays * calculateDailyCashback(_account);
        return _rewards;
    }

    function _claimCashback(address _account) internal returns(uint8) {
        if(calculateCashback(_account) == 0) return 0;
        uint256 _rewards = calculateCashback(_account);
        uint256 _totalClaimedCashback =  cashbacks[_account].totalClaimedCashback + _rewards;

        cashbacks[_account] = Cashback(_account, _totalClaimedCashback, block.timestamp);
        _transferCashbackReward(_account, _rewards);
        return 1;
    }

    function _transferCashbackReward(address _account, uint256 _rewards) internal {
        if(distributionRewardPool < _rewards) {
            uint256 _diff = _rewards - distributionRewardPool;
            _mint(address(this), _diff);
            distributionRewardPool += _diff;
        }
        distributionRewardPool -= _rewards;
        _transfer(address(this), _account, _rewards);
    }
    // End claimable cashback
}