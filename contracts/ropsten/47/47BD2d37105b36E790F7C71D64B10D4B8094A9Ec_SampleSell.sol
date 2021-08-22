/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUniswapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract SampleSell is Context,ReentrancyGuard {
  IUniswapRouter public uniswapRouter;
  mapping(address => uint256) public EthBalance;
  address private uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  constructor() ReentrancyGuard() {
    uniswapRouter = IUniswapRouter(uniswap);
    }
    function SellTokens(address tokenToSend,uint256 tokenAmount) nonReentrant() external {
		IERC20(tokenToSend).transferFrom(_msgSender(), address(this), tokenAmount);
        require(IERC20(tokenToSend).approve(address(uniswap), (tokenAmount + 10000)), 'Uniswap approval failed');
        uint256 currentContractBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = tokenToSend;
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 newContractBalance = address(this).balance;
        EthBalance[_msgSender()] = EthBalance[_msgSender()] + (newContractBalance - currentContractBalance);
    }
    function CollectEth() public {
        require(EthBalance[_msgSender()] > 0);
	    payable(_msgSender()).transfer(EthBalance[_msgSender()]);
        EthBalance[_msgSender()] = 0;
    }
}