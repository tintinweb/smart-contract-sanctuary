// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/utils/RegistryStorage.sol";
import "contracts/interfaces/apwine/IFutureVault.sol";
import "contracts/interfaces/apwine/IRegistry.sol";
import "contracts/interfaces/apwine/IController.sol";
import "contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "contracts/utils/APWineNaming.sol";

/**
 * @title TokenFactory contract
 * @notice The TokenFactory deployed the token of Protocol.
 */
contract TokensFactory is Initializable, RegistryStorage {
    /* Events */
    event PTDeployed(address _futureVault, address _pt);
    event FytDeployed(address _futureVault, address _fyt);
    event ProxyCreated(address proxy);
    /* Modifiers */
    modifier onlyRegisteredFutureVault() {
        require(registry.isRegisteredFutureVault(msg.sender), "TokensFactory: ERR_FUTURE_ADDRESS");
        _;
    }

    /**
     * @notice Initializer of the contract
     * @param _registry the address of the registry of the contract
     * @param _admin the address of the admin of the contract
     */
    function initialize(IRegistry _registry, address _admin) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ADMIN_ROLE, _admin);
        registry = _registry;
    }

    /**
     * @notice Deploy the pt of the future
     */
    function deployPT(
        string memory _ibtSymbol,
        uint256 _ibtDecimals,
        string memory _platformName,
        uint256 _perioDuration
    ) external returns (address newToken) {
        string memory ibtSymbol = _getFutureIBTSymbol(_ibtSymbol, _platformName, _perioDuration);
        bytes memory payload = abi.encodeWithSignature(
            "initialize(string,string,uint8,address)",
            ibtSymbol,
            ibtSymbol,
            _ibtDecimals,
            msg.sender
        );

        newToken = _clonePositonToken(
            registry.getPTLogicAddress(),
            payload,
            keccak256(abi.encodePacked(ibtSymbol, msg.sender))
        );
        emit PTDeployed(msg.sender, newToken);
    }

    /**
     * @notice Deploy the next future yield token of the futureVault
     * @dev the caller must be a registered future vault
     */
    function deployNextFutureYieldToken(uint256 newPeriodIndex)
        external
        onlyRegisteredFutureVault
        returns (address newToken)
    {
        IFutureVault futureVault = IFutureVault(msg.sender);
        IERC20 pt = IERC20(futureVault.getPTAddress());
        IERC20 ibt = IERC20(futureVault.getIBTAddress());
        uint256 periodDuration = futureVault.PERIOD_DURATION();

        string memory tokenDenomination = _getFYTSymbol(pt.symbol(), periodDuration);
        bytes memory payload = abi.encodeWithSignature(
            "initialize(string,string,uint8,uint256,address)",
            tokenDenomination,
            tokenDenomination,
            ibt.decimals(),
            newPeriodIndex,
            address(futureVault)
        );
        newToken = _clonePositonToken(
            registry.getFYTLogicAddress(),
            payload,
            keccak256(abi.encodePacked(tokenDenomination, msg.sender, newPeriodIndex))
        );

        emit FytDeployed(msg.sender, newToken);
    }

    /**
     * @notice Getter for the symbol of the APWine IBT of one futureVault
     * @param _ibtSymbol the IBT of the external protocol
     * @param _platform the external protocol name
     * @param _periodDuration the duration of the periods for the futureVault
     * @return the generated symbol of the APWine IBT
     */
    function _getFutureIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) internal pure returns (string memory) {
        return APWineNaming.genIBTSymbol(_ibtSymbol, _platform, _periodDuration);
    }

    /**
     * @notice Getter for the symbol of the FYT of one futureVault
     * @param _ptSymbol the APWine IBT symbol for this futureVault
     * @param _periodDuration the duration of the periods for this futureVault
     * @return the generated symbol of the FYT
     */
    function _getFYTSymbol(string memory _ptSymbol, uint256 _periodDuration) internal view returns (string memory) {
        return
            APWineNaming.genFYTSymbolFromIBT(
                uint8(IController(registry.getControllerAddress()).getPeriodIndex(_periodDuration)),
                _ptSymbol
            );
    }

    /**
     * @notice Clones the position token - { returns position token address }
     *
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone.
     *
     * @param _logic is the address of token whose behaviour needs to be mimicked
     * @param _data is the payload for the token address.
     * @param _salt is a salt used to deterministically deploy the clone
     *
     */
    function _clonePositonToken(
        address _logic,
        bytes memory _data,
        bytes32 _salt
    ) private returns (address proxy) {
        proxy = ClonesUpgradeable.cloneDeterministic(_logic, _salt);
        emit ProxyCreated(address(proxy));

        if (_data.length > 0) {
            (bool success, ) = proxy.call(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/apwine/IRegistry.sol";

import "contracts/utils/RoleCheckable.sol";

contract RegistryStorage is RoleCheckable {
    IRegistry internal registry;

    event RegistryChanged(IRegistry _registry);

    /* User Methods */

    /**
     * @notice Setter for the registry address
     * @param _registry the address of the new registry
     */
    function setRegistry(IRegistry _registry) external onlyAdmin {
        registry = _registry;
        emit RegistryChanged(_registry);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/apwine/tokens/IPT.sol";
import "contracts/interfaces/apwine/IRegistry.sol";
import "contracts/interfaces/apwine/IFutureWallet.sol";

interface IFutureVault {
    /* Events */
    event NewPeriodStarted(uint256 _newPeriodIndex);
    event FutureWalletSet(address _futureWallet);
    event RegistrySet(IRegistry _registry);
    event FundsDeposited(address _user, uint256 _amount);
    event FundsWithdrawn(address _user, uint256 _amount);
    event PTSet(IPT _pt);
    event LiquidityTransfersPaused();
    event LiquidityTransfersResumed();
    event DelegationCreated(address _delegator, address _receiver, uint256 _amount);
    event DelegationRemoved(address _delegator, address _receiver, uint256 _amount);

    /* Params */
    /**
     * @notice Getter for the PERIOD future parameter
     * @return returns the period duration of the future
     */
    function PERIOD_DURATION() external view returns (uint256);

    /**
     * @notice Getter for the PLATFORM_NAME future parameter
     * @return returns the platform of the future
     */
    function PLATFORM_NAME() external view returns (string memory);

    /**
     * @notice Start a new period
     * @dev needs corresponding permissions for sender
     */
    function startNewPeriod() external;

    /**
     * @notice Exit a terminated pool
     * @param _user the user to exit from the pool
     * @dev only pt are required as there  aren't any new FYTs
     */
    function exitTerminatedFuture(address _user) external;

    /**
     * @notice Update the state of the user and mint claimable pt
     * @param _user user adress
     */
    function updateUserState(address _user) external;

    /**
     * @notice Send the user their owed FYT (and pt if there are some claimable)
     * @param _user address of the user to send the FYT to
     */
    function claimFYT(address _user, uint256 _amount) external;

    /**
     * @notice Deposit funds into ongoing period
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev part of the amount deposited will be used to buy back the yield already generated proportionally to the amount deposited
     */
    function deposit(address _user, uint256 _amount) external;

    /**
     * @notice Sender unlocks the locked funds corresponding to their pt holding
     * @param _user user adress
     * @param _amount amount of funds to unlock
     * @dev will require a transfer of FYT of the ongoing period corresponding to the funds unlocked
     */
    function withdraw(address _user, uint256 _amount) external;

    /**
     * @notice Create a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to delegate
     */
    function createFYTDelegationTo(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Remove a delegation from one address to another
     * @param _delegator the address delegating its future FYTs
     * @param _receiver the address receiving the future FYTs
     * @param _amount the of future FYTs to remove from the delegation
     */
    function withdrawFYTDelegationFrom(
        address _delegator,
        address _receiver,
        uint256 _amount
    ) external;

    /* Getters */

    /**
     * @notice Getter the total number of FYTs on address is delegating
     * @param _delegator the delegating address
     * @return totalDelegated the number of FYTs delegated
     */
    function getTotalDelegated(address _delegator) external view returns (uint256 totalDelegated);

    /**
     * @notice Getter for next period index
     * @return next period index
     * @dev index starts at 1
     */
    function getNextPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for current period index
     * @return current period index
     * @dev index starts at 1
     */
    function getCurrentPeriodIndex() external view returns (uint256);

    /**
     * @notice Getter for the amount of pt that the user can claim
     * @param _user user to check the check the claimable pt of
     * @return the amount of pt claimable by the user
     */
    function getClaimablePT(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount (in underlying) of premium redeemable with the corresponding amount of fyt/pt to be burned
     * @param _user user adress
     * @return premiumLocked the premium amount unlockage at this period (in underlying), amountRequired the amount of pt/fyt required for that operation
     */
    function getUserEarlyUnlockablePremium(address _user)
        external
        view
        returns (uint256 premiumLocked, uint256 amountRequired);

    /**
     * @notice Getter for user IBT amount that is unlockable
     * @param _user the user to unlock the IBT from
     * @return the amount of IBT the user can unlock
     */
    function getUnlockableFunds(address _user) external view returns (uint256);

    /**
     * @notice Getter for the amount of FYT that the user can claim for a certain period
     * @param _user the user to check the claimable FYT of
     * @param _periodIndex period ID to check the claimable FYT of
     * @return the amount of FYT claimable by the user for this period ID
     */
    function getClaimableFYTForPeriod(address _user, uint256 _periodIndex) external view returns (uint256);

    /**
     * @notice Getter for the yield currently generated by one pt for the current period
     * @return the amount of yield (in IBT) generated during the current period
     */
    function getUnrealisedYieldPerPT() external view returns (uint256);

    /**
     * @notice Getter for the number of pt that can be minted for an amoumt deposited now
     * @param _amount the amount to of IBT to deposit
     * @return the number of pt that can be minted for that amount
     */
    function getPTPerAmountDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for premium in underlying tokens that can be redeemed at the end of the period of the deposit
     * @param _amount the amount of underlying deposited
     * @return the number of underlying of the ibt deposited that will be redeemable
     */
    function getPremiumPerUnderlyingDeposited(uint256 _amount) external view returns (uint256);

    /**
     * @notice Getter for total underlying deposited in the vault
     * @return the total amount of funds deposited in the vault (in underlying)
     */
    function getTotalUnderlyingDeposited() external view returns (uint256);

    /**
     * @notice Getter for the total yield generated during one period
     * @param _periodID the period id
     * @return the total yield in underlying value
     */
    function getYieldOfPeriod(uint256 _periodID) external view returns (uint256);

    /**
     * @notice Getter for controller address
     * @return the controller address
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for futureWallet address
     * @return futureWallet address
     */
    function getFutureWalletAddress() external view returns (address);

    /**
     * @notice Getter for the IBT address
     * @return IBT address
     */
    function getIBTAddress() external view returns (address);

    /**
     * @notice Getter for future pt address
     * @return pt address
     */
    function getPTAddress() external view returns (address);

    /**
     * @notice Getter for FYT address of a particular period
     * @param _periodIndex period index
     * @return FYT address
     */
    function getFYTofPeriod(uint256 _periodIndex) external view returns (address);

    /**
     * @notice Getter for the terminated state of the future
     * @return true if this vault is terminated
     */
    function isTerminated() external view returns (bool);

    /**
     * @notice Getter for the performance fee factor of the current period
     * @return the performance fee factor of the futureVault
     */
    function getPerformanceFeeFactor() external view returns (uint256);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the vault
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllVaultRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemVaultRewards(address _rewardToken) external;

    /**
     * @notice Add a token to the list of reward tokens
     * @param _token the reward token to add to the list
     * @dev the token must be different than the ibt
     */
    function addRewardsToken(address _token) external;

    /**
     * @notice Getter to check if a token is in the reward tokens list
     * @param _token the token to check if it is in the list
     * @return true if the token is a reward token
     */
    function isRewardToken(address _token) external view returns (bool);

    /**
     * @notice Getter for the reward token at an index
     * @param _index the index of the reward token in the list
     * @return the address of the token at this index
     */
    function getRewardTokenAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for the size of the list of reward tokens
     * @return the number of token in the list
     */
    function getRewardTokensCount() external view returns (uint256);

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;

    /* Admin functions */

    /**
     * @notice Set futureWallet address
     */
    function setFutureWallet(IFutureWallet _futureWallet) external;

    /**
     * @notice Set Registry
     */
    function setRegistry(IRegistry _registry) external;

    /**
     * @notice Pause liquidity transfers
     */
    function pauseLiquidityTransfers() external;

    /**
     * @notice Resume liquidity transfers
     */
    function resumeLiquidityTransfers() external;

    /**
     * @notice Convert an amount of IBTs in its equivalent in underlying tokens
     * @param _amount the amount of IBTs
     * @return the corresponding amount of underlying
     */
    function convertIBTToUnderlying(uint256 _amount) external view returns (uint256);

    /**
     * @notice Convert an amount of underlying tokens in its equivalent in IBTs
     * @param _amount the amount of underlying tokens
     * @return the corresponding amount of IBTs
     */
    function convertUnderlyingtoIBT(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRegistry {
    /* Setters */
    /**
     * @notice Setter for the treasury address
     * @param _newTreasury the address of the new treasury
     */
    function setTreasury(address _newTreasury) external;

    /**
     * @notice Setter for the controller address
     * @param _newController the address of the new controller
     */
    function setController(address _newController) external;

    /**
     * @notice Setter for the APWine IBT logic address
     * @param _PTLogic the address of the new APWine IBT logic
     */
    function setPTLogic(address _PTLogic) external;

    /**
     * @notice Setter for the APWine FYT logic address
     * @param _FYTLogic the address of the new APWine FYT logic
     */
    function setFYTLogic(address _FYTLogic) external;

    /**
     * @notice Getter for the controller address
     * @return the address of the controller
     */
    function getControllerAddress() external view returns (address);

    /**
     * @notice Getter for the treasury address
     * @return the address of the treasury
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @notice Getter for the token factory address
     * @return the token factory address
     */
    function getTokensFactoryAddress() external view returns (address);

    /**
     * @notice Getter for APWine IBT logic address
     * @return the APWine IBT logic address
     */
    function getPTLogicAddress() external view returns (address);

    /**
     * @notice Getter for APWine FYT logic address
     * @return the APWine FYT logic address
     */
    function getFYTLogicAddress() external view returns (address);

    /* Futures */
    /**
     * @notice Add a future to the registry
     * @param _future the address of the future to add to the registry
     */
    function addFutureVault(address _future) external;

    /**
     * @notice Remove a future from the registry
     * @param _future the address of the future to remove from the registry
     */
    function removeFutureVault(address _future) external;

    /**
     * @notice Getter to check if a future is registered
     * @param _future the address of the future to check the registration of
     * @return true if it is, false otherwise
     */
    function isRegisteredFutureVault(address _future) external view returns (bool);

    /**
     * @notice Getter for the future registered at an index
     * @param _index the index of the future to return
     * @return the address of the corresponding future
     */
    function getFutureVaultAt(uint256 _index) external view returns (address);

    /**
     * @notice Getter for number of future registered
     * @return the number of future registered
     */
    function futureVaultCount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "contracts/interfaces/apwine/IFutureVault.sol";
import "contracts/interfaces/apwine/IRegistry.sol";

interface IController {
    /* Events */

    event NextPeriodSwitchSet(uint256 _periodDuration, uint256 _nextSwitchTimestamp);
    event NewPeriodDurationIndexSet(uint256 _periodIndex);
    event FutureRegistered(IFutureVault _futureVault);
    event FutureUnregistered(IFutureVault _futureVault);
    event StartingDelaySet(uint256 _startingDelay);
    event NewPerformanceFeeFactor(IFutureVault _futureVault, uint256 _feeFactor);
    event FutureTerminated(IFutureVault _futureVault);
    event DepositsPaused(IFutureVault _futureVault);
    event DepositsResumed(IFutureVault _futureVault);
    event WithdrawalsPaused(IFutureVault _futureVault);
    event WithdrawalsResumed(IFutureVault _futureVault);
    event RegistryChanged(IRegistry _registry);
    event FutureSetToBeTerminated(IFutureVault _futureVault);

    /* Params */

    function STARTING_DELAY() external view returns (uint256);

    /* User Methods */

    /**
     * @notice Deposit funds into ongoing period
     * @param _futureVault the address of the futureVault to be deposit the funds in
     * @param _amount the amount to deposit on the ongoing period
     * @dev part of the amount depostied will be used to buy back the yield already generated proportionaly to the amount deposited
     */
    function deposit(address _futureVault, uint256 _amount) external;

    /**
     * @notice Withdraw deposited funds from APWine
     * @param _futureVault the address of the futureVault to withdraw the IBT from
     * @param _amount the amount to withdraw
     */
    function withdraw(address _futureVault, uint256 _amount) external;

    /**
     * @notice Exit a terminated pool
     * @param _futureVault the address of the futureVault to exit from from
     * @param _user the user to exit from the pool
     * @dev only pt are required as there  aren't any new FYTs
     */
    function exitTerminatedFuture(address _futureVault, address _user) external;

    /**
     * @notice Create a delegation from one address to another for a futureVault
     * @param _futureVault the corresponding futureVault address
     * @param _receiver the address receiving the futureVault FYTs
     * @param _amount the of futureVault FYTs to delegate
     */
    function createFYTDelegationTo(
        address _futureVault,
        address _receiver,
        uint256 _amount
    ) external;

    /**
     * @notice Remove a delegation from one address to another for a futureVault
     * @param _futureVault the corresponding futureVault address
     * @param _receiver the address receiving the futureVault FYTs
     * @param _amount the of futureVault FYTs to remove from the delegation
     */
    function withdrawFYTDelegationFrom(
        address _futureVault,
        address _receiver,
        uint256 _amount
    ) external;

    /* Getters */

    /**
     * @notice Getter for the registry address of the protocol
     * @return the address of the protocol registry
     */
    function getRegistryAddress() external view returns (address);

    /**
     * @notice Getter for the period index depending on the period duration of the futureVault
     * @param _periodDuration the duration of the periods
     * @return the period index
     */
    function getPeriodIndex(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for the beginning timestamp of the next period for the futures with a defined period duration
     * @param _periodDuration the duration of the periods
     * @return the timestamp of the beginning of the next period
     */
    function getNextPeriodStart(uint256 _periodDuration) external view returns (uint256);

    /**
     * @notice Getter for the next performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the next performance fee factor of the futureVault
     */
    function getNextPerformanceFeeFactor(address _futureVault) external view returns (uint256);

    /**
     * @notice Getter for the performance fee factor of one futureVault
     * @param _futureVault the address of the futureVault
     * @return the performance fee factor of the futureVault
     */
    function getCurrentPerformanceFeeFactor(address _futureVault) external view returns (uint256);

    /**
     * @notice Getter for the list of futureVault durations registered in the contract
     * @return durationsList which consists of futureVault durations
     */
    function getDurations() external view returns (uint256[] memory durationsList);

    /**
     * @notice Getter for the futures by period duration
     * @param _periodDuration the period duration of the futures to return
     */
    function getFuturesWithDuration(uint256 _periodDuration) external view returns (address[] memory filteredFutures);

    /**
     * @notice Getter for the futureVault period state
     * @param _futureVault the address of the futureVault
     * @return true if the futureVault is terminated
     */
    function isFutureTerminated(address _futureVault) external view returns (bool);

    /**
     * @notice Getter for the futureVault period state
     * @param _futureVault the address of the futureVault
     * @return true if the futureVault is set to be terminated at its expiration
     */
    function isFutureSetToBeTerminated(address _futureVault) external view returns (bool);

    /**
     * @notice Getter for the futureVault withdrawals state
     * @param _futureVault the address of the futureVault
     * @return true is new withdrawals are paused, false otherwise
     */
    function isWithdrawalsPaused(address _futureVault) external view returns (bool);

    /**
     * @notice Getter for the futureVault deposits state
     * @param _futureVault the address of the futureVault
     * @return true is new deposits are paused, false otherwise
     */
    function isDepositsPaused(address _futureVault) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20 is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library APWineNaming {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice generate the symbol of the FYT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the FYT
     * @dev i.e 30D-AAVE-ADAI-2
     */
    function genFYTSymbol(
        uint8 _index,
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) internal pure returns (string memory) {
        return concatenate(genIBTSymbol(_ibtSymbol, _platform, _periodDuration), concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the symbol from the PT
     * @param _index the index of the current period
     * @param _ibtSymbol the symbol of the IBT
     * @return the symbol for the FYT
     * @dev i.e ADAI-2
     */
    function genFYTSymbolFromIBT(uint8 _index, string memory _ibtSymbol) internal pure returns (string memory) {
        return concatenate(_ibtSymbol, concatenate("-", uintToString(_index)));
    }

    /**
     * @notice generate the PT symbol
     * @param _ibtSymbol the symbol of the IBT of the future
     * @param _platform the platform name
     * @param _periodDuration the period duration
     * @return the symbol for the PT
     * @dev i.e 30D-AAVE-ADAI
     */
    function genIBTSymbol(
        string memory _ibtSymbol,
        string memory _platform,
        uint256 _periodDuration
    ) internal pure returns (string memory) {
        return
            concatenate(
                getPeriodDurationDenominator(_periodDuration),
                concatenate("-", concatenate(_platform, concatenate("-", _ibtSymbol)))
            );
    }

    /**
     * @notice generate the period denominator
     * @param _periodDuration the period duration
     * @return the period denominator
     * @dev i.e 30D
     */
    function getPeriodDurationDenominator(uint256 _periodDuration) internal pure returns (string memory) {
        if (_periodDuration >= 1 days) {
            uint256 numberOfdays = _periodDuration.div(1 days);
            return string(concatenate(uintToString(numberOfdays), "D"));
        }
        return "CUSTOM";
    }

    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract RoleCheckable is AccessControlUpgradeable {
    /* ACR Roles*/

    // keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 internal constant ADMIN_ROLE = 0x1effbbff9c66c5e59634f24fe842750c60d18891155c32dd155fc2d661a4c86d;
    // keccak256("CONTROLLER_ROLE")
    bytes32 internal constant CONTROLLER_ROLE = 0x7b765e0e932d348852a6f810bfa1ab891e259123f02db8cdcde614c570223357;
    // keccak256("START_FUTURE")
    bytes32 internal constant START_FUTURE = 0xeb5092aab714e6356486bc97f25dd7a5c1dc5c7436a9d30e8d4a527fba24de1c;
    // keccak256("FUTURE_ROLE")
    bytes32 internal constant FUTURE_ROLE = 0x52d2dbc4d362e84c42bdfb9941433968ba41423559d7559b32db1183b22b148f;
    // keccak256("HARVEST_REWARDS")
    bytes32 internal constant HARVEST_REWARDS = 0xf2683e58e5a2a04c1ed32509bfdbf1e9ebc725c63f4c95425d2afd482bfdb0f8;

    /* Modifiers */

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "RoleCheckable: Caller should be ADMIN");
        _;
    }

    modifier onlyStartFuture() {
        require(hasRole(START_FUTURE, msg.sender), "RoleCheckable: Caller should have START FUTURE Role");
        _;
    }

    modifier onlyHarvestReward() {
        require(hasRole(HARVEST_REWARDS, msg.sender), "RoleCheckable: Caller should have HARVEST REWARDS Role");
        _;
    }

    modifier onlyController() {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "RoleCheckable: Caller should be CONTROLLER");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "contracts/interfaces/IERC20.sol";

interface IPT is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @notice Returns the current balance of one user (without the claimable amount)
     * @param account the address of the account to check the balance of
     * @return the current pt balance of this address
     */
    function recordedBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Returns the current balance of one user including the pt that were not claimed yet
     * @param account the address of the account to check the balance of
     * @return the total pt balance of one address
     */
    function balanceOf(address account) external view override returns (uint256);

    /**
     * @notice Getter for the future vault link to this pt
     * @return the address of the future vault
     */
    function futureVault() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IFutureWallet {
    /* Events */

    event YieldRedeemed(address _user, uint256 _periodIndex);
    event WithdrawalsPaused();
    event WithdrawalsResumed();

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) external;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) external;

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _user the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _user) external view returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureVaultAddress() external view returns (address);

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() external view returns (address);

    /* Rewards mecanisms*/

    /**
     * @notice Harvest all rewards from the future wallet
     */
    function harvestRewards() external;

    /**
     * @notice Transfer all the redeemable rewards to set defined recipient
     */
    function redeemAllWalletRewards() external;

    /**
     * @notice Transfer the specified token reward balance tot the defined recipient
     * @param _rewardToken the reward token to redeem the balance of
     */
    function redeemWalletRewards(address _rewardToken) external;

    /**
     * @notice Getter for the address of the rewards recipient
     * @return the address of the rewards recipient
     */
    function getRewardsRecipient() external view returns (address);

    /**
     * @notice Setter for the address of the rewards recipient
     */
    function setRewardRecipient(address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}