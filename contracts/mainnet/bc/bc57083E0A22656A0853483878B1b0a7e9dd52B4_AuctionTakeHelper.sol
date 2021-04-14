/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.6.6;


interface IERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

// File: contracts/interfaces/ICollateralAuction.sol

pragma solidity ^0.6.6;



interface ICollateralAuction {
    function baseToken() external returns(IERC20);

    function auctions(uint256 _auctionId) external view returns (
        IERC20 fromToken,    // Token that we are intending to sell
        uint64 startTime,    // Start time of the auction
        uint32 limitDelta,   // Limit time until all collateral is offered
        uint256 startOffer,  // Start offer of `fromToken` for the requested `amount`
        uint256 amount,      // Amount that we need to receive of `baseToken`
        uint256 limit        // Limit of how much are willing to spend of `fromToken`
    );

    function getAuctionsLength() external view returns (uint256);
    function take(uint256 _id, bytes calldata _data, bool _callback) external;

    // return How much is being requested and how much is being offered
    function offer(uint256 _auctionId) external view returns (uint256 selling, uint256 requesting);
}

// File: contracts/test/WETH9.sol

pragma solidity ^0.6.1;


contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad, "The sender dont have balance");
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

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad, "The sender dont have balance");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "The sender dont have allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.6.6;


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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

// File: contracts/utils/Ownable.sol

pragma solidity ^0.6.1;


contract Ownable {
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    address internal _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "The owner should be the sender");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// File: contracts/AuctionTakeHelper.sol

pragma solidity ^0.6.1;







/**
  @author Victor Fage <[email protected]>
*/
contract AuctionTakeHelper is Ownable {
	ICollateralAuction public collateralAuction;
	IERC20 public baseToken;

	IUniswapV2Router02 public router;
	IERC20 public WETH;

	constructor(ICollateralAuction _collateralAuction, IUniswapV2Router02 _router) public {
		collateralAuction = _collateralAuction;
		baseToken = collateralAuction.baseToken();

		setRouter(_router);
		reApprove();
	}

	function getProfitAmount(uint256 _auctionId) external view returns(uint256) {
		(IERC20 fromToken,,,,,) = collateralAuction.auctions(_auctionId);

		if (fromToken == baseToken)
			return 0;

		(uint256 amountGet, uint256 amountReturn) = collateralAuction.offer(_auctionId);

		address[] memory path = new address[](2);
		uint256[] memory amounts;

		if (fromToken != WETH) {
			// Calculate amount get in WETH, converting fromToken to WETH
			path[0] = address(fromToken);
			path[1] = address(WETH);
			amounts = router.getAmountsIn(amountGet, path);
			amountGet = amounts[1];
		}

		// Calculate amount return in WETH, converting WETH to baseToken, to pay the auction
		path[0] = address(WETH);
		path[1] = address(baseToken);
		amounts = router.getAmountsOut(amountReturn, path);
		amountReturn = amounts[0];

		return amountGet >= amountReturn ? amountGet - amountReturn : 0;
	}

	function take(uint256 _auctionId, bytes calldata _data, uint256 _profit) external {
		collateralAuction.take(_auctionId, _data, true);

		uint256 wethBal = WETH.balanceOf(address(this));
		require(wethBal >= _profit, "take: dont get profit");

		if (wethBal != 0) {
			WETH9(payable(address(WETH))).withdraw(wethBal);
			payable(_owner).transfer(wethBal);
		}
	}

	function onTake(IERC20 _fromToken, uint256 _amountGet, uint256 _amountReturn) external {
		require(msg.sender == address(collateralAuction), "onTake: The sender should be the collateralAuction");

		if (_fromToken == baseToken)
			return;

		address[] memory path = new address[](2);

		if (_fromToken != WETH) {
			_fromToken.approve(address(router), _amountGet);

			// Converting fromToken to WETH
			path[0] = address(_fromToken);
			path[1] = address(WETH);
			uint256[] memory amounts = router.swapExactTokensForTokens({
				amountIn:     _amountGet,
				amountOutMin: 0,
				path: 				path,
				to: 					address(this),
				deadline: 		uint(-1)
			});
			_amountGet = amounts[1];
		}

		// Converting WETH to baseToken, to pay the auction
		path[0] = address(WETH);
		path[1] = address(baseToken);
		router.swapTokensForExactTokens({
			amountOut: 	 _amountReturn,
			amountInMax: _amountGet,
			path: 			 path,
			to:				   address(this),
			deadline: 	 uint(-1)
		});
	}

	fallback() external payable { }

	receive() external payable { }

	function withdrawERC20(IERC20 _token) external onlyOwner {
		require(_token.transfer(_owner, _token.balanceOf(address(this))), "withdraw: error transfer the tokens");
	}

	function withdrawETH() external onlyOwner {
		payable(_owner).transfer(address(this).balance);
	}

	function setRouter(IUniswapV2Router02 _router) public onlyOwner {
		router = _router;
		WETH = IERC20(router.WETH());
	}

	function reApprove() public onlyOwner {
		WETH.approve(address(router), uint(-1));
		baseToken.approve(address(collateralAuction), uint(-1));
	}
}