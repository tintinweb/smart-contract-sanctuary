// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IMasterChefJoeV2 {
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  struct PoolInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 lastRewardTimestamp;
    uint256 accJoePerShare;
    address rewarder;
  }

  function joe() external view returns (address);

  function poolInfo(uint256 pool) external view returns (PoolInfo memory);

  function userInfo(uint256 pool, address user) external view returns (UserInfo memory);

  function deposit(uint256 pool, uint256 amount) external;

  function withdraw(uint256 pool, uint256 amount) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/DFH/Automate.sol";
import "../utils/DFH/IStorage.sol";
import "../utils/Uniswap/IUniswapV2Router02.sol";
import "../utils/Uniswap/IUniswapV2Pair.sol";
import "./IMasterChefJoeV2.sol";
import {ERC20Tools} from "../utils/ERC20Tools.sol";

contract MasterChefJoeLpRestake is Automate {
  using ERC20Tools for IERC20;

  IMasterChefJoeV2 public staking;

  uint256 public pool;

  uint16 public slippage;

  uint16 public deadline;

  IERC20 public stakingToken;

  IERC20 public rewardToken;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    uint256 _pool,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    staking = IMasterChefJoeV2(_staking);
    pool = _pool;
    slippage = _slippage;
    deadline = _deadline;

    IMasterChefJoeV2.PoolInfo memory poolInfo = staking.poolInfo(pool);
    stakingToken = IERC20(poolInfo.lpToken);
    rewardToken = IERC20(staking.joe());
  }

  function deposit() external onlyOwner {
    stakingToken.safeApproveAll(address(staking));
    staking.deposit(pool, stakingToken.balanceOf(address(this)));
  }

  function refund() external onlyOwner {
    IMasterChefJoeV2 _staking = staking; // gas optimisation
    address __owner = owner(); // gas optimisation
    IMasterChefJoeV2.UserInfo memory userInfo = staking.userInfo(pool, address(this));
    _staking.withdraw(pool, userInfo.amount);
    stakingToken.transfer(__owner, stakingToken.balanceOf(address(this)));
    rewardToken.transfer(__owner, rewardToken.balanceOf(address(this)));
  }

  function _swap(
    address[3] memory path,
    uint256[2] memory amount,
    uint256 _deadline
  ) internal returns (uint256) {
    if (path[1] == path[2]) return amount[0];

    address[] memory _path = new address[](2);
    _path[0] = path[1];
    _path[1] = path[2];

    IERC20(path[2]).safeApproveAll(path[0]); // For add liquidity call
    return
      IUniswapV2Router02(path[0]).swapExactTokensForTokens(amount[0], amount[1], _path, address(this), _deadline)[1];
  }

  function _addLiquidity(
    address[3] memory path,
    uint256[2] memory amountIn,
    uint256[2] memory amountOutMin,
    uint256 _deadline
  ) internal {
    IUniswapV2Router02(path[0]).addLiquidity(
      path[1],
      path[2],
      amountIn[0],
      amountIn[1],
      amountOutMin[0],
      amountOutMin[1],
      address(this),
      _deadline
    );
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256[2] memory _outMin
  ) external bill(gasFee, "AvaxSmartcoinMasterChefJoeLPRestake") {
    IMasterChefJoeV2 _staking = staking; // gas optimization
    IMasterChefJoeV2.UserInfo memory userInfo = staking.userInfo(pool, address(this));
    require(userInfo.rewardDebt > 0, "MasterChefJoeLpRestake::run: no earned");
    address router = IStorage(info()).getAddress(keccak256("Joe:Contract:Router2"));
    require(router != address(0), "MasterChefJoeLpRestake::run: joe router contract not found");

    _staking.deposit(pool, 0); // get all reward
    uint256 rewardAmount = rewardToken.balanceOf(address(this));
    rewardToken.safeApproveAll(router);

    IUniswapV2Pair _stakingToken = IUniswapV2Pair(address(stakingToken));
    address[2] memory tokens = [_stakingToken.token0(), _stakingToken.token1()];
    uint256[2] memory amountIn = [
      _swap([router, address(rewardToken), tokens[0]], [rewardAmount / 2, _outMin[0]], _deadline),
      _swap([router, address(rewardToken), tokens[1]], [rewardAmount - rewardAmount / 2, _outMin[1]], _deadline)
    ];
    uint256[2] memory amountOutMin = [uint256(0), uint256(0)];

    _addLiquidity([router, tokens[0], tokens[1]], amountIn, amountOutMin, _deadline);
    stakingToken.safeApproveAll(address(_staking));
    _staking.deposit(pool, stakingToken.balanceOf(address(this)));
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./proxy/ERC1167.sol";
import "./IStorage.sol";
import "./IBalance.sol";

// solhint-disable avoid-tx-origin
abstract contract Automate {
  using ERC1167 for address;

  /// @notice Storage contract address.
  address internal _info;

  /// @notice Contract owner.
  address internal _owner;

  /// @notice Is contract paused.
  bool internal _paused;

  /// @notice Protocol fee in USD (-1 if value in global storage).
  int256 internal _protocolFee;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event ProtocolFeeChanged(int256 protocolFee);

  constructor(address __info) {
    _info = __info;
    _owner = tx.origin;
    _protocolFee = -1;
  }

  /**
   * @notice Returns address of Storage contract.
   */
  function info() public view returns (address) {
    address impl = address(this).implementation();
    if (impl == address(this)) return _info;

    return Automate(impl).info();
  }

  /// @dev Modifier to protect an initializer function from being invoked twice.
  modifier initializer() {
    if (_owner == address(0)) {
      _owner = tx.origin;
      _protocolFee = -1;
    } else {
      require(_owner == msg.sender, "Automate: caller is not the owner");
    }
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Automate: caller is not the owner");
    _;
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(address(this).implementation() == address(this), "Automate: change the owner failed");

    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev Throws if called by any account other than the pauser.
   */
  modifier onlyPauser() {
    if (address(this).implementation() == address(this)) {
      address pauser = IStorage(info()).getAddress(keccak256("DFH:Pauser"));
      require(msg.sender == _owner || msg.sender == pauser, "Automate: caller is not the pauser");
    } else {
      require(msg.sender == _owner, "Automate: caller is not the pauser");
    }
    _;
  }

  /**
   * @notice Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view returns (bool) {
    address impl = address(this).implementation();
    if (impl == address(this)) return _paused;

    return _paused || Automate(impl).paused();
  }

  /**
   * @dev Throws if contract paused.
   */
  modifier whenPaused() {
    require(paused(), "Automate: not paused");
    _;
  }

  /**
   * @dev Throws if contract unpaused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Automate: paused");
    _;
  }

  /**
   * @notice Pause contract.
   */
  function pause() external onlyPauser whenNotPaused {
    _paused = true;
  }

  /**
   * @notice Unpause contract.
   */
  function unpause() external onlyPauser whenPaused {
    _paused = false;
  }

  /**
   * @return Current protocol fee.
   */
  function protocolFee() public view returns (uint256) {
    address impl = address(this).implementation();
    if (impl != address(this) && _protocolFee < 0) {
      return Automate(impl).protocolFee();
    }

    IStorage __info = IStorage(info());
    uint256 feeOnUSD = _protocolFee < 0 ? __info.getUint(keccak256("DFH:Fee:Automate")) : uint256(_protocolFee);
    if (feeOnUSD == 0) return 0;

    (, int256 price, , , ) = AggregatorV3Interface(__info.getAddress(keccak256("DFH:Fee:PriceFeed"))).latestRoundData();
    require(price > 0, "Automate: invalid price");

    return (feeOnUSD * 1e18) / uint256(price);
  }

  /**
   * @notice Change protocol fee.
   * @param __protocolFee New protocol fee.
   */
  function changeProtocolFee(int256 __protocolFee) external {
    address impl = address(this).implementation();
    require(
      (impl == address(this) ? _owner : Automate(impl).owner()) == msg.sender,
      "Automate::changeProtocolFee: caller is not the protocol owner"
    );

    _protocolFee = __protocolFee;
    emit ProtocolFeeChanged(__protocolFee);
  }

  /**
   * @dev Claim fees from owner.
   * @param gasFee Claim gas fee.
   * @param operation Claim description.
   */
  function _bill(uint256 gasFee, string memory operation) internal whenNotPaused returns (uint256) {
    address account = owner(); // gas optimisation
    if (tx.origin == account) return 0; // free if called by the owner

    IStorage __info = IStorage(info());

    address balance = __info.getAddress(keccak256("DFH:Contract:Balance"));
    require(balance != address(0), "Automate::_bill: balance contract not found");

    return IBalance(balance).claim(account, gasFee, protocolFee(), operation);
  }

  /**
   * @dev Claim fees from owner.
   * @param gasFee Claim gas fee.
   * @param operation Claim description.
   */
  modifier bill(uint256 gasFee, string memory operation) {
    _bill(gasFee, operation);
    _;
  }

  /**
   * @notice Transfer ERC20 token to recipient.
   * @param token The address of the token to be transferred.
   * @param recipient Token recipient address.
   * @param amount Transferred amount of tokens.
   */
  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    IERC20(token).transfer(recipient, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IStorage {
  function getBytes(bytes32 key) external view returns (bytes memory);

  function getBool(bytes32 key) external view returns (bool);

  function getUint(bytes32 key) external view returns (uint256);

  function getInt(bytes32 key) external view returns (int256);

  function getAddress(bytes32 key) external view returns (address);

  function getString(bytes32 key) external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IUniswapV2Router02 {
  function factory() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
interface IUniswapV2Pair is IERC20 {
  function nonces(address owner) external view returns (uint256);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

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

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ERC20Tools {
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 allowance = token.allowance(address(this), spender);
    if (allowance != 0 && allowance < value) {
      token.approve(spender, 0);
    }
    if (allowance != value) {
      token.approve(spender, value);
    }
  }

  function safeApproveAll(IERC20 token, address spender) internal {
    safeApprove(token, spender, 2**256 - 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable no-inline-assembly
library ERC1167 {
  bytes public constant CLONE =
    hex"363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";

  /**
   * @notice Make new proxy contract.
   * @param impl Address prototype contract.
   * @return proxy Address new proxy contract.
   */
  function clone(address impl) external returns (address proxy) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, impl))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, ptr, 0x37)
    }
    require(proxy != address(0), "ERC1167: create failed");
  }

  /**
   * @notice Returns address of prototype contract for proxy.
   * @param proxy Address proxy contract.
   * @return impl Address prototype contract (current contract address if not proxy).
   */
  function implementation(address proxy) external view returns (address impl) {
    uint256 size;
    assembly {
      size := extcodesize(proxy)
    }

    impl = proxy;
    if (size <= 45 && size >= 41) {
      bool matches = true;
      uint256 i;

      bytes memory code;
      assembly {
        code := mload(0x40)
        mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        mstore(code, size)
        extcodecopy(proxy, add(code, 0x20), 0, size)
      }
      for (i = 0; matches && i < 9; i++) {
        matches = code[i] == CLONE[i];
      }
      for (i = 0; matches && i < 15; i++) {
        if (i == 4) {
          matches = code[code.length - i - 1] == bytes1(uint8(CLONE[45 - i - 1]) - uint8(45 - size));
        } else {
          matches = code[code.length - i - 1] == CLONE[45 - i - 1];
        }
      }
      if (code[9] != bytes1(0x73 - uint8(45 - size))) {
        matches = false;
      }
      uint256 forwardedToBuffer;
      if (matches) {
        assembly {
          forwardedToBuffer := mload(add(code, 30))
        }
        forwardedToBuffer &= (0x1 << (20 * 8)) - 1;
        impl = address(uint160(forwardedToBuffer >> ((45 - size) * 8)));
      }
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IBalance {
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/DFH/Automate.sol";
import "../utils/Curve/IRegistry.sol";
import "../utils/Curve/IGauge.sol";
import "../utils/Curve/IMinter.sol";
import "../utils/Curve/IPlainPool.sol";
import "../utils/Curve/IMetaPool.sol";
import "../utils/Uniswap/IUniswapV2Router02.sol";
import {ERC20Tools} from "../utils/ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract GaugeUniswapRestake is Automate {
  using ERC20Tools for IERC20;

  IGauge public staking;

  address public swapToken;

  uint16 public slippage;

  uint16 public deadline;

  IERC20 internal _lpToken;

  address internal _pool;

  uint8 internal _swapTokenN;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _swapToken,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    IRegistry registry = IRegistry(_registry());

    staking = IGauge(_staking);
    swapToken = _swapToken;
    slippage = _slippage;
    deadline = _deadline;
    _lpToken = IERC20(staking.lp_token());
    _pool = registry.get_pool_from_lp_token(address(_lpToken));
    address[8] memory coins = registry.get_coins(_pool);

    for (; _swapTokenN < 9; _swapTokenN++) {
      require(_swapTokenN < 8, "GaugeUniswapRestake::init: invalid swap token address");
      if (coins[_swapTokenN] == _swapToken) break;
    }
  }

  function _registry() internal view returns (address) {
    return IStorage(info()).getAddress(keccak256("Curve:Contract:Registry"));
  }

  function deposit() external onlyOwner {
    _lpToken.safeApproveAll(address(staking));
    staking.deposit(_lpToken.balanceOf(address(this)));
  }

  function refund() external onlyOwner {
    address __owner = owner(); // gas optimisation

    IGauge _staking = staking; // gas optimisation
    uint256 stakingBalance = _staking.balanceOf(address(this));
    if (stakingBalance > 0) {
      _staking.withdraw(stakingBalance);
    }
    uint256 lpBalance = _lpToken.balanceOf(address(this));
    if (lpBalance > 0) {
      _lpToken.transfer(__owner, lpBalance);
    }

    IMinter _minter = IMinter(staking.minter());
    if (_minter.minted(address(this), address(_staking)) > 0) {
      _minter.mint(address(_staking));
    }
    IERC20 rewardToken = IERC20(_staking.crv_token());
    uint256 rewardBalance = rewardToken.balanceOf(address(this));
    if (rewardBalance > 0) {
      rewardToken.transfer(__owner, rewardBalance);
    }
  }

  function _swap(
    address router,
    address[2] memory path,
    uint256 amount,
    uint256 minOut,
    uint256 _deadline
  ) internal returns (uint256) {
    address[] memory _path = new address[](2);
    _path[0] = path[0];
    _path[1] = path[1];

    return IUniswapV2Router02(router).swapExactTokensForTokens(amount, minOut, _path, address(this), _deadline)[1];
  }

  function calcTokenAmount(uint256 amount) external view returns (uint256) {
    address pool = _pool; // gas optimization
    IRegistry registry = IRegistry(_registry());

    if (registry.get_n_coins(pool) == 3) {
      uint256[3] memory amountIn;
      amountIn[_swapTokenN] = amount;
      return IPlainPool(pool).calc_token_amount(amountIn, true);
    } else {
      uint256[2] memory amountIn;
      amountIn[_swapTokenN] = amount;
      return IMetaPool(pool).calc_token_amount(amountIn, true);
    }
  }

  function _addLiquidity(
    address pool,
    uint256 amount,
    uint256 minOut
  ) internal {
    IRegistry registry = IRegistry(_registry());

    if (registry.get_n_coins(pool) == 3) {
      uint256[3] memory amountIn;
      amountIn[_swapTokenN] = amount;
      IPlainPool(pool).add_liquidity(amountIn, minOut);
    } else {
      uint256[2] memory amountIn;
      amountIn[_swapTokenN] = amount;
      IMetaPool(pool).add_liquidity(amountIn, minOut);
    }
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256 swapOutMin,
    uint256 lpOutMin
  ) external bill(gasFee, "CurveGaugeUniswapRestake") {
    IGauge _staking = staking; // gas optimization
    IMinter _minter = IMinter(staking.minter());
    require(_minter.minted(address(this), address(_staking)) > 0, "GaugeUniswapRestake::run: no earned");
    address router = IStorage(info()).getAddress(keccak256("UniswapV2:Contract:Router2"));
    require(router != address(0), "GaugeUniswapRestake::run: uniswap router contract not found");

    _minter.mint(address(staking));
    address rewardToken = _staking.crv_token();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));

    IERC20(rewardToken).safeApproveAll(router);
    uint256 amount = _swap(router, [rewardToken, swapToken], rewardAmount, swapOutMin, _deadline);
    IERC20(swapToken).safeApproveAll(_pool);
    _addLiquidity(_pool, amount, lpOutMin);

    _lpToken.safeApproveAll(address(_staking));
    _staking.deposit(_lpToken.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IRegistry {
  function get_n_coins(address pool) external view returns (uint256);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_pool_from_lp_token(address) external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IGauge {
  function minter() external view returns (address);

  function crv_token() external view returns (address);

  function lp_token() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address recipient) external;

  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IMinter {
  function minted(address wallet, address gauge) external view returns (uint256);

  function mint(address gauge) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IPlainPool {
  function calc_token_amount(uint256[3] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 minMint) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IMetaPool {
  function calc_token_amount(uint256[2] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[2] memory amounts, uint256 minMint) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/DFH/Automate.sol";
import "../utils/DFH/IStorage.sol";
import "../utils/Uniswap/IUniswapV2Router02.sol";
import "../utils/Uniswap/IUniswapV2Pair.sol";
import "../utils/Synthetix/IStaking.sol";
import {ERC20Tools} from "../utils/ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract SynthetixUniswapLpRestake is Automate {
  using ERC20Tools for IERC20;

  IStaking public staking;

  uint16 public slippage;

  uint16 public deadline;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    staking = IStaking(_staking);
    slippage = _slippage;
    deadline = _deadline;
  }

  function deposit() external onlyOwner {
    IStaking _staking = staking; // gas optimisation
    address stakingToken = _staking.stakingToken();
    IERC20(stakingToken).safeApproveAll(address(_staking));
    _staking.stake(IERC20(stakingToken).balanceOf(address(this)));
  }

  function refund() external onlyOwner {
    IStaking _staking = staking; // gas optimisation
    _staking.exit();

    address __owner = owner(); // gas optimisation
    IERC20 stakingToken = IERC20(_staking.stakingToken());
    stakingToken.transfer(__owner, stakingToken.balanceOf(address(this)));

    IERC20 rewardToken = IERC20(_staking.rewardsToken());
    rewardToken.transfer(__owner, rewardToken.balanceOf(address(this)));
  }

  function _swap(
    address[3] memory path,
    uint256[2] memory amount,
    uint256 _deadline
  ) internal returns (uint256) {
    if (path[1] == path[2]) return amount[0];

    address[] memory _path = new address[](2);
    _path[0] = path[1];
    _path[1] = path[2];

    IERC20(path[2]).safeApproveAll(path[0]); // For add liquidity call
    return
      IUniswapV2Router02(path[0]).swapExactTokensForTokens(amount[0], amount[1], _path, address(this), _deadline)[1];
  }

  function _addLiquidity(
    address[3] memory path,
    uint256[4] memory amount,
    uint256 _deadline
  ) internal {
    IUniswapV2Router02(path[0]).addLiquidity(
      path[1],
      path[2],
      amount[0],
      amount[1],
      amount[2],
      amount[3],
      address(this),
      _deadline
    );
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256[2] memory _outMin
  ) external bill(gasFee, "BondappetitSynthetixLPRestake") {
    IStaking _staking = staking; // gas optimization
    require(_staking.earned(address(this)) > 0, "SynthetixUniswapLpRestake::run: no earned");
    address router = IStorage(info()).getAddress(keccak256("UniswapV2:Contract:Router2"));
    require(router != address(0), "SynthetixUniswapLpRestake::run: uniswap router contract not found");

    _staking.getReward();
    address rewardToken = _staking.rewardsToken();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));
    IERC20(rewardToken).safeApproveAll(router);

    IUniswapV2Pair stakingToken = IUniswapV2Pair(_staking.stakingToken());
    address[2] memory tokens = [stakingToken.token0(), stakingToken.token1()];
    uint256[4] memory amount = [
      _swap([router, rewardToken, tokens[0]], [rewardAmount / 2, _outMin[0]], _deadline),
      _swap([router, rewardToken, tokens[1]], [rewardAmount - rewardAmount / 2, _outMin[1]], _deadline),
      0,
      0
    ];

    _addLiquidity([router, tokens[0], tokens[1]], amount, _deadline);
    IERC20(stakingToken).safeApproveAll(address(_staking));
    _staking.stake(IERC20(stakingToken).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IStaking {
  function rewardsToken() external view returns (address);

  function stakingToken() external view returns (address);

  function totalSupply() external view returns (uint256);

  function rewardsDuration() external view returns (uint256);

  function periodFinish() external view returns (uint256);

  function rewardRate() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function earned(address) external view returns (uint256);

  function stake(uint256) external;

  function getReward() external;

  function withdraw(uint256) external;

  function exit() external;

  function notifyRewardAmount(uint256) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../utils/Synthetix/IStaking.sol";

// solhint-disable no-unused-vars
contract StakingMock is IStaking {
  address public override rewardsToken;

  address public override stakingToken;

  uint256 public override periodFinish;

  uint256 public override rewardRate;

  uint256 public override rewardsDuration;

  uint256 public override totalSupply;

  mapping(address => uint256) internal _rewards;

  mapping(address => uint256) internal _balances;

  constructor(
    address _rewardsToken,
    address _stakingToken,
    uint256 _rewardsDuration,
    uint256 _rewardRate
  ) {
    rewardsToken = _rewardsToken;
    stakingToken = _stakingToken;
    rewardsDuration = _rewardsDuration;
    rewardRate = _rewardRate;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function earned(address account) public view override returns (uint256) {
    return _rewards[account];
  }

  function stake(uint256 amount) external override {
    IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
    _balances[msg.sender] += amount;
    totalSupply += amount;
  }

  function withdraw(uint256 amount) public override {
    require(balanceOf(msg.sender) >= amount, "withdraw: transfer amount exceeds balance");

    _balances[msg.sender] -= amount;
    totalSupply -= amount;
    IERC20(stakingToken).transfer(msg.sender, amount);
  }

  function getReward() public override {
    uint256 reward = _rewards[msg.sender];
    require(reward > 0, "getReward: transfer amount exceeds balance");

    _rewards[msg.sender] = 0;
    IERC20(rewardsToken).transfer(msg.sender, reward);
  }

  function exit() external override {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function notifyRewardAmount(uint256 reward) external override {
    IERC20(rewardsToken).transferFrom(msg.sender, address(this), reward);
    _rewards[msg.sender] += reward;
    periodFinish = block.number + rewardsDuration;
  }

  function setReward(address account, uint256 amount) external {
    _rewards[account] += amount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IPlainPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
contract PlainPoolMock is IPlainPool {
  address public lpToken;

  address[3] public tokens;

  constructor(address _lpToken, address[3] memory _tokens) {
    lpToken = _lpToken;
    tokens = _tokens;
  }

  function calc_token_amount(uint256[3] memory amounts, bool) external pure override returns (uint256 minted) {
    for (uint8 i = 0; i < 3; i++) {
      minted += amounts[i];
    }
  }

  function add_liquidity(uint256[3] memory amounts, uint256) external override returns (uint256 minted) {
    for (uint8 i = 0; i < 3; i++) {
      IERC20 token = IERC20(tokens[i]);
      if (amounts[i] > 0) {
        require(token.allowance(msg.sender, address(this)) >= amounts[i], "PlainPoolMock::add_liquidity: token not allowance");
        token.transferFrom(msg.sender, address(this), amounts[i]);
      }
      minted += amounts[i];
    }
    IERC20(lpToken).transfer(msg.sender, minted);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../utils/Curve/IMinter.sol";

contract MinterMock is IMinter {
  IERC20 public crv;

  mapping(address => mapping(address => uint256)) public override minted;

  constructor(address _crv) {
    crv = IERC20(_crv);
  }

  function setMinted(
    address wallet,
    address gauge,
    uint256 amount
  ) external {
    minted[wallet][gauge] = amount;
  }

  function mint(address gauge) external override {
    uint256 amount = minted[msg.sender][gauge];
    minted[msg.sender][gauge] = 0;
    crv.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IMetaPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
contract MetaPoolMock is IMetaPool {
  address public lpToken;

  address[2] public tokens;

  constructor(address _lpToken, address[2] memory _tokens) {
    lpToken = _lpToken;
    tokens = _tokens;
  }

  function calc_token_amount(uint256[2] memory amounts, bool) external pure override returns (uint256 minted) {
    for (uint8 i = 0; i < 2; i++) {
      minted += amounts[i];
    }
  }

  function add_liquidity(uint256[2] memory amounts, uint256) external override returns (uint256 minted) {
    for (uint8 i = 0; i < 2; i++) {
      IERC20 token = IERC20(tokens[i]);
      if (amounts[i] > 0) {
        require(token.allowance(msg.sender, address(this)) >= amounts[i], "MetaPoolMock::add_liquidity: token not allowance");
        token.transferFrom(msg.sender, address(this), amounts[i]);
      }
      minted += amounts[i];
    }
    IERC20(lpToken).transfer(msg.sender, minted);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IGauge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
contract GaugeMock is IGauge {
  address public override minter;

  address public override crv_token;

  address public override lp_token;

  uint256 public override totalSupply;

  mapping(address => uint256) public override balanceOf;

  constructor(
    address _minter,
    address _crvToken,
    address _lpToken
  ) {
    minter = _minter;
    crv_token = _crvToken;
    lp_token = _lpToken;
  }

  function deposit(uint256 amount, address recipient) public override {
    IERC20(lp_token).transferFrom(msg.sender, address(this), amount);
    balanceOf[recipient] += amount;
    totalSupply += amount;
  }

  function deposit(uint256 amount) external override {
    deposit(amount, msg.sender);
  }

  function withdraw(uint256 amount) external override {
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    IERC20(lp_token).transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// solhint-disable no-unused-vars
contract UniswapV2RouterMock {
  mapping(bytes32 => uint256[]) internal _amountsOut;
  address internal _pair;

  constructor(address pair) {
    _pair = pair;
  }

  function setAmountsOut(address[] calldata path, uint256[] calldata amountsOut) external {
    _amountsOut[keccak256(abi.encodePacked(path))] = amountsOut;
  }

  function getAmountsOut(uint256, address[] calldata path) external view returns (uint256[] memory amounts) {
    amounts = _amountsOut[keccak256(abi.encodePacked(path))];
  }

  function swapExactTokensForTokens(
    uint256,
    uint256,
    address[] calldata path,
    address,
    uint256
  ) external returns (uint256[] memory amounts) {
    amounts = _amountsOut[keccak256(abi.encodePacked(path))];
    IERC20(path[path.length - 1]).transfer(msg.sender, amounts[amounts.length - 1]);
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256,
    uint256,
    address,
    uint256
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
    amountA = amountADesired;
    amountB = amountBDesired;
    liquidity = IERC20(_pair).balanceOf(address(this));
    IERC20(_pair).transfer(msg.sender, liquidity);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
  ) ERC20(name, symbol) {
    if (initialSupply > 0) _mint(_msgSender(), initialSupply);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/ERC20Mock.sol";

contract UniswapV2PairMock is ERC20Mock {
  address public token0;
  address public token1;

  constructor(
    address _token0,
    address _token1,
    uint256 initialSupply
  ) ERC20Mock("Uniswap V2", "UNI-V2", initialSupply) {
    token0 = _token0;
    token1 = _token1;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../Automate.sol";

// solhint-disable no-empty-blocks
// solhint-disable avoid-tx-origin
contract AutomateMock is Automate {
  address public staking;

  constructor(address _info) Automate(_info) {}

  function init(address _staking) external initializer {
    staking = _staking;
  }

  function run(
    uint256 gasFee,
    uint256 x,
    uint256 y
  ) external bill(gasFee, "AutomateMock.run") returns (uint256) {
    return x + y;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./ERC1167.sol";

contract ProxyFactory {
  using ERC1167 for address;

  event ProxyCreated(address indexed prototype, address indexed proxy);

  /**
   * @notice Create proxy contract by prototype.
   * @param prototype Address of prototype contract.
   * @param args Encoded call to the init function.
   */
  function create(address prototype, bytes memory args) external returns (address proxy) {
    proxy = prototype.clone();

    if (args.length > 0) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = proxy.call(args);
      require(success, "ProxyFactory::create: proxy initialization failed");
    }

    emit ProxyCreated(prototype, proxy);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../../utils/Curve/IRegistry.sol";

// solhint-disable func-name-mixedcase
contract RegistryMock is IRegistry {
  struct Pool {
    uint256 n;
    address[8] coins;
    address lp;
  }

  mapping(address => Pool) internal _pools;

  address[] internal _addedPools;

  function addPool(address pool, Pool memory data) external {
    _pools[pool] = data;
    _addedPools.push(pool);
  }

  function get_n_coins(address pool) external view override returns (uint256) {
    return _pools[pool].n;
  }

  function get_coins(address pool) external view override returns (address[8] memory) {
    return _pools[pool].coins;
  }

  function get_pool_from_lp_token(address lpToken) external view override returns (address pool) {
    for (uint256 i = 0; i < _addedPools.length; i++) {
      if (_pools[_addedPools[i]].lp == lpToken) pool = _addedPools[i];
    }
  }
}