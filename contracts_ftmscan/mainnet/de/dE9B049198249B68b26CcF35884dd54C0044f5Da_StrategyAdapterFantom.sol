pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/Math.sol";
import "./upgradability/BaseUpgradeableStrategy.sol";
import "./interface/SushiBar.sol";
import "./interface/IMasterChef.sol";
import "./TAlphaToken.sol";
import "./interface/IVault.sol";
import "hardhat/console.sol";

contract AlphaStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _SLP_POOLID_SLOT = 0x8956ecb40f9dfb494a392437d28a65bb0ddc57b20a9b6274df098a6daa528a72;
  bytes32 internal constant _ONX_FARM_POOLID_SLOT = 0x1da1707f101f5a1bf84020973bd9ccafa38ae6f35fcff3e0f1f3590f13f665c0;

  address public onx;
  address public stakedOnx;
  address public sushi;
  address public xSushi;

  address public treasury;

  mapping(address => uint256) public userRewardDebt;

  uint256 public accRewardPerShare;
  uint256 public lastPendingReward;
  uint256 public curPendingReward;

  mapping(address => uint256) public userXSushiDebt;

  uint256 public accXSushiPerShare;
  uint256 public lastPendingXSushi;
  uint256 public curPendingXSushi;

  uint256 keepFee;
  uint256 keepFeeMax;

  TAlphaToken public tAlpha;

  constructor() public {
  }

  function initializeAlphaStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _slpRewardPool,
    uint256 _slpPoolID,
    address _onxFarmRewardPool,
    uint256 _onxFarmRewardPoolId,
    address _onx,
    address _stakedOnx,
    address _sushi,
    address _xSushi,
    address _tAlpha
  ) public initializer {
    assert(_SLP_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpPoolId")) - 1));
    assert(_ONX_FARM_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxFarmRewardPoolId")) - 1));

    BaseUpgradeableStrategy.initializeBaseUpgradeableStrategy(
      _storage,
      _underlying,
      _vault,
      _slpRewardPool,
      _sushi,
      _onxFarmRewardPool,
      _stakedOnx,
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(slpRewardPool()).poolInfo(_slpPoolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setSLPPoolId(_slpPoolID);
    _setOnxFarmPoolId(_onxFarmRewardPoolId);

    onx = _onx;
    sushi = _sushi;
    xSushi = _xSushi;
    stakedOnx = _stakedOnx;

    tAlpha = TAlphaToken(_tAlpha);

    treasury = address(0x252766CD49395B6f11b9F319DAC1c786a72f6537);
    keepFee = 10;
    keepFeeMax = 100;
  }

  // keep fee functions
  function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyGovernance {
    require(_feeMax > 0, "feeMax should be bigger than zero");
    require(_fee < _feeMax, "fee can't be bigger than feeMax");
    keepFee = _fee;
    keepFeeMax = _feeMax;
  }

  // Salvage functions
  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == onx || token == stakedOnx || token == sushi || token == underlying());
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  // Reward time based model functions

  modifier onlyVault() {
    require(msg.sender == vault(), "Not a vault");
    _;
  }

  function updateAccPerShare(address user) public onlyVault {
    updateAccSOnxPerShare(user);
    updateAccXSushiPerShare(user);
  }

  function updateAccSOnxPerShare(address user) internal {
    // For xOnx
    curPendingReward = pendingReward();
    uint256 totalSupply = IERC20(vault()).totalSupply();

    if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
      curPendingReward = 0;
      lastPendingReward = 0;
      accRewardPerShare = 0;
      userRewardDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accRewardPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingReward.sub(lastPendingReward);
    accRewardPerShare = accRewardPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateAccXSushiPerShare(address user) internal {
    // For XSushi
    curPendingXSushi = pendingXSushi();
    uint256 totalSupply = IERC20(vault()).totalSupply();

    if (lastPendingXSushi > 0 && curPendingXSushi < lastPendingXSushi) {
      curPendingXSushi = 0;
      lastPendingXSushi = 0;
      accXSushiPerShare = 0;
      userXSushiDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accXSushiPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingXSushi.sub(lastPendingXSushi);
    accXSushiPerShare = accXSushiPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateUserRewardDebts(address user) public onlyVault {
    userRewardDebt[user] = IERC20(vault()).balanceOf(user)
    .mul(accRewardPerShare)
    .div(1e36);

    userXSushiDebt[user] = IERC20(vault()).balanceOf(user)
    .mul(accXSushiPerShare)
    .div(1e36);
  }

  function pendingReward() public view returns (uint256) {
    return IERC20(stakedOnx).balanceOf(address(this));
  }

  function pendingXSushi() public view returns (uint256) {
    return IERC20(xSushi).balanceOf(address(this));
  }

  function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
    return (pendingSOnxOfUser(user), pendingXSushiOfUser(user));
  }

  function pendingXSushiOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault()).totalSupply();
    uint256 userBalance = IERC20(vault()).balanceOf(user);
    if (totalSupply == 0) return 0;

    // pending xSushi
    uint256 allPendingXSushi = pendingXSushi();
    if (allPendingXSushi < lastPendingXSushi) return 0;
    uint256 addedReward = allPendingXSushi.sub(lastPendingXSushi);
    uint256 newAccXSushiPerShare = accXSushiPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );
    uint256 _pendingXSushi = userBalance.mul(newAccXSushiPerShare).div(1e36).sub(
      userXSushiDebt[user]
    );

    return _pendingXSushi;
  }

  function pendingSOnxOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault()).totalSupply();
    uint256 userBalance = IERC20(vault()).balanceOf(user);
    if (totalSupply == 0) return 0;

    // pending sOnx
    uint256 allPendingReward = pendingReward();
    if (allPendingReward < lastPendingReward) return 0;
    uint256 addedReward = allPendingReward.sub(lastPendingReward);
    uint256 newAccRewardPerShare = accRewardPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );
    uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
      userRewardDebt[user]
    );

    return _pendingReward;
  }

  function withdrawReward(address user) public onlyVault {
    // withdraw pending SOnx
    uint256 _pending = IERC20(vault()).balanceOf(user)
      .mul(accRewardPerShare)
      .div(1e36)
      .sub(userRewardDebt[user]);
    uint256 _balance = IERC20(stakedOnx).balanceOf(address(this));
    if (_balance < _pending) {
      _pending = _balance;
    }

    // send reward to user
    IERC20(stakedOnx).safeTransfer(user, _pending);
    lastPendingReward = curPendingReward.sub(_pending);

    // withdraw pending XSushi
    uint256 _pendingXSushi = IERC20(vault()).balanceOf(user)
      .mul(accXSushiPerShare)
      .div(1e36)
      .sub(userXSushiDebt[user]);
    uint256 _xSushiBalance = IERC20(xSushi).balanceOf(address(this));
    if (_xSushiBalance < _pendingXSushi) {
      _pendingXSushi = _xSushiBalance;
    }

    // send reward to user
    IERC20(xSushi).safeTransfer(user, _pendingXSushi);
    lastPendingXSushi = curPendingXSushi.sub(_pendingXSushi);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitSLPRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(slpRewardPool()) != address(0)) {
      exitSLPRewardPool();
    }
    // _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(slpRewardPoolBalance(), needToWithdraw);
      IMasterChef(slpRewardPool()).withdraw(slpPoolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (slpRewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return slpRewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  // OnsenFarm functions - Sushiswap slp reward pool functions

  function slpRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(slpRewardPool()).userInfo(slpPoolId(), address(this));
  }

  function exitSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).withdraw(slpPoolId(), bal);
      }
  }

  function claimSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).withdraw(slpPoolId(), 0);
      }
  }

  function emergencyExitSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).emergencyWithdraw(slpPoolId());
      }
  }

  function enterSLPRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    if (entireBalance > 0) {
      IERC20(underlying()).safeApprove(slpRewardPool(), 0);
      IERC20(underlying()).safeApprove(slpRewardPool(), entireBalance);
      IMasterChef(slpRewardPool()).deposit(slpPoolId(), entireBalance);
    }
  }

  function stakeOnsenFarm() external onlyNotPausedInvesting restricted {
    enterSLPRewardPool();
  }

  // SushiBar Functions

  function stakeSushiBar() external onlyNotPausedInvesting restricted {
    claimSLPRewardPool();

    uint256 sushiRewardBalance = IERC20(sushi).balanceOf(address(this));
    if (!sell() || sushiRewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      // emit ProfitsNotCollected(sell(), sushiRewardBalance < sellFloor());
      return;
    }

    if (sushiRewardBalance == 0) {
      return;
    }

    IERC20(sushi).safeApprove(xSushi, 0);
    IERC20(sushi).safeApprove(xSushi, sushiRewardBalance);

    uint256 balanceBefore = IERC20(xSushi).balanceOf(address(this));

    SushiBar(xSushi).enter(sushiRewardBalance);

    uint256 balanceAfter = IERC20(xSushi).balanceOf(address(this));
    uint256 added = balanceAfter.sub(balanceBefore);

    if (added > 0) {
      uint256 fee = added.mul(keepFee).div(keepFeeMax);
      IERC20(xSushi).safeTransfer(treasury, fee);
    }
  }

  // Onx Farm Dummy Token Pool functions

  function _enterOnxFarmRewardPool() internal {
    uint256 bal = _onxFarmRewardPoolBalance();
    uint256 entireBalance = IERC20(vault()).totalSupply();
    if (bal == 0) {
      tAlpha.mint(address(this), entireBalance);
      IERC20(tAlpha).safeApprove(onxFarmRewardPool(), 0);
      IERC20(tAlpha).safeApprove(onxFarmRewardPool(), entireBalance);
      IMasterChef(onxFarmRewardPool()).deposit(onxFarmRewardPoolId(), entireBalance);
    }
  }

  function _onxFarmRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(onxFarmRewardPool()).userInfo(onxFarmRewardPoolId(), address(this));
  }

  function exitOnxFarmRewardPool() external restricted {
      uint256 bal = _onxFarmRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxFarmRewardPool()).withdraw(onxFarmRewardPoolId(), bal);
          tAlpha.burn(address(this), bal);
      }
  }

  function _claimXSushiRewardPool() internal {
      uint256 bal = _onxFarmRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxFarmRewardPool()).withdraw(onxFarmRewardPoolId(), 0);
      }
  }

  function stakeOnxFarm() external onlyNotPausedInvesting restricted {
    _enterOnxFarmRewardPool();
  }

  // Onx Priv Pool functions

  function stakeOnx() external onlyNotPausedInvesting restricted {
    _claimXSushiRewardPool();

    uint256 onxRewardBalance = IERC20(onx).balanceOf(address(this));

    uint256 stakedOnxRewardBalance = IERC20(onxStakingRewardPool()).balanceOf(address(this));

    if (!sell() || onxRewardBalance < sellFloor()) {
      return;
    }

    if (onxRewardBalance == 0) {
      return;
    }

    IERC20(onx).safeApprove(onxStakingRewardPool(), 0);
    IERC20(onx).safeApprove(onxStakingRewardPool(), onxRewardBalance);

    uint256 balanceBefore = IERC20(stakedOnx).balanceOf(address(this));
    SushiBar(onxStakingRewardPool()).enter(onxRewardBalance);
    uint256 balanceAfter = IERC20(stakedOnx).balanceOf(address(this));
    uint256 added = balanceAfter.sub(balanceBefore);

    if (added > 0) {
      uint256 fee = added.mul(keepFee).div(keepFeeMax);
      IERC20(stakedOnx).safeTransfer(treasury, fee);
    }
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setSLPPoolId(uint256 _value) internal {
    setUint256(_SLP_POOLID_SLOT, _value);
  }

  // onx masterchef rewards pool ID
  function _setOnxFarmPoolId(uint256 _value) internal {
    setUint256(_ONX_FARM_POOLID_SLOT, _value);
  }

  function slpPoolId() public view returns (uint256) {
    return getUint256(_SLP_POOLID_SLOT);
  }

  function onxFarmRewardPoolId() public view returns (uint256) {
    return getUint256(_ONX_FARM_POOLID_SLOT);
  }

  function setOnxTreasuryFundAddress(address _address) public onlyGovernance {
    treasury = _address;
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

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../ControllableInit.sol";
import "../interface/IController.sol";

contract BaseUpgradeableStrategy is ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public {
  }

  function initializeBaseUpgradeableStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _slpRewardPool,
    address _slpRewardToken,
    address _onxOnxFarmRewardPool,
    address _onxStakingRewardPool,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay
  ) public initializer {
    ControllableInit.initializeControllableInit(
      _storage
    );
    BaseUpgradeableStrategyStorage.initializeBaseUpgradeableStrategyStorage();

    _setUnderlying(_underlying);
    _setVault(_vault);
    _setSLPRewardPool(_slpRewardPool);
    _setSLPRewardToken(_slpRewardToken);
    _setOnxFarmRewardPool(_onxOnxFarmRewardPool);
    _setOnxStakingRewardPool(_onxStakingRewardPool);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setPausedInvesting(false);
  }
}

