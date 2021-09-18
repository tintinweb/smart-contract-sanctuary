// SPDX-License-Identifier: GPL-3.0
//        .-.                               .-.
//       / (_)         /      /       .--.-'
//      /      .-. ---/------/---.-. (  (_)`)    (  .-.   .-.
//     /      (  |   /      /  ./.-'_ `-.  /  .   )(  |   /  )
//  .-/.    .-.`-'-'/      /   (__.'_    )(_.' `-'  `-'-'/`-'
// (_/ `-._.                       (_.--'               /

pragma solidity 0.6.12;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IWETH.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

import "./IMasterBarista.sol";
import "./IMasterBaristaCallback.sol";
import "./IBoosterConfig.sol";
import "./IWNativeRelayer.sol";

import "./ECDSA.sol";
import "./SafeToken.sol";

contract Booster is
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  AccessControlUpgradeable,
  IMasterBaristaCallback,
  IERC721Receiver
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  // keccak256(abi.encodePacked("I am an EOA"))
  bytes32 public constant SIGNATURE_HASH = 0x08367bb0e0d2abf304a79452b2b95f4dc75fda0fc6df55dca6e5ad183de10cf0;

  IMasterBarista public masterBarista;
  IBoosterConfig public boosterConfig;
  IERC20Upgradeable public latte;
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
  event Stake(address indexed staker, IERC20Upgradeable indexed stakeToken, uint256 amount);
  event Unstake(address indexed unstaker, IERC20Upgradeable indexed stakeToken, uint256 amount);
  event Harvest(address indexed harvester, IERC20Upgradeable indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed caller, IERC20Upgradeable indexed stakeToken, uint256 amount);
  event MasterBaristaCall(
    address indexed user,
    uint256 extraReward,
    address stakeToken,
    uint256 prevEnergy,
    uint256 currentEnergy
  );
  event Pause();
  event Unpause();

  function initialize(
    IERC20Upgradeable _latte,
    IMasterBarista _masterBarista,
    IBoosterConfig _boosterConfig,
    IWNativeRelayer _wNativeRelayer,
    address _wNative
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    PausableUpgradeable.__Pausable_init();
    AccessControlUpgradeable.__AccessControl_init();

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
  function _withdrawFromMasterBarista(IERC20Upgradeable _stakeToken, uint256 _shares) internal {
    if (_shares == 0) return;
    if (address(_stakeToken) == address(latte)) {
      masterBarista.withdrawLatte(_msgSender(), _shares);
    } else {
      masterBarista.withdraw(_msgSender(), address(_stakeToken), _shares);
    }
  }

  /// @dev Internal function for harvest a reward from a master barista
  /// @param _stakeToken specified stake token
  function _harvestFromMasterBarista(address user, IERC20Upgradeable _stakeToken) internal {
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
    uint256 _nftTokenId,
    bytes calldata _sig
  )
    external
    whenNotPaused
    isStakeTokenOK(_stakeToken)
    isBoosterNftOK(_stakeToken, _nftAddress, _nftTokenId)
    nonReentrant
    permit(_sig)
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
    _harvestFromMasterBarista(_msgSender(), IERC20Upgradeable(_stakeToken));

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
  function unstakeNFT(address _stakeToken, bytes calldata _sig)
    external
    whenNotPaused
    isStakeTokenOK(_stakeToken)
    nonReentrant
    permit(_sig)
  {
    _unstakeNFT(_stakeToken);
  }

  /// @dev avoid stack-too-deep by branching the function
  function _unstakeNFT(address _stakeToken) internal {
    NFTStakingInfo memory toBeSentBackNft = userStakingNFT[_stakeToken][_msgSender()];
    require(toBeSentBackNft.nftAddress != address(0), "Booster::stakeNFT:: no nft staked");

    _harvestFromMasterBarista(_msgSender(), IERC20Upgradeable(_stakeToken));

    userStakingNFT[_stakeToken][_msgSender()] = NFTStakingInfo({ nftAddress: address(0), nftTokenId: 0 });

    IERC721(toBeSentBackNft.nftAddress).safeTransferFrom(address(this), _msgSender(), toBeSentBackNft.nftTokenId);

    emit UnstakeNFT(_msgSender(), _stakeToken, toBeSentBackNft.nftAddress, toBeSentBackNft.nftTokenId);
  }

  /// @notice for staking a stakeToken and receive some rewards
  /// @param _stakeToken a specified stake token to be staked
  /// @param _amount amount to stake
  function stake(IERC20Upgradeable _stakeToken, uint256 _amount)
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
  function _unstake(IERC20Upgradeable _stakeToken, uint256 _amount) internal {
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
    _unstake(IERC20Upgradeable(_stakeToken), _amount);
  }

  /// @notice function for unstaking all portion of stakeToken and receive some rewards
  /// @dev similar to unstake with user's shares
  /// @param _stakeToken a specified stake token to be unstaked
  function unstakeAll(address _stakeToken) external whenNotPaused isStakeTokenOK(_stakeToken) nonReentrant {
    (uint256 userStakeAmount, , , ) = masterBarista.userInfo(address(_stakeToken), _msgSender());
    _unstake(IERC20Upgradeable(_stakeToken), userStakeAmount);
  }

  /// @notice function for harvesting the reward
  /// @param _stakeToken a specified stake token to be harvested
  function harvest(address _stakeToken) external whenNotPaused isStakeTokenOK(_stakeToken) nonReentrant {
    _harvestFromMasterBarista(_msgSender(), IERC20Upgradeable(_stakeToken));
  }

  /// @notice function for harvesting rewards in specified staking tokens
  /// @param _stakeTokens specified stake tokens to be harvested
  function harvest(address[] calldata _stakeTokens) external whenNotPaused nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      require(boosterConfig.stakeTokenAllowance(_stakeTokens[i]), "Booster::harvest::bad stake token");
      _harvestFromMasterBarista(_msgSender(), IERC20Upgradeable(_stakeTokens[i]));
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
    uint256 extraReward = MathUpgradeable.min(currentEnergy, unboostedReward.mul(boostBps).div(1e4));
    totalAccumBoostedReward[stakeToken] = totalAccumBoostedReward[stakeToken].add(extraReward);
    user.accumBoostedReward = user.accumBoostedReward.add(extraReward);
    uint256 newEnergy = currentEnergy.sub(extraReward);
    masterBarista.mintExtraReward(stakeToken, userAddr, extraReward, lastRewardBlock);
    boosterConfig.consumeEnergy(stakingNFT.nftAddress, stakingNFT.nftTokenId, extraReward);

    emit MasterBaristaCall(userAddr, extraReward, stakeToken, currentEnergy, newEnergy);
  }

  function _safeWrap(IERC20Upgradeable _quoteBep20, uint256 _amount) internal {
    if (msg.value != 0) {
      require(address(_quoteBep20) == wNative, "Booster::_safeWrap:: baseToken is not wNative");
      require(_amount == msg.value, "Booster::_safeWrap:: value != msg.value");
      IWETH(wNative).deposit{ value: msg.value }();
      return;
    }
    _quoteBep20.safeTransferFrom(_msgSender(), address(this), _amount);
  }

  function _safeUnwrap(
    IERC20Upgradeable _quoteBep20,
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
  function emergencyWithdraw(IERC20Upgradeable _stakeToken) external isStakeTokenOK(address(_stakeToken)) {
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