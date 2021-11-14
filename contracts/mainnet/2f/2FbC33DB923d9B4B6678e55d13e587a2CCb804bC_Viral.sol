// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

/*
BEGIN KEYBASE SALTPACK SIGNED MESSAGE. kXR7VktZdyH7rvq v5weRa0zkYfegFM 5cM6gB7cyPatQvp 6KyygX8PsvQVo4n Ugo6Il5bm5uWrwV gfKz4IMGvvw0ZCQ QJai8AcoC5xNiFh PGioCgTkGBEInLL uz40oe8lYwjoXoM eTXsRVcG6KdNwsH nQS2X4ruHIv5Ffi QLYkL1vejSBJL8Z RvdM02suYKeOkm0 Hwf7STe3UtViWlg J7QZUO3TuLtxC1i L9Gy5HSUv8k9ZXE T1jUkD7myLRQ1MO SDAAAIpj9yVw7i. END KEYBASE SALTPACK SIGNED MESSAGE.
*/

import '../libraries/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the VIRAL token.
 *
 * Viral is a GSN supporting ERC20 token with:
 *  - a variable token supply
 *  - a 5% fee on transfer such that:
 *    - 3% is redistributed to all eligible token holders
 *    - 1% is awarded to the team wallet (aka the default referrer)
 *    - 1% is awarded to the referrer of the recipient address (fallbacks to the default referrer)
 *
 * Every address can chose to set (only once) its referrer, by calling the `addReferrer` function.
 * The default value for addresses that chose not to set this value is the default referrer address
 *
 * The `owner` has the ability to:
 *  - exclude/include addresses from/in fees on transfer
 *  - exclude/include addresses from/in reflection rewards
 *  - allow/disallow an address to mint VIRAL tokens
 *  - allow/disallow an address to burn VIRAL tokens
 *  - update the trustedForwarder address
 *  - update the fee on transfer (upto a maximum of 5% of transaction amount)
 */
