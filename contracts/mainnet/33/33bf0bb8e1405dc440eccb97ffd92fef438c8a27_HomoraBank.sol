pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/cryptography/MerkleProof.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import './Governable.sol';
import '../interfaces/ICErc20.sol';

contract SafeBox is Governable, ERC20, ReentrancyGuard {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  event Claim(address user, uint amount);

  ICErc20 public immutable cToken;
  IERC20 public immutable uToken;

  address public relayer;
  bytes32 public root;
  mapping(address => uint) public claimed;

  constructor(
    ICErc20 _cToken,
    string memory _name,
    string memory _symbol
  ) public ERC20(_name, _symbol) {
    _setupDecimals(_cToken.decimals());
    IERC20 _uToken = IERC20(_cToken.underlying());
    __Governable__init();
    cToken = _cToken;
    uToken = _uToken;
    relayer = msg.sender;
    _uToken.safeApprove(address(_cToken), uint(-1));
  }

  function setRelayer(address _relayer) external onlyGov {
    relayer = _relayer;
  }

  function updateRoot(bytes32 _root) external {
    require(msg.sender == relayer || msg.sender == governor, '!relayer');
    root = _root;
  }

  function deposit(uint amount) external nonReentrant {
    uint uBalanceBefore = uToken.balanceOf(address(this));
    uToken.safeTransferFrom(msg.sender, address(this), amount);
    uint uBalanceAfter = uToken.balanceOf(address(this));
    uint cBalanceBefore = cToken.balanceOf(address(this));
    require(cToken.mint(uBalanceAfter.sub(uBalanceBefore)) == 0, '!mint');
    uint cBalanceAfter = cToken.balanceOf(address(this));
    _mint(msg.sender, cBalanceAfter.sub(cBalanceBefore));
  }

  function withdraw(uint amount) public nonReentrant {
    _burn(msg.sender, amount);
    uint uBalanceBefore = uToken.balanceOf(address(this));
    require(cToken.redeem(amount) == 0, '!redeem');
    uint uBalanceAfter = uToken.balanceOf(address(this));
    uToken.safeTransfer(msg.sender, uBalanceAfter.sub(uBalanceBefore));
  }

  function claim(uint totalReward, bytes32[] memory proof) public nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalReward));
    require(MerkleProof.verify(proof, root, leaf), '!proof');
    uint send = totalReward.sub(claimed[msg.sender]);
    claimed[msg.sender] = totalReward;
    uToken.safeTransfer(msg.sender, send);
    emit Claim(msg.sender, send);
  }

  function adminClaim(uint amount) external onlyGov {
    uToken.safeTransfer(msg.sender, amount);
  }

  function claimAndWithdraw(
    uint claimAmount,
    bytes32[] memory proof,
    uint withdrawAmount
  ) external {
    claim(claimAmount, proof);
    withdraw(withdrawAmount);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/proxy/Initializable.sol';

contract Governable is Initializable {
  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
  }
}

pragma solidity 0.6.12;

interface ICErc20 {
  function decimals() external returns (uint8);

  function underlying() external returns (address);

  function mint(uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function balanceOf(address user) external view returns (uint);

  function borrowBalanceCurrent(address account) external returns (uint);

  function borrowBalanceStored(address account) external view returns (uint);

  function borrow(uint borrowAmount) external returns (uint);

  function repayBorrow(uint repayAmount) external returns (uint);
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../../interfaces/IWERC20.sol';

contract WERC20 is ERC1155('WERC20'), ReentrancyGuard, IWERC20 {
  using SafeERC20 for IERC20;

  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint id) external view override returns (address) {
    address token = address(id);
    require(uint(token) == id, 'id overflow');
    return token;
  }

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  /// @dev Return the underlying ERC20 balance for the user.
  function balanceOfERC20(address token, address user) external view override returns (uint) {
    return balanceOf(user, uint(token));
  }

  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(address token, uint amount) external override nonReentrant {
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    _mint(msg.sender, uint(token), balanceAfter.sub(balanceBefore), '');
  }

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(address token, uint amount) external override nonReentrant {
    _burn(msg.sender, uint(token), amount);
    IERC20(token).safeTransfer(msg.sender, amount);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';

import './IERC20Wrapper.sol';

interface IWERC20 is IERC1155, IERC20Wrapper {
  /// @dev Return the underlying ERC20 balance for the user.
  function balanceOfERC20(address token, address user) external view returns (uint);

  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(address token, uint amount) external;

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(address token, uint amount) external;
}

pragma solidity 0.6.12;

interface IERC20Wrapper {
  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint id) external view returns (address);

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint id) external view returns (uint);
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/open[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IStakingRewards.sol';

contract WStakingRewards is ERC1155('WStakingRewards'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  address public immutable staking;
  address public immutable underlying;
  address public immutable reward;

  constructor(
    address _staking,
    address _underlying,
    address _reward
  ) public {
    staking = _staking;
    underlying = _underlying;
    reward = _reward;
    IERC20(_underlying).approve(_staking, uint(-1));
  }

  function getUnderlyingToken(uint) external view override returns (address) {
    return underlying;
  }

  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  function mint(uint amount) external nonReentrant returns (uint) {
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    IStakingRewards(staking).stake(amount);
    uint rewardPerToken = IStakingRewards(staking).rewardPerToken();
    _mint(msg.sender, rewardPerToken, amount, '');
    return rewardPerToken;
  }

  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    _burn(msg.sender, id, amount);
    IStakingRewards(staking).withdraw(amount);
    IStakingRewards(staking).getReward();
    IERC20(underlying).safeTransfer(msg.sender, amount);
    uint stRewardPerToken = id;
    uint enRewardPerToken = IStakingRewards(staking).rewardPerToken();
    uint stReward = stRewardPerToken.mul(amount).divCeil(1e18);
    uint enReward = enRewardPerToken.mul(amount).div(1e18);
    if (enReward > stReward) {
      IERC20(reward).safeTransfer(msg.sender, enReward.sub(stReward));
    }
    return enRewardPerToken;
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

library HomoraMath {
  using SafeMath for uint;

  function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.add(rhs).sub(1) / rhs;
  }

  function fmul(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.mul(rhs) / (2**112);
  }

  function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
    return lhs.mul(2**112) / rhs;
  }

  // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
  // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint x) internal pure returns (uint) {
    if (x == 0) return 0;
    uint xx = x;
    uint r = 1;

    if (xx >= 0x100000000000000000000000000000000) {
      xx >>= 128;
      r <<= 64;
    }

    if (xx >= 0x10000000000000000) {
      xx >>= 64;
      r <<= 32;
    }
    if (xx >= 0x100000000) {
      xx >>= 32;
      r <<= 16;
    }
    if (xx >= 0x10000) {
      xx >>= 16;
      r <<= 8;
    }
    if (xx >= 0x100) {
      xx >>= 8;
      r <<= 4;
    }
    if (xx >= 0x10) {
      xx >>= 4;
      r <<= 2;
    }
    if (xx >= 0x8) {
      r <<= 1;
    }

    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint r1 = x / r;
    return (r < r1 ? r : r1);
  }
}

pragma solidity 0.6.12;

interface IStakingRewards {
  function rewardPerToken() external view returns (uint);

  function stake(uint amount) external;

  function withdraw(uint amount) external;

  function getReward() external;
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../Governable.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/ICurveRegistry.sol';
import '../../interfaces/ILiquidityGauge.sol';

interface ILiquidityGaugeMinter {
  function mint(address gauge) external;
}

contract WLiquidityGauge is ERC1155('WLiquidityGauge'), ReentrancyGuard, IERC20Wrapper, Governable {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  struct GaugeInfo {
    ILiquidityGauge impl;
    uint accCrvPerShare;
  }

  ICurveRegistry public immutable registry;
  IERC20 public immutable crv;
  mapping(uint => mapping(uint => GaugeInfo)) public gauges;

  constructor(ICurveRegistry _registry, IERC20 _crv) public {
    __Governable__init();
    registry = _registry;
    crv = _crv;
  }

  function encodeId(
    uint pid,
    uint gid,
    uint crvPerShare
  ) public pure returns (uint id) {
    require(pid < (1 << 8), 'bad pid');
    require(gid < (1 << 8), 'bad gid');
    require(crvPerShare < (1 << 240), 'bad crv per share');
    return (pid << 248) | (gid << 240) | crvPerShare;
  }

  function decodeId(uint id)
    public
    pure
    returns (
      uint pid,
      uint gid,
      uint crvPerShare
    )
  {
    pid = id >> 248; // First 8 bits
    gid = (id >> 240) & (255); // Next 8 bits
    crvPerShare = id & ((1 << 240) - 1); // Last 240 bits
  }

  function getUnderlyingToken(uint id) external view override returns (address) {
    (uint pid, uint gid, ) = decodeId(id);
    ILiquidityGauge impl = gauges[pid][gid].impl;
    require(address(impl) != address(0), 'no gauge');
    return impl.lp_token();
  }

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  function registerGauge(uint pid, uint gid) external onlyGov {
    require(address(gauges[pid][gid].impl) == address(0), 'gauge already exists');
    address pool = registry.pool_list(pid);
    require(pool != address(0), 'no pool');
    (address[10] memory _gauges, ) = registry.get_gauges(pool);
    address gauge = _gauges[gid];
    require(gauge != address(0), 'no gauge');
    IERC20 lpToken = IERC20(ILiquidityGauge(gauge).lp_token());
    lpToken.approve(gauge, 0);
    lpToken.approve(gauge, uint(-1));
    gauges[pid][gid] = GaugeInfo({impl: ILiquidityGauge(gauge), accCrvPerShare: 0});
  }

  function mint(
    uint pid,
    uint gid,
    uint amount
  ) external nonReentrant returns (uint) {
    GaugeInfo storage gauge = gauges[pid][gid];
    ILiquidityGauge impl = gauge.impl;
    require(address(impl) != address(0), 'gauge not registered');
    mintCrv(gauge);
    IERC20 lpToken = IERC20(impl.lp_token());
    lpToken.safeTransferFrom(msg.sender, address(this), amount);
    impl.deposit(amount);
    uint id = encodeId(pid, gid, gauge.accCrvPerShare);
    _mint(msg.sender, id, amount, '');
    return id;
  }

  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    (uint pid, uint gid, uint stCrvPerShare) = decodeId(id);
    _burn(msg.sender, id, amount);
    GaugeInfo storage gauge = gauges[pid][gid];
    ILiquidityGauge impl = gauge.impl;
    require(address(impl) != address(0), 'gauge not registered');
    mintCrv(gauge);
    impl.withdraw(amount);
    IERC20(impl.lp_token()).safeTransfer(msg.sender, amount);
    uint stCrv = stCrvPerShare.mul(amount).divCeil(1e18);
    uint enCrv = gauge.accCrvPerShare.mul(amount).div(1e18);
    if (enCrv > stCrv) {
      crv.safeTransfer(msg.sender, enCrv.sub(stCrv));
    }
    return pid;
  }

  function mintCrv(GaugeInfo storage gauge) internal {
    ILiquidityGauge impl = gauge.impl;
    uint balanceBefore = crv.balanceOf(address(this));
    ILiquidityGaugeMinter(impl.minter()).mint(address(impl));
    uint balanceAfter = crv.balanceOf(address(this));
    uint gain = balanceAfter.sub(balanceBefore);
    uint supply = impl.balanceOf(address(this));
    if (gain > 0 && supply > 0) {
      gauge.accCrvPerShare = gauge.accCrvPerShare.add(gain.mul(1e18).div(supply));
    }
  }
}

pragma solidity 0.6.12;

interface ICurveRegistry {
  function get_n_coins(address lp) external view returns (uint);

  function pool_list(uint id) external view returns (address);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_gauges(address pool) external view returns (address[10] memory, uint128[10] memory);

  function get_lp_token(address pool) external view returns (address);

  function get_pool_from_lp_token(address lp) external view returns (address);
}

pragma solidity 0.6.12;

interface ILiquidityGauge {
  function minter() external view returns (address);

  function crv_token() external view returns (address);

  function lp_token() external view returns (address);

  function balanceOf(address addr) external view returns (uint);

  function deposit(uint value) external;

  function withdraw(uint value) external;
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IMasterChef.sol';

contract WMasterChef is ERC1155('WMasterChef'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  IMasterChef public immutable chef;
  IERC20 public immutable sushi;

  constructor(IMasterChef _chef) public {
    chef = _chef;
    sushi = IERC20(_chef.sushi());
  }

  function encodeId(uint pid, uint sushiPerShare) public pure returns (uint id) {
    require(pid < (1 << 16), 'bad pid');
    require(sushiPerShare < (1 << 240), 'bad sushi per share');
    return (pid << 240) | sushiPerShare;
  }

  function decodeId(uint id) public pure returns (uint pid, uint sushiPerShare) {
    pid = id >> 240; // First 16 bits
    sushiPerShare = id & ((1 << 240) - 1); // Last 240 bits
  }

  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  function getUnderlyingToken(uint id) external view override returns (address) {
    (uint pid, ) = decodeId(id);
    (address lpToken, , , ) = chef.poolInfo(pid);
    return lpToken;
  }

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  /// @dev Mint ERC1155 token for the given pool id.
  /// @return The token id that got minted.
  function mint(uint pid, uint amount) external nonReentrant returns (uint) {
    (address lpToken, , , ) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
    if (IERC20(lpToken).allowance(address(this), address(chef)) != uint(-1)) {
      // We only need to do this once per pool, as LP token's allowance won't decrease if it's -1.
      IERC20(lpToken).approve(address(chef), uint(-1));
    }
    chef.deposit(pid, amount);
    (, , , uint sushiPerShare) = chef.poolInfo(pid);
    uint id = encodeId(pid, sushiPerShare);
    _mint(msg.sender, id, amount, '');
    return id;
  }

  /// @dev Burn ERC1155 token to redeem LP ERC20 token back plus SUSHI rewards.
  /// @return The pool id that that you received LP token back.
  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    (uint pid, uint stSushiPerShare) = decodeId(id);
    _burn(msg.sender, id, amount);
    chef.withdraw(pid, amount);
    (address lpToken, , , uint enSushiPerShare) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
    uint stSushi = stSushiPerShare.mul(amount).divCeil(1e12);
    uint enSushi = enSushiPerShare.mul(amount).div(1e12);
    if (enSushi > stSushi) {
      sushi.safeTransfer(msg.sender, enSushi.sub(stSushi));
    }
    return pid;
  }

  /// @dev Burn ERC1155 token to redeem LP ERC20 token back without taking SUSHI rewards.
  /// @return The pool id that that you received LP token back.
  function emergencyBurn(uint id, uint amount) external nonReentrant returns (uint) {
    (uint pid, ) = decodeId(id);
    _burn(msg.sender, id, amount);
    chef.withdraw(pid, amount);
    (address lpToken, , , ) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
    return pid;
  }
}

pragma solidity 0.6.12;

interface IMasterChef {
  function sushi() external view returns (address);

  function poolInfo(uint pid)
    external
    view
    returns (
      address lpToken,
      uint allocPoint,
      uint lastRewardBlock,
      uint accSushiPerShare
    );

  function deposit(uint pid, uint amount) external;

  function withdraw(uint pid, uint amount) external;
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IUniswapV2Factory.sol';
import '../../interfaces/IUniswapV2Router02.sol';
import '../../interfaces/IUniswapV2Pair.sol';
import '../../interfaces/IWStakingRewards.sol';

contract UniswapV2SpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  IUniswapV2Factory public immutable factory;
  IUniswapV2Router02 public immutable router;

  mapping(address => mapping(address => address)) public pairs;

  constructor(
    IBank _bank,
    address _werc20,
    IUniswapV2Router02 _router
  ) public BasicSpell(_bank, _werc20, _router.WETH()) {
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
  }

  function getPair(address tokenA, address tokenB) public returns (address) {
    address lp = pairs[tokenA][tokenB];
    if (lp == address(0)) {
      lp = factory.getPair(tokenA, tokenB);
      require(lp != address(0), 'no lp token');
      ensureApprove(tokenA, address(router));
      ensureApprove(tokenB, address(router));
      ensureApprove(lp, address(router));
      pairs[tokenA][tokenB] = lp;
      pairs[tokenB][tokenA] = lp;
    }
    return lp;
  }

