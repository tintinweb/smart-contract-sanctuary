// Copyright © 2021 Moon Bear Finance Ltd. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
// ░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░
// ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████▓████▓▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒░░░░░░
// ░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▓███████████▓▓▒▒▒▒▒▒▒░░░░░▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒█████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▓▓▓███████████████▓▒▒▒▒▒▒░▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓███████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒░░░░▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒█████████▓▓█████████▓▓▓█████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒██████▓▒▒▒▒▓█████▓▓▒▒▒▓█████▒▒▒▒▒▒▒▒▒▒░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒██████▓▓▓▓▓██████▓▓▓▓▓▓█████▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░░░░▒▓▓▓██████████████████████████████████▓▓▓▒▒░░░░░░░░
// ░░░░░░░░░░▓██████████████████████████████████████▓░░░░░░░░░░
// ░░░░░░░░░░░▒▓██████████████████████████████████▓▒░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▓████████████████████████████▓▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▒▒▓▓████████████████████▓▓▒▒░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓██████▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonBearTokenSale is Ownable {
    using SafeERC20 for IERC20;

    uint32 public constant week = 7 days;
    uint256 public constant PRICE_DECIMAL = 1e9;

    uint256 public softcap;
    uint256 public salePrice;
    uint256 public cap;
    address public token;
    uint256 public tokensSold;
    uint256 public tokenSaleDuration;
    uint256 public startTime;

    bool public released = false;
    address payable public wallet;

    bool public whitelistEnabled = true;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _purchasedTokens;
    mapping(address => bool) private _whitelist;

    uint256 public maxBuyAmount;
    uint256 private totalBNB;

    struct ReleaseScheduleItem {
        uint256 percent;
        uint256 unlockTime;
    }

    ReleaseScheduleItem[] public releaseSchedule;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokensWithdrawn(address indexed withdrawer, uint256 amount);
    event StartChanged(uint256 newStartDate);
    event TokenSaleDurationChanged(uint256 newDuration);
    event WhitelistEnabled(bool enabled);

    modifier ongoingSale() {
        require(
            block.timestamp >= startTime && block.timestamp <= tokenSaleEndTime(),
            "Sale: not selling now"
        );
        _;
    }

    modifier afterRelease() {
        require(released || block.timestamp >= tokenSaleEndTime() + 3 days, "Sale: not released yet");
        _;
    }

    modifier softcapReached() {
        require(isSoftcapReached(), "Sale: softcap not reached");
        _;
    }

    /**
     * @notice Create token sale contracts with initial params. After creation init functions must be called
     * @param _token Address of token to sale
     * @param _softcap minium BNB to finish the sale
     * @param _salePrice BNB per token, multiplied by PRICE_DECIMAL
     * @param _startTime Token sale start time in unix seconds
     * @param _cap Amount of tokens to sell
     * @param _tokenSaleDuration token sale duration
     */
    constructor(
        address _token,
        uint256 _softcap,
        uint256 _salePrice,
        uint256 _startTime,
        uint256 _cap,
        uint256 _tokenSaleDuration
    ) {
        require(_startTime > block.timestamp, "invalid start time");
        require(_token != address(0), "zero token address");
        require(_softcap > 0, "soft cap must not be zero");
        require(_salePrice > 0, "sale price must not be zero");
        require(_cap > 0, "cap not be zero");
        require(_tokenSaleDuration > 0, "sale duration not be zero");
        require(
            (convertTo18Decimal(_cap) * _salePrice) / PRICE_DECIMAL >= _softcap,
            "hardcap must be bigger or equal to softcap"
        ); // TODO: Double confirme this

        token = _token;
        softcap = _softcap;
        cap = _cap;
        salePrice = _salePrice;
        startTime = _startTime;
        tokenSaleDuration = _tokenSaleDuration;
        wallet = payable(msg.sender);

        maxBuyAmount = calculatePurchaseAmount(50 ether);

        //vesting config
        _setReleaseSchedule();
    }

    /**
     * @notice Token sale end time in unix seconds
     */
    function tokenSaleEndTime() public view returns (uint256) {
        return startTime + tokenSaleDuration;
    }

    /**
     * set releaseSchedule
     */
    function _setReleaseSchedule() private {
        uint256 saleEnd = tokenSaleEndTime();

        if (releaseSchedule.length == 0) {
            releaseSchedule.push(ReleaseScheduleItem(20, saleEnd));
            releaseSchedule.push(ReleaseScheduleItem(30, saleEnd + week));
            releaseSchedule.push(ReleaseScheduleItem(40, saleEnd + 2 * week));
            releaseSchedule.push(ReleaseScheduleItem(50, saleEnd + 3 * week));
            releaseSchedule.push(ReleaseScheduleItem(60, saleEnd + 4 * week));
            releaseSchedule.push(ReleaseScheduleItem(70, saleEnd + 5 * week));
            releaseSchedule.push(ReleaseScheduleItem(80, saleEnd + 6 * week));
            releaseSchedule.push(ReleaseScheduleItem(90, saleEnd + 7 * week));
            releaseSchedule.push(ReleaseScheduleItem(100, saleEnd + 8 * week));
        } else {
            releaseSchedule[0].unlockTime = saleEnd;
            releaseSchedule[1].unlockTime = saleEnd + week;
            releaseSchedule[2].unlockTime = saleEnd + 2 * week;
            releaseSchedule[3].unlockTime = saleEnd + 3 * week;
            releaseSchedule[4].unlockTime = saleEnd + 4 * week;
            releaseSchedule[5].unlockTime = saleEnd + 5 * week;
            releaseSchedule[6].unlockTime = saleEnd + 6 * week;
            releaseSchedule[7].unlockTime = saleEnd + 7 * week;
            releaseSchedule[8].unlockTime = saleEnd + 8 * week;
        }
    }

    /**
     * @notice Buy tokens
     * @param beneficiary Address of account token can be withdrawn to after sale
     */
    function buyTokens(address beneficiary) external payable ongoingSale returns (bool) {
        require(beneficiary != address(0), "Sale: to the zero address");
        require(!whitelistEnabled || _whitelist[msg.sender], "Sale: whitelist");

        // 0.05 interval
        require(msg.value % (5 * 1e16) == 0, "Amount should be 0.05 BNB interval");

        uint256 amount = calculatePurchaseAmount(msg.value);
        require(amount != 0, "Sale: amount is 0");
        require(amount + tokensSold <= cap, "Sale: cap reached");

        totalBNB = totalBNB + msg.value;
        tokensSold = tokensSold + amount;
        _balances[beneficiary] = _balances[beneficiary] + amount;
        require(_balances[beneficiary] <= maxBuyAmount, "Sale: amount exceeds max");
        _purchasedTokens[beneficiary] = _purchasedTokens[beneficiary] + amount;

        emit TokensPurchased(_msgSender(), beneficiary, msg.value, amount);
        return true;
    }

    function convertTo18Decimal(uint256 amount) private pure returns (uint256) {
        return amount * 1e9;
    }

    function convertFrom18Decimal(uint256 amount) private pure returns (uint256) {
        return amount / 1e9;
    }

    /**
     * @notice Calculates amount of tokens to be bought for given bnb
     * @param purchaseAmountWei amount in wei
     * @return amount of tokens that can be bought for given purchaseAmountInWei
     */
    function calculatePurchaseAmount(uint256 purchaseAmountWei) public view returns (uint256) {
        return convertFrom18Decimal((purchaseAmountWei * PRICE_DECIMAL) / salePrice);
    }

    /**
     * @notice Amount of tokens that can be withdrawn (locked and unlocked)
     * @param account Address of account to query balance
     * @return the balance of purchased tokens of an account.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @return the amount of purchased tokens of an account.
     */
    function tokensPurchased(address account) public view returns (uint256) {
        return _purchasedTokens[account];
    }

    /**
     * @return true if the address in whitelist
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function isSoftcapReached() public view returns (bool) {
        return totalBNB >= softcap;
    }

    /**
     * @notice Withdraw bought tokens
     */
    function withdrawTokens(uint256 amount) public afterRelease softcapReached {
        require(amount <= _balances[msg.sender], "Sale: insufficient balance");
        require(amount <= withdrawableBalance(msg.sender), "Sale: locked");
        _balances[msg.sender] = _balances[msg.sender] - amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit TokensWithdrawn(msg.sender, amount);
    }

    /**
     * @notice amount of tokens available to withdraw at current time
     * @param user Address of account
     */
    function withdrawableBalance(address user) public view returns (uint256) {
        uint256 purchasedAmount = _purchasedTokens[user];

        for (uint256 i = releaseSchedule.length; i > 0; i--) {
            if (releaseSchedule[i - 1].unlockTime < block.timestamp) {
                uint256 lockedAmount = (purchasedAmount * (100 - releaseSchedule[i - 1].percent)) / 100;
                return _balances[user] - lockedAmount;
            }
        }
        return 0; //fallback value
    }

    function withdrawBNBWhenFailed() public afterRelease {
        require(isSoftcapReached() == false, "Sale: not failed");
        require(_balances[msg.sender] > 0, "Sale: nothing to withdraw");

        uint256 bnbAmount = (convertTo18Decimal(_balances[msg.sender]) * salePrice) / PRICE_DECIMAL;
        _balances[msg.sender] = 0;

        (bool res, ) = payable(msg.sender).call{ value: bnbAmount }("");
        require(res, "transfer failed");
    }

    function enableWhitelist(bool _enabled) public onlyOwner {
        require(whitelistEnabled != _enabled, "Sale: already enabled or disabled");
        whitelistEnabled = _enabled;
        emit WhitelistEnabled(_enabled);
    }

    function changeSaleStart(uint256 _startTime) public onlyOwner {
        require(block.timestamp < startTime, "Sale: started");
        startTime = _startTime;
        emit StartChanged(startTime);
    }

    function changeSaleDuration(uint256 _saleDuration) public onlyOwner {
        require(block.timestamp <= tokenSaleEndTime(), "Sale: ended");
        tokenSaleDuration = _saleDuration;
        emit TokenSaleDurationChanged(startTime);
    }

    function addToWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint256 i = 0; i < _accounts.length; ++i) {
            if (!_whitelist[_accounts[i]]) {
                _whitelist[_accounts[i]] = true;
            }
        }
    }

    function release() public onlyOwner {
        require(block.timestamp >= tokenSaleEndTime(), "Sale: not ended");
        require(IERC20(token).balanceOf(address(this)) >= cap, "Sale: not enough token to release");

        released = true;
    }

    function withdrawBnb() external onlyOwner {
        withdrawBnbPartially(address(this).balance);
    }

    function withdrawNotSoldTokens() external onlyOwner {
        require(block.timestamp >= tokenSaleEndTime(), "Sale: only after sale");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(wallet, balance - tokensSold);
    }

    /**
     * Withdraw bnb from the sale contract after sale is ended
     * param amount amount to withdraw
     */
    function withdrawBnbPartially(uint256 amount) public onlyOwner {
        (bool res, ) = wallet.call{ value: amount }("");
        require(res, "transfer failed");
    }

    function changeWallet(address _to) public onlyOwner {
        require(_to != address(0), "change wallet: to the zero address");
        wallet = payable(_to);
    }

    /**
     * Update EndTime
     * _endTime == 0 : close with current block.timestamp
     */
    function setEndTime(uint256 _endTime) external onlyOwner {
        if (_endTime == 0) {
            require(block.timestamp > startTime, "You can't end");

            tokenSaleDuration = block.timestamp - startTime;
        } else {
            require(block.timestamp < _endTime, "EndTime can't be past time");
            require(_endTime > startTime, "endTime should be greater than startTime");

            tokenSaleDuration = _endTime - startTime;
        }

        _setReleaseSchedule();
    }

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "zero token address");

        token = _token;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

