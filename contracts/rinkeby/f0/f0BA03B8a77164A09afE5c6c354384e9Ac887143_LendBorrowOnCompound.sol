// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Compound_CTokenInterface.sol';
import './Compound_ComptrollerInterface.sol';
import './Compound_PriceOracle.sol';

contract LendBorrowOnCompound {
  ComptrollerInterface public comptroller;
  PriceOracle public priceOracle;

  constructor(address _comptroller, address _priceOracle) {
    comptroller = ComptrollerInterface(_comptroller);
    priceOracle = PriceOracle(_priceOracle);
  }

  function supply(address cTokenAddress, uint256 underlyingAmount) public {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    address underlyingAddress = cToken.underlying();
    IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
    uint256 result = cToken.mint(underlyingAmount);
    require(
      result == 0,
      'cToken#mint() failed. see Compound ErrorReporter.sol for details'
    );
  }

  function redeem(address cTokenAddress, uint256 cTokenAmount) external {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    uint256 result = cToken.redeem(cTokenAmount);
    require(
      result == 0,
      'cToken#redeem() failed. see Compound ErrorReporter.sol for more details'
    );
  }

  function enterMarket(address cTokenAddress) external {
    address[] memory markets = new address[](1);
    markets[0] = cTokenAddress;
    uint256[] memory results = comptroller.enterMarkets(markets);
    require(
      results[0] == 0,
      'comptroller#enterMarket() failed. see Compound ErrorReporter.sol for details'
    );
  }

  function borrow(address cTokenAddress, uint256 borrowAmount) external {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    // address underlyingAddress = cToken.underlying();
    uint256 result = cToken.borrow(borrowAmount);
    require(
      result == 0,
      'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
    );
  }

  function repayBorrow(address cTokenAddress, uint256 underlyingAmount)
    external
  {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    address underlyingAddress = cToken.underlying();
    IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
    uint256 result = cToken.repayBorrow(underlyingAmount);
    require(
      result == 0,
      'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
    );
  }

  function getMaxBorrow(address cTokenAddress) external view returns (uint256) {
    (uint256 result, uint256 liquidity, uint256 shortfall) = comptroller
      .getAccountLiquidity(address(this));
    require(
      result == 0,
      'comptroller#getAccountLiquidity() failed. see Compound ErrorReporter.sol for details'
    );
    require(shortfall == 0, 'account underwater');
    require(liquidity > 0, 'account does not have collateral');
    uint256 underlyingPrice = priceOracle.getUnderlyingPrice(cTokenAddress);
    return liquidity / underlyingPrice;
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CTokenInterface {
  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ComptrollerInterface {
  function enterMarkets(address[] calldata cTokens)
    external
    returns (uint256[] memory);

  function getAccountLiquidity(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PriceOracle {
  function getUnderlyingPrice(address cTokenAddress)
    external
    view
    returns (uint256);
}