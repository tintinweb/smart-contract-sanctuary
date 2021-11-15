//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "../base/governance/Controllable.sol";
import "../base/interface/IBookkeeper.sol";
import "../base/interface/ISmartVault.sol";
import "../base/interface/IGovernable.sol";
import "../base/interface/IStrategy.sol";
import "./IPriceCalculator.sol";

contract ContractReader is IGovernable, Initializable, Controllable {
  using SafeMath for uint256;

  string public constant VERSION = "0";
  uint256 constant public PRECISION = 1e18;
  mapping(bytes32 => address) internal tools;

  function initialize(address _controller) public initializer {
    Controllable.initializeControllable(_controller);
  }

  event ToolAddressUpdated(address newValue);

  struct VaultInfo {
    address addr;
    string name;
    uint256 created;
    bool active;
    uint256 tvl;
    uint256 tvlUsdc;
    uint256 decimals;
    address underlying;
    address[] rewardTokens;
    uint256[] rewardTokensBal;
    uint256[] rewardTokensBalUsdc;
    uint256 duration;
    uint256[] rewardsApr;
    uint256 ppfsApr;
    uint256 users;

    // strategy
    address strategy;
    uint256 strategyCreated;
    string platform;
    address[] assets;
    address[] strategyRewards;
    bool strategyOnPause;
    uint256 earned;
  }

  struct UserInfo {
    address wallet;
    address vault;
    uint256 underlyingBalance;
    uint256 underlyingBalanceUsdc;
    uint256 depositedUnderlying;
    uint256 depositedUnderlyingUsdc;
    uint256 depositedShare;
    address[] rewardTokens;
    uint256[] rewards;
    uint256[] rewardsUsdc;
  }

  // **************************************************************
  // HEAVY QUERIES
  //***************************************************************

  function vaultInfos() public view returns (VaultInfo[] memory) {
    VaultInfo[] memory result = new VaultInfo[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultInfo(vaults()[i]);
    }
    return result;
  }

  function vaultInfo(address vault) public view returns (VaultInfo memory) {
    address strategy = ISmartVault(vault).strategy();
    VaultInfo memory v = VaultInfo(
      vault,
      vaultName(vault),
      vaultCreated(vault),
      vaultActive(vault),
      vaultTvl(vault),
      vaultTvlUsdc(vault),
      vaultDecimals(vault),
      vaultUnderlying(vault),
      vaultRewardTokens(vault),
      vaultRewardTokensBal(vault),
      vaultRewardTokensBalUsdc(vault),
      vaultDuration(vault),
      vaultRewardsApr(vault),
      vaultPpfsApr(vault),
      vaultUsers(vault),
      strategy,
      strategyCreated(strategy),
      strategyPlatform(strategy),
      strategyAssets(strategy),
      strategyRewardTokens(strategy),
      strategyPausedInvesting(strategy),
      strategyEarned(strategy)
    );

    return v;
  }

  function userInfos(address _user)
  public view returns (UserInfo[] memory) {
    UserInfo[] memory result = new UserInfo[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = userInfo(_user, vaults()[i]);
    }
    return result;
  }

  function userInfo(address _user, address _vault) public view returns (UserInfo memory) {
    address[] memory rewardTokens = ISmartVault(_vault).rewardTokens();
    uint256[] memory rewards = new uint256[](rewardTokens.length);
    for (uint256 i; i < rewardTokens.length; i++) {
      rewards[i] = ISmartVault(_vault).earned(rewardTokens[i], _user);
    }
    return UserInfo(
      _user,
      _vault,
      userUnderlyingBalance(_user, _vault),
      userUnderlyingBalanceUsdc(_user, _vault),
      userDepositedUnderlying(_user, _vault),
      userDepositedUnderlyingUsdc(_user, _vault),
      userDepositedShare(_user, _vault),
      rewardTokens,
      userRewards(_user, _vault),
      userRewardsUsdc(_user, _vault)
    );
  }

  struct VaultWithUserInfo {
    VaultInfo vault;
    UserInfo user;
  }

  function vaultWithUserInfos(address _user)
  public view returns (VaultWithUserInfo[] memory){
    VaultWithUserInfo[] memory result = new VaultWithUserInfo[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = VaultWithUserInfo(
        vaultInfo(vaults()[i]),
        userInfo(_user, vaults()[i])
      );
    }
    return result;
  }

  function vaultWithUserInfoPages(address _user, uint256 page, uint256 pageSize)
  public view returns (VaultWithUserInfo[] memory){

    uint256 size = vaults().length;
    require(size > 0, "empty vaults");

    uint256 totalPages = size / pageSize;
    if (totalPages * pageSize < size) {
      totalPages++;
    }

    if (page < 0) {
      page = uint256(0);
    } else if (page > totalPages) {
      page = totalPages;
    }

    uint256 start = Math.min(page * pageSize, size - 1);
    uint256 end = Math.min((start + pageSize), size);
    VaultWithUserInfo[] memory result = new VaultWithUserInfo[](end - start);
    for (uint256 i = start; i < end; i++) {
      result[i - start] = VaultWithUserInfo(
        vaultInfo(vaults()[i]),
        userInfo(_user, vaults()[i])
      );
    }
    return result;
  }


  // ********************** FIELDS ***********************

  // no decimals
  function vaultUsers(address _vault) public view returns (uint256){
    return IBookkeeper(bookkeeper()).vaultUsersQuantity(_vault);
  }

  function vaultName(address _vault) public view returns (string memory){
    return ERC20(_vault).name();
  }

  // no decimals
  function vaultCreated(address _vault) public view returns (uint256){
    return Controllable(_vault).created();
  }

  function vaultActive(address _vault) public view returns (bool){
    return ISmartVault(_vault).active();
  }

  // normalized precision
  function vaultTvl(address _vault) public view returns (uint256){
    return normalizePrecision(ERC20(_vault).totalSupply(), vaultDecimals(_vault));
  }

  // normalized precision
  function vaultTvlUsdc(address _vault) public view returns (uint256){
    uint256 underlyingPrice = getPrice(vaultUnderlying(_vault));
    return vaultTvl(_vault).mul(underlyingPrice).div(PRECISION);
  }

  function vaultDecimals(address _vault) public view returns (uint256){
    return uint256(ERC20(_vault).decimals());
  }

  function vaultUnderlying(address _vault) public view returns (address){
    return ISmartVault(_vault).underlying();
  }

  // no decimals
  function vaultDuration(address _vault) public view returns (uint256){
    return ISmartVault(_vault).duration();
  }

  function vaultRewardTokens(address _vault) public view returns (address[] memory){
    return ISmartVault(_vault).rewardTokens();
  }

  function vaultRewardTokensDecimals(address _vault) public view returns (uint256[] memory){
    uint256[] memory result = new uint256[](vaultRewardTokens(_vault).length);
    for (uint256 i; i < vaultRewardTokens(_vault).length; i++) {
      address rt = vaultRewardTokens(_vault)[i];
      result[i] = uint256(ERC20(rt).decimals());
    }
    return result;
  }

  // normalized precision
  function vaultRewardTokensBal(address _vault) public view returns (uint256[] memory){
    uint256[] memory result = new uint256[](vaultRewardTokens(_vault).length);
    for (uint256 i; i < vaultRewardTokens(_vault).length; i++) {
      address rt = vaultRewardTokens(_vault)[i];
      result[i] = normalizePrecision(ERC20(rt).balanceOf(_vault), ERC20(rt).decimals());
    }
    return result;
  }

  // normalized precision
  function vaultRewardTokensBalUsdc(address _vault) public view returns (uint256[] memory){
    uint256[] memory result = new uint256[](vaultRewardTokens(_vault).length);
    for (uint256 i; i < vaultRewardTokens(_vault).length; i++) {
      address rt = vaultRewardTokens(_vault)[i];
      uint256 rtPrice = getPrice(rt);
      uint256 bal = ERC20(rt).balanceOf(_vault).mul(rtPrice).div(PRECISION);
      result[i] = normalizePrecision(bal, ERC20(rt).decimals());
    }
    return result;
  }

  // normalized precision
  function vaultRewardsApr(address _vault) public view returns (uint256[] memory){
    ISmartVault vault = ISmartVault(_vault);
    uint256[] memory result = new uint256[](vault.rewardTokens().length);
    for (uint256 i; i < vault.rewardTokens().length; i++) {
      result[i] = computeRewardApr(_vault, vault.rewardTokens()[i]);
    }
    return result;
  }

  // normalized precision
  function computeRewardApr(address _vault, address rt) public view returns (uint256) {
    uint256 periodFinish = ISmartVault(_vault).periodFinishForToken(rt);
    uint256 tvlUsd = vaultTvlUsdc(_vault);
    uint256 rtPrice = getPrice(rt);

    // keep precision numbers
    uint256 rtBalanceUsd = ERC20(rt).balanceOf(_vault).mul(rtPrice).div(PRECISION);
    if (tvlUsd != 0 && rtBalanceUsd != 0 && periodFinish > block.timestamp) {
      uint256 duration = periodFinish.sub(block.timestamp);
      // amounts should have the same decimals
      tvlUsd = normalizePrecision(tvlUsd, vaultDecimals(_vault));
      rtBalanceUsd = normalizePrecision(rtBalanceUsd, ERC20(rt).decimals());

      return computeApr(tvlUsd, rtBalanceUsd, duration);
    } else {
      return 0;
    }
  }

  // https://www.investopedia.com/terms/a/apr.asp
  // TVL and rewards should be in the same currency and with the same decimals
  function computeApr(uint256 tvl, uint256 rewards, uint256 duration) public pure returns (uint256) {
    uint256 rewardsPerTvlRatio = rewards.mul(PRECISION).div(tvl).mul(PRECISION);
    return rewardsPerTvlRatio.mul(PRECISION).div(duration.mul(PRECISION).div(1 days))
    .mul(uint256(365)).mul(uint256(100)).div(PRECISION);
  }

  // normalized precision
  function vaultPpfsApr(address _vault) public view returns (uint256){
    return normalizePrecision(computePpfsApr(
        ISmartVault(_vault).getPricePerFullShare(),
        10 ** vaultDecimals(_vault),
        block.timestamp,
        vaultCreated(_vault)
      ), vaultDecimals(_vault));
  }

  // it is an experimental metric and shows very volatile value
  // normalized precision
  function vaultPpfsLastApr(address _vault) public view returns (uint256){
    IBookkeeper.PpfsChange memory lastPpfsChange = IBookkeeper(bookkeeper()).lastPpfsChange(_vault);
    // skip fresh vault
    if (lastPpfsChange.time == 0) {
      return 0;
    }
    return normalizePrecision(computePpfsApr(
        lastPpfsChange.value,
        lastPpfsChange.oldValue,
        lastPpfsChange.time,
        lastPpfsChange.oldTime
      ), vaultDecimals(_vault));
  }

  function computePpfsApr(uint256 ppfs, uint256 startPpfs, uint256 curTime, uint256 startTime)
  internal pure returns (uint256) {
    if (ppfs <= startPpfs) {
      return 0;
    }
    uint256 ppfsChange = ppfs.sub(startPpfs);
    uint256 timeChange = Math.max(curTime.sub(startTime), 1);
    return ppfsChange.mul(PRECISION).div(timeChange)
    .mul(uint256(1 days * 365)).mul(uint256(100)).div(PRECISION);
  }

  // no decimals
  function strategyCreated(address _strategy) public view returns (uint256){
    return Controllable(_strategy).created();
  }

  function strategyPlatform(address _strategy) public pure returns (string memory){
    return IStrategy(_strategy).platform();
  }

  function strategyAssets(address _strategy) public view returns (address[] memory){
    return IStrategy(_strategy).assets();
  }

  function strategyRewardTokens(address _strategy) public view returns (address[] memory){
    return IStrategy(_strategy).rewardTokens();
  }

  function strategyPausedInvesting(address _strategy) internal view returns (bool){
    return IStrategy(_strategy).pausedInvesting();
  }

  // normalized precision
  function strategyEarned(address _strategy) internal view returns (uint256){
    address targetToken = IController(controller()).rewardToken();
    return normalizePrecision(
      IBookkeeper(bookkeeper()).targetTokenEarned(_strategy),
      ERC20(targetToken).decimals()
    );
  }

  // normalized precision
  function userUnderlyingBalance(address _user, address _vault) public view returns (uint256) {
    return normalizePrecision(IERC20(vaultUnderlying(_vault)).balanceOf(_user), vaultDecimals(_vault));
  }

  // normalized precision
  function userUnderlyingBalanceUsdc(address _user, address _vault) public view returns (uint256) {
    uint256 underlyingPrice = getPrice(vaultUnderlying(_vault));
    return userUnderlyingBalance(_user, _vault).mul(underlyingPrice).div(PRECISION);
  }

  // normalized precision
  function userDepositedUnderlying(address _user, address _vault) public view returns (uint256) {
    return normalizePrecision(
      ISmartVault(_vault).underlyingBalanceWithInvestmentForHolder(_user),
      vaultDecimals(_vault)
    );
  }

  function userDepositedUnderlyingUsdc(address _user, address _vault)
  public view returns (uint256) {
    uint256 underlyingPrice = getPrice(vaultUnderlying(_vault));
    return userDepositedUnderlying(_user, _vault).mul(underlyingPrice).div(PRECISION);
  }

  // normalized precision
  function userDepositedShare(address _user, address _vault) public view returns (uint256) {
    return normalizePrecision(IERC20(_vault).balanceOf(_user), vaultDecimals(_vault));
  }

  // normalized precision
  function userRewards(address _user, address _vault) public view returns (uint256[] memory) {
    address[] memory rewardTokens = ISmartVault(_vault).rewardTokens();
    uint256[] memory rewards = new uint256[](rewardTokens.length);
    for (uint256 i; i < rewardTokens.length; i++) {
      rewards[i] = normalizePrecision(
        ISmartVault(_vault).earned(rewardTokens[i], _user),
        ERC20(rewardTokens[i]).decimals()
      );
    }
    return rewards;
  }

  // normalized precision
  function userRewardsUsdc(address _user, address _vault) public view returns (uint256[] memory) {
    address[] memory rewardTokens = ISmartVault(_vault).rewardTokens();
    uint256[] memory rewards = new uint256[](rewardTokens.length);
    for (uint256 i; i < rewardTokens.length; i++) {
      uint256 price = getPrice(rewardTokens[i]);
      rewards[i] = normalizePrecision(
        ISmartVault(_vault).earned(rewardTokens[i], _user).mul(price).div(PRECISION),
        ERC20(rewardTokens[i]).decimals()
      );
    }
    return rewards;
  }

  // ************ LISTS ********************

  function vaultUsersList() public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultUsers(vaults()[i]);
    }
    return result;
  }

  function vaultNamesList() public view returns (string[] memory) {
    string[] memory names = new string[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      names[i] = vaultName(vaults()[i]);
    }
    return names;
  }

  function vaultTvlsList() public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultTvl(vaults()[i]);
    }
    return result;
  }

  function vaultDecimalsList() public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultDecimals(vaults()[i]);
    }
    return result;
  }

  function vaultPlatformsList() public view returns (string[] memory) {
    string[] memory result = new string[](vaults().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = IStrategy(ISmartVault(vaults()[i]).strategy()).platform();
    }
    return result;
  }

  function vaultAssetsList() public view returns (address[][] memory) {
    address[][] memory result = new address[][](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = IStrategy(ISmartVault(vaults()[i]).strategy()).assets();
    }
    return result;
  }

  function vaultCreatedList() public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultCreated(vaults()[i]);
    }
    return result;
  }

  function vaultActiveList() public view returns (bool[] memory) {
    bool[] memory result = new bool[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultActive(vaults()[i]);
    }
    return result;
  }

  function vaultDurationList() public view returns (uint256[] memory){
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = vaultDuration(vaults()[i]);
    }
    return result;
  }

  function strategyCreatedList() public view returns (uint256[] memory){
    uint256[] memory result = new uint256[](strategies().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = strategyCreated(strategies()[i]);
    }
    return result;
  }

  function strategyPlatformList() public view returns (string[] memory){
    string[] memory result = new string[](strategies().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = strategyPlatform(strategies()[i]);
    }
    return result;
  }

  function strategyAssetsList() public view returns (address[][] memory){
    address[][] memory result = new address[][](strategies().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = strategyAssets(strategies()[i]);
    }
    return result;
  }

  function strategyRewardTokensList() public view returns (address[][] memory){
    address[][] memory result = new address[][](strategies().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = strategyRewardTokens(strategies()[i]);
    }
    return result;
  }

  function strategyPausedInvestingList() public view returns (bool[] memory){
    bool[] memory result = new bool[](strategies().length);
    for (uint256 i; i < strategies().length; i++) {
      result[i] = strategyPausedInvesting(strategies()[i]);
    }
    return result;
  }


  function userRewardsList(address _user, address _rewardToken) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](vaults().length);
    for (uint256 i; i < vaults().length; i++) {
      result[i] = ISmartVault(vaults()[i]).earned(_rewardToken, _user);
    }
    return result;
  }

  function vaults() public view returns (address[] memory){
    return IBookkeeper(bookkeeper()).vaults();
  }

  function strategies() public view returns (address[] memory){
    return IBookkeeper(bookkeeper()).strategies();
  }

  function isGovernance(address _contract) external override view returns (bool) {
    return IController(controller()).isGovernance(_contract);
  }

  function priceCalculator() public view returns (address) {
    return tools[keccak256(abi.encodePacked("calculator"))];
  }

  function bookkeeper() public view returns (address) {
    return tools[keccak256(abi.encodePacked("bookkeeper"))];
  }

  //noinspection NoReturn
  function getPrice(address _token) public view returns (uint256) {
    try IPriceCalculator(priceCalculator()).getPriceWithDefaultOutput(_token) returns (uint256 price){
      return price;
    } catch Error(string memory) {
      return 0;
    }
  }

  function normalizePrecision(uint256 amount, uint256 decimals) internal pure returns (uint256){
    return amount.mul(PRECISION).div(10 ** decimals);
  }

  // *********** GOVERNANCE ACTIONS *****************

  function setPriceCalculator(address newValue) public onlyGovernance {
    tools[keccak256(abi.encodePacked("calculator"))] = newValue;
    emit ToolAddressUpdated(newValue);
  }

  function setBookkeeper(address newValue) public onlyGovernance {
    tools[keccak256(abi.encodePacked("bookkeeper"))] = newValue;
    emit ToolAddressUpdated(newValue);
  }

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