  /// @dev Compute optimal deposit amount
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  /// @dev Compute optimal deposit amount helper.
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  /// Formula: https://blog.alphafinance.io/byot/
  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');
    uint a = 997;
    uint b = uint(1997).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);
    uint d = a.mul(c).mul(4);
    uint e = HomoraMath.sqrt(b.mul(b).add(d));
    uint numerator = e.sub(b);
    uint denominator = a.mul(2);
    return numerator.div(denominator);
  }

  struct Amounts {
    uint amtAUser;
    uint amtBUser;
    uint amtLPUser;
    uint amtABorrow;
    uint amtBBorrow;
    uint amtLPBorrow;
    uint amtAMin;
    uint amtBMin;
  }

  function addLiquidityInternal(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);

    // 1. Get user input amounts
    doTransmitETH();
    doTransmit(tokenA, amt.amtAUser);
    doTransmit(tokenB, amt.amtBUser);
    doTransmit(lp, amt.amtLPUser);

    // 2. Borrow specified amounts
    doBorrow(tokenA, amt.amtABorrow);
    doBorrow(tokenB, amt.amtBBorrow);
    doBorrow(lp, amt.amtLPBorrow);

    // 3. Calculate optimal swap amount
    uint swapAmt;
    bool isReversed;
    {
      uint amtA = IERC20(tokenA).balanceOf(address(this));
      uint amtB = IERC20(tokenB).balanceOf(address(this));
      uint resA;
      uint resB;
      if (IUniswapV2Pair(lp).token0() == tokenA) {
        (resA, resB, ) = IUniswapV2Pair(lp).getReserves();
      } else {
        (resB, resA, ) = IUniswapV2Pair(lp).getReserves();
      }
      (swapAmt, isReversed) = optimalDeposit(amtA, amtB, resA, resB);
    }

    // 4. Swap optimal amount
    {
      address[] memory path = new address[](2);
      (path[0], path[1]) = isReversed ? (tokenB, tokenA) : (tokenA, tokenB);
      router.swapExactTokensForTokens(swapAmt, 0, path, address(this), now);
    }

    // 5. Add liquidity
    router.addLiquidity(
      tokenA,
      tokenB,
      IERC20(tokenA).balanceOf(address(this)),
      IERC20(tokenB).balanceOf(address(this)),
      amt.amtAMin,
      amt.amtBMin,
      address(this),
      now
    );
  }

  function addLiquidityWERC20(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Put collateral
    doPutCollateral(lp, IERC20(lp).balanceOf(address(this)));

    // 7. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
  }

  function addLiquidityWStakingRewards(
    address tokenA,
    address tokenB,
    Amounts calldata amt,
    address wstaking
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    address reward = IWStakingRewards(wstaking).reward();

    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
      bank.takeCollateral(wstaking, collId, collSize);
      IWStakingRewards(wstaking).burn(collId, collSize);
    }

    // 7. Put collateral
    ensureApprove(lp, wstaking);
    uint amount = IERC20(lp).balanceOf(address(this));
    uint id = IWStakingRewards(wstaking).mint(amount);
    if (!IWStakingRewards(wstaking).isApprovedForAll(address(this), address(bank))) {
      IWStakingRewards(wstaking).setApprovalForAll(address(bank), true);
    }
    bank.putCollateral(address(wstaking), id, amount);

    // 8. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);

    // 9. Refund reward
    doRefund(reward);
  }

  struct RepayAmounts {
    uint amtLPTake;
    uint amtLPWithdraw;
    uint amtARepay;
    uint amtBRepay;
    uint amtLPRepay;
    uint amtAMin;
    uint amtBMin;
  }

  function removeLiquidityInternal(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();

    uint amtARepay = amt.amtARepay;
    uint amtBRepay = amt.amtBRepay;
    uint amtLPRepay = amt.amtLPRepay;

    // 2. Compute repay amount if MAX_INT is supplied (max debt)
    if (amtARepay == uint(-1)) {
      amtARepay = bank.borrowBalanceCurrent(positionId, tokenA);
    }
    if (amtBRepay == uint(-1)) {
      amtBRepay = bank.borrowBalanceCurrent(positionId, tokenB);
    }
    if (amtLPRepay == uint(-1)) {
      amtLPRepay = bank.borrowBalanceCurrent(positionId, lp);
    }

    // 3. Compute amount to actually remove
    uint amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amt.amtLPWithdraw);

    // 4. Remove liquidity
    (uint amtA, uint amtB) =
      router.removeLiquidity(tokenA, tokenB, amtLPToRemove, 0, 0, address(this), now);

    // 5. MinimizeTrading
    uint amtADesired = amtARepay.add(amt.amtAMin);
    uint amtBDesired = amtBRepay.add(amt.amtBMin);

    if (amtA < amtADesired && amtB >= amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenB, tokenA);
      router.swapTokensForExactTokens(
        amtADesired.sub(amtA),
        amtB.sub(amtBDesired),
        path,
        address(this),
        now
      );
    } else if (amtA >= amtADesired && amtB < amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenA, tokenB);
      router.swapTokensForExactTokens(
        amtBDesired.sub(amtB),
        amtA.sub(amtADesired),
        path,
        address(this),
        now
      );
    }

    // 6. Repay
    doRepay(tokenA, amtARepay);
    doRepay(tokenB, amtBRepay);
    doRepay(lp, amtLPRepay);

    // 7. Slippage control
    require(IERC20(tokenA).balanceOf(address(this)) >= amt.amtAMin);
    require(IERC20(tokenB).balanceOf(address(this)) >= amt.amtBMin);
    require(IERC20(lp).balanceOf(address(this)) >= amt.amtLPWithdraw);

    // 8. Refund leftover
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
    doRefund(lp);
  }

  function removeLiquidityWERC20(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) external {
    address lp = getPair(tokenA, tokenB);

    // 1. Take out collateral
    doTakeCollateral(lp, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);
  }

  function removeLiquidityWStakingRewards(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt,
    address wstaking
  ) external {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    address reward = IWStakingRewards(wstaking).reward();

    // 1. Take out collateral
    require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    bank.takeCollateral(wstaking, collId, amt.amtLPTake);
    IWStakingRewards(wstaking).burn(collId, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);

    // 9. Refund reward
    doRefund(reward);
  }

  function harvestWStakingRewards(address wstaking) external {
    address reward = IWStakingRewards(wstaking).reward();
    uint positionId = bank.POSITION_ID();
    (, , uint collId, ) = bank.getPositionInfo(positionId);
    address lp = IWStakingRewards(wstaking).getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(wstaking, collId, uint(-1));
    IWStakingRewards(wstaking).burn(collId, uint(-1));

    // 2. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, wstaking);
    uint id = IWStakingRewards(wstaking).mint(amount);
    bank.putCollateral(wstaking, id, amount);

    // 3. Refund reward
    doRefund(reward);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';

import '../utils/ERC1155NaiveReceiver.sol';
import '../../interfaces/IBank.sol';
import '../../interfaces/IWERC20.sol';
import '../../interfaces/IWETH.sol';

contract BasicSpell is ERC1155NaiveReceiver {
  using SafeERC20 for IERC20;

  IBank public immutable bank;
  IWERC20 public immutable werc20;
  address public immutable weth;

  mapping(address => mapping(address => bool)) public approved;

  constructor(
    IBank _bank,
    address _werc20,
    address _weth
  ) public {
    bank = _bank;
    werc20 = IWERC20(_werc20);
    weth = _weth;
    ensureApprove(_weth, address(_bank));
    IWERC20(_werc20).setApprovalForAll(address(_bank), true);
  }

  /// @dev Ensure that the spell approve the given spender to spend all of its tokens.
  /// @param token The token to approve.
  /// @param spender The spender to allow spending.
  /// NOTE: This is safe because spell is never built to hold fund custody.
  function ensureApprove(address token, address spender) public {
    if (!approved[token][spender]) {
      IERC20(token).safeApprove(spender, uint(-1));
      approved[token][spender] = true;
    }
  }

  /// @dev Internal call to convert msg.value ETH to WETH inside the contract.
  function doTransmitETH() internal {
    if (msg.value > 0) {
      IWETH(weth).deposit{value: msg.value}();
    }
  }

  /// @dev Internal call to transmit tokens from the bank if amount is positive.
  /// @param token The token to perform the transmit action.
  /// @param amount The amount to transmit.
  function doTransmit(address token, uint amount) internal {
    if (amount > 0) {
      bank.transmit(token, amount);
    }
  }

  /// @dev Internal call to refund tokens to the current bank executor.
  /// @param token The token to perform the refund action.
  function doRefund(address token) internal {
    uint balance = IERC20(token).balanceOf(address(this));
    if (balance > 0) {
      IERC20(token).safeTransfer(bank.EXECUTOR(), balance);
    }
  }

  /// @dev Internal call to refund all WETH to the current executor as native ETH.
  function doRefundETH() internal {
    uint balance = IWETH(weth).balanceOf(address(this));
    if (balance > 0) {
      IWETH(weth).withdraw(balance);
      (bool success, ) = bank.EXECUTOR().call{value: balance}(new bytes(0));
      require(success, 'refund ETH failed');
    }
  }

  /// @dev Internal call to borrow tokens from the bank on behalf of the current executor.
  /// @param token The token to borrow from the bank.
  /// @param amount The amount to borrow.
  function doBorrow(address token, uint amount) internal {
    if (amount > 0) {
      bank.borrow(token, amount);
    }
  }

  /// @dev Internal call to repay tokens to the bank on behalf of the current executor.
  /// @param token The token to repay to the bank.
  /// @param amount The amount to repay.
  function doRepay(address token, uint amount) internal {
    if (amount > 0) {
      ensureApprove(token, address(bank));
      bank.repay(token, amount);
    }
  }

  /// @dev Internal call to put collateral tokens to the bank.
  /// @param token The token to put to the bank.
  /// @param amount The amount to put to the bank.
  function doPutCollateral(address token, uint amount) internal {
    if (amount > 0) {
      ensureApprove(token, address(werc20));
      werc20.mint(token, amount);
      bank.putCollateral(address(werc20), uint(token), amount);
    }
  }

  /// @dev Internal call to take collateral tokens from the bank.
  /// @param token The token to take back.
  /// @param amount The amount to take back.
  function doTakeCollateral(address token, uint amount) internal {
    if (amount > 0) {
      if (amount == uint(-1)) {
        (, , , amount) = bank.getPositionInfo(bank.POSITION_ID());
      }
      bank.takeCollateral(address(werc20), uint(token), amount);
      werc20.burn(token, amount);
    }
  }

  receive() external payable {
    require(msg.sender == weth, 'ETH must come from WETH');
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155Receiver.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155Receiver.sol';

contract ERC1155NaiveReceiver is ERC1155Receiver {
  function onERC1155Received(
    address operator,
    address from,
    uint id,
    uint value,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint[] calldata ids,
    uint[] calldata values,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}

pragma solidity 0.6.12;

interface IBank {
  /// The governor adds a new bank gets added to the system.
  event AddBank(address token, address cToken);
  /// The governor sets the address of the oracle smart contract.
  event SetOracle(address oracle);
  /// The governor sets the basis point fee of the bank.
  event SetFeeBps(uint feeBps);
  /// The governor withdraw tokens from the reserve of a bank.
  event WithdrawReserve(address user, address token, uint amount);
  /// Someone borrows tokens from a bank via a spell caller.
  event Borrow(uint positionId, address caller, address token, uint amount, uint share);
  /// Someone repays tokens to a bank via a spell caller.
  event Repay(uint positionId, address caller, address token, uint amount, uint share);
  /// Someone puts tokens as collateral via a spell caller.
  event PutCollateral(uint positionId, address caller, address token, uint id, uint amount);
  /// Someone takes tokens from collateral via a spell caller.
  event TakeCollateral(uint positionId, address caller, address token, uint id, uint amount);
  /// Someone calls liquidatation on a position, paying debt and taking collateral tokens.
  event Liquidate(
    uint positionId,
    address liquidator,
    address debtToken,
    uint amount,
    uint share,
    uint bounty
  );

  /// @dev Return the current position while under execution.
  function POSITION_ID() external view returns (uint);

  /// @dev Return the current target while under execution.
  function SPELL() external view returns (address);

  /// @dev Return the current executor (the owner of the current position).
  function EXECUTOR() external view returns (address);

  /// @dev Return bank information for the given token.
  function getBankInfo(address token)
    external
    view
    returns (
      bool isListed,
      address cToken,
      uint reserve,
      uint totalDebt,
      uint totalShare
    );

  /// @dev Return position information for the given position id.
  function getPositionInfo(uint positionId)
    external
    view
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    );

  /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
  function borrowBalanceStored(uint positionId, address token) external view returns (uint);

  /// @dev Trigger interest accrual and return the current borrow balance.
  function borrowBalanceCurrent(uint positionId, address token) external returns (uint);

  /// @dev Borrow tokens from the bank.
  function borrow(address token, uint amount) external;

  /// @dev Repays tokens to the bank.
  function repay(address token, uint amountCall) external;

  /// @dev Transmit user assets to the spell.
  function transmit(address token, uint amount) external;

  /// @dev Put more collateral for users.
  function putCollateral(
    address collToken,
    uint collId,
    uint amountCall
  ) external;

  /// @dev Take some collateral back.
  function takeCollateral(
    address collToken,
    uint collId,
    uint amount
  ) external;

  /// @dev Liquidate a position.
  function liquidate(
    uint positionId,
    address debtToken,
    uint amountCall
  ) external;

  function getBorrowETHValue(uint positionId) external view returns (uint);

  function accrue(address token) external;

  function nextPositionId() external view returns (uint);
}

pragma solidity 0.6.12;

interface IWETH {
  function balanceOf(address user) external returns (uint);

  function approve(address to, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function deposit() external payable;

  function withdraw(uint) external;
}

pragma solidity >=0.5.0;

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

pragma solidity >=0.6.2;

// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';

import './IERC20Wrapper.sol';

interface IWStakingRewards is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(uint amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint);

  function reward() external returns (address);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/ICurvePool.sol';
import '../../interfaces/ICurveRegistry.sol';
import '../../interfaces/IWLiquidityGauge.sol';
import '../../interfaces/IWERC20.sol';

contract CurveSpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  ICurveRegistry public immutable registry;
  IWLiquidityGauge public immutable wgauge;
  address public immutable crv;
  mapping(address => address[]) public ulTokens; // lpToken -> underlying token array
  mapping(address => address) public poolOf; // lpToken -> pool

  constructor(
    IBank _bank,
    address _werc20,
    address _weth,
    address _wgauge
  ) public BasicSpell(_bank, _werc20, _weth) {
    wgauge = IWLiquidityGauge(_wgauge);
    IWLiquidityGauge(_wgauge).setApprovalForAll(address(_bank), true);
    registry = IWLiquidityGauge(_wgauge).registry();
    crv = address(IWLiquidityGauge(_wgauge).crv());
  }

  /// @dev Return pool address given LP token and update pool info if not exist.
  /// @param lp LP token to find the corresponding pool.
  function getPool(address lp) public returns (address) {
    address pool = poolOf[lp];
    if (pool == address(0)) {
      require(lp != address(0), 'no lp token');
      pool = registry.get_pool_from_lp_token(lp);
      require(pool != address(0), 'no corresponding pool for lp token');
      poolOf[lp] = pool;
      uint n = registry.get_n_coins(pool);
      address[8] memory tokens = registry.get_coins(pool);
      ulTokens[lp] = new address[](n);
      for (uint i = 0; i < n; i++) {
        ulTokens[lp][i] = tokens[i];
      }
    }
    return pool;
  }

  function ensureApproveN(address lp, uint n) public {
    require(ulTokens[lp].length == n, 'incorrect pool length');
    address pool = poolOf[lp];
    address[] memory tokens = ulTokens[lp];
    for (uint idx = 0; idx < n; idx++) {
      ensureApprove(tokens[idx], pool);
    }
  }

  /// @dev add liquidity for pools with 2 underlying tokens
  function addLiquidity2(
    address lp,
    uint[2] calldata amtsUser,
    uint amtLPUser,
    uint[2] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 2, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 2 underlying tokens
    ensureApproveN(lp, 2);

    // 2. Get user input amounts
    for (uint i = 0; i < 2; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 2; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[2] memory suppliedAmts;
    for (uint i = 0; i < 2; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 2; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev add liquidity for pools with 3 underlying tokens
  function addLiquidity3(
    address lp,
    uint[3] calldata amtsUser,
    uint amtLPUser,
    uint[3] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 3, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 3 underlying tokens
    ensureApproveN(lp, 3);

    // 2. Get user input amounts
    for (uint i = 0; i < 3; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 3; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[3] memory suppliedAmts;
    for (uint i = 0; i < 3; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 3; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev add liquidity for pools with 4 underlying tokens
  function addLiquidity4(
    address lp,
    uint[4] calldata amtsUser,
    uint amtLPUser,
    uint[4] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 4, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 4 underlying tokens
    ensureApproveN(lp, 4);

    // 2. Get user input amounts
    for (uint i = 0; i < 4; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 4; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[4] memory suppliedAmts;
    for (uint i = 0; i < 4; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 4; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity2(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[2] calldata amtsRepay,
    uint amtLPRepay,
    uint[2] calldata amtsMin
  ) external {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 2);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[2] memory actualAmtsRepay;
    for (uint i = 0; i < 2; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[2] memory amtsDesired;
    for (uint i = 0; i < 2; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[2] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 2; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 2; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity3(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[3] calldata amtsRepay,
    uint amtLPRepay,
    uint[3] calldata amtsMin
  ) external {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 3);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[3] memory actualAmtsRepay;
    for (uint i = 0; i < 3; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[3] memory amtsDesired;
    for (uint i = 0; i < 3; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[3] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 3; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 3; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity4(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[4] calldata amtsRepay,
    uint amtLPRepay,
    uint[4] calldata amtsMin
  ) external {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 4);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[4] memory actualAmtsRepay;
    for (uint i = 0; i < 4; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[4] memory amtsDesired;
    for (uint i = 0; i < 4; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0 || amtsDesired[3] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[4] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 4; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 4; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function harvest() external {
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    (uint pid, uint gid, ) = wgauge.decodeId(collId);
    address lp = wgauge.getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(address(wgauge), collId, collSize);
    wgauge.burn(collId, collSize);

    // 2. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 3. Refund crv
    doRefund(crv);
  }
}

pragma solidity 0.6.12;

interface ICurvePool {
  function add_liquidity(uint[2] calldata, uint) external;

  function add_liquidity(uint[3] calldata, uint) external;

  function add_liquidity(uint[4] calldata, uint) external;

  function remove_liquidity(uint, uint[2] calldata) external;

  function remove_liquidity(uint, uint[3] calldata) external;

  function remove_liquidity(uint, uint[4] calldata) external;

  function remove_liquidity_imbalance(uint[2] calldata, uint) external;

  function remove_liquidity_imbalance(uint[3] calldata, uint) external;

  function remove_liquidity_imbalance(uint[4] calldata, uint) external;

  function remove_liquidity_one_coin(
    uint,
    int128,
    uint
  ) external;

  function get_virtual_price() external view returns (uint);
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

import './IERC20Wrapper.sol';
import './ICurveRegistry.sol';
import './ILiquidityGauge.sol';

interface IWLiquidityGauge is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(
    uint pid,
    uint gid,
    uint amount
  ) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function crv() external returns (IERC20);

  function registry() external returns (ICurveRegistry);

  function encodeId(
    uint,
    uint,
    uint
  ) external pure returns (uint);

  function decodeId(uint id)
    external
    pure
    returns (
      uint,
      uint,
      uint
    );
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IUniswapV2Factory.sol';
import '../../interfaces/IUniswapV2Router02.sol';
import '../../interfaces/IUniswapV2Pair.sol';
import '../../interfaces/IWMasterChef.sol';

contract SushiswapSpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  IUniswapV2Factory public immutable factory;
  IUniswapV2Router02 public immutable router;

  mapping(address => mapping(address => address)) public pairs;

  IWMasterChef public immutable wmasterchef;

  address public immutable sushi;

  constructor(
    IBank _bank,
    address _werc20,
    IUniswapV2Router02 _router,
    address _wmasterchef
  ) public BasicSpell(_bank, _werc20, _router.WETH()) {
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    wmasterchef = IWMasterChef(_wmasterchef);
    IWMasterChef(_wmasterchef).setApprovalForAll(address(_bank), true);
    sushi = address(IWMasterChef(_wmasterchef).sushi());
  }

  function getPair(address tokenA, address tokenB) public returns (address) {
    address lp = pairs[tokenA][tokenB];
    if (lp == address(0)) {
      lp = factory.getPair(tokenA, tokenB);
      require(lp != address(0), 'no lp token');
      ensureApprove(tokenA, address(router));
      ensureApprove(tokenB, address(router));
      ensureApprove(lp, address(router));
      pairs[tokenA][tokenB] = lp;
      pairs[tokenB][tokenA] = lp;
    }
    return lp;
  }

  /// @dev Compute optimal deposit amount
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  /// @dev Compute optimal deposit amount helper.
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  /// Formula: https://blog.alphafinance.io/byot/
  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');
    uint a = 997;
    uint b = uint(1997).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);
    uint d = a.mul(c).mul(4);
    uint e = HomoraMath.sqrt(b.mul(b).add(d));
    uint numerator = e.sub(b);
    uint denominator = a.mul(2);
    return numerator.div(denominator);
  }

  struct Amounts {
    uint amtAUser;
    uint amtBUser;
    uint amtLPUser;
    uint amtABorrow;
    uint amtBBorrow;
    uint amtLPBorrow;
    uint amtAMin;
    uint amtBMin;
  }

  function addLiquidityInternal(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);

    // 1. Get user input amounts
    doTransmitETH();
    doTransmit(tokenA, amt.amtAUser);
    doTransmit(tokenB, amt.amtBUser);
    doTransmit(lp, amt.amtLPUser);

    // 2. Borrow specified amounts
    doBorrow(tokenA, amt.amtABorrow);
    doBorrow(tokenB, amt.amtBBorrow);
    doBorrow(lp, amt.amtLPBorrow);

    // 3. Calculate optimal swap amount
    uint swapAmt;
    bool isReversed;
    {
      uint amtA = IERC20(tokenA).balanceOf(address(this));
      uint amtB = IERC20(tokenB).balanceOf(address(this));
      uint resA;
      uint resB;
      if (IUniswapV2Pair(lp).token0() == tokenA) {
        (resA, resB, ) = IUniswapV2Pair(lp).getReserves();
      } else {
        (resB, resA, ) = IUniswapV2Pair(lp).getReserves();
      }
      (swapAmt, isReversed) = optimalDeposit(amtA, amtB, resA, resB);
    }

    // 4. Swap optimal amount
    {
      address[] memory path = new address[](2);
      (path[0], path[1]) = isReversed ? (tokenB, tokenA) : (tokenA, tokenB);
      router.swapExactTokensForTokens(swapAmt, 0, path, address(this), now);
    }

    // 5. Add liquidity
    router.addLiquidity(
      tokenA,
      tokenB,
      IERC20(tokenA).balanceOf(address(this)),
      IERC20(tokenB).balanceOf(address(this)),
      amt.amtAMin,
      amt.amtBMin,
      address(this),
      now
    );
  }

  function addLiquidityWERC20(
    address tokenA,
    address tokenB,
    Amounts calldata amt
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Put collateral
    doPutCollateral(lp, IERC20(lp).balanceOf(address(this)));

    // 7. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
  }

  function addLiquidityWMasterChef(
    address tokenA,
    address tokenB,
    Amounts calldata amt,
    uint pid
  ) external payable {
    address lp = getPair(tokenA, tokenB);
    (address lpToken, , , ) = wmasterchef.chef().poolInfo(pid);
    require(lpToken == lp, 'incorrect lp token');

    // 1-5. add liquidity
    addLiquidityInternal(tokenA, tokenB, amt);

    // 6. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, ) = wmasterchef.decodeId(collId);
      require(pid == decodedPid, 'incorrect pid');
      bank.takeCollateral(address(wmasterchef), collId, collSize);
      wmasterchef.burn(collId, collSize);
    }

    // 7. Put collateral
    ensureApprove(lp, address(wmasterchef));
    uint amount = IERC20(lp).balanceOf(address(this));
    uint id = wmasterchef.mint(pid, amount);
    bank.putCollateral(address(wmasterchef), id, amount);

    // 8. Refund leftovers to users
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);

    // 9. Refund sushi
    doRefund(sushi);
  }

  struct RepayAmounts {
    uint amtLPTake;
    uint amtLPWithdraw;
    uint amtARepay;
    uint amtBRepay;
    uint amtLPRepay;
    uint amtAMin;
    uint amtBMin;
  }

  function removeLiquidityInternal(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) internal {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();

    uint amtARepay = amt.amtARepay;
    uint amtBRepay = amt.amtBRepay;
    uint amtLPRepay = amt.amtLPRepay;

    // 2. Compute repay amount if MAX_INT is supplied (max debt)
    if (amtARepay == uint(-1)) {
      amtARepay = bank.borrowBalanceCurrent(positionId, tokenA);
    }
    if (amtBRepay == uint(-1)) {
      amtBRepay = bank.borrowBalanceCurrent(positionId, tokenB);
    }
    if (amtLPRepay == uint(-1)) {
      amtLPRepay = bank.borrowBalanceCurrent(positionId, lp);
    }

    // 3. Compute amount to actually remove
    uint amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amt.amtLPWithdraw);

    // 4. Remove liquidity
    (uint amtA, uint amtB) =
      router.removeLiquidity(tokenA, tokenB, amtLPToRemove, 0, 0, address(this), now);

    // 5. MinimizeTrading
    uint amtADesired = amtARepay.add(amt.amtAMin);
    uint amtBDesired = amtBRepay.add(amt.amtBMin);

    if (amtA < amtADesired && amtB >= amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenB, tokenA);
      router.swapTokensForExactTokens(
        amtADesired.sub(amtA),
        amtB.sub(amtBDesired),
        path,
        address(this),
        now
      );
    } else if (amtA >= amtADesired && amtB < amtBDesired) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = (tokenA, tokenB);
      router.swapTokensForExactTokens(
        amtBDesired.sub(amtB),
        amtA.sub(amtADesired),
        path,
        address(this),
        now
      );
    }

    // 6. Repay
    doRepay(tokenA, amtARepay);
    doRepay(tokenB, amtBRepay);
    doRepay(lp, amtLPRepay);

    // 7. Slippage control
    require(IERC20(tokenA).balanceOf(address(this)) >= amt.amtAMin);
    require(IERC20(tokenB).balanceOf(address(this)) >= amt.amtBMin);
    require(IERC20(lp).balanceOf(address(this)) >= amt.amtLPWithdraw);

    // 8. Refund leftover
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
    doRefund(lp);
  }

  function removeLiquidityWERC20(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) external {
    address lp = getPair(tokenA, tokenB);

    // 1. Take out collateral
    doTakeCollateral(lp, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);
  }

  function removeLiquidityWMasterChef(
    address tokenA,
    address tokenB,
    RepayAmounts calldata amt
  ) external {
    address lp = getPair(tokenA, tokenB);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWMasterChef(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');

    // 1. Take out collateral
    bank.takeCollateral(address(wmasterchef), collId, amt.amtLPTake);
    wmasterchef.burn(collId, amt.amtLPTake);

    // 2-8. remove liquidity
    removeLiquidityInternal(tokenA, tokenB, amt);

    // 9. Refund sushi
    doRefund(sushi);
  }

  function harvestWMasterChef() external {
    uint positionId = bank.POSITION_ID();
    (, , uint collId, ) = bank.getPositionInfo(positionId);
    (uint pid, ) = wmasterchef.decodeId(collId);
    address lp = wmasterchef.getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(address(wmasterchef), collId, uint(-1));
    wmasterchef.burn(collId, uint(-1));

    // 2. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wmasterchef));
    uint id = wmasterchef.mint(pid, amount);
    bank.putCollateral(address(wmasterchef), id, amount);

    // 3. Refund sushi
    doRefund(sushi);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

import './IERC20Wrapper.sol';
import './IMasterChef.sol';

interface IWMasterChef is IERC1155, IERC20Wrapper {
  /// @dev Mint ERC1155 token for the given ERC20 token.
  function mint(uint pid, uint amount) external returns (uint id);

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  function burn(uint id, uint amount) external returns (uint pid);

  function sushi() external returns (IERC20);

  function decodeId(uint id) external pure returns (uint, uint);

  function chef() external view returns (IMasterChef);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IBalancerPool.sol';
import '../../interfaces/IWStakingRewards.sol';

contract BalancerSpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  mapping(address => address[2]) pairs; // mapping from lp token to underlying token (only pairs)

  constructor(
    IBank _bank,
    address _werc20,
    address _weth
  ) public BasicSpell(_bank, _werc20, _weth) {}

  function getPair(address lp) public returns (address tokenA, address tokenB) {
    address[2] memory ulTokens = pairs[lp];
    tokenA = ulTokens[0];
    tokenB = ulTokens[1];
    if (tokenA == address(0) || tokenB == address(0)) {
      address[] memory tokens = IBalancerPool(lp).getFinalTokens();
      require(tokens.length == 2, 'underlying tokens not 2');
      tokenA = tokens[0];
      tokenB = tokens[1];
      ensureApprove(tokenA, lp);
      ensureApprove(tokenB, lp);
    }
  }

  struct Amounts {
    uint amtAUser;
    uint amtBUser;
    uint amtLPUser;
    uint amtABorrow;
    uint amtBBorrow;
    uint amtLPBorrow;
    uint amtLPDesired;
  }

  function addLiquidityInternal(address lp, Amounts calldata amt) internal {
    (address tokenA, address tokenB) = getPair(lp);

    // 1. Get user input amounts
    doTransmitETH();
    doTransmit(tokenA, amt.amtAUser);
    doTransmit(tokenB, amt.amtBUser);
    doTransmit(lp, amt.amtLPUser);

    // 2. Borrow specified amounts
    doBorrow(tokenA, amt.amtABorrow);
    doBorrow(tokenB, amt.amtBBorrow);
    doBorrow(lp, amt.amtLPBorrow);

    // 3.1 Add Liquidity using equal value two side to minimize swap fee
    uint[] memory maxAmountsIn = new uint[](2);
    maxAmountsIn[0] = amt.amtAUser.add(amt.amtABorrow);
    maxAmountsIn[1] = amt.amtBUser.add(amt.amtBBorrow);
    uint totalLPSupply = IBalancerPool(lp).totalSupply();
    uint poolAmountFromA =
      maxAmountsIn[0].mul(1e18).div(IBalancerPool(lp).getBalance(tokenA)).mul(totalLPSupply).div(
        1e18
      ); // compute in reverse order of how Balancer's `joinPool` computes tokenAmountIn
    uint poolAmountFromB =
      maxAmountsIn[1].mul(1e18).div(IBalancerPool(lp).getBalance(tokenB)).mul(totalLPSupply).div(
        1e18
      ); // compute in reverse order of how Balancer's `joinPool` computes tokenAmountIn

    uint poolAmountOut = poolAmountFromA > poolAmountFromB ? poolAmountFromB : poolAmountFromA;
    if (poolAmountOut > 0) IBalancerPool(lp).joinPool(poolAmountOut, maxAmountsIn);

    // 3.2 Add Liquidity leftover for each token
    uint ABal = IERC20(tokenA).balanceOf(address(this));
    uint BBal = IERC20(tokenB).balanceOf(address(this));
    if (ABal > 0) IBalancerPool(lp).joinswapExternAmountIn(tokenA, ABal, 0);
    if (BBal > 0) IBalancerPool(lp).joinswapExternAmountIn(tokenB, BBal, 0);

    // 4. Slippage control
    uint lpBalance = IERC20(lp).balanceOf(address(this));
    require(lpBalance >= amt.amtLPDesired, 'lp desired not met');
  }

  /// @dev Add liquidity to Balancer pool (with 2 underlying tokens)
  function addLiquidityWERC20(address lp, Amounts calldata amt) external payable {
    // 1-4. add liquidity
    addLiquidityInternal(lp, amt);

    // 5. Put collateral
    doPutCollateral(lp, IERC20(lp).balanceOf(address(this)));

    // 6. Refund leftovers to users
    (address tokenA, address tokenB) = getPair(lp);
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
  }

  /// @dev Add liquidity to Balancer pool (with 2 underlying tokens)
  function addLiquidityWStakingRewards(
    address lp,
    Amounts calldata amt,
    address wstaking
  ) external payable {
    // 1-4. add liquidity
    addLiquidityInternal(lp, amt);

    // 5. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
      bank.takeCollateral(wstaking, collId, collSize);
      IWStakingRewards(wstaking).burn(collId, collSize);
    }

    // 6. Put collateral
    ensureApprove(lp, wstaking);
    uint amount = IERC20(lp).balanceOf(address(this));
    uint id = IWStakingRewards(wstaking).mint(amount);
    if (!IWStakingRewards(wstaking).isApprovedForAll(address(this), address(bank))) {
      IWStakingRewards(wstaking).setApprovalForAll(address(bank), true);
    }
    bank.putCollateral(address(wstaking), id, amount);

    // 7. Refund leftovers to users
    (address tokenA, address tokenB) = getPair(lp);
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);

    // 8. Refund reward
    doRefund(IWStakingRewards(wstaking).reward());
  }

  struct RepayAmounts {
    uint amtLPTake;
    uint amtLPWithdraw;
    uint amtARepay;
    uint amtBRepay;
    uint amtLPRepay;
    uint amtAMin;
    uint amtBMin;
  }

  function removeLiquidityInternal(address lp, RepayAmounts calldata amt) internal {
    (address tokenA, address tokenB) = getPair(lp);
    uint amtARepay = amt.amtARepay;
    uint amtBRepay = amt.amtBRepay;
    uint amtLPRepay = amt.amtLPRepay;

    // 2. Compute repay amount if MAX_INT is supplied (max debt)
    {
      uint positionId = bank.POSITION_ID();
      if (amtARepay == uint(-1)) {
        amtARepay = bank.borrowBalanceCurrent(positionId, tokenA);
      }
      if (amtBRepay == uint(-1)) {
        amtBRepay = bank.borrowBalanceCurrent(positionId, tokenB);
      }
      if (amtLPRepay == uint(-1)) {
        amtLPRepay = bank.borrowBalanceCurrent(positionId, lp);
      }
    }

    // 3.1 Remove liquidity 2 sides
    uint amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amt.amtLPWithdraw);

    uint[] memory minAmountsOut = new uint[](2);
    IBalancerPool(lp).exitPool(amtLPToRemove, minAmountsOut);

    // 3.2 Minimize trading
    uint amtADesired = amtARepay.add(amt.amtAMin);
    uint amtBDesired = amtBRepay.add(amt.amtBMin);

    uint amtA = IERC20(tokenA).balanceOf(address(this));
    uint amtB = IERC20(tokenB).balanceOf(address(this));

    if (amtA < amtADesired && amtB >= amtBDesired) {
      IBalancerPool(lp).swapExactAmountOut(
        tokenB,
        amtB.sub(amtBDesired),
        tokenA,
        amtADesired.sub(amtA),
        uint(-1)
      );
    } else if (amtA >= amtADesired && amtB < amtBDesired) {
      IBalancerPool(lp).swapExactAmountOut(
        tokenA,
        amtA.sub(amtADesired),
        tokenB,
        amtBDesired.sub(amtB),
        uint(-1)
      );
    }

    // 4. Repay
    doRepay(tokenA, amtARepay);
    doRepay(tokenB, amtBRepay);
    doRepay(lp, amtLPRepay);

    // 5. Slippage control
    require(IERC20(tokenA).balanceOf(address(this)) >= amt.amtAMin);
    require(IERC20(tokenB).balanceOf(address(this)) >= amt.amtBMin);
    require(IERC20(lp).balanceOf(address(this)) >= amt.amtLPWithdraw);

    // 6. Refund leftover
    doRefundETH();
    doRefund(tokenA);
    doRefund(tokenB);
    doRefund(lp);
  }

  function removeLiquidityWERC20(address lp, RepayAmounts calldata amt) external {
    // 1. Take out collateral
    doTakeCollateral(lp, amt.amtLPTake);

    // 2-6. remove liquidity
    removeLiquidityInternal(lp, amt);
  }

  function removeLiquidityWStakingRewards(
    address lp,
    RepayAmounts calldata amt,
    address wstaking
  ) external {
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);

    // 1. Take out collateral
    require(IWStakingRewards(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    bank.takeCollateral(wstaking, collId, amt.amtLPTake);
    IWStakingRewards(wstaking).burn(collId, amt.amtLPTake);

    // 2-6. remove liquidity
    removeLiquidityInternal(lp, amt);

    // 7. Refund reward
    doRefund(IWStakingRewards(wstaking).reward());
  }

  function harvestWStakingRewards(address wstaking) external {
    uint positionId = bank.POSITION_ID();
    (, , uint collId, ) = bank.getPositionInfo(positionId);
    address lp = IWStakingRewards(wstaking).getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(wstaking, collId, uint(-1));
    IWStakingRewards(wstaking).burn(collId, uint(-1));

    // 2. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, wstaking);
    uint id = IWStakingRewards(wstaking).mint(amount);
    bank.putCollateral(wstaking, id, amount);

    // 3. Refund reward
    doRefund(IWStakingRewards(wstaking).reward());
  }
}

pragma solidity 0.6.12;

interface IBalancerPool {
  function getFinalTokens() external view returns (address[] memory);

  function getNormalizedWeight(address token) external view returns (uint);

  function getSwapFee() external view returns (uint);

  function getNumTokens() external view returns (uint);

  function getBalance(address token) external view returns (uint);

  function totalSupply() external view returns (uint);

  function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

  function swapExactAmountOut(
    address tokenIn,
    uint maxAmountIn,
    address tokenOut,
    uint tokenAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountIn, uint spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint tokenAmountIn,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut);

  function exitPool(uint poolAmoutnIn, uint[] calldata minAmountsOut) external;

  function exitswapExternAmountOut(
    address tokenOut,
    uint tokenAmountOut,
    uint maxPoolAmountIn
  ) external returns (uint poolAmountIn);
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

import './BasicSpell.sol';
import '../../interfaces/IBank.sol';
import '../../interfaces/IWETH.sol';

contract HouseHoldSpell is BasicSpell {
  constructor(
    IBank _bank,
    address _werc20,
    address _weth
  ) public BasicSpell(_bank, _werc20, _weth) {}

  function borrowETH(uint amount) external {
    doBorrow(weth, amount);
    doRefundETH();
  }

  function borrow(address token, uint amount) external {
    doBorrow(token, amount);
    doRefund(token);
  }

  function repayETH(uint amount) external payable {
    doTransmitETH();
    doRepay(weth, amount);
    doRefundETH();
  }

  function repay(address token, uint amount) external {
    doTransmit(token, amount);
    doRepay(token, IERC20(token).balanceOf(address(this)));
  }

  function putCollateral(address token, uint amount) external {
    doTransmit(token, amount);
    doPutCollateral(token, IERC20(token).balanceOf(address(this)));
  }

  function takeCollateral(address token, uint amount) external {
    doTakeCollateral(token, amount);
    doRefund(token);
  }
}

pragma solidity 0.6.12;

interface MockUniswapV2FactoryIUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface MockUniswapV2FactoryIUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface MockUniswapV2FactoryIUniswapV2ERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

interface MockUniswapV2FactoryIERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);
}

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}

contract UniswapV2ERC20 {
  using MockUniswapV2FactorySafeMath for uint;

  string public constant name = 'Uniswap V2';
  string public constant symbol = 'UNI-V2';
  uint8 public constant decimals = 18;
  uint public totalSupply;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
  mapping(address => uint) public nonces;

  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  constructor() public {
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        ),
        keccak256(bytes(name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
  }

  function _mint(address to, uint value) internal {
    totalSupply = totalSupply.add(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(address(0), to, value);
  }

  function _burn(address from, uint value) internal {
    balanceOf[from] = balanceOf[from].sub(value);
    totalSupply = totalSupply.sub(value);
    emit Transfer(from, address(0), value);
  }

  function _approve(
    address owner,
    address spender,
    uint value
  ) private {
    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _transfer(
    address from,
    address to,
    uint value
  ) private {
    balanceOf[from] = balanceOf[from].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    emit Transfer(from, to, value);
  }

  function approve(address spender, uint value) external returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

  function transfer(address to, uint value) external returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool) {
    if (allowance[from][msg.sender] != uint(-1)) {
      allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    }
    _transfer(from, to, value);
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(
      recoveredAddress != address(0) && recoveredAddress == owner,
      'UniswapV2: INVALID_SIGNATURE'
    );
    _approve(owner, spender, value);
  }
}

contract MockUniswapV2FactoryUniswapV2Pair is UniswapV2ERC20 {
  using MockUniswapV2FactorySafeMath for uint;
  using UQ112x112 for uint224;

  uint public constant MINIMUM_LIQUIDITY = 10**3;
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

  address public factory;
  address public token0;
  address public token1;

  uint112 private reserve0; // uses single storage slot, accessible via getReserves
  uint112 private reserve1; // uses single storage slot, accessible via getReserves
  uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

  uint public price0CumulativeLast;
  uint public price1CumulativeLast;
  uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

  uint private unlocked = 1;
  modifier lock() {
    require(unlocked == 1, 'UniswapV2: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  function getReserves()
    public
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    )
  {
    _reserve0 = reserve0;
    _reserve1 = reserve1;
    _blockTimestampLast = blockTimestampLast;
  }

  function _safeTransfer(
    address token,
    address to,
    uint value
  ) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'UniswapV2: TRANSFER_FAILED'
    );
  }

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  constructor() public {
    factory = msg.sender;
  }

  // called once by the factory at time of deployment
  function initialize(address _token0, address _token1) external {
    require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
    token0 = _token0;
    token1 = _token1;
  }

  // update reserves and, on the first call per block, price accumulators
  function _update(
    uint balance0,
    uint balance1,
    uint112 _reserve0,
    uint112 _reserve1
  ) private {
    require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
    uint32 blockTimestamp = uint32(block.timestamp % 2**32);
    uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
    if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
      // * never overflows, and + overflow is desired
      price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
      price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
    }
    reserve0 = uint112(balance0);
    reserve1 = uint112(balance1);
    blockTimestampLast = blockTimestamp;
    emit Sync(reserve0, reserve1);
  }

  // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
  function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
    address feeTo = MockUniswapV2FactoryIUniswapV2Factory(factory).feeTo();
    feeOn = feeTo != address(0);
    uint _kLast = kLast; // gas savings
    if (feeOn) {
      if (_kLast != 0) {
        uint rootK = MockUniswapV2FactoryMah.sqrt(uint(_reserve0).mul(_reserve1));
        uint rootKLast = MockUniswapV2FactoryMah.sqrt(_kLast);
        if (rootK > rootKLast) {
          uint numerator = totalSupply.mul(rootK.sub(rootKLast));
          uint denominator = rootK.mul(5).add(rootKLast);
          uint liquidity = numerator / denominator;
          if (liquidity > 0) _mint(feeTo, liquidity);
        }
      }
    } else if (_kLast != 0) {
      kLast = 0;
    }
  }

  // this low-level function should be called from a contract which performs important safety checks
  function mint(address to) external lock returns (uint liquidity) {
    (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
    uint balance0 = MockUniswapV2FactoryIERC20(token0).balanceOf(address(this));
    uint balance1 = MockUniswapV2FactoryIERC20(token1).balanceOf(address(this));
    uint amount0 = balance0.sub(_reserve0);
    uint amount1 = balance1.sub(_reserve1);

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    if (_totalSupply == 0) {
      liquidity = MockUniswapV2FactoryMah.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
      _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
    } else {
      liquidity = MockUniswapV2FactoryMah.min(
        amount0.mul(_totalSupply) / _reserve0,
        amount1.mul(_totalSupply) / _reserve1
      );
    }
    require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
    _mint(to, liquidity);

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Mint(msg.sender, amount0, amount1);
  }

  // this low-level function should be called from a contract which performs important safety checks
  function burn(address to) external lock returns (uint amount0, uint amount1) {
    (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
    address _token0 = token0; // gas savings
    address _token1 = token1; // gas savings
    uint balance0 = MockUniswapV2FactoryIERC20(_token0).balanceOf(address(this));
    uint balance1 = MockUniswapV2FactoryIERC20(_token1).balanceOf(address(this));
    uint liquidity = balanceOf[address(this)];

    bool feeOn = _mintFee(_reserve0, _reserve1);
    uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
    amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
    amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
    require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
    _burn(address(this), liquidity);
    _safeTransfer(_token0, to, amount0);
    _safeTransfer(_token1, to, amount1);
    balance0 = MockUniswapV2FactoryIERC20(_token0).balanceOf(address(this));
    balance1 = MockUniswapV2FactoryIERC20(_token1).balanceOf(address(this));

    _update(balance0, balance1, _reserve0, _reserve1);
    if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
    emit Burn(msg.sender, amount0, amount1, to);
  }

  // this low-level function should be called from a contract which performs important safety checks
  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external lock {
    require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
    (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
    require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

    uint balance0;
    uint balance1;
    {
      // scope for _token{0,1}, avoids stack too deep errors
      address _token0 = token0;
      address _token1 = token1;
      require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
      if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
      if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
      if (data.length > 0)
        IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
      balance0 = MockUniswapV2FactoryIERC20(_token0).balanceOf(address(this));
      balance1 = MockUniswapV2FactoryIERC20(_token1).balanceOf(address(this));
    }
    uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
    uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
    require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
    {
      // scope for reserve{0,1}Adjusted, avoids stack too deep errors
      uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
      uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
      require(
        balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2),
        'UniswapV2: K'
      );
    }

    _update(balance0, balance1, _reserve0, _reserve1);
    emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
  }

  // force balances to match reserves
  function skim(address to) external lock {
    address _token0 = token0; // gas savings
    address _token1 = token1; // gas savings
    _safeTransfer(
      _token0,
      to,
      MockUniswapV2FactoryIERC20(_token0).balanceOf(address(this)).sub(reserve0)
    );
    _safeTransfer(
      _token1,
      to,
      MockUniswapV2FactoryIERC20(_token1).balanceOf(address(this)).sub(reserve1)
    );
  }

  // force reserves to match balances
  function sync() external lock {
    _update(
      MockUniswapV2FactoryIERC20(token0).balanceOf(address(this)),
      MockUniswapV2FactoryIERC20(token1).balanceOf(address(this)),
      reserve0,
      reserve1
    );
  }
}

contract MockUniswapV2Factory {
  address public feeTo;
  address public feeToSetter;

  mapping(address => mapping(address => address)) public getPair;
  address[] public allPairs;

  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  constructor(address _feeToSetter) public {
    feeToSetter = _feeToSetter;
  }

  function allPairsLength() external view returns (uint) {
    return allPairs.length;
  }

  function createPair(address tokenA, address tokenB) external returns (address pair) {
    require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
    bytes memory bytecode = type(MockUniswapV2FactoryUniswapV2Pair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    MockUniswapV2FactoryIUniswapV2Pair(pair).initialize(token0, token1);
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair; // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setFeeTo(address _feeTo) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library MockUniswapV2FactorySafeMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }
}

// a library for performing various math operations

library MockUniswapV2FactoryMah {
  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
  uint224 constant Q112 = 2**112;

  // encode a uint112 as a UQ112x112
  function encode(uint112 y) internal pure returns (uint224 z) {
    z = uint224(y) * Q112; // never overflows
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
    z = x / uint224(y);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  function mint(address to, uint amount) public {
    _mint(to, amount);
  }
}

pragma solidity 0.6.12;

// import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../../interfaces/ICErc20_2.sol';

contract MockCErc20_2 is ICErc20_2 {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  IERC20 public token;
  uint public mintRate = 1e18;
  uint public totalSupply = 0;
  mapping(address => uint) public override balanceOf;

  constructor(IERC20 _token) public {
    token = _token;
  }

  function setMintRate(uint _mintRate) external override {
    mintRate = _mintRate;
  }

  function underlying() external override returns (address) {
    return address(token);
  }

  function mint(uint mintAmount) external override returns (uint) {
    uint amountIn = mintAmount.mul(mintRate).div(1e18);
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
    totalSupply = totalSupply.add(mintAmount);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(mintAmount);
    return 0;
  }

  function redeem(uint redeemAmount) external override returns (uint) {
    uint amountOut = redeemAmount.mul(1e18).div(mintRate);
    IERC20(token).safeTransfer(msg.sender, amountOut);
    totalSupply = totalSupply.sub(redeemAmount);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(redeemAmount);
    return 0;
  }
}

pragma solidity 0.6.12;

interface ICErc20_2 {
  function underlying() external returns (address);

  function mint(uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function balanceOf(address user) external view returns (uint);

  function setMintRate(uint mintRate) external;
}

pragma solidity 0.6.12;

interface MockUniswapV2Router02IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface MockUniswapV2Router02IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface MockUniswapV2Router02IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);
}

interface MockUniswapV2Router02IUniswapV2Router02 is MockUniswapV2Router02IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);
}

interface MockUniswapV2Router02IWETH {
  function deposit() external payable;

  function transfer(address to, uint value) external returns (bool);

  function withdraw(uint) external;
}

contract MockUniswapV2Router02 is MockUniswapV2Router02IUniswapV2Router02 {
  using MockUniswapV2Router02SafeMath for uint;

  address public immutable override factory;
  address public immutable override WETH;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    _;
  }

  constructor(address _factory, address _WETH) public {
    factory = _factory;
    WETH = _WETH;
  }

  receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
  }

  // **** ADD LIQUIDITY ****
  function _addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  ) internal virtual returns (uint amountA, uint amountB) {
    // create the pair if it doesn't exist yet
    if (MockUniswapV2Router02IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
      MockUniswapV2Router02IUniswapV2Factory(factory).createPair(tokenA, tokenB);
    }
    (uint reserveA, uint reserveB) =
      MockUniswapV2Router02UniswapV2Library.getReserves(factory, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal =
        MockUniswapV2Router02UniswapV2Library.quote(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint amountAOptimal =
          MockUniswapV2Router02UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    virtual
    override
    ensure(deadline)
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    )
  {
    (amountA, amountB) = _addLiquidity(
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin
    );
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, tokenA, tokenB);
    MockUniswapV2Router02TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    MockUniswapV2Router02TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = MockUniswapV2Router02IUniswapV2Pair(pair).mint(to);
  }

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    )
  {
    (amountToken, amountETH) = _addLiquidity(
      token,
      WETH,
      amountTokenDesired,
      msg.value,
      amountTokenMin,
      amountETHMin
    );
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, token, WETH);
    MockUniswapV2Router02TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    MockUniswapV2Router02IWETH(WETH).deposit{value: amountETH}();
    assert(MockUniswapV2Router02IWETH(WETH).transfer(pair, amountETH));
    liquidity = MockUniswapV2Router02IUniswapV2Pair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH)
      MockUniswapV2Router02TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
  }

  // **** REMOVE LIQUIDITY ****
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, tokenA, tokenB);
    MockUniswapV2Router02IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
    (uint amount0, uint amount1) = MockUniswapV2Router02IUniswapV2Pair(pair).burn(to);
    (address token0, ) = MockUniswapV2Router02UniswapV2Library.sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
    require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
  }

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
    (amountToken, amountETH) = removeLiquidity(
      token,
      WETH,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    MockUniswapV2Router02TransferHelper.safeTransfer(token, to, amountToken);
    MockUniswapV2Router02IWETH(WETH).withdraw(amountETH);
    MockUniswapV2Router02TransferHelper.safeTransferETH(to, amountETH);
  }

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint amountA, uint amountB) {
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, tokenA, tokenB);
    uint value = approveMax ? uint(-1) : liquidity;
    MockUniswapV2Router02IUniswapV2Pair(pair).permit(
      msg.sender,
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );
    (amountA, amountB) = removeLiquidity(
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint amountToken, uint amountETH) {
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, token, WETH);
    uint value = approveMax ? uint(-1) : liquidity;
    MockUniswapV2Router02IUniswapV2Pair(pair).permit(
      msg.sender,
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );
    (amountToken, amountETH) = removeLiquidityETH(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) public virtual override ensure(deadline) returns (uint amountETH) {
    (, amountETH) = removeLiquidity(
      token,
      WETH,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    MockUniswapV2Router02TransferHelper.safeTransfer(
      token,
      to,
      IERC20(token).balanceOf(address(this))
    );
    MockUniswapV2Router02IWETH(WETH).withdraw(amountETH);
    MockUniswapV2Router02TransferHelper.safeTransferETH(to, amountETH);
  }

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual override returns (uint amountETH) {
    address pair = MockUniswapV2Router02UniswapV2Library.pairFor(factory, token, WETH);
    uint value = approveMax ? uint(-1) : liquidity;
    MockUniswapV2Router02IUniswapV2Pair(pair).permit(
      msg.sender,
      address(this),
      value,
      deadline,
      v,
      r,
      s
    );
    amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
      token,
      liquidity,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint[] memory amounts,
    address[] memory path,
    address _to
  ) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = MockUniswapV2Router02UniswapV2Library.sortTokens(input, output);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) =
        input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to =
        i < path.length - 2
          ? MockUniswapV2Router02UniswapV2Library.pairFor(factory, output, path[i + 2])
          : _to;
      MockUniswapV2Router02IUniswapV2Pair(
        MockUniswapV2Router02UniswapV2Library.pairFor(factory, input, output)
      )
        .swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsOut(factory, amountIn, path);
    require(
      amounts[amounts.length - 1] >= amountOutMin,
      'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    );
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, to);
  }

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
    require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsOut(factory, msg.value, path);
    require(
      amounts[amounts.length - 1] >= amountOutMin,
      'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    );
    MockUniswapV2Router02IWETH(WETH).deposit{value: amounts[0]}();
    assert(
      MockUniswapV2Router02IWETH(WETH).transfer(
        MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
        amounts[0]
      )
    );
    _swap(amounts, path, to);
  }

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
    require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    MockUniswapV2Router02IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    MockUniswapV2Router02TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
    require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsOut(factory, amountIn, path);
    require(
      amounts[amounts.length - 1] >= amountOutMin,
      'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    );
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amounts[0]
    );
    _swap(amounts, path, address(this));
    MockUniswapV2Router02IWETH(WETH).withdraw(amounts[amounts.length - 1]);
    MockUniswapV2Router02TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable virtual override ensure(deadline) returns (uint[] memory amounts) {
    require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    amounts = MockUniswapV2Router02UniswapV2Library.getAmountsIn(factory, amountOut, path);
    require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
    MockUniswapV2Router02IWETH(WETH).deposit{value: amounts[0]}();
    assert(
      MockUniswapV2Router02IWETH(WETH).transfer(
        MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
        amounts[0]
      )
    );
    _swap(amounts, path, to);
    // refund dust eth, if any
    if (msg.value > amounts[0])
      MockUniswapV2Router02TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }

  // **** SWAP (supporting fee-on-transfer tokens) ****
  // requires the initial amount to have already been sent to the first pair
  function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
    for (uint i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = MockUniswapV2Router02UniswapV2Library.sortTokens(input, output);
      MockUniswapV2Router02IUniswapV2Pair pair =
        MockUniswapV2Router02IUniswapV2Pair(
          MockUniswapV2Router02UniswapV2Library.pairFor(factory, input, output)
        );
      uint amountInput;
      uint amountOutput;
      {
        // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) =
          input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = MockUniswapV2Router02UniswapV2Library.getAmountOut(
          amountInput,
          reserveInput,
          reserveOutput
        );
      }
      (uint amount0Out, uint amount1Out) =
        input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to =
        i < path.length - 2
          ? MockUniswapV2Router02UniswapV2Library.pairFor(factory, output, path[i + 2])
          : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) {
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amountIn
    );
    uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable virtual override ensure(deadline) {
    require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
    uint amountIn = msg.value;
    MockUniswapV2Router02IWETH(WETH).deposit{value: amountIn}();
    assert(
      MockUniswapV2Router02IWETH(WETH).transfer(
        MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
        amountIn
      )
    );
    uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require(
      IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
      'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) {
    require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
    MockUniswapV2Router02TransferHelper.safeTransferFrom(
      path[0],
      msg.sender,
      MockUniswapV2Router02UniswapV2Library.pairFor(factory, path[0], path[1]),
      amountIn
    );
    _swapSupportingFeeOnTransferTokens(path, address(this));
    uint amountOut = IERC20(WETH).balanceOf(address(this));
    require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
    MockUniswapV2Router02IWETH(WETH).withdraw(amountOut);
    MockUniswapV2Router02TransferHelper.safeTransferETH(to, amountOut);
  }

  // **** LIBRARY FUNCTIONS ****
  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) public pure virtual override returns (uint amountB) {
    return MockUniswapV2Router02UniswapV2Library.quote(amountA, reserveA, reserveB);
  }

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) public pure virtual override returns (uint amountOut) {
    return MockUniswapV2Router02UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
  }

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) public pure virtual override returns (uint amountIn) {
    return MockUniswapV2Router02UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
  }

  function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
  {
    return MockUniswapV2Router02UniswapV2Library.getAmountsOut(factory, amountIn, path);
  }

  function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
  {
    return MockUniswapV2Router02UniswapV2Library.getAmountsIn(factory, amountOut, path);
  }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library MockUniswapV2Router02SafeMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }
}

