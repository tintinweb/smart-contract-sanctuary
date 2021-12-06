/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;
// use latest solidity version at time of writing, need not worry about overflow and underflow

interface IUniwap{

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external
    returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}




contract OasisDemoSwap {
    string  public name = "OasisPay Demo";
    IUniwap uniswap;
    address internal constant _uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    constructor() {
        uniswap = IUniwap(_uniswap);
    }


    event autoswapEvent(
        address account,
        string orderId,
        uint amount
    );


    function autoSwap(
        string memory orderId,
        address token, // from coin
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
    external{
        IERC20(token).transferFrom(msg.sender,address(this),amountIn);
        require(IERC20(token).approve(address(uniswap),amountIn),'approve error');
        uniswap.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        // send event
        emit autoswapEvent(msg.sender,orderId,amountIn);
    }

    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline)
    external{
        IERC20(token).transferFrom(msg.sender,address(this),amountIn);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        require(IERC20(token).approve(address(uniswap),amountIn),'approve error');
        uniswap.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function autoSwapWithSystemFee(
        string memory orderId,
        address token, // from coin
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        address payable _system_fee_address
    )
    payable external{
        IERC20(token).transferFrom(msg.sender,address(this),amountIn);
        require(IERC20(token).approve(address(uniswap),amountIn),'approve error');
        uniswap.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        // send system fee
        bool sent = _system_fee_address.send(msg.value);
        require(sent, "Failed to send Ether");
        // send event
        emit autoswapEvent(msg.sender,orderId,amountIn);
    }

    function transferWithSystemFee(
        string memory orderId,
        address token, // from coin
        uint amountIn,
        address to,
        address payable _system_fee_address
    )
   payable external {
        IERC20(token).transferFrom(msg.sender,address(this),amountIn);
        IERC20(token).transfer(address(to),amountIn);
        // send system fee
        bool sent = _system_fee_address.send(msg.value);
        require(sent, "Failed to send Ether");
        // send event
        emit autoswapEvent(msg.sender,orderId,amountIn);
    }
    
}