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

        // Handling changes
        if (hub_.updating && block.timestamp > hub_.endTime) {
            hub_ = hub.finishUpdate(meToken_.hubId);
        } else if (meToken_.targetHubId != 0) {
            if (block.timestamp > meToken_.endTime) {
                hub_ = hub.getDetails(meToken_.targetHubId);
                meToken_ = meTokenRegistry.finishResubscribe(_meToken);
            } else if (block.timestamp > meToken_.startTime) {
                // Handle migration actions if needed
                IMigration(meToken_.migration).poke(_meToken);
                meToken_ = meTokenRegistry.getDetails(_meToken);
            }
        }

        uint256 fee = (_assetsDeposited * fees.mintFee()) / PRECISION;
        uint256 assetsDepositedAfterFees = _assetsDeposited - fee;

        uint256 meTokensMinted = _calculateMeTokensMinted(
            _meToken,
            assetsDepositedAfterFees
        );
        IVault vault = IVault(hub_.vault);
        address asset = hub_.asset;
        // Check if meToken is using a migration vault and in the active stage of resubscribing.
        // Sometimes a meToken may be resubscribing to a hub w/ the same asset,
        // in which case a migration vault isn't needed
        if (
            meToken_.migration != address(0) &&
            block.timestamp > meToken_.startTime
        ) {
            Details.Hub memory targetHub_ = hub.getDetails(
                meToken_.targetHubId
            );
            // Use meToken address to get the asset address from the migration vault
            vault = IVault(meToken_.migration);
            asset = targetHub_.asset;
        }

        vault.handleDeposit(msg.sender, asset, _assetsDeposited, fee);

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

        if (hub_.updating && block.timestamp > hub_.endTime) {
            hub_ = hub.finishUpdate(meToken_.hubId);
        } else if (
            meToken_.targetHubId != 0 && block.timestamp > meToken_.endTime
        ) {
            hub_ = hub.getDetails(meToken_.targetHubId);
            meToken_ = meTokenRegistry.finishResubscribe(_meToken);
        }
        // Calculate how many tokens are returned
        uint256 rawAssetsReturned = _calculateRawAssetsReturned(
            _meToken,
            _meTokensBurned
        );
        uint256 assetsReturned = _calculateActualAssetsReturned(
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

        uint256 fee = (assetsReturned * feeRate) / PRECISION;
        assetsReturned = assetsReturned - fee;
        IVault vault = IVault(hub_.vault);
        address asset = hub_.asset;

        if (
            meToken_.migration != address(0) &&
            block.timestamp > meToken_.startTime
        ) {
            Details.Hub memory targetHub_ = hub.getDetails(
                meToken_.targetHubId
            );
            vault = IVault(meToken_.migration);
            asset = targetHub_.asset;
        }

        vault.handleWithdrawal(_recipient, asset, assetsReturned, fee);

        emit Burn(
            _meToken,
            asset,
            msg.sender,
            _recipient,
            _meTokensBurned,
            assetsReturned
        );
    }

    // NOTE: for now this does not include fees
    function _calculateMeTokensMinted(
        address _meToken,
        uint256 _assetsDeposited
    ) private view returns (uint256 meTokensMinted) {
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

    function _calculateRawAssetsReturned(
        address _meToken,
        uint256 _meTokensBurned
    ) private view returns (uint256 rawAssetsReturned) {
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

        uint256 targetAssetsReturned;
        // Logic for if we're switching to a new curve type // updating curveDetails
        if (
            (hub_.updating && (hub_.targetCurve != address(0))) ||
            (hub_.reconfigure)
        ) {
            if (hub_.targetCurve != address(0)) {
                // Means we are updating to a new curve type

                targetAssetsReturned = ICurve(hub_.targetCurve)
                    .viewAssetsReturned(
                        _meTokensBurned,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            } else {
                // Must mean we're updating curveDetails
                targetAssetsReturned = ICurve(hub_.curve)
                    .viewTargetAssetsReturned(
                        _meTokensBurned,
                        meToken_.hubId,
                        totalSupply_,
                        meToken_.balancePooled
                    );
            }
            rawAssetsReturned = WeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                hub_.startTime,
                hub_.endTime
            );
        } else if (meToken_.targetHubId != 0) {
            Details.Hub memory targetHub_ = hub.getDetails(
                meToken_.targetHubId
            );

            // Calculate return assuming update is not happening
            targetAssetsReturned = ICurve(targetHub_.curve).viewAssetsReturned(
                _meTokensBurned,
                meToken_.targetHubId,
                totalSupply_,
                meToken_.balancePooled
            );
            rawAssetsReturned = WeightedAverage.calculate(
                rawAssetsReturned,
                targetAssetsReturned,
                meToken_.startTime,
                meToken_.endTime
            );
        }
    }

    /// @dev applies refundRatio
    function _calculateActualAssetsReturned(
        address _sender,
        address _meToken,
        uint256 _meTokensBurned,
        uint256 rawAssetsReturned
    ) private view returns (uint256 actualAssetsReturned) {
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

/// @title MeTokens protocol fee interface
/// @author Carl Farterson (@carlfarterson)
interface IFees {
    /// @notice Set meToken protocol BurnBuyer fee
    /// @param _fee new fee
    function setBurnBuyerFee(uint256 _fee) external;

    /// @notice Set meToken protocol BurnOwner fee
    /// @param _fee new fee
    function setBurnOwnerFee(uint256 _fee) external;

    /// @notice Set meToken protocol Transfer fee
    /// @param _fee new fee
    function setTransferFee(uint256 _fee) external;

    /// @notice Set meToken protocol Interest fee
    /// @param _fee new fee
    function setInterestFee(uint256 _fee) external;

    /// @notice Set meToken protocol Yield fee
    /// @param _fee new fee
    function setYieldFee(uint256 _fee) external;

    /// @notice Get mint fee
    /// @return uint256 _mintFee
    function mintFee() external view returns (uint256);

    /// @notice Get burnBuyer fee
    /// @return uint256 _burnBuyerFee
    function burnBuyerFee() external view returns (uint256);

    /// @notice Get burnOwner fee
    /// @return uint256 _burnOwnerFee
    function burnOwnerFee() external view returns (uint256);

    /// @notice Get transfer fee
    /// @return uint256 _transferFee
    function transferFee() external view returns (uint256);

    /// @notice Get interest fee
    /// @return uint256 _interestFee
    function interestFee() external view returns (uint256);

    /// @notice Get yield fee
    /// @return uint256 _yieldFee
    function yieldFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libs/Details.sol";

/// @title meToken registry interface
/// @author Carl Farterson (@carlfarterson)
interface IMeTokenRegistry {
    /// @notice Event of subscribing (creating) a new meToken
    /// @param _meToken         address of created meToken
    /// @param _owner           address of meToken owner
    /// @param _minted          amount of meToken minted to owner
    /// @param _asset           address of underlying asset
    /// @param _assetsDeposited amount of assets deposited
    /// @param _name            name of meToken
    /// @param _symbol          symbol of meToken
    /// @param _hubId           unique hub identifier
    event Subscribe(
        address indexed _meToken,
        address indexed _owner,
        uint256 _minted,
        address _asset,
        uint256 _assetsDeposited,
        string _name,
        string _symbol,
        uint256 _hubId
    );

    /// @notice Event of initializing a meToken subscription to a different hub
    /// @param _meToken                 address of meToken
    /// @param _targetHubId             target hub to suscribe to
    /// @param _migration               address of migration vault
    /// @param _encodedMigrationArgs    additional encoded migration vault arguments
    event InitResubscribe(
        address indexed _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes _encodedMigrationArgs
    );
    /// @notice Event of canceling a meToken resubscription
    /// @param _meToken address of meToken
    event CancelResubscribe(address indexed _meToken);

    /// @notice Event of finishing a meToken resubscription
    /// @param _meToken address of meToken
    event FinishResubscribe(address indexed _meToken);

    /// @notice Event of updating a meToken's balancePooled and balanceLocked
    /// @param _meToken     address of meToken
    /// @param _newBalance  rate to multiply balances by
    event UpdateBalances(address _meToken, uint256 _newBalance);

    /// @notice Event of transfering meToken ownership to a new owner
    /// @param _from    address of current meToken owner
    /// @param _to      address to own the meToken
    /// @param _meToken address of meToken
    event TransferMeTokenOwnership(
        address _from,
        address _to,
        address _meToken
    );

    /// @notice Event of cancelling the transfer of meToken ownership
    /// @param _from    address of current meToken owner
    /// @param _meToken address of meToken
    event CancelTransferMeTokenOwnership(address _from, address _meToken);

    /// @notice Event of claiming the transfer of meToken ownership
    /// @param _from    address of current meToken owner
    /// @param _to      address to own the meToken
    /// @param _meToken address of meToken
    event ClaimMeTokenOwnership(address _from, address _to, address _meToken);

    /// @notice Event of updating a meToken's balancePooled
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    event UpdateBalancePooled(bool _add, address _meToken, uint256 _amount);

    /// @notice Event of updating a meToken's balanceLocked
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    event UpdateBalanceLocked(bool _add, address _meToken, uint256 _amount);

    /// @notice Create and subscribe a meToken to a hub
    /// @param _name            name of meToken
    /// @param _symbol          symbol of meToken
    /// @param _hubId           initial hub to subscribe to
    /// @param _assetsDeposited amount of assets deposited at meToken initialization
    function subscribe(
        string calldata _name,
        string calldata _symbol,
        uint256 _hubId,
        uint256 _assetsDeposited
    ) external;

    /// @notice Initialize a meToken resubscription to a new hub
    /// @param _meToken                 address of meToken
    /// @param _targetHubId             hub which meToken is resubscribing to
    /// @param _migration               address of migration vault
    /// @param _encodedMigrationArgs    additional encoded migration vault arguments
    function initResubscribe(
        address _meToken,
        uint256 _targetHubId,
        address _migration,
        bytes memory _encodedMigrationArgs
    ) external;

    /// @notice Cancel a meToken resubscription
    /// @dev can only be done during the warmup period
    /// @param _meToken address of meToken
    function cancelResubscribe(address _meToken) external;

    /// @notice Finish a meToken's resubscription to a new hub
    /// @param _meToken address of meToken
    /// @return details of meToken
    function finishResubscribe(address _meToken)
        external
        returns (Details.MeToken memory);

    /// @notice Update a meToken's balanceLocked and balancePooled
    /// @param _meToken     address of meToken
    /// @param _newBalance  rate to multiply balances by
    function updateBalances(address _meToken, uint256 _newBalance) external;

    /// @notice Update a meToken's balancePooled
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    function updateBalancePooled(
        bool _add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice Update a meToken's balanceLocked
    /// @param _add     boolean that is true if adding to balance, false if subtracting
    /// @param _meToken address of meToken
    /// @param _amount  amount to add/subtract
    function updateBalanceLocked(
        bool _add,
        address _meToken,
        uint256 _amount
    ) external;

    /// @notice Transfer meToken ownership to a new owner
    /// @param _newOwner address to claim meToken ownership of msg.sender
    function transferMeTokenOwnership(address _newOwner) external;

    /// @notice Cancel the transfer of meToken ownership
    function cancelTransferMeTokenOwnership() external;

    /// @notice Claim the transfer of meToken ownership
    /// @param _from address of current meToken owner
    function claimMeTokenOwnership(address _from) external;

    /// @notice View to return address of meToken owned by _owner
    /// @param _owner   address of meToken owner
    /// @return         address of meToken
    function getOwnerMeToken(address _owner) external view returns (address);

    /// @notice View to see the address to claim meToken ownership from _from
    /// @param _from    address to transfer meToken ownership
    /// @return         address of pending meToken owner
    function getPendingOwner(address _from) external view returns (address);

    /// @notice View to get details of a meToken
    /// @param meToken      address of meToken queried
    /// @return meToken_    details of meToken
    function getDetails(address meToken)
        external
        view
        returns (Details.MeToken memory meToken_);

    /// @notice View to return if an address owns a meToken or not
    /// @param _owner   address to query
    /// @return         true if owns a meToken, else false
    function isOwner(address _owner) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title meToken interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all meTokens
interface IMeToken {
    // TODO: are these needed, or can we do IERC20?
    function initialize(
        string calldata name,
        address owner,
        string calldata symbol
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Generic Curve interface
/// @author Carl Farterson (@carlfarterson)
/// @dev Required for all Curves
interface ICurve {
    /// @notice Event when curveDetails are updated from target values to actual values
    event Updated(uint256 indexed _hubId);

    /// @notice Given a hub, baseX, baseY and connector weight, add the configuration to the
    /// BancorZero Curve registry
    /// @dev Curve need to be encoded as the Hub may register Curves for different curves
    ///      that may contain different Curve arguments
    /// @param _hubId           unique hub identifier
    /// @param _encodedDetails  encoded Curve arguments
    function register(uint256 _hubId, bytes calldata _encodedDetails) external;

    /// @notice Initialize reconfiguring curveDetails for a hub
    /// @param _hubId           unique hub identifier
    /// @param _encodedDetails  encoded target Curve arguments
    function initReconfigure(uint256 _hubId, bytes calldata _encodedDetails)
        external;

    /// @notice Finish reconfiguring curveDetails for a hub
    /// @param _hubId uinque hub identifier
    function finishReconfigure(uint256 _hubId) external;

    /// @notice Get curveDetails for a hub
    /// @return curveDetails (TODO: curve w/ more than 4 curveDetails)
    function getDetails(uint256 _hubId)
        external
        view
        returns (uint256[4] memory);

    /// @notice Calculate meTokens minted based on a curve's active details
    /// @param _assetsDeposited Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return meTokensMinted  amount of MeTokens minted
    function viewMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's active details
    /// @param _meTokensBurned  Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return assetsReturned  amount of assets returned
    function viewAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);

    /// @notice Calculate meTokens minted based on a curve's target details
    /// @param _assetsDeposited Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return meTokensMinted  amount of MeTokens minted
    function viewTargetMeTokensMinted(
        uint256 _assetsDeposited,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's target details
    /// @param _meTokensBurned  Amount of assets deposited to the hub
    /// @param _hubId           unique hub identifier
    /// @param _supply          current meToken supply
    /// @param _balancePooled   area under curve
    /// @return assetsReturned  amount of assets returned
    function viewTargetAssetsReturned(
        uint256 _meTokensBurned,
        uint256 _hubId,
        uint256 _supply,
        uint256 _balancePooled
    ) external view returns (uint256 assetsReturned);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title generic vault interface
/// @author Carl Farterson (@carlfarterson)
abstract contract IVault {
    /// @notice Event when an asset is deposited to the vault
    /// @param _from            address which is depositing the asset
    /// @param _asset           address of asset
    /// @param _depositAmount   amount of assets deposited
    /// @param _feeAmount       amount of fees paid
    event HandleDeposit(
        address _from,
        address _asset,
        uint256 _depositAmount,
        uint256 _feeAmount
    );

    /// @notice Event when an asset is withdrawn from the vault
    /// @param _to                  address which will receive the asset
    /// @param _asset               address of asset
    /// @param _withdrawalAmount    amount of assets withdrawn
    /// @param _feeAmount           amount of fees paid
    event HandleWithdrawal(
        address _to,
        address _asset,
        uint256 _withdrawalAmount,
        uint256 _feeAmount
    );

    /// @notice Event when claiming the accrued fees of an asset
    /// @param _recipient   Recipient of the asset
    /// @param _asset       address of asset
    /// @param _amount      amount of asset
    event Claim(address _recipient, address _asset, uint256 _amount);

    /// @dev key: addr of asset, value: cumulative fees paid in the asset
    mapping(address => uint256) public accruedFees;

    /// @notice Claim the accrued fees of an asset
    /// @param _asset   address of asset
    /// @param _max     true if claiming all accrued fees of the asset, else false
    /// @param _amount  amount of asset to claim
    function claim(
        address _asset,
        bool _max,
        uint256 _amount
    ) external virtual;

    /// @notice Deposit an asset to the vault
    /// @param _from            address which is depositing the asset
    /// @param _asset           address of asset
    /// @param _depositAmount   amount of assets deposited
    /// @param _feeAmount       amount of fees paid
    function handleDeposit(
        address _from,
        address _asset,
        uint256 _depositAmount,
        uint256 _feeAmount
    ) external virtual;

    /// @notice Withdraw an asset from the vault
    /// @param _to                  address which will receive the asset
    /// @param _asset               address of asset
    /// @param _withdrawalAmount    amount of assets withdrawn
    function handleWithdrawal(
        address _to,
        address _asset,
        uint256 _withdrawalAmount,
        uint256 _feeAmount
    ) external virtual;

    /// @notice View to see if an asset with encoded arguments passed
    ///         when a vault is registered to a new hub
    /// @param _asset       address of asset
    /// @param _encodedArgs additional encoded arguments
    function isValid(address _asset, bytes memory _encodedArgs)
        external
        virtual
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Generic migration vault interface
/// @author Carl Farterson (@carlfarterson)
interface IMigration {
    /// @notice Method to trigger actions from the migration vault if needed
    /// @param _meToken address of meToken
    function poke(address _meToken) external;

    /// @notice Method called when a meToken starts resubscribing to a new hub
    /// @dev This is called within meTokenRegistry.initResubscribe()
    /// @param _meToken     address of meToken
    /// @param _encodedArgs additional encoded arguments
    function initMigration(address _meToken, bytes memory _encodedArgs)
        external;

    /// @notice Method to send assets from migration vault to the vault of the
    ///         target hub
    /// @param _meToken address of meToken
    function finishMigration(address _meToken) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IVault.sol";
import "./ICurve.sol";
import "../libs/Details.sol";

/// @title MeTokens hub interface
/// @author Carl Farterson (@carlfarterson)
interface IHub {
    /// @notice Event of registering a hub
    /// @param _id                  unique hub identifer
    /// @param _owner               address to own hub
    /// @param _asset               address of underlying asset
    /// @param _vault               address of vault
    /// @param _curve               address of curve
    /// @param _refundRatio         rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    /// @param _encodedVaultArgs    additional encoded vault arguments
    event Register(
        uint256 _id,
        address _owner,
        address _asset,
        address _vault,
        address _curve,
        uint256 _refundRatio,
        bytes _encodedCurveDetails,
        bytes _encodedVaultArgs
    );

    /// @notice Event of making a hub inactive, preventing new subscriptions to the hub
    /// @param _id  unique hub identifier
    event Deactivate(uint256 _id);

    /// @notice Event of initializing a hub update
    /// @param _id                     unique hub identifier
    /// @param _targetCurve            address of target curve
    /// @param _targetRefundRatio      target rate to refund burners
    /// @param _encodedCurveDetails    additional encoded curve details
    /// @param _reconfigure            boolean to show if we're changing the
    ///                                 curveDetails but not the curve address
    /// @param _startTime              timestamp to start updating
    /// @param _endTime                timestamp to end updating
    /// @param _endCooldown            timestamp to allow another update
    event InitUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes _encodedCurveDetails,
        bool _reconfigure,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _endCooldown
    );

    /// @notice Event of canceling a hub update
    /// @param _id unique hub identifier
    event CancelUpdate(uint256 _id);

    /// @notice Event of transfering hub ownership
    /// @param _id          unique hub identifier
    /// @param _newOwner    address to own the hub
    event TransferHubOwnership(uint256 _id, address _newOwner);

    /// @notice Event of finishing a hub update
    /// @param _id unique hub identifier
    event FinishUpdate(uint256 _id);

    /// @notice Register a new hub
    /// @param _owner               address to own hub
    /// @param _asset               address of vault asset
    /// @param _vault               address of vault
    /// @param _curve               address of curve
    /// @param _refundRatio         rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    /// @param _encodedVaultArgs    additional encoded vault arguments
    function register(
        address _owner,
        address _asset,
        IVault _vault,
        ICurve _curve,
        uint256 _refundRatio,
        bytes memory _encodedCurveDetails,
        bytes memory _encodedVaultArgs
    ) external;

    function deactivate(uint256 _id) external;

    /// @notice Intialize a hub update
    /// @param _id                  unique hub identifier
    /// @param _targetCurve         address of target curve
    /// @param _targetRefundRatio   target rate to refund burners
    /// @param _encodedCurveDetails additional encoded curve details
    function initUpdate(
        uint256 _id,
        address _targetCurve,
        uint256 _targetRefundRatio,
        bytes memory _encodedCurveDetails
    ) external;

    /// @notice Cancel a hub update
    /// @dev Can only be called before _startTime
    /// @param _id unique hub identifier
    function cancelUpdate(uint256 _id) external;

    /// @notice Finish updating a hub
    /// @param _id  unique hub identifier
    /// @return     details of hub
    function finishUpdate(uint256 _id) external returns (Details.Hub memory);

    /// @notice Get the details of a hub
    /// @param _id  unique hub identifier
    /// @return     details of hub
    function getDetails(uint256 _id) external view returns (Details.Hub memory);

    /// @notice Counter of hubs registered
    /// @return uint256
    function count() external view returns (uint256);

    function warmup() external view returns (uint256);

    function setWarmup(uint256 warmup_) external;

    function duration() external view returns (uint256);

    function setDuration(uint256 duration_) external;

    function cooldown() external view returns (uint256);

    function setCooldown(uint256 cooldown_) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title MeTokens foundry interface
/// @author Carl Farterson (@carlfarterson)
interface IFoundry {
    /// @notice Event of minting a meToken
    /// @param _meToken         address of meToken minted
    /// @param _asset           address of asset deposited
    /// @param _depositor       address to deposit asset
    /// @param _recipient       address to receive minted meTokens
    /// @param _assetsDeposited amount of assets deposited
    /// @param _meTokensMinted  amount of meTokens minted
    event Mint(
        address _meToken,
        address _asset,
        address _depositor,
        address _recipient,
        uint256 _assetsDeposited,
        uint256 _meTokensMinted
    );

    /// @notice Event of burning a meToken
    /// @param _meToken         address of meToken burned
    /// @param _asset           address of asset returned
    /// @param _burner          address to burn meTokens
    /// @param _recipient       address to receive underlying asset
    /// @param _meTokensBurned  amount of meTokens to burn
    /// @param _assetsReturned  amount of assets
    event Burn(
        address _meToken,
        address _asset,
        address _burner,
        address _recipient,
        uint256 _meTokensBurned,
        uint256 _assetsReturned
    );

    /// @notice Mint a meToken by depositing the underlying asset
    /// @param _meToken         address of meToken to mint
    /// @param _assetsDeposited amount of assets to deposit
    /// @param _recipient       address to receive minted meTokens
    function mint(
        address _meToken,
        uint256 _assetsDeposited,
        address _recipient
    ) external;

    /// @notice Burn a meToken to receive the underlying asset
    /// @param _meToken         address of meToken to burn
    /// @param _meTokensBurned  amount of meTokens to burn
    /// @param _recipient       address to receive the underlying assets
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
        address owner;
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