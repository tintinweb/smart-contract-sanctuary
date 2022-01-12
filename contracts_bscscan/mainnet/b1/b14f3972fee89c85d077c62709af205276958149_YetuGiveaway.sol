/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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

/**
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
        return msg.data;
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IMansaMusa {
    function enterStaking(uint256 _amount) external;

    function yetuPerBlock() external view returns (uint256);

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingYetu(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

contract YetuGiveaway is Ownable {
    using SafeMath for uint256;

    event TokenPurchase(
        address indexed purchaser,
        uint256 indexed depositedAmount,
        uint256 indexed tokenAmount,
        uint256 bonusAmount
    );

    bool public isEnded = false;

    uint256 public bnbToYetuPrice;

    IBEP20 public yetuToken =
        IBEP20(0x6652048Fa5E66ed63a0225FFd7C82e106b0Aa18b);

    IBEP20 public afrikanToken =
        IBEP20(0xA67b68633379A24E3C5d2c05E7D69977AEcDc06A);

    IMansaMusa public mansaMusa =
        IMansaMusa(0x7B0ef401EA6961b08dfE8B00Ab15Ed3318cE8Ed7);

    uint8 public currentGiveawayStage;

    uint256 public totalYetuTokens = 10000000 ether;

    uint256 public totalBNBRaised;

    uint256 public lastRewardBlock;

    uint256 public accYetuPerShare;

    uint256 public yetuStaked;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        mapping(uint256 => uint256) yetuPurchasedInStage;
    }

    mapping(address => UserInfo) public userInfo;

    mapping(uint256 => uint256) public remainingYetuInStage;
    mapping(uint256 => uint256) public minYetuPurchaseInStage;
    mapping(uint256 => uint256) public maxYetuPurchaseInStage;

    constructor(uint256 _bnbToYetuPrice) {
        currentGiveawayStage = 2;

        bnbToYetuPrice = _bnbToYetuPrice;

        remainingYetuInStage[2] = 3000000 ether;
        remainingYetuInStage[3] = 3000000 ether;
        remainingYetuInStage[4] = 4000000 ether;

        minYetuPurchaseInStage[2] = 10000 ether;
        minYetuPurchaseInStage[3] = 13000 ether;
        minYetuPurchaseInStage[4] = 15000 ether;

        maxYetuPurchaseInStage[2] = 500000 ether;
        maxYetuPurchaseInStage[3] = 600000 ether;
        maxYetuPurchaseInStage[4] = 700000 ether;
    }

    function switchToNextStage() public onlyOwner {
        require(currentGiveawayStage < 4, "Already at final stage");
        currentGiveawayStage = currentGiveawayStage + 1;
    }

    // YetuTokens Purchase
    // =========================
    receive() external payable {
        if (isEnded) {
            revert("Crowdsale Ended"); //Block Incoming BNB Deposits if Crowdsale has ended
        }
        buyYetuTokens(msg.sender);
    }

    function determineBonusAmount(uint256 _yetuPurchased)
        public
        view
        returns (uint256 _bonusAmount)
    {
        if (currentGiveawayStage == 2) {
            if (
                _yetuPurchased >= 10000 ether && _yetuPurchased <= 20000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(2).div(100);
            } else if (
                _yetuPurchased >= 20000 ether && _yetuPurchased <= 100000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(4).div(100);
            } else if (
                _yetuPurchased >= 100000 ether && _yetuPurchased <= 200000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(5).div(100);
            } else if (
                _yetuPurchased >= 200000 ether && _yetuPurchased <= 500000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(7).div(100);
            }
        } else if (currentGiveawayStage == 3) {
            if (
                _yetuPurchased >= 13000 ether && _yetuPurchased <= 20000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(2).div(100);
            } else if (
                _yetuPurchased >= 20000 ether && _yetuPurchased <= 100000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(4).div(100);
            } else if (
                _yetuPurchased >= 100000 ether && _yetuPurchased <= 200000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(5).div(100);
            } else if (
                _yetuPurchased >= 200000 ether && _yetuPurchased <= 600000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(8).div(100);
            }
        } else if (currentGiveawayStage == 4) {
            if (
                _yetuPurchased >= 15000 ether && _yetuPurchased <= 20000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(2).div(100);
            } else if (
                _yetuPurchased >= 20000 ether && _yetuPurchased <= 100000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(4).div(100);
            } else if (
                _yetuPurchased >= 100000 ether && _yetuPurchased <= 200000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(5).div(100);
            } else if (
                _yetuPurchased >= 200000 ether && _yetuPurchased <= 700000 ether
            ) {
                _bonusAmount = _yetuPurchased.mul(9).div(100);
            }
        }
    }

    function buyYetuTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0), "Invalid beneficiary");
        uint256 bnbAmount = msg.value;
        require(bnbAmount > 0, "Please Send some BNB");
        if (isEnded) {
            revert("Crowdsale Ended");
        }

        uint256 purchasedYetuTokens = bnbAmount.mul(bnbToYetuPrice);
        UserInfo storage user = userInfo[_beneficiary];
        user.yetuPurchasedInStage[currentGiveawayStage] =
            user.yetuPurchasedInStage[currentGiveawayStage] +
            purchasedYetuTokens;
        require(
            purchasedYetuTokens >= minYetuPurchaseInStage[currentGiveawayStage],
            "Purchase Amount below Minimum Stage amount"
        );
        require(
            user.yetuPurchasedInStage[currentGiveawayStage] <=
                maxYetuPurchaseInStage[currentGiveawayStage],
            "Exceeds Max Purchasing Amount for user"
        );
        if (purchasedYetuTokens > remainingYetuInStage[currentGiveawayStage]) {
            revert("Not enough Yetu Tokens in this stage");
        }
        uint256 bonusAmount = determineBonusAmount(purchasedYetuTokens);
        uint256 stakeAmount = purchasedYetuTokens.add(bonusAmount);
        _stake(_beneficiary, stakeAmount);

        totalBNBRaised = totalBNBRaised.add(bnbAmount);
        remainingYetuInStage[currentGiveawayStage] = remainingYetuInStage[
            currentGiveawayStage
        ].sub(stakeAmount);

        if (remainingYetuInStage[currentGiveawayStage] == 0) {
            currentGiveawayStage += 1;
        }
        emit TokenPurchase(
            _beneficiary,
            bnbAmount,
            purchasedYetuTokens,
            bonusAmount
        );
    }

    function updateStakingData() public {
        if (block.number <= lastRewardBlock || yetuStaked == 0) {
            return;
        }
        uint256 yetuReward = mansaMusa.pendingYetu(0, address(this));
        accYetuPerShare = accYetuPerShare.add(
            yetuReward.mul(1e12).div(yetuStaked)
        );
    }

    function _stake(address _beneficiary, uint256 _amount) internal {
        updateStakingData();
        UserInfo storage user = userInfo[_beneficiary];

        if (_amount > 0) {
            yetuToken.approve(address(mansaMusa), _amount);
            yetuStaked = yetuStaked.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        mansaMusa.enterStaking(_amount);

        if (user.amount > 0) {
            uint256 userPending = user
                .amount
                .mul(accYetuPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (userPending > 0) yetuToken.transfer(_beneficiary, userPending);
        }

        user.rewardDebt = user.amount.mul(accYetuPerShare).div(1e12);
    }

    function leaveStaking(uint256 _amount) external {
        updateStakingData();
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Invalid withdraw");

        mansaMusa.leaveStaking(_amount);

        uint256 userPending = user.amount.mul(accYetuPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (userPending > 0) yetuToken.transfer(msg.sender, userPending);

        if (_amount > 0) {
            yetuStaked = yetuStaked.sub(_amount);
            user.amount = user.amount.sub(_amount);
            yetuToken.transfer(msg.sender, _amount);
        }

        user.rewardDebt = user.amount.mul(accYetuPerShare).div(1e12);
    }

    function endGiveaway() public onlyOwner {
        require(!isEnded, "Giveaway already finalized");
        isEnded = true;
    }

    function updateBNBtoYetuPrice(uint256 _price) external onlyOwner {
        require(_price != 0, "Price can't be zero");
        bnbToYetuPrice = _price;
    }

    function withdrawBNB(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient Funds");
        payable(owner()).transfer(amount);
    }

    function totalRemainingYetu() public view returns (uint256 _total) {
        for (uint8 i = 2; i <= 4; i++) {
            _total += remainingYetuInStage[i];
        }
    }

    function withdrawTokens(IBEP20 _token, uint256 _amount) public onlyOwner {
        require(_amount <= totalRemainingYetu(), "Insufficient Funds");
        _token.transfer(owner(), _amount);
    }
}