pragma solidity 0.7.3;

interface SushiBar {
  function enter(uint256 _amount) external;
  function leave(uint256 _share) external;
}

pragma solidity 0.7.3;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint256, uint256, uint256);
    function massUpdatePools() external;
    function add(uint256, address, bool) external;
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TAlphaToken is ERC20("TAlphaToken", "TALPHA"), Ownable {
  address private _minter;

  function minter() public view returns (address) {
    return _minter;
  }

  modifier onlyOwnerOrMinter() {
    require(owner() == _msgSender() || minter() == _msgSender(), "caller is not the owner or minter");
    _;
  }

  /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
  function mint(address _to, uint256 _amount) public onlyOwnerOrMinter {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyOwnerOrMinter {
    _burn(_from, _amount);
  }

  function setMinter(address __minter) public onlyOwner {
    _minter = __minter;
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.3;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function deposit(uint256 amountWei) external;
    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares) external;

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    function stakeOnsenFarm() external;
    function stakeSushiBar() external;
    function stakeOnxFarm() external;
    function stakeOnx() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BaseUpgradeableStrategyStorage is Initializable {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _SLP_REWARD_TOKEN_SLOT = 0x39f6508fa78bf0f8811208dd5eeef269668a89d1dc64bfffde1f9147d9071963;
  bytes32 internal constant _SLP_REWARD_POOL_SLOT = 0x38a0c4d4bce281b7791c697a1359747b8fbd89f22fbe5557828bf15a023175da;
  bytes32 internal constant _ONX_FARM_REWARD_POOL_SLOT = 0x24f4d5cb1e6d05c6fb88a551e1e1659fba608459340d9f45cc3171803a2b8552;
  bytes32 internal constant _ONX_STAKING_REWARD_POOL_SLOT = 0x9cb98b534f7a03048b0fe6d7d318ae0a1818bcdf1b23f010350af3399659d8cf;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  constructor() public {
  }

  function initializeBaseUpgradeableStrategyStorage() public initializer {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_SLP_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpRewardToken")) - 1));
    assert(_SLP_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpRewardPool")) - 1));
    assert(_ONX_FARM_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxXSushiFarmRewardPool")) - 1));
    assert(_ONX_STAKING_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxStakingRewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  // Sushiswap Onsen farm reward pool functions

  function _setSLPRewardPool(address _address) internal {
    setAddress(_SLP_REWARD_POOL_SLOT, _address);
  }

  function slpRewardPool() public view returns (address) {
    return getAddress(_SLP_REWARD_POOL_SLOT);
  }

  function _setSLPRewardToken(address _address) internal {
    setAddress(_SLP_REWARD_TOKEN_SLOT, _address);
  }

  function slpRewardToken() public view returns (address) {
    return getAddress(_SLP_REWARD_TOKEN_SLOT);
  }

  // Onx Farm Dummy Token Reward Pool Functions

  function _setOnxFarmRewardPool(address _address) internal {
    setAddress(_ONX_FARM_REWARD_POOL_SLOT, _address);
  }

  function onxFarmRewardPool() public view returns (address) {
    return getAddress(_ONX_FARM_REWARD_POOL_SLOT);
  }

  // Onx Staking Functions

  function _setOnxStakingRewardPool(address _address) internal {
    setAddress(_ONX_STAKING_REWARD_POOL_SLOT, _address);
  }

  function onxStakingRewardPool() public view returns (address) {
    return getAddress(_ONX_STAKING_REWARD_POOL_SLOT);
  }

  // ---

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

pragma solidity 0.7.3;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initializeControllableInit(address _storage) public initializer {
    GovernableInit.initializeGovernableInit(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

pragma solidity 0.7.3;

interface IController {
    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function hasVault(address _vault) external returns(bool);

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;
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

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
  }

  function initializeGovernableInit(address _store) public initializer {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

pragma solidity 0.7.3;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
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

pragma solidity 0.7.3;

import "./AlphaStrategy.sol";

contract Strategy is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      address(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58), // underlying wbtc/eth
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      21,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      12,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "../AlphaStrategy.sol";

contract StrategyEthUsdt is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      address(0x06da0fd433C1A5d7a4faa01111c044910A184553), // underlying usdt/eth
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      0,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      15,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "../AlphaStrategy.sol";

contract StrategyEthUsdc is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      address(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0), // underlying onx/eth
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      1,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      14,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "../AlphaStrategy.sol";

contract StrategyEthOnx is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      address(0x0652687E87a4b8b5370b05bc298Ff00d205D9B5f), // underlying onx/eth
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      282,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      13,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "../AlphaStrategy.sol";

contract StrategyEthOnx is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      address(0x1241F4a348162d99379A23E73926Cf0bfCBf131e), // underlying ankr/eth
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      281,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      17,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "../AlphaStrategy.sol";

contract StrategyCommon is AlphaStrategy {

  constructor() public {}

  function initialize(
    address _storage,
    address _vault,
    address _underlying,
    uint256 _slpPoolID,
    uint256 _onxPoolID,
    address _tAlpha
  ) public initializer {
    AlphaStrategy.initializeAlphaStrategy(
      _storage,
      _underlying,
      _vault,
      address(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd), // slpRewardPool - master chef contract
      _slpPoolID,  // SLP Pool id
      address(0x168F8469Ac17dd39cd9a2c2eAD647f814a488ce9), // onxFarmRewardPool
      _onxPoolID,
      address(0xE0aD1806Fd3E7edF6FF52Fdb822432e847411033), // onx
      address(0xa99F0aD2a539b2867fcfea47F7E71F240940B47c), // stakedOnx
      address(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2), // sushi
      address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272), // xSushi
      _tAlpha
    );
  }
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/SushiBar.sol";
import "./interface/IStakingRewards.sol";
import "../interface/IVault.sol";
import "hardhat/console.sol";

contract SingleStrategyPolygon is OwnableUpgradeable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public multisigWallet;
  address public treasury;
  address public rewardManager;

  mapping(address => uint256) public userDQuickDebt;

  uint256 public accDQuickPerShare;
  uint256 public lastPendingDQuick;
  uint256 public curPendingDQuick;

  mapping(address => uint256) public userRewardDebt;

  uint256 public accRewardPerShare;
  uint256 public lastPendingReward;
  uint256 public curPendingReward;

  uint256 keepFee;
  uint256 keepFeeMax;

  uint256 keepReward;
  uint256 keepRewardMax;

  address public vault;
  address public underlying;
  address public quickRewardPool;
  address public dQuick;
  address public externalRewardToken;
  bool public sell;

  address public dQuickExternalRewardsPool;

  constructor() public {
  }

  function initializeAlphaStrategy(
    address _multisigWallet,
    address _rewardManager,
    address _underlying,
    address _vault,
    address _quickRewardPool,
    address _dQuickExternalRewardsPool
  ) public initializer {
    underlying = _underlying;
    vault = _vault;
    quickRewardPool = _quickRewardPool;

    rewardManager = _rewardManager;

    dQuick = getRewardsToken(_quickRewardPool);
    dQuickExternalRewardsPool = _dQuickExternalRewardsPool;
    externalRewardToken = getRewardsToken(_dQuickExternalRewardsPool);

    sell = true;

    __Ownable_init();

    address _lpt;

    _lpt = IStakingRewards(_quickRewardPool).stakingToken();
    require(_lpt == underlying, "Pool Info does not match underlying");
    
    keepFee = 10;
    keepFeeMax = 100;

    keepReward = 10;
    keepRewardMax = 100;

    multisigWallet = _multisigWallet;

    treasury = address(0xc109a7ccC7413F19a3F6C4a3DD70868E69aAaAfc);
  }

  // keep fee functions
  function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyOwner {
    require(_feeMax > 0, "feeMax should be bigger than zero");
    require(_fee < _feeMax, "fee can't be bigger than feeMax");
    keepFee = _fee;
    keepFeeMax = _feeMax;
  }

  // keep reward functions
  function setKeepReward(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
    require(_feeMax > 0, "Reward feeMax should be bigger than zero");
    require(_fee < _feeMax, "Reward fee can't be bigger than feeMax");
    keepReward = _fee;
    keepRewardMax = _feeMax;
  }

  // Salvage functions
  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == underlying);
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyOwner {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  // Reward time based model functions

  modifier onlyVault() {
    require(msg.sender == vault, "Not a vault");
    _;
  }

  modifier onlyMultisig() {
    require(msg.sender == multisigWallet , "The sender has to be the multisig wallet");
    _;
  }

  modifier onlyMultisigOrOwner() {
    require(msg.sender == multisigWallet || msg.sender == owner() , "The sender has to be the multisig wallet or owner");
    _;
  }

  function setMultisig(address _wallet) public onlyMultisig {
    multisigWallet = _wallet;
  }

  function updateAccPerShare(address user) public onlyVault {
    updateAccDQuickPerShare(user);
    updateAccRewardPerShare(user);
  }

  function updateAccRewardPerShare(address user) internal {
    curPendingReward = pendingReward();
    uint256 totalSupply = IERC20(vault).totalSupply();

    if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
      curPendingReward = 0;
      lastPendingReward = 0;
      accRewardPerShare = 0;
      userRewardDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accRewardPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingReward.sub(lastPendingReward);
    accRewardPerShare = accRewardPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateAccDQuickPerShare(address user) internal {
    // For XSushi
    curPendingDQuick = pendingDQuick();
    uint256 totalSupply = IERC20(vault).totalSupply();

    if (lastPendingDQuick > 0 && curPendingDQuick < lastPendingDQuick) {
      curPendingDQuick = 0;
      lastPendingDQuick = 0;
      accDQuickPerShare = 0;
      userDQuickDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accDQuickPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingDQuick.sub(lastPendingDQuick);
    accDQuickPerShare = accDQuickPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateUserRewardDebts(address user) public onlyVault {
    userDQuickDebt[user] = IERC20(vault).balanceOf(user)
      .mul(accDQuickPerShare)
      .div(1e36);

    userRewardDebt[user] = IERC20(vault).balanceOf(user)
      .mul(accRewardPerShare)
      .div(1e36);
  }


  function pendingDQuick() public view returns (uint256) {
    uint256 dQuickBalance = IERC20(dQuick).balanceOf(address(this));
    // uint256 earnedDquick = IStakingRewards(quickRewardPool).earned(address(this));

    uint256 stakedDquick = IStakingRewards(dQuickExternalRewardsPool).balanceOf(address(this));

    return dQuickBalance.add(stakedDquick);
  }

  function pendingReward() public view returns (uint256) {
    uint256 balance = IERC20(externalRewardToken).balanceOf(address(this));

    // uint256 earnedToken = IStakingRewards(dQuickExternalRewardsPool).earned(address(this));
    return balance;
  }

  function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
    return (pendingDQuickOfUser(user), pendingRewardTokenOfUser(user));
  }

  function pendingDQuickOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault).totalSupply();
    uint256 userBalance = IERC20(vault).balanceOf(user);

    if (totalSupply == 0) return 0;

    // pending dQuick
    uint256 allPendingDQuick = pendingDQuick();

    if (allPendingDQuick < lastPendingDQuick) return 0;

    uint256 addedReward = allPendingDQuick.sub(lastPendingDQuick);

    uint256 newAccDQuickPerShare = accDQuickPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );

    uint256 _pendingDQuick = userBalance.mul(newAccDQuickPerShare).div(1e36).sub(
      userDQuickDebt[user]
    );

    return _pendingDQuick;
  }

  function pendingRewardTokenOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault).totalSupply();
    uint256 userBalance = IERC20(vault).balanceOf(user);

    if (totalSupply == 0) return 0;

    // pending RewardToken
    uint256 allPendingReward = pendingReward();
    if (allPendingReward < lastPendingReward) return 0;

    uint256 addedReward = allPendingReward.sub(lastPendingReward);

    uint256 newAccRewardPerShare = accRewardPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );

    uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
      userRewardDebt[user]
    );

    return _pendingReward;
  }

  function getPendingShare(address user, uint256 perShare, uint256 debt) internal returns (uint256 share) {
    uint256 current = IERC20(vault).balanceOf(user)
      .mul(perShare)
      .div(1e36);

    if(current < debt){
      return 0;
    }

    return current.sub(debt);
  }

  function withdrawReward(address user) public onlyVault {
    // withdraw pending dQuick
    uint256 _pendingDQuick = getPendingShare(user, accDQuickPerShare, userDQuickDebt[user]);

    uint256 _dQuickBalance = IERC20(dQuick).balanceOf(address(this));

    if (_dQuickBalance < _pendingDQuick) {
      uint256 remaining = _pendingDQuick.sub(_dQuickBalance);

      uint256 dQuckBalanceInRewardsPool = IStakingRewards(dQuickExternalRewardsPool).balanceOf(address(this));

      if(remaining > dQuckBalanceInRewardsPool){
        remaining = dQuckBalanceInRewardsPool;
      }

      IStakingRewards(dQuickExternalRewardsPool).withdraw(remaining);

      _dQuickBalance = IERC20(dQuick).balanceOf(address(this));
    }

    _pendingDQuick = MathUpgradeable.min(_dQuickBalance, _pendingDQuick);

    // send reward to user
    if(_pendingDQuick > 0 && _pendingDQuick <= curPendingDQuick) {
      IERC20(dQuick).safeTransfer(user, _pendingDQuick);

      lastPendingDQuick = curPendingDQuick.sub(_pendingDQuick);
    }

    // withdraw pending rewards token
    uint256 _pending = getPendingShare(user, accRewardPerShare, userRewardDebt[user]);

    uint256 _balance = IERC20(externalRewardToken).balanceOf(address(this));

    if (_balance < _pending) {
      getRewardForPool(dQuickExternalRewardsPool);

      _balance = IERC20(externalRewardToken).balanceOf(address(this));
    }

    _pending = MathUpgradeable.min(_balance, _pending);

    if(_pending > 0 && _pending <= curPendingReward){
      // send reward to user
      IERC20(externalRewardToken).safeTransfer(user, _pending);
      lastPendingReward = curPendingReward.sub(_pending);
    }
  }

  function getRewardsToken(address pool) public view returns (address token) {
    return IStakingRewards(pool).rewardsToken();
  }

  function withdrawAllToVault() public onlyVault {
    if (address(quickRewardPool) != address(0)) {
      exitQuickRewardPool();
    }

    IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
  }

  function withdrawToVault(uint256 amount) public onlyVault {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(quickRewardPoolBalance(), needToWithdraw);
      IStakingRewards(quickRewardPool).withdraw(toWithdraw);
    }

    IERC20(underlying).safeTransfer(vault, amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (quickRewardPool == address(0)) {
      return IERC20(underlying).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return quickRewardPoolBalance().add(IERC20(underlying).balanceOf(address(this)));
  }

  function quickRewardPoolBalance() internal view returns (uint256 bal) {
      bal = IStakingRewards(quickRewardPool).balanceOf(address(this));
  }


  function dQuickRewardPoolBalance() internal view returns (uint256 bal) {
    bal = IStakingRewards(dQuickExternalRewardsPool).balanceOf(address(this));
  }

  function exitQuickRewardPool() internal {
      uint256 bal = quickRewardPoolBalance();
      if (bal != 0) {
          IStakingRewards(quickRewardPool).exit();
      }
  }


  function exitDQuickRewardPool() internal {
    uint256 bal = dQuickRewardPoolBalance();
    if (bal != 0) {
      IStakingRewards(dQuickExternalRewardsPool).exit();
    }
  }

  function enterQuickRewardPool() internal {
    uint256 entireBalance = IERC20(underlying).balanceOf(address(this));
    if (entireBalance > 0) {
      IERC20(underlying).safeApprove(quickRewardPool, 0);
      IERC20(underlying).safeApprove(quickRewardPool, entireBalance);

      IStakingRewards(quickRewardPool).stake(entireBalance);
    }
  }

  function stakeQuickFarm() external {
    enterQuickRewardPool();
  }

  function withdrawFees(uint256 added, address token) internal{
    if (added != 0) {
      uint256 fee = added.mul(keepFee).div(keepFeeMax);
      IERC20(token).safeTransfer(treasury, fee);

      uint256 feeReward = added.mul(keepReward).div(keepRewardMax);
      IERC20(token).safeTransfer(rewardManager, feeReward);
    }
  }

  function getRewardForPool(address pool) internal {
    uint256 earned = IStakingRewards(pool).earned(address(this));

    if(earned != 0){
      address rewardToken = getRewardsToken(pool);

      uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));

      IStakingRewards(pool).getReward();

      uint256 balanceAfter = IERC20(rewardToken).balanceOf(address(this));

      uint256 added = balanceAfter.sub(balanceBefore);

      withdrawFees(added, rewardToken);
    }
  }

  function enterRewardPool() internal {
    getRewardForPool(quickRewardPool);

    uint256 entireBalance = IERC20(dQuick).balanceOf(address(this));

    if (entireBalance != 0) {
      IERC20(dQuick).safeApprove(dQuickExternalRewardsPool, 0);
      IERC20(dQuick).safeApprove(dQuickExternalRewardsPool, entireBalance);

      IStakingRewards(dQuickExternalRewardsPool).stake(entireBalance);
    }

    getRewardForPool(dQuickExternalRewardsPool);
  }

  function stakeExternalRewards() external {
    enterRewardPool();
  }

  function setDquickRewardsPool(address _dQuickExternalRewardsPool) public onlyMultisig {
    exitDQuickRewardPool();

    dQuickExternalRewardsPool = _dQuickExternalRewardsPool;
    externalRewardToken = getRewardsToken(_dQuickExternalRewardsPool);

    enterRewardPool();
  }

  function setOnxTreasuryFundAddress(address _address) public onlyMultisigOrOwner {
    treasury = _address;
  }

  function setRewardManagerAddress(address _address) public onlyMultisigOrOwner {
    rewardManager = _address;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

pragma solidity 0.7.3;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
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

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interface/IStrategy.sol";
import "../interface/IVault.sol";
import "../interface/IController.sol";
import "../interface/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../VaultStorage.sol";

contract OnxAlphaVaultPolygon is ERC20Upgradeable, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);

  address public treasury;

  constructor() public {}

  uint256 keepFee;
  uint256 keepFeeMax;

  function initialize(
    address _storage,
    address _underlying
  ) public initializer {
    __ERC20_init(
      string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initializeControllableInit(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    VaultStorage.initializeVaultStorage(
      _underlying,
      underlyingUnit
    );

    treasury = address(0x252766CD49395B6f11b9F319DAC1c786a72f6537);

    keepFee = 10;
    keepFeeMax = 10000;
  }

  // keep fee functions
  function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyGovernance {
    require(_feeMax > 0, "feeMax should be bigger than zero");
    require(_fee < _feeMax, "fee can't be bigger than feeMax");
    keepFee = _fee;
    keepFeeMax = _feeMax;
  }

  // override erc20 transfer function
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    super._transfer(sender, recipient, amount);

    IStrategy(strategy()).updateUserRewardDebts(sender);
    IStrategy(strategy()).updateUserRewardDebts(recipient);
  }

  function strategy() public view returns(address) {
    return _strategy();
  }

  function underlying() public view returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "undefined strategy");
    _;
  }

  function setStrategy(address _strategy) public onlyControllerOrGovernance {
    require(_strategy != address(0), "empty strategy");
    require(IStrategy(_strategy).underlying() == address(underlying()), "underlying not match");
    require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

    _setStrategy(_strategy);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  function stakeQuickFarm() whenStrategyDefined onlyControllerOrGovernance external {
    invest();
    IStrategy(strategy()).stakeQuickFarm();
  }

  function doHardWork() whenStrategyDefined public {
    invest();
    IStrategy(strategy()).stakeQuickFarm();
    IStrategy(strategy()).stakeExternalRewards();
  }
  
  function underlyingBalanceInVault() view public returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }
  
  function underlyingBalanceWithInvestment() view public returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }
  
  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }
  
  function invest() internal whenStrategyDefined {
    uint256 availableAmount = underlyingBalanceInVault();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }
  
  function deposit(uint256 amount) external defense {
    _deposit(amount, msg.sender, msg.sender);
  }
  
  function depositFor(uint256 amount, address holder) public defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) external {
    require(totalSupply() > 0, "no shares");

    // doHardWork at every withdraw
    if (address(strategy()) != address(0)) {
      doHardWork();
      IStrategy(strategy()).updateAccPerShare(msg.sender);
      IStrategy(strategy()).withdrawReward(msg.sender);
    }

    if (numberOfShares > 0) {
      uint256 totalSupply = totalSupply();
      _burn(msg.sender, numberOfShares);

      uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply);

      uint256 balanceInVault = underlyingBalanceInVault();

      if (underlyingAmountToWithdraw > balanceInVault) {
        // withdraw everything from the strategy to accurately check the share value
        if (numberOfShares == totalSupply) {
          IStrategy(strategy()).withdrawAllToVault();
        } else {
          uint256 missing = underlyingAmountToWithdraw.sub(balanceInVault);
          IStrategy(strategy()).withdrawToVault(missing);
        }
        // recalculate to improve accuracy
        underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
            .mul(numberOfShares)
            .div(totalSupply), underlyingBalanceInVault());
      }

      // Send withdrawal fee
      if (address(strategy()) != address(0)) {
        uint256 feeAmount = underlyingAmountToWithdraw.mul(keepFee).div(keepFeeMax);
        IERC20Upgradeable(underlying()).safeTransfer(IStrategy(strategy()).treasury(), feeAmount);
        underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(feeAmount);
      }

      IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

      // update the withdrawal amount for the holder
      emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    IStrategy(strategy()).updateUserRewardDebts(msg.sender);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(beneficiary != address(0), "holder undefined");
    // doHardWork at every deposit
    if (address(strategy()) != address(0)) {
      doHardWork();
      IStrategy(strategy()).updateAccPerShare(beneficiary);
      IStrategy(strategy()).withdrawReward(beneficiary);
    }


    if (amount > 0) {
      uint256 supply =  totalSupply();
      uint256 toMint = supply == 0
          ? amount
          : amount.mul(supply).div(underlyingBalanceWithInvestment());

      _mint(beneficiary, toMint);

      IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

      // update the contribution amount for the beneficiary
      emit Deposit(beneficiary, amount);
    }

    IStrategy(strategy()).updateUserRewardDebts(beneficiary);
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