library MockUniswapV2Router02UniswapV2Library {
  using MockUniswapV2Router02SafeMath for uint;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, 'MockUniswapV2Router02UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'MockUniswapV2Router02UniswapV2Library: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    return MockUniswapV2Router02IUniswapV2Factory(factory).getPair(tokenA, tokenB);
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, ) =
      MockUniswapV2Router02IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) internal pure returns (uint amountB) {
    require(amountA > 0, 'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_AMOUNT');
    require(
      reserveA > 0 && reserveB > 0,
      'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_LIQUIDITY'
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
    require(
      reserveIn > 0 && reserveOut > 0,
      'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_LIQUIDITY'
    );
    uint amountInWithFee = amountIn.mul(997);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    require(
      reserveIn > 0 && reserveOut > 0,
      'MockUniswapV2Router02UniswapV2Library: INSUFFICIENT_LIQUIDITY'
    );
    uint numerator = reserveIn.mul(amountOut).mul(1000);
    uint denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint amountIn,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MockUniswapV2Router02UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'MockUniswapV2Router02UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library MockUniswapV2Router02TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'MockUniswapV2Router02TransferHelper: APPROVE_FAILED'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'MockUniswapV2Router02TransferHelper: TRANSFER_FAILED'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'MockUniswapV2Router02TransferHelper: TRANSFER_FROM_FAILED'
    );
  }

  function safeTransferETH(address to, uint value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'MockUniswapV2Router02TransferHelper: ETH_TRANSFER_FAILED');
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../../interfaces/ICErc20.sol';

