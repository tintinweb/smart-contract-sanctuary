/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.0;

//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}

contract Swap {
    address payable owner;
    mapping(string => address) public routers;
    string[] public routerNames;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _pancake, address _bakery) {
        owner = msg.sender;
        routers["PANCAKE"] = _pancake;
        routers["BAKERY"] = _bakery;
        routerNames.push("PANCAKE");
        routerNames.push("BAKERY");
    }

    receive() external payable {}

    function hasRouter(string memory _router) internal view returns (bool) {
        return (routers[_router] != address(0x0));
    }

    function setExchangeAddresses(
        string[] calldata _names,
        address[] calldata _exchangeAddresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _names.length; i++) {
            if (!hasRouter(_names[i])) {
                routerNames.push(_names[i]);
            }
            routers[_names[i]] = _exchangeAddresses[i];
        }
    }

    function checkPrices(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public view returns (string memory, uint256) {
        uint256 max;
        string memory best;
        for (uint16 i = 0; i < routerNames.length; i++) {
            string memory theRouter = routerNames[i];
            uint256 amountOut = getAmountOutMin(
                _tokenIn,
                _tokenOut,
                theRouter,
                _amountIn
            );
            if (i == 0) {
                max = amountOut;
                best = routerNames[i];
                continue;
            }
            if (amountOut > max) {
                max = amountOut;
                best = routerNames[i];
            }
        }
        return (best, max);
    }

    function smartSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public {
        string memory exchange;
        uint256 amountOut;
        (exchange, amountOut) = checkPrices(_tokenIn, _tokenOut, _amountIn);
        swap(_tokenIn, _tokenOut, exchange, _amountIn, amountOut);
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        string memory _exchange,
        uint256 _amountIn,
        uint256 _amountOut
    ) public {
        require(_amountOut != 0, "AmountOut is 0");
        require(
            hasRouter(_exchange),
            "This Router doesn't have an address saved!"
        );
        address from;
        if (msg.sender == address(this)) {
            from = tx.origin;
        } else {
            from = msg.sender;
        }

        IERC20 tokenIn = IERC20(_tokenIn);

        require(
            tokenIn.transferFrom(from, address(this), _amountIn),
            "Can't access the token"
        );

        address theRouter = routers[_exchange];

        // //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        // //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract
        require(
            tokenIn.approve(theRouter, _amountIn),
            "Couldn't approve token for the router"
        );

        // //path is an array of addresses.
        // //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        // //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        // //then we will call swapExactTokensForTokens
        // //for the deadline we will pass in block.timestamp
        // //the deadline is the latest time the trade is valid for
        IUniswapV2Router(theRouter).swapExactTokensForTokens(
            _amountIn,
            _amountOut,
            path,
            tx.origin,
            block.timestamp
        );
    }

    //this function will return the minimum amount from a swap
    //input the 3 parameters below and it will return the minimum amount out
    //this is needed for the swap function above
    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        string memory _router,
        uint256 _amountIn
    ) public view returns (uint256) {
        require(hasRouter(_router), "This router does not exist");
        //path is an array of addresses.
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountOutMins = IUniswapV2Router(routers[_router])
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function sendBackBnb() external payable onlyOwner {
        uint256 bal = address(this).balance;
        owner.transfer(bal);
    }

    function sendBackToken(address _token) external onlyOwner {
        IERC20 thetoken = IERC20(_token);
        uint256 bal = thetoken.balanceOf(address(this));
        require(bal > 0, "You have no funds in this token");
        thetoken.transfer(owner, bal);
    }
}