pragma solidity 0.7.3;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function stakeQuickFarm() external;
    function stakeExternalRewards() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;

    function updateAccPerShare(address user) external;
    function updateUserRewardDebts(address user) external;
    function pendingDQuick() external view returns (uint256);
    function pendingDQuickOfUser(address user) external view returns (uint256);
    function withdrawReward(address user) external;
}

pragma solidity 0.7.3;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract VaultStorage is Initializable {
  bytes32 internal constant _STRATEGY_SLOT = 0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
  bytes32 internal constant _UNDERLYING_SLOT = 0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
  bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;

  constructor() public {
  }

  function initializeVaultStorage(
    address _underlying,
    uint256 _underlyingUnit
  ) public initializer {
    assert(_STRATEGY_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1));
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlying")) - 1));
    assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) - 1));
    _setUnderlying(_underlying);
    _setUnderlyingUnit(_underlyingUnit);
  }

  function _setStrategy(address _address) internal {
    setAddress(_STRATEGY_SLOT, _address);
  }

  function _strategy() internal view returns (address) {
    return getAddress(_STRATEGY_SLOT);
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    setUint256(_UNDERLYING_UNIT_SLOT, _value);
  }

  function _underlyingUnit() internal view returns (uint256) {
    return getUint256(_UNDERLYING_UNIT_SLOT);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private ______gap;
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./interface/IController.sol";
import "./interface/IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";

contract OnxAlphaVault is ERC20Upgradeable, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);

  constructor() public {}

  function initialize(
    address _storage,
    address _underlying
  ) public initializer {
    __ERC20_init(
      string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initializeControllableInit(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    VaultStorage.initializeVaultStorage(
      _underlying,
      underlyingUnit
    );
  }

  // override erc20 transfer function
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    super._transfer(sender, recipient, amount);
    IStrategy(strategy()).updateUserRewardDebts(sender);
    IStrategy(strategy()).updateUserRewardDebts(recipient);
  }

  function strategy() public view returns(address) {
    return _strategy();
  }

  function underlying() public view returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "undefined strategy");
    _;
  }

  function setStrategy(address _strategy) public onlyControllerOrGovernance {
    require(_strategy != address(0), "empty strategy");
    require(IStrategy(_strategy).underlying() == address(underlying()), "underlying not match");
    require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

    _setStrategy(_strategy);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
      // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  function stakeOnsenFarm() whenStrategyDefined onlyControllerOrGovernance external {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
  }

  function stakeSushiBar() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeSushiBar();
  }

  function stakeOnxFarm() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeOnxFarm();
  }

  function stakeOnx() whenStrategyDefined onlyControllerOrGovernance external {
    IStrategy(strategy()).stakeOnx();
  }

  function doHardWork() whenStrategyDefined public {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
    IStrategy(strategy()).stakeSushiBar();
    IStrategy(strategy()).stakeOnxFarm();
    IStrategy(strategy()).stakeOnx();
  }

  function doHardWorkXSushi() whenStrategyDefined public {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
    IStrategy(strategy()).stakeSushiBar();
  }

  function doHardWorkSOnx() whenStrategyDefined public {
    IStrategy(strategy()).stakeOnxFarm();
    IStrategy(strategy()).stakeOnx();
  }

  function underlyingBalanceInVault() view public returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }

  function underlyingBalanceWithInvestment() view public returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
    .mul(balanceOf(holder))
    .div(totalSupply());
  }

  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = underlyingBalanceInVault();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }

  function deposit(uint256 amount) external defense {
    _deposit(amount, msg.sender, msg.sender);
  }

  function depositFor(uint256 amount, address holder) public defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) external {
    require(totalSupply() > 0, "no shares");

    // doHardWork at every withdraw
    if (address(strategy()) != address(0)) {
      doHardWork();
    }

    IStrategy(strategy()).updateAccPerShare(msg.sender);
    IStrategy(strategy()).withdrawReward(msg.sender);

    if (numberOfShares > 0) {
      uint256 totalSupply = totalSupply();
      _burn(msg.sender, numberOfShares);

      uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
      .mul(numberOfShares)
      .div(totalSupply);
      if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
        // withdraw everything from the strategy to accurately check the share value
        if (numberOfShares == totalSupply) {
          IStrategy(strategy()).withdrawAllToVault();
        } else {
          uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
          IStrategy(strategy()).withdrawToVault(missing);
        }
        // recalculate to improve accuracy
        underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply), underlyingBalanceInVault());
      }

      // Send withdrawal fee
      if (address(strategy()) != address(0)) {
        uint256 feeAmount = underlyingAmountToWithdraw.mul(10).div(10000);
        IERC20Upgradeable(underlying()).safeTransfer(IStrategy(strategy()).treasury(), feeAmount);
        underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(feeAmount);
      }

      IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

      // update the withdrawal amount for the holder
      emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    IStrategy(strategy()).updateUserRewardDebts(msg.sender);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(beneficiary != address(0), "holder undefined");
    // doHardWork at every deposit
    if (address(strategy()) != address(0)) {
      doHardWork();
    }

    IStrategy(strategy()).updateAccPerShare(beneficiary);
    IStrategy(strategy()).withdrawReward(beneficiary);

    if (amount > 0) {
      uint256 toMint = totalSupply() == 0
      ? amount
      : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
      _mint(beneficiary, toMint);

      IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

      // update the contribution amount for the beneficiary
      emit Deposit(beneficiary, amount);
    }

    IStrategy(strategy()).updateUserRewardDebts(beneficiary);
  }
}

