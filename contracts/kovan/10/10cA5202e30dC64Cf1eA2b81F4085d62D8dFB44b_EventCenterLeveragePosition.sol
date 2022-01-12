// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AccountCenterInterface} from "../interfaces/IAccountCenter.sol";

contract EventCenterLeveragePosition is Ownable {

    mapping(address => uint256) public weight; // token wieght

    uint256 public epochStart;
    uint256 public epochEnd;
    uint256 public epochInterval = 14 days;

    event CreateAccount(address EOA, address account);

    event UseFlashLoanForLeverage(
        address indexed EOA,
        address indexed account,
        address token,
        uint256 amount
    );

    event OpenLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    );

    event OpenShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    );

    event CloseLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    );

    event CloseShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    );

    event AddMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken
    );

    event removeMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken
    );

    event AddPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore
    );

    event SubPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore
    );

    address internal accountCenter;

    address internal accountant;

    modifier onlyAccountType1() {
        require(accountCenter != address(0), "CHFRY: accountCenter not setup");
        require(
            AccountCenterInterface(accountCenter).isSmartAccountofTypeN(msg.sender, 1) ||
            AccountCenterInterface(accountCenter).isSmartAccountofTypeN(msg.sender, 2) ||
            AccountCenterInterface(accountCenter).isSmartAccountofTypeN(msg.sender, 3) ||
            msg.sender == accountant,
            "CHFRY: only SmartAccount could emit Event in EventCenter"
        );
        _;
    }

    constructor(address _accountCenter) {
        accountCenter = _accountCenter;
    }

    function setEpochInterval(uint256 _epochInterval) external onlyOwner {
        epochInterval = _epochInterval;
    }

    function setAccountant(address _accountant) external onlyOwner {
        accountant = _accountant;
    }

    function startEpoch() external onlyOwner {
        epochStart = block.timestamp;
        epochEnd = epochStart + epochInterval;
    }

    function setWeight(address _token, uint256 _weight) external onlyOwner {
        require(_token != address(0), "CHFRY: address shoud not be 0");

        weight[_token] = _weight;
    }

    function emitCreateAccountEvent(address EOA, address account)
        external
        onlyAccountType1
    {
        emit CreateAccount(EOA, account);
    }

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external
        onlyAccountType1
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit UseFlashLoanForLeverage(EOA, account, token, amount);
    }

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountType1 {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 1);
        emit OpenLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );

    }

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountType1 {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 1);
        emit CloseLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountRepay,
            unitAmt,
            rateMode
        );
    }

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountType1 {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 2);
        emit OpenShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );
    }

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountType1 {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 4);
        emit CloseShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountWithDraw,
            unitAmt,
            rateMode
        );
    }

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountType1 {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit AddMargin(EOA, account, leverageToken, amountLeverageToken);
    }

    function emitRemoveMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountType1 {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit AddMargin(EOA, account, leverageToken, amountLeverageToken);
    }

    function addScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;
        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);
        require(notOverflow == true, "CHFRY: You are so rich!");
        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        emit AddPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore
        );
    }

    function subScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;
        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);

        require(notOverflow == true, "CHFRY: You are so rich!");
        
        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        emit SubPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account) external view returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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