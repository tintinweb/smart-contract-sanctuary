// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./interface/IAgreement.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Agreement is OwnableUpgradeable, IAgreement {
    /**
     * @dev router contract
     */
    address public router;

    /**
     * @dev public agreements list
     */
    agreement[] public agreements;

    /**
     * @dev agreementID => LP
     */
    mapping(uint256 => address) AgreementtoLP;

    /**
     * @dev agreementID => accepted
     */
    mapping(uint256 => bool) AcceptedAgreement;

    /**
     * @dev  agreementID => FEED
     */
    mapping(uint256 => address) AgreementtoFeed;

    /**
     * @dev only router modifier
     */
    modifier onlyRouter() {
        require(router == msg.sender, "Agreement: only router allowed");
        _;
    }

    /**
     * @dev agreement initialize start values
     * @param _router router contract
     */

    function initialize(address _router) public virtual initializer {
        __Ownable_init();
        router = _router;
    }

    function FEEDcreateAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        address feed
    ) external override onlyRouter returns (uint256 agreementId) {
        agreements.push(
            agreement(
                0,
                timePeriod,
                coreType,
                jobTaskCount,
                jobTaskCount,
                jobFund,
                jobPenalty,
                taskResultPenalty
            )
        );
        AgreementtoFeed[agreements.length - 1] = feed;
        agreementId = agreements.length - 1;
    }

    function FEEDcancelAgreement(uint256 agreementID, address feed)
        external
        override
        onlyRouter
        returns (uint256 returnAmount)
    {
        require(AgreementtoFeed[agreementID] == feed, "Sender not allowed");
        require(
            !AcceptedAgreement[agreementID],
            "Agreement: job already in work"
        );

        returnAmount =
            agreements[agreementID].jobPenalty +
            agreements[agreementID].taskResultPenalty;

        agreements[agreementID].jobPenalty = 0;
        agreements[agreementID].taskResultPenalty = 0;
    }

    function LPAcceptAgreement(address lp, uint256 agreementID)
        external
        override
        onlyRouter
        returns (uint256 jobFund)
    {
        require(
            agreementID >= 0 && agreementID < agreements.length,
            "Incorrect agreementID"
        );
        require(
            !AcceptedAgreement[agreementID],
            "Agreement job already in work"
        );
        AgreementtoLP[agreementID] = lp;
        AcceptedAgreement[agreementID] = true;
        agreements[agreementID].timeStop =
            block.timestamp +
            agreements[agreementID].timePeriod;

        jobFund = agreements[agreementID].jobFund;
    }

    function LPCloseAgreement(address lp, uint256 agreementID)
        external
        override
        onlyRouter
        returns (
            uint256 penaltyAmount,
            uint256 returntoFeed,
            address feed
        )
    {
        require(
            AgreementtoLP[agreementID] == lp && AcceptedAgreement[agreementID],
            "Agreement: incorrect or not in work"
        );
        require(
            block.timestamp > agreements[agreementID].timeStop,
            "Agreement not timed out"
        );

        feed = AgreementtoFeed[agreementID];

        AcceptedAgreement[agreementID] = false;

        // FEED not completed job, make penalty
        if (agreements[agreementID].jobConditionResolves > 0) {
            penaltyAmount =
                agreements[agreementID].jobFund +
                agreements[agreementID].jobPenalty;
            agreements[agreementID].jobFund = 0;
            agreements[agreementID].jobPenalty = 0;
        }
        // Return taskResultPenalty+jobPenalty to FEED
        if (
            agreements[agreementID].taskResultPenalty +
                agreements[agreementID].jobPenalty >
            0
        ) {
            returntoFeed =
                agreements[agreementID].taskResultPenalty +
                agreements[agreementID].jobPenalty;
            agreements[agreementID].taskResultPenalty = 0;
            agreements[agreementID].jobPenalty = 0;
        }
    }

    function resolveCondition(uint256 inAgreement)
        external
        override
        onlyRouter
        returns (uint128 _profit)
    {
        agreement storage _agreement = agreements[inAgreement];
        _profit = _agreement.jobFund / _agreement.jobConditionResolves;
        _agreement.jobFund -= _profit;
        _agreement.jobConditionResolves--;
    }

    function getAgreementsLength()
        external
        view
        override
        returns (uint256 agreementsLength)
    {
        return agreements.length;
    }

    function getAgreementData(uint256 agreementID)
        external
        view
        override
        returns (agreement memory)
    {
        return agreements[agreementID];
    }

    function getAgreementtoLP(uint256 agreementID)
        external
        view
        override
        returns (address lp)
    {
        return AgreementtoLP[agreementID];
    }

    function getAgreementtoFEED(uint256 agreementID)
        external
        view
        override
        returns (address feed)
    {
        return AgreementtoFeed[agreementID];
    }

    function isAgreementAccepted(uint256 agreementID)
        external
        view
        override
        returns (bool accepted)
    {
        return AcceptedAgreement[agreementID];
    }

    function getJobResultPenalty(uint256 agreementID)
        external
        view
        override
        returns (uint256 jobResultPenalty)
    {
        jobResultPenalty =
            agreements[agreementID].taskResultPenalty /
            agreements[agreementID].jobs;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IAgreement {
    /**
     * @dev LP <-> FEED agreement job details
     * @param timeStop - stop data, =0 for inactive agreement
     * @param timePeriod - latency
     * @param coreType - core type
     * @param jobConditionResolves - number of condition resolves rest in job
     * @param jobFund - amount of full job payment, supplied by LP owner
     * @param jobSecurity - job security, supplied by FEED provider, must be > 0 for active job proposal
     * @param taskResultPenalty - whole penalty = jobs * ResultPenalty
     */

    struct agreement {
        uint256 timeStop;
        uint32 timePeriod;
        uint32 coreType;
        uint32 jobs;
        uint32 jobConditionResolves;
        uint128 jobFund;
        uint128 jobPenalty;
        uint128 taskResultPenalty;
    }

    function FEEDcreateAgreement(
        uint32 timePeriod,
        uint32 coreType,
        uint32 jobTaskCount,
        uint128 jobFund,
        uint128 jobPenalty,
        uint128 taskResultPenalty,
        address feed
    ) external returns (uint256 agreementId);

    function FEEDcancelAgreement(uint256 agreementID, address feed)
        external
        returns (uint256 returnAmount);

    function LPAcceptAgreement(address lp, uint256 agreementID)
        external
        returns (uint256 jobFund);

    function LPCloseAgreement(address lp, uint256 agreementID)
        external
        returns (
            uint256 penaltyAmount,
            uint256 returntoFeed,
            address feed
        );

    function resolveCondition(uint256 inAgreement)
        external
        returns (uint128 _profit);

    function getAgreementsLength()
        external
        view
        returns (uint256 agreementsLength);

    function getAgreementData(uint256 agreementID)
        external
        view
        returns (agreement memory);

    function getAgreementtoLP(uint256 agreementID)
        external
        view
        returns (address lp);

    function getAgreementtoFEED(uint256 agreementID)
        external
        view
        returns (address feed);

    function isAgreementAccepted(uint256 agreementID)
        external
        view
        returns (bool accepted);

    function getJobResultPenalty(uint256 agreementID)
        external
        view
        returns (uint256 jobResultPenalty);
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}