//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ZkSyncBridgeSwapper.sol";
import "./interfaces/IStaticATokenLM.sol";

/**
* @notice Exchanges tokens for their respective static Aave tokens.
* NOTE: to add a new pool, put the underlying token at the even index,
* immediately followed by the static aToken at the odd index.
* Example indexes:
* 0: DAI
* 1: stataDAI
* 2: USDC
* 3: stataUSDC
*/
contract AaveBridgeSwapper is ZkSyncBridgeSwapper {

    address[] public tokens;

    event PoolAdded(address stataToken);

    constructor(
        address _zkSync,
        address _l2Account,
        address[] memory _stataTokens
    )
        ZkSyncBridgeSwapper(_zkSync, _l2Account)
    {
        for (uint i = 0; i < _stataTokens.length; i++) {
            addPool(_stataTokens[i]);
        }
    }

    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external override returns (uint256 amountOut) {
        require(_indexIn < tokens.length, "invalid input index");
        require(_indexOut < tokens.length && _indexOut != _indexIn, "invalid output index");

        address inputToken = tokens[_indexIn];
        address outputToken = tokens[_indexOut];

        transferFromZkSync(inputToken);

        if (_indexIn % 2 == 0) { // deposit
            require(outputToken == tokens[_indexIn + 1], "invalid output token");

            IERC20(inputToken).approve(outputToken, _amountIn);
            amountOut = IStaticATokenLM(outputToken).deposit(
                address(this),
                _amountIn,
                0,
                true
            );
        } else { // withdrawal
            require(outputToken == tokens[_indexIn - 1], "invalid output token");

            (, amountOut) = IStaticATokenLM(inputToken).withdraw(
                address(this),
                _amountIn,
                true
            );
        }

        transferToZkSync(outputToken, amountOut);
        emit Swapped(inputToken, _amountIn, outputToken, amountOut);
    }

    function addPool(address _stataToken) public onlyOwner {
        require(_stataToken != address(0), "null stataToken");
        address token = address(IStaticATokenLM(_stataToken).ASSET());
        require(token != address(0), "null token");

        tokens.push(token);
        tokens.push(_stataToken);
        assert(tokens.length % 2 == 0);

        emit PoolAdded(_stataToken);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./interfaces/IZkSync.sol";
import "./interfaces/IBridgeSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ZkSyncBridgeSwapper is IBridgeSwapper {

    // The owner of the contract
    address public owner;
    // The max slippage accepted for swapping. Defaults to 1% with 6 decimals.
    uint256 public slippagePercent = 1e6;

    // The ZkSync bridge contract
    address public immutable zkSync;
    // The L2 market maker account
    address public immutable l2Account;

    address constant internal ETH_TOKEN = address(0);

    event OwnerChanged(address _owner, address _newOwner);
    event SlippageChanged(uint256 _slippagePercent);

    modifier onlyOwner {
        require(msg.sender == owner, "unauthorised");
        _;
    }

    constructor(address _zkSync, address _l2Account) {
        zkSync = _zkSync;
        l2Account = _l2Account;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "invalid input");
        owner = _newOwner;
        emit OwnerChanged(owner, _newOwner);
    }

    function changeSlippage(uint256 _slippagePercent) external onlyOwner {
        require(_slippagePercent != slippagePercent && _slippagePercent <= 100e6, "invalid slippage");
        slippagePercent = _slippagePercent;
        emit SlippageChanged(slippagePercent);
    }

    /**
    * @dev Check if there is a pending balance to withdraw in zkSync and withdraw it if applicable.
    * @param _token The token to withdraw.
    */
    function transferFromZkSync(address _token) internal {
        uint128 pendingBalance = IZkSync(zkSync).getPendingBalance(address(this), _token);
        if (pendingBalance > 0) {
            IZkSync(zkSync).withdrawPendingBalance(payable(address(this)), _token, pendingBalance);
        }
    }

    /**
    * @dev Deposit the ETH or ERC20 token to zkSync.
    * @param _outputToken The token that was given.
    * @param _amountOut The amount of given token.
    */
    function transferToZkSync(address _outputToken, uint256 _amountOut) internal {
        if (_outputToken == ETH_TOKEN) {
            // deposit Eth to L2 bridge
            IZkSync(zkSync).depositETH{value: _amountOut}(l2Account);
        } else {
            // approve the zkSync bridge to take the output token
            IERC20(_outputToken).approve(zkSync, _amountOut);
            // deposit the output token to the L2 bridge
            IZkSync(zkSync).depositERC20(IERC20(_outputToken), toUint104(_amountOut), l2Account);
        }
    }

    /**
    * @dev Safety method to recover ETH or ERC20 tokens that are sent to the contract by error.
    * @param _token The token to recover.
    */
    function recoverToken(address _recipient, address _token) external onlyOwner returns (uint256 balance) {
        bool success;
        if (_token == ETH_TOKEN) {
            balance = address(this).balance;
            (success, ) = _recipient.call{value: balance}("");
        } else {
            balance = IERC20(_token).balanceOf(address(this));
            success = IERC20(_token).transfer(_recipient, balance);
        }
        require(success, "failed to recover");
    }

    /**
     * @dev fallback method to make sure we can receive ETH
     */
    receive() external payable {
        
    }

    /**
     * @dev Returns the minimum accepted out amount.
     */
    function getMinAmountOut(uint256 _amountIn) internal view returns (uint256) {
        return _amountIn * (100e6 - slippagePercent) / 100e6;
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaticATokenLM is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);

  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice Deposits `ASSET` in the Aave protocol and mints static aTokens to msg.sender
   * @param recipient The address that will receive the static aTokens
   * @param amount The amount of underlying `ASSET` to deposit (e.g. deposit of 100 USDC)
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @return uint256 The amount of StaticAToken minted, static balance
   **/
  function deposit(
    address recipient,
    uint256 amount,
    uint16 referralCode,
    bool fromUnderlying
  ) external returns (uint256);

  /**
   * @notice Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
   * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param amount The amount to withdraw, in static balance of StaticAToken
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   **/
  function withdraw(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  /**
   * @notice Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
   * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param amount The amount to withdraw, in dynamic balance of aToken/underlying asset
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   **/
  function withdrawDynamicAmount(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  /**
   * @notice Implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Allows to deposit on Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param depositor Address from which the funds to deposit are going to be pulled
   * @param recipient Address that will receive the staticATokens, in the average case, same as the `depositor`
   * @param value The amount to deposit
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return uint256 The amount of StaticAToken minted, static balance
   */
  function metaDeposit(
    address depositor,
    address recipient,
    uint256 value,
    uint16 referralCode,
    bool fromUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256);

  /**
   * @notice Allows to withdraw from Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner Address owning the staticATokens
   * @param recipient Address that will receive the underlying withdrawn from Aave
   * @param staticAmount The amount of staticAToken to withdraw. If > 0, `dynamicAmount` needs to be 0
   * @param dynamicAmount The amount of underlying/aToken to withdraw. If > 0, `staticAmount` needs to be 0
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   */
  function metaWithdraw(
    address owner,
    address recipient,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams
  ) external returns (uint256, uint256);

  /**
   * @notice Utility method to get the current aToken balance of an user, from his staticAToken balance
   * @param account The address of the user
   * @return uint256 The aToken balance
   **/
  function dynamicBalanceOf(address account) external view returns (uint256);

  /**
   * @notice Converts a static amount (scaled balance on aToken) to the aToken/underlying value,
   * using the current liquidity index on Aave
   * @param amount The amount to convert from
   * @return uint256 The dynamic amount
   **/
  function staticToDynamicAmount(uint256 amount) external view returns (uint256);

  /**
   * @notice Converts an aToken or underlying amount to the what it is denominated on the aToken as
   * scaled balance, function of the principal and the liquidity index
   * @param amount The amount to convert from
   * @return uint256 The static (scaled) amount
   **/
  function dynamicToStaticAmount(uint256 amount) external view returns (uint256);

  /**
   * @notice Returns the Aave liquidity index of the underlying aToken, denominated rate here
   * as it can be considered as an ever-increasing exchange rate
   * @return The liquidity index
   **/
  function rate() external view returns (uint256);

  /**
   * @notice Function to return a dynamic domain separator, in order to be compatible with forks changing chainId
   * @return bytes32 The domain separator
   **/
  function getDomainSeparator() external view returns (bytes32);

  /**
   * @notice Claims rewards from `INCENTIVES_CONTROLLER` and updates internal accounting of rewards.
   */
  function collectAndUpdateRewards() external;

  /**
   * @notice Claim rewards on behalf of a user and send them to a receiver
   * @dev Only callable by if sender is onBehalfOf or sender is approved claimer
   * @param onBehalfOf The address to claim on behalf of
   * @param receiver The address to receive the rewards
   * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
   */
  function claimRewardsOnBehalf(
    address onBehalfOf,
    address receiver,
    bool forceUpdate
  ) external;

  /**
   * @notice Claim rewards and send them to a receiver
   * @param receiver The address to receive the rewards
   * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
   */
  function claimRewards(address receiver, bool forceUpdate) external;

  /**
   * @notice Claim rewards
   * @param forceUpdate Flag to retrieve latest rewards from `INCENTIVES_CONTROLLER`
   */
  function claimRewardsToSelf(bool forceUpdate) external;

  /**
   * @notice Get the total claimable rewards of the contract.
   * @return The current balance + pending rewards from the `_incentivesController`
   */
  function getTotalClaimableRewards() external view returns (uint256);

  /**
   * @notice Get the total claimable rewards for a user in WAD
   * @param user The address of the user
   * @return The claimable amount of rewards in WAD
   */
  function getClaimableRewards(address user) external view returns (uint256);

  /**
   * @notice The unclaimed rewards for a user in WAD
   * @param user The address of the user
   * @return The unclaimed amount of rewards in WAD
   */
  function getUnclaimedRewards(address user) external view returns (uint256);

  function getAccRewardsPerToken() external view returns (uint256);

  function getLifetimeRewardsClaimed() external view returns (uint256);

  function getLifetimeRewards() external view returns (uint256);

  function getLastRewardBlock() external view returns (uint256);

  // function LENDING_POOL() external view returns (ILendingPool);

  // function INCENTIVES_CONTROLLER() external view returns (IAaveIncentivesController);

  function ATOKEN() external view returns (IERC20);

  function ASSET() external view returns (IERC20);

  function REWARD_TOKEN() external view returns (IERC20);

  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  // function getIncentivesController() external view returns (IAaveIncentivesController);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IZkSync {
    function getPendingBalance(address _address, address _token) external view returns (uint128);
    function withdrawPendingBalance(address payable _owner, address _token, uint128 _amount) external;
    function depositETH(address _zkSyncAddress) external payable;
    function depositERC20(IERC20 _token, uint104 _amount, address _zkSyncAddress) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IBridgeSwapper {
    event Swapped(address _inputToken, uint256 _amountIn, address _outputToken, uint256 _amountOut);

    /**
    * @notice Perform an exchange between two tokens
    * @dev Index values can usually be found via the constructor arguments (if not hardcoded)
    * @param _indexIn Index value for the token to send
    * @param _indexOut Index valie of the token to receive
    * @param _amountIn Amount of `_indexIn` being exchanged
    * @return Actual amount of `_indexOut` received
    */
    function exchange(uint256 _indexIn, uint256 _indexOut, uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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