pragma solidity 0.7.6;

import "IERC20.sol";

interface CryptoSwap {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

interface StableSwap {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract TreasuryConverter {

    IERC20 constant gDAI = IERC20(0x07E6332dD090D287d3489245038daF987955DCFB);
    IERC20 constant gUSDC = IERC20(0xe578C856933D8e1082740bf7661e379Aa2A30b26);
    IERC20 constant gUSDT = IERC20(0x940F41F0ec9ba1A34CF001cc03347ac092F5F6B5);
    IERC20 constant gWBTC = IERC20(0x38aCa5484B8603373Acc6961Ecd57a6a594510A3);

    IERC20 constant WBTC = IERC20(0x321162Cd933E2Be498Cd2267a90534A804051b11);
    IERC20 constant USDT = IERC20(0x049d68029688eAbF473097a2fC38ef61633A3C7A);

    ILendingPool constant lendingPool = ILendingPool(0x9FAD24f572045c7869117160A571B2e50b10d068);
    StableSwap constant gPool = StableSwap(0x0fa949783947Bf6c1b171DB13AEACBB488845B3f);
    CryptoSwap constant triCrypto = CryptoSwap(0x3a1659Ddcf2339Be3aeA159cA010979FB49155FF);
    address constant feeDistributor = 0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8;

    uint256 public lastSwapTimestamp;

    constructor() {
        gUSDT.approve(address(gPool), uint(-1));
        gUSDC.approve(address(gPool), uint(-1));
        WBTC.approve(address(triCrypto), uint(-1));
        USDT.approve(address(lendingPool), uint(-1));
    }

    function swapAndTransfer() public {
        require(block.timestamp > lastSwapTimestamp + 86400 * 3, "Can only call every 3 days");

        uint balance = gUSDC.balanceOf(feeDistributor);
        if (balance > 20000 * 10**6) {
            balance -= 20000 * 10**6;
            if (balance > 50000 * 10**6) balance = 50000 * 10**6;
            gUSDC.transferFrom(feeDistributor, address(this), balance);
        }
        balance = gUSDT.balanceOf(feeDistributor);
        if (balance > 20000 * 10**6) {
            balance -= 20000 * 10**6;
            if (balance > 50000 * 10**6) balance = 50000 * 10**6;
            gUSDT.transferFrom(feeDistributor, address(this), balance);
        }
        balance = gWBTC.balanceOf(feeDistributor);
        if (balance > 0) {
            if (balance > 10**8) balance = 10**8;
            gWBTC.transferFrom(feeDistributor, address(this), balance);
        }

        balance = gWBTC.balanceOf(address(this));
        if (balance > 0) {
            lendingPool.withdraw(address(WBTC), balance, address(this));
            balance = triCrypto.exchange(1, 0, balance, 0);
            lendingPool.deposit(address(USDT), balance, address(this), 0);
        }
        balance = gUSDT.balanceOf(address(this));
        if (balance > 0) {
            gPool.exchange(2, 0, balance, 0);
        }
        balance = gUSDC.balanceOf(address(this));
        if (balance > 0) {
            gPool.exchange(1, 0, balance, 0);
        }

        balance = gDAI.balanceOf(address(this));
        if (balance > 0) {
            gDAI.transfer(feeDistributor, balance);
            lastSwapTimestamp = block.timestamp;
        }
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

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