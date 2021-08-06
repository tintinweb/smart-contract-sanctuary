/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // sushiswap
        if (factory == 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac) {
            pair = address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            );
        }
        // uniswap
        if (factory == 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) {
            pair = address(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            );
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        )
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract mySwapContract {
    using SafeMath for uint256;
    address
        internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address
        internal constant SUSHISWAP_ROUTER_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Router02 public sushiswapRouter;
    address private _owner;
    mapping(address => bool) addressAuthorized;
    mapping(address => bool) tokenApprovedUniswap;
    mapping(address => bool) tokenApprovedSushiswap;

    event AuthorizedAccessToAddress(address indexed myaddress, bool value);

    function isTokenApproved(address token, address address_router)
        public
        view
        returns (bool)
    {
        return
            address_router == UNISWAP_ROUTER_ADDRESS
                ? tokenApprovedUniswap[token]
                : tokenApprovedSushiswap[token];
    }

    function isAddressAuthorized(address myaddress) public view returns (bool) {
        return addressAuthorized[myaddress];
    }

    constructor() public {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        sushiswapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER_ADDRESS);
        IERC20(uniswapRouter.WETH()).approve(
            address(uniswapRouter),
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
        IERC20(uniswapRouter.WETH()).approve(
            address(sushiswapRouter),
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
        tokenApprovedUniswap[uniswapRouter.WETH()] = true;
        tokenApprovedSushiswap[uniswapRouter.WETH()] = true;
        _owner = msg.sender;
        addressAuthorized[msg.sender] = true;
        addressAuthorized[address(this)] = true;
    }

    function setAddressAllowance(address myaddress, bool value) external {
        require(msg.sender == _owner, "only owner can set address allowance");
        addressAuthorized[myaddress] = value;
        emit AuthorizedAccessToAddress(myaddress, value);
    }

    function approve(address token, address address_router) private {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to approve"
        );
        IERC20(token).approve(
            address_router,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
        if (address_router == UNISWAP_ROUTER_ADDRESS) {
            tokenApprovedUniswap[token] = true;
        }
        if (address_router == SUSHISWAP_ROUTER_ADDRESS) {
            tokenApprovedSushiswap[token] = true;
        }
    }

    function swapEtherForWETH(uint256 amount) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to swapEtherForWETH"
        );
        IWETH(uniswapRouter.WETH()).deposit{value: amount}();
    }

    function swapAllTokensForWETH(
        address token,
        uint256 deadline,
        address router_address
    ) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to swapAllTokensForWETH"
        );
        uint256 amountIn = IERC20(token).balanceOf(address(this));
        require(amountIn > 0, "no balance for this token");
        if (router_address == UNISWAP_ROUTER_ADDRESS) {
            if (!tokenApprovedUniswap[token])
                approve(token, UNISWAP_ROUTER_ADDRESS);
            uint256[] memory amountOutMin = uniswapRouter.getAmountsOut(
                amountIn,
                getPathForTokentoWETH(token)
            );
            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin[amountOutMin.length - 1],
                getPathForTokentoWETH(token),
                address(this),
                deadline
            );
        }
        if (router_address == SUSHISWAP_ROUTER_ADDRESS) {
            if (!tokenApprovedSushiswap[token])
                approve(token, SUSHISWAP_ROUTER_ADDRESS);
            uint256[] memory amountOutMin = sushiswapRouter.getAmountsOut(
                amountIn,
                getPathForTokentoWETH(token)
            );
            sushiswapRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin[amountOutMin.length - 1],
                getPathForTokentoWETH(token),
                address(this),
                deadline
            );
        }
    }

    function frontrunExactTokens(
        uint256 reserveWETHTarget,
        uint256 minWETHProfitable,
        address token,
        uint256 deadline,
        address router_address
    ) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to frontrunExactTokens"
        );
        uint256 reserveWETH = 0;
        uint256 reserveToken = 0;
        if (router_address == UNISWAP_ROUTER_ADDRESS) {
            (reserveWETH, reserveToken) = UniswapV2Library.getReserves(
                uniswapRouter.factory(),
                uniswapRouter.WETH(),
                token
            );
        }
        if (router_address == SUSHISWAP_ROUTER_ADDRESS) {
            (reserveWETH, reserveToken) = UniswapV2Library.getReserves(
                sushiswapRouter.factory(),
                uniswapRouter.WETH(),
                token
            );
        }
        require(reserveWETH > 0, "reserve WETH empty");
        require(reserveToken > 0, "reserve TOKEN empty");
        uint256 desiredWETHamount = reserveWETHTarget.sub(
            reserveWETH,
            "Frontrun not profitable anymore, revert"
        );
        require(
            desiredWETHamount >= minWETHProfitable,
            "Frontrun not profitable anymore, revert"
        );
        uint256 WETH_balance = IERC20(uniswapRouter.WETH()).balanceOf(
            address(this)
        );
        require(WETH_balance > 0, "No WETH balance");
        uint256 maxWETHPossible = WETH_balance < desiredWETHamount
            ? WETH_balance
            : desiredWETHamount;
        require(
            maxWETHPossible >= minWETHProfitable,
            "Frontrun not profitable anymore, revert"
        );
        if (router_address == UNISWAP_ROUTER_ADDRESS) {
            uint256 exactTokenOut = uniswapRouter.getAmountOut(
                maxWETHPossible,
                reserveWETH,
                reserveToken
            );
            uniswapRouter.swapTokensForExactTokens(
                exactTokenOut,
                maxWETHPossible,
                getPathForWETHtoToken(token),
                address(this),
                deadline
            );
        }
        if (router_address == SUSHISWAP_ROUTER_ADDRESS) {
            uint256 exactTokenOut = sushiswapRouter.getAmountOut(
                maxWETHPossible,
                reserveWETH,
                reserveToken
            );
            sushiswapRouter.swapTokensForExactTokens(
                exactTokenOut,
                maxWETHPossible,
                getPathForWETHtoToken(token),
                address(this),
                deadline
            );
        }
    }

    function getPathForWETHtoToken(address token)
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;
        return path;
    }

    function getPathForTokentoWETH(address token)
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        return path;
    }

    function retrieveWei(uint256 amount) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to retrieveWei"
        );
        msg.sender.transfer(amount);
    }

    function retrieveAllWETH() external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to retrieveAllWETH"
        );
        IERC20(uniswapRouter.WETH()).transfer(
            msg.sender,
            IERC20(uniswapRouter.WETH()).balanceOf(address(this))
        );
    }

    function retrieveToken(uint256 amount, address token) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to retrieveToken"
        );
        IERC20(token).transfer(msg.sender, amount);
    }

    // this function is used for checking if a token has a transfer fee on buy and/or sell actions
    // swapExactTokensForTokensSupportingFeeOnTransferTokens with 0% slippage will fail for tokens that have unexpected transfer fees
    // We check for WETH --> TOKEN, and then back from TOKEN --> WETH
    function checkTransferFee(
        address token,
        uint256 deadline,
        address router_address
    ) external {
        require(
            addressAuthorized[msg.sender] == true,
            "msg.sender not authorized to checkTransferFee"
        );
        approve(token, router_address);
        // input 0.1 ether
        // get exact output of token
        uint256[] memory amountTokenOutMin = uniswapRouter.getAmountsOut(
            1e17,
            getPathForWETHtoToken(token)
        );
        // if this fails then there is a transfer fee on buy action
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1e17,
            amountTokenOutMin[amountTokenOutMin.length - 1],
            getPathForWETHtoToken(token),
            address(this),
            deadline
        );
        //
        // if this fails then there is a transfer fee on sell action

        uint256[] memory amountWETHOutMin = uniswapRouter.getAmountsOut(
            amountTokenOutMin[amountTokenOutMin.length - 1],
            getPathForTokentoWETH(token)
        );
        uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountTokenOutMin[amountTokenOutMin.length - 1],
            amountWETHOutMin[amountWETHOutMin.length - 1],
            getPathForTokentoWETH(token),
            address(this),
            deadline
        );
    }

    // important to receive ETH
    receive() external payable {}
}