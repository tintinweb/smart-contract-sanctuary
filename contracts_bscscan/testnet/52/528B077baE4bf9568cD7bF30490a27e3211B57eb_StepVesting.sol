// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StepVesting is Ownable {
    event ReceiverChanged(address oldWallet, address newWallet);

    // token to claim
    IERC20 public immutable token;

    // cliff & vesting config
    uint256 public immutable started;
    uint256 public immutable cliffDuration;
    uint256 public immutable stepDuration;
    uint256 public immutable cliffAmount;
    uint256 public immutable stepAmount;
    uint256 public immutable numOfSteps;
    address public receiver;

    // claimed amount
    uint256 public claimed;

    // address tha can clearExceedingFunds
    address public deployer;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "access denied");
        _;
    }

    modifier onlyReceiver() {
        require(msg.sender == receiver, "access denied");
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _started,
        uint256 _cliffDuration,
        uint256 _stepDuration,
        uint256 _cliffAmount,
        uint256 _stepAmount,
        uint256 _numOfSteps,
        address _receiver
    ) {
        deployer = msg.sender;

        token = _token;
        started = _started;
        cliffDuration = _cliffDuration;
        stepDuration = _stepDuration;
        cliffAmount = _cliffAmount;
        stepAmount = _stepAmount;
        numOfSteps = _numOfSteps;
        setReceiver(_receiver);
    }

    function available() public view returns (uint256) {
        return claimable() - claimed;
    }

    function claimable() public view returns (uint256) {
        if (block.timestamp < (started + cliffDuration)) {
            return 0;
        }

        uint256 passedSinceCliff = block.timestamp - (started + cliffDuration);
        uint256 stepsPassed = Math.min(numOfSteps, (passedSinceCliff / stepDuration));
        return cliffAmount + (stepsPassed * stepAmount);
    }

    function claim() external onlyReceiver {
        uint256 amount = available();
        require(amount > 0, "Nothing to claim");

        claimed = claimed + amount;
        
        token.transfer(msg.sender, amount);
    }

    /**
     * ADMIN FUNCTIONS
     */

    function setReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0), "Receiver is zero address");
        emit ReceiverChanged(receiver, _receiver);
        receiver = _receiver;
    }

    /**
     * @dev allows withdrawing any token that is stuck in the contract
     * @param tokenAddress addres of the token we are withdrawing
     */
    function emergencyWithdrawToken(address tokenAddress) external onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddress);

        uint256 withdrawBalance = tokenContract.balanceOf(address(this));

        require(withdrawBalance > 0, "No balance for this token");

        tokenContract.transfer(msg.sender, withdrawBalance);
    }

    /**
     * @dev Remove funds stuck after the vesting is completed
     */
    function clearExceedingFunds() external onlyDeployer {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 exceedingFunds = (contractBalance + claimed) - totalVesting();

        require(exceedingFunds > 0, "No exceeding funds");

        token.transfer(msg.sender, exceedingFunds);
    }

    /**
     * @dev Delete deployer access to clearExceedingFunds
     */
    function deleteDeployer() external {
        require(msg.sender == owner() || msg.sender == deployer, "access denied");
        deployer = address(0);
    }

    /**
     * @dev Change deployer address
     */
    function changeDeployer(address newDeployer) external {
        require(msg.sender == owner() || msg.sender == deployer, "access denied");
        deployer = newDeployer;
    }

    /**
     * VIEWS FOR BETTER OBSERVABILITY
     */

    function totalVesting() public view returns (uint256) {
        return cliffAmount + (stepAmount * numOfSteps);
    }

    function cliffEnds() external view returns (uint256) {
        return started + cliffDuration;
    }

    function vestingEnds() external view returns (uint256) {
        return started + cliffDuration + (stepDuration * numOfSteps);
    }

    function nextClaim() external view returns (uint256) {
        if (block.timestamp < (started + cliffDuration)) {
            if (cliffAmount > 0) {
                return started + cliffDuration;
            } else {
                return started + cliffDuration + stepDuration;
            }
        }

        uint256 claimedWithoutCliff = claimed - cliffAmount;
        uint256 claimedPeriods = claimedWithoutCliff / stepAmount;
        uint256 lastClaimeableDate = started + cliffDuration + (claimedPeriods * stepDuration);

        return lastClaimeableDate + stepDuration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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