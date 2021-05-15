/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity ^0.7.3;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUniswap {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract SimpleTokenSwap {

    event pathEvent(address[] path);

    // Creator of this contract.
    address public owner;
    address public UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswap public uniswap;

    constructor() {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function swapWEth(address tokenAddress, uint amountOut, address to, uint deadline) external onlyOwner payable {
        require(IERC20(tokenAddress).approve(UNISWAP_ROUTER_ADDRESS, uint256(-1)));
        address[] memory path = getPathForTokenToETH(tokenAddress);
        emit pathEvent(path);
        uniswap.swapETHForExactTokens{ value: msg.value }(amountOut, path, to, deadline);
    }

    function getPathForTokenToETH(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[1] = token;
        path[0] = uniswap.WETH();

        return path;
    }

}