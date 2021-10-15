// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import './WBNB.sol';

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

interface PancakeSwap {
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

interface BakerySwap {
    function factory() external pure returns (address);

    // function WBNB() external pure returns (address);

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

    function addLiquidityBNB(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountBNB,
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

    function removeLiquidityBNB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountBNB);

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

    function removeLiquidityBNBWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountBNB);

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

    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactBNB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForBNB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapBNBForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountBNB);

    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountBNB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract Arbitrage {

    event NewArbitrage (string fromRouter, string toRouter, uint profit, uint date);
    
    string fromRouter;
    string toRouter;
    mapping (string => address) contractAddresses;
    BakerySwap bakeryRouter;
    PancakeSwap pancakeRouter;
    WBNB wbnb;
    IERC20 token;
    address payable owner;
    
    constructor() payable {
      owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner of this contract can call this function.");
        _;
    }

    function setContracts(string memory _fromRouter, string memory _toRouter, string memory tokenSymbol) public onlyOwner {
        fromRouter = _fromRouter;
        toRouter = _toRouter;
        require (contractAddresses['PancakeSwap'] != address(0));
        pancakeRouter = PancakeSwap(contractAddresses['PancakeSwap']);
        if (keccak256(abi.encodePacked(fromRouter)) == keccak256(abi.encodePacked('PancakeSwap'))) {
            if (keccak256(abi.encodePacked(toRouter)) == keccak256(abi.encodePacked('BakerySwap'))) {
                require (contractAddresses['BakerySwap'] != address(0));
                bakeryRouter = BakerySwap(contractAddresses['BakerySwap']);
            }
        } else {
            if (keccak256(abi.encodePacked(fromRouter)) == keccak256(abi.encodePacked('BakerySwap'))) {
                require (contractAddresses['BakerySwap'] != address(0));
                bakeryRouter = BakerySwap(contractAddresses['BakerySwap']);
            }
        }
        wbnb = WBNB(contractAddresses['WBNB']);
        token = IERC20(contractAddresses[tokenSymbol]);
    }
    
    function setContractAddress(string memory contractName, address contractAddress) public onlyOwner {
        contractAddresses[contractName] = address(contractAddress);
    }
    
    function getContractAddress(string memory contractName) public view onlyOwner returns(address) {
      return contractAddresses[contractName];
    }
    
    function arbitrage(uint256 currencyAmount, uint256 currencyMinAmount, uint256 assetMinAmount) public payable onlyOwner {
        uint256 profit;
        if (keccak256(abi.encodePacked(fromRouter)) == keccak256(abi.encodePacked('BakerySwap')) && keccak256(abi.encodePacked(toRouter)) == keccak256(abi.encodePacked('PancakeSwap'))) {
            profit = arbitrageBakeryToPancake(currencyAmount, currencyMinAmount, assetMinAmount);
        }
        else if (keccak256(abi.encodePacked(fromRouter)) == keccak256(abi.encodePacked('PancakeSwap')) && keccak256(abi.encodePacked(toRouter)) == keccak256(abi.encodePacked('BakerySwap'))) {
            profit = arbitragePancakeToBakery(currencyAmount, currencyMinAmount, assetMinAmount);
        }
        wbnb.transfer(owner, wbnb.balanceOf(address(this)));
        emit NewArbitrage(fromRouter, toRouter, profit, block.timestamp);
    }
    
    function arbitragePancakeToBakery(uint256 currencyAmount, uint256 currencyMinAmount, uint256 assetMinAmount) internal returns(uint256) {
        address[] memory path = new address[](2);
        uint256 assetAmount;
        path[0] = address(wbnb);
        path[1] = address(token);
        pancakeRouter.swapExactETHForTokens{value:currencyAmount}(
          assetMinAmount, 
          path, 
          address(this), 
          block.timestamp
         );
        pancakeRouter.swapExactETHForTokens{value:currencyAmount}(
          assetMinAmount, 
          path, 
          address(this), 
          block.timestamp
         );

        assetAmount = token.balanceOf(address(this));
        token.approve(address(this), assetAmount); 
        path[0] = address(token);
        path[1] = address(wbnb);
        bakeryRouter.swapExactBNBForTokens{value:assetAmount}(
          currencyMinAmount, 
          path, 
          address(this),
          block.timestamp
        );
        uint256 profit = wbnb.balanceOf(address(this)) - currencyAmount;
        return profit;
    }
    
    function arbitrageBakeryToPancake(uint256 currencyAmount, uint256 currencyMinAmount, uint256 assetMinAmount) internal returns(uint256) {
        address[] memory path = new address[](2);
        uint256 assetAmount;
        path[0] = address(wbnb);
        path[1] = address(token);
        bakeryRouter.swapExactBNBForTokens{value:currencyAmount}(
            assetMinAmount, 
            path, 
            address(this),
            block.timestamp
        );

        assetAmount = token.balanceOf(address(this));
        token.approve(address(this), assetAmount); 
        path[0] = address(token);
        path[1] = address(wbnb);
        pancakeRouter.swapExactETHForTokens{value:assetAmount}(
            currencyMinAmount, 
            path, 
            address(this), 
            block.timestamp
        );
        uint256 profit = wbnb.balanceOf(address(this)) - currencyAmount;
        return profit;
    }
    
    receive () external payable  {

    }
}