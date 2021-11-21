/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/*
  @source https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template

  CHANGES:
  
  - formatted with Prettier.
  - Updated syntax to 0.8.9
*/

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BEP20Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    /* BEP20 related */

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _symbol;
    string private _name;

    /* Kenshi related */

    /* Whitelisting and IDO presale */

    mapping(address => bool) private _whitelisted;

    /* Liquidity pools */

    address private _dexAddr;
    address private _dexRouterAddr;

    /* Reward calculation */

    uint256 private _circulation;
    uint256 private _balanceCoeff;

    /* Treasury */

    address private _treasuryAddr;

    /* Tokenomics */

    mapping(address => uint256) private _purchaseTimes;

    address private _burnAddr;

    uint8 private _baseTax;
    uint8 private _burnPercentage;
    uint8 private _investPercentage;

    uint256 private _minMaxBalance;
    uint256 private _burnThreshold;

    /**
     * Instead of implementing log functions and calculating the fine
     * amount on-demand, we decided to use pre-calculated values for it.
     * Just a bit less accurate, but saves a lot of gas.
     */
    uint8[30] private _earlySaleFines = [
        49,
        39,
        33,
        29,
        26,
        23,
        21,
        19,
        17,
        16,
        14,
        13,
        12,
        11,
        10,
        9,
        8,
        7,
        7,
        6,
        5,
        4,
        4,
        3,
        3,
        2,
        2,
        1,
        0,
        0
    ];

    /* Security / Anti-bot measures */

    bool private _tradeOpen;

    constructor() {
        _name = "Kenshi";
        _symbol = "KENSHI";

        /*
            Large supply and large decimal places were 
            to help with the accuracy loss caused by
            the reward system.
        */

        _decimals = 18;
        _totalSupply = 1e13 * 1e18;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

        /* Kenshi related */

        _dexAddr = address(0);
        _dexRouterAddr = address(0);

        _baseTax = 5;
        _burnPercentage = 1;
        _investPercentage = 50;

        /* Burning */

        _burnAddr = address(0xdead);
        _burnThreshold = _totalSupply.div(2);

        /* Treasury */

        _treasuryAddr = address(0);

        /* 
            Set initial max balance, this amount
            increases over time
        */

        _minMaxBalance = _totalSupply.div(1000);

        /*
            This value gives us maximum precision without
            facing overflows or underflows. Be careful when
            updating the _totalSupply or the value below.
        */

        _balanceCoeff = (~uint256(0)).div(_totalSupply);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded(account)) {
            return _balances[account];
        }
        return _balances[account].div(_balanceCoeff);
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address addr, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[addr][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    event Reflect(uint256 amount);

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     * Emits a {Reflect} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - `amount` should not exceed the maximum allowed
     * - `amount` should not cause the recipient balance
                  to get bigger than the maximum allowed
       - trading should be open
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        if (sender == owner() && _dexAddr == address(0)) {
            /* Transfering to DEX, do it tax free */
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            _dexAddr = recipient;
            emit Transfer(sender, recipient, amount);
            return;
        }

        /* Relay router transfers to allow removing lp tokens */
        if (sender == _dexRouterAddr || recipient == _dexRouterAddr) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return;
        }

        require(
            _tradeOpen || _whitelisted[recipient],
            "Kenshi: trading is not open yet"
        );

        uint256 burn = _getBurnAmount(amount);
        uint256 tax = _getTax(sender, amount).sub(burn);

        /* Split the tax */

        uint256 invest = tax.mul(_investPercentage).div(100);
        uint256 reward = tax.sub(invest);

        uint256 remainingAmount = amount.sub(tax);
        uint256 outgoing = _getTransferAmount(sender, amount);
        uint256 incoming = _getTransferAmount(recipient, remainingAmount);

        require(
            outgoing <= _balances[sender],
            "Balance is lower than the requested amount"
        );

        // Allow selling to DEX
        if (recipient != owner() && recipient != _dexAddr) {
            require(
                _checkMaxBalance(recipient, incoming),
                "Kenshi: resulting balance more than the maximum allowed"
            );
        }

        if (_treasuryAddr != address(0)) {
            _balances[_treasuryAddr] = _balances[_treasuryAddr].add(invest);
            emit Transfer(sender, _treasuryAddr, invest);
        }

        if (burn > 0) {
            _balances[_burnAddr] = _balances[_burnAddr].add(burn);
            emit Transfer(sender, _burnAddr, burn);
        }

        _balances[sender] = _balances[sender].sub(outgoing);
        _balances[recipient] = _balances[recipient].add(incoming);

        if (sender == _dexAddr || recipient == _dexAddr) {
            _circulation = _totalSupply
                .sub(_balances[_dexAddr])
                .sub(_balances[_burnAddr])
                .sub(_balances[_treasuryAddr]);
        }

        emit Reflect(reward);

        _balanceCoeff = _balanceCoeff.sub(
            _balanceCoeff.mul(reward).div(_circulation)
        );

        _recordPurchase(recipient, incoming);

        emit Transfer(sender, recipient, amount.sub(burn).sub(tax));
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `addr`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `addr` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address addr,
        address spender,
        uint256 amount
    ) internal {
        require(addr != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[addr][spender] = amount;
        emit Approval(addr, spender, amount);
    }

    /* Kenshi methods */

    /**
     * @dev Records weighted purchase times for fine calculation.
     */
    function _recordPurchase(address addr, uint256 amount) private {
        uint256 current = _purchaseTimes[addr].mul(
            _decoeff(addr, _balances[addr].sub(amount))
        );

        _purchaseTimes[addr] = current
            .add(block.timestamp.mul(_decoeff(addr, amount)))
            .div(balanceOf(addr));
    }

    /**
     * @dev Removes the coefficient factor from `addr` is not excluded.
     */
    function _decoeff(address addr, uint256 amount)
        private
        view
        returns (uint256)
    {
        if (_isExcluded(addr)) {
            return amount;
        }
        return amount.div(_balanceCoeff);
    }

    /**
     * @dev Check if `addr` is excluded from rewards.
     */
    function _isExcluded(address addr) private view returns (bool) {
        return
            addr == owner() ||
            addr == _dexAddr ||
            addr == _dexRouterAddr ||
            addr == _treasuryAddr ||
            addr == address(this);
    }

    /**
     * @dev Calculates the burn amount for a transaction.
     *
     * Checks how many tokens are already burned, if it's more than the
     * burn threshold then it returns zero, otherwise returns one percent
     * of `amount`.
     */
    function _getBurnAmount(uint256 amount) private view returns (uint256) {
        uint256 _burnedAmount = _balances[_burnAddr];
        if (_burnedAmount >= _burnThreshold) {
            return 0;
        }
        uint256 toBurn = amount.div(100);
        if (_burnThreshold.sub(_burnedAmount) < toBurn) {
            return _burnThreshold.sub(_burnedAmount);
        }
        return toBurn;
    }

    /**
     * @dev Check how many tokens are currently burned.
     */
    function getTotalBurned() external view returns (uint256) {
        return _balances[_burnAddr];
    }

    /**
     * @dev Check how many tokens are in circulation.
     */
    function getCirculation() external view returns (uint256) {
        return _circulation;
    }

    /**
     * @dev Get tax amount for `amount` moved from `sender`.
     */
    function _getTax(address sender, uint256 amount)
        private
        view
        returns (uint256)
    {
        uint8 taxPercentage = _getTaxPercentage(sender);
        uint256 tax = amount.mul(taxPercentage).div(100);
        return tax;
    }

    /**
     * @dev calculate tax percentage for `sender` based on purchase times.
     */
    function _getTaxPercentage(address sender) private view returns (uint8) {
        if (_isExcluded(sender)) {
            return _baseTax;
        }
        uint256 daysPassed = block.timestamp.sub(_purchaseTimes[sender]).div(
            86400
        );
        if (daysPassed >= 30) {
            return _baseTax;
        }
        return _baseTax + _earlySaleFines[daysPassed];
    }

    /**
     * @dev calculate tax percentage for `sender` at `timestamp` based on purchase times.
     */
    function getTaxPercentageAt(address sender, uint256 timestamp)
        public
        view
        returns (uint8)
    {
        if (_isExcluded(sender)) {
            return _baseTax;
        }
        uint256 daysPassed = timestamp.sub(_purchaseTimes[sender]).div(86400);
        if (daysPassed >= 30) {
            return _baseTax;
        }
        return _baseTax + _earlySaleFines[daysPassed];
    }

    /**
     * @dev Calculates transfer amount based on reward exclusion and reward coeff.
     */
    function _getTransferAmount(address sender, uint256 amount)
        private
        view
        returns (uint256)
    {
        if (_isExcluded(sender)) {
            return amount;
        }
        return amount.mul(_balanceCoeff);
    }

    /**
     * @dev Checks if `recipient` won't have more than max balance after a transfer.
     */
    function _checkMaxBalance(address recipient, uint256 incoming)
        private
        view
        returns (bool)
    {
        uint256 newBalance = _balances[recipient].add(incoming);
        if (!_isExcluded(recipient)) {
            newBalance = newBalance.div(_balanceCoeff);
        }
        return newBalance <= getMaxBalance();
    }

    /**
     * @dev Returns the current maximum balance.
     */
    function getMaxBalance() public view returns (uint256) {
        return _minMaxBalance.add(_circulation.div(100));
    }

    /**
     * @dev Remove `amount` from msg.sender and reflect it on all holders.
     *
     * Requirements:
     *
     * - `amount` shouldn't be bigger than the msg.sender balance.
     */
    function deliver(uint256 amount) external {
        address sender = _msgSender();
        uint256 outgoing = _getTransferAmount(sender, amount);

        require(
            outgoing <= _balances[sender],
            "Kenshi: cannot deliver more than the owned balance"
        );

        _balances[sender] = _balances[sender].sub(outgoing);

        if (sender == _treasuryAddr) {
            _circulation = _totalSupply
                .sub(_balances[_dexAddr])
                .sub(_balances[_burnAddr])
                .sub(_balances[_treasuryAddr]);
        }

        _balanceCoeff = _balanceCoeff.sub(
            _balanceCoeff.mul(amount).div(_circulation)
        );

        emit Reflect(amount);
    }

    /**
     * @dev Sets the current DEX address to `dex`.
     *
     * Requirements:
     *
     * - `dex` should not be address(0)
     */
    function setDexAddr(address dex) external onlyOwner {
        require(dex != address(0), "Kenshi: cannot set DEX addr to 0x0");
        _dexAddr = dex;
    }

    /**
     * @dev Get the current DEX address.
     */
    function getDexAddr() external view returns (address) {
        return _dexAddr;
    }

    /**
     * @dev Sets the current DEX router address to `router`.
     *
     * Requirements:
     *
     * - `router` should not be address(0)
     */
    function setDexRouterAddr(address router) external onlyOwner {
        require(router != address(0), "Kenshi: cannot set router addr to 0x0");
        _dexRouterAddr = router;
    }

    /**
     * @dev Get the current DEX router address.
     */
    function getDexRouterAddr() external view returns (address) {
        return _dexRouterAddr;
    }

    event InvestmentPercentageChanged(uint8 percentage);

    /**
     * @dev Sets the treasury `percentage`, indirectly sets rewards percentage.
     *
     * Requirements:
     *
     * - percentage should be equal to or smaller than 100
     *
     * emits a {InvestmentPercentageChanged} event.
     */
    function setInvestPercentage(uint8 percentage) external onlyOwner {
        require(percentage <= 100);
        _investPercentage = percentage;
        emit InvestmentPercentageChanged(percentage);
    }

    /**
     * @dev Returns the investment percentage.
     */
    function getInvestPercentage() external view returns (uint8) {
        return _investPercentage;
    }

    event BaseTaxChanged(uint8 percentage);

    /**
     * @dev Sets the base tax `percentage`.
     *
     * Requirements:
     *
     * - percentage should be equal to or smaller than 15
     *
     * emits a {BaseTaxChanged} event.
     */
    function setBaseTaxPercentage(uint8 percentage) external onlyOwner {
        require(percentage <= 15);
        _baseTax = percentage;
        emit BaseTaxChanged(percentage);
    }

    /**
     * @dev Returns the base tax percentage.
     */
    function getBaseTaxPercentage() external view returns (uint8) {
        return _baseTax;
    }

    /**
     * @dev Sets the trading to open, allows making transfers.
     */
    function openTrades() external onlyOwner {
        _tradeOpen = true;
    }

    /**
     * @dev Adds `addr` to whitelisted IDO presale addresses.
     */
    function whitelist(address addr) external onlyOwner {
        require(addr != address(0), "Kenshi: cannot whitelist 0x0");
        _whitelisted[addr] = true;
    }

    /**
     * @dev Checks if `addr` is whitelisted for IDO presale.
     */
    function isWhitelisted(address addr) external view returns (bool) {
        return _whitelisted[addr];
    }

    /**
     * @dev Sets `treasury` addr for collecting investment tokens.
     *
     * Requirements:
     *
     * - `treasury` should not be address(0)
     */
    function setTreasuryAddr(address treasury) external onlyOwner {
        require(treasury != address(0), "Kenshi: cannot set treasury to 0x0");
        _treasuryAddr = treasury;
    }

    event BurnThresholdChanged(uint256 threshold);

    /**
     * @dev Sets the `threshold` for automatic burns.
     *
     * emits a {BurnThresholdChanged} event.
     */
    function setBurnThreshold(uint256 threshold) external onlyOwner {
        _burnThreshold = threshold;
        emit BurnThresholdChanged(threshold);
    }

    /**
     * @dev Returns the burn threshold amount.
     */
    function getBurnThreshold() external view returns (uint256) {
        return _burnThreshold;
    }

    /**
     * @dev Sends `amount` of BEP20 `token` from contract address to `recipient`
     *
     * Useful if someone sent bep20 tokens to the contract address by mistake.
     */
    function recoverBEP20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner returns (bool) {
        return IBEP20(token).transfer(recipient, amount);
    }
}