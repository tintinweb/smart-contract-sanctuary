//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

/**
 * Exempt Surge Interface
 */
contract BabyBuyer {
    
    IUniswapV2Router02 constant router = IUniswapV2Router02(0x325E343f1dE602396E256B67eFd1F61C3A6B38Bd);
    
    address[] path;
    
    address creator;
    
    constructor() {
        creator = msg.sender;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = 0xcEff4b7001Db64e12131ce70FA96f42C4ad52058;
    }
    
    function withdraw(address token, address receiver) external {
        require(msg.sender == creator);
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(receiver, bal);
    }
    
    function purchaseBaby() external payable {
        _purchaseToken(msg.sender, msg.value);   
    }
    
    function purchaseBaby(address receiver) external payable {
        _purchaseToken(receiver, msg.value);
    }
    
    function _purchaseToken(address receiver, uint256 amount) private {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            receiver,
            block.timestamp + 30
        );
    }
	
    // Swap For Useless
    receive() external payable {
        _purchaseToken(msg.sender, msg.value);
    }
    
}