contract MockCErc20 is ICErc20 {
  using SafeMath for uint;

  IERC20 public token;
  uint public interestPerYear = 10e16; // 10% per year

  mapping(address => uint) public borrows;
  mapping(address => uint) public lastBlock;

  constructor(IERC20 _token) public {
    token = _token;
  }

  function decimals() external override returns (uint8) {
    return 8;
  }

  function underlying() external override returns (address) {
    return address(token);
  }

  function mint(uint mintAmount) external override returns (uint) {
    // Not implemented
    return 0;
  }

  function redeem(uint redeemTokens) external override returns (uint) {
    // Not implemented
    return 0;
  }

  function balanceOf(address user) external view override returns (uint) {
    // Not implemented
    return 0;
  }

  function borrowBalanceCurrent(address account) public override returns (uint) {
    uint timePast = now - lastBlock[account];
    if (timePast > 0) {
      uint interest = borrows[account].mul(interestPerYear).div(100e16).mul(timePast).div(365 days);
      borrows[account] = borrows[account].add(interest);
      lastBlock[account] = now;
    }
    return borrows[account];
  }

  function borrowBalanceStored(address account) external view override returns (uint) {
    return borrows[account];
  }

  function borrow(uint borrowAmount) external override returns (uint) {
    borrowBalanceCurrent(msg.sender);
    token.transfer(msg.sender, borrowAmount);
    borrows[msg.sender] = borrows[msg.sender].add(borrowAmount);
    return 0;
  }

  function repayBorrow(uint repayAmount) external override returns (uint) {
    borrowBalanceCurrent(msg.sender);
    token.transferFrom(msg.sender, address(this), repayAmount);
    borrows[msg.sender] = borrows[msg.sender].sub(repayAmount);
    return 0;
  }
}

