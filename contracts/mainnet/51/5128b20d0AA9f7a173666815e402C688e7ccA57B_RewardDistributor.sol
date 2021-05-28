//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interface/IiToken.sol";
import "./interface/IRewardDistributor.sol";
import "./interface/IPriceOracle.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";
import "./library/SafeRatioMath.sol";
import "./Controller.sol";

/**
 * @title dForce's lending reward distributor Contract
 * @author dForce
 */
contract RewardDistributor is Initializable, Ownable, IRewardDistributor {
    using SafeRatioMath for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice the controller
    Controller public controller;

    /// @notice the global Reward distribution speed
    uint256 public globalDistributionSpeed;

    /// @notice the Reward distribution speed of each iToken
    mapping(address => uint256) public distributionSpeed;

    /// @notice the Reward distribution factor of each iToken, 1.0 by default. stored as a mantissa
    mapping(address => uint256) public distributionFactorMantissa;

    struct DistributionState {
        // Token's last updated index, stored as a mantissa
        uint256 index;
        // The block number the index was last updated at
        uint256 block;
    }

    /// @notice the Reward distribution supply state of each iToken
    mapping(address => DistributionState) public distributionSupplyState;
    /// @notice the Reward distribution borrow state of each iToken
    mapping(address => DistributionState) public distributionBorrowState;

    /// @notice the Reward distribution state of each account of each iToken
    mapping(address => mapping(address => uint256))
        public distributionSupplierIndex;
    /// @notice the Reward distribution state of each account of each iToken
    mapping(address => mapping(address => uint256))
        public distributionBorrowerIndex;

    /// @notice the Reward distributed into each account
    mapping(address => uint256) public reward;

    /// @notice the Reward token address
    address public rewardToken;

    /// @notice whether the reward distribution is paused
    bool public paused;

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(
            address(controller) == msg.sender,
            "onlyController: caller is not the controller"
        );
        _;
    }

    /**
     * @notice Initializes the contract.
     */
    function initialize(Controller _controller) external initializer {
        __Ownable_init();
        controller = _controller;
        paused = true;
    }

    /**
     * @notice set reward token address
     * @dev Admin function, only owner can call this
     * @param _newRewardToken the address of reward token
     */
    function _setRewardToken(address _newRewardToken)
        external
        override
        onlyOwner
    {
        address _oldRewardToken = rewardToken;
        require(
            _newRewardToken != address(0) && _newRewardToken != _oldRewardToken,
            "Reward token address invalid"
        );
        rewardToken = _newRewardToken;
        emit NewRewardToken(_oldRewardToken, _newRewardToken);
    }

    /**
     * @notice Add the iToken as receipient
     * @dev Admin function, only controller can call this
     * @param _iToken the iToken to add as recipient
     * @param _distributionFactor the distribution factor of the recipient
     */
    function _addRecipient(address _iToken, uint256 _distributionFactor)
        external
        override
        onlyController
    {
        distributionFactorMantissa[_iToken] = _distributionFactor;
        distributionSupplyState[_iToken] = DistributionState({
            index: 0,
            block: block.number
        });
        distributionBorrowState[_iToken] = DistributionState({
            index: 0,
            block: block.number
        });

        emit NewRecipient(_iToken, _distributionFactor);
    }

    /**
     * @notice Pause the reward distribution
     * @dev Admin function, pause will set global speed to 0 to stop the accumulation
     */
    function _pause() external override onlyOwner {
        // Set the global distribution speed to 0 to stop accumulation
        _setGlobalDistributionSpeed(0);

        _setPaused(true);
    }

    /**
     * @notice Unpause and set global distribution speed
     * @dev Admin function
     * @param _speed The speed of Reward distribution per second
     */
    function _unpause(uint256 _speed) external override onlyOwner {
        _setPaused(false);

        _setGlobalDistributionSpeed(_speed);
    }

    /**
     * @notice Pause/Unpause the reward distribution
     * @dev Admin function
     * @param _paused whether to pause/unpause the distribution
     */
    function _setPaused(bool _paused) internal {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @notice Sets the global distribution speed, updating each iToken's speed accordingly
     * @dev Admin function, will fail when paused
     * @param _speed The speed of Reward distribution per second
     */
    function _setGlobalDistributionSpeed(uint256 _speed)
        public
        override
        onlyOwner
    {
        require(!paused, "Can not change global speed when paused");

        globalDistributionSpeed = _speed;

        _updateDistributionSpeed();

        emit GlobalDistributionSpeedUpdated(_speed);
    }

    /**
     * @notice Update each iToken's distribution speed according to current global speed
     * @dev Only EOA can call this function
     */
    function updateDistributionSpeed() public override {
        require(msg.sender == tx.origin, "only EOA can update speeds");
        require(!paused, "Can not update speeds when paused");

        // Do the actual update
        _updateDistributionSpeed();
    }

    /**
     * @notice Internal function to update each iToken's distribution speed
     */
    function _updateDistributionSpeed() internal {
        address[] memory _iTokens = controller.getAlliTokens();
        uint256 _globalspeed = globalDistributionSpeed;
        uint256 _len = _iTokens.length;

        uint256[] memory _tokenValues = new uint256[](_len);
        uint256 _totalValue;

        // Calculates the total value and token value
        // tokenValue = tokenTotalBorrow * price * tokenDistributionFactorMantissa
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_iTokens[i]);

            // Update both supply and borrow state before updating new speed
            _updateDistributionState(address(_token), true);
            _updateDistributionState(address(_token), false);

            uint256 _totalBorrow = _token.totalBorrows();

            // It is okay if the underlying price is 0
            uint256 _underlyingPrice =
                IPriceOracle(controller.priceOracle()).getUnderlyingPrice(
                    address(_token)
                );

            _tokenValues[i] = _totalBorrow.mul(_underlyingPrice).rmul(
                distributionFactorMantissa[address(_token)]
            );

            _totalValue = _totalValue.add(_tokenValues[i]);
        }

        // Calculates the distribution speed for each token
        for (uint256 i = 0; i < _len; i++) {
            address _token = _iTokens[i];
            uint256 _speed =
                _totalValue > 0
                    ? _globalspeed.mul(_tokenValues[i]).div(_totalValue)
                    : 0;
            distributionSpeed[_token] = _speed;

            emit DistributionSpeedUpdated(_token, _speed);
        }
    }

    /**
     * @notice Sets the distribution factor for a iToken
     * @dev Admin function to set distribution factor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newDistributionFactorMantissa The new distribution factor, scaled by 1e18
     */
    function _setDistributionFactor(
        address _iToken,
        uint256 _newDistributionFactorMantissa
    ) internal {
        // iToken must have been listed
        require(controller.hasiToken(_iToken), "Token has not been listed");

        uint256 _oldDistributionFactorMantissa =
            distributionFactorMantissa[_iToken];
        distributionFactorMantissa[_iToken] = _newDistributionFactorMantissa;

        emit NewDistributionFactor(
            _iToken,
            _oldDistributionFactorMantissa,
            _newDistributionFactorMantissa
        );
    }

    /**
     * @notice Sets the distribution factors for a list of iTokens
     * @dev Admin function to set distribution factors for a list of iTokens
     * @param _iTokens The list of tokens to set the factor on
     * @param _distributionFactors The list of distribution factors, scaled by 1e18
     */
    function _setDistributionFactors(
        address[] calldata _iTokens,
        uint256[] calldata _distributionFactors
    ) external override onlyOwner {
        require(
            _iTokens.length == _distributionFactors.length,
            "Length of _iTokens and _distributionFactors mismatch"
        );

        uint256 _len = _iTokens.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDistributionFactor(_iTokens[i], _distributionFactors[i]);
        }

        // Update the distribution speed of all iTokens
        updateDistributionSpeed();
    }

    /**
     * @notice Update the iToken's  Reward distribution state
     * @dev Will be called every time when the iToken's supply/borrow changes
     * @param _iToken The iToken to be updated
     * @param _isBorrow whether to update the borrow state
     */
    function updateDistributionState(address _iToken, bool _isBorrow)
        external
        override
    {
        // Skip all updates if it is paused
        if (paused) {
            return;
        }

        _updateDistributionState(_iToken, _isBorrow);
    }

    function _updateDistributionState(address _iToken, bool _isBorrow)
        internal
    {
        require(controller.hasiToken(_iToken), "Token has not been listed");

        DistributionState storage state =
            _isBorrow
                ? distributionBorrowState[_iToken]
                : distributionSupplyState[_iToken];

        uint256 _speed = distributionSpeed[_iToken];
        uint256 _blockNumber = block.number;
        uint256 _deltaBlocks = _blockNumber.sub(state.block);

        if (_deltaBlocks > 0 && _speed > 0) {
            uint256 _totalToken =
                _isBorrow
                    ? IiToken(_iToken).totalBorrows()
                    : IERC20Upgradeable(_iToken).totalSupply();
            uint256 _totalDistributed = _speed.mul(_deltaBlocks);

            // Reward distributed per token since last time
            uint256 _distributedPerToken =
                _totalToken > 0 ? _totalDistributed.rdiv(_totalToken) : 0;

            state.index = state.index.add(_distributedPerToken);
        }

        state.block = _blockNumber;
    }

    /**
     * @notice Update the account's Reward distribution state
     * @dev Will be called every time when the account's supply/borrow changes
     * @param _iToken The iToken to be updated
     * @param _account The account to be updated
     * @param _isBorrow whether to update the borrow state
     */
    function updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) external override {
        // Skip all updates if it is paused
        if (paused) {
            return;
        }

        _updateReward(_iToken, _account, _isBorrow);
    }

    function _updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) internal {
        require(_account != address(0), "Invalid account address!");
        require(controller.hasiToken(_iToken), "Token has not been listed");

        uint256 _iTokenIndex;
        uint256 _accountIndex;
        uint256 _accountBalance;
        if (_isBorrow) {
            _iTokenIndex = distributionBorrowState[_iToken].index;
            _accountIndex = distributionBorrowerIndex[_iToken][_account];
            _accountBalance = IiToken(_iToken).borrowBalanceStored(_account);

            // Update the account state to date
            distributionBorrowerIndex[_iToken][_account] = _iTokenIndex;
        } else {
            _iTokenIndex = distributionSupplyState[_iToken].index;
            _accountIndex = distributionSupplierIndex[_iToken][_account];
            _accountBalance = IERC20Upgradeable(_iToken).balanceOf(_account);

            // Update the account state to date
            distributionSupplierIndex[_iToken][_account] = _iTokenIndex;
        }

        uint256 _deltaIndex = _iTokenIndex.sub(_accountIndex);
        uint256 _amount = _accountBalance.rmul(_deltaIndex);

        if (_amount > 0) {
            reward[_account] = reward[_account].add(_amount);

            emit RewardDistributed(_iToken, _account, _amount, _accountIndex);
        }
    }

    /**
     * @notice Claim reward accrued in iTokens by the holders
     * @param _holders The account to claim for
     * @param _iTokens The _iTokens to claim from
     */
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        public
        override
    {
        // Update rewards for all _iTokens for holders
        for (uint256 i = 0; i < _iTokens.length; i++) {
            address _iToken = _iTokens[i];
            _updateDistributionState(_iToken, false);
            _updateDistributionState(_iToken, true);
            for (uint256 j = 0; j < _holders.length; j++) {
                _updateReward(_iToken, _holders[j], false);
                _updateReward(_iToken, _holders[j], true);
            }
        }

        // Withdraw all reward for all holders
        for (uint256 j = 0; j < _holders.length; j++) {
            address _account = _holders[j];
            uint256 _reward = reward[_account];
            if (_reward > 0) {
                reward[_account] = 0;
                IERC20Upgradeable(rewardToken).safeTransfer(_account, _reward);
            }
        }
    }

    /**
     * @notice Claim reward accrued in all iTokens by the holders
     * @param _holders The account to claim for
     */
    function claimAllReward(address[] memory _holders) external override {
        claimReward(_holders, controller.getAlliTokens());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IInterestRateModelInterface.sol";
import "./IControllerInterface.sol";

interface IiToken {
    function isiToken() external returns (bool);

    //----------------------------------
    //********* User Interface *********
    //----------------------------------
    function mint(address recipient, uint256 mintAmount) external;

    function redeem(address from, uint256 redeemTokens) external;

    function redeemUnderlying(address from, uint256 redeemAmount) external;

    function borrow(uint256 borrowAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address iTokenCollateral
    ) external;

    function flashloan(
        address recipient,
        uint256 loanAmount,
        bytes memory data
    ) external;

    function seize(
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external;

    function updateInterest() external returns (bool);

    function controller() external view returns (address);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowBalanceCurrent(address _user) external returns (uint256);

    function borrowBalanceStored(address _user) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function getAccountSnapshot(address _account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getCash() external view returns (uint256);

    //----------------------------------
    //********* Owner Actions **********
    //----------------------------------

    function _setNewReserveRatio(uint256 _newReserveRatio) external;

    function _setNewFlashloanFeeRatio(uint256 _newFlashloanFeeRatio) external;

    function _setNewProtocolFeeRatio(uint256 _newProtocolFeeRatio) external;

    function _setController(IControllerInterface _newController) external;

    function _setInterestRateModel(
        IInterestRateModelInterface _newInterestRateModel
    ) external;

    function _withdrawReserves(uint256 _withdrawAmount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRewardDistributor {
    function _setRewardToken(address newRewardToken) external;

    /// @notice Emitted reward token address is changed by admin
    event NewRewardToken(address oldRewardToken, address newRewardToken);

    function _addRecipient(address _iToken, uint256 _distributionFactor)
        external;

    event NewRecipient(address iToken, uint256 distributionFactor);

    /// @notice Emitted when mint is paused/unpaused by admin
    event Paused(bool paused);

    function _pause() external;

    function _unpause(uint256 _speed) external;

    /// @notice Emitted when Global Distribution speed is updated
    event GlobalDistributionSpeedUpdated(uint256 speed);

    function _setGlobalDistributionSpeed(uint256 speed) external;

    /// @notice Emitted when iToken's Distribution speed is updated
    event DistributionSpeedUpdated(address iToken, uint256 speed);

    function updateDistributionSpeed() external;

    /// @notice Emitted when iToken's Distribution factor is changed by admin
    event NewDistributionFactor(
        address iToken,
        uint256 oldDistributionFactorMantissa,
        uint256 newDistributionFactorMantissa
    );

    function _setDistributionFactors(
        address[] calldata iToken,
        uint256[] calldata distributionFactors
    ) external;

    function updateDistributionState(address _iToken, bool _isBorrow) external;

    function updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) external;

    function claimReward(address[] memory _holders, address[] memory _iTokens)
        external;

    function claimAllReward(address[] memory _holders) external;

    /// @notice Emitted when reward of amount is distributed into account
    event RewardDistributed(
        address iToken,
        address account,
        uint256 amount,
        uint256 accountIndex
    );
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IiToken.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a iToken asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address _iToken)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            !_initialized,
            "Initializable: contract is already initialized"
        );

        _;

        _initialized = true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {_setPendingOwner} and {_acceptOwner}.
 */
contract Ownable {
    /**
     * @dev Returns the address of the current owner.
     */
    address payable public owner;

    /**
     * @dev Returns the address of the current pending owner.
     */
    address payable public pendingOwner;

    event NewOwner(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(
        address indexed oldPendingOwner,
        address indexed newPendingOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal {
        owner = msg.sender;
        emit NewOwner(address(0), msg.sender);
    }

    /**
     * @notice Base on the inputing parameter `newPendingOwner` to check the exact error reason.
     * @dev Transfer contract control to a new owner. The newPendingOwner must call `_acceptOwner` to finish the transfer.
     * @param newPendingOwner New pending owner.
     */
    function _setPendingOwner(address payable newPendingOwner)
        external
        onlyOwner
    {
        require(
            newPendingOwner != address(0) && newPendingOwner != pendingOwner,
            "_setPendingOwner: New owenr can not be zero address and owner has been set!"
        );

        // Gets current owner.
        address oldPendingOwner = pendingOwner;

        // Sets new pending owner.
        pendingOwner = newPendingOwner;

        emit NewPendingOwner(oldPendingOwner, newPendingOwner);
    }

    /**
     * @dev Accepts the admin rights, but only for pendingOwenr.
     */
    function _acceptOwner() external {
        require(
            msg.sender == pendingOwner,
            "_acceptOwner: Only for pending owner!"
        );

        // Gets current values for events.
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;

        // Set the new contract owner.
        owner = pendingOwner;

        // Clear the pendingOwner.
        pendingOwner = address(0);

        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library SafeRatioMath {
    using SafeMathUpgradeable for uint256;

    uint256 private constant BASE = 10**18;
    uint256 private constant DOUBLE = 10**36;

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.add(y.sub(1)).div(y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).div(BASE);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).add(y.sub(1)).div(y);
    }

    function tmul(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 result) {
        result = x.mul(y).mul(z).div(DOUBLE);
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.

                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(
                                iszero(iszero(x)),
                                iszero(eq(div(zx, x), z))
                            ) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "./interface/IControllerInterface.sol";
import "./interface/IPriceOracle.sol";
import "./interface/IiToken.sol";
import "./interface/IRewardDistributor.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";
import "./library/SafeRatioMath.sol";

/**
 * @title dForce's lending controller Contract
 * @author dForce
 */
contract Controller is Initializable, Ownable, IControllerInterface {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeRatioMath for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev EnumerableSet of all iTokens
    EnumerableSetUpgradeable.AddressSet internal iTokens;

    struct Market {
        /*
         *  Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be in [0, 0.9], and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
        /*
         *  Multiplier representing the most one can borrow the asset.
         *  For instance, 0.5 to allow borrowing this asset 50% * collateral value * collateralFactor.
         *  When calculating equity, 0.5 with 100 borrow balance will produce 200 borrow value
         *  Must be between (0, 1], and stored as a mantissa.
         */
        uint256 borrowFactorMantissa;
        /*
         *  The borrow capacity of the asset, will be checked in beforeBorrow()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be borrowed any more
         */
        uint256 borrowCapacity;
        /*
         *  The supply capacity of the asset, will be checked in beforeMint()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be supplied any more
         */
        uint256 supplyCapacity;
        // Whether market's mint is paused
        bool mintPaused;
        // Whether market's redeem is paused
        bool redeemPaused;
        // Whether market's borrow is paused
        bool borrowPaused;
    }

    /// @notice Mapping of iTokens to corresponding markets
    mapping(address => Market) public markets;

    struct AccountData {
        // Account's collateral assets
        EnumerableSetUpgradeable.AddressSet collaterals;
        // Account's borrowed assets
        EnumerableSetUpgradeable.AddressSet borrowed;
    }

    /// @dev Mapping of accounts' data, including collateral and borrowed assets
    mapping(address => AccountData) internal accountsData;

    /**
     * @notice Oracle to query the price of a given asset
     */
    address public priceOracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    // liquidationIncentiveMantissa must be no less than this value
    uint256 internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint256 internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    // collateralFactorMantissa must not exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 1e18; // 1.0

    // borrowFactorMantissa must not exceed this value
    uint256 internal constant borrowFactorMaxMantissa = 1e18; // 1.0

    /**
     * @notice Guardian who can pause mint/borrow/liquidate/transfer in case of emergency
     */
    address public pauseGuardian;

    /// @notice whether global transfer is paused
    bool public transferPaused;

    /// @notice whether global seize is paused
    bool public seizePaused;

    /**
     * @notice the address of reward distributor
     */
    address public rewardDistributor;

    /**
     * @dev Check if called by owner or pauseGuardian, and only owner can unpause
     */
    modifier checkPauser(bool _paused) {
        require(
            msg.sender == owner || (msg.sender == pauseGuardian && _paused),
            "Only owner and guardian can pause and only owner can unpause"
        );

        _;
    }

    /**
     * @notice Initializes the contract.
     */
    function initialize() external initializer {
        __Ownable_init();
    }

    /*********************************/
    /******** Security Check *********/
    /*********************************/

    /**
     * @notice Ensure this is a Controller contract.
     */
    function isController() external view override returns (bool) {
        return true;
    }

    /*********************************/
    /******** Admin Operations *******/
    /*********************************/

    /**
     * @notice Admin function to add iToken into supported markets
     * Checks if the iToken already exsits
     * Will `revert()` if any check fails
     * @param _iToken The _iToken to add
     * @param _collateralFactor The _collateralFactor of _iToken
     * @param _borrowFactor The _borrowFactor of _iToken
     * @param _supplyCapacity The _supplyCapacity of _iToken
     * @param _distributionFactor The _distributionFactor of _iToken
     */
    function _addMarket(
        address _iToken,
        uint256 _collateralFactor,
        uint256 _borrowFactor,
        uint256 _supplyCapacity,
        uint256 _borrowCapacity,
        uint256 _distributionFactor
    ) external override onlyOwner {
        require(IiToken(_iToken).isiToken(), "Token is not a iToken");

        // Market must not have been listed, EnumerableSet.add() will return false if it exsits
        require(iTokens.add(_iToken), "Token has already been listed");

        require(
            _collateralFactor <= collateralFactorMaxMantissa,
            "Collateral factor invalid"
        );

        require(
            _borrowFactor > 0 && _borrowFactor <= borrowFactorMaxMantissa,
            "Borrow factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Underlying price is unavailable"
        );

        markets[_iToken] = Market({
            collateralFactorMantissa: _collateralFactor,
            borrowFactorMantissa: _borrowFactor,
            borrowCapacity: _borrowCapacity,
            supplyCapacity: _supplyCapacity,
            mintPaused: false,
            redeemPaused: false,
            borrowPaused: false
        });

        IRewardDistributor(rewardDistributor)._addRecipient(
            _iToken,
            _distributionFactor
        );

        emit MarketAdded(
            _iToken,
            _collateralFactor,
            _borrowFactor,
            _supplyCapacity,
            _borrowCapacity,
            _distributionFactor
        );
    }

    /**
     * @notice Sets price oracle
     * @dev Admin function to set price oracle
     * @param _newOracle New oracle contract
     */
    function _setPriceOracle(address _newOracle) external override onlyOwner {
        address _oldOracle = priceOracle;
        require(
            _newOracle != address(0) && _newOracle != _oldOracle,
            "Oracle address invalid"
        );
        priceOracle = _newOracle;
        emit NewPriceOracle(_oldOracle, _newOracle);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Admin function to set closeFactor
     * @param _newCloseFactorMantissa New close factor, scaled by 1e18
     */
    function _setCloseFactor(uint256 _newCloseFactorMantissa)
        external
        override
        onlyOwner
    {
        require(
            _newCloseFactorMantissa >= closeFactorMinMantissa &&
                _newCloseFactorMantissa <= closeFactorMaxMantissa,
            "Close factor invalid"
        );

        uint256 _oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = _newCloseFactorMantissa;
        emit NewCloseFactor(_oldCloseFactorMantissa, _newCloseFactorMantissa);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Admin function to set liquidationIncentive
     * @param _newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     */
    function _setLiquidationIncentive(uint256 _newLiquidationIncentiveMantissa)
        external
        override
        onlyOwner
    {
        require(
            _newLiquidationIncentiveMantissa >=
                liquidationIncentiveMinMantissa &&
                _newLiquidationIncentiveMantissa <=
                liquidationIncentiveMaxMantissa,
            "Liquidation incentive invalid"
        );

        uint256 _oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = _newLiquidationIncentiveMantissa;

        emit NewLiquidationIncentive(
            _oldLiquidationIncentiveMantissa,
            _newLiquidationIncentiveMantissa
        );
    }

    /**
     * @notice Sets the collateralFactor for a iToken
     * @dev Admin function to set collateralFactor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     */
    function _setCollateralFactor(
        address _iToken,
        uint256 _newCollateralFactorMantissa
    ) external override onlyOwner {
        _checkiTokenListed(_iToken);

        require(
            _newCollateralFactorMantissa <= collateralFactorMaxMantissa,
            "Collateral factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Failed to set collateral factor, underlying price is unavailable"
        );

        Market storage _market = markets[_iToken];
        uint256 _oldCollateralFactorMantissa = _market.collateralFactorMantissa;
        _market.collateralFactorMantissa = _newCollateralFactorMantissa;

        emit NewCollateralFactor(
            _iToken,
            _oldCollateralFactorMantissa,
            _newCollateralFactorMantissa
        );
    }

    /**
     * @notice Sets the borrowFactor for a iToken
     * @dev Admin function to set borrowFactor for a iToken
     * @param _iToken The token to set the factor on
     * @param _newBorrowFactorMantissa The new borrow factor, scaled by 1e18
     */
    function _setBorrowFactor(address _iToken, uint256 _newBorrowFactorMantissa)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        require(
            _newBorrowFactorMantissa > 0 &&
                _newBorrowFactorMantissa <= borrowFactorMaxMantissa,
            "Borrow factor invalid"
        );

        // Its value will be taken into account when calculate account equity
        // Check if the price is available for the calculation
        require(
            IPriceOracle(priceOracle).getUnderlyingPrice(_iToken) != 0,
            "Failed to set borrow factor, underlying price is unavailable"
        );

        Market storage _market = markets[_iToken];
        uint256 _oldBorrowFactorMantissa = _market.borrowFactorMantissa;
        _market.borrowFactorMantissa = _newBorrowFactorMantissa;

        emit NewBorrowFactor(
            _iToken,
            _oldBorrowFactorMantissa,
            _newBorrowFactorMantissa
        );
    }

    /**
     * @notice Sets the borrowCapacity for a iToken
     * @dev Admin function to set borrowCapacity for a iToken
     * @param _iToken The token to set the capacity on
     * @param _newBorrowCapacity The new borrow capacity
     */
    function _setBorrowCapacity(address _iToken, uint256 _newBorrowCapacity)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        uint256 oldBorrowCapacity = _market.borrowCapacity;
        _market.borrowCapacity = _newBorrowCapacity;

        emit NewBorrowCapacity(_iToken, oldBorrowCapacity, _newBorrowCapacity);
    }

    /**
     * @notice Sets the supplyCapacity for a iToken
     * @dev Admin function to set supplyCapacity for a iToken
     * @param _iToken The token to set the capacity on
     * @param _newSupplyCapacity The new supply capacity
     */
    function _setSupplyCapacity(address _iToken, uint256 _newSupplyCapacity)
        external
        override
        onlyOwner
    {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        uint256 oldSupplyCapacity = _market.supplyCapacity;
        _market.supplyCapacity = _newSupplyCapacity;

        emit NewSupplyCapacity(_iToken, oldSupplyCapacity, _newSupplyCapacity);
    }

    /**
     * @notice Sets the pauseGuardian
     * @dev Admin function to set pauseGuardian
     * @param _newPauseGuardian The new pause guardian
     */
    function _setPauseGuardian(address _newPauseGuardian)
        external
        override
        onlyOwner
    {
        address _oldPauseGuardian = pauseGuardian;

        require(
            _newPauseGuardian != address(0) &&
                _newPauseGuardian != _oldPauseGuardian,
            "Pause guardian address invalid"
        );

        pauseGuardian = _newPauseGuardian;

        emit NewPauseGuardian(_oldPauseGuardian, _newPauseGuardian);
    }

    /**
     * @notice pause/unpause mint() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllMintPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setMintPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause mint() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setMintPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setMintPausedInternal(_iToken, _paused);
    }

    function _setMintPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].mintPaused = _paused;
        emit MintPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause redeem() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllRedeemPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setRedeemPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause redeem() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setRedeemPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setRedeemPausedInternal(_iToken, _paused);
    }

    function _setRedeemPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].redeemPaused = _paused;
        emit RedeemPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause borrow() for all iTokens
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setAllBorrowPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            _setBorrowPausedInternal(_iTokens.at(i), _paused);
        }
    }

    /**
     * @notice pause/unpause borrow() for the iToken
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _iToken The iToken to pause/unpause
     * @param _paused whether to pause or unpause
     */
    function _setBorrowPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setBorrowPausedInternal(_iToken, _paused);
    }

    function _setBorrowPausedInternal(address _iToken, bool _paused) internal {
        markets[_iToken].borrowPaused = _paused;
        emit BorrowPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause global transfer()
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setTransferPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _setTransferPausedInternal(_paused);
    }

    function _setTransferPausedInternal(bool _paused) internal {
        transferPaused = _paused;
        emit TransferPaused(_paused);
    }

    /**
     * @notice pause/unpause global seize()
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setSeizePaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _setSeizePausedInternal(_paused);
    }

    function _setSeizePausedInternal(bool _paused) internal {
        seizePaused = _paused;
        emit SeizePaused(_paused);
    }

    /**
     * @notice pause/unpause all actions iToken, including mint/redeem/borrow
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setiTokenPaused(address _iToken, bool _paused)
        external
        override
        checkPauser(_paused)
    {
        _checkiTokenListed(_iToken);

        _setiTokenPausedInternal(_iToken, _paused);
    }

    function _setiTokenPausedInternal(address _iToken, bool _paused) internal {
        Market storage _market = markets[_iToken];

        _market.mintPaused = _paused;
        emit MintPaused(_iToken, _paused);

        _market.redeemPaused = _paused;
        emit RedeemPaused(_iToken, _paused);

        _market.borrowPaused = _paused;
        emit BorrowPaused(_iToken, _paused);
    }

    /**
     * @notice pause/unpause entire protocol, including mint/redeem/borrow/seize/transfer
     * @dev Admin function, only owner and pauseGuardian can call this
     * @param _paused whether to pause or unpause
     */
    function _setProtocolPaused(bool _paused)
        external
        override
        checkPauser(_paused)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;
        uint256 _len = _iTokens.length();

        for (uint256 i = 0; i < _len; i++) {
            address _iToken = _iTokens.at(i);

            _setiTokenPausedInternal(_iToken, _paused);
        }

        _setTransferPausedInternal(_paused);
        _setSeizePausedInternal(_paused);
    }

    /**
     * @notice Sets Reward Distributor
     * @dev Admin function to set reward distributor
     * @param _newRewardDistributor new reward distributor
     */
    function _setRewardDistributor(address _newRewardDistributor)
        external
        override
        onlyOwner
    {
        address _oldRewardDistributor = rewardDistributor;
        require(
            _newRewardDistributor != address(0) &&
                _newRewardDistributor != _oldRewardDistributor,
            "Reward Distributor address invalid"
        );

        rewardDistributor = _newRewardDistributor;
        emit NewRewardDistributor(_oldRewardDistributor, _newRewardDistributor);
    }

    /*********************************/
    /******** Poclicy Hooks **********/
    /*********************************/

    /**
     * @notice Hook function before iToken `mint()`
     * Checks if the account should be allowed to mint the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the mint against
     * @param _minter The account which would get the minted tokens
     * @param _mintAmount The amount of underlying being minted to iToken
     */
    function beforeMint(
        address _iToken,
        address _minter,
        uint256 _mintAmount
    ) external override {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        require(!_market.mintPaused, "Token mint has been paused");

        // Check the iToken's supply capacity, -1 means no limit
        uint256 _totalSupplyUnderlying =
            IERC20Upgradeable(_iToken).totalSupply().rmul(
                IiToken(_iToken).exchangeRateStored()
            );
        require(
            _totalSupplyUnderlying.add(_mintAmount) <= _market.supplyCapacity,
            "Token supply capacity reached"
        );

        // Update the Reward Distribution Supply state and distribute reward to suppplier
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _minter,
            false
        );
    }

    /**
     * @notice Hook function after iToken `mint()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being minted
     * @param _minter The account which would get the minted tokens
     * @param _mintAmount The amount of underlying being minted to iToken
     * @param _mintedAmount The amount of iToken being minted
     */
    function afterMint(
        address _iToken,
        address _minter,
        uint256 _mintAmount,
        uint256 _mintedAmount
    ) external override {
        _iToken;
        _minter;
        _mintAmount;
        _mintedAmount;
    }

    /**
     * @notice Hook function before iToken `redeem()`
     * Checks if the account should be allowed to redeem the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the redeem against
     * @param _redeemer The account which would redeem iToken
     * @param _redeemAmount The amount of iToken to redeem
     */
    function beforeRedeem(
        address _iToken,
        address _redeemer,
        uint256 _redeemAmount
    ) external override {
        // _redeemAllowed below will check whether _iToken is listed

        require(!markets[_iToken].redeemPaused, "Token redeem has been paused");

        _redeemAllowed(_iToken, _redeemer, _redeemAmount);

        // Update the Reward Distribution Supply state and distribute reward to suppplier
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _redeemer,
            false
        );
    }

    /**
     * @notice Hook function after iToken `redeem()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being redeemed
     * @param _redeemer The account which redeemed iToken
     * @param _redeemAmount  The amount of iToken being redeemed
     * @param _redeemedUnderlying The amount of underlying being redeemed
     */
    function afterRedeem(
        address _iToken,
        address _redeemer,
        uint256 _redeemAmount,
        uint256 _redeemedUnderlying
    ) external override {
        _iToken;
        _redeemer;
        _redeemAmount;
        _redeemedUnderlying;
    }

    /**
     * @notice Hook function before iToken `borrow()`
     * Checks if the account should be allowed to borrow the given iToken
     * Will `revert()` if any check fails
     * @param _iToken The iToken to check the borrow against
     * @param _borrower The account which would borrow iToken
     * @param _borrowAmount The amount of underlying to borrow
     */
    function beforeBorrow(
        address _iToken,
        address _borrower,
        uint256 _borrowAmount
    ) external override {
        _checkiTokenListed(_iToken);

        Market storage _market = markets[_iToken];
        require(!_market.borrowPaused, "Token borrow has been paused");

        if (!hasBorrowed(_borrower, _iToken)) {
            // Unlike collaterals, borrowed asset can only be added by iToken,
            // rather than enabled by user directly.
            require(msg.sender == _iToken, "sender must be iToken");

            // Have checked _iToken is listed, just add it
            _addToBorrowed(_borrower, _iToken);
        }

        // Check borrower's equity
        (, uint256 _shortfall, , ) =
            calcAccountEquityWithEffect(_borrower, _iToken, 0, _borrowAmount);

        require(_shortfall == 0, "Account has some shortfall");

        // Check the iToken's borrow capacity, -1 means no limit
        uint256 _totalBorrows = IiToken(_iToken).totalBorrows();
        require(
            _totalBorrows.add(_borrowAmount) <= _market.borrowCapacity,
            "Token borrow capacity reached"
        );

        // Update the Reward Distribution Borrow state and distribute reward to borrower
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            true
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _borrower,
            true
        );
    }

    /**
     * @notice Hook function after iToken `borrow()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being borrewd
     * @param _borrower The account which borrowed iToken
     * @param _borrowedAmount  The amount of underlying being borrowed
     */
    function afterBorrow(
        address _iToken,
        address _borrower,
        uint256 _borrowedAmount
    ) external override {
        _iToken;
        _borrower;
        _borrowedAmount;
    }

    /**
     * @notice Hook function before iToken `repayBorrow()`
     * Checks if the account should be allowed to repay the given iToken
     * for the borrower. Will `revert()` if any check fails
     * @param _iToken The iToken to verify the repay against
     * @param _payer The account which would repay iToken
     * @param _borrower The account which has borrowed
     * @param _repayAmount The amount of underlying to repay
     */
    function beforeRepayBorrow(
        address _iToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        _checkiTokenListed(_iToken);

        // Update the Reward Distribution Borrow state and distribute reward to borrower
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            true
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _borrower,
            true
        );

        _payer;
        _repayAmount;
    }

    /**
     * @notice Hook function after iToken `repayBorrow()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken being repaid
     * @param _payer The account which would repay
     * @param _borrower The account which has borrowed
     * @param _repayAmount  The amount of underlying being repaied
     */
    function afterRepayBorrow(
        address _iToken,
        address _payer,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        _checkiTokenListed(_iToken);

        // Remove _iToken from borrowed list if new borrow balance is 0
        if (IiToken(_iToken).borrowBalanceStored(_borrower) == 0) {
            // Only allow called by iToken as we are going to remove this token from borrower's borrowed list
            require(msg.sender == _iToken, "sender must be iToken");

            // Have checked _iToken is listed, just remove it
            _removeFromBorrowed(_borrower, _iToken);
        }

        _payer;
        _repayAmount;
    }

    /**
     * @notice Hook function before iToken `liquidateBorrow()`
     * Checks if the account should be allowed to liquidate the given iToken
     * for the borrower. Will `revert()` if any check fails
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be liqudate with
     * @param _liquidator The account which would repay the borrowed iToken
     * @param _borrower The account which has borrowed
     * @param _repayAmount The amount of underlying to repay
     */
    function beforeLiquidateBorrow(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repayAmount
    ) external override {
        // Tokens must have been listed
        require(
            iTokens.contains(_iTokenBorrowed) &&
                iTokens.contains(_iTokenCollateral),
            "Tokens have not been listed"
        );

        (, uint256 _shortfall, , ) = calcAccountEquity(_borrower);

        require(_shortfall > 0, "Account does not have shortfall");

        // Only allowed to repay the borrow balance's close factor
        uint256 _borrowBalance =
            IiToken(_iTokenBorrowed).borrowBalanceStored(_borrower);
        uint256 _maxRepay = _borrowBalance.rmul(closeFactorMantissa);

        require(_repayAmount <= _maxRepay, "Repay exceeds max repay allowed");

        _liquidator;
    }

    /**
     * @notice Hook function after iToken `liquidateBorrow()`
     * Will `revert()` if any operation fails
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _liquidator The account which would repay and seize
     * @param _borrower The account which has borrowed
     * @param _repaidAmount  The amount of underlying being repaied
     * @param _seizedAmount  The amount of collateral being seized
     */
    function afterLiquidateBorrow(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        address _liquidator,
        address _borrower,
        uint256 _repaidAmount,
        uint256 _seizedAmount
    ) external override {
        _iTokenBorrowed;
        _iTokenCollateral;
        _liquidator;
        _borrower;
        _repaidAmount;
        _seizedAmount;

        // Unlike repayBorrow, liquidateBorrow does not allow to repay all borrow balance
        // No need to check whether should remove from borrowed asset list
    }

    /**
     * @notice Hook function before iToken `seize()`
     * Checks if the liquidator should be allowed to seize the collateral iToken
     * Will `revert()` if any check fails
     * @param _iTokenCollateral The collateral iToken to be seize
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _liquidator The account which has repaid the borrowed iToken
     * @param _borrower The account which has borrowed
     * @param _seizeAmount The amount of collateral iToken to seize
     */
    function beforeSeize(
        address _iTokenCollateral,
        address _iTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint256 _seizeAmount
    ) external override {
        require(!seizePaused, "Seize has been paused");

        // Markets must have been listed
        require(
            iTokens.contains(_iTokenBorrowed) &&
                iTokens.contains(_iTokenCollateral),
            "Tokens have not been listed"
        );

        // Sanity Check the controllers
        require(
            IiToken(_iTokenBorrowed).controller() ==
                IiToken(_iTokenCollateral).controller(),
            "Controller mismatch between Borrowed and Collateral"
        );

        // Update the Reward Distribution Supply state on collateral
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iTokenCollateral,
            false
        );

        // Update reward of liquidator and borrower on collateral
        IRewardDistributor(rewardDistributor).updateReward(
            _iTokenCollateral,
            _liquidator,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(
            _iTokenCollateral,
            _borrower,
            false
        );

        _seizeAmount;
    }

    /**
     * @notice Hook function after iToken `seize()`
     * Will `revert()` if any operation fails
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _liquidator The account which has repaid and seized
     * @param _borrower The account which has borrowed
     * @param _seizedAmount  The amount of collateral being seized
     */
    function afterSeize(
        address _iTokenCollateral,
        address _iTokenBorrowed,
        address _liquidator,
        address _borrower,
        uint256 _seizedAmount
    ) external override {
        _iTokenBorrowed;
        _iTokenCollateral;
        _liquidator;
        _borrower;
        _seizedAmount;
    }

    /**
     * @notice Hook function before iToken `transfer()`
     * Checks if the transfer should be allowed
     * Will `revert()` if any check fails
     * @param _iToken The iToken to be transfered
     * @param _from The account to be transfered from
     * @param _to The account to be transfered to
     * @param _amount The amount to be transfered
     */
    function beforeTransfer(
        address _iToken,
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        // _redeemAllowed below will check whether _iToken is listed

        require(!transferPaused, "Transfer has been paused");

        // Check account equity with this amount to decide whether the transfer is allowed
        _redeemAllowed(_iToken, _from, _amount);

        // Update the Reward Distribution supply state
        IRewardDistributor(rewardDistributor).updateDistributionState(
            _iToken,
            false
        );

        // Update reward of from and to
        IRewardDistributor(rewardDistributor).updateReward(
            _iToken,
            _from,
            false
        );
        IRewardDistributor(rewardDistributor).updateReward(_iToken, _to, false);
    }

    /**
     * @notice Hook function after iToken `transfer()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken was transfered
     * @param _from The account was transfer from
     * @param _to The account was transfer to
     * @param _amount  The amount was transfered
     */
    function afterTransfer(
        address _iToken,
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        _iToken;
        _from;
        _to;
        _amount;
    }

    /**
     * @notice Hook function before iToken `flashloan()`
     * Checks if the flashloan should be allowed
     * Will `revert()` if any check fails
     * @param _iToken The iToken to be flashloaned
     * @param _to The account flashloaned transfer to
     * @param _amount The amount to be flashloaned
     */
    function beforeFlashloan(
        address _iToken,
        address _to,
        uint256 _amount
    ) external override {
        // Flashloan share the same pause state with borrow
        require(!markets[_iToken].borrowPaused, "Token borrow has been paused");

        _checkiTokenListed(_iToken);

        _to;
        _amount;
    }

    /**
     * @notice Hook function after iToken `flashloan()`
     * Will `revert()` if any operation fails
     * @param _iToken The iToken was flashloaned
     * @param _to The account flashloan transfer to
     * @param _amount  The amount was flashloaned
     */
    function afterFlashloan(
        address _iToken,
        address _to,
        uint256 _amount
    ) external override {
        _iToken;
        _to;
        _amount;
    }

    /*********************************/
    /***** Internal  Functions *******/
    /*********************************/

    function _redeemAllowed(
        address _iToken,
        address _redeemer,
        uint256 _amount
    ) private view {
        _checkiTokenListed(_iToken);

        // No need to check liquidity if _redeemer has not used _iToken as collateral
        if (!accountsData[_redeemer].collaterals.contains(_iToken)) {
            return;
        }

        (, uint256 _shortfall, , ) =
            calcAccountEquityWithEffect(_redeemer, _iToken, _amount, 0);

        require(_shortfall == 0, "Account has some shortfall");
    }

    /**
     * @dev Check if _iToken is listed
     */
    function _checkiTokenListed(address _iToken) private view {
        require(iTokens.contains(_iToken), "Token has not been listed");
    }

    /*********************************/
    /** Account equity calculation ***/
    /*********************************/

    /**
     * @notice Calculates current account equity
     * @param _account The account to query equity of
     * @return account equity, shortfall, collateral value, borrowed value.
     */
    function calcAccountEquity(address _account)
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return calcAccountEquityWithEffect(_account, address(0), 0, 0);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `iTokenBalance` is the number of iTokens the account owns in the collateral,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountEuityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowed;
        uint256 iTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 underlyingPrice;
        uint256 collateralValue;
        uint256 borrowValue;
    }

    /**
     * @notice Calculates current account equity plus some token and amount to effect
     * @param _account The account to query equity of
     * @param _tokenToEffect The token address to add some additional redeeem/borrow
     * @param _redeemAmount The additional amount to redeem
     * @param _borrowAmount The additional amount to borrow
     * @return account euqity, shortfall, collateral value, borrowed value plus the effect.
     */
    function calcAccountEquityWithEffect(
        address _account,
        address _tokenToEffect,
        uint256 _redeemAmount,
        uint256 _borrowAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountEuityLocalVars memory _local;
        AccountData storage _accountData = accountsData[_account];

        // Calculate value of all collaterals
        // collateralValuePerToken = underlyingPrice * exchangeRate * collateralFactor
        // collateralValue = balance * collateralValuePerToken
        // sumCollateral += collateralValue
        uint256 _len = _accountData.collaterals.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.collaterals.at(i));

            _local.iTokenBalance = IERC20Upgradeable(address(_token)).balanceOf(
                _account
            );
            _local.exchangeRateMantissa = _token.exchangeRateStored();

            if (_tokenToEffect == address(_token) && _redeemAmount > 0) {
                _local.iTokenBalance = _local.iTokenBalance.sub(_redeemAmount);
            }

            _local.underlyingPrice = IPriceOracle(priceOracle)
                .getUnderlyingPrice(address(_token));

            require(
                _local.underlyingPrice != 0,
                "Invalid price to calculate account equity"
            );

            _local.collateralValue = _local
                .iTokenBalance
                .mul(_local.underlyingPrice)
                .rmul(_local.exchangeRateMantissa)
                .rmul(markets[address(_token)].collateralFactorMantissa);

            _local.sumCollateral = _local.sumCollateral.add(
                _local.collateralValue
            );
        }

        // Calculate all borrowed value
        // borrowValue = underlyingPrice * underlyingBorrowed / borrowFactor
        // sumBorrowed += borrowValue
        _len = _accountData.borrowed.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.borrowed.at(i));

            _local.borrowBalance = _token.borrowBalanceStored(_account);

            if (_tokenToEffect == address(_token) && _borrowAmount > 0) {
                _local.borrowBalance = _local.borrowBalance.add(_borrowAmount);
            }

            _local.underlyingPrice = IPriceOracle(priceOracle)
                .getUnderlyingPrice(address(_token));

            require(
                _local.underlyingPrice != 0,
                "Invalid price to calculate account equity"
            );

            // borrowFactorMantissa can not be set to 0
            _local.borrowValue = _local
                .borrowBalance
                .mul(_local.underlyingPrice)
                .rdiv(markets[address(_token)].borrowFactorMantissa);

            _local.sumBorrowed = _local.sumBorrowed.add(_local.borrowValue);
        }

        // Should never underflow
        return
            _local.sumCollateral > _local.sumBorrowed
                ? (
                    _local.sumCollateral - _local.sumBorrowed,
                    uint256(0),
                    _local.sumCollateral,
                    _local.sumBorrowed
                )
                : (
                    uint256(0),
                    _local.sumBorrowed - _local.sumCollateral,
                    _local.sumCollateral,
                    _local.sumBorrowed
                );
    }

    /**
     * @notice Calculate amount of collateral iToken to seize after repaying an underlying amount
     * @dev Used in liquidation
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _actualRepayAmount The amount of underlying token liquidator has repaied
     * @return _seizedTokenCollateral amount of iTokenCollateral tokens to be seized
     */
    function liquidateCalculateSeizeTokens(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        uint256 _actualRepayAmount
    ) external view override returns (uint256 _seizedTokenCollateral) {
        /* Read oracle prices for borrowed and collateral assets */
        uint256 _priceBorrowed =
            IPriceOracle(priceOracle).getUnderlyingPrice(_iTokenBorrowed);
        uint256 _priceCollateral =
            IPriceOracle(priceOracle).getUnderlyingPrice(_iTokenCollateral);
        require(
            _priceBorrowed != 0 && _priceCollateral != 0,
            "Borrowed or Collateral asset price is invalid"
        );

        uint256 _valueRepayPlusIncentive =
            _actualRepayAmount.mul(_priceBorrowed).rmul(
                liquidationIncentiveMantissa
            );

        // Use stored value here as it is view function
        uint256 _exchangeRateMantissa =
            IiToken(_iTokenCollateral).exchangeRateStored();

        // seizedTokenCollateral = valueRepayPlusIncentive / valuePerTokenCollateral
        // valuePerTokenCollateral = exchangeRateMantissa * priceCollateral
        _seizedTokenCollateral = _valueRepayPlusIncentive
            .rdiv(_exchangeRateMantissa)
            .div(_priceCollateral);
    }

    /*********************************/
    /*** Account Markets Operation ***/
    /*********************************/

    /**
     * @notice Returns the markets list the account has entered
     * @param _account The address of the account to query
     * @return _accountCollaterals The markets list the account has entered
     */
    function getEnteredMarkets(address _account)
        external
        view
        override
        returns (address[] memory _accountCollaterals)
    {
        AccountData storage _accountData = accountsData[_account];

        uint256 _len = _accountData.collaterals.length();
        _accountCollaterals = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _accountCollaterals[i] = _accountData.collaterals.at(i);
        }
    }

    /**
     * @notice Add markets to `msg.sender`'s markets list for liquidity calculations
     * @param _iTokens The list of addresses of the iToken markets to be entered
     * @return _results Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata _iTokens)
        external
        override
        returns (bool[] memory _results)
    {
        uint256 _len = _iTokens.length;

        _results = new bool[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _results[i] = _enterMarket(_iTokens[i], msg.sender);
        }
    }

    /**
     * @notice Add the market to the account's markets list for liquidity calculations
     * @param _iToken The market to enter
     * @param _account The address of the account to modify
     * @return True if entered successfully, false for non-listed market or other errors
     */
    function _enterMarket(address _iToken, address _account)
        internal
        returns (bool)
    {
        // Market not listed, skip it
        if (!iTokens.contains(_iToken)) {
            return false;
        }

        // add() will return false if iToken is in account's market list
        if (accountsData[_account].collaterals.add(_iToken)) {
            emit MarketEntered(_iToken, _account);
        }

        return true;
    }

    /**
     * @notice Returns whether the given account has entered the market
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has entered the market, otherwise false.
     */
    function hasEnteredMarket(address _account, address _iToken)
        external
        view
        override
        returns (bool)
    {
        return accountsData[_account].collaterals.contains(_iToken);
    }

    /**
     * @notice Remove markets from `msg.sender`'s collaterals for liquidity calculations
     * @param _iTokens The list of addresses of the iToken to exit
     * @return _results Success indicators for whether each corresponding market was exited
     */
    function exitMarkets(address[] calldata _iTokens)
        external
        override
        returns (bool[] memory _results)
    {
        uint256 _len = _iTokens.length;
        _results = new bool[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _results[i] = _exitMarket(_iTokens[i], msg.sender);
        }
    }

    /**
     * @notice Remove the market to the account's markets list for liquidity calculations
     * @param _iToken The market to exit
     * @param _account The address of the account to modify
     * @return True if exit successfully, false for non-listed market or other errors
     */
    function _exitMarket(address _iToken, address _account)
        internal
        returns (bool)
    {
        // Market not listed, skip it
        if (!iTokens.contains(_iToken)) {
            return true;
        }

        // Account has not entered this market, skip it
        if (!accountsData[_account].collaterals.contains(_iToken)) {
            return true;
        }

        // Get the iToken balance
        uint256 _balance = IERC20Upgradeable(_iToken).balanceOf(_account);

        // Check account's equity if all balance are redeemed
        // which means iToken can be removed from collaterals
        _redeemAllowed(_iToken, _account, _balance);

        // Have checked account has entered market before
        accountsData[_account].collaterals.remove(_iToken);

        emit MarketExited(_iToken, _account);

        return true;
    }

    /**
     * @notice Returns the asset list the account has borrowed
     * @param _account The address of the account to query
     * @return _borrowedAssets The asset list the account has borrowed
     */
    function getBorrowedAssets(address _account)
        external
        view
        override
        returns (address[] memory _borrowedAssets)
    {
        AccountData storage _accountData = accountsData[_account];

        uint256 _len = _accountData.borrowed.length();
        _borrowedAssets = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _borrowedAssets[i] = _accountData.borrowed.at(i);
        }
    }

    /**
     * @notice Add the market to the account's borrowed list for equity calculations
     * @param _iToken The iToken of underlying to borrow
     * @param _account The address of the account to modify
     */
    function _addToBorrowed(address _account, address _iToken) internal {
        // add() will return false if iToken is in account's market list
        if (accountsData[_account].borrowed.add(_iToken)) {
            emit BorrowedAdded(_iToken, _account);
        }
    }

    /**
     * @notice Returns whether the given account has borrowed the given iToken
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has borrowed the iToken, otherwise false.
     */
    function hasBorrowed(address _account, address _iToken)
        public
        view
        override
        returns (bool)
    {
        return accountsData[_account].borrowed.contains(_iToken);
    }

    /**
     * @notice Remove the iToken from the account's borrowed list
     * @param _iToken The iToken to remove
     * @param _account The address of the account to modify
     */
    function _removeFromBorrowed(address _account, address _iToken) internal {
        // remove() will return false if iToken does not exist in account's borrowed list
        if (accountsData[_account].borrowed.remove(_iToken)) {
            emit BorrowedRemoved(_iToken, _account);
        }
    }

    /*********************************/
    /****** General Information ******/
    /*********************************/

    /**
     * @notice Return all of the iTokens
     * @return _alliTokens The list of iToken addresses
     */
    function getAlliTokens()
        public
        view
        override
        returns (address[] memory _alliTokens)
    {
        EnumerableSetUpgradeable.AddressSet storage _iTokens = iTokens;

        uint256 _len = _iTokens.length();
        _alliTokens = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _alliTokens[i] = _iTokens.at(i);
        }
    }

    /**
     * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
    function hasiToken(address _iToken) public view override returns (bool) {
        return iTokens.contains(_iToken);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title dForce Lending Protocol's InterestRateModel Interface.
 * @author dForce Team.
 */
