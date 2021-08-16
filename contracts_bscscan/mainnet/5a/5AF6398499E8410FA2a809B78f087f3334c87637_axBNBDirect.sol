// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IMagic.sol";
import "./IAxBNB.sol";
import "./TokensRecoverable.sol";
import "./Owned.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./IMagicTransferGate.sol";
import "./IUniswapV2Router02.sol";
import "./ReentrancyGuard.sol";

contract axBNBDirect is Owned, TokensRecoverable, ReentrancyGuard
{
    using SafeMath for uint256;

    IAxBNB immutable axBNB;
    IGatedERC20 immutable magic;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);

    uint slippage = 5000; // 5000 for 5%
    event SlippageSet(uint slippage);

    constructor(address payable _axBNB, address payable _magic)
    {
        axBNB = IAxBNB(_axBNB);
        magic = IGatedERC20(_magic);

        IAxBNB(_axBNB).approve(address(uniswapV2Router), uint256(-1));
        IGatedERC20(_magic).approve(address(uniswapV2Router), uint256(-1));
    }

    receive() external payable
    {
        require (msg.sender == address(axBNB));
    }

    // 3 decimal =>1000 = 1% => 
    function setSlippage(uint _slippage) external ownerOnly{
        require(_slippage<100000,"Cant be more than 100%");
        slippage=_slippage;
        emit SlippageSet(slippage);
    }

    function estimateBuy(uint256 axBNBAmountIn) public view returns (uint256 magicAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(axBNB);
        path[1] = address(magic);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), axBNBAmountIn, path);
        return amounts[1];
    }

    function estimateSell(uint256 magicAmountIn) public view returns (uint256 ethAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(magic);
        path[1] = address(axBNB);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), magicAmountIn, path);
        return amounts[1];
    }

    function easyBuy() public payable returns (uint256 magicAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return buy(estimateBuy(msg.value).mul(slippageFactor).div(100));
    }

     function easyBuyFromAXBNB(uint256 axBNBIn) public returns (uint256 magicAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return buyFromAXBNB(axBNBIn, (estimateBuy(axBNBIn).mul(slippageFactor).div(100)));
    }

    function easySell(uint256 magicAmountIn) public returns (uint256 axBNBAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return sell(magicAmountIn, estimateSell(magicAmountIn).mul(slippageFactor).div(100));
    }

    function easySellToAXBNB(uint256 magicAmountIn) public returns (uint256 axBNBAmount)
    {
        uint slippageFactor=(SafeMath.sub(100000,slippage)).div(1000); // 100 - slippage => will return like 98000/1000 = 98 for default
        return sellForAXBNB(magicAmountIn, estimateSell(magicAmountIn).mul(slippageFactor).div(100));
    }

    function buy(uint256 magicOutMin) public payable nonReentrant returns (uint256 magicAmount)
    {
        uint256 amount = msg.value;
        require (amount > 0, "Send BNB In to buy");
        uint256 magicPrev=magic.balanceOf(address(this));

        axBNB.deposit{ value: amount}();

        address[] memory path = new address[](2);
        path[0] = address(axBNB);
        path[1] = address(magic);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, magicOutMin, path, address(this), block.timestamp);
        uint256 magicCurr=magic.balanceOf(address(this));

        magicAmount = magicCurr.sub(magicPrev);
        magic.transfer(msg.sender, magicAmount);// transfer magic swapped

        return magicAmount; // fee will cut on this if not IGNORED_ADDRESS;
    }

    function buyFromAXBNB(uint256 axBNBIn, uint256 magicOutMin) public nonReentrant returns (uint256 magicAmount)
    {

        uint256 magicPrev=magic.balanceOf(address(this));

        axBNB.transferFrom(msg.sender,address(this),axBNBIn);
        
        address[] memory path = new address[](2);
        path[0] = address(axBNB);
        path[1] = address(magic);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(axBNBIn, magicOutMin, path, address(this), block.timestamp);
        uint256 magicCurr=magic.balanceOf(address(this));

        magicAmount = magicCurr.sub(magicPrev);
        magic.transfer(msg.sender, magicAmount);// transfer magic swapped
        
        return magicAmount; // fee will cut on this if not IGNORED_ADDRESS;
     }



    function sell(uint256 magicAmountIn, uint256 axBNBOutMin) public nonReentrant returns (uint256 bnbAmount)
    {
        require (magicAmountIn > 0, "Nothing to sell");
        IMagicTransferGate gate = IMagicTransferGate(address(magic.transferGate()));

        uint256 prevaxBNBAmount = axBNB.balanceOf(address(this));

        // to avoid double taxation
        gate.setUnrestricted(true);
        magic.transferFrom(msg.sender, address(this), magicAmountIn);
        gate.setUnrestricted(false);

        address[] memory path = new address[](2);
        path[0] = address(magic);
        path[1] = address(axBNB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(magicAmountIn, axBNBOutMin, path, address(this), block.timestamp);
        uint256 currAXBNBAmount = axBNB.balanceOf(address(this));

        uint256 axBNBAmount = currAXBNBAmount.sub(prevaxBNBAmount);
    
        // will be applied only if BNB payout is happening 
        //else IGNORED_ADDRESSES in axBNB will handle
        if(!axBNB.isIgnored(msg.sender)){

            uint feeAXBNB = axBNB.FEE();
            address feeAddress = axBNB.FEE_ADDRESS();

            uint feeAmount= axBNBAmount.mul(feeAXBNB).div(100000);
            uint remAmount = axBNBAmount.sub(feeAmount);
            axBNB.transfer(feeAddress, feeAmount);
            axBNB.withdraw(remAmount);
            msg.sender.transfer(remAmount);
            return remAmount;
        }
        else{
            axBNB.withdraw(axBNBAmount);
            msg.sender.transfer(axBNBAmount);
            return axBNBAmount;
        }
    }


    function sellForAXBNB(uint256 magicAmountIn, uint256 axBNBOutMin) public nonReentrant returns (uint256 axBNBAmount)
    {
        require (magicAmountIn > 0, "Nothing to sell");
        IMagicTransferGate gate = IMagicTransferGate(address(magic.transferGate()));
        uint256 prevaxBNBAmount = axBNB.balanceOf(address(this));

        // to avoid double taxation
        gate.setUnrestricted(true);
        magic.transferFrom(msg.sender, address(this), magicAmountIn);
        gate.setUnrestricted(false);

        address[] memory path = new address[](2);
        path[0] = address(magic);
        path[1] = address(axBNB);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(magicAmountIn, axBNBOutMin, path, address(this), block.timestamp);
        uint256 currAXBNBAmount = axBNB.balanceOf(address(this));
        axBNBAmount = currAXBNBAmount.sub(prevaxBNBAmount);
        axBNB.transfer(msg.sender, axBNBAmount);
        
        return axBNBAmount;
    }

}