pragma solidity ^0.7.0;

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
    constructor (string memory name_, string memory symbol_) {
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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interface/IController.sol";

/**
* 200 - vault does not exist
* 201 - only hard worker or governance can call this
* 202 - Not governance
* 203 - message sender is a contract and have not added to the white list
* 204 - Not reward distributor
* 205 - empty address
* 206 - Not controller
*/
abstract contract Controllable is Initializable {
  bytes32 internal constant _CONTROLLER_SLOT = 0x5165972ef41194f06c5007493031d0b927c20741adcb74403b954009fd2c3617;
  bytes32 internal constant _CREATED_SLOT = 0x6f55f470bdc9cb5f04223fd822021061668e4dccb43e8727b295106dc9769c8a;

  event UpdateController(address oldValue, address newValue);

  function initializeControllable(address _controller) public initializer {
    assert(_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.controllable.controller")) - 1));
    assert(_CREATED_SLOT == bytes32(uint256(keccak256("eip1967.controllable.created")) - 1));
    setController(_controller);
    setCreated(block.timestamp);
  }

  // ************ MODIFIERS **********************

  modifier onlyGovernance() {
    require(IController(controller()).isGovernance(msg.sender), "not governance");
    _;
  }

  modifier onlyControllerOrGovernance() {
    require(controller() == msg.sender || IController(controller()).isGovernance(msg.sender), "not controller");
    _;
  }

  /**
 *  Only smart contracts will be affected by this modifier
 *  If it is a contract it should be whitelisted
 */
  modifier onlyAllowedUsers() {
    require(IController(controller()).isAllowedUser(msg.sender), "not allowed");
    _;
  }

  modifier onlyRewardDistribution() {
    require(IController(controller()).isRewardDistributor(msg.sender), "only distr");
    _;
  }

  // ************* SETTERS/GETTERS *******************

  function controller() public view returns (address str) {
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setController(address _newController) internal {
    require(_newController != address(0), "zero address");
    emit UpdateController(controller(), _newController);
    bytes32 slot = _CONTROLLER_SLOT;
    assembly {
      sstore(slot, _newController)
    }
  }

  function created() public view returns (uint256 str) {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      str := sload(slot)
    }
  }

  function setCreated(uint256 _created) private {
    bytes32 slot = _CREATED_SLOT;
    assembly {
      sstore(slot, _created)
    }
  }

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function vaults() external view returns (address[] memory);

  function strategies() external view returns (address[] memory);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  function targetTokenEarned(address vault) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  function vaultUsersQuantity(address vault) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface ISmartVault {

  function setStrategy(address _strategy) external;

  function doHardWork() external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 reward) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFor(uint256 amount, address holder) external;

  function withdraw(uint256 numberOfShares) external;

  function exit() external;

  function getAllRewards() external;

  function getReward(address rt) external;

  function underlying() external view returns (address);

  function strategy() external view returns (address);

  function nextImplementation() external view returns (address);

  function futureStrategy() external view returns (address);

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function nextImplementationTimestamp() external view returns (uint256);

  function strategyUpdateTime() external view returns (uint256);

  function duration() external view returns (uint256);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function availableToInvestOut() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function rewardPerToken(address rt) external view returns (uint256);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function rewardTokensLength() external view returns (uint256);

  function active() external view returns (bool);

  function canUpdateStrategy(address _strategy) external view returns (bool);

  function rewardTokens() external view returns (address[] memory);

  function periodFinishForToken(address _rt) external view returns (uint256);

  function rewardRateForToken(address _rt) external view returns (uint256);

  function lastUpdateTimeForToken(address _rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address _rt) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address _rt, address account) external view returns (uint256);

  function rewardsForToken(address _rt, address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IGovernable {

  function isGovernance(address _contract) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IStrategy {

  // *************** GOVERNANCE ACTIONS **************
  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external pure returns (string memory);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IPriceCalculator {

  function getPrice(address token, address outputToken) external view returns (uint256);

  function getPriceWithDefaultOutput(address token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IController {

  function addVaultAndStrategy(address _vault, address _strategy) external;

  function addStrategy(address _strategy) external;

  function governance() external view returns (address);

  function bookkeeper() external view returns (address);

  function feeRewardForwarder() external view returns (address);

  function mintHelper() external view returns (address);

  function rewardToken() external view returns (address);

  function notifyHelper() external view returns (address);

  function psVault() external view returns (address);

  function whiteList(address _target) external view returns (bool);

  function vaults(address _target) external view returns (bool);

  function strategies(address _target) external view returns (bool);

  function psNumerator() external view returns (uint256);

  function psDenominator() external view returns (uint256);

  function isAllowedUser(address _adr) external view returns (bool);

  function isGovernance(address _adr) external view returns (bool);

  function isHardWorker(address _adr) external view returns (bool);

  function isRewardDistributor(address _adr) external view returns (bool);

  function isValidVault(address _vault) external view returns (bool);
}