interface IInterestRateModelInterface {
    function isInterestRateModel() external view returns (bool);

    /**
     * @dev Calculates the current borrow interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amnount of reserves the market has.
     * @return The borrow rate per block (as a percentage, and scaled by 1e18).
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @dev Calculates the current supply interest rate per block.
     * @param cash The total amount of cash the market has.
     * @param borrows The total amount of borrows the market has.
     * @param reserves The total amnount of reserves the market has.
     * @param reserveRatio The current reserve factor the market has.
     * @return The supply rate per block (as a percentage, and scaled by 1e18).
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveRatio
    ) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IControllerAdminInterface {
    /// @notice Emitted when an admin supports a market
    event MarketAdded(
        address iToken,
        uint256 collateralFactor,
        uint256 borrowFactor,
        uint256 supplyCapacity,
        uint256 borrowCapacity,
        uint256 distributionFactor
    );

    function _addMarket(
        address _iToken,
        uint256 _collateralFactor,
        uint256 _borrowFactor,
        uint256 _supplyCapacity,
        uint256 _borrowCapacity,
        uint256 _distributionFactor
    ) external;

    /// @notice Emitted when new price oracle is set
    event NewPriceOracle(address oldPriceOracle, address newPriceOracle);

    function _setPriceOracle(address newOracle) external;

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(
        uint256 oldCloseFactorMantissa,
        uint256 newCloseFactorMantissa
    );

    function _setCloseFactor(uint256 newCloseFactorMantissa) external;

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(
        uint256 oldLiquidationIncentiveMantissa,
        uint256 newLiquidationIncentiveMantissa
    );

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external;

    /// @notice Emitted when iToken's collateral factor is changed by admin
    event NewCollateralFactor(
        address iToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    function _setCollateralFactor(
        address iToken,
        uint256 newCollateralFactorMantissa
    ) external;

    /// @notice Emitted when iToken's borrow factor is changed by admin
    event NewBorrowFactor(
        address iToken,
        uint256 oldBorrowFactorMantissa,
        uint256 newBorrowFactorMantissa
    );

    function _setBorrowFactor(address iToken, uint256 newBorrowFactorMantissa)
        external;

    /// @notice Emitted when iToken's borrow capacity is changed by admin
    event NewBorrowCapacity(
        address iToken,
        uint256 oldBorrowCapacity,
        uint256 newBorrowCapacity
    );

    function _setBorrowCapacity(address iToken, uint256 newBorrowCapacity)
        external;

    /// @notice Emitted when iToken's supply capacity is changed by admin
    event NewSupplyCapacity(
        address iToken,
        uint256 oldSupplyCapacity,
        uint256 newSupplyCapacity
    );

    function _setSupplyCapacity(address iToken, uint256 newSupplyCapacity)
        external;

    /// @notice Emitted when pause guardian is changed by admin
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    function _setPauseGuardian(address newPauseGuardian) external;

    /// @notice Emitted when mint is paused/unpaused by admin or pause guardian
    event MintPaused(address iToken, bool paused);

    function _setMintPaused(address iToken, bool paused) external;

    function _setAllMintPaused(bool paused) external;

    /// @notice Emitted when redeem is paused/unpaused by admin or pause guardian
    event RedeemPaused(address iToken, bool paused);

    function _setRedeemPaused(address iToken, bool paused) external;

    function _setAllRedeemPaused(bool paused) external;

    /// @notice Emitted when borrow is paused/unpaused by admin or pause guardian
    event BorrowPaused(address iToken, bool paused);

    function _setBorrowPaused(address iToken, bool paused) external;

    function _setAllBorrowPaused(bool paused) external;

    /// @notice Emitted when transfer is paused/unpaused by admin or pause guardian
    event TransferPaused(bool paused);

    function _setTransferPaused(bool paused) external;

    /// @notice Emitted when seize is paused/unpaused by admin or pause guardian
    event SeizePaused(bool paused);

    function _setSeizePaused(bool paused) external;

    function _setiTokenPaused(address iToken, bool paused) external;

    function _setProtocolPaused(bool paused) external;

    event NewRewardDistributor(
        address oldRewardDistributor,
        address _newRewardDistributor
    );

    function _setRewardDistributor(address _newRewardDistributor) external;
}

interface IControllerPolicyInterface {
    function beforeMint(
        address iToken,
        address account,
        uint256 mintAmount
    ) external;

    function afterMint(
        address iToken,
        address minter,
        uint256 mintAmount,
        uint256 mintedAmount
    ) external;

    function beforeRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount
    ) external;

    function afterRedeem(
        address iToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemedAmount
    ) external;

    function beforeBorrow(
        address iToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function afterBorrow(
        address iToken,
        address borrower,
        uint256 borrowedAmount
    ) external;

    function beforeRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterRepayBorrow(
        address iToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external;

    function beforeLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external;

    function afterLiquidateBorrow(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repaidAmount,
        uint256 seizedAmount
    ) external;

    function beforeSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizeAmount
    ) external;

    function afterSeize(
        address iTokenBorrowed,
        address iTokenCollateral,
        address liquidator,
        address borrower,
        uint256 seizedAmount
    ) external;

    function beforeTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function afterTransfer(
        address iToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function beforeFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;

    function afterFlashloan(
        address iToken,
        address to,
        uint256 amount
    ) external;
}

interface IControllerAccountEquityInterface {
    function calcAccountEquity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function liquidateCalculateSeizeTokens(
        address iTokenBorrowed,
        address iTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256);
}

interface IControllerAccountInterface {
    function hasEnteredMarket(address account, address iToken)
        external
        view
        returns (bool);

    function getEnteredMarkets(address account)
        external
        view
        returns (address[] memory);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address iToken, address account);

    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    /// @notice Emitted when an account exits a market
    event MarketExited(address iToken, address account);

    function exitMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    /// @notice Emitted when an account add a borrow asset
    event BorrowedAdded(address iToken, address account);

    /// @notice Emitted when an account remove a borrow asset
    event BorrowedRemoved(address iToken, address account);

    function hasBorrowed(address account, address iToken)
        external
        view
        returns (bool);

    function getBorrowedAssets(address account)
        external
        view
        returns (address[] memory);
}

interface IControllerInterface is
    IControllerAdminInterface,
    IControllerPolicyInterface,
    IControllerAccountEquityInterface,
    IControllerAccountInterface
{
    /**
     * @notice Security checks when updating the comptroller of a market, always expect to return true.
     */
    function isController() external view returns (bool);

    /**
     * @notice Return all of the iTokens
     * @return The list of iToken addresses
     */
    function getAlliTokens() external view returns (address[] memory);

    /**
     * @notice Check whether a iToken is listed in controller
     * @param _iToken The iToken to check for
     * @return true if the iToken is listed otherwise false
     */
    function hasiToken(address _iToken) external view returns (bool);
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}