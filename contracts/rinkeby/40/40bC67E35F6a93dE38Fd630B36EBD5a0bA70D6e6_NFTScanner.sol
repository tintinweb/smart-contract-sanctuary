// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./farm/interfaces/IMasterBarista.sol";
import "./farm/interfaces/IMasterBaristaCallback.sol";
import "./interfaces/IBoosterConfig.sol";
import "./periphery/interfaces/IWNativeRelayer.sol";
import "./periphery/interfaces/IWETH.sol";
import "./periphery/library/SafeToken.sol";

contract Booster is
  Ownable,
  Pausable,
  ReentrancyGuard,
  AccessControl,
  IMasterBaristaCallback,
  IERC721Receiver
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  IMasterBarista public masterBarista;
  IBoosterConfig public boosterConfig;
  IERC20 public latte;
  IWNativeRelayer public wNativeRelayer;
  address public wNative;

  struct UserInfo {
    uint256 accumBoostedReward;
    uint256 lastUserActionTime;
  }

  struct NFTStakingInfo {
    address nftAddress;
    uint256 nftTokenId;
  }

  mapping(address => mapping(address => UserInfo)) public userInfo;

  mapping(address => uint256) public totalAccumBoostedReward;
  mapping(address => mapping(address => NFTStakingInfo)) public userStakingNFT;

  uint256 public _IN_EXEC_LOCK;

  event StakeNFT(address indexed staker, address indexed stakeToken, address nftAddress, uint256 nftTokenId);
  event UnstakeNFT(address indexed staker, address indexed stakeToken, address nftAddress, uint256 nftTokenId);
  event Stake(address indexed staker, IERC20 indexed stakeToken, uint256 amount);
  event Unstake(address indexed unstaker, IERC20 indexed stakeToken, uint256 amount);
  event Harvest(address indexed harvester, IERC20 indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed caller, IERC20 indexed stakeToken, uint256 amount);
  event MasterBaristaCall(
    address indexed user,
    uint256 extraReward,
    address stakeToken,
    uint256 prevEnergy,
    uint256 currentEnergy
  );
  event Pause();
  event Unpause();

  constructor(
    IERC20 _latte,
    IMasterBarista _masterBarista,
    IBoosterConfig _boosterConfig,
    IWNativeRelayer _wNativeRelayer,
    address _wNative
  ) public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    masterBarista = _masterBarista;
    boosterConfig = _boosterConfig;
    latte = _latte;
    wNativeRelayer = _wNativeRelayer;
    wNative = _wNative;

    _IN_EXEC_LOCK = _NOT_ENTERED;
  }

  /// @dev Ensure that the function is called with the execution scope
  modifier inExec() {
    require(_IN_EXEC_LOCK == _NOT_ENTERED, "Booster::inExec:: in exec lock");
    require(address(masterBarista) == _msgSender(), "Booster::inExec:: not from the master barista");
    _IN_EXEC_LOCK = _ENTERED;
    _;
    _IN_EXEC_LOCK = _NOT_ENTERED;
  }

  /// @dev validate whether a specified stake token is allowed
  modifier isStakeTokenOK(address _stakeToken) {
    require(boosterConfig.stakeTokenAllowance(_stakeToken), "Booster::isStakeTokenOK::bad stake token");
    _;
  }

  /// @dev validate whether a specified nft can be staked into a particular staoke token
  modifier isBoosterNftOK(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  ) {
    require(
      boosterConfig.boosterNftAllowance(_stakeToken, _nftAddress, _nftTokenId),
      "Booster::isBoosterNftOK::bad nft"
    );
    _;
  }

  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "Booster::permit::INVALID_SIGNATURE");
    _;
  }

  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Booster::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Booster::onlyEOA:: not eoa");
    _;
  }

  /**
   * @notice Triggers stopped state
   * @dev Only possible when contract not paused.
   */
  function pause() external onlyGovernance whenNotPaused {
    _pause();
    emit Pause();
  }

  /**
   * @notice Returns to normal state
   * @dev Only possible when contract is paused.
   */
  function unpause() external onlyGovernance whenPaused {
    _unpause();
    emit Unpause();
  }

  /// @dev Internal function for withdrawing a boosted stake token and receive a reward from a master barista
  /// @param _stakeToken specified stake token
  /// @param _shares user's shares to be withdrawn
  function _withdrawFromMasterBarista(IERC20 _stakeToken, uint256 _shares) internal {
    if (_shares == 0) return;
    if (address(_stakeToken) == address(latte)) {
      masterBarista.withdrawLatte(_msgSender(), _shares);
    } else {
      masterBarista.withdraw(_msgSender(), address(_stakeToken), _shares);
    }
  }

  /// @dev Internal function for harvest a reward from a master barista
  /// @param _stakeToken specified stake token
  function _harvestFromMasterBarista(address user, IERC20 _stakeToken) internal {
    (uint256 userStakeAmount, , , ) = masterBarista.userInfo(address(_stakeToken), user);
    if (userStakeAmount == 0) {
      emit Harvest(user, _stakeToken, 0);
      return;
    }
    uint256 beforeReward = latte.balanceOf(user);
    masterBarista.harvest(user, address(_stakeToken));

    emit Harvest(user, _stakeToken, latte.balanceOf(user).sub(beforeReward));
  }

  /// @notice function for staking a new nft
  /// @dev This one is a preparation for nft staking info, if nft address and nft token id are the same with existing record, it will be reverted
  /// @param _stakeToken a specified stake token address
  /// @param _nftAddress composite key for nft
  /// @param _nftTokenId composite key for nft
  function stakeNFT(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  )
    external
    whenNotPaused
    isStakeTokenOK(_stakeToken)
    isBoosterNftOK(_stakeToken, _nftAddress, _nftTokenId)
    nonReentrant
    onlyEOA
  {
    _stakeNFT(_stakeToken, _nftAddress, _nftTokenId);
  }

  /// @dev avoid stack-too-deep by branching the function
  function _stakeNFT(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  ) internal {
    NFTStakingInfo memory toBeSentBackNft = userStakingNFT[_stakeToken][_msgSender()];
    require(
      toBeSentBackNft.nftAddress != _nftAddress || toBeSentBackNft.nftTokenId != _nftTokenId,
      "Booster::stakeNFT:: nft already staked"
    );
    _harvestFromMasterBarista(_msgSender(), IERC20(_stakeToken));

    userStakingNFT[_stakeToken][_msgSender()] = NFTStakingInfo({ nftAddress: _nftAddress, nftTokenId: _nftTokenId });

    IERC721(_nftAddress).safeTransferFrom(_msgSender(), address(this), _nftTokenId);

    if (toBeSentBackNft.nftAddress != address(0)) {
      IERC721(toBeSentBackNft.nftAddress).safeTransferFrom(address(this), _msgSender(), toBeSentBackNft.nftTokenId);
    }
    emit StakeNFT(_msgSender(), _stakeToken, _nftAddress, _nftTokenId);
  }

  /// @notice function for unstaking a current nft
  /// @dev This one is a preparation for nft staking info, if nft address and nft token id are the same with existing record, it will be reverted
  /// @param _stakeToken a specified stake token address
  function unstakeNFT(address _stakeToken) external whenNotPaused isStakeTokenOK(_stakeToken) nonReentrant onlyEOA {
    _unstakeNFT(_stakeToken);
  }

  /// @dev avoid stack-too-deep by branching the function
  function _unstakeNFT(address _stakeToken) internal {
    NFTStakingInfo memory toBeSentBackNft = userStakingNFT[_stakeToken][_msgSender()];
    require(toBeSentBackNft.nftAddress != address(0), "Booster::stakeNFT:: no nft staked");

    _harvestFromMasterBarista(_msgSender(), IERC20(_stakeToken));

    userStakingNFT[_stakeToken][_msgSender()] = NFTStakingInfo({ nftAddress: address(0), nftTokenId: 0 });

    IERC721(toBeSentBackNft.nftAddress).safeTransferFrom(address(this), _msgSender(), toBeSentBackNft.nftTokenId);

    emit UnstakeNFT(_msgSender(), _stakeToken, toBeSentBackNft.nftAddress, toBeSentBackNft.nftTokenId);
  }

  /// @notice for staking a stakeToken and receive some rewards
  /// @param _stakeToken a specified stake token to be staked
  /// @param _amount amount to stake
  function stake(IERC20 _stakeToken, uint256 _amount)
    external
    payable
    whenNotPaused
    isStakeTokenOK(address(_stakeToken))
    nonReentrant
  {
    require(_amount > 0, "Booster::stake::nothing to stake");

    UserInfo storage user = userInfo[address(_stakeToken)][_msgSender()];

    _harvestFromMasterBarista(_msgSender(), _stakeToken);
    user.lastUserActionTime = block.timestamp;
    _stakeToken.safeApprove(address(masterBarista), _amount);
    _safeWrap(_stakeToken, _amount);

    if (address(_stakeToken) == address(latte)) {
      masterBarista.depositLatte(_msgSender(), _amount);
    } else {
      masterBarista.deposit(_msgSender(), address(_stakeToken), _amount);
    }

    _stakeToken.safeApprove(address(masterBarista), 0);

    emit Stake(_msgSender(), _stakeToken, _amount);
  }

  /// @dev internal function for unstaking a stakeToken and receive some rewards
  /// @param _stakeToken a specified stake token to be unstaked
  /// @param _amount amount to stake
  function _unstake(IERC20 _stakeToken, uint256 _amount) internal {
    require(_amount > 0, "Booster::_unstake::use harvest instead");

    UserInfo storage user = userInfo[address(_stakeToken)][_msgSender()];

    _withdrawFromMasterBarista(_stakeToken, _amount);

    user.lastUserActionTime = block.timestamp;
    _safeUnwrap(_stakeToken, _msgSender(), _amount);

    emit Unstake(_msgSender(), _stakeToken, _amount);
  }

  /// @dev function for unstaking a stakeToken and receive some rewards
  /// @param _stakeToken a specified stake token to be unstaked
  /// @param _amount amount to stake
  function unstake(address _stakeToken, uint256 _amount)
    external
    whenNotPaused
    isStakeTokenOK(_stakeToken)
    nonReentrant
  {
    _unstake(IERC20(_stakeToken), _amount);
  }

  /// @notice function for unstaking all portion of stakeToken and receive some rewards
  /// @dev similar to unstake with user's shares
  /// @param _stakeToken a specified stake token to be unstaked
  function unstakeAll(address _stakeToken) external whenNotPaused isStakeTokenOK(_stakeToken) nonReentrant {
    (uint256 userStakeAmount, , , ) = masterBarista.userInfo(address(_stakeToken), _msgSender());
    _unstake(IERC20(_stakeToken), userStakeAmount);
  }

  /// @notice function for harvesting the reward
  /// @param _stakeToken a specified stake token to be harvested
  function harvest(address _stakeToken) external whenNotPaused isStakeTokenOK(_stakeToken) nonReentrant {
    _harvestFromMasterBarista(_msgSender(), IERC20(_stakeToken));
  }

  /// @notice function for harvesting rewards in specified staking tokens
  /// @param _stakeTokens specified stake tokens to be harvested
  function harvest(address[] calldata _stakeTokens) external whenNotPaused nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      require(boosterConfig.stakeTokenAllowance(_stakeTokens[i]), "Booster::harvest::bad stake token");
      _harvestFromMasterBarista(_msgSender(), IERC20(_stakeTokens[i]));
    }
  }

  /// @dev a notifier function for letting some observer call when some conditions met
  /// @dev currently, the caller will be a master barista calling before a latte lock
  function masterBaristaCall(
    address stakeToken,
    address userAddr,
    uint256 unboostedReward,
    uint256 lastRewardBlock
  ) external override inExec {
    NFTStakingInfo memory stakingNFT = userStakingNFT[stakeToken][userAddr];
    UserInfo storage user = userInfo[stakeToken][userAddr];
    if (stakingNFT.nftAddress == address(0)) {
      return;
    }
    (, uint256 currentEnergy, uint256 boostBps) = boosterConfig.energyInfo(
      stakingNFT.nftAddress,
      stakingNFT.nftTokenId
    );
    if (currentEnergy == 0) {
      return;
    }
    uint256 extraReward = Math.min(currentEnergy, unboostedReward.mul(boostBps).div(1e4));
    totalAccumBoostedReward[stakeToken] = totalAccumBoostedReward[stakeToken].add(extraReward);
    user.accumBoostedReward = user.accumBoostedReward.add(extraReward);
    uint256 newEnergy = currentEnergy.sub(extraReward);
    masterBarista.mintExtraReward(stakeToken, userAddr, extraReward, lastRewardBlock);
    boosterConfig.consumeEnergy(stakingNFT.nftAddress, stakingNFT.nftTokenId, extraReward);

    emit MasterBaristaCall(userAddr, extraReward, stakeToken, currentEnergy, newEnergy);
  }

  function _safeWrap(IERC20 _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "Booster::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "Booster::_safeWrap:: value != msg.value");
      IWETH(wNative).deposit{ value: msg.value }();
      return;
    }
    _quoteBep20.safeTransferFrom(_msgSender(), address(this), _amount);
  }

  function _safeUnwrap(
    IERC20 _quoteBep20,
    address _to,
    uint256 _amount
  ) internal {
    if (address(_quoteBep20) == wNative) {
      _quoteBep20.safeTransfer(address(wNativeRelayer), _amount);
      wNativeRelayer.withdraw(_amount);
      SafeToken.safeTransferETH(_to, _amount);
      return;
    }
    _quoteBep20.safeTransfer(_to, _amount);
  }

  /**
   * @notice Withdraws a stake token from MasterBarista back to the user considerless the rewards.
   * @dev EMERGENCY ONLY
   */
  function emergencyWithdraw(IERC20 _stakeToken) external isStakeTokenOK(address(_stakeToken)) {
    UserInfo storage user = userInfo[address(_stakeToken)][_msgSender()];
    (uint256 userStakeAmount, , , ) = masterBarista.userInfo(address(_stakeToken), _msgSender());

    user.lastUserActionTime = block.timestamp;
    masterBarista.emergencyWithdraw(_msgSender(), address(_stakeToken));

    emit EmergencyWithdraw(_msgSender(), _stakeToken, userStakeAmount);
  }

  /// @dev when doing a safeTransferFrom, the caller needs to implement this, for safety reason
  function onERC721Received(
    address, /*operator*/
    address, /*from*/
    uint256, /*tokenId*/
    bytes calldata /*data*/
  ) external override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  /// @dev Fallback function to accept ETH. Workers will send ETH back the pool.
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
library SafeMath {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IMasterBarista {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingLatte(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function devAddr() external view returns (address);

  function devFeeBps() external view returns (uint256);

  /// @dev configuration functions
  function addPool(address _stakeToken, uint256 _allocPoint) external;

  function setPool(address _stakeToken, uint256 _allocPoint) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositLatte(address _for, uint256 _amount) external;

  function withdrawLatte(address _for, uint256 _amount) external;

  function depositLatteV2(address _for, uint256 _amount) external;

  function withdrawLatteV2(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterBaristaCallback {
  function masterBaristaCall(
    address stakeToken,
    address userAddr,
    uint256 unboostedReward,
    uint256 lastRewardBlock
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IBoosterConfig {
  // getter

  function energyInfo(address nftAddress, uint256 nftTokenId)
    external
    view
    returns (
      uint256 maxEnergy,
      uint256 currentEnergy,
      uint256 boostBps
    );

  function boosterNftAllowance(
    address stakingToken,
    address nftAddress,
    uint256 nftTokenId
  ) external view returns (bool);

  function stakeTokenAllowance(address stakingToken) external view returns (bool);

  function callerAllowance(address caller) external view returns (bool);

  // external

  function consumeEnergy(
    address nftAddress,
    uint256 nftTokenId,
    uint256 energyToBeConsumed
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWNativeRelayer {
  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
library EnumerableSet {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./interfaces/ILatteNFT.sol";
import "./periphery/interfaces/IWNativeRelayer.sol";
import "./periphery/interfaces/IWETH.sol";
import "./periphery/library/SafeToken.sol";

contract LatteMarket is ERC721Holder, Ownable, Pausable, AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  struct BidEntry {
    address bidder;
    uint256 price;
  }

  struct LatteNFTMetadataParam {
    address nftAddress;
    uint256 nftCategoryId;
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
  }

  struct LatteNFTMetadata {
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
    bool isBidding;
    uint256 price;
    IERC20 quoteBep20;
  }

  mapping(address => bool) public isNFTSupported;
  address public feeAddr;
  uint256 public feePercentBps;
  IWNativeRelayer public wNativeRelayer;
  address public wNative;
  mapping(address => mapping(uint256 => address)) public tokenCategorySellers;
  mapping(address => mapping(uint256 => BidEntry)) public tokenBid;

  // latte original nft related
  mapping(address => mapping(uint256 => LatteNFTMetadata)) public latteNFTMetadata;

  event Trade(
    address indexed seller,
    address indexed buyer,
    address nftAddress,
    uint256 indexed nftCategoryId,
    uint256 price,
    uint256 fee,
    uint256 size
  );
  event Ask(
    address indexed seller,
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 price,
    IERC20 quoteToken
  );
  event SetLatteNFTMetadata(
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 cap,
    uint256 startBlock,
    uint256 endBlock
  );
  event CancelSellNFT(address indexed seller, address indexed nftAddress, uint256 indexed nftCategoryId);
  event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
  event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
  event Bid(address indexed bidder, address indexed nftAddress, uint256 indexed nftCategoryId, uint256 price);
  event CancelBidNFT(address indexed bidder, address indexed nftAddress, uint256 indexed nftCategoryId);
  event SetSupportNFT(address indexed nftAddress, bool isSupported);
  event Pause();
  event Unpause();

  constructor(
    address _feeAddr,
    uint256 _feePercentBps,
    IWNativeRelayer _wNativeRelayer,
    address _wNative
  ) public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    feeAddr = _feeAddr;
    feePercentBps = _feePercentBps;
    wNativeRelayer = _wNativeRelayer;
    wNative = _wNative;
    emit FeeAddressTransferred(address(0), feeAddr);
    emit SetFeePercent(_msgSender(), 0, feePercentBps);
  }

  /**
   * @notice check address
   */
  modifier validAddress(address _addr) {
    require(_addr != address(0));
    _;
  }

  /// @notice check whether this particular nft address is supported by the contract
  modifier onlySupportedNFT(address _nft) {
    require(isNFTSupported[_nft], "LatteMarket::onlySupportedNFT::unsupported nft");
    _;
  }

  /// @notice only GOVERNANCE ROLE (role that can setup NON sensitive parameters) can continue the execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "LatteMarket::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @notice if the block number is not within the start and end block number, reverted
  modifier withinBlockRange(address _nftAddress, uint256 _categoryId) {
    require(
      block.number >= latteNFTMetadata[_nftAddress][_categoryId].startBlock &&
        block.number <= latteNFTMetadata[_nftAddress][_categoryId].endBlock,
      "LatteMarket::withinBlockRange:: invalid block number"
    );
    _;
  }

  /// @notice only verified signature can continue a statement
  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "LatteMarket::permit::INVALID_SIGNATURE");
    _;
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "LatteMarket::onlyEOA:: not eoa");
    _;
  }

  modifier onlyBiddingNFT(address _nftAddress, uint256 _categoryId) {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].isBidding,
      "LatteMarket::onlyBiddingNFT::only bidding token can be used here"
    );
    _;
  }

  modifier onlyNonBiddingNFT(address _nftAddress, uint256 _categoryId) {
    require(
      !latteNFTMetadata[_nftAddress][_categoryId].isBidding,
      "LatteMarket::onlyNonBiddingNFT::only selling token can be used here"
    );
    _;
  }

  /// @dev set LATTE NFT metadata consisted of cap, startBlock, and endBlock
  function setLatteNFTMetadata(LatteNFTMetadataParam[] calldata _params) external onlyGovernance {
    for (uint256 i = 0; i < _params.length; i++) {
      require(isNFTSupported[_params[i].nftAddress], "LatteMarket::setLatteNFTMetadata::unsupported nft");
      _setLatteNFTMetadata(_params[i]);
    }
  }

  function _setLatteNFTMetadata(LatteNFTMetadataParam memory _param) internal {
    require(
      _param.startBlock > block.number && _param.endBlock > _param.startBlock,
      "LatteMarket::_setLatteNFTMetadata::invalid start or end block"
    );
    LatteNFTMetadata storage metadata = latteNFTMetadata[_param.nftAddress][_param.nftCategoryId];
    metadata.cap = _param.cap;
    metadata.startBlock = _param.startBlock;
    metadata.endBlock = _param.endBlock;

    emit SetLatteNFTMetadata(_param.nftAddress, _param.nftCategoryId, _param.cap, _param.startBlock, _param.endBlock);
  }

  /// @dev set supported NFT for the contract
  function setSupportNFT(address[] calldata _nft, bool _isSupported) external onlyGovernance {
    for (uint256 i = 0; i < _nft.length; i++) {
      isNFTSupported[_nft[i]] = _isSupported;
      emit SetSupportNFT(_nft[i], _isSupported);
    }
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  function buyNFT(address _nftAddress, uint256 _categoryId)
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    onlyEOA
  {
    _buyNFTTo(_nftAddress, _categoryId, _msgSender(), 1);
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _size - amount to buy
  function buyBatchNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _size
  ) external payable whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyEOA {
    LatteNFTMetadata memory metadata = latteNFTMetadata[_nftAddress][_categoryId];
    /// re-use a storage usage by using the same metadata to validate
    /// multiple modifiers can cause stack too deep exception
    require(
      block.number >= metadata.startBlock && block.number <= metadata.endBlock,
      "LatteMarket::buyBatchNFT:: invalid block number"
    );
    _buyNFTTo(_nftAddress, _categoryId, _msgSender(), _size);
  }

  /// @dev use to decrease a total cap by 1, will get reverted if no more to be decreased
  function _decreaseCap(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _size
  ) internal {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].cap >= _size,
      "LatteMarket::_decreaseCap::maximum mint cap reached"
    );
    latteNFTMetadata[_nftAddress][_categoryId].cap = latteNFTMetadata[_nftAddress][_categoryId].cap.sub(_size);
  }

  /// @notice buyNFT based on its category id
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _to whom this will be bought to
  function buyNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    address _to
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    onlyEOA
  {
    _buyNFTTo(_nftAddress, _categoryId, _to, 1);
  }

  /// @dev internal method for buyNFTTo to avoid stack-too-deep
  function _buyNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    address _to,
    uint256 _size
  ) internal {
    _decreaseCap(_nftAddress, _categoryId, _size);
    LatteNFTMetadata memory metadata = latteNFTMetadata[_nftAddress][_categoryId];
    uint256 totalPrice = metadata.price.mul(_size);
    uint256 feeAmount = totalPrice.mul(feePercentBps).div(1e4);
    _safeWrap(metadata.quoteBep20, totalPrice);
    if (feeAmount != 0) {
      metadata.quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    metadata.quoteBep20.safeTransfer(tokenCategorySellers[_nftAddress][_categoryId], totalPrice.sub(feeAmount));
    ILatteNFT(_nftAddress).mintBatch(_to, _categoryId, "", _size);
    emit Trade(
      tokenCategorySellers[_nftAddress][_categoryId],
      _to,
      _nftAddress,
      _categoryId,
      totalPrice,
      feeAmount,
      _size
    );
  }

  /// @dev set a current price of a nftaddress with the following categoryId
  function setCurrentPrice(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    IERC20 _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _setCurrentPrice(_nftAddress, _categoryId, _price, _quoteToken);
  }

  function _setCurrentPrice(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    IERC20 _quoteToken
  ) internal {
    require(address(_quoteToken) != address(0), "LatteMarket::_setCurrentPrice::invalid quote token");
    latteNFTMetadata[_nftAddress][_categoryId].price = _price;
    latteNFTMetadata[_nftAddress][_categoryId].quoteBep20 = _quoteToken;
    emit Ask(_msgSender(), _nftAddress, _categoryId, _price, _quoteToken);
  }

  /// @notice this needs to be called when the seller want to SELL the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - price of a token
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _readyToSellNFTTo(
      _nftAddress,
      _categoryId,
      _price,
      address(_msgSender()),
      _cap,
      _startBlock,
      _endBlock,
      _quoteToken
    );
  }

  /// @notice this needs to be called when the seller want to start AUCTION the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - starting price of a token
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToStartAuction(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    latteNFTMetadata[_nftAddress][_categoryId].isBidding = true;
    _readyToSellNFTTo(
      _nftAddress,
      _categoryId,
      _price,
      address(_msgSender()),
      _cap,
      _startBlock,
      _endBlock,
      _quoteToken
    );
  }

  /// @notice this needs to be called when the seller want to start AUCTION the token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  /// @param _price - starting price of a token
  /// @param _to - whom this token is selling to
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) external whenNotPaused onlySupportedNFT(_nftAddress) onlyNonBiddingNFT(_nftAddress, _categoryId) onlyGovernance {
    _readyToSellNFTTo(_nftAddress, _categoryId, _price, _to, _cap, _startBlock, _endBlock, _quoteToken);
  }

  /// @dev an internal function for readyToSellNFTTo
  function _readyToSellNFTTo(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) internal {
    require(
      latteNFTMetadata[_nftAddress][_categoryId].startBlock == 0,
      "LatteMarket::_readyToSellNFTTo::duplicated entry"
    );
    tokenCategorySellers[_nftAddress][_categoryId] = _to;
    _setLatteNFTMetadata(
      LatteNFTMetadataParam({
        cap: _cap,
        startBlock: _startBlock,
        endBlock: _endBlock,
        nftAddress: _nftAddress,
        nftCategoryId: _categoryId
      })
    );
    _setCurrentPrice(_nftAddress, _categoryId, _price, _quoteToken);
  }

  /// @notice cancel selling token
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  function cancelSellNFT(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyNonBiddingNFT(_nftAddress, _categoryId)
    onlyGovernance
  {
    _cancelSellNFT(_nftAddress, _categoryId);
    emit CancelSellNFT(_msgSender(), _nftAddress, _categoryId);
  }

  /// @notice cancel a bidding token, similar to cancel sell, with functionalities to return bidding amount back to the user
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id for each nft address
  function cancelBiddingNFT(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyGovernance
    onlyBiddingNFT(_nftAddress, _categoryId)
  {
    BidEntry memory bidEntry = tokenBid[_nftAddress][_categoryId];
    require(bidEntry.bidder == address(0), "LatteMarket::cancelBiddingNFT::auction already has a bidder");
    _delBidByCompositeId(_nftAddress, _categoryId);
    _cancelSellNFT(_nftAddress, _categoryId);
    emit CancelBidNFT(bidEntry.bidder, _nftAddress, _categoryId);
  }

  /// @dev internal function for cancelling a selling token
  function _cancelSellNFT(address _nftAddress, uint256 _categoryId) internal {
    delete tokenCategorySellers[_nftAddress][_categoryId];
    delete latteNFTMetadata[_nftAddress][_categoryId];
  }

  function pause() external onlyGovernance whenNotPaused {
    _pause();
    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();
    emit Unpause();
  }

  /// @dev set a new feeAddress
  function setTransferFeeAddress(address _feeAddr) external onlyOwner {
    feeAddr = _feeAddr;
    emit FeeAddressTransferred(_msgSender(), feeAddr);
  }

  /// @dev set a new fee Percentage BPS
  function setFeePercent(uint256 _feePercentBps) external onlyOwner {
    require(feePercentBps != _feePercentBps, "LatteMarket::setFeePercent::Not need update");
    require(feePercentBps <= 1e4, "LatteMarket::setFeePercent::percent exceed 100%");
    emit SetFeePercent(_msgSender(), feePercentBps, _feePercentBps);
    feePercentBps = _feePercentBps;
  }

  /// @notice use for only bidding token, this method is for bidding the following nft
  /// @param _nftAddress - nft address
  /// @param _categoryId - category id
  /// @param _price - bidding price
  function bidNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price
  )
    external
    payable
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    withinBlockRange(_nftAddress, _categoryId)
    onlyBiddingNFT(_nftAddress, _categoryId)
    onlyEOA
  {
    _bidNFT(_nftAddress, _categoryId, _price);
  }

  function _bidNFT(
    address _nftAddress,
    uint256 _categoryId,
    uint256 _price
  ) internal {
    address _seller = tokenCategorySellers[_nftAddress][_categoryId];
    address _to = address(_msgSender());
    require(_seller != _to, "LatteMarket::_bidNFT::Owner cannot bid");
    require(
      latteNFTMetadata[_nftAddress][_categoryId].price < _price,
      "LatteMarket::_bidNFT::price cannot be lower than or equal to the starting bid"
    );
    if (tokenBid[_nftAddress][_categoryId].bidder != address(0)) {
      require(
        tokenBid[_nftAddress][_categoryId].price < _price,
        "LatteMarket::_bidNFT::price cannot be lower than or equal to the latest bid"
      );
    }
    BidEntry memory prevBid = tokenBid[_nftAddress][_categoryId];
    _delBidByCompositeId(_nftAddress, _categoryId);
    tokenBid[_nftAddress][_categoryId] = BidEntry({ bidder: _to, price: _price });
    if (prevBid.bidder != address(0)) {
      _safeUnwrap(latteNFTMetadata[_nftAddress][_categoryId].quoteBep20, prevBid.bidder, prevBid.price);
    }
    _safeWrap(latteNFTMetadata[_nftAddress][_categoryId].quoteBep20, _price);
    emit Bid(_msgSender(), _nftAddress, _categoryId, _price);
  }

  function _delBidByCompositeId(address _nftAddress, uint256 _categoryId) internal {
    delete tokenBid[_nftAddress][_categoryId];
  }

  /// @notice this is like a process of releasing an nft for a quoteBep20, only used when the seller is satisfied with the bidding price
  /// @param _nftAddress an nft address
  /// @param _categoryId an nft category id
  function concludeAuction(address _nftAddress, uint256 _categoryId)
    external
    whenNotPaused
    onlySupportedNFT(_nftAddress)
    onlyBiddingNFT(_nftAddress, _categoryId)
    onlyGovernance
  {
    _concludeAuction(_nftAddress, _categoryId);
  }

  /// @dev internal function for sellNFTTo to avoid stack-too-deep
  function _concludeAuction(address _nftAddress, uint256 _categoryId) internal {
    require(
      block.number >= latteNFTMetadata[_nftAddress][_categoryId].endBlock,
      "LatteMarket::_concludeAuction::Unable to conclude auction now, bad block number"
    );
    address _seller = tokenCategorySellers[_nftAddress][_categoryId];
    _decreaseCap(_nftAddress, _categoryId, 1);
    BidEntry memory bidEntry = tokenBid[_nftAddress][_categoryId];
    require(bidEntry.price != 0, "LatteMarket::_concludeAuction::Bidder does not exist");
    uint256 price = bidEntry.price;
    uint256 feeAmount = price.mul(feePercentBps).div(1e4);
    _delBidByCompositeId(_nftAddress, _categoryId);
    if (feeAmount != 0) {
      latteNFTMetadata[_nftAddress][_categoryId].quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    latteNFTMetadata[_nftAddress][_categoryId].quoteBep20.safeTransfer(_seller, price.sub(feeAmount));
    ILatteNFT(_nftAddress).mint(bidEntry.bidder, _categoryId, "");
    emit Trade(
      tokenCategorySellers[_nftAddress][_categoryId],
      bidEntry.bidder,
      _nftAddress,
      _categoryId,
      price,
      feeAmount,
      1
    );
  }

  function _safeWrap(IERC20 _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "latteMarket::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "latteMarket::_safeWrap:: value != msg.value");
      IWETH(wNative).deposit{ value: msg.value }();
    } else {
      _quoteBep20.safeTransferFrom(_msgSender(), address(this), _amount);
    }
  }

  function _safeUnwrap(
    IERC20 _quoteBep20,
    address _to,
    uint256 _amount
  ) internal {
    if (address(_quoteBep20) == wNative) {
      _quoteBep20.safeTransfer(address(wNativeRelayer), _amount);
      wNativeRelayer.withdraw(_amount);
      SafeToken.safeTransferETH(_to, _amount);
    } else {
      _quoteBep20.safeTransfer(_to, _amount);
    }
  }

  /// @notice get all bidding entries of the following nft
  function getBid(address _nftAddress, uint256 _categoryId) external view returns (BidEntry memory) {
    return tokenBid[_nftAddress][_categoryId];
  }

  /// @dev Fallback function to accept ETH. Workers will send ETH back the pool.
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface ILatteNFT is IERC721, IERC721Metadata, IERC721Enumerable {
  // getter

  function latteNames(uint256 tokenId) external view returns (string calldata);

  function categoryInfo(uint256 tokenId)
    external
    view
    returns (
      string calldata,
      string calldata,
      uint256
    );

  function latteNFTToCategory(uint256 tokenId) external view returns (uint256);

  function categoryToLatteNFTList(uint256 categoryId) external view returns (uint256[] memory);

  function currentTokenId() external view returns (uint256);

  function currentCategoryId() external view returns (uint256);

  function categoryURI(uint256 categoryId) external view returns (string memory);

  function getLatteNameOfTokenId(uint256 tokenId) external view returns (string memory);

  // setter
  function mint(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI
  ) external returns (uint256);

  function mintBatch(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI,
    uint256 _size
  ) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WNativeRelayer is Ownable, ReentrancyGuard {
  address public wnative;
  mapping(address => bool) public okCallers;

  constructor(address _wnative) public {
    wnative = _wnative;
  }

  modifier onlyWhitelistedCaller() {
    require(okCallers[msg.sender] == true, "WNativeRelayer::onlyWhitelistedCaller:: !okCaller");
    _;
  }

  function setCallerOk(address[] calldata whitelistedCallers, bool isOk) external onlyOwner {
    uint256 len = whitelistedCallers.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okCallers[whitelistedCallers[idx]] = isOk;
    }
  }

  function withdraw(uint256 _amount) external onlyWhitelistedCaller nonReentrant {
    IWETH(wnative).withdraw(_amount);
    (bool success, ) = msg.sender.call{ value: _amount }("");
    require(success, "WNativeRelayer::onlyWhitelistedCaller:: can't withdraw");
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IOGOwnerToken.sol";

contract OGOwnerToken is IOGOwnerToken, ERC20, Ownable {
  /// @dev just reserve for future use
  address public timelock;

  mapping(address => bool) public okHolders;

  modifier onlyTimelock() {
    require(timelock == msg.sender, "OGOwnerToken::onlyTimelock:: msg.sender not timelock");
    _;
  }

  event SetOkHolders(address indexed holder, bool isOk);

  constructor(
    string memory _name,
    string memory _symbol,
    address _timelock
  ) ERC20(_name, _symbol) public {
    timelock = _timelock;
  }

  function setOkHolders(address[] memory _okHolders, bool _isOk) external override onlyOwner {
    for (uint256 idx = 0; idx < _okHolders.length; idx++) {
      okHolders[_okHolders[idx]] = _isOk;
      emit SetOkHolders(_okHolders[idx], _isOk);
    }
  }

  function mint(address to, uint256 amount) external override onlyOwner {
    require(okHolders[to], "OGOwnerToken::mint:: unapproved holder");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyOwner {
    require(okHolders[from], "OGOwnerToken::burn:: unapproved holder");
    _burn(from, amount);
  }

  function transfer(address to, uint256 amount) public override returns (bool) {
    // allow the caller to transfer back to a destination
    require(okHolders[msg.sender], "OGOwnerToken::transfer:: unapproved holder on msg.sender");
    require(okHolders[to], "OGOwnerToken::transfer:: unapproved holder on to");
    _transfer(msg.sender, to, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override returns (bool) {
    // allow the caller to transfer back to a destination
    require(okHolders[from], "OGOwnerToken::transferFrom:: unapproved holder in from");
    require(okHolders[to], "OGOwnerToken::transferFrom:: unapproved holder in to");
    _transfer(from, to, amount);
    _approve(from, _msgSender(), allowance(from, _msgSender()).sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOGOwnerToken {
  function setOkHolders(address[] calldata _okHolders, bool _isOk) external;

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMasterBarista.sol";
import "./interfaces/IMasterBaristaCallback.sol";
import "./interfaces/IBoosterConfig.sol";
import "./interfaces/IOGOwnerToken.sol";
import "./interfaces/ILatteNFT.sol";

contract OGNFT is
  ILatteNFT,
  ERC721Pausable,
  Ownable,
  AccessControl,
  ReentrancyGuard,
  IMasterBaristaCallback
{
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeERC20 for IERC20;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // role for setting up non-sensitive data
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // role for minting stuff (owner + some delegated contract eg nft market)

  struct Category {
    string name;
    string categoryURI; // category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
    uint256 timestamp;
  }

  // Used for generating the tokenId of new NFT minted
  Counters.Counter private _tokenIds;

  // Used for incrementing category id
  Counters.Counter private _categoryIds;

  // Map the latteName for a tokenId
  mapping(uint256 => string) public override latteNames;

  mapping(uint256 => Category) public override categoryInfo;

  mapping(uint256 => uint256) public override latteNFTToCategory;

  mapping(uint256 => EnumerableSet.UintSet) private _categoryToLatteNFTList;

  mapping(uint256 => string) private _tokenURIs;

  mapping(uint256 => IOGOwnerToken) public ogOwnerToken;

  IMasterBarista public masterBarista;
  IERC20 public latte;
  mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal _userStakeTokenIds;

  event AddCategoryInfo(uint256 indexed id, string name, string uri);
  event UpdateCategoryInfo(uint256 indexed id, string prevName, string newName, string newURI);
  event SetLatteName(uint256 indexed tokenId, string prevName, string newName);
  event SetTokenURI(uint256 indexed tokenId, string indexed prevURI, string indexed currentURI);
  event SetBaseURI(string indexed prevURI, string indexed currentURI);
  event SetTokenCategory(uint256 indexed tokenId, uint256 indexed categoryId);
  event Pause();
  event Unpause();
  event SetOgOwnerToken(uint256 indexed categoryId, address indexed ogOwnerToken);
  event Harvest(address indexed user, uint256 indexed categoryId, uint256 balance);
  event Stake(address indexed user, uint256 indexed categoryId, uint256 tokenId);
  event Unstake(address indexed user, uint256 indexed categoryId, uint256 tokenId);

  constructor(
    string memory _baseURI,
    IERC20 _latte,
    IMasterBarista _masterBarista
  ) ERC721("OG NFT", "LOG") public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setBaseURI(_baseURI);
    masterBarista = _masterBarista;
    latte = _latte;
  }

  /// @notice check whether this token's category id has an og owner token set
  modifier withOGOwnerToken(uint256 _tokenId) {
    require(
      address(ogOwnerToken[latteNFTToCategory[_tokenId]]) != address(0),
      "OGNFT::withOGOwnerToken:: og owner token not set"
    );
    _;
  }

  /// @dev only the one having a GOVERNANCE_ROLE can continue an execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "OGNFT::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @dev only the one having a MINTER_ROLE can continue an execution
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "OGNFT::onlyMinter::only MINTER role");
    _;
  }

  modifier onlyExistingCategoryId(uint256 _categoryId) {
    require(_categoryIds.current() >= _categoryId, "OGNFT::onlyExistingCategoryId::categoryId not existed");
    _;
  }

  /// @notice getter function for getting a token id list with respect to category Id
  /// @param _categoryId category id
  /// @return return alist of nft tokenId
  function categoryToLatteNFTList(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds = new uint256[](_categoryToLatteNFTList[_categoryId].length());
    for (uint256 i = 0; i < _categoryToLatteNFTList[_categoryId].length(); i++) {
      tokenIds[i] = _categoryToLatteNFTList[_categoryId].at(i);
    }
    return tokenIds;
  }

  /// @notice return latest token id
  /// @return uint256 of the current token id
  function currentTokenId() public view override returns (uint256) {
    return _tokenIds.current();
  }

  /// @notice return latest category id
  /// @return uint256 of the current category id
  function currentCategoryId() public view override returns (uint256) {
    return _categoryIds.current();
  }

  /// @notice add category (group of tokens)
  /// @param _name a name of a category
  /// @param _uri category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
  function addCategoryInfo(string memory _name, string memory _uri) external onlyGovernance {
    uint256 newId = _categoryIds.current();
    _categoryIds.increment();
    categoryInfo[newId] = Category({ name: _name, timestamp: block.timestamp, categoryURI: _uri });

    emit AddCategoryInfo(newId, _name, _uri);
  }

  /// @notice view function for category URI
  /// @param _categoryId category id
  function categoryURI(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (string memory)
  {
    string memory _categoryURI = categoryInfo[_categoryId].categoryURI;
    string memory base = baseURI();

    // If there is no base URI, return the category URI.
    if (bytes(base).length == 0) {
      return _categoryURI;
    }
    // If both are set, concatenate the baseURI and categoryURI (via abi.encodePacked).
    if (bytes(_categoryURI).length > 0) {
      return string(abi.encodePacked(base, _categoryURI));
    }
    // If there is a baseURI but no categoryURI, concatenate the categoryId to the baseURI.
    return string(abi.encodePacked(base, _categoryId.toString()));
  }

  /**
   * @dev overrided tokenURI with a categoryURI replacement feature
   * @param _tokenId - token id
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721, IERC721Metadata)
    returns (string memory)
  {
    require(_exists(_tokenId), "OGNFT::tokenURI:: token not existed");

    string memory _tokenURI = _tokenURIs[_tokenId];
    string memory base = baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    // If if category uri exists, use categoryURI as a tokenURI
    if (bytes(categoryInfo[latteNFTToCategory[_tokenId]].categoryURI).length > 0) {
      return string(abi.encodePacked(base, categoryInfo[latteNFTToCategory[_tokenId]].categoryURI));
    }

    // If there is a baseURI but neither have tokenURI nor categoryURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, _tokenId.toString()));
  }

  /// @notice update category (group of tokens)
  /// @param _categoryId a category id
  /// @param _newName a new updated name
  /// @param _newURI a new category URI
  function updateCategoryInfo(
    uint256 _categoryId,
    string memory _newName,
    string memory _newURI
  ) external onlyGovernance onlyExistingCategoryId(_categoryId) {
    Category storage category = categoryInfo[_categoryId];
    string memory prevName = category.name;
    category.name = _newName;
    category.categoryURI = _newURI;
    category.timestamp = block.timestamp;

    emit UpdateCategoryInfo(_categoryId, prevName, _newName, _newURI);
  }

  /// @notice update a token's categoryId
  /// @param _tokenId a token id to be updated
  /// @param _newCategoryId a new categoryId for the token
  function updateTokenCategory(uint256 _tokenId, uint256 _newCategoryId)
    external
    onlyGovernance
    onlyExistingCategoryId(_newCategoryId)
  {
    uint256 categoryIdToBeRemovedFrom = latteNFTToCategory[_tokenId];
    latteNFTToCategory[_tokenId] = _newCategoryId;
    require(
      _categoryToLatteNFTList[categoryIdToBeRemovedFrom].remove(_tokenId),
      "OGNFT::updateTokenCategory::tokenId not found"
    );
    require(_categoryToLatteNFTList[_newCategoryId].add(_tokenId), "OGNFT::updateTokenCategory::duplicated tokenId");

    emit SetTokenCategory(_tokenId, _newCategoryId);
  }

  /**
   * @dev Get the associated latteName for a unique tokenId.
   */
  function getLatteNameOfTokenId(uint256 _tokenId) external view override returns (string memory) {
    return latteNames[_tokenId];
  }

  /**
   * @dev Mint NFT. Only the minter can call it.
   */
  function mint(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI
  ) public virtual override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256) {
    uint256 newId = _tokenIds.current();
    _tokenIds.increment();
    latteNFTToCategory[newId] = _categoryId;
    require(_categoryToLatteNFTList[_categoryId].add(newId), "OGNFT::mint::duplicated tokenId");
    _mint(address(this), newId);
    _setTokenURI(newId, _tokenURI);
    // _stake(newId, _to);
    emit SetTokenCategory(newId, _categoryId);
    return newId;
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
    require(_exists(_tokenId), "OGNFT::_setTokenURI::tokenId not found");
    string memory prevURI = _tokenURIs[_tokenId];
    _tokenURIs[_tokenId] = _tokenURI;

    emit SetTokenURI(_tokenId, prevURI, _tokenURI);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyGovernance {
    _setTokenURI(_tokenId, _tokenURI);
  }

  /**
   * @dev function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function setBaseURI(string memory _baseURI) external onlyGovernance {
    string memory prevURI = baseURI();
    _setBaseURI(_baseURI);

    emit SetBaseURI(prevURI, _baseURI);
  }

  /**
   * @dev batch ming NFTs. Only the owner can call it.
   */
  function mintBatch(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI,
    uint256 _size
  ) external override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256[] memory tokenIds) {
    require(_size != 0, "OGNFT::mintBatch::size must be granter than zero");
    tokenIds = new uint256[](_size);
    for (uint256 i = 0; i < _size; ++i) {
      tokenIds[i] = mint(_to, _categoryId, _tokenURI);
    }
    return tokenIds;
  }

  /**
   * @dev Set a unique name for each tokenId. It is supposed to be called once.
   */
  function setLatteName(uint256 _tokenId, string calldata _name) external onlyGovernance {
    string memory _prevName = latteNames[_tokenId];
    latteNames[_tokenId] = _name;

    emit SetLatteName(_tokenId, _prevName, _name);
  }

  function pause() external onlyGovernance whenNotPaused {
    _pause();

    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();

    emit Unpause();
  }

  /// @notice setCategoryOGOwnerToken for setting an ogOwnerToken with regard to a category id
  /// @param _categoryId - a category id
  /// @param _ogOwnerToken - BEP20 og token for staking at a master barista
  function setCategoryOGOwnerToken(uint256 _categoryId, address _ogOwnerToken) external onlyGovernance {
    ogOwnerToken[_categoryId] = IOGOwnerToken(_ogOwnerToken);

    emit SetOgOwnerToken(_categoryId, _ogOwnerToken);
  }

  /// @dev Internal function for withdrawing a boosted stake token and receive a reward from a master barista
  /// @param _categoryId specified category id
  /// @param _shares user's shares to be withdrawn
  function _withdrawFromMasterBarista(uint256 _categoryId, uint256 _shares) internal {
    if (_shares == 0) return;
    masterBarista.withdraw(_msgSender(), address(ogOwnerToken[_categoryId]), _shares);
  }

  /// @dev Internal function for harvest a reward from a master barista
  /// @param _user harvester
  /// @param _categoryId specified category Id
  function _harvestFromMasterBarista(address _user, uint256 _categoryId) internal {
    address stakeToken = address(ogOwnerToken[_categoryId]);
    (uint256 userStakeAmount, , , ) = masterBarista.userInfo(stakeToken, _user);
    if (userStakeAmount == 0) {
      emit Harvest(_user, _categoryId, 0);
      return;
    }
    uint256 beforeReward = latte.balanceOf(_user);
    masterBarista.harvest(_user, stakeToken);

    emit Harvest(_user, _categoryId, latte.balanceOf(_user).sub(beforeReward));
  }

  /// @notice for staking a stakeToken and receive some rewards
  /// @param _tokenId a tokenId
  function stake(uint256 _tokenId) external whenNotPaused nonReentrant withOGOwnerToken(_tokenId) {
    transferFrom(_msgSender(), address(this), _tokenId);
    _stake(_tokenId, _msgSender());
  }

  /// @dev internal function for stake
  function _stake(uint256 _tokenId, address _for) internal {
    uint256 categoryId = latteNFTToCategory[_tokenId];
    IOGOwnerToken stakeToken = ogOwnerToken[categoryId];
    _userStakeTokenIds[categoryId][_for].add(_tokenId);

    _harvestFromMasterBarista(_for, categoryId);
    stakeToken.mint(address(this), 1 ether);
    IERC20(address(stakeToken)).safeApprove(address(masterBarista), 1 ether);

    masterBarista.deposit(_for, address(stakeToken), 1 ether);

    IERC20(address(stakeToken)).safeApprove(address(masterBarista), 0);

    emit Stake(_for, categoryId, _tokenId);
  }

  /// @dev internal function for unstaking a stakeToken and receive some rewards
  /// @param _tokenId a tokenId
  function _unstake(uint256 _tokenId) internal {
    uint256 categoryId = latteNFTToCategory[_tokenId];
    require(
      _userStakeTokenIds[categoryId][_msgSender()].contains(_tokenId),
      "OGNFT::_unstake:: invalid token to be unstaked"
    );
    IOGOwnerToken stakeToken = ogOwnerToken[categoryId];
    _userStakeTokenIds[categoryId][_msgSender()].remove(_tokenId);

    _withdrawFromMasterBarista(categoryId, 1 ether);
    stakeToken.burn(address(this), 1 ether);
    _transfer(address(this), _msgSender(), _tokenId);
    emit Unstake(_msgSender(), categoryId, _tokenId);
  }

  /// @dev function for unstaking a stakeToken and receive some rewards
  /// @param _tokenId a tokenId
  function unstake(uint256 _tokenId) external whenNotPaused withOGOwnerToken(_tokenId) nonReentrant {
    _unstake(_tokenId);
  }

  /// @notice function for harvesting the reward
  /// @param _categoryId a categoryId linked to an og owner token pool to be harvested
  function harvest(uint256 _categoryId) external whenNotPaused nonReentrant {
    require(address(ogOwnerToken[_categoryId]) != address(0), "OGNFT::harvest:: og owner token not set");
    _harvestFromMasterBarista(_msgSender(), _categoryId);
  }

  /// @notice function for harvesting rewards in specified staking tokens
  /// @param _categoryIdParams a set of tokenId to be harvested
  function harvest(uint256[] calldata _categoryIdParams) external whenNotPaused nonReentrant {
    for (uint256 i = 0; i < _categoryIdParams.length; i++) {
      require(address(ogOwnerToken[_categoryIdParams[i]]) != address(0), "OGNFT::harvest:: og owner token not set");
      _harvestFromMasterBarista(_msgSender(), _categoryIdParams[i]);
    }
  }

  /// @dev a notifier function for letting some observer call when some conditions met
  /// @dev currently, the caller will be a master barista calling before a latte lock
  function masterBaristaCall(
    address, /*stakeToken*/
    address, /*userAddr*/
    uint256, /*reward*/
    uint256 /*lastRewardBlock*/
  ) external override {
    return;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IMasterBarista {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingLatte(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function devAddr() external view returns (address);

  function devFeeBps() external view returns (uint256);

  /// @dev configuration functions
  function addPool(address _stakeToken, uint256 _allocPoint) external;

  function setPool(address _stakeToken, uint256 _allocPoint) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositLatte(address _for, uint256 _amount) external;

  function withdrawLatte(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterBaristaCallback {
  function masterBaristaCall(
    address stakeToken,
    address userAddr,
    uint256 unboostedReward,
    uint256 lastRewardBlock
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

import "./interfaces/ILatteNFT.sol";
import "./interfaces/IWNativeRelayer.sol";
import "./interfaces/IWETH.sol";
import "./library/SafeToken.sol";
import "./interfaces/IOGPriceModel.sol";

contract OGNFTOffering is ERC721Holder, Ownable, Pausable, AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  struct OGNFTMetadataParam {
    uint256 nftCategoryId;
    uint256 cap;
    uint256 startBlock;
    uint256 endBlock;
  }

  struct OGNFTMetadata {
    uint256 cap;
    uint256 maxCap;
    uint256 startBlock;
    uint256 endBlock;
    bool isBidding;
    IERC20 quoteBep20;
  }

  struct OGNFTBuyLimitMetadata {
    uint256 counter;
    uint256 cooldownStartBlock;
  }

  address public ogNFT;
  address public feeAddr;
  uint256 public feePercentBps;
  uint256 public buyLimitCount;
  uint256 public buyLimitPeriod;
  IWNativeRelayer public wNativeRelayer;
  IOGPriceModel public priceModel;
  address public wNative;
  mapping(uint256 => address) public tokenCategorySellers;

  // og nft original nft related
  mapping(uint256 => OGNFTMetadata) public ogNFTMetadata;
  mapping(address => mapping(uint256 => OGNFTBuyLimitMetadata)) public buyLimitMetadata;

  event Trade(address indexed seller, address indexed buyer, uint256 indexed nftCategoryId, uint256 price, uint256 fee);
  event SetQuoteBep20(address indexed seller, uint256 indexed nftCategoryId, IERC20 quoteToken);
  event SetOGNFTMetadata(uint256 indexed nftCategoryId, uint256 cap, uint256 startBlock, uint256 endBlock);
  event CancelSellNFT(address indexed seller, uint256 indexed nftCategoryId);
  event FeeAddressTransferred(address indexed previousOwner, address indexed newOwner);
  event SetFeePercent(address indexed seller, uint256 oldFeePercent, uint256 newFeePercent);
  event SetPriceModel(IOGPriceModel indexed newPriceModel);
  event SetBuyLimitCount(uint256 buyLimitCount);
  event SetBuyLimitPeriod(uint256 buyLimitPeriod);
  event UpdateBuyLimit(uint256 counter, uint256 cooldownStartBlock);
  event Pause();
  event Unpause();

  constructor(
    address _ogNFT,
    address _feeAddr,
    uint256 _feePercentBps,
    IWNativeRelayer _wNativeRelayer,
    address _wNative,
    IOGPriceModel _priceModel
  ) public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    require(_ogNFT != address(0), "OGNFTOffering::initialize:: og nft cannot be address(0)");
    require(address(_priceModel) != address(0), "OGNFTOffering::initialize:: price model cannot be address(0)");

    ogNFT = _ogNFT;
    priceModel = _priceModel;
    feeAddr = _feeAddr;
    feePercentBps = _feePercentBps;
    wNativeRelayer = _wNativeRelayer;
    wNative = _wNative;
    buyLimitCount = 5;
    buyLimitPeriod = 100; //100 blocks, 5 mins

    emit SetPriceModel(_priceModel);
    emit SetBuyLimitCount(buyLimitCount);
    emit SetBuyLimitPeriod(buyLimitPeriod);
    emit FeeAddressTransferred(address(0), feeAddr);
    emit SetFeePercent(_msgSender(), 0, feePercentBps);
  }

  /**
   * @notice check address
   */
  modifier validAddress(address _addr) {
    require(_addr != address(0));
    _;
  }

  /// @notice only GOVERNANCE ROLE (role that can setup NON sensitive parameters) can continue the execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "OGNFTOffering::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @notice if the block number is not within the start and end block number, reverted
  modifier withinBlockRange(uint256 _categoryId) {
    require(
      block.number >= ogNFTMetadata[_categoryId].startBlock && block.number <= ogNFTMetadata[_categoryId].endBlock,
      "OGNFTOffering::withinBlockRange:: invalid block number"
    );
    _;
  }

  /// @notice only verified signature can continue a statement
  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "OGNFTOffering::permit::INVALID_SIGNATURE");
    _;
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "OGNFTOffering::onlyEOA:: not eoa");
    _;
  }

  /// @notice set price model for getting a price
  function setPriceModel(IOGPriceModel _priceModel) external onlyOwner {
    require(address(_priceModel) != address(0), "OGNFTOffering::permit::price model cannot be address(0)");
    priceModel = _priceModel;
    emit SetPriceModel(_priceModel);
  }

  /// @notice set the maximum amount of nfts that can be bought within the period
  function setBuyLimitCount(uint256 _buyLimitCount) external onlyOwner {
    buyLimitCount = _buyLimitCount;
    emit SetBuyLimitCount(_buyLimitCount);
  }

  /// @notice set the buy limit period (in block number)
  /// @dev this will be use for a buy limit mechanism
  /// within this period, the user can only buy nfts at limited amount. (using buyLimitCount as a comparator)
  function setBuyLimitPeriod(uint256 _buyLimitPeriod) external onlyOwner {
    buyLimitPeriod = _buyLimitPeriod;
    emit SetBuyLimitPeriod(_buyLimitPeriod);
  }

  /// @dev set OG NFT metadata consisted of cap, startBlock, and endBlock
  function setOGNFTMetadata(OGNFTMetadataParam[] calldata _params) external onlyGovernance {
    for (uint256 i = 0; i < _params.length; i++) {
      _setOGNFTMetadata(_params[i]);
    }
  }

  function _setOGNFTMetadata(OGNFTMetadataParam memory _param) internal {
    require(
      _param.startBlock >= block.number && _param.endBlock > _param.startBlock,
      "OGNFTOffering::_setOGNFTMetadata::invalid start or end block"
    );
    OGNFTMetadata storage metadata = ogNFTMetadata[_param.nftCategoryId];
    metadata.cap = _param.cap;
    metadata.maxCap = _param.cap;
    metadata.startBlock = _param.startBlock;
    metadata.endBlock = _param.endBlock;

    emit SetOGNFTMetadata(_param.nftCategoryId, _param.cap, _param.startBlock, _param.endBlock);
  }

  /// @dev set a current quoteBep20 of an og with the following categoryId
  function setQuoteBep20(uint256 _categoryId, IERC20 _quoteToken) external whenNotPaused onlyGovernance {
    _setQuoteBep20(_categoryId, _quoteToken);
  }

  function _setQuoteBep20(uint256 _categoryId, IERC20 _quoteToken) internal {
    require(address(_quoteToken) != address(0), "OGNFTOffering::_setQuoteBep20::invalid quote token");
    ogNFTMetadata[_categoryId].quoteBep20 = _quoteToken;
    emit SetQuoteBep20(_msgSender(), _categoryId, _quoteToken);
  }

  /// @notice buyNFT based on its category id
  /// @param _categoryId - category id for each nft address
  function buyNFT(uint256 _categoryId) external payable whenNotPaused withinBlockRange(_categoryId) onlyEOA {
    _buyNFTTo(_categoryId, _msgSender());
  }

  /// @dev use to decrease a total cap by 1, will get reverted if no more to be decreased
  function _decreaseCap(uint256 _categoryId, uint256 _size) internal {
    require(ogNFTMetadata[_categoryId].cap >= _size, "OGNFTOffering::_decreaseCap::maximum mint cap reached");
    ogNFTMetadata[_categoryId].cap = ogNFTMetadata[_categoryId].cap.sub(_size);
  }

  /// @dev internal method for buyNFTTo to avoid stack-too-deep
  function _buyNFTTo(uint256 _categoryId, address _to) internal {
    _decreaseCap(_categoryId, 1);
    OGNFTMetadata memory metadata = ogNFTMetadata[_categoryId];
    uint256 price = priceModel.getPrice(metadata.maxCap, metadata.cap, _categoryId);
    uint256 feeAmount = price.mul(feePercentBps).div(1e4);
    _updateBuyLimit(_categoryId, _to);
    require(buyLimitMetadata[_to][_categoryId].counter <= buyLimitCount, "OGNFTOffering::_buyNFTTo::exceed buy limit");
    _safeWrap(metadata.quoteBep20, price);
    if (feeAmount != 0) {
      metadata.quoteBep20.safeTransfer(feeAddr, feeAmount);
    }
    metadata.quoteBep20.safeTransfer(tokenCategorySellers[_categoryId], price.sub(feeAmount));
    ILatteNFT(ogNFT).mint(_to, _categoryId, "");
    emit Trade(tokenCategorySellers[_categoryId], _to, _categoryId, price, feeAmount);
  }

  function _updateBuyLimit(uint256 _category, address _buyer) internal {
    OGNFTBuyLimitMetadata storage _buyLimitMetadata = buyLimitMetadata[_buyer][_category];
    _buyLimitMetadata.counter = _buyLimitMetadata.counter.add(1);

    if (
      uint256(block.number).sub(_buyLimitMetadata.cooldownStartBlock) > buyLimitPeriod ||
      _buyLimitMetadata.cooldownStartBlock == 0
    ) {
      _buyLimitMetadata.counter = 1;
      _buyLimitMetadata.cooldownStartBlock = block.number;
    }

    emit UpdateBuyLimit(_buyLimitMetadata.counter, _buyLimitMetadata.cooldownStartBlock);
  }

  /// @notice this needs to be called when the seller want to SELL the token
  /// @param _categoryId - category id for each nft address
  /// @param _cap - total cap for this nft address with a category id
  /// @param _startBlock - starting block for a sale
  /// @param _endBlock - end block for a sale
  function readyToSellNFT(
    uint256 _categoryId,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) external whenNotPaused onlyGovernance {
    _readyToSellNFTTo(_categoryId, address(_msgSender()), _cap, _startBlock, _endBlock, _quoteToken);
  }

  /// @dev an internal function for readyToSellNFTTo
  function _readyToSellNFTTo(
    uint256 _categoryId,
    address _to,
    uint256 _cap,
    uint256 _startBlock,
    uint256 _endBlock,
    IERC20 _quoteToken
  ) internal {
    require(ogNFTMetadata[_categoryId].startBlock == 0, "OGNFTOffering::_readyToSellNFTTo::duplicated entry");
    tokenCategorySellers[_categoryId] = _to;
    _setOGNFTMetadata(
      OGNFTMetadataParam({ cap: _cap, startBlock: _startBlock, endBlock: _endBlock, nftCategoryId: _categoryId })
    );
    _setQuoteBep20(_categoryId, _quoteToken);
  }

  /// @notice cancel selling token
  /// @param _categoryId - category id for each nft address
  function cancelSellNFT(uint256 _categoryId) external whenNotPaused onlyGovernance {
    _cancelSellNFT(_categoryId);
    emit CancelSellNFT(_msgSender(), _categoryId);
  }

  /// @dev internal function for cancelling a selling token
  function _cancelSellNFT(uint256 _categoryId) internal {
    delete tokenCategorySellers[_categoryId];
    delete ogNFTMetadata[_categoryId];
  }

  function pause() external onlyGovernance whenNotPaused {
    _pause();
    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();
    emit Unpause();
  }

  /// @dev set a new feeAddress
  function setTransferFeeAddress(address _feeAddr) external onlyOwner {
    feeAddr = _feeAddr;
    emit FeeAddressTransferred(_msgSender(), feeAddr);
  }

  /// @dev set a new fee Percentage BPS
  function setFeePercent(uint256 _feePercentBps) external onlyOwner {
    require(feePercentBps != _feePercentBps, "OGNFTOffering::setFeePercent::Not need update");
    require(feePercentBps <= 1e4, "OGNFTOffering::setFeePercent::percent exceed 100%");
    emit SetFeePercent(_msgSender(), feePercentBps, _feePercentBps);
    feePercentBps = _feePercentBps;
  }

  function _safeWrap(IERC20 _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "OGNFTOffering::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "OGNFTOffering::_safeWrap:: value != msg.value");
      IWETH(wNative).deposit{ value: msg.value }();
    } else {
      _quoteBep20.safeTransferFrom(_msgSender(), address(this), _amount);
    }
  }

  function _safeUnwrap(
    IERC20 _quoteBep20,
    address _to,
    uint256 _amount
  ) internal {
    if (address(_quoteBep20) == wNative) {
      _quoteBep20.safeTransfer(address(wNativeRelayer), _amount);
      wNativeRelayer.withdraw(_amount);
      SafeToken.safeTransferETH(_to, _amount);
    } else {
      _quoteBep20.safeTransfer(_to, _amount);
    }
  }

  /// @dev Fallback function to accept BNB
  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWNativeRelayer {
  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "!safeTransferETH");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IOGPriceModel {
  /// @dev Return the price based on a triple slope
  function getPrice(
    uint256 maxCap,
    uint256 cap,
    uint256 categoryId
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IOGPriceModel.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TripleSlopePriceModel is IOGPriceModel, Ownable {
  using SafeMath for uint256;

  uint256 public constant CEIL_SLOPE_1_BPS = 1e4;
  uint256 public constant CEIL_SLOPE_2_BPS = 5000;
  uint256 public constant CEIL_SLOPE_3_BPS = 2000;

  struct SetPricePerCategoryParams {
    uint256 categoryId;
    uint256 slope;
    uint256 price;
  }

  // categoryId -> slope bps -> price
  mapping(uint256 => mapping(uint256 => uint256)) public price;

  event SetPricePerCategory(uint256 indexed categoryId, uint256 indexed slope, uint256 price);

  constructor(SetPricePerCategoryParams[] memory _params) public {
    _setPricePerCategories(_params);
  }

  /// @dev Return the price based on triple slope
  function getPrice(
    uint256 maxCap,
    uint256 cap,
    uint256 categoryId
  ) external view override returns (uint256) {
    if (maxCap == 0) return 0;
    uint256 capLeftBps = cap.mul(1e4).div(maxCap);
    if (capLeftBps < CEIL_SLOPE_3_BPS) return price[categoryId][CEIL_SLOPE_3_BPS];
    if (capLeftBps < CEIL_SLOPE_2_BPS) return price[categoryId][CEIL_SLOPE_2_BPS];
    return price[categoryId][CEIL_SLOPE_1_BPS];
  }

  function _setPricePerCategories(SetPricePerCategoryParams[] memory _params) internal {
    for (uint256 idx = 0; idx < _params.length; idx++) {
      price[_params[idx].categoryId][_params[idx].slope] = _params[idx].price;
      emit SetPricePerCategory(_params[idx].categoryId, _params[idx].slope, _params[idx].price);
    }
  }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IMasterBarista.sol";
import "./interfaces/IOGNFT.sol";
import "./interfaces/ILatteNFT.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IBoosterConfig.sol";

contract NFTScanner is Context {
    using SafeMath for uint256;

    struct OGNFT {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        bool isStaking;
    }

    struct BoosterNFT {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        uint256 maxEnergy;
        uint256 currentEnergy;
        uint256 boostBps;
    }

    struct BoosterTokenInfo {
        address nftAddress;
        uint256 nftCategoryId;
        uint256 nftTokenId;
        bool isOwner;
        bool isApproved;
        bool[] isAllowance;
        bool[] isStakingIn;
    }

    IMasterBarista public masterBarista;
    IOGNFT public ogNFT;
    ILatteNFT public latteNFT;
    IBooster public booster;
    IBoosterConfig public boosterConfig;

    constructor(
        IMasterBarista _masterBarista,
        IOGNFT _ogNFT,
        ILatteNFT _latteNFT,
        IBooster _booster,
        IBoosterConfig _boosterConfig
    ) public {
        masterBarista = _masterBarista;
        ogNFT = _ogNFT;
        latteNFT = _latteNFT;
        booster = _booster;
        boosterConfig = _boosterConfig;
    }

    function getOGNFTInfo(address _user)
        external
        view
        returns (OGNFT[] memory)
    {
        uint256 _balance = ogNFT.balanceOf(_user);

        OGNFT[] memory ogNFTInfo = new OGNFT[](_balance);

        for (uint256 i = 0; i < _balance; i++) {
            uint256 _nftTokenId = ogNFT.tokenOfOwnerByIndex(_user, i);
            uint256 _nftCategoryId = ogNFT.latteNFTToCategory(_nftTokenId);

            ogNFTInfo[i] = OGNFT({
                nftAddress: address(ogNFT),
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                isStaking: false
            });
        }

        return ogNFTInfo;
    }

    function getOGNFTStakingInfo(address _user)
        public
        view
        returns (OGNFT[] memory)
    {
        uint256 _currentCategoryId = ogNFT.currentCategoryId();
        uint256 _currentTokenId = ogNFT.currentTokenId();

        OGNFT[] memory ogNFTStakingInfo = new OGNFT[](_currentTokenId + 1);

        for (
            uint256 _nftCategoryId = 0;
            _nftCategoryId <= _currentCategoryId;
            _nftCategoryId++
        ) {
            uint256[] memory _nftTokenIds = ogNFT.userStakeTokenIds(
                _nftCategoryId,
                _user
            );

            if (_nftTokenIds.length != 0) {
                for (uint256 i = 0; i < _nftTokenIds.length; i++) {
                    uint256 _nftTokenId = _nftTokenIds[i];

                    ogNFTStakingInfo[_nftCategoryId] = OGNFT({
                        nftAddress: address(ogNFT),
                        nftCategoryId: _nftCategoryId,
                        nftTokenId: _nftTokenId,
                        isStaking: true
                    });
                }
            }
        }

        return ogNFTStakingInfo;
    }

    function getBoosterInfo(address _user)
        external
        view
        returns (BoosterNFT[] memory)
    {
        uint256 balance = latteNFT.balanceOf(_user);
        BoosterNFT[] memory boosterNFTInfo = new BoosterNFT[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 _nftTokenId = latteNFT.tokenOfOwnerByIndex(_user, i);
            uint256 _nftCategoryId = latteNFT.latteNFTToCategory(_nftTokenId);
            (
                uint256 _maxEnergy,
                uint256 _currentEnergy,
                uint256 _boostBps
            ) = boosterConfig.energyInfo(address(latteNFT), _nftTokenId);
            boosterNFTInfo[i] = BoosterNFT({
                nftAddress: address(latteNFT),
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                maxEnergy: _maxEnergy,
                currentEnergy: _currentEnergy,
                boostBps: _boostBps
            });
        }

        return boosterNFTInfo;
    }

    function getBoosterStakingInfo(address[] memory _stakeTokens, address _user)
        external
        view
        returns (BoosterNFT[] memory)
    {
        BoosterNFT[] memory boosterNFTStakingInfo = new BoosterNFT[](
            _stakeTokens.length
        );

        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            (address _nftAddress, uint256 _nftTokenId) = booster.userStakingNFT(
                _stakeTokens[i],
                _user
            );

            if (_nftAddress != address(0)) {
                uint256 _nftCategoryId = latteNFT.latteNFTToCategory(
                    _nftTokenId
                );
                (
                    uint256 _maxEnergy,
                    uint256 _currentEnergy,
                    uint256 _boostBps
                ) = boosterConfig.energyInfo(address(latteNFT), _nftTokenId);
                boosterNFTStakingInfo[i] = BoosterNFT({
                    nftAddress: _nftAddress,
                    nftCategoryId: _nftCategoryId,
                    nftTokenId: _nftTokenId,
                    maxEnergy: _maxEnergy,
                    currentEnergy: _currentEnergy,
                    boostBps: _boostBps
                });
            }
        }

        return boosterNFTStakingInfo;
    }

    function getBoosterTokenInfo(
        address[] memory _stakeTokens,
        address _nftAddress,
        uint256 _nftCategoryId,
        uint256 _nftTokenId,
        address _user
    ) external returns (BoosterTokenInfo memory) {
        address _owner = latteNFT.ownerOf(_nftTokenId);
        address _approvedAddress = latteNFT.getApproved(_nftTokenId);
        bool[] memory _isAllowance = new bool[](_stakeTokens.length);
        bool[] memory _isStakingIn = new bool[](_stakeTokens.length);

        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            _isAllowance[i] = boosterConfig.boosterNftAllowance(
                _stakeTokens[i],
                _nftAddress,
                _nftTokenId
            );
            (address _stakingNFTAddress, uint256 _stakingNFTTokenId) = booster
                .userStakingNFT(_stakeTokens[i], _user);
            _isStakingIn[i] =
                _owner == address(booster) &&
                _nftAddress == _stakingNFTAddress &&
                _nftTokenId == _stakingNFTTokenId;
        }

        return
            BoosterTokenInfo({
                nftAddress: _nftAddress,
                nftCategoryId: _nftCategoryId,
                nftTokenId: _nftTokenId,
                isOwner: _owner == _user,
                isApproved: _approvedAddress == address(booster),
                isAllowance: _isAllowance,
                isStakingIn: _isStakingIn
            });
    }
}

pragma solidity 0.6.12;

import "./ILatteNFT.sol";

interface IOGNFT is ILatteNFT {
    function ogOwnerToken(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            string calldata,
            string calldata
        );

    function userStakeTokenIds(uint256 _categoryId, address _user)
        external
        view
        returns (uint256[] memory);
}

pragma solidity 0.6.12;

interface IBooster {
    function userInfo(address _stakeToken, address _user)
        external
        view
        returns (uint256, uint256);

    function totalAccumBoostedReward(address _stakeToken)
        external
        view
        returns (uint256);

    function userStakingNFT(address _stakeToken, address _user)
        external
        view
        returns (address, uint256);

    function stakeNFT(
        address _stakeToken,
        address _nftAddress,
        uint256 _nftTokenId
    ) external;

    function unstakeNFT(address _stakeToken) external;

    function stake(address _stakeToken, uint256 _amount) external payable;

    function unstake(address _stakeToken, uint256 _amount) external;

    function unstakeAll(address _stakeToken) external;

    function harvest(address _stakeToken) external;

    function harvest(address[] memory _stakeTokens) external;

    function masterBaristaCall(
        address stakeToken,
        address userAddr,
        uint256 unboostedReward,
        uint256 lastRewardBlock
    ) external;

    function emergencyWithdraw(address _stakeToken) external;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IBoosterConfig.sol";
import "./interfaces/ILatteNFT.sol";

contract BoosterConfig is IBoosterConfig, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  struct BoosterNFTInfo {
    address nftAddress;
    uint256 tokenId;
  }

  struct BoosterEnergyInfo {
    uint256 maxEnergy;
    uint256 currentEnergy;
    uint256 boostBps;
    uint256 updatedAt;
  }

  struct CategoryEnergyInfo {
    uint256 maxEnergy;
    uint256 boostBps;
    uint256 updatedAt;
  }

  struct BoosterNFTParams {
    address nftAddress;
    uint256 nftTokenId;
    uint256 maxEnergy;
    uint256 boostBps;
  }

  struct CategoryNFTParams {
    address nftAddress;
    uint256 nftCategoryId;
    uint256 maxEnergy;
    uint256 boostBps;
  }

  struct BoosterAllowance {
    address nftAddress;
    uint256 nftTokenId;
    bool allowance;
  }

  struct BoosterAllowanceParams {
    address stakingToken;
    BoosterAllowance[] allowance;
  }

  struct CategoryAllowance {
    address nftAddress;
    uint256 nftCategoryId;
    bool allowance;
  }

  struct CategoryAllowanceParams {
    address stakingToken;
    CategoryAllowance[] allowance;
  }

  mapping(address => mapping(uint256 => BoosterEnergyInfo)) public boosterEnergyInfo;
  mapping(address => mapping(uint256 => CategoryEnergyInfo)) public categoryEnergyInfo;

  mapping(address => mapping(address => mapping(uint256 => bool))) public boosterNftAllowanceConfig;
  mapping(address => mapping(address => mapping(uint256 => bool))) public categoryNftAllowanceConfig;

  mapping(address => bool) public override stakeTokenAllowance;

  mapping(address => bool) public override callerAllowance;

  event UpdateCurrentEnergy(
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    uint256 indexed updatedCurrentEnergy
  );
  event SetStakeTokenAllowance(address indexed stakingToken, bool isAllowed);
  event SetBoosterNFTEnergyInfo(
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    uint256 maxEnergy,
    uint256 currentEnergy,
    uint256 boostBps
  );
  event SetCallerAllowance(address indexed caller, bool isAllowed);
  event SetBoosterNFTAllowance(
    address indexed stakeToken,
    address indexed nftAddress,
    uint256 indexed nftTokenId,
    bool isAllowed
  );
  event SetCategoryNFTEnergyInfo(
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    uint256 maxEnergy,
    uint256 boostBps
  );
  event SetCategoryNFTAllowance(
    address indexed stakeToken,
    address indexed nftAddress,
    uint256 indexed nftCategoryId,
    bool isAllowed
  );

  /// @notice only eligible caller can continue the execution
  modifier onlyCaller() {
    require(callerAllowance[msg.sender], "BoosterConfig::onlyCaller::only eligible caller");
    _;
  }

  constructor() public {
  }

  /// @notice getter function for energy info
  /// @dev check if the booster energy existed,
  /// if not, it should be non-preminted version, so use categoryEnergyInfo to get a current, maxEnergy instead
  function energyInfo(address _nftAddress, uint256 _nftTokenId)
    public
    view
    override
    returns (
      uint256 maxEnergy,
      uint256 currentEnergy,
      uint256 boostBps
    )
  {
    BoosterEnergyInfo memory boosterInfo = boosterEnergyInfo[_nftAddress][_nftTokenId];
    // if there is no preset booster energy info, use preset in category info
    // presume that it's not a preminted nft
    if (boosterInfo.updatedAt == 0) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryInfo = categoryEnergyInfo[_nftAddress][categoryId];
      return (categoryInfo.maxEnergy, categoryInfo.maxEnergy, categoryInfo.boostBps);
    }
    // if there is an updatedAt, it's a preminted nft
    return (boosterInfo.maxEnergy, boosterInfo.currentEnergy, boosterInfo.boostBps);
  }

  /// @notice function for updating a curreny energy of the specified nft
  /// @dev Only eligible caller can freely update an energy
  /// @param _nftAddress a composite key for nft
  /// @param _nftTokenId a composite key for nft
  /// @param _energyToBeConsumed an energy to be consumed
  function consumeEnergy(
    address _nftAddress,
    uint256 _nftTokenId,
    uint256 _energyToBeConsumed
  ) external override onlyCaller {
    require(_nftAddress != address(0), "BoosterConfig::consumeEnergy::_nftAddress must not be address(0)");
    BoosterEnergyInfo storage energy = boosterEnergyInfo[_nftAddress][_nftTokenId];

    if (energy.updatedAt == 0) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryEnergy = categoryEnergyInfo[_nftAddress][categoryId];
      require(categoryEnergy.updatedAt != 0, "BoosterConfig::consumeEnergy:: invalid nft to be updated");
      energy.maxEnergy = categoryEnergy.maxEnergy;
      energy.boostBps = categoryEnergy.boostBps;
      energy.currentEnergy = categoryEnergy.maxEnergy;
    }

    energy.currentEnergy = energy.currentEnergy.sub(_energyToBeConsumed);
    energy.updatedAt = block.timestamp;

    emit UpdateCurrentEnergy(_nftAddress, _nftTokenId, energy.currentEnergy);
  }

  /// @notice set stake token allowance
  /// @dev only owner can call this function
  /// @param _stakeToken a specified token
  /// @param _isAllowed a flag indicating the allowance of a specified token
  function setStakeTokenAllowance(address _stakeToken, bool _isAllowed) external onlyOwner {
    require(_stakeToken != address(0), "BoosterConfig::setStakeTokenAllowance::_stakeToken must not be address(0)");
    stakeTokenAllowance[_stakeToken] = _isAllowed;

    emit SetStakeTokenAllowance(_stakeToken, _isAllowed);
  }

  /// @notice set caller allowance - only eligible caller can call a function
  /// @dev only eligible callers can call this function
  /// @param _caller a specified caller
  /// @param _isAllowed a flag indicating the allowance of a specified token
  function setCallerAllowance(address _caller, bool _isAllowed) external onlyOwner {
    require(_caller != address(0), "BoosterConfig::setCallerAllowance::_caller must not be address(0)");
    callerAllowance[_caller] = _isAllowed;

    emit SetCallerAllowance(_caller, _isAllowed);
  }

  /// @notice A function for setting booster NFT energy info as a batch
  /// @param _params a list of BoosterNFTParams [{nftAddress, nftTokenId, maxEnergy, boostBps}]
  function setBatchBoosterNFTEnergyInfo(BoosterNFTParams[] calldata _params) external onlyOwner {
    for (uint256 i = 0; i < _params.length; ++i) {
      _setBoosterNFTEnergyInfo(_params[i]);
    }
  }

  /// @notice A function for setting booster NFT energy info
  /// @param _param a BoosterNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function setBoosterNFTEnergyInfo(BoosterNFTParams calldata _param) external onlyOwner {
    _setBoosterNFTEnergyInfo(_param);
  }

  /// @dev An internal function for setting booster NFT energy info
  /// @param _param a BoosterNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function _setBoosterNFTEnergyInfo(BoosterNFTParams calldata _param) internal {
    boosterEnergyInfo[_param.nftAddress][_param.nftTokenId] = BoosterEnergyInfo({
      maxEnergy: _param.maxEnergy,
      currentEnergy: _param.maxEnergy,
      boostBps: _param.boostBps,
      updatedAt: block.timestamp
    });

    emit SetBoosterNFTEnergyInfo(
      _param.nftAddress,
      _param.nftTokenId,
      _param.maxEnergy,
      _param.maxEnergy,
      _param.boostBps
    );
  }

  /// @notice A function for setting category NFT energy info as a batch, used for nft with non-preminted
  /// @param _params a list of CategoryNFTParams [{nftAddress, nftTokenId, maxEnergy, boostBps}]
  function setBatchCategoryNFTEnergyInfo(CategoryNFTParams[] calldata _params) external onlyOwner {
    for (uint256 i = 0; i < _params.length; ++i) {
      _setCategoryNFTEnergyInfo(_params[i]);
    }
  }

  /// @notice A function for setting category NFT energy info, used for nft with non-preminted
  /// @param _param a CategoryNFTParams {nftAddress, nftTokenId, maxEnergy, boostBps}
  function setCategoryNFTEnergyInfo(CategoryNFTParams calldata _param) external onlyOwner {
    _setCategoryNFTEnergyInfo(_param);
  }

  /// @dev An internal function for setting category NFT energy info, used for nft with non-preminted
  /// @param _param a CategoryNFTParams {nftAddress, nftCategoryId, maxEnergy, boostBps}
  function _setCategoryNFTEnergyInfo(CategoryNFTParams calldata _param) internal {
    categoryEnergyInfo[_param.nftAddress][_param.nftCategoryId] = CategoryEnergyInfo({
      maxEnergy: _param.maxEnergy,
      boostBps: _param.boostBps,
      updatedAt: block.timestamp
    });

    emit SetCategoryNFTEnergyInfo(_param.nftAddress, _param.nftCategoryId, _param.maxEnergy, _param.boostBps);
  }

  /// @dev A function setting if a particular stake token should allow a specified nft category to be boosted (used with non-preminted nft)
  /// @param _param a CategoryAllowanceParams {stakingToken, [{nftAddress, nftCategoryId, allowance;}]}
  function setStakingTokenCategoryAllowance(CategoryAllowanceParams calldata _param) external onlyOwner {
    for (uint256 i = 0; i < _param.allowance.length; ++i) {
      require(
        stakeTokenAllowance[_param.stakingToken],
        "BoosterConfig::setStakingTokenCategoryAllowance:: bad staking token"
      );
      categoryNftAllowanceConfig[_param.stakingToken][_param.allowance[i].nftAddress][
        _param.allowance[i].nftCategoryId
      ] = _param.allowance[i].allowance;

      emit SetCategoryNFTAllowance(
        _param.stakingToken,
        _param.allowance[i].nftAddress,
        _param.allowance[i].nftCategoryId,
        _param.allowance[i].allowance
      );
    }
  }

  /// @dev A function setting if a particular stake token should allow a specified nft to be boosted
  /// @param _param a BoosterAllowanceParams {stakingToken, [{nftAddress, nftTokenId,allowance;}]}
  function setStakingTokenBoosterAllowance(BoosterAllowanceParams calldata _param) external onlyOwner {
    for (uint256 i = 0; i < _param.allowance.length; ++i) {
      require(
        stakeTokenAllowance[_param.stakingToken],
        "BoosterConfig::setStakingTokenBoosterAllowance:: bad staking token"
      );
      boosterNftAllowanceConfig[_param.stakingToken][_param.allowance[i].nftAddress][
        _param.allowance[i].nftTokenId
      ] = _param.allowance[i].allowance;

      emit SetBoosterNFTAllowance(
        _param.stakingToken,
        _param.allowance[i].nftAddress,
        _param.allowance[i].nftTokenId,
        _param.allowance[i].allowance
      );
    }
  }

  /// @notice use for checking whether or not this nft supports an input stakeToken
  /// @dev if not support when checking with token, need to try checking with category level (categoryNftAllowanceConfig) as well since there should not be boosterNftAllowanceConfig in non-preminted nft
  function boosterNftAllowance(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  ) external view override returns (bool) {
    if (!boosterNftAllowanceConfig[_stakeToken][_nftAddress][_nftTokenId]) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      return categoryNftAllowanceConfig[_stakeToken][_nftAddress][categoryId];
    }
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../library/LinkList.sol";
import "./interfaces/ILATTE.sol";
import "./interfaces/ILATTEV2.sol";
import "./interfaces/IBeanBag.sol";
import "./interfaces/IMasterBarista.sol";
import "./interfaces/IMasterBaristaCallback.sol";

/// @notice MasterBarista is a smart contract for distributing LATTE by asking user to stake the BEP20-based token.
contract MasterBarista is IMasterBarista, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using LinkList for LinkList.List;
  using Address for address;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 bonusDebt; // Last block that user exec something to the pool.
    address fundedBy;
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool.
    uint256 lastRewardBlock; // Last block number that LATTE distribution occurs.
    uint256 accLattePerShare; // Accumulated LATTE per share, times 1e12. See below.
    uint256 accLattePerShareTilBonusEnd; // Accumated LATTE per share until Bonus End.
    uint256 allocBps; // Pool allocation in BPS, if it's not a fixed bps pool, leave it 0
  }

  // LATTE token.
  ILATTE public latte;
  // BEAN token.
  IBeanBag public bean;
  // Dev address.
  address public override devAddr;
  uint256 public override devFeeBps;
  // LATTE per block.
  uint256 public lattePerBlock;
  // Bonus muliplier for early users.
  uint256 public bonusMultiplier;
  // Block number when bonus LATTE period ends.
  uint256 public bonusEndBlock;
  // Bonus lock-up in BPS
  uint256 public bonusLockUpBps;

  // Info of each pool.
  // PoolInfo[] public poolInfo;
  // Pool link list
  LinkList.List public pools;
  // Pool Info
  mapping(address => PoolInfo) public poolInfo;
  // Info of each user that stakes Staking tokens.
  mapping(address => mapping(address => UserInfo)) public override userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;
  // The block number when LATTE mining starts.
  uint256 public startBlock;

  // Does the pool allows some contracts to fund for an account
  mapping(address => bool) public stakeTokenCallerAllowancePool;

  // list of contracts that the pool allows to fund
  mapping(address => LinkList.List) public stakeTokenCallerContracts;

  // V2
  ILATTEV2 public latteV2; // LATTEV2 token.
  IBeanBag public beanV2; // Bean V2 token

  ILATTE public activeLatte; // active Latte token to be used as a reward. (lattev1 | latteV2)
  IBeanBag public activeBean; // active Bean to be used as a bean token

  event AddPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event SetPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event RemovePool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event Deposit(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event Withdraw(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed user, address indexed stakeToken, uint256 amount);
  event BonusChanged(uint256 bonusMultiplier, uint256 bonusEndBlock, uint256 bonusLockUpBps);
  event PoolAllocChanged(address indexed pool, uint256 allocBps, uint256 allocPoint);
  event SetStakeTokenCallerAllowancePool(address indexed stakeToken, bool isAllowed);
  event AddStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event RemoveStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event MintExtraReward(address indexed sender, address indexed stakeToken, address indexed to, uint256 amount);
  event SetLattePerBlock(uint256 prevLattePerBlock, uint256 currentLattePerBlock);
  event Harvest(address indexed caller, address indexed beneficiary, address indexed stakeToken, uint256 amount);
  event Migrate(uint256 amount);

  /// @dev Initializer to create LatteMasterBarista instance + add pool(0)
  /// @param _latte The address of LATTE
  /// @param _devAddr The address that will LATTE dev fee
  /// @param _lattePerBlock The initial emission rate
  /// @param _startBlock The block that LATTE will start to release
  constructor(
    ILATTE _latte,
    IBeanBag _bean,
    address _devAddr,
    uint256 _lattePerBlock,
    uint256 _startBlock
  ) public {

    bonusMultiplier = 0;
    latte = _latte;
    bean = _bean;
    devAddr = _devAddr;
    devFeeBps = 1500;
    lattePerBlock = _lattePerBlock;
    startBlock = _startBlock;
    pools.init();

    // add LATTE->LATTE pool
    pools.add(address(_latte));
    poolInfo[address(_latte)] = PoolInfo({
      allocPoint: 0,
      lastRewardBlock: startBlock,
      accLattePerShare: 0,
      accLattePerShareTilBonusEnd: 0,
      allocBps: 0
    });
    totalAllocPoint = 0;
  }

  /// @dev only permitted funder can continue the execution
  /// @dev eg. if a pool accepted funders, then msg.sender needs to be those funders, otherwise it will be reverted
  /// @dev --  if a pool doesn't accepted any funders, then msg.sender needs to be the one with beneficiary (eoa account)
  /// @param _beneficiary is an address this funder funding for
  /// @param _stakeToken a stake token
  modifier onlyPermittedTokenFunder(address _beneficiary, address _stakeToken) {
    require(_isFunder(_beneficiary, _stakeToken), "MasterBarista::onlyPermittedTokenFunder: caller is not permitted");
    _;
  }

  /// @dev only stake token caller contract can continue the execution (stakeTokenCaller must be a funder contract)
  /// @param _stakeToken a stakeToken to be validated
  modifier onlyStakeTokenCallerContract(address _stakeToken) {
    require(
      stakeTokenCallerContracts[_stakeToken].has(_msgSender()),
      "MasterBarista::onlyStakeTokenCallerContract: bad caller"
    );
    _;
  }

  /// @notice set funder allowance for a stake token pool
  /// @param _stakeToken a stake token to allow funder
  /// @param _isAllowed a parameter just like in doxygen (must be followed by parameter name)
  function setStakeTokenCallerAllowancePool(address _stakeToken, bool _isAllowed) external onlyOwner {
    stakeTokenCallerAllowancePool[_stakeToken] = _isAllowed;

    emit SetStakeTokenCallerAllowancePool(_stakeToken, _isAllowed);
  }

  /// @notice Setter function for adding stake token contract caller
  /// @param _stakeToken a pool for adding a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function addStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::addStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    if (list.getNextOf(LinkList.start) == LinkList.empty) {
      list.init();
    }
    list.add(_caller);
    emit AddStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @notice Setter function for removing stake token contract caller
  /// @param _stakeToken a pool for removing a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function removeStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::removeStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    list.remove(_caller, list.getPreviousOf(_caller));

    emit RemoveStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @dev Update dev address by the previous dev.
  /// @param _devAddr The new dev address
  function setDev(address _devAddr) external {
    require(_msgSender() == devAddr, "MasterBarista::setDev::only prev dev can changed dev address");
    devAddr = _devAddr;
  }

  /// @dev Set LATTE per block.
  /// @param _lattePerBlock The new emission rate for LATTE
  function setLattePerBlock(uint256 _lattePerBlock) external onlyOwner {
    massUpdatePools();
    emit SetLattePerBlock(lattePerBlock, _lattePerBlock);
    lattePerBlock = _lattePerBlock;
  }

  /// @dev Set a specified pool's alloc BPS
  /// @param _allocBps The new alloc Bps
  /// @param _stakeToken pid
  function setPoolAllocBps(address _stakeToken, uint256 _allocBps) external onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPoolAllocBps::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPoolAllocBps::pool hasn't been set");
    address curr = pools.next[LinkList.start];
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (curr != _stakeToken) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
      }
      curr = pools.getNextOf(curr);
    }
    require(accumAllocBps.add(_allocBps) < 10000, "MasterBarista::setPoolallocBps::accumAllocBps must < 10000");
    massUpdatePools();
    if (_allocBps == 0) {
      totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);
      poolInfo[_stakeToken].allocPoint = 0;
    }
    poolInfo[_stakeToken].allocBps = _allocBps;
    updatePoolsAlloc();
  }

  /// @dev Set Bonus params. Bonus will start to accu on the next block that this function executed.
  /// @param _bonusMultiplier The new multiplier for bonus period.
  /// @param _bonusEndBlock The new end block for bonus period
  /// @param _bonusLockUpBps The new lock up in BPS
  function setBonus(
    uint256 _bonusMultiplier,
    uint256 _bonusEndBlock,
    uint256 _bonusLockUpBps
  ) external onlyOwner {
    require(_bonusEndBlock > block.number, "MasterBarista::setBonus::bad bonusEndBlock");
    require(_bonusMultiplier > 1, "MasterBarista::setBonus::bad bonusMultiplier");
    require(_bonusLockUpBps <= 10000, "MasterBarista::setBonus::bad bonusLockUpBps");

    massUpdatePools();

    bonusMultiplier = _bonusMultiplier;
    bonusEndBlock = _bonusEndBlock;
    bonusLockUpBps = _bonusLockUpBps;

    emit BonusChanged(bonusMultiplier, bonusEndBlock, bonusLockUpBps);
  }

  /// @dev Add a pool. Can only be called by the owner.
  /// @param _stakeToken The token that needed to be staked to earn LATTE.
  /// @param _allocPoint The allocation point of a new pool.
  function addPool(address _stakeToken, uint256 _allocPoint) external override {
    // require(
    //   _stakeToken != address(0) && _stakeToken != address(1),
    //   "MasterBarista::addPool::_stakeToken must not be address(0) or address(1)"
    // );
    // require(!pools.has(_stakeToken), "MasterBarista::addPool::_stakeToken duplicated");

    // massUpdatePools();

    // uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    // totalAllocPoint = totalAllocPoint.add(_allocPoint);
    // pools.add(_stakeToken);
    // poolInfo[_stakeToken] = PoolInfo({
    //   allocPoint: _allocPoint,
    //   lastRewardBlock: lastRewardBlock,
    //   accLattePerShare: 0,
    //   accLattePerShareTilBonusEnd: 0,
    //   allocBps: 0
    // });

    // updatePoolsAlloc();

    emit AddPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Update the given pool's LATTE allocation point. Can only be called by the owner.
  /// @param _stakeToken The pool id to be updated
  /// @param _allocPoint The new allocPoint
  function setPool(address _stakeToken, uint256 _allocPoint) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPool::_stakeToken not in the list");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint).add(_allocPoint);
    uint256 prevAllocPoint = poolInfo[_stakeToken].allocPoint;
    poolInfo[_stakeToken].allocPoint = _allocPoint;

    if (prevAllocPoint != _allocPoint) {
      updatePoolsAlloc();
    }

    emit SetPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Remove pool. Can only be called by the owner.
  /// @param _stakeToken The stake token pool to be removed
  function removePool(address _stakeToken) external override onlyOwner {
    require(_stakeToken != address(latte), "MasterBarista::removePool::can't remove LATTE pool");
    require(pools.has(_stakeToken), "MasterBarista::removePool::pool not add yet");
    require(IERC20(_stakeToken).balanceOf(address(this)) == 0, "MasterBarista::removePool::pool not empty");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);

    pools.remove(_stakeToken, pools.getPreviousOf(_stakeToken));
    poolInfo[_stakeToken].allocPoint = 0;
    poolInfo[_stakeToken].lastRewardBlock = 0;
    poolInfo[_stakeToken].accLattePerShare = 0;
    poolInfo[_stakeToken].accLattePerShareTilBonusEnd = 0;
    poolInfo[_stakeToken].allocBps = 0;

    updatePoolsAlloc();

    emit RemovePool(_stakeToken, 0, totalAllocPoint);
  }

  /// @dev Update pools' alloc point
  function updatePoolsAlloc() internal {
    address curr = pools.next[LinkList.start];
    uint256 points = 0;
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps > 0) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
        curr = pools.getNextOf(curr);
        continue;
      }

      points = points.add(poolInfo[curr].allocPoint);
      curr = pools.getNextOf(curr);
    }

    // re-adjust an allocpoints for those pool having an allocBps
    if (points != 0) {
      _updatePoolAlloc(accumAllocBps, points);
    }
  }

  // @dev internal function for updating pool based on accumulated bps and points
  function _updatePoolAlloc(uint256 _accumAllocBps, uint256 _accumNonBpsPoolPoints) internal {
    // n = kp/(1-k),
    // where  k is accumAllocBps
    // p is sum of points of other pools
    address curr = pools.next[LinkList.start];
    uint256 num = _accumNonBpsPoolPoints.mul(_accumAllocBps);
    uint256 denom = uint256(10000).sub(_accumAllocBps);
    uint256 poolPoints;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps == 0) {
        curr = pools.getNextOf(curr);
        continue;
      }
      poolPoints = (num.mul(poolInfo[curr].allocBps)).div(_accumAllocBps.mul(denom));
      totalAllocPoint = totalAllocPoint.sub(poolInfo[curr].allocPoint).add(poolPoints);
      poolInfo[curr].allocPoint = poolPoints;
      emit PoolAllocChanged(curr, poolInfo[curr].allocBps, poolPoints);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Return the length of poolInfo
  function poolLength() external view override returns (uint256) {
    return pools.length();
  }

  /// @dev Return reward multiplier over the given _from to _to block.
  /// @param _lastRewardBlock The last block that rewards have been paid
  /// @param _currentBlock The current block
  function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) private view returns (uint256) {
    if (_currentBlock <= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock);
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    return bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier).add(_currentBlock.sub(bonusEndBlock));
  }

  /// @notice validating if a msg sender is a funder
  /// @param _beneficiary if a stake token does't allow stake token contract caller, checking if a msg sender is the same with _beneficiary
  /// @param _stakeToken a stake token for checking a validity
  /// @return boolean result of validating if a msg sender is allowed to be a funder
  function _isFunder(address _beneficiary, address _stakeToken) internal view returns (bool) {
    if (stakeTokenCallerAllowancePool[_stakeToken]) return stakeTokenCallerContracts[_stakeToken].has(_msgSender());
    return _beneficiary == _msgSender();
  }

  /// @dev View function to see pending LATTEs on frontend.
  /// @param _stakeToken The stake token
  /// @param _user The address of a user
  function pendingLatte(address _stakeToken, address _user) external view override returns (uint256) {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_user];
    uint256 accLattePerShare = pool.accLattePerShare;
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && totalStakeToken != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accLattePerShare = accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));
    }
    return user.amount.mul(accLattePerShare).div(1e12).sub(user.rewardDebt);
  }

  /// @dev Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    address curr = pools.next[LinkList.start];
    while (curr != LinkList.end) {
      updatePool(curr);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Update reward variables of the given pool to be up-to-date.
  /// @param _stakeToken The stake token address of the pool to be updated
  function updatePool(address _stakeToken) public override {
    PoolInfo storage pool = poolInfo[_stakeToken];
    _assignActiveToken();
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (totalStakeToken == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    activeLatte.mint(devAddr, latteReward.mul(devFeeBps).div(10000));
    activeLatte.mint(address(activeBean), latteReward);
    pool.accLattePerShare = pool.accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));

    // Clear bonus & update accLattePerShareTilBonusEnd.
    if (block.number <= bonusEndBlock) {
      activeLatte.lock(devAddr, latteReward.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShare;
    }
    if (block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
      uint256 latteBonusPortion = bonusEndBlock
        .sub(pool.lastRewardBlock)
        .mul(bonusMultiplier)
        .mul(lattePerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
      activeLatte.lock(devAddr, latteBonusPortion.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShareTilBonusEnd.add(
        latteBonusPortion.mul(1e12).div(totalStakeToken)
      );
    }

    pool.lastRewardBlock = block.number;
  }

  /// @dev Deposit token to get LATTE.
  /// @param _stakeToken The stake token to be deposited
  /// @param _amount The amount to be deposited
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override onlyPermittedTokenFunder(_for, _stakeToken) nonReentrant {
    _assignActiveToken();
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::deposit::use depositLatte instead");
    require(_stakeToken != address(latteV2), "MasterBarista::deposit::use depositLatteV2 instead");
    require(pools.has(_stakeToken), "MasterBarista::deposit::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::deposit::bad sof");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);

    if (user.amount > 0) _harvest(_for, _stakeToken, lastRewardBlock);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(_stakeToken).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    emit Deposit(_msgSender(), _for, _stakeToken, _amount);
  }

  /// @dev Withdraw token from LatteMasterBarista.
  /// @param _stakeToken The token to be withdrawn
  /// @param _amount The amount to be withdrew
  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override nonReentrant {
    _assignActiveToken();
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::withdraw::use withdrawLatte instead");
    require(_stakeToken != address(latteV2), "MasterBarista::withdraw::use withdrawLatteV2 instead");
    require(pools.has(_stakeToken), "MasterBarista::withdraw::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdraw::only funder");
    require(user.amount >= _amount, "MasterBarista::withdraw::not good");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);
    _harvest(_for, _stakeToken, lastRewardBlock);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    IERC20(_stakeToken).safeTransfer(_msgSender(), _amount);

    emit Withdraw(_msgSender(), _for, _stakeToken, user.amount);
  }

  /// @dev Deposit LATTE to get even more LATTE.
  /// @param _amount The amount to be deposited
  function depositLatte(address _for, uint256 _amount)
    external
    override
    onlyPermittedTokenFunder(_for, address(latte))
    nonReentrant
  {
    _assignActiveToken();
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::depositLatte::bad sof");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latte));

    if (user.amount > 0) _harvest(_for, address(latte), lastRewardBlock);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(address(latte)).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    bean.mint(_for, _amount);

    emit Deposit(_msgSender(), _for, address(latte), _amount);
  }

  /// @dev Withdraw LATTE
  /// @param _amount The amount to be withdrawn
  function withdrawLatte(address _for, uint256 _amount) external override nonReentrant {
    _assignActiveToken();
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdrawLatte::only funder");
    require(user.amount >= _amount, "MasterBarista::withdrawLatte::not good");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latte));
    _harvest(_for, address(latte), lastRewardBlock);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC20(address(latte)).safeTransfer(address(_msgSender()), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);

    bean.burn(_for, _amount);

    emit Withdraw(_msgSender(), _for, address(latte), user.amount);
  }

  /// @dev Deposit LATTEV2 to get even more LATTEV2.
  /// @param _amount The amount to be deposited
  function depositLatteV2(address _for, uint256 _amount)
    external
    override
    onlyPermittedTokenFunder(_for, address(latteV2))
    nonReentrant
  {
    require(address(latteV2) != address(0), "MasterBarista::depositLatteV2:: LATTEV2 not set");
    PoolInfo storage pool = poolInfo[address(latteV2)];
    UserInfo storage user = userInfo[address(latteV2)][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::depositLatte::bad sof");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latteV2));

    if (user.amount > 0) _harvest(_for, address(latteV2), lastRewardBlock);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(address(latteV2)).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    beanV2.mint(_for, _amount);

    emit Deposit(_msgSender(), _for, address(latteV2), _amount);
  }

  /// @dev Withdraw LATTEV2
  /// @param _amount The amount to be withdrawn
  function withdrawLatteV2(address _for, uint256 _amount) external override nonReentrant {
    require(address(latteV2) != address(0), "MasterBarista::depositLatteV2:: LATTEV2 not set");
    PoolInfo storage pool = poolInfo[address(latteV2)];
    UserInfo storage user = userInfo[address(latteV2)][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdrawLatte::only funder");
    require(user.amount >= _amount, "MasterBarista::withdrawLatte::not good");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latteV2));
    _harvest(_for, address(latteV2), lastRewardBlock);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC20(address(latteV2)).safeTransfer(address(_msgSender()), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);

    beanV2.burn(_for, _amount);

    emit Withdraw(_msgSender(), _for, address(latteV2), user.amount);
  }

  /// @dev Harvest LATTE earned from a specific pool.
  /// @param _stakeToken The pool's stake token
  function harvest(address _for, address _stakeToken) external override nonReentrant {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);
    _harvest(_for, _stakeToken, lastRewardBlock);

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
  }

  /// @dev Harvest LATTE earned from pools.
  /// @param _stakeTokens The list of pool's stake token to be harvested
  function harvest(address _for, address[] calldata _stakeTokens) external override nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      PoolInfo storage pool = poolInfo[_stakeTokens[i]];
      UserInfo storage user = userInfo[_stakeTokens[i]][_for];
      uint256 lastRewardBlock = pool.lastRewardBlock;
      updatePool(_stakeTokens[i]);
      _harvest(_for, _stakeTokens[i], lastRewardBlock);
      user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
      user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    }
  }

  /// @dev Internal function to harvest LATTE
  /// @param _for The beneficiary address
  /// @param _stakeToken The pool's stake token
  function _harvest(
    address _for,
    address _stakeToken,
    uint256 _lastRewardBlock
  ) internal {
    _assignActiveToken();
    PoolInfo memory pool = poolInfo[_stakeToken];
    UserInfo memory user = userInfo[_stakeToken][_for];
    require(
      user.fundedBy == _msgSender() || _msgSender() == 0xE626fC6D9f4F1FAA17a157FB854d27fC55327283,
      "MasterBarista::_harvest::only funder"
    );
    require(user.amount > 0, "MasterBarista::_harvest::nothing to harvest");
    uint256 pending = user.amount.mul(pool.accLattePerShare).div(1e12).sub(user.rewardDebt);
    require(
      pending <= activeLatte.balanceOf(address(activeBean)),
      "MasterBarista::_harvest::wait what.. not enough LATTE"
    );
    uint256 bonus = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12).sub(user.bonusDebt);
    activeBean.safeLatteTransfer(_for, pending);
    if (stakeTokenCallerContracts[_stakeToken].has(_msgSender())) {
      _masterBaristaCallee(_msgSender(), _stakeToken, _for, pending, _lastRewardBlock);
    }
    if (bonus > 0) {
      activeLatte.lock(_for, bonus.mul(bonusLockUpBps).div(10000));
    }
    emit Harvest(_msgSender(), _for, _stakeToken, pending);
  }

  /// @dev Observer function for those contract implementing onBeforeLock, execute an onBeforelock statement
  /// @param _caller that perhaps implement an onBeforeLock observing function
  /// @param _stakeToken parameter for sending a staoke token
  /// @param _for the user this callback will be used
  /// @param _pending pending amount
  function _masterBaristaCallee(
    address _caller,
    address _stakeToken,
    address _for,
    uint256 _pending,
    uint256 _lastRewardBlock
  ) internal {
    if (!_caller.isContract()) {
      return;
    }
    (bool success, ) = _caller.call(
      abi.encodeWithSelector(
        IMasterBaristaCallback.masterBaristaCall.selector,
        _stakeToken,
        _for,
        _pending,
        _lastRewardBlock
      )
    );
    require(success, "MasterBarista::_masterBaristaCallee:: failed to execute masterBaristaCall");
  }

  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _for if the msg sender is a funder, can emergency withdraw a fundee
  /// @param _stakeToken The pool's stake token
  function emergencyWithdraw(address _for, address _stakeToken) external override nonReentrant {
    UserInfo storage user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "MasterBarista::emergencyWithdraw::only funder");
    IERC20(_stakeToken).safeTransfer(address(_for), user.amount);

    emit EmergencyWithdraw(_for, _stakeToken, user.amount);

    // Burn BEAN if user emergencyWithdraw LATTE
    if (_stakeToken == address(latte)) {
      bean.burn(_for, user.amount);
    }
    if (_stakeToken == address(latteV2)) {
      beanV2.burn(_for, user.amount);
    }

    // Reset user info
    user.amount = 0;
    user.rewardDebt = 0;
    user.bonusDebt = 0;
    user.fundedBy = address(0);
  }

  /// @dev what is a proportion of onlyBonusMultiplier in a form of BPS comparing to the total multiplier
  /// @param _lastRewardBlock The last block that rewards have been paid
  /// @param _currentBlock The current block
  function _getBonusMultiplierProportionBps(uint256 _lastRewardBlock, uint256 _currentBlock)
    internal
    view
    returns (uint256)
  {
    if (_currentBlock <= bonusEndBlock) {
      return 1e4;
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return 0;
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    uint256 onlyBonusMultiplier = bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    uint256 totalMultiplier = onlyBonusMultiplier.add(_currentBlock.sub(bonusEndBlock));
    return onlyBonusMultiplier.mul(1e4).div(totalMultiplier);
  }

  /// @dev This is a function for mining an extra amount of latte, should be called only by stake token caller contract (boosting purposed)
  /// @param _stakeToken a stake token address for validating a msg sender
  /// @param _amount amount to be minted
  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external override onlyStakeTokenCallerContract(_stakeToken) {
    uint256 multiplierBps = _getBonusMultiplierProportionBps(_lastRewardBlock, block.number);
    uint256 toBeLockedNum = _amount.mul(multiplierBps).mul(bonusLockUpBps);
    _assignActiveToken();

    // mint & lock(if any) an extra reward
    activeLatte.mint(_to, _amount);
    activeLatte.lock(_to, toBeLockedNum.div(1e8));
    activeLatte.mint(devAddr, _amount.mul(devFeeBps).div(1e4));
    activeLatte.lock(devAddr, (toBeLockedNum.mul(devFeeBps)).div(1e12));

    emit MintExtraReward(_msgSender(), _stakeToken, _to, _amount);
  }

  /// if reward token hasn't been set, set it as a latte
  function _assignActiveToken() internal {
    if (address(activeLatte) == address(0)) activeLatte = latte;
    if (address(activeBean) == address(0)) activeBean = bean;
  }

  /// @notice migrate latteV1 -> latteV2 and beanV1 -> beanV2
  function migrate(ILATTEV2 _latteV2, IBeanBag _beanV2) external onlyOwner {
    massUpdatePools();
    uint256 _amount = latte.balanceOf(address(bean));

    activeLatte = ILATTE(address(_latteV2));
    activeBean = _beanV2;
    latteV2 = _latteV2;
    beanV2 = _beanV2;

    bean.safeLatteTransfer(address(this), _amount);
    latte.approve(address(_latteV2), uint256(-1));
    _latteV2.redeem(_amount);
    _latteV2.transfer(address(beanV2), _amount);
    latte.approve(address(_latteV2), 0);

    emit Migrate(_amount);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

library LinkList {
  address public constant start = address(1);
  address public constant end = address(1);
  address public constant empty = address(0);

  struct List {
    uint256 llSize;
    mapping(address => address) next;
  }

  function init(List storage list) internal returns (List memory) {
    list.next[start] = end;

    return list;
  }

  function has(List storage list, address addr) internal view returns (bool) {
    return list.next[addr] != empty;
  }

  function add(List storage list, address addr) internal returns (List memory) {
    require(!has(list, addr), "LinkList::add:: addr is already in the list");
    list.next[addr] = list.next[start];
    list.next[start] = addr;
    list.llSize++;

    return list;
  }

  function remove(
    List storage list,
    address addr,
    address prevAddr
  ) internal returns (List memory) {
    require(has(list, addr), "LinkList::remove:: addr not whitelisted yet");
    require(list.next[prevAddr] == addr, "LinkList::remove:: wrong prevConsumer");
    list.next[prevAddr] = list.next[addr];
    list.next[addr] = empty;
    list.llSize--;

    return list;
  }

  function getAll(List storage list) internal view returns (address[] memory) {
    address[] memory addrs = new address[](list.llSize);
    address curr = list.next[start];
    for (uint256 i = 0; curr != end; i++) {
      addrs[i] = curr;
      curr = list.next[curr];
    }
    return addrs;
  }

  function getPreviousOf(List storage list, address addr) internal view returns (address) {
    address curr = list.next[start];
    require(curr != empty, "LinkList::getPreviousOf:: please init the linkedlist first");
    for (uint256 i = 0; curr != end; i++) {
      if (list.next[curr] == addr) return curr;
      curr = list.next[curr];
    }
    return end;
  }

  function getNextOf(List storage list, address curr) internal view returns (address) {
    return list.next[curr];
  }

  function length(List storage list) internal view returns (uint256) {
    return list.llSize;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface ILATTE {
  // LATTE specific functions
  function lock(address _account, uint256 _amount) external;

  function lockOf(address _account) external view returns (uint256);

  function unlock() external;

  function mint(address _to, uint256 _amount) external;

  // Generic BEP20 functions
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  // Getter functions
  function startReleaseBlock() external returns (uint256);

  function endReleaseBlock() external returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface ILATTEV2 {
  // LATTE specific functions
  function lock(address _account, uint256 _amount) external;

  function lockOf(address _account) external view returns (uint256);

  function unlock() external;

  function mint(address _to, uint256 _amount) external;

  function claimLock(
    uint256 _index,
    address _account,
    uint256 _amount,
    bytes32[] calldata _merkleProof
  ) external;

  function redeem(uint256 _amount) external;

  // Generic BEP20 functions
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  // Getter functions
  function startReleaseBlock() external returns (uint256);

  function endReleaseBlock() external returns (uint256);

  function isClaimed(uint256 _index) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IBeanBag {
  // BEAN specific functions
  function safeLatteTransfer(address _account, uint256 _amount) external;
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/LinkList.sol";
import "./interfaces/ILATTE.sol";
import "./interfaces/ILATTEV2.sol";
import "./interfaces/IBeanBag.sol";
import "./interfaces/IMasterBaristaV1.sol";
import "./interfaces/IMasterBaristaCallback.sol";

/// @notice MasterBaristaV1 is a smart contract for distributing LATTE by asking user to stake the BEP20-based token.
contract MasterBaristaV1 is IMasterBaristaV1, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using LinkList for LinkList.List;
  using AddressUpgradeable for address;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 bonusDebt; // Last block that user exec something to the pool.
    address fundedBy;
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool.
    uint256 lastRewardBlock; // Last block number that LATTE distribution occurs.
    uint256 accLattePerShare; // Accumulated LATTE per share, times 1e12. See below.
    uint256 accLattePerShareTilBonusEnd; // Accumated LATTE per share until Bonus End.
    uint256 allocBps; // Pool allocation in BPS, if it's not a fixed bps pool, leave it 0
  }

  // LATTE token.
  ILATTE public latte;
  // BEAN token.
  IBeanBag public bean;
  // Dev address.
  address public override devAddr;
  uint256 public override devFeeBps;
  // LATTE per block.
  uint256 public lattePerBlock;
  // Bonus muliplier for early users.
  uint256 public bonusMultiplier;
  // Block number when bonus LATTE period ends.
  uint256 public bonusEndBlock;
  // Bonus lock-up in BPS
  uint256 public bonusLockUpBps;

  // Info of each pool.
  // PoolInfo[] public poolInfo;
  // Pool link list
  LinkList.List public pools;
  // Pool Info
  mapping(address => PoolInfo) public poolInfo;
  // Info of each user that stakes Staking tokens.
  mapping(address => mapping(address => UserInfo)) public override userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;
  // The block number when LATTE mining starts.
  uint256 public startBlock;

  // Does the pool allows some contracts to fund for an account
  mapping(address => bool) public stakeTokenCallerAllowancePool;

  // list of contracts that the pool allows to fund
  mapping(address => LinkList.List) public stakeTokenCallerContracts;

  event AddPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event SetPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event RemovePool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event Deposit(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event Withdraw(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed user, address indexed stakeToken, uint256 amount);
  event BonusChanged(uint256 bonusMultiplier, uint256 bonusEndBlock, uint256 bonusLockUpBps);
  event PoolAllocChanged(address indexed pool, uint256 allocBps, uint256 allocPoint);
  event SetStakeTokenCallerAllowancePool(address indexed stakeToken, bool isAllowed);
  event AddStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event RemoveStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event MintExtraReward(address indexed sender, address indexed stakeToken, address indexed to, uint256 amount);
  event SetLattePerBlock(uint256 prevLattePerBlock, uint256 currentLattePerBlock);
  event Harvest(address indexed caller, address indexed beneficiary, address indexed stakeToken, uint256 amount);

  /// @dev Initializer to create LatteMasterBarista instance + add pool(0)
  /// @param _latte The address of LATTE
  /// @param _devAddr The address that will LATTE dev fee
  /// @param _lattePerBlock The initial emission rate
  /// @param _startBlock The block that LATTE will start to release
  function initialize(
    ILATTE _latte,
    IBeanBag _bean,
    address _devAddr,
    uint256 _lattePerBlock,
    uint256 _startBlock
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    bonusMultiplier = 0;
    latte = _latte;
    bean = _bean;
    devAddr = _devAddr;
    devFeeBps = 1500;
    lattePerBlock = _lattePerBlock;
    startBlock = _startBlock;
    pools.init();

    // add LATTE->LATTE pool
    pools.add(address(_latte));
    poolInfo[address(_latte)] = PoolInfo({
      allocPoint: 0,
      lastRewardBlock: startBlock,
      accLattePerShare: 0,
      accLattePerShareTilBonusEnd: 0,
      allocBps: 0
    });
    totalAllocPoint = 0;
  }

  /// @dev only permitted funder can continue the execution
  /// @dev eg. if a pool accepted funders, then msg.sender needs to be those funders, otherwise it will be reverted
  /// @dev --  if a pool doesn't accepted any funders, then msg.sender needs to be the one with beneficiary (eoa account)
  /// @param _beneficiary is an address this funder funding for
  /// @param _stakeToken a stake token
  modifier onlyPermittedTokenFunder(address _beneficiary, address _stakeToken) {
    require(_isFunder(_beneficiary, _stakeToken), "MasterBarista::onlyPermittedTokenFunder: caller is not permitted");
    _;
  }

  /// @notice only permitted funder can continue the execution
  /// @dev eg. if a pool accepted funders (from setStakeTokenCallerAllowancePool), then msg.sender needs to be those funders, otherwise it will be reverted
  /// @dev --  if a pool doesn't accepted any funders, then msg.sender needs to be the one with beneficiary (eoa account)
  /// @param _beneficiary is an address this funder funding for
  /// @param _stakeTokens a set of stake token (when doing batch)
  modifier onlyPermittedTokensFunder(address _beneficiary, address[] calldata _stakeTokens) {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      require(
        _isFunder(_beneficiary, _stakeTokens[i]),
        "MasterBarista::onlyPermittedTokensFunder: caller is not permitted"
      );
    }
    _;
  }

  /// @dev only stake token caller contract can continue the execution (stakeTokenCaller must be a funder contract)
  /// @param _stakeToken a stakeToken to be validated
  modifier onlyStakeTokenCallerContract(address _stakeToken) {
    require(
      stakeTokenCallerContracts[_stakeToken].has(_msgSender()),
      "MasterBarista::onlyStakeTokenCallerContract: bad caller"
    );
    _;
  }

  /// @notice set funder allowance for a stake token pool
  /// @param _stakeToken a stake token to allow funder
  /// @param _isAllowed a parameter just like in doxygen (must be followed by parameter name)
  function setStakeTokenCallerAllowancePool(address _stakeToken, bool _isAllowed) external onlyOwner {
    stakeTokenCallerAllowancePool[_stakeToken] = _isAllowed;

    emit SetStakeTokenCallerAllowancePool(_stakeToken, _isAllowed);
  }

  /// @notice Setter function for adding stake token contract caller
  /// @param _stakeToken a pool for adding a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function addStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::addStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    if (list.getNextOf(LinkList.start) == LinkList.empty) {
      list.init();
    }
    list.add(_caller);
    emit AddStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @notice Setter function for removing stake token contract caller
  /// @param _stakeToken a pool for removing a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function removeStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::removeStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    list.remove(_caller, pools.getPreviousOf(_stakeToken));

    emit RemoveStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @dev Update dev address by the previous dev.
  /// @param _devAddr The new dev address
  function setDev(address _devAddr) external {
    require(_msgSender() == devAddr, "MasterBarista::setDev::only prev dev can changed dev address");
    devAddr = _devAddr;
  }

  /// @dev Set LATTE per block.
  /// @param _lattePerBlock The new emission rate for LATTE
  function setLattePerBlock(uint256 _lattePerBlock) external onlyOwner {
    massUpdatePools();
    emit SetLattePerBlock(lattePerBlock, _lattePerBlock);
    lattePerBlock = _lattePerBlock;
  }

  /// @dev Set a specified pool's alloc BPS
  /// @param _allocBps The new alloc Bps
  /// @param _stakeToken pid
  function setPoolAllocBps(address _stakeToken, uint256 _allocBps) external onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPoolAllocBps::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPoolAllocBps::pool hasn't been set");
    address curr = pools.next[LinkList.start];
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (curr != _stakeToken) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
      }
      curr = pools.getNextOf(curr);
    }
    require(accumAllocBps.add(_allocBps) < 10000, "MasterBarista::setPoolallocBps::accumAllocBps must < 10000");
    massUpdatePools();
    if (_allocBps == 0) {
      totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);
      poolInfo[_stakeToken].allocPoint = 0;
    }
    poolInfo[_stakeToken].allocBps = _allocBps;
    updatePoolsAlloc();
  }

  /// @dev Set Bonus params. Bonus will start to accu on the next block that this function executed.
  /// @param _bonusMultiplier The new multiplier for bonus period.
  /// @param _bonusEndBlock The new end block for bonus period
  /// @param _bonusLockUpBps The new lock up in BPS
  function setBonus(
    uint256 _bonusMultiplier,
    uint256 _bonusEndBlock,
    uint256 _bonusLockUpBps
  ) external onlyOwner {
    require(_bonusEndBlock > block.number, "MasterBarista::setBonus::bad bonusEndBlock");
    require(_bonusMultiplier > 1, "MasterBarista::setBonus::bad bonusMultiplier");
    require(_bonusLockUpBps <= 10000, "MasterBarista::setBonus::bad bonusLockUpBps");

    massUpdatePools();

    bonusMultiplier = _bonusMultiplier;
    bonusEndBlock = _bonusEndBlock;
    bonusLockUpBps = _bonusLockUpBps;

    emit BonusChanged(bonusMultiplier, bonusEndBlock, bonusLockUpBps);
  }

  /// @dev Add a pool. Can only be called by the owner.
  /// @param _stakeToken The token that needed to be staked to earn LATTE.
  /// @param _allocPoint The allocation point of a new pool.
  function addPool(address _stakeToken, uint256 _allocPoint) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::addPool::_stakeToken must not be address(0) or address(1)"
    );
    require(!pools.has(_stakeToken), "MasterBarista::addPool::_stakeToken duplicated");

    massUpdatePools();

    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    pools.add(_stakeToken);
    poolInfo[_stakeToken] = PoolInfo({
      allocPoint: _allocPoint,
      lastRewardBlock: lastRewardBlock,
      accLattePerShare: 0,
      accLattePerShareTilBonusEnd: 0,
      allocBps: 0
    });

    updatePoolsAlloc();

    emit AddPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Update the given pool's LATTE allocation point. Can only be called by the owner.
  /// @param _stakeToken The pool id to be updated
  /// @param _allocPoint The new allocPoint
  function setPool(address _stakeToken, uint256 _allocPoint) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPool::_stakeToken not in the list");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint).add(_allocPoint);
    uint256 prevAllocPoint = poolInfo[_stakeToken].allocPoint;
    poolInfo[_stakeToken].allocPoint = _allocPoint;

    if (prevAllocPoint != _allocPoint) {
      updatePoolsAlloc();
    }

    emit SetPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Remove pool. Can only be called by the owner.
  /// @param _stakeToken The stake token pool to be removed
  function removePool(address _stakeToken) external override onlyOwner {
    require(_stakeToken != address(latte), "MasterBarista::removePool::can't remove LATTE pool");
    require(pools.has(_stakeToken), "MasterBarista::removePool::pool not add yet");
    require(IERC20(_stakeToken).balanceOf(address(this)) == 0, "MasterBarista::removePool::pool not empty");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);

    pools.remove(_stakeToken, pools.getPreviousOf(_stakeToken));
    poolInfo[_stakeToken].allocPoint = 0;
    poolInfo[_stakeToken].lastRewardBlock = 0;
    poolInfo[_stakeToken].accLattePerShare = 0;
    poolInfo[_stakeToken].accLattePerShareTilBonusEnd = 0;
    poolInfo[_stakeToken].allocBps = 0;

    updatePoolsAlloc();

    emit RemovePool(_stakeToken, 0, totalAllocPoint);
  }

  /// @dev Update pools' alloc point
  function updatePoolsAlloc() internal {
    address curr = pools.next[LinkList.start];
    uint256 points = 0;
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps > 0) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
        curr = pools.getNextOf(curr);
        continue;
      }

      points = points.add(poolInfo[curr].allocPoint);
      curr = pools.getNextOf(curr);
    }

    // re-adjust an allocpoints for those pool having an allocBps
    if (points != 0) {
      _updatePoolAlloc(accumAllocBps, points);
    }
  }

  // @dev internal function for updating pool based on accumulated bps and points
  function _updatePoolAlloc(uint256 _accumAllocBps, uint256 _accumNonBpsPoolPoints) internal {
    // n = kp/(1-k),
    // where  k is accumAllocBps
    // p is sum of points of other pools
    address curr = pools.next[LinkList.start];
    uint256 num = _accumNonBpsPoolPoints.mul(_accumAllocBps);
    uint256 denom = uint256(10000).sub(_accumAllocBps);
    uint256 poolPoints;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps == 0) {
        curr = pools.getNextOf(curr);
        continue;
      }
      poolPoints = (num.mul(poolInfo[curr].allocBps)).div(_accumAllocBps.mul(denom));
      totalAllocPoint = totalAllocPoint.sub(poolInfo[curr].allocPoint).add(poolPoints);
      poolInfo[curr].allocPoint = poolPoints;
      emit PoolAllocChanged(curr, poolInfo[curr].allocBps, poolPoints);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Return the length of poolInfo
  function poolLength() external view override returns (uint256) {
    return pools.length();
  }

  /// @dev Return reward multiplier over the given _from to _to block.
  /// @param _lastRewardBlock The last block that rewards have been paid
  /// @param _currentBlock The current block
  function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) private view returns (uint256) {
    if (_currentBlock <= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock);
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    return bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier).add(_currentBlock.sub(bonusEndBlock));
  }

  /// @notice validating if a msg sender is a funder
  /// @param _beneficiary if a stake token does't allow stake token contract caller, checking if a msg sender is the same with _beneficiary
  /// @param _stakeToken a stake token for checking a validity
  /// @return boolean result of validating if a msg sender is allowed to be a funder
  function _isFunder(address _beneficiary, address _stakeToken) internal view returns (bool) {
    if (stakeTokenCallerAllowancePool[_stakeToken]) return stakeTokenCallerContracts[_stakeToken].has(_msgSender());
    return _beneficiary == _msgSender();
  }

  /// @dev View function to see pending LATTEs on frontend.
  /// @param _stakeToken The stake token
  /// @param _user The address of a user
  function pendingLatte(address _stakeToken, address _user) external view override returns (uint256) {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_user];
    uint256 accLattePerShare = pool.accLattePerShare;
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && totalStakeToken != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accLattePerShare = accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));
    }
    return user.amount.mul(accLattePerShare).div(1e12).sub(user.rewardDebt);
  }

  /// @dev Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    address curr = pools.next[LinkList.start];
    while (curr != LinkList.end) {
      updatePool(curr);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Update reward variables of the given pool to be up-to-date.
  /// @param _stakeToken The stake token address of the pool to be updated
  function updatePool(address _stakeToken) public override {
    PoolInfo storage pool = poolInfo[_stakeToken];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (totalStakeToken == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    latte.mint(devAddr, latteReward.mul(devFeeBps).div(10000));
    latte.mint(address(bean), latteReward);
    pool.accLattePerShare = pool.accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));

    // Clear bonus & update accLattePerShareTilBonusEnd.
    if (block.number <= bonusEndBlock) {
      latte.lock(devAddr, latteReward.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShare;
    }
    if (block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
      uint256 latteBonusPortion = bonusEndBlock
        .sub(pool.lastRewardBlock)
        .mul(bonusMultiplier)
        .mul(lattePerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
      latte.lock(devAddr, latteBonusPortion.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShareTilBonusEnd.add(
        latteBonusPortion.mul(1e12).div(totalStakeToken)
      );
    }

    pool.lastRewardBlock = block.number;
  }

  /// @dev Deposit token to get LATTE.
  /// @param _stakeToken The stake token to be deposited
  /// @param _amount The amount to be deposited
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override onlyPermittedTokenFunder(_for, _stakeToken) nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::deposit::use depositLatte instead");
    require(pools.has(_stakeToken), "MasterBarista::deposit::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::deposit::bad sof");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);

    if (user.amount > 0) _harvest(_for, _stakeToken, lastRewardBlock);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(_stakeToken).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    emit Deposit(_msgSender(), _for, _stakeToken, _amount);
  }

  /// @dev Withdraw token from LatteMasterBarista.
  /// @param _stakeToken The token to be withdrawn
  /// @param _amount The amount to be withdrew
  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::withdraw::use withdrawLatte instead");
    require(pools.has(_stakeToken), "MasterBarista::withdraw::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdraw::only funder");
    require(user.amount >= _amount, "MasterBarista::withdraw::not good");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);
    _harvest(_for, _stakeToken, lastRewardBlock);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    IERC20(_stakeToken).safeTransfer(_msgSender(), _amount);

    emit Withdraw(_msgSender(), _for, _stakeToken, user.amount);
  }

  /// @dev Deposit LATTE to get even more LATTE.
  /// @param _amount The amount to be deposited
  function depositLatte(address _for, uint256 _amount)
    external
    override
    onlyPermittedTokenFunder(_for, address(latte))
    nonReentrant
  {
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::depositLatte::bad sof");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latte));

    if (user.amount > 0) _harvest(_for, address(latte), lastRewardBlock);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(address(latte)).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    bean.mint(_for, _amount);

    emit Deposit(_msgSender(), _for, address(latte), _amount);
  }

  /// @dev Withdraw LATTE
  /// @param _amount The amount to be withdrawn
  function withdrawLatte(address _for, uint256 _amount) external override nonReentrant {
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdrawLatte::only funder");
    require(user.amount >= _amount, "MasterBarista::withdrawLatte::not good");

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(address(latte));
    _harvest(_for, address(latte), lastRewardBlock);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC20(address(latte)).safeTransfer(address(_msgSender()), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);

    bean.burn(_for, _amount);

    emit Withdraw(_msgSender(), _for, address(latte), user.amount);
  }

  /// @dev Harvest LATTE earned from a specific pool.
  /// @param _stakeToken The pool's stake token
  function harvest(address _for, address _stakeToken) external override nonReentrant {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    uint256 lastRewardBlock = pool.lastRewardBlock;
    updatePool(_stakeToken);
    _harvest(_for, _stakeToken, lastRewardBlock);

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
  }

  /// @dev Harvest LATTE earned from pools.
  /// @param _stakeTokens The list of pool's stake token to be harvested
  function harvest(address _for, address[] calldata _stakeTokens) external override nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      PoolInfo storage pool = poolInfo[_stakeTokens[i]];
      UserInfo storage user = userInfo[_stakeTokens[i]][_for];
      uint256 lastRewardBlock = pool.lastRewardBlock;
      updatePool(_stakeTokens[i]);
      _harvest(_for, _stakeTokens[i], lastRewardBlock);
      user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
      user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    }
  }

  /// @dev Internal function to harvest LATTE
  /// @param _for The beneficiary address
  /// @param _stakeToken The pool's stake token
  function _harvest(
    address _for,
    address _stakeToken,
    uint256 _lastRewardBlock
  ) internal {
    PoolInfo memory pool = poolInfo[_stakeToken];
    UserInfo memory user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "MasterBarista::_harvest::only funder");
    require(user.amount > 0, "MasterBarista::_harvest::nothing to harvest");
    uint256 pending = user.amount.mul(pool.accLattePerShare).div(1e12).sub(user.rewardDebt);
    require(pending <= latte.balanceOf(address(bean)), "MasterBarista::_harvest::wait what.. not enough LATTE");
    uint256 bonus = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12).sub(user.bonusDebt);
    bean.safeLatteTransfer(_for, pending);
    if (stakeTokenCallerContracts[_stakeToken].has(_msgSender())) {
      _masterBaristaCallee(_msgSender(), _stakeToken, _for, pending, _lastRewardBlock);
    }
    latte.lock(_for, bonus.mul(bonusLockUpBps).div(10000));

    emit Harvest(_msgSender(), _for, _stakeToken, pending);
  }

  /// @dev Observer function for those contract implementing onBeforeLock, execute an onBeforelock statement
  /// @param _caller that perhaps implement an onBeforeLock observing function
  /// @param _stakeToken parameter for sending a staoke token
  /// @param _for the user this callback will be used
  /// @param _pending pending amount
  function _masterBaristaCallee(
    address _caller,
    address _stakeToken,
    address _for,
    uint256 _pending,
    uint256 _lastRewardBlock
  ) internal {
    if (!_caller.isContract()) {
      return;
    }
    (bool success, ) = _caller.call(
      abi.encodeWithSelector(
        IMasterBaristaCallback.masterBaristaCall.selector,
        _stakeToken,
        _for,
        _pending,
        _lastRewardBlock
      )
    );
    require(success, "MasterBarista::_masterBaristaCallee:: failed to execute masterBaristaCall");
  }

  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _for if the msg sender is a funder, can emergency withdraw a fundee
  /// @param _stakeToken The pool's stake token
  function emergencyWithdraw(address _for, address _stakeToken) external override nonReentrant {
    UserInfo storage user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "MasterBarista::emergencyWithdraw::only funder");
    IERC20(_stakeToken).safeTransfer(address(_for), user.amount);

    emit EmergencyWithdraw(_for, _stakeToken, user.amount);

    // Burn BEAN if user emergencyWithdraw LATTE
    if (_stakeToken == address(latte)) {
      bean.burn(_for, user.amount);
    }

    // Reset user info
    user.amount = 0;
    user.rewardDebt = 0;
    user.bonusDebt = 0;
    user.fundedBy = address(0);
  }

  /// @dev what is a proportion of onlyBonusMultiplier in a form of BPS comparing to the total multiplier
  /// @param _lastRewardBlock The last block that rewards have been paid
  /// @param _currentBlock The current block
  function _getBonusMultiplierProportionBps(uint256 _lastRewardBlock, uint256 _currentBlock)
    internal
    view
    returns (uint256)
  {
    if (_currentBlock <= bonusEndBlock) {
      return 1e4;
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return 0;
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    uint256 onlyBonusMultiplier = bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    uint256 totalMultiplier = onlyBonusMultiplier.add(_currentBlock.sub(bonusEndBlock));
    return onlyBonusMultiplier.mul(1e4).div(totalMultiplier);
  }

  /// @dev This is a function for mining an extra amount of latte, should be called only by stake token caller contract (boosting purposed)
  /// @param _stakeToken a stake token address for validating a msg sender
  /// @param _amount amount to be minted
  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external override onlyStakeTokenCallerContract(_stakeToken) {
    uint256 multiplierBps = _getBonusMultiplierProportionBps(_lastRewardBlock, block.number);
    uint256 toBeLockedNum = _amount.mul(multiplierBps).mul(bonusLockUpBps);

    // mint & lock(if any) an extra reward
    latte.mint(_to, _amount);
    latte.lock(_to, toBeLockedNum.div(1e8));
    latte.mint(devAddr, _amount.mul(devFeeBps).div(1e4));
    latte.lock(devAddr, (toBeLockedNum.mul(devFeeBps)).div(1e12));

    emit MintExtraReward(_msgSender(), _stakeToken, _to, _amount);
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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IMasterBaristaV1 {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingLatte(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function devAddr() external view returns (address);

  function devFeeBps() external view returns (uint256);

  /// @dev configuration functions
  function addPool(address _stakeToken, uint256 _allocPoint) external;

  function setPool(address _stakeToken, uint256 _allocPoint) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositLatte(address _for, uint256 _amount) external;

  function withdrawLatte(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount,
    uint256 _lastRewardBlock
  ) external;
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

// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBeanBag.sol";
import "./interfaces/ILATTE.sol";

contract BeanBagV2 is ERC20Upgradeable, IBeanBag, OwnableUpgradeable {
  /// @notice latte token
  ILATTE public latte;

  function initialize(ILATTE _latte) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ERC20Upgradeable.__ERC20_init("Bean Token V2", "BEANV2");

    latte = _latte;
  }

  /// @dev A generic transfer function
  /// @param _to The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
    _transfer(_msgSender(), _to, _amount);
    return true;
  }

  /// @dev A generic transferFrom function
  /// @param _from The address of the account that will be debited
  /// @param _to The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) public virtual override returns (bool) {
    _transfer(_from, _to, _amount);
    _approve(
      _from,
      _msgSender(),
      allowance(_from, _msgSender()).sub(_amount, "BeanBagV2::transferFrom::transfer amount exceeds allowance")
    );
    return true;
  }

  /// @notice Mint `_amount` BEAN to `_to`. Must only be called by MasterBarista.
  /// @param _to The address to receive BEAN
  /// @param _amount The amount of BEAN that will be mint
  function mint(address _to, uint256 _amount) external override onlyOwner {
    _mint(_to, _amount);
  }

  /// @notice Burn `_amount` BEAN to `_from`. Must only be called by MasterBarista.
  /// @param _from The address to burn BEAN from
  /// @param _amount The amount of BEAN that will be burned
  function burn(address _from, uint256 _amount) external override onlyOwner {
    _burn(_from, _amount);
  }

  /// @notice Safe LATTE transfer function, just in case if rounding error causes pool to not have enough LATTEs.
  /// @param _to The address to transfer LATTE to
  /// @param _amount The amount to transfer to
  function safeLatteTransfer(address _to, uint256 _amount) external override onlyOwner {
    uint256 _latteBal = latte.balanceOf(address(this));
    if (_amount > _latteBal) {
      latte.transfer(_to, _latteBal);
    } else {
      latte.transfer(_to, _amount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
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

// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ILATTE.sol";

contract LATTEV2 is ERC20("LATTEv2", "LATTE"), Ownable, AccessControl {
  using SafeERC20 for IERC20;
  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  /// @dev private state variables
  uint256 private _totalLock;
  mapping(address => uint256) private _locks;
  mapping(address => uint256) private _lastUnlockBlock;

  /// @dev public immutable state variables
  uint256 public immutable startReleaseBlock;
  uint256 public immutable endReleaseBlock;
  bytes32 public immutable merkleRoot;

  /// @dev public mutable state variables
  uint256 public cap;

  // V1 LATTE token
  IERC20 public immutable lattev1;

  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // role for setting up non-sensitive data
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // role for minting stuff (owner + some delegated contract)
  address public constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;

  /// @dev events
  event LogLock(address indexed to, uint256 value);
  event LogCapChanged(uint256 prevCap, uint256 newCap);
  // This event is triggered whenever a call to #claim succeeds.
  event LogClaimedLock(uint256 index, address indexed account, uint256 amount);
  event LogRedeem(address indexed account, uint256 indexed amount);

  constructor(IERC20 _lattev1, bytes32 _merkleRoot) public {
    require(address(_lattev1) != address(0), "LATTEV2::constructor::latte v1 cannot be a zero address");
    _setupDecimals(18);
    cap = uint256(-1);
    startReleaseBlock = ILATTE(address(_lattev1)).startReleaseBlock();
    endReleaseBlock = ILATTE(address(_lattev1)).endReleaseBlock();
    merkleRoot = _merkleRoot;
    lattev1 = _lattev1;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNOR_ROLE, _msgSender());
  }

  modifier beforeStartReleaseBlock() {
    require(
      block.number < startReleaseBlock,
      "LATTEV2::beforeStartReleaseBlock:: operation can only be done before start release"
    );
    _;
  }

  /// @dev only the one having a GOVERNOR_ROLE can continue an execution
  modifier onlyGovernor() {
    require(hasRole(GOVERNOR_ROLE, _msgSender()), "LATTEV2::onlyGovernor::only GOVERNOR role");
    _;
  }

  /// @dev only the one having a MINTER_ROLE can continue an execution
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "LATTEV2::onlyMinter::only MINTER role");
    _;
  }

  /// @dev Return unlocked LATTE
  function unlockedSupply() external view returns (uint256) {
    return totalSupply().sub(totalLock());
  }

  /// @dev Return totalLocked LATTE
  function totalLock() public view returns (uint256) {
    return _totalLock;
  }

  /// @dev Set cap. Cap must lower than previous cap. Only Governor can adjust
  /// @param _cap The new cap
  function setCap(uint256 _cap) external onlyGovernor {
    require(_cap < cap, "LATTEV2::setCap::_cap must < cap");
    uint256 _prevCap = cap;
    cap = _cap;
    emit LogCapChanged(_prevCap, cap);
  }

  /// @dev A function to mint LATTE. This will be called by a minter only.
  /// @param _to The address of the account to get this newly mint LATTE
  /// @param _amount The amount to be minted
  function mint(address _to, uint256 _amount) external onlyMinter {
    require(totalSupply().add(_amount) < cap, "LATTEV2::mint::cap exceeded");
    _mint(_to, _amount);
  }

  /// @dev A generic transfer function
  /// @param _recipient The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
    _transfer(_msgSender(), _recipient, _amount);
    return true;
  }

  /// @dev A generic transferFrom function
  /// @param _sender The address of the account that will be debited
  /// @param _recipient The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public virtual override returns (bool) {
    _transfer(_sender, _recipient, _amount);
    _approve(
      _sender,
      _msgSender(),
      allowance(_sender, _msgSender()).sub(_amount, "LATTEV2::transferFrom::transfer amount exceeds allowance")
    );
    return true;
  }

  /// @dev Return the total balance (locked + unlocked) of a given account
  /// @param _account The address that you want to know the total balance
  function totalBalanceOf(address _account) external view returns (uint256) {
    return _locks[_account].add(balanceOf(_account));
  }

  /// @dev Return the locked LATTE of a given account
  /// @param _account The address that you want to know the locked LATTE
  function lockOf(address _account) external view returns (uint256) {
    return _locks[_account];
  }

  /// @dev Return unlock for a given account
  /// @param _account The address that you want to know the last unlock block
  function lastUnlockBlock(address _account) external view returns (uint256) {
    return _lastUnlockBlock[_account];
  }

  /// @dev Lock LATTE based-on the command from MasterBarista
  /// @param _account The address that will own this locked amount
  /// @param _amount The locked amount
  function lock(address _account, uint256 _amount) external onlyMinter {
    require(_account != address(this), "LATTEV2::lock::no lock to token address");
    require(_account != address(0), "LATTEV2::lock::no lock to address(0)");
    require(_amount <= balanceOf(_account), "LATTEV2::lock::no lock over balance");

    _lock(_account, _amount);
  }

  /// internal function for lock, there will be NO interaction here
  function _lock(address _account, uint256 _amount) internal {
    _transfer(_account, address(this), _amount);

    _locks[_account] = _locks[_account].add(_amount);
    _totalLock = _totalLock.add(_amount);

    if (_lastUnlockBlock[_account] < startReleaseBlock) {
      _lastUnlockBlock[_account] = startReleaseBlock;
    }

    emit LogLock(_account, _amount);
  }

  /// @dev Return how many LATTE is unlocked for a given account
  /// @param _account The address that want to check canUnlockAmount
  function canUnlockAmount(address _account) public view returns (uint256) {
    // When block number less than startReleaseBlock, no LATTEs can be unlocked
    if (block.number < startReleaseBlock) {
      return 0;
    }
    // When block number more than endReleaseBlock, all locked LATTEs can be unlocked
    else if (block.number >= endReleaseBlock) {
      return _locks[_account];
    }
    // When block number is more than startReleaseBlock but less than endReleaseBlock,
    // some LATTEs can be released
    else {
      uint256 releasedBlock = block.number.sub(_lastUnlockBlock[_account]);
      uint256 blockLeft = endReleaseBlock.sub(_lastUnlockBlock[_account]);
      return _locks[_account].mul(releasedBlock).div(blockLeft);
    }
  }

  /// @dev Claim unlocked LATTE after the release schedule is reached
  function unlock() external {
    require(_locks[msg.sender] > 0, "LATTEV2::unlock::no locked LATTE");

    uint256 amount = canUnlockAmount(msg.sender);

    _transfer(address(this), msg.sender, amount);
    _locks[msg.sender] = _locks[msg.sender].sub(amount);
    _lastUnlockBlock[msg.sender] = block.number;
    _totalLock = _totalLock.sub(amount);
  }

  /// @dev check whether or not the user already claimed
  function isClaimed(uint256 _index) public view returns (bool) {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /// @dev once an index (which is an account) claimed sth, set claimed
  function _setClaimed(uint256 _index) private {
    uint256 claimedWordIndex = _index / 256;
    uint256 claimedBitIndex = _index % 256;
    claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
  }

  /// @notice method for letting an account to claim lock from V1
  function claimLock(
    uint256[] calldata _indexes,
    address[] calldata _accounts,
    uint256[] calldata _amounts,
    bytes32[][] calldata _merkleProofs
  ) external beforeStartReleaseBlock {
    uint256 _total = 0;
    for (uint256 i = 0; i < _accounts.length; i++) {
      if (isClaimed(_indexes[i])) continue; // if some amounts already claimed their lock, continue to another one

      // Verify the merkle proof.
      bytes32 node = keccak256(abi.encodePacked(_indexes[i], _accounts[i], _amounts[i]));
      require(MerkleProof.verify(_merkleProofs[i], merkleRoot, node), "LATTEV2::claimLock:: invalid proof");

      _locks[_accounts[i]] = _amounts[i];
      _lastUnlockBlock[_accounts[i]] = startReleaseBlock; // set batch is always < startReleaseBlock
      _total = _total.add(_amounts[i]);

      // Mark it claimed
      _setClaimed(_indexes[i]);
      emit LogClaimedLock(_indexes[i], _accounts[i], _amounts[i]);
    }
    _mint(address(this), _total);
    _totalLock = _totalLock.add(_total);
  }

  /// @notice used for redeem a new token from the lagacy one, noted that the legacy one will be burnt as a result of redemption
  function redeem(uint256 _amount) external beforeStartReleaseBlock {
    // burn legacy token
    lattev1.safeTransferFrom(_msgSender(), DEAD_ADDR, _amount);

    // mint a new token
    _mint(_msgSender(), _amount);

    emit LogRedeem(_msgSender(), _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMasterBarista.sol";

contract LatteVault is Ownable, Pausable, ReentrancyGuard, AccessControl {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  struct UserInfo {
    uint256 shares; // number of shares for a user
    uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
    uint256 latteAtLastUserAction; // keeps track of LATTE deposited at the last user action
    uint256 lastUserActionTime; // keeps track of the last user action time
  }

  IERC20 public immutable latte; // LATTE token

  IMasterBarista public immutable masterBarista;

  mapping(address => UserInfo) public userInfo;

  uint256 public totalShares;
  uint256 public lastHarvestedTime;
  address public treasury;
  mapping(address => bool) public okFarmers;

  uint256 public constant MAX_PERFORMANCE_FEE = 500; // 5%
  uint256 public constant MAX_CALL_FEE = 100; // 1%
  uint256 public constant MAX_WITHDRAW_FEE = 100; // 1%
  uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 72 hours; // 3 days

  uint256 public performanceFee = 225; // 2.25%
  uint256 public withdrawFee = 10; // 0.1%
  uint256 public withdrawFeePeriod = 72 hours; // 3 days

  event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
  event Withdraw(address indexed sender, uint256 amount, uint256 shares);
  event Harvest(address indexed sender, uint256 performanceFee);
  event Pause();
  event Unpause();

  /**
   * @notice Constructor
   * @param _latte: LATTE token contract
   * @param _masterBarista: MasterBarista contract
   * @param _treasury: address of the treasury (collects fees)
   */
  constructor(
    IERC20 _latte,
    IMasterBarista _masterBarista,
    address _treasury,
    address[] memory _farmers
  ) public {
    latte = _latte;
    masterBarista = _masterBarista;
    treasury = _treasury;

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());

    uint256 len = _farmers.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okFarmers[_farmers[idx]] = true;
    }
  }

  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "LatteVault::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /**
   * @notice Checks if the msg.sender is a ok farmer
   */
  modifier onlyFarmer() {
    require(okFarmers[msg.sender], "LatteVault::onlyFarmer::msg.sender is not farmer");
    _;
  }

  modifier permit(bytes calldata _sig) {
    address recoveredAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(SIGNATURE_HASH), _sig);
    require(recoveredAddress == _msgSender(), "LatteVault::permit::INVALID_SIGNATURE");
    _;
  }

  /**
   * @notice Deposits funds into the Latte Vault
   * @dev Only possible when contract not paused.
   * @param _amount: number of tokens to deposit (in LATTE)
   */
  function deposit(uint256 _amount, bytes calldata _sig) external whenNotPaused nonReentrant permit(_sig) {
    require(_amount > 0, "LatteVault::deposit::nothing to deposit");

    _harvest();

    uint256 pool = balanceOf();
    latte.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 currentShares = 0;
    if (totalShares != 0) {
      currentShares = (_amount.mul(totalShares)).div(pool);
    } else {
      currentShares = _amount;
    }
    UserInfo storage user = userInfo[msg.sender];

    user.shares = user.shares.add(currentShares);
    user.lastDepositedTime = block.timestamp;

    totalShares = totalShares.add(currentShares);

    user.latteAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
    user.lastUserActionTime = block.timestamp;

    _earn();

    require(totalShares > 1e17, "LatteVault::deposit::no tiny shares");

    emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
  }

  /**
   * @notice Withdraws all funds for a user
   */
  function withdrawAll(bytes calldata _sig) external permit(_sig) {
    withdraw(userInfo[msg.sender].shares, _sig);
  }

  /**
   * @notice Reinvests LATTE into MasterBarista
   * @dev Only possible when contract not paused.
   */
  function harvest() external onlyFarmer whenNotPaused nonReentrant {
    _harvest();
  }

  /// @dev internal function for harvest to be reusable within the contract
  function _harvest() internal {
    IMasterBarista(masterBarista).harvest(address(this), address(latte));

    uint256 bal = available();
    uint256 currentPerformanceFee = bal.mul(performanceFee).div(10000);
    latte.safeTransfer(treasury, currentPerformanceFee);

    _earn();

    lastHarvestedTime = block.timestamp;

    emit Harvest(msg.sender, currentPerformanceFee);
  }

  /**
   * @notice Sets treasury address
   * @dev Only callable by the contract owner.
   */
  function setTreasury(address _treasury) external onlyOwner {
    require(_treasury != address(0), "LatteVault::setTreasury::cannot be zero address");
    treasury = _treasury;
  }

  /**
   * @notice Sets performance fee
   * @dev Only callable by the contract admin.
   */
  function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
    require(
      _performanceFee <= MAX_PERFORMANCE_FEE,
      "LatteVault::setPerformanceFee::performanceFee cannot be more than MAX_PERFORMANCE_FEE"
    );
    performanceFee = _performanceFee;
  }

  /**
   * @notice Sets withdraw fee
   * @dev Only callable by the contract admin.
   */
  function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
    require(
      _withdrawFee <= MAX_WITHDRAW_FEE,
      "LatteVault::setWithdrawFee::withdrawFee cannot be more than MAX_WITHDRAW_FEE"
    );
    withdrawFee = _withdrawFee;
  }

  /**
   * @notice Sets withdraw fee period
   * @dev Only callable by the contract admin.
   */
  function setWithdrawFeePeriod(uint256 _withdrawFeePeriod) external onlyOwner {
    require(
      _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
      "LatteVault::setWithdrawFeePeriod::withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
    );
    withdrawFeePeriod = _withdrawFeePeriod;
  }

  /**
   * @notice Withdraws from MasterChef to Vault without caring about rewards.
   * @dev EMERGENCY ONLY. Only callable by the contract admin.
   */
  function emergencyWithdraw() external onlyOwner {
    IMasterBarista(masterBarista).emergencyWithdraw(address(this), address(latte));
  }

  /**
   * @notice Withdraw unexpected tokens sent to the Latte Vault
   */
  function inCaseTokensGetStuck(address _token) external onlyOwner {
    require(_token != address(latte), "LatteVault::inCaseTokensGetStuck::token cannot be same as deposit token");

    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(msg.sender, amount);
  }

  /**
   * @notice Triggers stopped state
   * @dev Only possible when contract not paused.
   */
  function pause() external onlyGovernance whenNotPaused {
    _pause();
    emit Pause();
  }

  /**
   * @notice Returns to normal state
   * @dev Only possible when contract is paused.
   */
  function unpause() external onlyGovernance whenPaused {
    _unpause();
    emit Unpause();
  }

  /**
   * @notice Calculates the total pending rewards that can be restaked
   * @return Returns total pending LATTE rewards
   */
  function calculateTotalPendingLatteRewards() external view returns (uint256) {
    uint256 amount = IMasterBarista(masterBarista).pendingLatte(address(latte), address(this));
    amount = amount.add(available());

    return amount;
  }

  /**
   * @notice Calculates the price per share
   */
  function getPricePerFullShare() external view returns (uint256) {
    return totalShares == 0 ? 1e18 : balanceOf().mul(1e18).div(totalShares);
  }

  /**
   * @notice Withdraws from funds from the Latte Vault
   * @param _shares: Number of shares to withdraw
   */
  function withdraw(uint256 _shares, bytes calldata _sig) public nonReentrant permit(_sig) {
    UserInfo storage user = userInfo[msg.sender];
    require(_shares > 0, "LatteVault::withdraw::nothing to withdraw");
    require(_shares <= user.shares, "LatteVault::withdraw::withdraw amount exceeds balance");

    uint256 currentAmount = (balanceOf().mul(_shares)).div(totalShares);
    user.shares = user.shares.sub(_shares);
    totalShares = totalShares.sub(_shares);

    uint256 bal = available();
    if (bal < currentAmount) {
      uint256 balWithdraw = currentAmount.sub(bal);
      IMasterBarista(masterBarista).withdraw(address(this), address(latte), balWithdraw);
      uint256 balAfter = available();
      uint256 diff = balAfter.sub(bal);
      if (diff < balWithdraw) {
        currentAmount = bal.add(diff);
      }
    }

    if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
      uint256 currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
      latte.safeTransfer(treasury, currentWithdrawFee);
      currentAmount = currentAmount.sub(currentWithdrawFee);
    }

    /// @notice optimistically transfer LATTE before update latteAtLastUserAction
    latte.safeTransfer(msg.sender, currentAmount);

    if (user.shares > 0) {
      user.latteAtLastUserAction = user.shares.mul(balanceOf()).div(totalShares);
    } else {
      user.latteAtLastUserAction = 0;
    }

    user.lastUserActionTime = block.timestamp;

    require(totalShares > 1e17, "LatteVault::deposit::no tiny shares");

    emit Withdraw(msg.sender, currentAmount, _shares);
  }

  /**
   * @notice Custom logic for how much the vault allows to be borrowed
   * @dev The contract puts 100% of the tokens to work.
   */
  function available() public view returns (uint256) {
    return latte.balanceOf(address(this));
  }

  /**
   * @notice Calculates the total underlying tokens
   * @dev It includes tokens held by the contract and held in MasterBarista
   */
  function balanceOf() public view returns (uint256) {
    (uint256 amount, , , ) = IMasterBarista(masterBarista).userInfo(address(latte), address(this));
    return latte.balanceOf(address(this)).add(amount);
  }

  /**
   * @notice Deposits tokens into MasterBarista to earn staking rewards
   */
  function _earn() internal {
    uint256 bal = available();
    if (bal > 0) {
      IMasterBarista(masterBarista).deposit(address(this), address(latte), bal);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/ILatteNFT.sol";

contract LatteNFT is ILatteNFT, ERC721Pausable, Ownable, AccessControl {
  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE"); // role for setting up non-sensitive data
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // role for minting stuff (owner + some delegated contract eg nft market)

  struct Category {
    string name;
    string categoryURI; // category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
    uint256 timestamp;
  }

  // Used for generating the tokenId of new NFT minted
  Counters.Counter private _tokenIds;

  // Used for incrementing category id
  Counters.Counter private _categoryIds;

  // Map the latteName for a tokenId
  mapping(uint256 => string) public override latteNames;

  mapping(uint256 => Category) public override categoryInfo;

  mapping(uint256 => uint256) public override latteNFTToCategory;

  mapping(uint256 => EnumerableSet.UintSet) private _categoryToLatteNFTList;

  mapping(uint256 => string) private _tokenURIs;

  event AddCategoryInfo(uint256 indexed id, string name, string uri);
  event UpdateCategoryInfo(uint256 indexed id, string prevName, string newName, string newURI);
  event SetLatteName(uint256 indexed tokenId, string prevName, string newName);
  event SetTokenURI(uint256 indexed tokenId, string indexed prevURI, string indexed currentURI);
  event SetBaseURI(string indexed prevURI, string indexed currentURI);
  event SetTokenCategory(uint256 indexed tokenId, uint256 indexed categoryId);
  event Pause();
  event Unpause();

  /// @dev only the one having a GOVERNANCE_ROLE can continue an execution
  modifier onlyGovernance() {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "LatteNFT::onlyGovernance::only GOVERNANCE role");
    _;
  }

  /// @dev only the one having a MINTER_ROLE can continue an execution
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "LatteNFT::onlyMinter::only MINTER role");
    _;
  }

  modifier onlyExistingCategoryId(uint256 _categoryId) {
    require(_categoryIds.current() >= _categoryId, "LatteNFT::onlyExistingCategoryId::categoryId not existed");
    _;
  }

  constructor(string memory _baseURI) ERC721("LATTE NFT", "LNFT") public {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setBaseURI(_baseURI);
  }

  /// @notice getter function for getting a token id list with respect to category Id
  /// @param _categoryId category id
  /// @return return alist of nft tokenId
  function categoryToLatteNFTList(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds = new uint256[](_categoryToLatteNFTList[_categoryId].length());
    for (uint256 i = 0; i < _categoryToLatteNFTList[_categoryId].length(); i++) {
      tokenIds[i] = _categoryToLatteNFTList[_categoryId].at(i);
    }
    return tokenIds;
  }

  /// @notice return latest token id
  /// @return uint256 of the current token id
  function currentTokenId() public view override returns (uint256) {
    return _tokenIds.current();
  }

  /// @notice return latest category id
  /// @return uint256 of the current category id
  function currentCategoryId() public view override returns (uint256) {
    return _categoryIds.current();
  }

  /// @notice add category (group of tokens)
  /// @param _name a name of a category
  /// @param _uri category URI, a super set of token's uri (it can be either uri or a path (if specify a base URI))
  function addCategoryInfo(string memory _name, string memory _uri) external onlyGovernance {
    uint256 newId = _categoryIds.current();
    _categoryIds.increment();
    categoryInfo[newId] = Category({ name: _name, timestamp: block.timestamp, categoryURI: _uri });

    emit AddCategoryInfo(newId, _name, _uri);
  }

  /// @notice view function for category URI
  /// @param _categoryId category id
  function categoryURI(uint256 _categoryId)
    external
    view
    override
    onlyExistingCategoryId(_categoryId)
    returns (string memory)
  {
    string memory _categoryURI = categoryInfo[_categoryId].categoryURI;
    string memory base = baseURI();

    // If there is no base URI, return the category URI.
    if (bytes(base).length == 0) {
      return _categoryURI;
    }
    // If both are set, concatenate the baseURI and categoryURI (via abi.encodePacked).
    if (bytes(_categoryURI).length > 0) {
      return string(abi.encodePacked(base, _categoryURI));
    }
    // If there is a baseURI but no categoryURI, concatenate the categoryId to the baseURI.
    return string(abi.encodePacked(base, _categoryId.toString()));
  }

  /**
   * @dev overrided tokenURI with a categoryURI replacement feature
   * @param _tokenId - token id
   */
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721, IERC721Metadata)
    returns (string memory)
  {
    require(_exists(_tokenId), "LatteNFT::tokenURI:: token not existed");

    string memory _tokenURI = _tokenURIs[_tokenId];
    string memory base = baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    // If if category uri exists, use categoryURI as a tokenURI
    if (bytes(categoryInfo[latteNFTToCategory[_tokenId]].categoryURI).length > 0) {
      return string(abi.encodePacked(base, categoryInfo[latteNFTToCategory[_tokenId]].categoryURI));
    }

    // If there is a baseURI but neither have tokenURI nor categoryURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, _tokenId.toString()));
  }

  /// @notice update category (group of tokens)
  /// @param _categoryId a category id
  /// @param _newName a new updated name
  /// @param _newURI a new category URI
  function updateCategoryInfo(
    uint256 _categoryId,
    string memory _newName,
    string memory _newURI
  ) external onlyGovernance onlyExistingCategoryId(_categoryId) {
    Category storage category = categoryInfo[_categoryId];
    string memory prevName = category.name;
    category.name = _newName;
    category.categoryURI = _newURI;
    category.timestamp = block.timestamp;

    emit UpdateCategoryInfo(_categoryId, prevName, _newName, _newURI);
  }

  /// @notice update a token's categoryId
  /// @param _tokenId a token id to be updated
  /// @param _newCategoryId a new categoryId for the token
  function updateTokenCategory(uint256 _tokenId, uint256 _newCategoryId)
    external
    onlyGovernance
    onlyExistingCategoryId(_newCategoryId)
  {
    uint256 categoryIdToBeRemovedFrom = latteNFTToCategory[_tokenId];
    latteNFTToCategory[_tokenId] = _newCategoryId;
    require(
      _categoryToLatteNFTList[categoryIdToBeRemovedFrom].remove(_tokenId),
      "LatteNFT::updateTokenCategory::tokenId not found"
    );
    require(_categoryToLatteNFTList[_newCategoryId].add(_tokenId), "LatteNFT::updateTokenCategory::duplicated tokenId");

    emit SetTokenCategory(_tokenId, _newCategoryId);
  }

  /**
   * @dev Get the associated latteName for a unique tokenId.
   */
  function getLatteNameOfTokenId(uint256 _tokenId) external view override returns (string memory) {
    return latteNames[_tokenId];
  }

  /**
   * @dev Mint NFT. Only the minter can call it.
   */
  function mint(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI
  ) public virtual override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256) {
    uint256 newId = _tokenIds.current();
    _tokenIds.increment();
    latteNFTToCategory[newId] = _categoryId;
    require(_categoryToLatteNFTList[_categoryId].add(newId), "LatteNFT::mint::duplicated tokenId");
    _mint(_to, newId);
    _setTokenURI(newId, _tokenURI);
    emit SetTokenCategory(newId, _categoryId);
    return newId;
  }

  function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
    require(_exists(_tokenId), "LatteNFT::_setTokenURI::tokenId not found");
    string memory prevURI = _tokenURIs[_tokenId];
    _tokenURIs[_tokenId] = _tokenURI;

    emit SetTokenURI(_tokenId, prevURI, _tokenURI);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyGovernance {
    _setTokenURI(_tokenId, _tokenURI);
  }

  /**
   * @dev function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function setBaseURI(string memory _baseURI) external onlyGovernance {
    string memory prevURI = baseURI();
    _setBaseURI(_baseURI);

    emit SetBaseURI(prevURI, _baseURI);
  }

  /**
   * @dev batch ming NFTs. Only the owner can call it.
   */
  function mintBatch(
    address _to,
    uint256 _categoryId,
    string calldata _tokenURI,
    uint256 _size
  ) external override onlyMinter onlyExistingCategoryId(_categoryId) returns (uint256[] memory tokenIds) {
    require(_size != 0, "LatteNFT::mintBatch::size must be granter than zero");
    tokenIds = new uint256[](_size);
    for (uint256 i = 0; i < _size; ++i) {
      tokenIds[i] = mint(_to, _categoryId, _tokenURI);
    }
    return tokenIds;
  }

  /**
   * @dev Set a unique name for each tokenId. It is supposed to be called once.
   */
  function setLatteName(uint256 _tokenId, string calldata _name) external onlyGovernance {
    string memory _prevName = latteNames[_tokenId];
    latteNames[_tokenId] = _name;

    emit SetLatteName(_tokenId, _prevName, _name);
  }

  function pause() external onlyGovernance whenNotPaused {
    _pause();

    emit Pause();
  }

  function unpause() external onlyGovernance whenPaused {
    _unpause();

    emit Unpause();
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LATTE is ERC20("LATTE", "LATTE"), Ownable {
  /// @dev private state variables
  uint256 private _totalLock;
  mapping(address => uint256) private _locks;
  mapping(address => uint256) private _lastUnlockBlock;

  /// @dev public immutable state variables
  uint256 public startReleaseBlock;
  uint256 public endReleaseBlock;

  /// @dev public mutable state variables
  uint256 public cap;
  address public governor;

  /// @dev events
  event Lock(address indexed to, uint256 value);
  event CapChanged(uint256 prevCap, uint256 newCap);
  event GovernorChanged(address prevGovernor, address newGovernor);

  constructor(
    address _governor,
    uint256 _startReleaseBlock,
    uint256 _endReleaseBlock
  ) public {
    require(_endReleaseBlock > _startReleaseBlock, "LATTE::constructor::endReleaseBlock < startReleaseBlock");
    _setupDecimals(18);
    cap = uint256(-1);
    governor = _governor;
    startReleaseBlock = _startReleaseBlock;
    endReleaseBlock = _endReleaseBlock;
  }

  modifier onlyGovernor() {
    require(_msgSender() == governor, "LATTE::onlyGovernor::not governor");
    _;
  }

  /// @dev Return unlocked LATTE
  function unlockedSupply() external view returns (uint256) {
    return totalSupply().sub(totalLock());
  }

  /// @dev Return totalLocked LATTE
  function totalLock() public view returns (uint256) {
    return _totalLock;
  }

  /// @dev Set cap. Cap must lower than previous cap. Only Governor can adjust
  /// @param _cap The new cap
  function setCap(uint256 _cap) external onlyGovernor {
    require(_cap < cap, "LATTE::setCap::_cap must < cap");
    uint256 prevCap = cap;
    cap = _cap;
    emit CapChanged(prevCap, cap);
  }

  /// @dev Set a new governor
  /// @param _governor The new governor
  function setGovernor(address _governor) external onlyGovernor {
    require(governor != _governor, "LATTE::setGovernor::no self set");
    address prevGov = governor;
    governor = _governor;
    emit GovernorChanged(prevGov, governor);
  }

  /// @dev A function to mint LATTE. This will be called by an owner only.
  /// @param _to The address of the account to get this newly mint LATTE
  /// @param _amount The amount to be minted
  function mint(address _to, uint256 _amount) external onlyOwner {
    require(totalSupply().add(_amount) < cap, "LATTE::mint::cap exceeded");
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  /// @dev A generic transfer function with moveDelegates
  /// @param _recipient The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
    _transfer(_msgSender(), _recipient, _amount);
    _moveDelegates(_delegates[_msgSender()], _delegates[_recipient], _amount);
    return true;
  }

  /// @dev A generic transferFrom function with moveDelegates
  /// @param _sender The address of the account that will be debited
  /// @param _recipient The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
    _transfer(_sender, _recipient, _amount);
    _approve(_sender, _msgSender(), allowance(_sender, _msgSender()).sub(_amount, "LATTE::transferFrom::transfer amount exceeds allowance"));
    _moveDelegates(_delegates[_sender], _delegates[_recipient], _amount);
    return true;
  }

  /// @dev Return the total balance (locked + unlocked) of a given account
  /// @param _account The address that you want to know the total balance
  function totalBalanceOf(address _account) external view returns (uint256) {
    return _locks[_account].add(balanceOf(_account));
  }

  /// @dev Return the locked LATTE of a given account
  /// @param _account The address that you want to know the locked LATTE
  function lockOf(address _account) external view returns (uint256) {
    return _locks[_account];
  }

  /// @dev Return unlock for a given account
  /// @param _account The address that you want to know the last unlock block
  function lastUnlockBlock(address _account) external view returns (uint256) {
    return _lastUnlockBlock[_account];
  }

  /// @dev Lock LATTE based-on the command from MasterBarista
  /// @param _account The address that will own this locked amount
  /// @param _amount The locked amount
  function lock(address _account, uint256 _amount) external onlyOwner {
    require(_account != address(this), "LATTE::lock::no lock to token address");
    require(_account != address(0), "LATTE::lock::no lock to address(0)");
    require(_amount <= balanceOf(_account), "LATTE::lock::no lock over balance");

    _transfer(_account, address(this), _amount);

    _locks[_account] = _locks[_account].add(_amount);
    _totalLock = _totalLock.add(_amount);

    if (_lastUnlockBlock[_account] < startReleaseBlock) {
      _lastUnlockBlock[_account] = startReleaseBlock;
    }

    emit Lock(_account, _amount);
  }

  /// @dev Return how many LATTE is unlocked for a given account
  /// @param _account The address that want to check canUnlockAmount
  function canUnlockAmount(address _account) public view returns (uint256) {
    // When block number less than startReleaseBlock, no LATTEs can be unlocked
    if (block.number < startReleaseBlock) {
      return 0;
    }
    // When block number more than endReleaseBlock, all locked LATTEs can be unlocked
    else if (block.number >= endReleaseBlock) {
      return _locks[_account];
    }
    // When block number is more than startReleaseBlock but less than endReleaseBlock,
    // some LATTEs can be released
    else
    {
      uint256 releasedBlock = block.number.sub(_lastUnlockBlock[_account]);
      uint256 blockLeft = endReleaseBlock.sub(_lastUnlockBlock[_account]);
      return _locks[_account].mul(releasedBlock).div(blockLeft);
    }
  }

  /// @dev Claim unlocked LATTE after the release schedule is reached
  function unlock() external {
    require(_locks[msg.sender] > 0, "LATTE::unlock::no locked LATTE");

    uint256 amount = canUnlockAmount(msg.sender);

    _transfer(address(this), msg.sender, amount);
    _locks[msg.sender] = _locks[msg.sender].sub(amount);
    _lastUnlockBlock[msg.sender] = block.number;
    _totalLock = _totalLock.sub(amount);
  }

  /// @dev Move both locked and unlocked LATTE to another account
  /// @param _to The address to be received locked and unlocked LATTE
  function transferAll(address _to) external {
    require(msg.sender != _to, "LATTE::transferAll::no self-transferAll");

    _locks[_to] = _locks[_to].add(_locks[msg.sender]);

    if (_lastUnlockBlock[_to] < startReleaseBlock) {
      _lastUnlockBlock[_to] = startReleaseBlock;
    }

    else if (block.number < endReleaseBlock) {
        uint256 fromUnlocked = canUnlockAmount(msg.sender);
        uint256 toUnlocked = canUnlockAmount(_to);
        uint256 numerator = block.number.mul(_locks[msg.sender]).add(block.number.mul(_locks[_to])).sub(endReleaseBlock.mul(fromUnlocked)).sub(endReleaseBlock.mul(toUnlocked));
        uint256 denominator = _locks[msg.sender].add(_locks[_to]).sub(fromUnlocked).sub(toUnlocked);
        _lastUnlockBlock[_to] = numerator.div(denominator);
    }
    
    _locks[msg.sender] = 0;
    _lastUnlockBlock[msg.sender] = 0;

    _moveDelegates(_delegates[_msgSender()], _delegates[_to], balanceOf(_msgSender()));
    _transfer(msg.sender, _to, balanceOf(_msgSender()));
  }

  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  mapping(address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
  );

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256(
    "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
  );

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegator The address to get delegatee for
    */
  function delegates(address delegator) external view returns (address) {
    return _delegates[delegator];
  }

  /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
    * @notice Delegates votes from signatory to `delegatee`
    * @param delegatee The address to delegate votes to
    * @param nonce The contract state required to match the signature
    * @param expiry The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
    );

    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "LATTE::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "LATTE::delegateBySig: invalid nonce");
    require(now <= expiry, "LATTE::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
    * @notice Gets the current votes balance for `account`
    * @param account The address to get votes balance
    * @return The number of current votes for `account`
    */
  function getCurrentVotes(address account) external view returns (uint256) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
    * @notice Determine the prior number of votes for an account as of a block number
    * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    * @param account The address of the account to check
    * @param blockNumber The block number to get the vote balance at
    * @return The number of votes the account had as of the given block
    */
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
    require(blockNumber < block.number, "LATTE::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying LATTEs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint256 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "LATTE::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Dripbar allows users to stake BEAN to earn various rewards.
contract DripBar is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }

  // Info of each reward distribution campaign.
  struct CampaignInfo {
    IERC20 stakingToken; // Address of Staking token contract.
    IERC20 rewardToken; // Address of Reward token contract
    uint256 startBlock; // start block of the campaign
    uint256 lastRewardBlock; // Last block number that Reward Token distribution occurs.
    uint256 accRewardPerShare; // Accumulated Reward Token per share, times 1e12. See below.
    uint256 totalStaked; // total staked amount each campaign's stake token, typically, each campaign has the same stake token, so need to track it separatedly
    uint256 totalRewards;
  }

  // Reward info
  struct RewardInfo {
    uint256 endBlock;
    uint256 rewardPerBlock;
  }

  // @dev this is mostly used for extending reward period
  // @notice Reward info is a set of {endBlock, rewardPerBlock}
  // indexed by campaigh ID
  mapping(uint256 => RewardInfo[]) public campaignRewardInfo;

  // @notice Info of each campaign. mapped from campaigh ID
  CampaignInfo[] public campaignInfo;
  // Info of each user that stakes Staking tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  // @notice limit length of reward info
  // how many phases are allowed
  uint256 public rewardInfoLimit;
  // @dev reward holder account
  address public rewardHolder;

  event Deposit(address indexed user, uint256 amount, uint256 campaign);
  event Withdraw(address indexed user, uint256 amount, uint256 campaign);
  event EmergencyWithdraw(address indexed user, uint256 amount, uint256 campaign);
  event AddCampaignInfo(uint256 indexed campaignID, IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock);
  event AddRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);
  event SetRewardInfoLimit(uint256 rewardInfoLimit);
  event SetRewardHolder(address rewardHolder);

  function initialize(address _rewardHolder) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    rewardInfoLimit = 52; // 52 weeks, 1 year
    rewardHolder = _rewardHolder;
  }

  /// @notice function for setting a reward holder who is responsible for adding a reward info
  function setRewardHolder(address _rewardHolder) external onlyOwner {
    rewardHolder = _rewardHolder;
    emit SetRewardHolder(_rewardHolder);
  }

  /// @notice set new reward info limit
  function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external onlyOwner {
    rewardInfoLimit = _updatedRewardInfoLimit;
    emit SetRewardInfoLimit(rewardInfoLimit);
  }

  /// @notice reward campaign, one campaign represents a pair of staking and reward token, last reward Block and acc reward Per Share
  function addCampaignInfo(
    IERC20 _stakingToken,
    IERC20 _rewardToken,
    uint256 _startBlock
  ) external onlyOwner {
    campaignInfo.push(
      CampaignInfo({
        stakingToken: _stakingToken,
        rewardToken: _rewardToken,
        startBlock: _startBlock,
        lastRewardBlock: _startBlock,
        accRewardPerShare: 0,
        totalStaked: 0,
        totalRewards: 0
      })
    );
    emit AddCampaignInfo(campaignInfo.length - 1, _stakingToken, _rewardToken, _startBlock);
  }

  /// @notice if the new reward info is added, the reward & its end block will be extended by the newly pushed reward info.
  function addRewardInfo(
    uint256 _campaignID,
    uint256 _endBlock,
    uint256 _rewardPerBlock
  ) external onlyOwner {
    RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    require(rewardInfo.length < rewardInfoLimit, "DripBar::addRewardInfo::reward info length exceeds the limit");
    require(
      rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock >= block.number,
      "DripBar::addRewardInfo::reward period ended"
    );
    require(
      rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock < _endBlock,
      "DripBar::addRewardInfo::bad new endblock"
    );
    uint256 startBlock = rewardInfo.length == 0 ? campaign.startBlock : rewardInfo[rewardInfo.length - 1].endBlock;
    uint256 blockRange = _endBlock.sub(startBlock);
    uint256 totalRewards = _rewardPerBlock.mul(blockRange);
    campaign.rewardToken.safeTransferFrom(rewardHolder, address(this), totalRewards);
    campaign.totalRewards = campaign.totalRewards.add(totalRewards);
    rewardInfo.push(RewardInfo({ endBlock: _endBlock, rewardPerBlock: _rewardPerBlock }));
    emit AddRewardInfo(_campaignID, rewardInfo.length - 1, _endBlock, _rewardPerBlock);
  }

  function rewardInfoLen(uint256 _campaignID) external view returns (uint256) {
    return campaignRewardInfo[_campaignID].length;
  }

  function campaignInfoLen() external view returns (uint256) {
    return campaignInfo.length;
  }

  /// @notice this will return  end block based on the current block number.
  function currentEndBlock(uint256 _campaignID) external view returns (uint256) {
    return _endBlockOf(_campaignID, block.number);
  }

  function _endBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
    RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
    uint256 len = rewardInfo.length;
    if (len == 0) {
      return 0;
    }
    for (uint256 i = 0; i < len; ++i) {
      if (_blockNumber <= rewardInfo[i].endBlock) return rewardInfo[i].endBlock;
    }
    // @dev when couldn't find any reward info, it means that _blockNumber exceed endblock
    // so return the latest reward info.
    return rewardInfo[len - 1].endBlock;
  }

  /// @notice this will return reward per block based on the current block number.
  function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256) {
    return _rewardPerBlockOf(_campaignID, block.number);
  }

  function _rewardPerBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
    RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
    uint256 len = rewardInfo.length;
    if (len == 0) {
      return 0;
    }
    for (uint256 i = 0; i < len; ++i) {
      if (_blockNumber <= rewardInfo[i].endBlock) return rewardInfo[i].rewardPerBlock;
    }
    // @dev when couldn't find any reward info, it means that timestamp exceed endblock
    // so return 0
    return 0;
  }

  /// @notice Return reward multiplier over the given _from to _to block.
  function getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _endBlock
  ) public pure returns (uint256) {
    if ((_from >= _endBlock) || (_from > _to)) {
      return 0;
    }
    if (_to <= _endBlock) {
      return _to.sub(_from);
    }
    return _endBlock.sub(_from);
  }

  /// @notice View function to see pending Reward on frontend.
  function pendingReward(uint256 _campaignID, address _user) external view returns (uint256) {
    return _pendingReward(_campaignID, userInfo[_campaignID][_user].amount, userInfo[_campaignID][_user].rewardDebt);
  }

  function _pendingReward(
    uint256 _campaignID,
    uint256 _amount,
    uint256 _rewardDebt
  ) internal view returns (uint256) {
    CampaignInfo memory campaign = campaignInfo[_campaignID];
    RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
    uint256 accRewardPerShare = campaign.accRewardPerShare;
    if (block.number > campaign.lastRewardBlock && campaign.totalStaked != 0) {
      uint256 cursor = campaign.lastRewardBlock;
      for (uint256 i = 0; i < rewardInfo.length; ++i) {
        uint256 multiplier = getMultiplier(cursor, block.number, rewardInfo[i].endBlock);
        if (multiplier == 0) continue;
        cursor = rewardInfo[i].endBlock;
        accRewardPerShare = accRewardPerShare.add(
          multiplier.mul(rewardInfo[i].rewardPerBlock).mul(1e12).div(campaign.totalStaked)
        );
      }
    }
    return _amount.mul(accRewardPerShare).div(1e12).sub(_rewardDebt);
  }

  function updateCampaign(uint256 _campaignID) external nonReentrant {
    _updateCampaign(_campaignID);
  }

  /// @notice Update reward variables of the given campaign to be up-to-date.
  function _updateCampaign(uint256 _campaignID) internal {
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
    if (block.number <= campaign.lastRewardBlock) {
      return;
    }
    if (campaign.totalStaked == 0) {
      // if there is no total supply, return and use the campaign's start block as the last reward block
      // so that ALL reward will be distributed.
      // however, if the first deposit is out of reward period, last reward block will be its block number
      // in order to keep the multiplier = 0
      if (block.number > _endBlockOf(_campaignID, block.number)) {
        campaign.lastRewardBlock = block.number;
      }
      return;
    }
    // @dev for each reward info
    for (uint256 i = 0; i < rewardInfo.length; ++i) {
      // @dev get multiplier based on current Block and rewardInfo's end block
      // multiplier will be a range of either (current block - campaign.lastRewardBlock)
      // or (reward info's endblock - campaign.lastRewardBlock) or 0
      uint256 multiplier = getMultiplier(campaign.lastRewardBlock, block.number, rewardInfo[i].endBlock);
      if (multiplier == 0) continue;
      // @dev if currentBlock exceed end block, use end block as the last reward block
      // so that for the next iteration, previous endBlock will be used as the last reward block
      if (block.number > rewardInfo[i].endBlock) {
        campaign.lastRewardBlock = rewardInfo[i].endBlock;
      } else {
        campaign.lastRewardBlock = block.number;
      }
      campaign.accRewardPerShare = campaign.accRewardPerShare.add(
        multiplier.mul(rewardInfo[i].rewardPerBlock).mul(1e12).div(campaign.totalStaked)
      );
    }
  }

  /// @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL
  function massUpdateCampaigns() external nonReentrant {
    uint256 length = campaignInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      _updateCampaign(pid);
    }
  }

  /// @notice Stake Staking tokens to DripBar
  function deposit(uint256 _campaignID, uint256 _amount) external nonReentrant {
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    UserInfo storage user = userInfo[_campaignID][msg.sender];
    _updateCampaign(_campaignID);
    if (user.amount > 0) {
      uint256 pending = user.amount.mul(campaign.accRewardPerShare).div(1e12).sub(user.rewardDebt);
      if (pending > 0) {
        campaign.rewardToken.safeTransfer(address(msg.sender), pending);
      }
    }
    if (_amount > 0) {
      campaign.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      user.amount = user.amount.add(_amount);
      campaign.totalStaked = campaign.totalStaked.add(_amount);
    }
    user.rewardDebt = user.amount.mul(campaign.accRewardPerShare).div(1e12);
    emit Deposit(msg.sender, _amount, _campaignID);
  }

  /// @notice Withdraw Staking tokens from STAKING.
  function withdraw(uint256 _campaignID, uint256 _amount) external nonReentrant {
    _withdraw(_campaignID, _amount);
  }

  /// @notice internal method for withdraw (withdraw and harvest method depend on this method)
  function _withdraw(uint256 _campaignID, uint256 _amount) internal {
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    UserInfo storage user = userInfo[_campaignID][msg.sender];
    require(user.amount >= _amount, "DripBar::withdraw::bad withdraw amount");
    _updateCampaign(_campaignID);
    uint256 pending = user.amount.mul(campaign.accRewardPerShare).div(1e12).sub(user.rewardDebt);
    if (pending > 0) {
      campaign.rewardToken.safeTransfer(address(msg.sender), pending);
    }
    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      campaign.stakingToken.safeTransfer(address(msg.sender), _amount);
      campaign.totalStaked = campaign.totalStaked.sub(_amount);
    }
    user.rewardDebt = user.amount.mul(campaign.accRewardPerShare).div(1e12);

    emit Withdraw(msg.sender, _amount, _campaignID);
  }

  /// @notice method for harvest campaigns (used when the user want to claim their reward token based on specified campaigns)
  function harvest(uint256[] calldata _campaignIDs) external nonReentrant {
    for (uint256 i = 0; i < _campaignIDs.length; ++i) {
      _withdraw(_campaignIDs[i], 0);
    }
  }

  /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _campaignID) external nonReentrant {
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    UserInfo storage user = userInfo[_campaignID][msg.sender];
    uint256 _amount = user.amount;
    campaign.totalStaked = campaign.totalStaked.sub(_amount);
    user.amount = 0;
    user.rewardDebt = 0;
    campaign.stakingToken.safeTransfer(address(msg.sender), _amount);
    emit EmergencyWithdraw(msg.sender, _amount, _campaignID);
  }

  /// @notice Withdraw reward. EMERGENCY ONLY.
  function emergencyRewardWithdraw(
    uint256 _campaignID,
    uint256 _amount,
    address _beneficiary
  ) external onlyOwner nonReentrant {
    CampaignInfo storage campaign = campaignInfo[_campaignID];
    uint256 currentStakingPendingReward = _pendingReward(_campaignID, campaign.totalStaked, 0);
    require(
      currentStakingPendingReward.add(_amount) <= campaign.totalRewards,
      "DripBar::emergencyRewardWithdraw::not enough reward token"
    );
    campaign.totalRewards = campaign.totalRewards.sub(_amount);
    campaign.rewardToken.safeTransfer(_beneficiary, _amount);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBeanBag.sol";
import "./interfaces/ILATTE.sol";

contract BeanBag is ERC20('Bean Token', 'BEAN'), IBeanBag, Ownable {

  /// @notice latte token
  ILATTE public latte;

  constructor(
    ILATTE _latte
  ) public {
    latte = _latte;
  }

  /// @dev A generic transfer function with moveDelegates
  /// @param _to The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
    _transfer(_msgSender(), _to, _amount);
    _moveDelegates(_delegates[_msgSender()], _delegates[_to], _amount);
    return true;
  }

  /// @dev A generic transferFrom function with moveDelegates
  /// @param _from The address of the account that will be debited
  /// @param _to The address of the account that will be credited
  /// @param _amount The amount to be moved
  function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
    _transfer(_from, _to, _amount);
    _approve(_from, _msgSender(), allowance(_from, _msgSender()).sub(_amount, "BeanBag::transferFrom::transfer amount exceeds allowance"));
    _moveDelegates(_delegates[_from], _delegates[_to], _amount);
    return true;
  }

  /// @notice Mint `_amount` BEAN to `_to`. Must only be called by MasterBarista.
  /// @param _to The address to receive BEAN
  /// @param _amount The amount of BEAN that will be mint
  function mint(address _to, uint256 _amount) external override onlyOwner {
    _mint(_to, _amount);
    _moveDelegates(address(0), _delegates[_to], _amount);
  }

  /// @notice Burn `_amount` BEAN to `_from`. Must only be called by MasterBarista.
  /// @param _from The address to burn BEAN from
  /// @param _amount The amount of BEAN that will be burned
  function burn(address _from ,uint256 _amount) external override onlyOwner {
    _burn(_from, _amount);
    _moveDelegates(address(0), _delegates[_from], _amount);
  }

  /// @notice Safe LATTE transfer function, just in case if rounding error causes pool to not have enough LATTEs.
  /// @param _to The address to transfer LATTE to
  /// @param _amount The amount to transfer to
  function safeLatteTransfer(address _to, uint256 _amount) external override onlyOwner {
    uint256 latteBal = latte.balanceOf(address(this));
    if (_amount > latteBal) {
      latte.transfer(_to, latteBal);
    } else {
      latte.transfer(_to, _amount);
    }
  }

  // Copied and modified from YAM code:
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
  // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
  // Which is copied and modified from COMPOUND:
  // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

  /// @dev A record of each accounts delegate
  mapping (address => address) internal _delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint256 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping (address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping (address => uint) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

  /**
  * @notice Delegate votes from `msg.sender` to `delegatee`
  * @param delegator The address to get delegatee for
  */
  function delegates(address delegator)
    external
    view
    returns (address)
  {
    return _delegates[delegator];
  }

  /**
  * @notice Delegate votes from `msg.sender` to `delegatee`
  * @param delegatee The address to delegate votes to
  */
  function delegate(address delegatee) external {
    return _delegate(msg.sender, delegatee);
  }

  /**
  * @notice Delegates votes from signatory to `delegatee`
  * @param delegatee The address to delegate votes to
  * @param nonce The contract state required to match the signature
  * @param expiry The time at which to expire the signature
  * @param v The recovery byte of the signature
  * @param r Half of the ECDSA signature pair
  * @param s Half of the ECDSA signature pair
  */
  function delegateBySig(
    address delegatee,
    uint nonce,
    uint expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 domainSeparator = keccak256(
      abi.encode(
        DOMAIN_TYPEHASH,
        keccak256(bytes(name())),
        getChainId(),
        address(this)
      )
    );

    bytes32 structHash = keccak256(
      abi.encode(
        DELEGATION_TYPEHASH,
        delegatee,
        nonce,
        expiry
      )
    );

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        domainSeparator,
        structHash
      )
    );

    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "BeanBang::delegateBySig:: invalid signature");
    require(nonce == nonces[signatory]++, "BeanBang::delegateBySig:: invalid nonce");
    require(now <= expiry, "BeanBang::delegateBySig:: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
  * @notice Gets the current votes balance for `account`
  * @param account The address to get votes balance
  * @return The number of current votes for `account`
  */
  function getCurrentVotes(address account)
    external
    view
    returns (uint256)
  {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
  * @notice Determine the prior number of votes for an account as of a block number
  * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
  * @param account The address of the account to check
  * @param blockNumber The block number to get the vote balance at
  * @return The number of votes the account had as of the given block
  */
  function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256) {
    require(blockNumber < block.number, "BeanBang::getPriorVotes:: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = _delegates[delegator];
    uint256 delegatorBalance = balanceOf(delegator); // balance of underlying BEANs (not scaled);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        // decrease old representative
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint256 srcRepNew = srcRepOld.sub(amount);
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        // increase new representative
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint256 dstRepNew = dstRepOld.add(amount);
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint256 oldVotes,
    uint256 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "BeanBang::_writeCheckpoint:: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function getChainId() internal pure returns (uint) {
    uint256 chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}