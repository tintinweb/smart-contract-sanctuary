// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IBoosterConfig.sol";
import "./ILatteNFT.sol";

contract BoosterConfig is IBoosterConfig, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

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

  mapping(address => mapping(uint256 => BoosterEnergyInfo)) internal _boosterEnergyInfo;
  mapping(address => mapping(uint256 => CategoryEnergyInfo)) internal _categoryEnergyInfo;

  mapping(address => mapping(address => mapping(uint256 => bool))) internal _boosterNftAllowance;
  mapping(address => mapping(address => mapping(uint256 => bool))) internal _categoryNftAllowance;

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

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
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
    BoosterEnergyInfo memory boosterInfo = _boosterEnergyInfo[_nftAddress][_nftTokenId];
    // if there is no preset booster energy info, use preset in category info
    // presume that it's not a preminted nft
    if (boosterInfo.updatedAt == 0) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryInfo = _categoryEnergyInfo[_nftAddress][categoryId];
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
    BoosterEnergyInfo storage energy = _boosterEnergyInfo[_nftAddress][_nftTokenId];

    if (energy.updatedAt == 0) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      CategoryEnergyInfo memory categoryEnergy = _categoryEnergyInfo[_nftAddress][categoryId];
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
    _boosterEnergyInfo[_param.nftAddress][_param.nftTokenId] = BoosterEnergyInfo({
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
    _categoryEnergyInfo[_param.nftAddress][_param.nftCategoryId] = CategoryEnergyInfo({
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
      _categoryNftAllowance[_param.stakingToken][_param.allowance[i].nftAddress][
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
      _boosterNftAllowance[_param.stakingToken][_param.allowance[i].nftAddress][_param.allowance[i].nftTokenId] = _param
        .allowance[i]
        .allowance;

      emit SetBoosterNFTAllowance(
        _param.stakingToken,
        _param.allowance[i].nftAddress,
        _param.allowance[i].nftTokenId,
        _param.allowance[i].allowance
      );
    }
  }

  /// @notice use for checking whether or not this nft supports an input stakeToken
  /// @dev if not support when checking with token, need to try checking with category level (_categoryNftAllowance) as well since there should not be _boosterNftAllowance in non-preminted nft
  function boosterNftAllowance(
    address _stakeToken,
    address _nftAddress,
    uint256 _nftTokenId
  ) external view override returns (bool) {
    if (!_boosterNftAllowance[_stakeToken][_nftAddress][_nftTokenId]) {
      uint256 categoryId = ILatteNFT(_nftAddress).latteNFTToCategory(_nftTokenId);
      return _categoryNftAllowance[_stakeToken][_nftAddress][categoryId];
    }
    return true;
  }
}