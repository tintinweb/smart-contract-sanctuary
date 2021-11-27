// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFees.sol";
import "./interfaces/IMeTokenRegistry.sol";
import "./interfaces/IMeToken.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IMigration.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IFoundry.sol";
import "./libs/WeightedAverage.sol";
import "./libs/Details.sol";

contract Foundry is IFoundry, Ownable, Initializable {
    using SafeERC20 for IERC20;
    uint256 public constant PRECISION = 10**18;
    uint256 public constant MAX_REFUND_RATIO = 10**6;
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

    // MINT FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 mint()                  //
    //                                                   |                     //
    //                                             CALCULATE MINT              //
    //                                                 /    \                  //
    // is hub updating or meToken migrating? -{      (Y)     (N)               //
    //                                               /         \               //
    //                                          CALCULATE       |              //
    //                                         TARGET MINT      |              //
    //                                             |            |              //
    //                                        TIME-WEIGHTED     |              //
    //                                           AVERAGE        |              //
    //                                               \         /               //
    //                                               MINT RETURN               //
    //                                                   |                     //
    //                                              .sub(fees)                 //
    //                                                                         //
    ****************************************************************************/
    function mint(
        address _meToken,
        uint256 _assetsDeposited,
        address _recipient
    ) external override {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        require(hub_.active, "Hub inactive");

        // Handling changes
        if (hub_.updating && block.timestamp > hub_.endTime) {
            hub_ = hub.finishUpdate(meToken_.hubId);
        } else if (meToken_.targetHubId != 0) {
            if (block.timestamp > meToken_.endTime) {
                meToken_ = meTokenRegistry.finishResubscribe(_meToken);
            } else if (block.timestamp > meToken_.startTime) {
                // Handle migration actions if needed
                IMigration(meToken_.migration).poke(_meToken);
            }
        }

        uint256 fee = (_assetsDeposited * fees.mintFee()) / PRECISION;
        uint256 assetsDepositedAfterFees = _assetsDeposited - fee;

        uint256 meTokensMinted = calculateMeTokensMinted(
            _meToken,
            assetsDepositedAfterFees
        );

        IVault vault;
        address asset;
        // Check if meToken is using a migration vault and in the active stage of resubscribing.
        // Sometimes a meToken may be resubscribing to a hub w/ the same asset,
        // in which case a migration vault isn't needed
        if (
            meToken_.migration != address(0) &&
            block.timestamp > meToken_.startTime
        ) {
            vault = IVault(meToken_.migration);
            // Use meToken address to get the asset address from the migration vault
            Details.Hub memory targetHub_ = hub.getDetails(
                meToken_.targetHubId
            );
            asset = targetHub_.asset;
        } else {
            vault = IVault(hub_.vault);
            asset = hub_.asset;
        }
        IERC20(asset).safeTransferFrom(
            msg.sender,
            address(vault),
            _assetsDeposited
        );
        vault.approveAsset(asset, _assetsDeposited);

        vault.addFee(asset, fee);

        meTokenRegistry.updateBalancePooled(
            true,
            _meToken,
            assetsDepositedAfterFees
        );
        // Mint meToken to user
        IMeToken(_meToken).mint(_recipient, meTokensMinted);
        emit Mint(
            _meToken,
            asset,
            msg.sender,
            _recipient,
            _assetsDeposited,
            meTokensMinted
        );
    }

    // BURN FLOW CHART
    /****************************************************************************
    //                                                                         //
    //                                                 burn()                  //
    //                                                   |                     //
    //                                             CALCULATE BURN              //
    //                                                /     \                  //
    // is hub updating or meToken migrating? -{     (Y)     (N)                //
    //                                              /         \                //
    //                                         CALCULATE       \               //
    //                                        TARGET BURN       \              //
    //                                           /               \             //
    //                                  TIME-WEIGHTED             \            //
    //                                     AVERAGE                 \           //
    //                                        |                     |          //
    //                              WEIGHTED BURN RETURN       BURN RETURN     //
    //                                     /     \               /    \        //
    // is msg.sender the -{              (N)     (Y)           (Y)    (N)      //
    // owner? (vs buyer)                 /         \           /        \      //
    //                                 GET           CALCULATE         GET     //
    //                            TIME-WEIGHTED    BALANCE LOCKED     REFUND   //
    //                            REFUND RATIO        RETURNED        RATIO    //
    //                                  |                |              |      //
    //                              .mul(wRR)        .add(BLR)      .mul(RR)   //
    //                                   \_______________|_____________/       //
    //                                                   |                     //
    //                                     ACTUAL (WEIGHTED) BURN RETURN       //
    //                                                   |                     //
    //                                               .sub(fees)                //
    //                                                                         //
    ****************************************************************************/

    /// @inheritdoc IFoundry
    function burn(
        address _meToken,
        uint256 _meTokensBurned,
        address _recipient
    ) external override {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        require(hub_.active, "Hub inactive");
        if (hub_.updating && block.timestamp > hub_.endTime) {
            hub_ = hub.finishUpdate(meToken_.hubId);
        } else if (
            meToken_.targetHubId != 0 && block.timestamp > meToken_.endTime
        ) {
            meToken_ = meTokenRegistry.finishResubscribe(_meToken);
        }
        // Calculate how many tokens tokens are returned
        uint256 rawAssetsReturned = calculateRawAssetsReturned(
            _meToken,
            _meTokensBurned
        );
        uint256 assetsReturned = calculateActualAssetsReturned(
            msg.sender,
            _meToken,
            _meTokensBurned,
            rawAssetsReturned
        );

        uint256 feeRate;
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (msg.sender == meToken_.owner) {
            feeRate = fees.burnOwnerFee();
        } else {
            feeRate = fees.burnBuyerFee();
        }

        // Burn metoken from user
        IMeToken(_meToken).burn(msg.sender, _meTokensBurned);

        // Subtract tokens returned from balance pooled
        meTokenRegistry.updateBalancePooled(false, _meToken, rawAssetsReturned);

        if (msg.sender == meToken_.owner) {
            // Is owner, subtract from balance locked
            meTokenRegistry.updateBalanceLocked(
                false,
                _meToken,
                assetsReturned - rawAssetsReturned
            );
        } else {
            // Is buyer, add to balance locked using refund ratio
            meTokenRegistry.updateBalanceLocked(
                true,
                _meToken,
                rawAssetsReturned - assetsReturned
            );
        }

        uint256 fee = assetsReturned * feeRate;
        assetsReturned -= fee;
        IERC20(hub_.asset).safeTransferFrom(
            hub_.vault,
            _recipient,
            assetsReturned
        );
        IVault(hub_.vault).addFee(hub_.asset, fee);

        emit Burn(
            _meToken,
            hub_.asset,
            msg.sender,
            _recipient,
            _meTokensBurned,
            assetsReturned
        );
    }

    function calculateAssetsReturned(
        address _sender,
        address _meToken,
        uint256 _meTokensBurned
    ) external view returns (uint256 assetsReturned) {
        uint256 rawAssetsReturned = calculateRawAssetsReturned(
            _meToken,
            _meTokensBurned
        );
        assetsReturned = calculateActualAssetsReturned(
            _sender,
            _meToken,
            _meTokensBurned,
            rawAssetsReturned
        );
    }

    function calculateAssetsDeposited(
        // TODO: can we just pass in hubId instead of _meToken for first argument?
        address _meToken,
        uint256 _desiredMeTokensMinted
    ) external view returns (uint256 assetsDeposited) {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        // gas savings
        uint256 totalSupply_ = IERC20(_meToken).totalSupply();

        // Calculate return assuming update is not happening
        assetsDeposited = ICurve(hub_.curve).viewAssetsDeposited(
            _desiredMeTokensMinted,
            meToken_.hubId,
            totalSupply_,
            meToken_.balancePooled
        );
        // Logic for if we're switching to a new curve type // updating curveDetails
        if (
            (hub_.updating && (hub_.targetCurve != address(0))) ||
            (hub_.reconfigure)
        ) {
            uint256 targetAssetsDeposited;
            if (hub_.targetCurve != address(0)) {
                // Means we are updating to a new curve type
                targetAssetsDeposited = ICurve(hub_.targetCurve)
                    .viewAssetsDeposited(
                        _desiredMeTokensMinted,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            } else {
                // Must mean we're updating curveDetails
                targetAssetsDeposited = ICurve(hub_.curve)
                    .viewTargetAssetsDeposited(
                        _desiredMeTokensMinted,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            }
            assetsDeposited = WeightedAverage.calculate(
                assetsDeposited,
                targetAssetsDeposited,
                hub_.startTime,
                hub_.endTime
            );
        }
    }

    // NOTE: for now this does not include fees
    function calculateMeTokensMinted(address _meToken, uint256 _assetsDeposited)
        public
        view
        returns (uint256 meTokensMinted)
    {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        // gas savings
        uint256 totalSupply_ = IERC20(_meToken).totalSupply();

        // Calculate return assuming update/resubscribe is not happening
        meTokensMinted = ICurve(hub_.curve).viewMeTokensMinted(
            _assetsDeposited,
            meToken_.hubId,
            totalSupply_,
            meToken_.balancePooled
        );

        // Logic for if we're switching to a new curve type // reconfiguring
        if (
            (hub_.updating && (hub_.targetCurve != address(0))) ||
            (hub_.reconfigure)
        ) {
            uint256 targetMeTokensMinted;
            if (hub_.targetCurve != address(0)) {
                // Means we are updating to a new curve type
                targetMeTokensMinted = ICurve(hub_.targetCurve)
                    .viewMeTokensMinted(
                        _assetsDeposited,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            } else {
                // Must mean we're reconfiguring
                targetMeTokensMinted = ICurve(hub_.curve)
                    .viewTargetMeTokensMinted(
                        _assetsDeposited,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            }
            meTokensMinted = WeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                hub_.startTime,
                hub_.endTime
            );
        } else if (meToken_.targetHubId != 0) {
            Details.Hub memory targetHub = hub.getDetails(meToken_.targetHubId);
            uint256 targetMeTokensMinted = ICurve(targetHub.curve)
                .viewMeTokensMinted(
                    _assetsDeposited,
                    meToken_.targetHubId,
                    totalSupply_,
                    meToken_.balancePooled
                );
            meTokensMinted = WeightedAverage.calculate(
                meTokensMinted,
                targetMeTokensMinted,
                meToken_.startTime,
                meToken_.endTime
            );
        }
    }

    function calculateRawAssetsReturned(
        address _meToken,
        uint256 _meTokensBurned
    ) public view returns (uint256 rawAssetsReturned) {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);

        uint256 totalSupply_ = IERC20(_meToken).totalSupply(); // gas savings

        // Calculate return assuming update is not happening
        rawAssetsReturned = ICurve(hub_.curve).viewAssetsReturned(
            _meTokensBurned,
            meToken_.hubId,
            totalSupply_,
            meToken_.balancePooled
        );

        // Logic for if we're switching to a new curve type // updating curveDetails
        if (
            (hub_.updating && (hub_.targetCurve != address(0))) ||
            (hub_.reconfigure)
        ) {
            uint256 targetassetsReturned;
            if (hub_.targetCurve != address(0)) {
                // Means we are updating to a new curve type
                targetassetsReturned = ICurve(hub_.targetCurve)
                    .viewAssetsReturned(
                        _meTokensBurned,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            } else {
                // Must mean we're updating curveDetails
                targetassetsReturned = ICurve(hub_.curve)
                    .viewTargetAssetsReturned(
                        _meTokensBurned,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            }
            rawAssetsReturned = WeightedAverage.calculate(
                rawAssetsReturned,
                targetassetsReturned,
                hub_.startTime,
                hub_.endTime
            );
        }
    }

    /// @dev applies refundRatio
    function calculateActualAssetsReturned(
        address _sender,
        address _meToken,
        uint256 _meTokensBurned,
        uint256 rawAssetsReturned
    ) public view returns (uint256 actualAssetsReturned) {
        Details.MeToken memory meToken_ = meTokenRegistry.getDetails(_meToken);
        Details.Hub memory hub_ = hub.getDetails(meToken_.hubId);
        // If msg.sender == owner, give owner the sell rate. - all of tokens returned plus a %
        //      of balancePooled based on how much % of supply will be burned
        // If msg.sender != owner, give msg.sender the burn rate
        if (_sender == meToken_.owner) {
            actualAssetsReturned =
                rawAssetsReturned +
                (((PRECISION * _meTokensBurned) /
                    IERC20(_meToken).totalSupply()) * meToken_.balanceLocked) /
                PRECISION;
        } else {
            if (hub_.targetRefundRatio == 0 && meToken_.targetHubId == 0) {
                // Not updating targetRefundRatio or resubscribing
                actualAssetsReturned =
                    (rawAssetsReturned * hub_.refundRatio) /
                    MAX_REFUND_RATIO;
            } else {
                if (hub_.targetRefundRatio > 0) {
                    // Hub is updating
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            WeightedAverage.calculate(
                                hub_.refundRatio,
                                hub_.targetRefundRatio,
                                hub_.startTime,
                                hub_.endTime
                            )) /
                        MAX_REFUND_RATIO;
                } else {
                    // meToken is resubscribing
                    Details.Hub memory targetHub_ = hub.getDetails(
                        meToken_.targetHubId
                    );
                    actualAssetsReturned =
                        (rawAssetsReturned *
                            WeightedAverage.calculate(
                                hub_.refundRatio,
                                targetHub_.refundRatio,
                                meToken_.startTime,
                                meToken_.endTime
                            )) /
                        MAX_REFUND_RATIO;
                }
            }
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
    event Subscribe(
        address indexed _meToken,
        address indexed _owner,
        uint256 _minted,
        address _collateralToken,
        uint256 _collateralDeposited,
        string _name,
        string _symbol,
        uint256 _hubId
    );
    event InitResubscribe(
        address indexed _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes _encodedMigrationArgs
    );
    event FinishResubscribe(address indexed _meToken);
    event UpdateBalances(address _meToken, uint256 _newBalance);
    event TransferMeTokenOwnership(
        address _from,
        address _to,
        address _meToken
    );
    event UpdateBalancePooled(bool add, address _meToken, uint256 _amount);
    event UpdateBalanceLocked(bool add, address _meToken, uint256 _amount);

    /// @notice TODO
    /// @param _name TODO
    /// @param _symbol TODO
    /// @param _hubId TODO
    /// @param _assetsDeposited TODO
    function subscribe(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _assetsDeposited
    ) external;

    /// @notice TODO
    /// @param _meToken TODO
    /// @param _targetHubId TODO
    /// @param _migration TODO
    /// @param _encodedMigrationArgs TODO
    function initResubscribe(
        address _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes memory _encodedMigrationArgs
    ) external;

    /// @notice TODO
    /// @param _meToken TODO
    /// @return TODO
    function finishResubscribe(address _meToken)
        external
        returns (Details.MeToken memory);

    /// @notice TODO
    /// @param _meToken TODO
    /// @param _newBalance TODO
    function updateBalances(address _meToken, uint256 _newBalance) external;

    /// @notice TODO
    /// @param add TODO
    /// @param _meToken TODO
    /// @param _amount TODO
    function updateBalancePooled(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice TODO
    /// @param add TODO
    /// @param _meToken TODO
    /// @param _amount TODO
    function updateBalanceLocked(
        bool add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice TODO
    /// @param _newOwner TODO
    function transferMeTokenOwnership(address _newOwner) external;

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function getOwnerMeToken(address _owner) external view returns (address);

    /// @notice TODO
    /// @param meToken Address of meToken queried
    /// @return meToken_ details of the meToken
    function getDetails(address meToken)
        external
        view
        returns (Details.MeToken memory meToken_);

    /// @notice TODO
    /// @param _owner TODO
    /// @return TODO
    function isOwner(address _owner) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Curve Interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    event Updated(uint256 indexed hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero Curve registry
    /// @dev Curve need to be encoded as the Hub may register Curves for different curves
    ///      that may contain different Curve arguments
    /// @param _hubId                   unique hub identifier
    /// @param _encodedDetails          encoded Curve arguments
    function register(uint256 _hubId, bytes calldata _encodedDetails) external;

    /// @notice TODO
    /// @param _hubId                   unique hub identifier
    /// @param _encodedDetails          encoded target Curve arguments
    function initReconfigure(uint256 _hubId, bytes calldata _encodedDetails)
        external;

    function viewMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    function viewAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    function viewTargetMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    function viewTargetAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    function viewAssetsDeposited(
        uint256 _desiredMeTokensMinted,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsDeposited);

    function viewTargetAssetsDeposited(
        uint256 _desiredMeTokensMinted,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsDeposited);

    function finishReconfigure(uint256 id) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVault {
    event Withdraw(address _asset, uint256 _amount);
    event AddFee(address _asset, uint256 _amount);

    function withdraw(
        address _asset,
        bool _max,
        uint256 _amount
    ) external;

    function approveAsset(address _asset, uint256 _amount) external;

    function isValid(address _asset, bytes memory _encodedArgs)
        external
        returns (bool);

    function addFee(address _meToken, uint256 _amount) external;

    function getAccruedFees(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMigration {
    function poke(address _meToken) external;

    function initMigration(address _meToken, bytes memory _encodedArgs)
        external;

    function finishMigration(address _meToken) external returns (uint256);

    // function isReady() external view returns (bool);
    // function hasFinished() external view returns (bool);
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
    function finishUpdate(uint256 id) external returns (Details.Hub memory);

    function initUpdate(
        uint256 _id,
        address _migration,
        address _targetVault,
        address _targetCurve,
        bool _reconfigure,
        uint256 _targetRefundRatio,
        uint256 _startTime,
        uint256 _duration
    ) external;

    /// @notice TODO
    /// @param id Unique hub identifier
    /// @return hub_ Details of hub
    function getDetails(uint256 id)
        external
        view
        returns (Details.Hub memory hub_);

    /// @notice TODO
    /// @return count of hubs created
    function count() external view returns (uint256);

    function getWarmup() external view returns (uint256);

    function setWarmup(uint256 warmup_) external;

    function getDuration() external view returns (uint256);

    function setDuration(uint256 duration_) external;

    function getCooldown() external view returns (uint256);

    function setCooldown(uint256 cooldown_) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IFoundry {
    event Mint(
        address meToken,
        address token,
        address depositor,
        address recipient,
        uint256 assetsDeposited,
        uint256 meTokensMinted
    );

    event Burn(
        address meToken,
        address token,
        address burner,
        address recipient,
        uint256 meTokensBurned,
        uint256 assetsReturned
    );

    function mint(
        address _meToken,
        uint256 _assetsDeposited,
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

    // CALCULATE TIME-WEIGHTED AVERAGE
    /****************************************************************************
    //                                     __                      __          //
    // wA = weightedAmount                /                          \         //
    // a = amout                          |   (a - tA) * (bT - sT)   |         //
    // tA = targetAmount         wA = a + |   --------------------   |         //
    // sT = startTime                     |        (eT - sT)         |         //
    // eT = endTime                       \__                      __/         //
    // bT = block.timestame                                                    //
    //                                                                         //
    ****************************************************************************/

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
                // re-orders above visualized formula to handle negative numbers
                return
                    (_PRECISION *
                        amount +
                        (_PRECISION *
                            (targetAmount - amount) *
                            (block.timestamp - startTime)) /
                        (endTime - startTime)) / _PRECISION;
            } else {
                // follows order of visualized formula above
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
    struct MeToken {
        address owner;
        uint256 hubId;
        uint256 balancePooled;
        uint256 balanceLocked;
        uint256 startTime;
        uint256 endTime;
        uint256 endCooldown;
        uint256 targetHubId;
        address migration;
    }

    struct Hub {
        bool active;
        address vault;
        address asset;
        address curve;
        uint256 refundRatio;
        bool updating;
        uint256 startTime;
        uint256 endTime;
        uint256 endCooldown;
        bool reconfigure;
        address targetCurve;
        uint256 targetRefundRatio;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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