pragma solidity 0.7.3;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function stakeOnsenFarm() external;
    function stakeSushiBar() external;
    function stakeOnxFarm() external;
    function stakeOnx() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;
    function withdrawXSushiToStrategicWallet() external;

    function updateAccPerShare(address user) external;
    function updateUserRewardDebts(address user) external;
    function pendingReward() external view returns (uint256);
    function pendingRewardOfUser(address user) external view returns (uint256);
    function withdrawReward(address user) external;
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../IStrategy.sol";
import "../../interface/IVault.sol";
import "../../interface/IController.sol";
import "../../interface/IUpgradeSource.sol";
import "../../ControllableInit.sol";
import "../../VaultStorage.sol";


contract XBooAlphaVaultFantom is ERC20Upgradeable, ControllableInit, VaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);

    uint256 keepFee;
    uint256 keepFeeMax;

    constructor() public {}

    function initialize(
        address _storage,
        address _underlying
    ) public initializer {
        __ERC20_init(
            string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
            string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
        );
        _setupDecimals(ERC20Upgradeable(_underlying).decimals());

        ControllableInit.initializeControllableInit(
            _storage
        );

        uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
        VaultStorage.initializeVaultStorage(
            _underlying,
            underlyingUnit
        );

        keepFee = 10;
        keepFeeMax = 10000;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyGovernance {
        require(_feeMax > 0, "feeMax should be bigger than zero");
        require(_fee < _feeMax, "fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // override erc20 transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);

        IStrategy(strategy()).updateUserRewardDebts(sender);
        IStrategy(strategy()).updateUserRewardDebts(recipient);
    }

    function strategy() public view returns(address) {
        return _strategy();
    }

    function underlying() public view returns(address) {
        return _underlying();
    }

    function underlyingUnit() public view returns(uint256) {
        return _underlyingUnit();
    }

    modifier whenStrategyDefined() {
        require(address(strategy()) != address(0), "undefined strategy");
        _;
    }

    function setStrategy(address _strategy) public onlyControllerOrGovernance {
        require(_strategy != address(0), "empty strategy");
        require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

        _setStrategy(_strategy);

        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require(
            (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
            // then the requirement will pass
            !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
            "grey listed"  // make sure that it is not on our greyList.
        );
        _;
    }

    function stakeExternalRewards() whenStrategyDefined onlyControllerOrGovernance external {
        IStrategy(strategy()).stakeExternalRewards();
    }

    function doHardWork() whenStrategyDefined public {
        invest();
        IStrategy(strategy()).stakeExternalRewards();
    }

    function underlyingBalanceInVault() view public returns (uint256) {
        return IERC20Upgradeable(underlying()).balanceOf(address(this));
    }

    function underlyingBalanceWithInvestment() view public returns (uint256) {
        if (address(strategy()) == address(0)) {
            // initial state, when not set
            return underlyingBalanceInVault();
        }
        return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
    }

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return underlyingBalanceWithInvestment()
            .mul(balanceOf(holder))
            .div(totalSupply());
    }

    function rebalance() external onlyControllerOrGovernance {
        withdrawAll();
        invest();
    }

    function invest() internal whenStrategyDefined {
        uint256 availableAmount = underlyingBalanceInVault();
        if (availableAmount > 0) {
            IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
            emit Invest(availableAmount);
        }
    }

    function deposit(uint256 amount) external defense whenStrategyDefined {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address holder) public defense whenStrategyDefined {
        _deposit(amount, msg.sender, holder);
    }

    function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
        IStrategy(strategy()).withdrawAllToVault();
    }

    function withdraw(uint256 numberOfShares) whenStrategyDefined external {
        require(totalSupply() > 0, "no shares");

        // doHardWork at every withdraw
        doHardWork();

        IStrategy(strategy()).updateAccPerShare(msg.sender);
        IStrategy(strategy()).withdrawReward(msg.sender);

        if (numberOfShares > 0) {
            uint256 totalSupply = totalSupply();

            _burn(msg.sender, numberOfShares);

            uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
                .mul(numberOfShares)
                .div(totalSupply);

            if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
                // withdraw everything from the strategy to accurately check the share value
                if (numberOfShares == totalSupply) {
                    IStrategy(strategy()).withdrawAllToVault();
                } else {
                    uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
                    IStrategy(strategy()).withdrawToVault(missing);
                }
                // recalculate to improve accuracy
                underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
                    .mul(numberOfShares)
                    .div(totalSupply), underlyingBalanceInVault());
            }

            // Send withdrawal fee
            uint256 feeAmount = underlyingAmountToWithdraw.mul(keepFee).div(keepFeeMax);

            IERC20Upgradeable(underlying()).safeTransfer(IStrategy(strategy()).treasury(), feeAmount);

            underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(feeAmount);

            IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

            // update the withdrawal amount for the holder
            emit Withdraw(msg.sender, underlyingAmountToWithdraw);
        }

        IStrategy(strategy()).updateUserRewardDebts(msg.sender);
    }

    function _deposit(uint256 amount, address sender, address beneficiary) internal {
        require(beneficiary != address(0), "holder undefined");

        doHardWork();

        IStrategy(strategy()).updateAccPerShare(beneficiary);
        IStrategy(strategy()).withdrawReward(beneficiary);

        if (amount > 0) {
            uint256 toMint = totalSupply() == 0
                ? amount
                : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());

            _mint(beneficiary, toMint);

            IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

            // update the contribution amount for the beneficiary
            emit Deposit(beneficiary, amount);
        }

        IStrategy(strategy()).updateUserRewardDebts(beneficiary);
    }
}