contract Viral is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _isMinter;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;

    mapping(address => bool) private _isReferredYet;
    mapping(address => address) private _referrerOf;
    mapping(address => uint256) private _referralCountOf;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastDividendPoints;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant pointMultiplier = 10**18;
    uint256 private _totalSupply;
    uint256 private _totalReferrals;
    uint256 private _totalDividendPoints;
    uint256 private _excludedFromRewardSupply;

    uint256 public totalFee = 5;
    uint256 public viralFee = 1;
    uint256 public referralFee = 1;

    address public defaultReferrer;
    address public trustedForwarder;

    bool public isMintingAllowed = true;

    string private _name = "Viral";
    string private _symbol = "VIRAL";

    constructor(address _defaultReferrer) public {

        defaultReferrer = _defaultReferrer;

        _isMinter[owner()] = true;
        _isExcludedFromFee[owner()] = true;

        _isExcludedFromReward[address(0)] = true;
        _isExcludedFromReward[_defaultReferrer] = true;

        _referrerOf[_defaultReferrer] = address(0);
        _isReferredYet[_defaultReferrer] = true;

        _mint(_msgSender(), 10000000 * 10**18); // a starting supply of 10,000,000 tokens worth $100
    }

    modifier onlyMinter() {
        require(_isMinter[_msgSender()], "VIRAL: Minter only");
        _;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function versionRecipient() external pure returns (string memory) {
        return "1.0.0";
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function totalReferrals() external view returns (uint256) {
        return _totalReferrals;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account].add(_dividendsOwing(account));
    }

    function referrerOf(address account) public view returns (address) {
        if(_isReferredYet[account]) {
            return _referrerOf[account];
        }
        return defaultReferrer;
    }

    function referralCountOf(address account) public view returns (uint256) {
        return _referralCountOf[account];
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function addReferrer(address _referrer) external {
        _addReferrer(_msgSender(), _referrer);
    }

    function burn(uint256 amount) external onlyMinter() {
        _burn(_msgSender(), amount);
    }

    function mint(address account, uint256 amount) external onlyMinter() {
        require(isMintingAllowed, "VIRAL: Minting not allowed anymore");
        _mint(account, amount);
    }

    function disableMinting() external onlyMinter() {
        require(isMintingAllowed, "VIRAL: Minting already disabled");
        isMintingAllowed = false;
    }

    function enableMinting() external onlyOwner() {
        require(!isMintingAllowed, "VIRAL: Minting already enabled");
        isMintingAllowed = true;
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromReward[account], "VIRAL: Account already excluded");
        _updateAccount(account);
        _isExcludedFromReward[account] = true;
        _excludedFromRewardSupply = _excludedFromRewardSupply.add(_balances[account]);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "VIRAL: Account not excluded");
        _updateAccount(account);
        _isExcludedFromReward[account] = false;
        _excludedFromRewardSupply = _excludedFromRewardSupply.sub(_balances[account]);
    }

    function excludeFromFee(address account) external onlyOwner() {
        require(!_isExcludedFromFee[account], "VIRAL: Account already excluded");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        require(_isExcludedFromFee[account], "VIRAL: Account not excluded");
        _isExcludedFromFee[account] = false;
    }

    function addMinter(address account) external onlyOwner() {
        require(!_isMinter[account], "VIRAL: Account already a minter");
        _isMinter[account] = true;
    }

    function removeMinter(address account) external onlyOwner() {
        require(_isMinter[account], "VIRAL: Account is not a minter");
        _isMinter[account] = false;
    }

    function updateTrustedForwarder(address forwarder) external onlyOwner() {
        trustedForwarder = forwarder;
    }

    function _disburse(uint256 rAmount) private {
        if(rAmount != 0) {
            uint256 newDividendPoints = rAmount.mul(pointMultiplier).div(_totalSupply.sub(_excludedFromRewardSupply));
            _totalDividendPoints = _totalDividendPoints.add(newDividendPoints);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(sender != recipient, "ERC20: transfer to self");

        _beforeTokenTransfer(sender, recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        address defaultReferrer_ = defaultReferrer;
        address rReferrer = referrerOf(recipient);

        bool isDistinctDefaultRef;
        bool isDistinctRecipientRef;

        if(defaultReferrer_ != sender && defaultReferrer_ != recipient) {
            isDistinctDefaultRef = true;
        }

        if(rReferrer != recipient && rReferrer != sender && rReferrer != defaultReferrer_) {
            isDistinctRecipientRef = true;
        }

        uint256 dAmount;
        uint256 tAmount = amount;
        if (!_isExcludedFromFee[sender]) {
            /*
            amount : input amount
            tAmount : transfer amount
            fAmount : fee amount
            rAmount : referrer amount
            vAmount : viral team amount
            dAmount : distribution amount
            */
            uint256 totalFee_ = totalFee;
            uint256 fAmount = amount.mul(totalFee_).div(100);
            tAmount = amount.sub(fAmount);

            uint256 rAmount = referralFee.mul(fAmount).div(totalFee_);
            uint256 vAmount = viralFee.mul(fAmount).div(totalFee_);
            dAmount = fAmount.sub(rAmount).sub(vAmount);

            if (isDistinctDefaultRef) {
                _updateAccount(defaultReferrer_);
            }
            if (isDistinctRecipientRef) {
                _updateAccount(rReferrer);
            }

            _balances[defaultReferrer_] = _balances[defaultReferrer_].add(vAmount);
            _balances[rReferrer] = _balances[rReferrer].add(rAmount);

            if (isDistinctDefaultRef && _isExcludedFromReward[defaultReferrer_]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(vAmount);
            }
            if (isDistinctRecipientRef && _isExcludedFromReward[rReferrer]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(rAmount);
            }
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tAmount);

        if (_isExcludedFromReward[sender]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.sub(amount);
        }
        if (_isExcludedFromReward[recipient]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.add(tAmount);
        }

        _disburse(dAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _addReferrer(address _referee, address _referrer) internal {
        require(!_isReferredYet[_referee], "VIRAL: Account already referred");

        _referrerOf[_referee] = _referrer;
        _isReferredYet[_referee] = true;

        _referralCountOf[_referrer] = _referralCountOf[_referrer].add(1);
        _totalReferrals = _totalReferrals.add(1);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        if(_isExcludedFromReward[account]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.add(amount);
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        if(_isExcludedFromReward[account]) {
            _excludedFromRewardSupply = _excludedFromRewardSupply.sub(amount);
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _dividendsOwing(address account) internal view returns (uint256) {
        if (_isExcludedFromReward[account]) {
            return 0;
        }
        uint256 newDividendPoints = _totalDividendPoints.sub(_lastDividendPoints[account]);
        return _balances[account].mul(newDividendPoints).div(pointMultiplier);
    }

    function _updateAccount(address account) internal {
        uint256 owing = _dividendsOwing(account);
        if (owing > 0) {
            _balances[account] = _balances[account].add(owing);
            if(_isExcludedFromReward[account]) {
                _excludedFromRewardSupply = _excludedFromRewardSupply.add(owing);
            }
        }
        _lastDividendPoints[account] = _totalDividendPoints;
    }

    function _beforeTokenTransfer(address from, address to) internal {
        _updateAccount(from);
        _updateAccount(to);
    }

    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}