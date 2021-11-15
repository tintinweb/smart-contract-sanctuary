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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IFactory {
    enum GENERATOR {
        AUDITOR,
        REQUEST,
        AUDIT
    }

    function getGenerator(GENERATOR _generator) external view returns (address);

    function getAuditByContractAddress(address _contract)
        external
        view
        returns (address);

    function doesRequestExist(address _request) external view returns (bool);

    function doesAuditorExist(address _auditor) external view returns (bool);

    function registerAudit(address _audit, address[] memory _contracts)
        external;

    function registerAuditor(address _auditor) external;

    function unregisterAuditor(bool _isCertified) external;

    function registerRequest(address _request) external;

    function unregisterRequest() external;

    function updateCertifiedAuditor(bool _isCertified) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface ISettings {
  enum MAX_LENGTH {
      COMPANY_NAME,
      URL,
      CONTRACTS
  }

  function getMaxLength(MAX_LENGTH _index) external view returns (uint256);

  function getAuditDeliveryFeesPercentage() external view returns (uint256);

  function getAdminAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ISettings.sol";
import "./IFactory.sol";

interface IAuditor {
    function getOwner() external returns (address);
}

interface IAuditGenerator {
    function createAudit(
        address _auditor,
        address _client,
        address[] calldata _contracts,
        uint256[3] calldata _issues,
        string calldata _auditUrl
    ) external;
}

contract Request is ReentrancyGuard {
    using SafeMath for uint256;

    IFactory factory;
    ISettings settings;
    IERC20 wusd;
    IAuditGenerator auditGenerator;
    IAuditor auditorInstance;

    address public requestGenerator;

    enum PROPOSAL_STATUS {
        PENDING,
        ANSWERED,
        ACCEPTED,
        DELIVERED,
        CANCELED
    }

    struct Proposal {
        PROPOSAL_STATUS status;
        uint256 price;
        uint256 acceptanceDate;
        uint256 deliveryDate;
    }

    Proposal public proposal;
    address public auditor;
    address public client;
    address[] public contracts;

    constructor(
        address _factory,
        address _settings,
        address _wusd
    ) {
        factory = IFactory(_factory);
        auditGenerator = IAuditGenerator(
            factory.getGenerator(IFactory.GENERATOR.AUDIT)
        );
        settings = ISettings(_settings);
        wusd = IERC20(_wusd);
    }

    modifier onlyAuditorOwner() {
        require(msg.sender == auditorInstance.getOwner(), "NOT AUDITOR OWNER");
        _;
    }

    function auditorAnswersRequest(
        uint256 _acceptanceDate,
        uint256 _deliveryDate,
        uint256 _price
    ) external onlyAuditorOwner {
        require(
            proposal.status == PROPOSAL_STATUS.PENDING,
            "THIS REQUEST IS NOT PENDING"
        );

        proposal.status = PROPOSAL_STATUS.ANSWERED;
        proposal.acceptanceDate = _acceptanceDate;
        proposal.deliveryDate = _deliveryDate;
        proposal.price = _price;
    }

    modifier onlyClient() {
        require(msg.sender == client, "NOT CLIENT");
        _;
    }

    function clientAcceptsProposal() external onlyClient {
        require(
            proposal.status == PROPOSAL_STATUS.ANSWERED,
            "THIS REQUEST IS NOT ANSWERED"
        );
        require(
            block.timestamp < proposal.acceptanceDate,
            "TOO LATE TO ACCEPT"
        );

        proposal.status = PROPOSAL_STATUS.ACCEPTED;

        TransferHelper.safeTransferFrom(
            address(wusd),
            msg.sender,
            address(this),
            proposal.price
        );
    }

    function auditorDeliversAudit(
        uint256[3] calldata _issues,
        string memory _auditUrl
    ) external onlyAuditorOwner nonReentrant {
        require(
            proposal.status == PROPOSAL_STATUS.ACCEPTED,
            "THIS REQUEST IS NOT ACCEPTED"
        );
        require(
            bytes(_auditUrl).length <=
                settings.getMaxLength(ISettings.MAX_LENGTH.URL),
            "URL IS TOO LONG"
        );

        proposal.status = PROPOSAL_STATUS.DELIVERED;

        address auditorOwner = auditorInstance.getOwner();

        auditGenerator.createAudit(
            auditor,
            client,
            contracts,
            _issues,
            _auditUrl
        );

        address admin = settings.getAdminAddress();

        uint256 auditDeliveryFeesPercentage = settings
        .getAuditDeliveryFeesPercentage();
        uint256 ownerPayment = proposal.price;

        if (auditDeliveryFeesPercentage > 0) {
            uint256 adminPayment = ownerPayment
            .mul(auditDeliveryFeesPercentage)
            .div(100);
            ownerPayment = ownerPayment.sub(adminPayment);

            TransferHelper.safeApprove(address(wusd), admin, adminPayment);
            TransferHelper.safeTransfer(address(wusd), admin, adminPayment);
        }

        TransferHelper.safeApprove(address(wusd), auditorOwner, ownerPayment);
        TransferHelper.safeTransfer(address(wusd), auditorOwner, ownerPayment);
        factory.unregisterRequest();
    }

    function clientWithdrawsAfterDeadline() external onlyClient {
        require(proposal.status == PROPOSAL_STATUS.ACCEPTED, "CANNOT WITHDRAW");
        require(
            block.timestamp >= proposal.deliveryDate,
            "DEADLINE IS NOT MET"
        );

        proposal.status = PROPOSAL_STATUS.CANCELED;
        TransferHelper.safeApprove(
            address(wusd),
            address(this),
            proposal.price
        );

        TransferHelper.safeTransferFrom(
            address(wusd),
            address(this),
            address(msg.sender),
            proposal.price
        );

        proposal.status = PROPOSAL_STATUS.CANCELED;
        factory.unregisterRequest();
    }

    function getContracts() external view returns (address[] memory) {
        return (contracts);
    }

    function init(
        address _auditor,
        address _client,
        address[] memory _contracts
    ) external {
        require(msg.sender == factory.getGenerator(IFactory.GENERATOR.REQUEST));
        requestGenerator = msg.sender;
        proposal.status = PROPOSAL_STATUS.PENDING;
        auditor = _auditor;
        auditorInstance = IAuditor(auditor);
        client = _client;
        contracts = _contracts;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Request.sol";
import "./ISettings.sol";
import "./IFactory.sol";

contract RequestGenerator {
    ISettings settings;
    IFactory factory;

    address public wusd;

    constructor(
        address _factory,
        address _settings,
        address _wusd
    ) {
        factory = IFactory(_factory);
        settings = ISettings(_settings);
        wusd = _wusd;
    }

    function createRequest(
        address _client,
        address[] memory _contracts
    ) external {
        require(factory.doesAuditorExist(msg.sender));

        Request newRequest = new Request(
            address(factory),
            address(settings),
            wusd
        );

        newRequest.init(msg.sender, _client, _contracts);

        factory.registerRequest(address(newRequest));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