pragma solidity 0.7.3;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function stakeBooFarm() external;
    function stakeXBoo() external;
    function stakeExternalRewards() external;

    function withdrawPendingTeamFund() external;
    function withdrawPendingTreasuryFund() external;

    function updateAccPerShare(address user) external;
    function updateUserRewardDebts(address user) external;
    function pendingXBoo() external view returns (uint256);
    function pendingXBooOfUser(address user) external view returns (uint256);
    function withdrawReward(address user) external;
}

pragma solidity 0.7.3;

import "./interface/IUpgradeSource.sol";
import "./upgradability/BaseUpgradeabilityProxy.sol";

contract VaultProxy is BaseUpgradeabilityProxy {

  constructor(address _implementation) public {
    _setImplementation(_implementation);
  }

  /**
  * The main logic. If the timer has elapsed and there is a schedule upgrade,
  * the governance can upgrade the vault
  */
  function upgrade() external {
    (bool should, address newImplementation) = IUpgradeSource(address(this)).shouldUpgrade();
    require(should, "Upgrade not scheduled");
    _upgradeTo(newImplementation);

    // the finalization needs to be executed on itself to update the storage of this proxy
    // it also needs to be invoked by the governance, not by address(this), so delegatecall is needed
    (bool success,) = address(this).delegatecall(
      abi.encodeWithSignature("finalizeUpgrade()")
    );

    require(success, "Issue when finalizing the upgrade");
  }

  function implementation() external view returns (address) {
    return _implementation();
  }
}

pragma solidity 0.7.3;

import './Proxy.sol';
import './Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(OpenZeppelinUpgradesAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

pragma solidity 0.7.3;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  receive () payable external {}

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

pragma solidity 0.7.3;

/**
 * Utility library of inline functions on addresses
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/utils/Address.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Address implementation from an openzeppelin version.
 */
library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IStrategy.sol";
import "../interface/IVault.sol";
import "../interface/IController.sol";
import "../interface/IUpgradeSource.sol";
import "../ControllableInit.sol";
import "../VaultStorage.sol";

contract OnxAlphaVaultFantom is ERC20Upgradeable, ControllableInit, VaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);

    uint256 keepFee;
    uint256 keepFeeMax;

    constructor() public {}

    function initialize(
        address _storage,
        address _underlying
    ) public initializer {
        __ERC20_init(
            string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
            string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
        );
        _setupDecimals(ERC20Upgradeable(_underlying).decimals());

        ControllableInit.initializeControllableInit(
            _storage
        );

        uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
        VaultStorage.initializeVaultStorage(
            _underlying,
            underlyingUnit
        );

        keepFee = 10;
        keepFeeMax = 10000;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyGovernance {
        require(_feeMax > 0, "feeMax should be bigger than zero");
        require(_fee < _feeMax, "fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // override erc20 transfer function
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);

        IStrategy(strategy()).updateUserRewardDebts(sender);
        IStrategy(strategy()).updateUserRewardDebts(recipient);
    }

    function strategy() public view returns(address) {
        return _strategy();
    }

    function underlying() public view returns(address) {
        return _underlying();
    }

    function underlyingUnit() public view returns(uint256) {
        return _underlyingUnit();
    }

    modifier whenStrategyDefined() {
        require(address(strategy()) != address(0), "undefined strategy");
        _;
    }

    function setStrategy(address _strategy) public onlyControllerOrGovernance {
        require(_strategy != address(0), "empty strategy");
        require(IStrategy(_strategy).underlying() == address(underlying()), "underlying not match");
        require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

        _setStrategy(_strategy);

        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
        IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
    }

    // Only smart contracts will be affected by this modifier
    modifier defense() {
        require(
            (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
            // then the requirement will pass
            !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
            "grey listed"  // make sure that it is not on our greyList.
        );
        _;
    }

    function stakeBooFarm() whenStrategyDefined onlyControllerOrGovernance external {
        invest();
        IStrategy(strategy()).stakeBooFarm();
    }

    function stakeXBoo() whenStrategyDefined onlyControllerOrGovernance external {
        IStrategy(strategy()).stakeXBoo();
    }

    function stakeExternalRewards() whenStrategyDefined onlyControllerOrGovernance external {
        IStrategy(strategy()).stakeExternalRewards();
    }

    function doHardWork() whenStrategyDefined public {
        invest();
        IStrategy(strategy()).stakeBooFarm();
        IStrategy(strategy()).stakeXBoo();
        IStrategy(strategy()).stakeExternalRewards();
    }

    function underlyingBalanceInVault() view public returns (uint256) {
        return IERC20Upgradeable(underlying()).balanceOf(address(this));
    }

    function underlyingBalanceWithInvestment() view public returns (uint256) {
        if (address(strategy()) == address(0)) {
            // initial state, when not set
            return underlyingBalanceInVault();
        }
        return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
    }

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return underlyingBalanceWithInvestment()
            .mul(balanceOf(holder))
            .div(totalSupply());
    }

    function rebalance() external onlyControllerOrGovernance {
        withdrawAll();
        invest();
    }

    function invest() internal whenStrategyDefined {
        uint256 availableAmount = underlyingBalanceInVault();
        if (availableAmount > 0) {
            IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
            emit Invest(availableAmount);
        }
    }

    function deposit(uint256 amount) external defense whenStrategyDefined {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address holder) public defense whenStrategyDefined {
        _deposit(amount, msg.sender, holder);
    }

    function withdrawAll() public onlyControllerOrGovernance whenStrategyDefined {
        IStrategy(strategy()).withdrawAllToVault();
    }

    function withdraw(uint256 numberOfShares) whenStrategyDefined external {
        require(totalSupply() > 0, "no shares");

        // doHardWork at every withdraw
        doHardWork();

        IStrategy(strategy()).updateAccPerShare(msg.sender);
        IStrategy(strategy()).withdrawReward(msg.sender);

        if (numberOfShares > 0) {
            uint256 totalSupply = totalSupply();

            _burn(msg.sender, numberOfShares);

            uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
                .mul(numberOfShares)
                .div(totalSupply);

            if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
                // withdraw everything from the strategy to accurately check the share value
                if (numberOfShares == totalSupply) {
                    IStrategy(strategy()).withdrawAllToVault();
                } else {
                    uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
                    IStrategy(strategy()).withdrawToVault(missing);
                }
                // recalculate to improve accuracy
                underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
                    .mul(numberOfShares)
                    .div(totalSupply), underlyingBalanceInVault());
            }

            // Send withdrawal fee
            uint256 feeAmount = underlyingAmountToWithdraw.mul(keepFee).div(keepFeeMax);

            IERC20Upgradeable(underlying()).safeTransfer(IStrategy(strategy()).treasury(), feeAmount);

            underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(feeAmount);

            IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

            // update the withdrawal amount for the holder
            emit Withdraw(msg.sender, underlyingAmountToWithdraw);
        }

        IStrategy(strategy()).updateUserRewardDebts(msg.sender);
    }

    function _deposit(uint256 amount, address sender, address beneficiary) internal {
        require(beneficiary != address(0), "holder undefined");

        doHardWork();

        IStrategy(strategy()).updateAccPerShare(beneficiary);
        IStrategy(strategy()).withdrawReward(beneficiary);

        if (amount > 0) {
            uint256 toMint = totalSupply() == 0
                ? amount
                : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());

            _mint(beneficiary, toMint);

            IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

            // update the contribution amount for the beneficiary
            emit Deposit(beneficiary, amount);
        }

        IStrategy(strategy()).updateUserRewardDebts(beneficiary);
    }
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interface/IController.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./Governable.sol";

