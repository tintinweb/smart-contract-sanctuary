// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
//-------------------------|| UnityFund.finance ||----------------------------\\
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\/\/\/\\//\\//\\//\\//\\//\\//\\/\/\/\/\/\/\/\/\/\/\\\
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

import '../libraries/IERC20.sol';
import '../libraries/SafeMath.sol';

contract UnityPresale {

    using SafeMath for uint256;

    mapping(address => uint256) public allocations;

    uint8 decimals;
    uint256 public purchaseRate; // 0.1 BNB = 400000 UNITY
    uint256 public remainingAllocation; // In whole UNITY
    uint256 public remainingToCollect;
    bool public presaleActive;
    address payable private BNBreceiver;
    address payable private owner;

    IERC20 public unityToken;

    modifier onlyNotActive() {
        require(presaleActive == false, "The presale is still active and so you cant collect your Unity tokens yet.");
        _;
    }

    // Allocation Purchase Protection

    bool allocationPurchaseOccupied;

    modifier paymentModifiers() {
        // BNB: 10000000 0.1, 100000000 1, 1000000 0.1; ETH: 100000000000000000, 1000000000000000000, 100000000000000000
        require(presaleActive == true, "The presale is no longer active and all presale tokens have been sold.");
        require(msg.value >= 100000000000000000 && msg.value <= 1000000000000000000, "Min Purchase: 0.1 BNB, Max Purchase: 1 BNB");
        require(allocationPurchaseOccupied = false, "Someone else is buying UNITY tokens right now, please try again in a few minutes.");
        require(msg.value % 100000000000000000 == 0, "Only purchases divisible by 0.1 BNB can be made. Contact the team with this error msg.");
        _;
    }

    modifier lockTheAllocationPurchase() {
        allocationPurchaseOccupied = true;
        _;
        allocationPurchaseOccupied = false;
    }

    //;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this.");
        _;
    }

    event purchaseMade (
        address buyer,
        uint256 amountUNITY,
        uint256 amountBNB
    );

    event allocationCollected (
        address collector,
        uint256 amountUNITY
    );

    constructor (uint256 rate, uint256 startingAllocation, bool startPresale, address payable _BNBreceiver, address tokenAddress) {
        purchaseRate = rate; // 4,000,000 (0.1 BNB = 400,000)
        remainingAllocation = startingAllocation; // 400,000,000 UNITY in whole UNITY
        presaleActive = startPresale;
        BNBreceiver = _BNBreceiver;
        owner = payable(msg.sender);
        unityToken = IERC20(tokenAddress);
        allocationPurchaseOccupied = false;
        decimals = 9;
    }

    function getDecimalUnity(uint256 wholeUnity) private view returns(uint256) {
        return wholeUnity * (10 ** decimals);
    }
    
    function withdrawOutstanding(uint256 amount) public onlyOwner {
        unityToken.transfer(owner, getDecimalUnity(amount));

        emit allocationCollected(owner, amount);
    }

    function buyUnity() public payable paymentModifiers {
        allocationPurchase(payable(msg.sender), msg.value); // BNB in: BNB amount * 10**8
    }

    function allocationPurchase(address payable buyer, uint256 purchaseBNB) private lockTheAllocationPurchase {
        uint256 desiredPurchase = (purchaseBNB.div(1000000)).mul(purchaseRate); // 10000000 / 1000000 * 400000 = 4,000,000 per BNB

        if (desiredPurchase <= remainingAllocation) {
            completeFullPurchase(buyer, desiredPurchase, purchaseBNB);
        } else {
            uint256 refundedBNB = completePartialPurchase(buyer, desiredPurchase, purchaseBNB);
            buyer.transfer(refundedBNB);
            presaleActive = false;
        }
    }

    function completeFullPurchase(address payable _buyer, uint256 purchaseAmount, uint256 _purchaseBNB) private {
        executePurchase(_buyer, purchaseAmount, _purchaseBNB);
    }

    function completePartialPurchase(address payable _buyer, uint256 desiredPurchase, uint256 totalBNB) private returns(uint256) {
        uint256 purchaseAmount = remainingAllocation;
        uint256 unpurchasedUNITY = desiredPurchase.sub(purchaseAmount);
        uint256 unpurchasedBNB = (unpurchasedUNITY.div(purchaseRate)).mul(1000000);
        uint256 purchaseBNB = totalBNB.sub(unpurchasedBNB);
        executePurchase(_buyer, purchaseAmount, purchaseBNB);
        return unpurchasedBNB;
    }

    function executePurchase(address payable __buyer, uint256 amountUNITY, uint256 amountBNB) private {
        require((amountBNB.div(1000000)).mul(purchaseRate) == amountUNITY, "the purchase exchange rate is wrong");

        if (allocations[__buyer] == 0) {
            allocations[__buyer] = amountUNITY;
        } else {
            allocations[__buyer] += amountUNITY;
        }
        
        remainingAllocation -= amountUNITY;
        BNBreceiver.transfer(amountBNB); // Is the BNB paid into the contract already at this point?
        remainingToCollect += amountUNITY;

        emit purchaseMade(__buyer, amountUNITY, amountBNB);

    }

    function collectTokens() public onlyNotActive {
        require(allocations[msg.sender] != 0, "You have no tokens to collect");

        unityToken.transfer(msg.sender, getDecimalUnity(allocations[msg.sender]));

        emit allocationCollected(msg.sender, allocations[msg.sender]);

        remainingToCollect -= allocations[msg.sender];
        allocations[msg.sender] = 0;

    }

}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