pragma solidity 0.6.12;

contract MockWETH {
  string public name = 'Wrapped Ether';
  string public symbol = 'WETH';
  uint8 public decimals = 18;

  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);
  event Deposit(address indexed dst, uint wad);
  event Withdrawal(address indexed src, uint wad);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  receive() external payable {
    deposit();
  }

  function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint wad) public {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    msg.sender.transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }

  function totalSupply() public view returns (uint) {
    return address(this).balance;
  }

  function approve(address guy, uint wad) public returns (bool) {
    allowance[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

  function transfer(address dst, uint wad) public returns (bool) {
    return transferFrom(msg.sender, dst, wad);
  }

  function transferFrom(
    address src,
    address dst,
    uint wad
  ) public returns (bool) {
    require(balanceOf[src] >= wad);

    if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
      require(allowance[src][msg.sender] >= wad);
      allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    emit Transfer(src, dst, wad);

    return true;
  }
}

pragma solidity 0.6.12;

import '../../interfaces/IBaseOracle.sol';

contract UsingBaseOracle {
  IBaseOracle public immutable base;

  constructor(IBaseOracle _base) public {
    base = _base;
  }
}

pragma solidity 0.6.12;

interface IBaseOracle {
  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view returns (uint);
}

pragma solidity 0.6.12;

import '../Governable.sol';
import '../../interfaces/IBaseOracle.sol';

contract SimpleOracle is IBaseOracle, Governable {
  mapping(address => uint) public prices; // Mapping from token to price in ETH (times 2**112).

  /// The governor sets oracle price for a token.
  event SetETHPx(address token, uint px);

  /// @dev Create the contract and initialize the first governor.
  constructor() public {
    __Governable__init();
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view override returns (uint) {
    uint px = prices[token];
    require(px != 0, 'no px');
    return px;
  }

  /// @dev Set the prices of the given token addresses.
  /// @param tokens The token addresses to set the prices.
  /// @param pxs The price data points, representing token value in ETH times 2**112.
  function setETHPx(address[] memory tokens, uint[] memory pxs) external onlyGov {
    require(tokens.length == pxs.length, 'inconsistent length');
    for (uint idx = 0; idx < tokens.length; idx++) {
      prices[tokens[idx]] = pxs[idx];
      emit SetETHPx(tokens[idx], pxs[idx]);
    }
  }
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../Governable.sol';
import '../../interfaces/IBaseOracle.sol';

interface IStdReference {
  /// A structure returned whenever someone requests for standard reference data.
  struct ReferenceData {
    uint rate; // base/quote exchange rate, multiplied by 1e18.
    uint lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
    uint lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
  }

  /// Returns the price data for the given base/quote pair. Revert if not available.
  function getReferenceData(string memory _base, string memory _quote)
    external
    view
    returns (ReferenceData memory);

  /// Similar to getReferenceData, but with multiple base/quote pairs at once.
  function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
    external
    view
    returns (ReferenceData[] memory);
}

interface BandDetailedERC20 {
  function decimals() external view returns (uint8);
}

contract BandAdapterOracle is IBaseOracle, Governable {
  using SafeMath for uint;
  string public constant ETH = 'ETH';

  IStdReference public ref;
  uint public maxDelayTime;

  mapping(address => string) public symbols;

  constructor(IStdReference _ref, uint _maxDelayTime) public {
    __Governable__init();
    ref = _ref;
    maxDelayTime = _maxDelayTime;
  }

  function setSymbols(string[] memory syms, address[] memory tokens) external onlyGov {
    require(syms.length == tokens.length, 'inconsistent length');
    for (uint idx = 0; idx < syms.length; idx++) {
      symbols[tokens[idx]] = syms[idx];
    }
  }

  function setRef(IStdReference _ref) external onlyGov {
    ref = _ref;
  }

  function setMaxDelayTime(uint _maxDelayTime) external onlyGov {
    maxDelayTime = _maxDelayTime;
  }

  function getETHPx(address token) external view override returns (uint) {
    string memory sym = symbols[token];
    require(bytes(sym).length != 0, 'no mapping');
    uint8 decimals = BandDetailedERC20(token).decimals();
    IStdReference.ReferenceData memory data = ref.getReferenceData(sym, ETH);
    require(data.lastUpdatedBase >= block.timestamp.sub(maxDelayTime), 'delayed base data');
    require(data.lastUpdatedQuote >= block.timestamp.sub(maxDelayTime), 'delayed quote data');
    return data.rate.mul(2**112).div(10**decimals);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './UsingBaseOracle.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IUniswapV2Pair.sol';

contract UniswapV2Oracle is UsingBaseOracle, IBaseOracle {
  using SafeMath for uint;
  using HomoraMath for uint;

  constructor(IBaseOracle _base) public UsingBaseOracle(_base) {}

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param pair The Uniswap pair to check the value.
  function getETHPx(address pair) external view override returns (uint) {
    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();
    uint totalSupply = IUniswapV2Pair(pair).totalSupply();
    (uint r0, uint r1, ) = IUniswapV2Pair(pair).getReserves();
    uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply); // in 2**112
    uint px0 = base.getETHPx(token0);
    uint px1 = base.getETHPx(token1);
    return sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2**56).mul(HomoraMath.sqrt(px1)).div(2**56);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './UsingBaseOracle.sol';
import '../utils/BNum.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IBalancerPool.sol';

contract BalancerPairOracle is UsingBaseOracle, IBaseOracle, BNum {
  using SafeMath for uint;

  constructor(IBaseOracle _base) public UsingBaseOracle(_base) {}

  /// @dev Return fair reserve amounts given spot reserves, weights, and fair prices.
  /// @param resA Reserve of the first asset
  /// @param resB Reserev of the second asset
  /// @param wA Weight of the first asset
  /// @param wB Weight of the second asset
  /// @param pxA Fair price of the first asset
  /// @param pxB Fair price of the second asset
  function computeFairReserves(
    uint resA,
    uint resB,
    uint wA,
    uint wB,
    uint pxA,
    uint pxB
  ) internal pure returns (uint fairResA, uint fairResB) {
    uint r0 = bdiv(resA, resB);
    uint r1 = bdiv(bmul(wA, pxB), bmul(wB, pxA));
    // fairResA = resA * (r1 / r0) ^ wB
    // fairResB = resB * (r0 / r1) ^ wA
    if (r0 > r1) {
      uint ratio = bdiv(r1, r0);
      fairResA = bmul(resA, bpow(ratio, wB));
      fairResB = bdiv(resB, bpow(ratio, wA));
    } else {
      uint ratio = bdiv(r0, r1);
      fairResA = bdiv(resA, bpow(ratio, wB));
      fairResB = bmul(resB, bpow(ratio, wA));
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view override returns (uint) {
    IBalancerPool pool = IBalancerPool(token);
    require(pool.getNumTokens() == 2, 'num tokens must be 2');
    address[] memory tokens = pool.getFinalTokens();
    address tokenA = tokens[0];
    address tokenB = tokens[1];
    uint pxA = base.getETHPx(tokenA);
    uint pxB = base.getETHPx(tokenB);
    (uint fairResA, uint fairResB) =
      computeFairReserves(
        pool.getBalance(tokenA),
        pool.getBalance(tokenB),
        pool.getNormalizedWeight(tokenA),
        pool.getNormalizedWeight(tokenB),
        pxA,
        pxB
      );
    return fairResA.mul(pxA).add(fairResB.mul(pxB)).div(pool.totalSupply());
  }
}

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import './BConst.sol';

contract BNum is BConst {
  function btoi(uint a) internal pure returns (uint) {
    return a / BONE;
  }

  function bfloor(uint a) internal pure returns (uint) {
    return btoi(a) * BONE;
  }

  function badd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, 'ERR_ADD_OVERFLOW');
    return c;
  }

  function bsub(uint a, uint b) internal pure returns (uint) {
    (uint c, bool flag) = bsubSign(a, b);
    require(!flag, 'ERR_SUB_UNDERFLOW');
    return c;
  }

  function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint a, uint b) internal pure returns (uint) {
    uint c0 = a * b;
    require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
    uint c1 = c0 + (BONE / 2);
    require(c1 >= c0, 'ERR_MUL_OVERFLOW');
    uint c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint a, uint b) internal pure returns (uint) {
    require(b != 0, 'ERR_DIV_ZERO');
    uint c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
    uint c1 = c0 + (b / 2);
    require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
    uint c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint a, uint n) internal pure returns (uint) {
    uint z = n % 2 != 0 ? a : BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint base, uint exp) internal pure returns (uint) {
    require(base >= MIN_BPOW_BASE, 'ERR_BPOW_BASE_TOO_LOW');
    require(base <= MAX_BPOW_BASE, 'ERR_BPOW_BASE_TOO_HIGH');

    uint whole = bfloor(exp);
    uint remain = bsub(exp, whole);

    uint wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint base,
    uint exp,
    uint precision
  ) internal pure returns (uint) {
    // term 0:
    uint a = exp;
    (uint x, bool xneg) = bsubSign(base, BONE);
    uint term = BONE;
    uint sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint i = 1; term >= precision; i++) {
      uint bigK = i * BONE;
      (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
  }
}

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

contract BConst {
  uint public constant BONE = 10**18;

  uint public constant MIN_BOUND_TOKENS = 2;
  uint public constant MAX_BOUND_TOKENS = 8;

  uint public constant MIN_FEE = BONE / 10**6;
  uint public constant MAX_FEE = BONE / 10;
  uint public constant EXIT_FEE = 0;

  uint public constant MIN_WEIGHT = BONE;
  uint public constant MAX_WEIGHT = BONE * 50;
  uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint public constant MIN_BALANCE = BONE / 10**12;

  uint public constant INIT_POOL_SUPPLY = BONE * 100;

  uint public constant MIN_BPOW_BASE = 1 wei;
  uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint public constant BPOW_PRECISION = BONE / 10**10;

  uint public constant MAX_IN_RATIO = BONE / 2;
  uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './UsingBaseOracle.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/ICurvePool.sol';
import '../../interfaces/ICurveRegistry.sol';

interface IERC20Decimal {
  function decimals() external view returns (uint8);
}

contract CurveOracle is UsingBaseOracle, IBaseOracle {
  using SafeMath for uint;

  ICurveRegistry public immutable registry;

  struct UnderlyingToken {
    uint8 decimals; // token decimals
    address token; // token address
  }

  mapping(address => UnderlyingToken[]) public ulTokens; // lpToken -> underlying tokens array
  mapping(address => address) public poolOf; // lpToken -> pool

  constructor(IBaseOracle _base, ICurveRegistry _registry) public UsingBaseOracle(_base) {
    registry = _registry;
  }

  /// @dev Register the pool given LP token address and set the pool info.
  /// @param lp LP token to find the corresponding pool.
  function registerPool(address lp) external {
    address pool = poolOf[lp];
    require(pool == address(0), 'lp is already registered');
    pool = registry.get_pool_from_lp_token(lp);
    require(pool != address(0), 'no corresponding pool for lp token');
    poolOf[lp] = pool;
    uint n = registry.get_n_coins(pool);
    address[8] memory tokens = registry.get_coins(pool);
    for (uint i = 0; i < n; i++) {
      ulTokens[lp].push(
        UnderlyingToken({token: tokens[i], decimals: IERC20Decimal(tokens[i]).decimals()})
      );
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param lp The ERC-20 LP token to check the value.
  function getETHPx(address lp) external view override returns (uint) {
    address pool = poolOf[lp];
    require(pool != address(0), 'lp is not registered');
    UnderlyingToken[] memory tokens = ulTokens[lp];
    uint minPx = uint(-1);
    uint n = tokens.length;
    for (uint idx = 0; idx < n; idx++) {
      UnderlyingToken memory ulToken = tokens[idx];
      uint tokenPx = base.getETHPx(ulToken.token);
      if (ulToken.decimals < 18) tokenPx = tokenPx.div(10**(18 - uint(ulToken.decimals)));
      if (ulToken.decimals > 18) tokenPx = tokenPx.mul(10**(uint(ulToken.decimals) - 18));
      if (tokenPx < minPx) minPx = tokenPx;
    }
    require(minPx != uint(-1), 'no min px');
    return minPx.mul(ICurvePool(pool).get_virtual_price()).div(1e18);
  }
}

pragma solidity 0.6.12;

import './BaseKP3ROracle.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IKeep3rV1Oracle.sol';
import '../../interfaces/IUniswapV2Factory.sol';

contract ERC20KP3ROracle is IBaseOracle, BaseKP3ROracle {
  constructor(IKeep3rV1Oracle _kp3r) public BaseKP3ROracle(_kp3r) {}

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view override returns (uint) {
    if (token == weth || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
      return 2**112;
    }
    address pair = IUniswapV2Factory(factory).getPair(token, weth);
    if (token < weth) {
      return price0TWAP(pair);
    } else {
      return price1TWAP(pair);
    }
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/proxy/Initializable.sol';

import '../../interfaces/IKeep3rV1Oracle.sol';
import '../../interfaces/IUniswapV2Pair.sol';

contract BaseKP3ROracle is Initializable {
  uint public constant MIN_TWAP_TIME = 15 minutes;
  uint public constant MAX_TWAP_TIME = 60 minutes;

  IKeep3rV1Oracle public immutable kp3r;
  address public immutable factory;
  address public immutable weth;

  constructor(IKeep3rV1Oracle _kp3r) public {
    kp3r = _kp3r;
    factory = _kp3r.factory();
    weth = _kp3r.WETH();
  }

  /// @dev Return the TWAP value price0. Revert if TWAP time range is not within the threshold.
  /// @param pair The pair to query for price0.
  function price0TWAP(address pair) public view returns (uint) {
    uint length = kp3r.observationLength(pair);
    require(length > 0, 'no length-1 observation');
    (uint lastTime, uint lastPx0Cumu, ) = kp3r.observations(pair, length - 1);
    if (lastTime > now - MIN_TWAP_TIME) {
      require(length > 1, 'no length-2 observation');
      (lastTime, lastPx0Cumu, ) = kp3r.observations(pair, length - 2);
    }
    uint elapsedTime = now - lastTime;
    require(elapsedTime >= MIN_TWAP_TIME && elapsedTime <= MAX_TWAP_TIME, 'bad TWAP time');
    uint currPx0Cumu = currentPx0Cumu(pair);
    return (currPx0Cumu - lastPx0Cumu) / (now - lastTime); // overflow is desired
  }

  /// @dev Return the TWAP value price1. Revert if TWAP time range is not within the threshold.
  /// @param pair The pair to query for price1.
  function price1TWAP(address pair) public view returns (uint) {
    uint length = kp3r.observationLength(pair);
    require(length > 0, 'no length-1 observation');
    (uint lastTime, , uint lastPx1Cumu) = kp3r.observations(pair, length - 1);
    if (lastTime > now - MIN_TWAP_TIME) {
      require(length > 1, 'no length-2 observation');
      (lastTime, , lastPx1Cumu) = kp3r.observations(pair, length - 2);
    }
    uint elapsedTime = now - lastTime;
    require(elapsedTime >= MIN_TWAP_TIME && elapsedTime <= MAX_TWAP_TIME, 'bad TWAP time');
    uint currPx1Cumu = currentPx1Cumu(pair);
    return (currPx1Cumu - lastPx1Cumu) / (now - lastTime); // overflow is desired
  }

  /// @dev Return the current price0 cumulative value on uniswap.
  /// @param pair The uniswap pair to query for price0 cumulative value.
  function currentPx0Cumu(address pair) public view returns (uint px0Cumu) {
    uint32 currTime = uint32(now);
    px0Cumu = IUniswapV2Pair(pair).price0CumulativeLast();
    (uint reserve0, uint reserve1, uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
    if (lastTime != now) {
      uint32 timeElapsed = currTime - lastTime; // overflow is desired
      px0Cumu += uint((reserve1 << 112) / reserve0) * timeElapsed; // overflow is desired
    }
  }

  /// @dev Return the current price1 cumulative value on uniswap.
  /// @param pair The uniswap pair to query for price1 cumulative value.
  function currentPx1Cumu(address pair) public view returns (uint px1Cumu) {
    uint32 currTime = uint32(now);
    px1Cumu = IUniswapV2Pair(pair).price1CumulativeLast();
    (uint reserve0, uint reserve1, uint32 lastTime) = IUniswapV2Pair(pair).getReserves();
    if (lastTime != currTime) {
      uint32 timeElapsed = currTime - lastTime; // overflow is desired
      px1Cumu += uint((reserve0 << 112) / reserve1) * timeElapsed; // overflow is desired
    }
  }
}

pragma solidity 0.6.12;

abstract contract IKeep3rV1Oracle {
  struct Observation {
    uint timestamp;
    uint price0Cumulative;
    uint price1Cumulative;
  }

  function WETH() external pure virtual returns (address);

  function factory() external pure virtual returns (address);

  mapping(address => Observation[]) public observations;

  function observationLength(address pair) external view virtual returns (uint);
}

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import '../Governable.sol';
import '../../interfaces/IOracle.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IERC20Wrapper.sol';

contract ProxyOracle is IOracle, Governable {
  using SafeMath for uint;

  /// The governor sets oracle information for a token.
  event SetOracle(address token, Oracle info);
  /// The governor unsets oracle information for a token.
  event UnsetOracle(address token);
  /// The governor sets token whitelist for an ERC1155 token.
  event SetWhitelist(address token, bool ok);

  struct Oracle {
    uint16 borrowFactor; // The borrow factor for this token, multiplied by 1e4.
    uint16 collateralFactor; // The collateral factor for this token, multiplied by 1e4.
    uint16 liqIncentive; // The liquidation incentive, multiplied by 1e4.
  }

  IBaseOracle public immutable source;
  mapping(address => Oracle) public oracles; // Mapping from token address to oracle info.
  mapping(address => bool) public whitelistERC1155;

  /// @dev Create the contract and initialize the first governor.
  constructor(IBaseOracle _source) public {
    source = _source;
    __Governable__init();
  }

  /// @dev Set oracle information for the given list of token addresses.
  function setOracles(address[] memory tokens, Oracle[] memory info) external onlyGov {
    require(tokens.length == info.length, 'inconsistent length');
    for (uint idx = 0; idx < tokens.length; idx++) {
      require(info[idx].borrowFactor >= 10000, 'borrow factor must be at least 100%');
      require(info[idx].collateralFactor <= 10000, 'collateral factor must be at most 100%');
      require(info[idx].liqIncentive >= 10000, 'incentive must be at least 100%');
      require(info[idx].liqIncentive <= 20000, 'incentive must be at most 200%');
      oracles[tokens[idx]] = info[idx];
      emit SetOracle(tokens[idx], info[idx]);
    }
  }

  function unsetOracles(address[] memory tokens) external onlyGov {
    for (uint idx = 0; idx < tokens.length; idx++) {
      oracles[tokens[idx]] = Oracle(0, 0, 0);
      emit UnsetOracle(tokens[idx]);
    }
  }

  /// @dev Set whitelist status for the given list of token addresses.
  function setWhitelistERC1155(address[] memory tokens, bool ok) external onlyGov {
    for (uint idx = 0; idx < tokens.length; idx++) {
      whitelistERC1155[tokens[idx]] = ok;
      emit SetWhitelist(tokens[idx], ok);
    }
  }

  /// @dev Return whether the oracle supports evaluating collateral value of the given token.
  function support(address token, uint id) external view override returns (bool) {
    if (!whitelistERC1155[token]) return false;
    address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
    return oracles[tokenUnderlying].liqIncentive != 0;
  }

  /// @dev Return the amount of token out as liquidation reward for liquidating token in.
  function convertForLiquidation(
    address tokenIn,
    address tokenOut,
    uint tokenOutId,
    uint amountIn
  ) external view override returns (uint) {
    require(whitelistERC1155[tokenOut], 'bad token');
    address tokenOutUnderlying = IERC20Wrapper(tokenOut).getUnderlyingToken(tokenOutId);
    uint rateUnderlying = IERC20Wrapper(tokenOut).getUnderlyingRate(tokenOutId);
    Oracle memory oracleIn = oracles[tokenIn];
    Oracle memory oracleOut = oracles[tokenOutUnderlying];
    require(oracleIn.liqIncentive != 0, 'bad underlying in');
    require(oracleOut.liqIncentive != 0, 'bad underlying out');
    uint pxIn = source.getETHPx(tokenIn);
    uint pxOut = source.getETHPx(tokenOutUnderlying);
    uint amountOut = amountIn.mul(pxIn).div(pxOut);
    amountOut = amountOut.mul(2**112).div(rateUnderlying);
    return amountOut.mul(oracleIn.liqIncentive).mul(oracleOut.liqIncentive).div(10000 * 10000);
  }

  /// @dev Return the value of the given input as ETH for collateral purpose.
  function asETHCollateral(
    address token,
    uint id,
    uint amount,
    address owner
  ) external view override returns (uint) {
    require(whitelistERC1155[token], 'bad token');
    address tokenUnderlying = IERC20Wrapper(token).getUnderlyingToken(id);
    uint rateUnderlying = IERC20Wrapper(token).getUnderlyingRate(id);
    uint amountUnderlying = amount.mul(rateUnderlying).div(2**112);
    Oracle memory oracle = oracles[tokenUnderlying];
    require(oracle.liqIncentive != 0, 'bad underlying collateral');
    uint ethValue = source.getETHPx(tokenUnderlying).mul(amountUnderlying).div(2**112);
    return ethValue.mul(oracle.collateralFactor).div(10000);
  }

  /// @dev Return the value of the given input as ETH for borrow purpose.
  function asETHBorrow(
    address token,
    uint amount,
    address owner
  ) external view override returns (uint) {
    Oracle memory oracle = oracles[token];
    require(oracle.liqIncentive != 0, 'bad underlying borrow');
    uint ethValue = source.getETHPx(token).mul(amount).div(2**112);
    return ethValue.mul(oracle.borrowFactor).div(10000);
  }
}

pragma solidity 0.6.12;

interface IOracle {
  /// @dev Return whether the oracle supports evaluating collateral value of the given address.
  /// @param token The ERC-1155 token to check the acceptence.
  /// @param id The token id to check the acceptance.
  function support(address token, uint id) external view returns (bool);

  /// @dev Return the amount of token out as liquidation reward for liquidating token in.
  /// @param tokenIn The ERC-20 token that gets liquidated.
  /// @param tokenOut The ERC-1155 token to pay as reward.
  /// @param tokenOutId The id of the token to pay as reward.
  /// @param amountIn The amount of liquidating tokens.
  function convertForLiquidation(
    address tokenIn,
    address tokenOut,
    uint tokenOutId,
    uint amountIn
  ) external view returns (uint);

  /// @dev Return the value of the given input as ETH for collateral purpose.
  /// @param token The ERC-1155 token to check the value.
  /// @param id The id of the token to check the value.
  /// @param amount The amount of tokens to check the value.
  /// @param owner The owner of the token to check for collateral credit.
  function asETHCollateral(
    address token,
    uint id,
    uint amount,
    address owner
  ) external view returns (uint);

  /// @dev Return the value of the given input as ETH for borrow purpose.
  /// @param token The ERC-20 token to check the value.
  /// @param amount The amount of tokens to check the value.
  /// @param owner The owner of the token to check for borrow credit.
  function asETHBorrow(
    address token,
    uint amount,
    address owner
  ) external view returns (uint);
}

pragma solidity 0.6.12;

import '../../interfaces/IBaseOracle.sol';
import '../Governable.sol';

contract CoreOracle is IBaseOracle, Governable {
  event SetRoute(address token, address route);
  mapping(address => address) public routes;

  constructor() public {
    __Governable__init();
  }

  function setRoute(address[] calldata tokens, address[] calldata targets) external onlyGov {
    require(tokens.length == targets.length, 'inconsistent length');
    for (uint idx = 0; idx < tokens.length; idx++) {
      routes[tokens[idx]] = targets[idx];
      emit SetRoute(tokens[idx], targets[idx]);
    }
  }

  function getETHPx(address token) external view override returns (uint) {
    uint px = IBaseOracle(routes[token]).getETHPx(token);
    require(px != 0, 'no px');
    return px;
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import './utils/HomoraMath.sol';

interface IbETHRouterV2IbETHv2 is IERC20 {
  function deposit() external payable;

  function withdraw(uint amount) external;
}

interface IbETHRouterV2UniswapPair is IERC20 {
  function token0() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint,
      uint,
      uint
    );
}

interface IbETHRouterV2UniswapRouter {
  function factory() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
}

interface IbETHRouterV2UniswapFactory {
  function getPair(address tokenA, address tokenB) external view returns (address);
}

contract IbETHRouterV2 {
  using SafeMath for uint;

  IERC20 public immutable alpha;
  IbETHRouterV2IbETHv2 public immutable ibETHv2;
  IbETHRouterV2UniswapPair public immutable lpToken;
  IbETHRouterV2UniswapRouter public immutable router;

  constructor(
    IERC20 _alpha,
    IbETHRouterV2IbETHv2 _ibETHv2,
    IbETHRouterV2UniswapRouter _router
  ) public {
    IbETHRouterV2UniswapPair _lpToken =
      IbETHRouterV2UniswapPair(
        IbETHRouterV2UniswapFactory(_router.factory()).getPair(address(_alpha), address(_ibETHv2))
      );
    alpha = _alpha;
    ibETHv2 = _ibETHv2;
    lpToken = _lpToken;
    router = _router;
    require(_alpha.approve(address(_router), uint(-1)));
    require(_ibETHv2.approve(address(_router), uint(-1)));
    require(_lpToken.approve(address(_router), uint(-1)));
  }

  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');
    uint a = 997;
    uint b = uint(1997).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);
    uint d = a.mul(c).mul(4);
    uint e = HomoraMath.sqrt(b.mul(b).add(d));
    uint numerator = e.sub(b);
    uint denominator = a.mul(2);
    return numerator.div(denominator);
  }

  function swapExactETHToAlpha(
    uint amountOutMin,
    address to,
    uint deadline
  ) external payable {
    ibETHv2.deposit{value: msg.value}();
    address[] memory path = new address[](2);
    path[0] = address(ibETHv2);
    path[1] = address(alpha);
    router.swapExactTokensForTokens(
      ibETHv2.balanceOf(address(this)),
      amountOutMin,
      path,
      to,
      deadline
    );
  }

  function swapExactAlphaToETH(
    uint amountIn,
    uint amountOutMin,
    address to,
    uint deadline
  ) external {
    alpha.transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(alpha);
    path[1] = address(ibETHv2);
    router.swapExactTokensForTokens(amountIn, 0, path, address(this), deadline);
    ibETHv2.withdraw(ibETHv2.balanceOf(address(this)));
    uint ethBalance = address(this).balance;
    require(ethBalance >= amountOutMin, '!amountOutMin');
    (bool success, ) = to.call{value: ethBalance}(new bytes(0));
    require(success, '!eth');
  }

  function addLiquidityETHAlphaOptimal(
    uint amountAlpha,
    uint minLp,
    address to,
    uint deadline
  ) external payable {
    if (amountAlpha > 0) alpha.transferFrom(msg.sender, address(this), amountAlpha);
    ibETHv2.deposit{value: msg.value}();
    uint amountIbETHv2 = ibETHv2.balanceOf(address(this));
    uint swapAmt;
    bool isReversed;
    {
      (uint r0, uint r1, ) = lpToken.getReserves();
      (uint ibETHv2Reserve, uint alphaReserve) =
        lpToken.token0() == address(ibETHv2) ? (r0, r1) : (r1, r0);
      (swapAmt, isReversed) = optimalDeposit(
        amountIbETHv2,
        amountAlpha,
        ibETHv2Reserve,
        alphaReserve
      );
    }
    if (swapAmt > 0) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = isReversed
        ? (address(alpha), address(ibETHv2))
        : (address(ibETHv2), address(alpha));
      router.swapExactTokensForTokens(swapAmt, 0, path, address(this), deadline);
    }
    (, , uint liquidity) =
      router.addLiquidity(
        address(alpha),
        address(ibETHv2),
        alpha.balanceOf(address(this)),
        ibETHv2.balanceOf(address(this)),
        0,
        0,
        to,
        deadline
      );
    require(liquidity >= minLp, '!minLP');
  }

  function addLiquidityIbETHv2AlphaOptimal(
    uint amountIbETHv2,
    uint amountAlpha,
    uint minLp,
    address to,
    uint deadline
  ) external {
    if (amountAlpha > 0) alpha.transferFrom(msg.sender, address(this), amountAlpha);
    if (amountIbETHv2 > 0) ibETHv2.transferFrom(msg.sender, address(this), amountIbETHv2);
    uint swapAmt;
    bool isReversed;
    {
      (uint r0, uint r1, ) = lpToken.getReserves();
      (uint ibETHv2Reserve, uint alphaReserve) =
        lpToken.token0() == address(ibETHv2) ? (r0, r1) : (r1, r0);
      (swapAmt, isReversed) = optimalDeposit(
        amountIbETHv2,
        amountAlpha,
        ibETHv2Reserve,
        alphaReserve
      );
    }
    if (swapAmt > 0) {
      address[] memory path = new address[](2);
      (path[0], path[1]) = isReversed
        ? (address(alpha), address(ibETHv2))
        : (address(ibETHv2), address(alpha));
      router.swapExactTokensForTokens(swapAmt, 0, path, address(this), deadline);
    }
    (, , uint liquidity) =
      router.addLiquidity(
        address(alpha),
        address(ibETHv2),
        alpha.balanceOf(address(this)),
        ibETHv2.balanceOf(address(this)),
        0,
        0,
        to,
        deadline
      );
    require(liquidity >= minLp, '!minLP');
  }

  function removeLiquidityETHAlpha(
    uint liquidity,
    uint minETH,
    uint minAlpha,
    address to,
    uint deadline
  ) external {
    lpToken.transferFrom(msg.sender, address(this), liquidity);
    router.removeLiquidity(
      address(alpha),
      address(ibETHv2),
      liquidity,
      minAlpha,
      0,
      address(this),
      deadline
    );
    alpha.transfer(msg.sender, alpha.balanceOf(address(this)));
    ibETHv2.withdraw(ibETHv2.balanceOf(address(this)));
    uint ethBalance = address(this).balance;
    require(ethBalance >= minETH, '!minETH');
    (bool success, ) = to.call{value: ethBalance}(new bytes(0));
    require(success, '!eth');
  }

  function removeLiquidityAlphaOnly(
    uint liquidity,
    uint minAlpha,
    address to,
    uint deadline
  ) external {
    lpToken.transferFrom(msg.sender, address(this), liquidity);
    router.removeLiquidity(
      address(alpha),
      address(ibETHv2),
      liquidity,
      0,
      0,
      address(this),
      deadline
    );
    address[] memory path = new address[](2);
    path[0] = address(ibETHv2);
    path[1] = address(alpha);
    router.swapExactTokensForTokens(
      ibETHv2.balanceOf(address(this)),
      0,
      path,
      address(this),
      deadline
    );
    uint alphaBalance = alpha.balanceOf(address(this));
    require(alphaBalance >= minAlpha, '!minAlpha');
    alpha.transfer(to, alphaBalance);
  }

  receive() external payable {
    require(msg.sender == address(ibETHv2), '!ibETHv2');
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/IERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/math/Math.sol';
import 'OpenZeppelin/[email protected]/contracts/proxy/Initializable.sol';

import './Governable.sol';
import './utils/ERC1155NaiveReceiver.sol';
import '../interfaces/IBank.sol';
import '../interfaces/ICErc20.sol';
import '../interfaces/IOracle.sol';

contract HomoraCaster {
  /// @dev Call to the target using the given data.
  /// @param target The address target to call.
  /// @param data The data used in the call.
  function cast(address target, bytes calldata data) external payable {
    (bool ok, bytes memory returndata) = target.call{value: msg.value}(data);
    if (!ok) {
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert('bad cast call');
      }
    }
  }
}

contract HomoraBank is Initializable, Governable, ERC1155NaiveReceiver, IBank {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  uint private constant _NOT_ENTERED = 1;
  uint private constant _ENTERED = 2;
  uint private constant _NO_ID = uint(-1);
  address private constant _NO_ADDRESS = address(1);

  struct Bank {
    bool isListed; // Whether this market exists.
    uint8 index; // Reverse look up index for this bank.
    address cToken; // The CToken to draw liquidity from.
    uint reserve; // The reserve portion allocated to Homora protocol.
    uint pendingReserve; // The pending reserve portion waiting to be resolve.
    uint totalDebt; // The last recorded total debt since last action.
    uint totalShare; // The total debt share count across all open positions.
  }

  struct Position {
    address owner; // The owner of this position.
    address collToken; // The ERC1155 token used as collateral for this position.
    uint collId; // The token id used as collateral.
    uint collateralSize; // The size of collateral token for this position.
    uint debtMap; // Bitmap of nonzero debt. i^th bit is set iff debt share of i^th bank is nonzero.
    mapping(address => uint) debtShareOf; // The debt share for each token.
  }

  uint public _GENERAL_LOCK; // TEMPORARY: re-entrancy lock guard.
  uint public _IN_EXEC_LOCK; // TEMPORARY: exec lock guard.
  uint public override POSITION_ID; // TEMPORARY: position ID currently under execution.
  address public override SPELL; // TEMPORARY: spell currently under execution.

  address public caster; // The caster address for untrusted execution.
  IOracle public oracle; // The oracle address for determining prices.
  uint public feeBps; // The fee collected as protocol reserve in basis point from interest.
  uint public override nextPositionId; // Next available position ID, starting from 1 (see initialize).

  address[] public allBanks; // The list of all listed banks.
  mapping(address => Bank) public banks; // Mapping from token to bank data.
  mapping(address => bool) public cTokenInBank; // Mapping from cToken to its existence in bank.
  mapping(uint => Position) public positions; // Mapping from position ID to position data.

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Reentrancy lock guard.
  modifier lock() {
    require(_GENERAL_LOCK == _NOT_ENTERED, 'general lock');
    _GENERAL_LOCK = _ENTERED;
    _;
    _GENERAL_LOCK = _NOT_ENTERED;
  }

  /// @dev Ensure that the function is called from within the execution scope.
  modifier inExec() {
    require(POSITION_ID != _NO_ID, 'not within execution');
    require(SPELL == msg.sender, 'not from spell');
    require(_IN_EXEC_LOCK == _NOT_ENTERED, 'in exec lock');
    _IN_EXEC_LOCK = _ENTERED;
    _;
    _IN_EXEC_LOCK = _NOT_ENTERED;
  }

  /// @dev Ensure that the interest rate of the given token is accrued.
  modifier poke(address token) {
    accrue(token);
    _;
  }

  /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
  /// @param _oracle The oracle smart contract address.
  /// @param _feeBps The fee collected to Homora bank.
  function initialize(IOracle _oracle, uint _feeBps) external initializer {
    __Governable__init();
    _GENERAL_LOCK = _NOT_ENTERED;
    _IN_EXEC_LOCK = _NOT_ENTERED;
    POSITION_ID = _NO_ID;
    SPELL = _NO_ADDRESS;
    caster = address(new HomoraCaster());
    oracle = _oracle;
    require(address(_oracle) != address(0), 'bad oracle address');
    feeBps = _feeBps;
    nextPositionId = 1;
    emit SetOracle(address(_oracle));
    emit SetFeeBps(_feeBps);
  }

  /// @dev Return the current executor (the owner of the current position).
  function EXECUTOR() external view override returns (address) {
    uint positionId = POSITION_ID;
    require(positionId != _NO_ID, 'not under execution');
    return positions[positionId].owner;
  }

  /// @dev Trigger interest accrual for the given bank.
  /// @param token The underlying token to trigger the interest accrual.
  function accrue(address token) public override {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exists');
    uint totalDebt = bank.totalDebt;
    uint debt = ICErc20(bank.cToken).borrowBalanceCurrent(address(this));
    if (debt > totalDebt) {
      uint fee = debt.sub(totalDebt).mul(feeBps).div(10000);
      bank.totalDebt = debt;
      bank.pendingReserve = bank.pendingReserve.add(fee);
    } else if (totalDebt != debt) {
      // We should never reach here because CREAMv2 does not support *repayBorrowBehalf*
      // functionality. We set bank.totalDebt = debt nonetheless to ensure consistency. But do
      // note that if *repayBorrowBehalf* exists, an attacker can maliciously deflate debt
      // share value and potentially make this contract stop working due to math overflow.
      bank.totalDebt = debt;
    }
  }

  /// @dev Convenient function to trigger interest accrual for a list of banks.
  /// @param tokens The list of banks to trigger interest accrual.
  function accrueAll(address[] memory tokens) external {
    for (uint idx = 0; idx < tokens.length; idx++) {
      accrue(tokens[idx]);
    }
  }

  /// @dev Trigger reserve resolve by borrowing the pending amount for reserve.
  /// @param token The underlying token to trigger reserve resolve.
  function resolveReserve(address token) public lock poke(token) {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exists');
    uint pendingReserve = bank.pendingReserve;
    bank.pendingReserve = 0;
    bank.reserve = bank.reserve.add(doBorrow(token, pendingReserve));
  }

  /// @dev Convenient function to trigger reserve resolve for the list of banks.
  /// @param tokens The list of banks to trigger reserve resolve.
  function resolveReserveAll(address[] memory tokens) external {
    for (uint idx = 0; idx < tokens.length; idx++) {
      resolveReserve(tokens[idx]);
    }
  }

  /// @dev Return the borrow balance for given positon and token without trigger interest accrual.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceStored(uint positionId, address token) public view override returns (uint) {
    uint totalDebt = banks[token].totalDebt;
    uint totalShare = banks[token].totalShare;
    uint share = positions[positionId].debtShareOf[token];
    if (share == 0 || totalDebt == 0) {
      return 0;
    } else {
      return share.mul(totalDebt).div(totalShare);
    }
  }

  /// @dev Trigger interest accrual and return the current borrow balance.
  /// @param positionId The position to query for borrow balance.
  /// @param token The token to query for borrow balance.
  function borrowBalanceCurrent(uint positionId, address token) external override returns (uint) {
    accrue(token);
    return borrowBalanceStored(positionId, token);
  }

  /// @dev Return bank information for the given token.
  /// @param token The token address to query for bank information.
  function getBankInfo(address token)
    external
    view
    override
    returns (
      bool isListed,
      address cToken,
      uint reserve,
      uint totalDebt,
      uint totalShare
    )
  {
    Bank storage bank = banks[token];
    return (bank.isListed, bank.cToken, bank.reserve, bank.totalDebt, bank.totalShare);
  }

  /// @dev Return position information for the given position id.
  /// @param positionId The position id to query for position information.
  function getPositionInfo(uint positionId)
    external
    view
    override
    returns (
      address owner,
      address collToken,
      uint collId,
      uint collateralSize
    )
  {
    Position storage pos = positions[positionId];
    return (pos.owner, pos.collToken, pos.collId, pos.collateralSize);
  }

  /// @dev Return the debt share of the given bank token for the given position id.
  function getPositionDebtShareOf(uint positionId, address token) external view returns (uint) {
    return positions[positionId].debtShareOf[token];
  }

  /// @dev Return the list of all debts for the given position id.
  function getPositionDebts(uint positionId)
    external
    view
    returns (address[] memory tokens, uint[] memory debts)
  {
    Position storage pos = positions[positionId];
    uint count = 0;
    uint bitMap = pos.debtMap;
    while (bitMap > 0) {
      if ((bitMap & 1) != 0) {
        count++;
      }
      bitMap >>= 1;
    }
    tokens = new address[](count);
    debts = new uint[](count);
    bitMap = pos.debtMap;
    count = 0;
    uint idx = 0;
    while (bitMap > 0) {
      if ((bitMap & 1) != 0) {
        address token = allBanks[idx];
        Bank storage bank = banks[token];
        tokens[count] = token;
        debts[count] = pos.debtShareOf[token].mul(bank.totalDebt).div(bank.totalShare);
        count++;
      }
      idx++;
      bitMap >>= 1;
    }
  }

  /// @dev Return the total collateral value of the given position in ETH.
  /// @param positionId The position ID to query for the collateral value.
  function getCollateralETHValue(uint positionId) public view returns (uint) {
    Position storage pos = positions[positionId];
    uint size = pos.collateralSize;
    if (size == 0) {
      return 0;
    } else {
      require(pos.collToken != address(0), 'bad collateral token');
      return oracle.asETHCollateral(pos.collToken, pos.collId, size, pos.owner);
    }
  }

  /// @dev Return the total borrow value of the given position in ETH.
  /// @param positionId The position ID to query for the borrow value.
  function getBorrowETHValue(uint positionId) public view override returns (uint) {
    uint value = 0;
    Position storage pos = positions[positionId];
    address owner = pos.owner;
    uint bitMap = pos.debtMap;
    uint idx = 0;
    while (bitMap > 0) {
      if ((bitMap & 1) != 0) {
        address token = allBanks[idx];
        uint share = pos.debtShareOf[token];
        Bank storage bank = banks[token];
        uint debt = share.mul(bank.totalDebt).div(bank.totalShare);
        value = value.add(oracle.asETHBorrow(token, debt, owner));
      }
      idx++;
      bitMap >>= 1;
    }
    return value;
  }

  /// @dev Add a new bank to the ecosystem.
  /// @param token The underlying token for the bank.
  /// @param cToken The address of the cToken smart contract.
  function addBank(address token, address cToken) external onlyGov {
    Bank storage bank = banks[token];
    require(!cTokenInBank[cToken], 'cToken already exists');
    require(!bank.isListed, 'bank already exists');
    cTokenInBank[cToken] = true;
    bank.isListed = true;
    require(allBanks.length < 256, 'reach bank limit');
    bank.index = uint8(allBanks.length);
    bank.cToken = cToken;
    IERC20(token).safeApprove(cToken, 0);
    IERC20(token).safeApprove(cToken, uint(-1));
    allBanks.push(token);
    emit AddBank(token, cToken);
  }

  /// @dev Set the oracle smart contract address.
  /// @param _oracle The new oracle smart contract address.
  function setOracle(IOracle _oracle) external onlyGov {
    oracle = _oracle;
    emit SetOracle(address(_oracle));
  }

  /// @dev Set the fee bps value that Homora bank charges.
  /// @param _feeBps The new fee bps value.
  function setFeeBps(uint _feeBps) external onlyGov {
    require(_feeBps <= 10000, 'fee too high');
    feeBps = _feeBps;
    emit SetFeeBps(_feeBps);
  }

  /// @dev Withdraw the reserve portion of the bank.
  /// @param amount The amount of tokens to withdraw.
  function withdrawReserve(address token, uint amount) external onlyGov lock {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exists');
    bank.reserve = bank.reserve.sub(amount);
    IERC20(token).safeTransfer(msg.sender, amount);
    emit WithdrawReserve(msg.sender, token, amount);
  }

  /// @dev Liquidate a position. Pay debt for its owner and take the collateral.
  /// @param positionId The position ID to liquidate.
  /// @param debtToken The debt token to repay.
  /// @param amountCall The amount to repay when doing transferFrom call.
  function liquidate(
    uint positionId,
    address debtToken,
    uint amountCall
  ) external override lock poke(debtToken) {
    uint collateralValue = getCollateralETHValue(positionId);
    uint borrowValue = getBorrowETHValue(positionId);
    require(collateralValue < borrowValue, 'position still healthy');
    Position storage pos = positions[positionId];
    (uint amountPaid, uint share) = repayInternal(positionId, debtToken, amountCall);
    require(pos.collToken != address(0), 'bad collateral token');
    uint bounty =
      Math.min(
        oracle.convertForLiquidation(debtToken, pos.collToken, pos.collId, amountPaid),
        pos.collateralSize
      );
    pos.collateralSize = pos.collateralSize.sub(bounty);
    IERC1155(pos.collToken).safeTransferFrom(address(this), msg.sender, pos.collId, bounty, '');
    emit Liquidate(positionId, msg.sender, debtToken, amountPaid, share, bounty);
  }

  /// @dev Execute the action via HomoraCaster, calling its function with the supplied data.
  /// @param positionId The position ID to execute the action, or zero for new position.
  /// @param spell The target spell to invoke the execution via HomoraCaster.
  /// @param data Extra data to pass to the target for the execution.
  function execute(
    uint positionId,
    address spell,
    bytes memory data
  ) external payable lock onlyEOA returns (uint) {
    if (positionId == 0) {
      positionId = nextPositionId++;
      positions[positionId].owner = msg.sender;
    } else {
      require(positionId < nextPositionId, 'position id not exists');
      require(msg.sender == positions[positionId].owner, 'not position owner');
    }
    POSITION_ID = positionId;
    SPELL = spell;
    HomoraCaster(caster).cast{value: msg.value}(spell, data);
    uint collateralValue = getCollateralETHValue(positionId);
    uint borrowValue = getBorrowETHValue(positionId);
    require(collateralValue >= borrowValue, 'insufficient collateral');
    POSITION_ID = _NO_ID;
    SPELL = _NO_ADDRESS;
    return positionId;
  }

  /// @dev Borrow tokens from that bank. Must only be called while under execution.
  /// @param token The token to borrow from the bank.
  /// @param amount The amount of tokens to borrow.
  function borrow(address token, uint amount) external override inExec poke(token) {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exists');
    Position storage pos = positions[POSITION_ID];
    uint totalShare = bank.totalShare;
    uint totalDebt = bank.totalDebt;
    uint share = totalShare == 0 ? amount : amount.mul(totalShare).div(totalDebt);
    bank.totalShare = bank.totalShare.add(share);
    uint newShare = pos.debtShareOf[token].add(share);
    pos.debtShareOf[token] = newShare;
    if (newShare > 0) {
      pos.debtMap |= (1 << uint(bank.index));
    }
    IERC20(token).safeTransfer(msg.sender, doBorrow(token, amount));
    emit Borrow(POSITION_ID, msg.sender, token, amount, share);
  }

  /// @dev Repay tokens to the bank. Must only be called while under execution.
  /// @param token The token to repay to the bank.
  /// @param amountCall The amount of tokens to repay via transferFrom.
  function repay(address token, uint amountCall) external override inExec poke(token) {
    (uint amount, uint share) = repayInternal(POSITION_ID, token, amountCall);
    emit Repay(POSITION_ID, msg.sender, token, amount, share);
  }

  /// @dev Perform repay action. Return the amount actually taken and the debt share reduced.
  /// @param positionId The position ID to repay the debt.
  /// @param token The bank token to pay the debt.
  /// @param amountCall The amount to repay by calling transferFrom, or -1 for debt size.
  function repayInternal(
    uint positionId,
    address token,
    uint amountCall
  ) internal returns (uint, uint) {
    Bank storage bank = banks[token];
    require(bank.isListed, 'bank not exists');
    Position storage pos = positions[positionId];
    uint totalShare = bank.totalShare;
    uint totalDebt = bank.totalDebt;
    uint oldShare = pos.debtShareOf[token];
    uint oldDebt = oldShare.mul(totalDebt).div(totalShare);
    if (amountCall == uint(-1)) {
      amountCall = oldDebt;
    }
    uint paid = doRepay(token, doERC20TransferIn(token, amountCall));
    require(paid <= oldDebt, 'paid exceeds debt'); // prevent share overflow attack
    uint lessShare = paid == oldDebt ? oldShare : paid.mul(totalShare).div(totalDebt);
    bank.totalShare = totalShare.sub(lessShare);
    uint newShare = oldShare.sub(lessShare);
    pos.debtShareOf[token] = newShare;
    if (newShare == 0) {
      pos.debtMap &= ~(1 << uint(bank.index));
    }
    return (paid, lessShare);
  }

  /// @dev Transmit user assets to the caller, so users only need to approve Bank for spending.
  /// @param token The token to transfer from user to the caller.
  /// @param amount The amount to transfer.
  function transmit(address token, uint amount) external override inExec {
    Position storage pos = positions[POSITION_ID];
    IERC20(token).safeTransferFrom(pos.owner, msg.sender, amount);
  }

  /// @dev Put more collateral for users. Must only be called during execution.
  /// @param collToken The ERC1155 token to collateral.
  /// @param collId The token id to collateral.
  /// @param amountCall The amount of tokens to put via transferFrom.
  function putCollateral(
    address collToken,
    uint collId,
    uint amountCall
  ) external override inExec {
    Position storage pos = positions[POSITION_ID];
    if (pos.collToken != collToken || pos.collId != collId) {
      require(oracle.support(collToken, collId), 'collateral not supported');
      require(pos.collateralSize == 0, 'another type of collateral already exists');
      pos.collToken = collToken;
      pos.collId = collId;
    }
    uint amount = doERC1155TransferIn(collToken, collId, amountCall);
    pos.collateralSize = pos.collateralSize.add(amount);
    emit PutCollateral(POSITION_ID, msg.sender, collToken, collId, amount);
  }

  /// @dev Take some collateral back. Must only be called during execution.
  /// @param collToken The ERC1155 token to take back.
  /// @param collId The token id to take back.
  /// @param amount The amount of tokens to take back via transfer.
  function takeCollateral(
    address collToken,
    uint collId,
    uint amount
  ) external override inExec {
    Position storage pos = positions[POSITION_ID];
    require(collToken == pos.collToken, 'invalid collateral token');
    require(collId == pos.collId, 'invalid collateral token');
    if (amount == uint(-1)) {
      amount = pos.collateralSize;
    }
    pos.collateralSize = pos.collateralSize.sub(amount);
    IERC1155(collToken).safeTransferFrom(address(this), msg.sender, collId, amount, '');
    emit TakeCollateral(POSITION_ID, msg.sender, collToken, collId, amount);
  }

  /// @dev Internal function to perform borrow from the bank and return the amount received.
  /// @param token The token to perform borrow action.
  /// @param amountCall The amount use in the transferFrom call.
  /// NOTE: Caller must ensure that cToken interest was already accrued up to this block.
  function doBorrow(address token, uint amountCall) internal returns (uint) {
    Bank storage bank = banks[token]; // assume the input is already sanity checked.
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    require(ICErc20(bank.cToken).borrow(amountCall) == 0, 'bad borrow');
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    bank.totalDebt = bank.totalDebt.add(amountCall);
    return balanceAfter.sub(balanceBefore);
  }

  /// @dev Internal function to perform repay to the bank and return the amount actually repaid.
  /// @param token The token to perform repay action.
  /// @param amountCall The amount to use in the repay call.
  /// NOTE: Caller must ensure that cToken interest was already accrued up to this block.
  function doRepay(address token, uint amountCall) internal returns (uint) {
    Bank storage bank = banks[token]; // assume the input is already sanity checked.
    ICErc20 cToken = ICErc20(bank.cToken);
    uint oldDebt = bank.totalDebt;
    require(cToken.repayBorrow(amountCall) == 0, 'bad repay');
    uint newDebt = cToken.borrowBalanceStored(address(this));
    bank.totalDebt = newDebt;
    return oldDebt.sub(newDebt);
  }

  /// @dev Internal function to perform ERC20 transfer in and return amount actually received.
  /// @param token The token to perform transferFrom action.
  /// @param amountCall The amount use in the transferFrom call.
  function doERC20TransferIn(address token, uint amountCall) internal returns (uint) {
    uint balanceBefore = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountCall);
    uint balanceAfter = IERC20(token).balanceOf(address(this));
    return balanceAfter.sub(balanceBefore);
  }

  /// @dev Internal function to perform ERC1155 transfer in and return amount actually received.
  /// @param token The token to perform transferFrom action.
  /// @param id The id to perform transferFrom action.
  /// @param amountCall The amount use in the transferFrom call.
  function doERC1155TransferIn(
    address token,
    uint id,
    uint amountCall
  ) internal returns (uint) {
    uint balanceBefore = IERC1155(token).balanceOf(address(this), id);
    IERC1155(token).safeTransferFrom(msg.sender, address(this), id, amountCall, '');
    uint balanceAfter = IERC1155(token).balanceOf(address(this), id);
    return balanceAfter.sub(balanceBefore);
  }
}

pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/cryptography/MerkleProof.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import './Governable.sol';
import '../interfaces/ICErc20.sol';
import '../interfaces/IWETH.sol';

contract SafeBoxETH is Governable, ERC20, ReentrancyGuard {
  using SafeMath for uint;
  event Claim(address user, uint amount);

  ICErc20 public immutable cToken;
  IWETH public immutable weth;

  address public relayer;
  bytes32 public root;
  mapping(address => uint) public claimed;

  constructor(
    ICErc20 _cToken,
    string memory _name,
    string memory _symbol
  ) public ERC20(_name, _symbol) {
    _setupDecimals(_cToken.decimals());
    IWETH _weth = IWETH(_cToken.underlying());
    __Governable__init();
    cToken = _cToken;
    weth = _weth;
    relayer = msg.sender;
    _weth.approve(address(_cToken), uint(-1));
  }

  function setRelayer(address _relayer) external onlyGov {
    relayer = _relayer;
  }

  function updateRoot(bytes32 _root) external {
    require(msg.sender == relayer || msg.sender == governor, '!relayer');
    root = _root;
  }

  function deposit() external payable nonReentrant {
    weth.deposit{value: msg.value}();
    uint cBalanceBefore = cToken.balanceOf(address(this));
    require(cToken.mint(msg.value) == 0, '!mint');
    uint cBalanceAfter = cToken.balanceOf(address(this));
    _mint(msg.sender, cBalanceAfter.sub(cBalanceBefore));
  }

  function withdraw(uint amount) public nonReentrant {
    _burn(msg.sender, amount);
    uint wethBalanceBefore = weth.balanceOf(address(this));
    require(cToken.redeem(amount) == 0, '!redeem');
    uint wethBalanceAfter = weth.balanceOf(address(this));
    uint wethAmount = wethBalanceAfter.sub(wethBalanceBefore);
    weth.withdraw(wethAmount);
    (bool success, ) = msg.sender.call{value: wethAmount}(new bytes(0));
    require(success, '!withdraw');
  }

  function claim(uint totalReward, bytes32[] memory proof) public nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalReward));
    require(MerkleProof.verify(proof, root, leaf), '!proof');
    uint send = totalReward.sub(claimed[msg.sender]);
    claimed[msg.sender] = totalReward;
    weth.withdraw(send);
    (bool success, ) = msg.sender.call{value: send}(new bytes(0));
    require(success, '!claim');
    emit Claim(msg.sender, send);
  }

  function adminClaim(uint amount) external onlyGov {
    weth.withdraw(amount);
    (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
    require(success, '!adminClaim');
  }

  function claimAndWithdraw(
    uint claimAmount,
    bytes32[] memory proof,
    uint withdrawAmount
  ) external {
    claim(claimAmount, proof);
    withdraw(withdrawAmount);
  }

  receive() external payable {
    require(msg.sender == address(weth), '!weth');
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

pragma solidity >=0.4.24 <0.7.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../GSN/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri) public {
        _setURI(uri);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
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
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

pragma solidity ^0.6.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() public {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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