contract Controller is IController, Governable {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    mapping (address => bool) public override greyList;

    // All vaults that we have
    mapping (address => bool) public vaults;

    modifier validVault(address _vault){
        require(vaults[_vault], "vault does not exist");
        _;
    }

    constructor(address _storage)
        Governable(_storage) public {
    }

    function hasVault(address _vault) external override returns (bool) {
      return vaults[_vault];
    }

    // Only smart contracts will be affected by the greyList.
    function addToGreyList(address _target) public onlyGovernance {
        greyList[_target] = true;
    }

    function removeFromGreyList(address _target) public onlyGovernance {
        greyList[_target] = false;
    }

    function addVaultAndStrategy(address _vault, address _strategy) external override onlyGovernance {
        require(_vault != address(0), "new vault shouldn't be empty");
        require(!vaults[_vault], "vault already exists");
        require(_strategy != address(0), "new strategy shouldn't be empty");

        vaults[_vault] = true;
        // adding happens while setting
        IVault(_vault).setStrategy(_strategy);
    }

    // transfers token in the controller contract to the governance
    function salvage(address _token, uint256 _amount) external override onlyGovernance {
        IERC20(_token).safeTransfer(governance(), _amount);
    }

    function salvageStrategy(address _strategy, address _token, uint256 _amount) external override onlyGovernance {
        // the strategy is responsible for maintaining the list of
        // salvagable tokens, to make sure that governance cannot come
        // in and take away the coins
        IStrategy(_strategy).salvage(governance(), _token, _amount);
    }
}

pragma solidity 0.7.3;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interface/SushiBar.sol";
import "../../interface/IMasterChef.sol";
import "../../interface/IVault.sol";
import "./IXBoo.sol";
import "hardhat/console.sol";

contract BooStrategyFantom is OwnableUpgradeable {

    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    address public treasury;
    address public rewardManager;
    address public multisigWallet;

    mapping(address => uint256) public userXBooDebt;

    uint256 public accXBooPerShare;
    uint256 public lastPendingXBoo;
    uint256 public curPendingXBoo;

    mapping(address => uint256) public userRewardDebt;

    uint256 public accRewardPerShare;
    uint256 public lastPendingReward;
    uint256 public curPendingReward;

    uint256 keepFee;
    uint256 keepFeeMax;

    uint256 keepReward;
    uint256 keepRewardMax;

    address public vault;
    address public boo;
    address public xBoo;

    address public xBooStakingMasterchef;
    uint256 public xBooStakingPoolId;
    address public secondRewardsToken;

    bool public sell;
    uint256 public sellFloor;

    constructor() public {
    }

    function initializeAlphaStrategy(
        address _multisigWallet,
        address _rewardManager,
        address _vault,
        address _boo,
        address _xboo,
        address _xBooStakingMasterchef,
        uint _xBooStakingPoolId
    ) public initializer {
        vault = _vault;
        sell = true;
        xBooStakingMasterchef = _xBooStakingMasterchef;
        xBooStakingPoolId = _xBooStakingPoolId;

        secondRewardsToken = getRewardsToken();

        rewardManager = _rewardManager;

        __Ownable_init();

        xBoo = _xboo;
        boo = _boo;

        treasury = address(0xe33e7ed4A378eCBaca8737c94DE923a35694A7e6);

        keepFee = 5;
        keepFeeMax = 100;

        keepReward = 5;
        keepRewardMax = 100;

        multisigWallet = _multisigWallet;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Treasury feeMax should be bigger than zero");
        require(_fee < _feeMax, "Treasury fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // keep reward functions
    function setKeepReward(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Reward feeMax should be bigger than zero");
        require(_fee < _feeMax, "Reward fee can't be bigger than feeMax");
        keepReward = _fee;
        keepRewardMax = _feeMax;
    }

    // Salvage functions
    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == boo || token == xBoo);
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyMultisigOrOwner {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }


    modifier onlyVault() {
        require(msg.sender == vault, "Not a vault");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisigWallet , "The sender has to be the multisig wallet");
        _;
    }

    modifier onlyMultisigOrOwner() {
        require(msg.sender == multisigWallet || msg.sender == owner() , "The sender has to be the multisig wallet or owner");
        _;
    }

    function setMultisig(address _wallet) public onlyMultisig {
        multisigWallet = _wallet;
    }

    function updateAccPerShare(address user) public onlyVault {
        updateAccXBooPerShare(user);
        updateAccRewardPerShare(user);
    }

    function updateAccRewardPerShare(address user) internal {
        curPendingReward = pendingReward();

        if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
            curPendingReward = 0;
            lastPendingReward = 0;
            accRewardPerShare = 0;
            userRewardDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accRewardPerShare = 0;
            return;
        }

        uint256 addedReward = curPendingReward.sub(lastPendingReward);
        accRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }

    function updateAccXBooPerShare(address user) internal {
        curPendingXBoo = pendingXBoo();

        if (lastPendingXBoo > 0 && curPendingXBoo < lastPendingXBoo) {
            curPendingXBoo = 0;
            lastPendingXBoo = 0;
            accXBooPerShare = 0;
            userXBooDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accXBooPerShare = 0;
            return;
        }

        uint256 addedReward = curPendingXBoo.sub(lastPendingXBoo);
        accXBooPerShare = accXBooPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }

    function updateUserRewardDebts(address user) public onlyVault {
        userXBooDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accXBooPerShare)
            .div(1e36);

        userRewardDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accRewardPerShare)
            .div(1e36);
    }

    function pendingXBoo() public view returns (uint256) {
        uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));

        uint256 totalDepositedBoo = IERC20(vault).totalSupply();
        uint256 totalInXBoo = IXBoo(xBoo).xBOOForBOO(totalDepositedBoo);

        uint256 xBooSum = xBooMasterChefBalance().add(xBooBalance);

        if(xBooSum > totalInXBoo){
            return xBooSum.sub(totalInXBoo);
        } else {
            return 0;
        }
    }

    function pendingReward() public view returns (uint256) {
        return IERC20(secondRewardsToken).balanceOf(address(this));
    }

    function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
        return (pendingXBooOfUser(user), pendingRewardTokenOfUser(user));
    }

    function pendingRewardTokenOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending RewardToken
        uint256 allPendingReward = pendingReward();
        if (allPendingReward < lastPendingReward) return 0;

        uint256 addedReward = allPendingReward.sub(lastPendingReward);

        uint256 newAccRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
            userRewardDebt[user]
        );

        return _pendingReward;
    }

    function pendingXBooOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending xBoo
        uint256 allPendingXBoo = pendingXBoo();

        if (allPendingXBoo < lastPendingXBoo) return 0;

        uint256 addedReward = allPendingXBoo.sub(lastPendingXBoo);

        uint256 newAccXBooPerShare = accXBooPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingXBoo = userBalance.mul(newAccXBooPerShare).div(1e36).sub(
            userXBooDebt[user]
        );

        return _pendingXBoo;
    }

    function getPendingShare(address user, uint256 perShare, uint256 debt) internal returns (uint256 share) {
        uint256 current = IERC20(vault).balanceOf(user)
            .mul(perShare)
            .div(1e36);

        if(current < debt){
            return 0;
        }

        return current
            .sub(debt);
    }

    function withdrawXBooFromSecondPool(uint256 needToWithdraw) internal {
        uint256 toWithdraw = MathUpgradeable.min(xBooMasterChefBalance(), needToWithdraw);
        IMasterChef(xBooStakingMasterchef).withdraw(xBooStakingPoolId, toWithdraw);
    }

    function withdrawReward(address user) public onlyVault {
        // withdraw pending xBoo
        uint256 _pendingXBoo = getPendingShare(user, accXBooPerShare, userXBooDebt[user]);

        uint256 _xBooBalance = IERC20(xBoo).balanceOf(address(this));

        if(_xBooBalance < _pendingXBoo){
            uint256 needToWithdraw = _pendingXBoo.sub(_xBooBalance);

            withdrawXBooFromSecondPool(needToWithdraw);

            _xBooBalance = IERC20(xBoo).balanceOf(address(this));
        }

        if (_xBooBalance < _pendingXBoo) {
            _pendingXBoo = _xBooBalance;
        }

        if(_pendingXBoo > 0 && curPendingXBoo > _pendingXBoo){
            // send reward to user
            IERC20(xBoo).safeTransfer(user, _pendingXBoo);
            lastPendingXBoo = curPendingXBoo.sub(_pendingXBoo);
        }

        // withdraw pending rewards token
        uint256 _pending = getPendingShare(user, accRewardPerShare, userRewardDebt[user]);

        uint256 _balance = IERC20(secondRewardsToken).balanceOf(address(this));

        if (_balance < _pending) {
            _pending = _balance;
        }

        if(_pending > 0 && curPendingReward > _pending){
            // send reward to user
            uint256 available = withdrawFees(_pending, secondRewardsToken);

            IERC20(secondRewardsToken).safeTransfer(user, available);

            lastPendingReward = curPendingReward.sub(_pending);
        }
    }

    function getRewardsToken() internal returns (address token) {
        address RewardToken;
        (RewardToken,,,) = IMasterChef(xBooStakingMasterchef).poolInfo(xBooStakingPoolId);
        return RewardToken;
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawAllToVault() public onlyVault {
        exitBooRewardPool();

        IERC20(boo).safeTransfer(vault, booBalance());
    }

    function booBalance() public view returns(uint256) {
        return IERC20(boo).balanceOf(address(this));
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawToVault(uint256 amount) public onlyVault {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = booBalance();

        if(amount > entireBalance){
            uint256 needToWithdrawBoo = amount.sub(entireBalance);
            uint256 needToWithdrawXBoo = IXBoo(xBoo).xBOOForBOO(needToWithdrawBoo);

            uint256 currentXBooBalance = xBooBalance();

            if(currentXBooBalance < needToWithdrawXBoo){
                uint256 diff = needToWithdrawXBoo.sub(currentXBooBalance);

                withdrawXBooFromSecondPool(diff);
            }

            SushiBar(xBoo).leave(MathUpgradeable.min(needToWithdrawXBoo, xBooBalance()));
        }


        IERC20(boo).safeTransfer(vault, MathUpgradeable.min(amount, entireBalance));
    }

    /*
    *   Note that we currently do not have a mechanism here to include the
    *   amount of reward that is accrued.
    */
    function investedUnderlyingBalance() external view returns (uint256) {
        return booBalanceInXboo().add(booBalance());
    }

    function xBooBalance() internal view returns (uint256 bal) {
        return IXBoo(xBoo).balanceOf(address(this));
    }

    function booBalanceInXboo() internal view returns (uint256 bal) {
        return IXBoo(xBoo).BOOBalance(address(this));
    }

    function exitBooRewardPool() internal {
        uint256 bal = xBooBalance();
        if (bal != 0) {
            SushiBar(xBoo).leave(bal);
        }
    }

    function xBooMasterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IMasterChef(xBooStakingMasterchef).userInfo(xBooStakingPoolId, address(this));
    }

    function exitRewardsForXBoo() internal {
        uint256 bal = xBooMasterChefBalance();

        if (bal != 0) {
            IMasterChef(xBooStakingMasterchef).withdraw(xBooStakingPoolId, bal);
        }
    }

    function withdrawFees(uint256 added, address token) internal returns(uint256) {
        if (added != 0) {
            uint256 fee = added.mul(keepFee).div(keepFeeMax);
            IERC20(token).safeTransfer(treasury, fee);

            uint256 feeReward = added.mul(keepReward).div(keepRewardMax);
            IERC20(token).safeTransfer(rewardManager, feeReward);

            return added.sub(fee).sub(feeReward);
        }

        return added;
    }

    function enterXBooRewardPool() internal {
        uint256 entireBalance = IERC20(xBoo).balanceOf(address(this));

        if (entireBalance != 0) {
            IERC20(xBoo).safeApprove(xBooStakingMasterchef, 0);
            IERC20(xBoo).safeApprove(xBooStakingMasterchef, entireBalance);

            IMasterChef(xBooStakingMasterchef).deposit(xBooStakingPoolId, entireBalance);
        }
    }

    function stakeExternalRewards() external {
        enterXBooRewardPool();
    }

    function setXBooStakingPoolId(uint256 _poolId) public onlyMultisig {
        exitRewardsForXBoo();

        xBooStakingPoolId = _poolId;
        secondRewardsToken = getRewardsToken();

        enterXBooRewardPool();
    }

    function setOnxTreasuryFundAddress(address _address) public onlyMultisigOrOwner {
        treasury = _address;
    }

    function setRewardManagerAddress(address _address) public onlyMultisigOrOwner {
        rewardManager = _address;
    }
}

