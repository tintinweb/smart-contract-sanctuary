// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IFees.sol";
import "./interfaces/IMeTokenRegistry.sol";
import "./interfaces/IMeToken.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IFoundry.sol";

import "./libs/WeightedAverage.sol";
import "./libs/Details.sol";

contract Foundry is IFoundry, Ownable, Initializable {
    uint256 public constant PRECISION = 10**18;

    IHub public hub;
    IFees public fees;
    IMeTokenRegistry public meTokenRegistry;

    function initialize(
        address _hub,
        address _fees,
        address _meTokenRegistry
    ) external onlyOwner initializer {
        hub = IHub(_hub);
        fees = IFees(_fees);
        meTokenRegistry = IMeTokenRegistry(_meTokenRegistry);
    }

    function mint(
        address _meToken,
        uint256 _tokensDeposited,
        address _recipient
    ) external override {
        Details.MeTokenDetails memory meTokenDetails = meTokenRegistry
            .getDetails(_meToken);
        Details.HubDetails memory hubDetails = hub.getDetails(
            meTokenDetails.hubId
        );
        require(hubDetails.active, "Hub inactive");

        uint256 fee = (_tokensDeposited * fees.mintFee()) / PRECISION;
        uint256 tokensDepositedAfterFees = _tokensDeposited - fee;

        if (hubDetails.updating && block.timestamp > hubDetails.endTime) {
            // Finish updating curve
            hub.finishUpdate(meTokenDetails.hubId);
            if (hubDetails.curveDetails) {
                // Finish updating curve
                ICurve(hubDetails.curve).finishUpdate(meTokenDetails.hubId);
            }
        }

        uint256 meTokensMinted = calculateMintReturn(
            _meToken,
            tokensDepositedAfterFees,
            meTokenDetails,
            hubDetails
        );

        // Send tokens to vault and update balance pooled
        address vaultToken = IVault(hubDetails.vault).getToken();
        IERC20(vaultToken).transferFrom(
            msg.sender,
            address(this),
            _tokensDeposited
        );

        meTokenRegistry.incrementBalancePooled(
            true,
            _meToken,
            tokensDepositedAfterFees
        );

        // Transfer fees
        if (fee > 0) {
            IVault(hubDetails.vault).addFee(fee);
        }

        // Mint meToken to user
        IERC20(_meToken).mint(_recipient, meTokensMinted);
    }

    /// @inheritdoc IFoundry
    function burn(
        address _meToken,
        uint256 _meTokensBurned,
        address _recipient
    ) external override {
        Details.MeTokenDetails memory meTokenDetails = meTokenRegistry
            .getDetails(_meToken);
        Details.HubDetails memory hubDetails = hub.getDetails(
            meTokenDetails.hubId
        );
        require(hubDetails.active, "Hub inactive");

        // Calculate how many tokens tokens are returned
        uint256 tokensReturned = calculateBurnReturn(
            _meToken,
            _meTokensBurned,
            meTokenDetails,
            hubDetails
        );

        uint256 feeRate;
        uint256 actualTokensReturned;
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (msg.sender == meTokenDetails.owner) {
            feeRate = fees.burnOwnerFee();
            actualTokensReturned =
                tokensReturned +
                (((PRECISION * _meTokensBurned) /
                    IERC20(_meToken).totalSupply()) *
                    meTokenDetails.balanceLocked) /
                PRECISION;
        } else {
            feeRate = fees.burnBuyerFee();
            // tokensReturnedAfterFees = tokensReturned * (PRECISION - feeRate) / PRECISION;
            uint256 refundRatio = hubDetails.refundRatio;
            if (hubDetails.targetRefundRatio == 0) {
                // Not updating targetRefundRatio
                actualTokensReturned = tokensReturned * hubDetails.refundRatio;
            } else {
                actualTokensReturned =
                    tokensReturned *
                    WeightedAverage.calculate(
                        hubDetails.refundRatio,
                        hubDetails.targetRefundRatio,
                        hubDetails.startTime,
                        hubDetails.endTime
                    );
            }
            actualTokensReturned *= refundRatio;
        }

        // TODO: tokensReturnedAfterFees

        // Burn metoken from user
        IERC20(_meToken).burn(msg.sender, _meTokensBurned);

        // Subtract tokens returned from balance pooled
        meTokenRegistry.incrementBalancePooled(false, _meToken, tokensReturned);

        if (actualTokensReturned > tokensReturned) {
            // Is owner, subtract from balance locked
            meTokenRegistry.incrementBalanceLocked(
                false,
                _meToken,
                actualTokensReturned - tokensReturned
            );
        } else {
            // Is buyer, add to balance locked using refund ratio
            meTokenRegistry.incrementBalanceLocked(
                true,
                _meToken,
                tokensReturned - actualTokensReturned
            );
        }

        // Transfer fees - TODO
        // if ((tokensReturnedWeighted * feeRate / PRECISION) > 0) {
        //     uint256 fee = tokensReturnedWeighted * feeRate / PRECISION;
        //     IVault(hubDetails.vault).addFee(fee);
        // }

        // Send tokens from vault
        address vaultToken = IVault(hubDetails.vault).getToken();
        // IERC20(vaultToken).transferFrom(hubDetails.vault, _recipient, tokensReturnedAfterFees);
        IERC20(vaultToken).transferFrom(
            hubDetails.vault,
            _recipient,
            actualTokensReturned
        );
    }

    // NOTE: for now this does not include fees
    function calculateMintReturn(
        address _meToken,
        uint256 _tokensDeposited,
        Details.MeTokenDetails memory _meTokenDetails,
        Details.HubDetails memory _hubDetails
    ) public view returns (uint256 meTokensMinted) {
        // Calculate return assuming update is not happening
        meTokensMinted = ICurve(_hubDetails.curve).calculateMintReturn(
            _tokensDeposited,
            _meTokenDetails.hubId,
            IERC20(_meToken).totalSupply(),
            _meTokenDetails.balancePooled
        );

        // Logic for if we're switching to a new curve type // updating curveDetails
        if (
            (_hubDetails.updating && (_hubDetails.targetCurve != address(0))) ||
            (_hubDetails.curveDetails)
        ) {
            uint256 targetMeTokensMinted;
            if (_hubDetails.targetCurve != address(0)) {
                // Means we are updating to a new curve type
                targetMeTokensMinted = ICurve(_hubDetails.targetCurve)
                    .calculateMintReturn(
                        _tokensDeposited,
                        _meTokenDetails.hubId,
                        IERC20(_meToken).totalSupply(),
                        _meTokenDetails.balancePooled
                    );
            } else {
                // Must mean we're updating curveDetails
                targetMeTokensMinted = ICurve(_hubDetails.curve)
                    .calculateTargetMintReturn(
                        _tokensDeposited,
                        _meTokenDetails.hubId,
                        IERC20(_meToken).totalSupply(),
                        _meTokenDetails.balancePooled
                    );
            }
            meTokensMinted = WeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                _hubDetails.startTime,
                _hubDetails.endTime
            );
        }
    }

    function calculateBurnReturn(
        address _meToken,
        uint256 _meTokensBurned,
        Details.MeTokenDetails memory _meTokenDetails,
        Details.HubDetails memory _hubDetails
    ) public view returns (uint256 tokensReturned) {
        // Calculate return assuming update is not happening
        tokensReturned = ICurve(_hubDetails.curve).calculateBurnReturn(
            _meTokensBurned,
            _meTokenDetails.hubId,
            IERC20(_meToken).totalSupply(),
            _meTokenDetails.balancePooled
        );

        // Logic for if we're switching to a new curve type // updating curveDetails
        if (
            (_hubDetails.updating && (_hubDetails.targetCurve != address(0))) ||
            (_hubDetails.curveDetails)
        ) {
            uint256 targetTokensReturned;
            if (_hubDetails.targetCurve != address(0)) {
                // Means we are updating to a new curve type
                targetTokensReturned = ICurve(_hubDetails.targetCurve)
                    .calculateBurnReturn(
                        _meTokensBurned,
                        _meTokenDetails.hubId,
                        IERC20(_meToken).totalSupply(),
                        _meTokenDetails.balancePooled
                    );
            } else {
                // Must mean we're updating curveDetails
                targetTokensReturned = ICurve(_hubDetails.curve)
                    .calculateTargetBurnReturn(
                        _meTokensBurned,
                        _meTokenDetails.hubId,
                        IERC20(_meToken).totalSupply(),
                        _meTokenDetails.balancePooled
                    );
            }
            tokensReturned = WeightedAverage.calculate(
                tokensReturned,
                targetTokensReturned,
                _hubDetails.startTime,
                _hubDetails.endTime
            );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFees {
    function setBurnBuyerFee(uint256 amount) external;

    function setBurnOwnerFee(uint256 amount) external;

    function setTransferFee(uint256 amount) external;

    function setInterestFee(uint256 amount) external;

    function setYieldFee(uint256 amount) external;

    function setOwner(address _owner) external;

    function mintFee() external view returns (uint256);

    function burnBuyerFee() external view returns (uint256);

    function burnOwnerFee() external view returns (uint256);

    function transferFee() external view returns (uint256);

    function interestFee() external view returns (uint256);

    function yieldFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

interface IMeTokenRegistry {
    event Register(
        address indexed meToken,
        address indexed owner,
        string name,
        string symbol,
        uint256 hubId
    );
    event TransferOwnership(address from, address to, address meToken);
    event IncrementBalancePooled(bool add, address meToken, uint256 amount);
    event IncrementBalanceLocked(bool add, address meToken, uint256 amount);

    /// @notice TODO
    /// @param _name TODO
    /// @param _symbol TODO
    /// @param _hubId TODO
    /// @param _tokensDeposited TODO
    function register(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _tokensDeposited
    ) external;

    // /// @notice TODO
    // /// @return TODO
    // function toggleUpdating() external returns (bool);

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function isOwner(address _owner) external view returns (bool);

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function getOwnerMeToken(address _owner) external view returns (address);

    /// @notice TODO
    /// @param meToken Address of meToken queried
    /// @return meTokenDetails details of the meToken
    function getDetails(address meToken)
        external
        view
        returns (Details.MeTokenDetails memory meTokenDetails);

    function transferOwnership(address _meToken, address _newOwner) external;

    function incrementBalancePooled(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;

    function incrementBalanceLocked(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMeToken {
    function initialize(
        string calldata name,
        address owner,
        string calldata symbol
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function canMigrate() external view returns (bool);

    function switchUpdating() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

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
    function allowance(address owner, address spender)
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Curve Interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    event Updated(uint256 indexed hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero ValueSet registry
    /// @dev ValueSet need to be encoded as the Hub may register ValueSets for different curves
    ///      that may contain different ValueSet arguments
    /// @param _hubId                   unique hub identifier
    /// @param _encodedValueSet     encoded ValueSet arguments
    function register(uint256 _hubId, bytes calldata _encodedValueSet) external;

    /// @notice TODO
    /// @param _hubId                   unique hub identifier
    /// @param _encodedValueSet     encoded target ValueSet arguments
    function registerTarget(uint256 _hubId, bytes calldata _encodedValueSet)
        external;

    function calculateMintReturn(
        uint256 _tokensDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensReturned);

    function calculateBurnReturn(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 tokensReturned);

    function calculateTargetMintReturn(
        uint256 _tokensDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensReturned);

    function calculateTargetBurnReturn(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 tokensReturned);

    function finishUpdate(uint256 id) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVault {
    event Withdraw(uint256 amount, address to);
    event AddFee(uint256 amount);

    function addFee(uint256 amount) external;

    function withdraw(
        bool max,
        uint256 amount,
        address to
    ) external;

    function getToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

interface IHub {
    event Register(string name, address indexed vault); // TODO: decide on arguments
    event Deactivate(uint256 id);

    function subscribeMeToken(uint256 _id, address _meToken) external;

    function getSubscribedMeTokenCount(uint256 _id)
        external
        view
        returns (uint256);

    function getSubscribedMeTokens(uint256 _id)
        external
        view
        returns (address[] memory);

    /// @notice Function to modify a hubs' status to INACTIVE
    /// @param id Unique hub identifier
    function deactivate(uint256 id) external;

    /// @notice Function to modify a hubs' status to QUEUED
    /// @param id Unique hub identifier
    function startUpdate(uint256 id) external;

    /// @notice Function to end the update, setting the target values of the hub,
    ///         as well as modifying a hubs' status to ACTIVE
    /// @param id Unique hub identifier
    function finishUpdate(uint256 id) external;

    function initUpdate(
        uint256 _id,
        address _migrationVault,
        address _targetVault,
        address _targetCurve,
        bool _curveDetails,
        uint256 _targetRefundRatio,
        uint256 _startTime,
        uint256 _duration
    ) external;

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return hubDetails Details of hub
    function getDetails(uint256 id)
        external
        view
        returns (Details.HubDetails memory hubDetails);

    /// @notice Helper to fetch only owner of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of owner
    function getOwner(uint256 id) external view returns (address);

    /// @notice Helper to fetch only vault of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of vault
    function getVault(uint256 id) external view returns (address);

    /// @notice Helper to fetch only curve of hubDetails
    /// @param id Unique hub identifier
    /// @return Address of curve
    function getCurve(uint256 id) external view returns (address);

    /// @notice Helper to fetch only refundRatio of hubDetails
    /// @param id Unique hub identifier
    /// @return uint Return refundRatio
    function getRefundRatio(uint256 id) external view returns (uint256);

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return bool is the hub active?
    function isActive(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFoundry {
    function mint(
        address _meToken,
        uint256 _tokensDeposited,
        address _recipient
    ) external;

    function burn(
        address _meToken,
        uint256 _meTokensBurned,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library WeightedAverage {
    uint256 private constant _PRECISION = 10**18;

    /*
    EXAMPLE:
    _PRECISION = 500
    block.timestamp - startTime = 70
    endTime - startTime = 100

    // scenario 1 :  targetAmount > amount
    amount = 87
    targetAmount = 137

    ### pt 1
    ( _PRECISION*amount + _PRECISION * (targetAmount - amount) * 0.7 ) / _PRECISION;
    ( 500*87 + 500 * (137 - 87) * 0.7 ) / 500  =  122
    ### pt 2
    ( _PRECISION*amount - _PRECISION * (amount - targetAmount) * 0.7 ) / _PRECISION;
    ( 500*87 - 500 * (87 - 137) * 0.7 ) / 500  =  122

    // scenario 2 :  targetAmount < amount
    amount = 201
    targetAmount = 172

    ### pt 1
    ( _PRECISION*amount + _PRECISION * (targetAmount - amount) * 0.7 ) / _PRECISION;
    ( 500*201 + 500 * (172 - 201) * 0.7 ) / 500  =  180.7
    ### pt 2
    ( _PRECISION*amount - _PRECISION * (amount - targetAmount) * 0.7 ) / _PRECISION;
    ( 500*201 - 500 * (201 - 172) * 0.7 ) / 500  =  180.7
    */

    function calculate(
        uint256 amount,
        uint256 targetAmount,
        uint256 startTime,
        uint256 endTime
    ) external view returns (uint256) {
        if (block.timestamp < startTime) {
            // Update hasn't started, apply no weighting
            return amount;
        } else if (block.timestamp > endTime) {
            // Update is over, return target amount
            return targetAmount;
        } else {
            // Currently in an update, return weighted average
            if (targetAmount > amount) {
                return
                    (_PRECISION *
                        amount +
                        (_PRECISION *
                            (targetAmount - amount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            } else {
                return
                    (_PRECISION *
                        amount -
                        (_PRECISION *
                            (amount - targetAmount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Details {
    struct MeTokenDetails {
        address owner;
        uint256 hubId;
        uint256 balancePooled;
        uint256 balanceLocked;
        bool updating; // TODO: validate
        uint256 startTime;
        uint256 endTime;
        uint256 targetHub;
    }

    struct HubDetails {
        bool active;
        address vault;
        address curve;
        uint256 refundRatio;
        bool updating;
        uint256 startTime;
        uint256 endTime;
        address migrationVault;
        address targetVault;
        bool curveDetails;
        address targetCurve;
        uint256 targetRefundRatio;
    }

    struct BancorDetails {
        uint256 baseY;
        uint32 reserveWeight;
        // bool updating;
        uint256 targetBaseY;
        uint32 targetReserveWeight;
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