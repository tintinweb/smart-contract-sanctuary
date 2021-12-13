// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IUniswapV2Router.sol";

contract TokenSwap {

    address public admin;
    address public client;
    address public tok1;
    address public tok2;
    address public router; //["0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"]

    uint256 MAX_INT = 2**256 - 1;

    constructor(address _tok1, address _tok2, address _client, address _router) {
        admin = msg.sender;
        tok1 = _tok1;
        tok2 = _tok2;
        client = _client;
        router = _router;
        approveRouter();
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the manager");
        _;
    }

    function approveRouter() public onlyOwner {
        IERC20(tok1).approve(router, MAX_INT);
    }

    function disapproveRouter() public onlyOwner {
        IERC20(tok1).approve(router, 0);
    }

    function swap(
        uint256 _amountIn,
        uint256 _time
    ) onlyOwner external {
        address[] memory path;
        path = new address[](2);
        path[0] = tok1;
        path[1] = tok2;

        uint256 amountOutMin = 0;
        uint256[] memory amountOutMins = IUniswapV2Router(router)
                .getAmountsOut(_amountIn, path);
        amountOutMin = amountOutMins[1];  //fix not write min!!!!

        IERC20(tok1).transferFrom(client, address(this), _amountIn);
        IUniswapV2Router(router)
            .swapExactTokensForTokens(
                _amountIn,
                amountOutMin,
                path,
                client,
                _time
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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