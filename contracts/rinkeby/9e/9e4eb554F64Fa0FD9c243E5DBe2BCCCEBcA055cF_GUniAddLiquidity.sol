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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface GUniRouter {
  function addLiquidity(
    address pool,
    uint256 amount0Max,
    uint256 amount1Max,
    uint256 amount0Min,
    uint256 amount1Min,
    address receiver
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint256 mintAmount
    );
}

contract GUniAddLiquidity {
  address public constant GUNI_ROUTER = 0x14E6D67F824C3a7b4329d3228807f8654294e4bd;
  address public constant POP = 0xD0Cd466b34A24fcB2f87676278AF2005Ca8A78c4;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant POOL = 0xBBA11b41407dF8793A89b44ee4b50AfAD4508555;

  uint256 public popLiquidity = 0;
  uint256 public usdcLiquidity = 0;
  uint256 public minPopLiquidity = 0;
  uint256 public minUsdcLiquidity = 0;

  address public immutable dao;
  address public immutable admin;

  constructor(address _admin, address _dao) {
    admin = _admin;
    dao = _dao;
  }

  function setLiquidity(
    uint256 _popLiquidity,
    uint256 _usdcLiquidity,
    uint256 _minPopLiquidity,
    uint256 _minUsdcLiquidity
  ) public {
    require(msg.sender == admin, "Sender must be admin");
    require(_popLiquidity <= 750_000e18, "POP liquidity must not exceed maximum");
    require(_usdcLiquidity <= 2_000_000e6, "USDC liquidity must not exceed maximum");
    require(_minPopLiquidity <= _popLiquidity, "min pop liquidity must be less than pop liquidity");
    require(_minUsdcLiquidity <= _usdcLiquidity, "min usdc liquidity must be less than usdc liquidity");

    popLiquidity = _popLiquidity;
    usdcLiquidity = _usdcLiquidity;
    minPopLiquidity = _minPopLiquidity;
    minUsdcLiquidity = _minUsdcLiquidity;
  }

  function addLiquidity() public {
    require(IERC20(POP).transferFrom(msg.sender, address(this), popLiquidity), "Transfer of POP must succeed");
    require(IERC20(USDC).transferFrom(msg.sender, address(this), usdcLiquidity), "Transfer of USDC must succeed");
    IERC20(POP).approve(GUNI_ROUTER, popLiquidity);
    IERC20(USDC).approve(GUNI_ROUTER, usdcLiquidity);
    GUniRouter(GUNI_ROUTER).addLiquidity(POOL, usdcLiquidity, popLiquidity, minUsdcLiquidity, minPopLiquidity, dao);
  }
}