pragma solidity 0.7.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXBoo is IERC20 {
    function BOOBalance(address _account) external view returns (uint256 booAmount_);
    function BOOForxBOO(uint256 _booAmount) external view returns (uint256 xBOOAmount_);
    function xBOOForBOO(uint256 _xBOOAmount) external view returns (uint256 booAmount_);
}

pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/SushiBar.sol";
import "../interface/IMasterChef.sol";
import "../interface/IVault.sol";
import "hardhat/console.sol";

contract AlphaStrategyFantom is OwnableUpgradeable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public treasury;
    address public rewardManager;
    address public multisigWallet;

    mapping(address => uint256) public userXBooDebt;

    uint256 public accXBooPerShare;
    uint256 public lastPendingXBoo;
    uint256 public curPendingXBoo;

    mapping(address => uint256) public userRewardDebt;

    uint256 public accRewardPerShare;
    uint256 public lastPendingReward;
    uint256 public curPendingReward;

    uint256 keepFee;
    uint256 keepFeeMax;

    uint256 keepReward;
    uint256 keepRewardMax;

    address public vault;
    address public underlying;
    address public masterChef;
    address public boo;
    address public xBoo;

    address public xBooStakingMasterchef;
    uint256 public xBooStakingPoolId;

    bool public sell;
    uint256 public sellFloor;

    uint256 public poolId;

    constructor() public {
    }

    function initializeAlphaStrategy(
        address _multisigWallet,
        address _rewardManager,
        address _underlying,
        address _vault,
        address _masterChef,
        uint256 _poolId,
        address _boo,
        address _xBoo,
        address _xBooStakingMasterchef,
        uint _xBooStakingPoolId
    ) public initializer {
        underlying = _underlying;
        vault = _vault;
        masterChef = _masterChef;
        sell = true;
        poolId = _poolId;
        xBooStakingMasterchef = _xBooStakingMasterchef;
        xBooStakingPoolId = _xBooStakingPoolId;

        rewardManager = _rewardManager;

        __Ownable_init();

        address _lpt;
        (_lpt,,,) = IMasterChef(_masterChef).poolInfo(poolId);
        require(_lpt == underlying, "Pool Info does not match underlying");

        boo = _boo;
        xBoo = _xBoo;

        treasury = address(0xe33e7ed4A378eCBaca8737c94DE923a35694A7e6);

        keepFee = 10;
        keepFeeMax = 100;

        keepReward = 15;
        keepRewardMax = 100;

        multisigWallet = _multisigWallet;
    }

    // keep fee functions
    function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Treasury feeMax should be bigger than zero");
        require(_fee < _feeMax, "Treasury fee can't be bigger than feeMax");
        keepFee = _fee;
        keepFeeMax = _feeMax;
    }

    // keep reward functions
    function setKeepReward(uint256 _fee, uint256 _feeMax) external onlyMultisigOrOwner {
        require(_feeMax > 0, "Reward feeMax should be bigger than zero");
        require(_fee < _feeMax, "Reward fee can't be bigger than feeMax");
        keepReward = _fee;
        keepRewardMax = _feeMax;
    }

    // Salvage functions
    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == boo || token == underlying);
    }

    /**
    * Salvages a token.
    */
    function salvage(address recipient, address token, uint256 amount) public onlyMultisigOrOwner {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }


    modifier onlyVault() {
        require(msg.sender == vault, "Not a vault");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisigWallet , "The sender has to be the multisig wallet");
        _;
    }

    modifier onlyMultisigOrOwner() {
        require(msg.sender == multisigWallet || msg.sender == owner() , "The sender has to be the multisig wallet or owner");
        _;
    }

    function setMultisig(address _wallet) public onlyMultisig {
        multisigWallet = _wallet;
    }

    function updateAccPerShare(address user) public onlyVault {
        updateAccXBooPerShare(user);
        updateAccRewardPerShare(user);
    }

    function updateAccRewardPerShare(address user) internal {
        curPendingReward = pendingReward();

        if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
            curPendingReward = 0;
            lastPendingReward = 0;
            accRewardPerShare = 0;
            userRewardDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accRewardPerShare = 0;
            return;
        }

        uint256 addedReward = curPendingReward.sub(lastPendingReward);
        accRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }

    function updateAccXBooPerShare(address user) internal {
        curPendingXBoo = pendingXBoo();

        if (lastPendingXBoo > 0 && curPendingXBoo < lastPendingXBoo) {
            curPendingXBoo = 0;
            lastPendingXBoo = 0;
            accXBooPerShare = 0;
            userXBooDebt[user] = 0;
            return;
        }

        uint256 totalSupply = IERC20(vault).totalSupply();

        if (totalSupply == 0) {
            accXBooPerShare = 0;
            return;
        }

        uint256 addedReward = curPendingXBoo.sub(lastPendingXBoo);
        accXBooPerShare = accXBooPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );
    }

    function updateUserRewardDebts(address user) public onlyVault {
        userXBooDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accXBooPerShare)
            .div(1e36);

        userRewardDebt[user] = IERC20(vault).balanceOf(user)
            .mul(accRewardPerShare)
            .div(1e36);
    }

    function pendingXBoo() public view returns (uint256) {
        uint256 xBooBalance = IERC20(xBoo).balanceOf(address(this));
        return xBooMasterChefBalance().add(xBooBalance);
    }

    function pendingReward() public view returns (uint256) {
        address rewardToken = getSecondRewardsToken();
        return IERC20(rewardToken).balanceOf(address(this));
    }

    function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
        return (pendingXBooOfUser(user), pendingRewardTokenOfUser(user));
    }

    function pendingRewardTokenOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending RewardToken
        uint256 allPendingReward = pendingReward();
        if (allPendingReward < lastPendingReward) return 0;

        uint256 addedReward = allPendingReward.sub(lastPendingReward);

        uint256 newAccRewardPerShare = accRewardPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
            userRewardDebt[user]
        );

        return _pendingReward;
    }

    function pendingXBooOfUser(address user) public view returns (uint256) {
        uint256 totalSupply = IERC20(vault).totalSupply();
        uint256 userBalance = IERC20(vault).balanceOf(user);
        if (totalSupply == 0) return 0;

        // pending xBoo
        uint256 allPendingXBoo = pendingXBoo();

        if (allPendingXBoo < lastPendingXBoo) return 0;

        uint256 addedReward = allPendingXBoo.sub(lastPendingXBoo);

        uint256 newAccXBooPerShare = accXBooPerShare.add(
            (addedReward.mul(1e36)).div(totalSupply)
        );

        uint256 _pendingXBoo = userBalance.mul(newAccXBooPerShare).div(1e36).sub(
            userXBooDebt[user]
        );

        return _pendingXBoo;
    }

    function getPendingShare(address user, uint256 perShare, uint256 debt) internal returns (uint256) {
        uint256 current = IERC20(vault).balanceOf(user)
            .mul(perShare)
            .div(1e36);

        if(current < debt){
            return 0;
        }

        return current
            .sub(debt);
    }

    function withdrawReward(address user) public onlyVault {
        // withdraw pending xBoo
        uint256 _pendingXBoo = getPendingShare(user, accXBooPerShare, userXBooDebt[user]);

        uint256 _xBooBalance = IERC20(xBoo).balanceOf(address(this));

        if(_xBooBalance < _pendingXBoo){
            uint256 needToWithdraw = _pendingXBoo.sub(_xBooBalance);
            uint256 toWithdraw = Math.min(xBooMasterChefBalance(), needToWithdraw);

            IMasterChef(xBooStakingMasterchef).withdraw(xBooStakingPoolId, toWithdraw);

            _xBooBalance = IERC20(xBoo).balanceOf(address(this));
        }

        if (_xBooBalance < _pendingXBoo) {
            _pendingXBoo = _xBooBalance;
        }

        if(_pendingXBoo > 0 && curPendingXBoo > _pendingXBoo){
            // send reward to user
            IERC20(xBoo).safeTransfer(user, _pendingXBoo);
            lastPendingXBoo = curPendingXBoo.sub(_pendingXBoo);
        }

        // withdraw pending rewards token
        uint256 _pending = getPendingShare(user, accRewardPerShare, userRewardDebt[user]);

        address RewardToken = getSecondRewardsToken();

        uint256 _balance = IERC20(RewardToken).balanceOf(address(this));

        if (_balance < _pending) {
            _pending = _balance;
        }

        if(_pending > 0 && curPendingReward > _pending){
            // send reward to user
            IERC20(RewardToken).safeTransfer(user, _pending);
            lastPendingReward = curPendingReward.sub(_pending);
        }
    }

    function getSecondRewardsToken() public view returns (address token) {
        address RewardToken;
        (RewardToken,,,) = IMasterChef(xBooStakingMasterchef).poolInfo(xBooStakingPoolId);
        return RewardToken;
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawAllToVault() public onlyVault {
        if (address(masterChef) != address(0)) {
            exitBooRewardPool();
        }
        IERC20(underlying).safeTransfer(vault, IERC20(underlying).balanceOf(address(this)));
    }

    /*
    *   Withdraws all the asset to the vault
    */
    function withdrawToVault(uint256 amount) public onlyVault {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 entireBalance = IERC20(underlying).balanceOf(address(this));

        if(amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(masterChefBalance(), needToWithdraw);
            IMasterChef(masterChef).withdraw(poolId, toWithdraw);
        }

        IERC20(underlying).safeTransfer(vault, amount);
    }

    /*
    *   Note that we currently do not have a mechanism here to include the
    *   amount of reward that is accrued.
    */
    function investedUnderlyingBalance() external view returns (uint256) {
        if (masterChef == address(0)) {
            return IERC20(underlying).balanceOf(address(this));
        }
        // Adding the amount locked in the reward pool and the amount that is somehow in this contract
        // both are in the units of "underlying"
        // The second part is needed because there is the emergency exit mechanism
        // which would break the assumption that all the funds are always inside of the reward pool
        return masterChefBalance().add(IERC20(underlying).balanceOf(address(this)));
    }

    // OnsenFarm functions - Sushiswap slp reward pool functions

    function masterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IMasterChef(masterChef).userInfo(poolId, address(this));
    }

    function exitBooRewardPool() internal {
        uint256 bal = masterChefBalance();
        if (bal != 0) {
            IMasterChef(masterChef).withdraw(poolId, bal);
        }
    }

    function claimBooRewardPool() internal {
        uint256 bal = masterChefBalance();
        if (bal != 0) {
            IMasterChef(masterChef).withdraw(poolId, 0);
        }
    }

    function xBooMasterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IMasterChef(xBooStakingMasterchef).userInfo(xBooStakingPoolId, address(this));
    }

    function exitRewardsForXBoo() internal {
        uint256 bal = xBooMasterChefBalance();

        if (bal != 0) {
            IMasterChef(xBooStakingMasterchef).withdraw(xBooStakingPoolId, bal);
        }
    }

    function enterBooRewardPool() internal {
        uint256 entireBalance = IERC20(underlying).balanceOf(address(this));

        IERC20(underlying).safeApprove(masterChef, 0);
        IERC20(underlying).safeApprove(masterChef, entireBalance);
        IMasterChef(masterChef).deposit(poolId, entireBalance);
    }

    function enterXBooRewardPool() internal {
        uint256 entireBalance = IERC20(xBoo).balanceOf(address(this));

        IERC20(xBoo).safeApprove(xBooStakingMasterchef, 0);
        IERC20(xBoo).safeApprove(xBooStakingMasterchef, entireBalance);

        IMasterChef(xBooStakingMasterchef).deposit(xBooStakingPoolId, entireBalance);
    }

    function stakeBooFarm() external {
        enterBooRewardPool();
    }

    function stakeXBoo() external {
        claimBooRewardPool();

        uint256 booRewardBalance = IERC20(boo).balanceOf(address(this));
        if (!sell || booRewardBalance < sellFloor) {
            // Profits can be disabled for possible simplified and rapid exit
            // emit ProfitsNotCollected(sell, booRewardBalance < sellFloor);
            return;
        }

        if (booRewardBalance == 0) {
            return;
        }

        IERC20(boo).safeApprove(xBoo, 0);
        IERC20(boo).safeApprove(xBoo, booRewardBalance);

        uint256 balanceBefore = IERC20(xBoo).balanceOf(address(this));

        SushiBar(xBoo).enter(booRewardBalance);

        uint256 balanceAfter = IERC20(xBoo).balanceOf(address(this));
        uint256 added = balanceAfter.sub(balanceBefore);

        if (added > 0) {
            uint256 fee = added.mul(keepFee).div(keepFeeMax);
            IERC20(xBoo).safeTransfer(treasury, fee);

            uint256 feeReward = added.mul(keepReward).div(keepRewardMax);
            IERC20(xBoo).safeTransfer(rewardManager, feeReward);
        }
    }

    function stakeExternalRewards() external {
        enterXBooRewardPool();
    }

    function setXBooStakingPoolId(uint256 _poolId) public onlyMultisig {
        exitRewardsForXBoo();

        xBooStakingPoolId = _poolId;

        enterXBooRewardPool();
    }

    function setOnxTreasuryFundAddress(address _address) public onlyMultisigOrOwner {
        treasury = _address;
    }

    function setRewardManagerAddress(address _address) public onlyMultisigOrOwner {
        rewardManager = _address;
    }
}

pragma solidity 0.7.3;

import "./AlphaStrategyFantom.sol";

contract StrategyAdapterFantom is AlphaStrategyFantom {
    constructor() public {}

    function initialize(
        address _multisigWallet,
        address _rewardManager,
        address _vault,
        address _underlying,
        uint256 _poolId,
        uint256 _xBooStakingPoolId,
        address _xBooRewardsToken
    ) public initializer {
        AlphaStrategyFantom.initializeAlphaStrategy(
            _multisigWallet,
            _rewardManager,
            _underlying,
            _vault,
            address(0x2b2929E785374c651a81A63878Ab22742656DcDd), // SpookySwap masterchef
            _poolId,
            address(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE), // boo
            address(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598), // xBoo
            address(0x2352b745561e7e6FCD03c093cE7220e3e126ace0), // xBooFarmingMasterchef
            _xBooStakingPoolId // 2
        );
    }
}

pragma solidity 0.7.3;

import "./BooStrategyFantom.sol";

contract BooStrategyAdapterFantom is BooStrategyFantom {
    constructor() public {}

    function initialize(
        address _multisigWallet,
        address _rewardManager,
        address _vault,
        uint256 _xBooStakingPoolId
    ) public initializer {
        BooStrategyFantom.initializeAlphaStrategy(
            _multisigWallet,
            _rewardManager,
            _vault,
            address(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE), // boo
            address(0xa48d959AE2E88f1dAA7D5F611E01908106dE7598), // xBoo
            address(0x2352b745561e7e6FCD03c093cE7220e3e126ace0), // xBooFarmingMasterchef
            _xBooStakingPoolId // 2
        );
    }
}

pragma solidity 0.7.3;

import "./SingleStrategyPolygon.sol";

contract SingleStrategyAdapter is SingleStrategyPolygon {

  constructor() public {}

  function initialize(
    address _multisigWallet,
    address _rewardManager,
    address _vault,
    address _underlying,
    address _quickRewardPool
  ) public initializer {
    SingleStrategyPolygon.initializeAlphaStrategy(
      _multisigWallet,
      _rewardManager,
      _underlying,
      _vault,
      _quickRewardPool, // quickRewardPool
      address(0xd6Ce4f3D692C1c6684fb449993414C5c9E5D0073) // earn wMATIC for staked dQuick
    );
  }
}