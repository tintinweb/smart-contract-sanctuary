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
import "./IERC31337.sol";
import "./IaxBNB_Direct.sol";
import "./ReentrancyGuard.sol";

contract wizardDirect is Owned, TokensRecoverable, ReentrancyGuard
{
    using SafeMath for uint256;
    IAxBNB public immutable axBNB;
    IMagic public immutable magic;
    IaxBNB_Direct public immutable axBNBDirect;
    IMagicTransferGate public immutable transferGate; 
    IERC31337 public immutable Wizard;

    uint SLIPPAGE_Wizard =10000; //10%
    
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Factory private uniswapV2Factory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    
    event SlippageSet(uint slippage);

    constructor(IAxBNB _axBNB, IMagic _magic, IaxBNB_Direct _axBNB_Direct, IMagicTransferGate _transferGate, IERC31337 _axBNB_Liquidity)
    {
        axBNB = _axBNB;
        axBNBDirect = _axBNB_Direct;
        transferGate = _transferGate;
        Wizard = _axBNB_Liquidity;
        magic = _magic;

        _axBNB.approve(address(_axBNB_Direct), uint256(-1));
        _magic.approve(address(_axBNB_Direct), uint256(-1));

        _axBNB.approve(address(_transferGate), uint256(-1));
        _magic.approve(address(_transferGate), uint256(-1));

        _axBNB.approve(address(uniswapV2Router), uint256(-1));
        _magic.approve(address(uniswapV2Router), uint256(-1));
        _axBNB_Liquidity.approve(address(uniswapV2Router), uint256(-1));

    }

    receive() external payable
    {
        require (msg.sender == address(axBNB));
    }
   
    // 3 decimal =>1000 = 1% => 
    function setSlippage(uint _slippage_Wizard) external ownerOnly{
        require(_slippage_Wizard<100000,"Cant be more than 100%");
        SLIPPAGE_Wizard=_slippage_Wizard;
        emit SlippageSet(SLIPPAGE_Wizard);
    }

    
    //  BNB => Wizard via LP
    function easyBuy() external payable nonReentrant
    {
        uint256 prevmagicAmount = magic.balanceOf(address(this));
        uint256 prevWizardAmount = Wizard.balanceOf(address(this));

        uint256 tBNB=SafeMath.div(msg.value,2);
        axBNB.deposit{ value: tBNB }();

        uint256 magicAmt = axBNBDirect.easyBuy{ value: tBNB }();
        
        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, axBNB, tBNB, magicAmt);
 
        address LPaddress = uniswapV2Factory.getPair(address(magic), address(axBNB));
        
        IERC20(LPaddress).approve(address(Wizard),LPtokens);

        Wizard.depositTokens(LPaddress, LPtokens);
    
        uint256 currWizardAmount = Wizard.balanceOf(address(this));
        Wizard.transfer(msg.sender,currWizardAmount.sub(prevWizardAmount));

        // // any residue sent back to buyer/seller
        uint256 currmagicAmount = magic.balanceOf(address(this)); 
        if(currmagicAmount>prevmagicAmount)
            magic.transfer(msg.sender,currmagicAmount.sub(prevmagicAmount));
    }


    //  BNB => Wizard
    function easyBuyDirect() external payable nonReentrant
    {

        uint256 magicAmtTotal = axBNBDirect.easyBuy{ value: msg.value }();
               
        // swap magic to Wizard
        address[] memory path = new address[](2);
        path[0] = address(magic);
        path[1] = address(Wizard);
        (uint256[] memory amountsMin) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), magicAmtTotal, path);
        uint256 WizardMin = amountsMin[1].mul(100000-SLIPPAGE_Wizard).div(100000); 

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(magicAmtTotal, WizardMin, path, msg.sender, block.timestamp);
                                                                        
    }


    //  axBNB => Wizard
    function easyBuyFromAXBNB(uint256 axBNBAmt) external nonReentrant returns (uint256)
    {

        uint256 prevAXBNBAmount = axBNB.balanceOf(address(this));
        uint256 prevmagicAmount = magic.balanceOf(address(this));
        uint256 prevWizardAmount = Wizard.balanceOf(address(this));

        axBNB.transferFrom(msg.sender,address(this),axBNBAmt);

        //swap half axBNB to magic    
        uint256 axBNBForBuy = axBNBAmt.div(2);

        uint256 magicAmt = axBNBDirect.easyBuyFromAXBNB(axBNBForBuy);
   
        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, IERC20(axBNB), axBNBForBuy, magicAmt);

        address LPaddress = uniswapV2Factory.getPair(address(magic), address(axBNB));
        
        IERC20(LPaddress).approve(address(Wizard),LPtokens);

        Wizard.depositTokens(LPaddress, LPtokens);

        uint256 WizardCurrBalance=Wizard.balanceOf(address(this));
        Wizard.transfer(msg.sender,WizardCurrBalance.sub(prevWizardAmount));

        // any residue sent back to buyer/seller
        uint256 currmagicAmount = magic.balanceOf(address(this)); 
        uint256 currAXBNBAmount = axBNB.balanceOf(address(this));

        if(currmagicAmount>prevmagicAmount)
            magic.transfer(msg.sender,currmagicAmount.sub(prevmagicAmount));

        if(currAXBNBAmount>prevAXBNBAmount)
            axBNB.transfer(msg.sender,currAXBNBAmount.sub(prevAXBNBAmount));

        return WizardCurrBalance.sub(prevWizardAmount);
  
    }

    //  magic => Wizard
    function easyBuyFromMagic(uint256 magicAmt) external nonReentrant
    {
        uint256 prevWizardAmount = Wizard.balanceOf(address(this));
        uint256 prevaxBNBAmount = axBNB.balanceOf(address(this));
        uint256 prevmagicAmount = magic.balanceOf(address(this));

        magic.transferFrom(msg.sender,address(this),magicAmt);
        
        //swap half axBNB to magic    
        uint256 magicForBuy = magicAmt.div(2);

        uint256 axBNBAmt = axBNBDirect.easySellToAXBNB(magicForBuy);
   
        (, ,  uint256 LPtokens) =transferGate.safeAddLiquidity(uniswapV2Router, IERC20(axBNB), axBNBAmt, magicForBuy);

        address LPaddress = uniswapV2Factory.getPair(address(magic), address(axBNB));
        
        IERC20(LPaddress).approve(address(Wizard),LPtokens);

        Wizard.depositTokens(LPaddress, LPtokens);
        
        uint256 currWizardAmount = Wizard.balanceOf(address(this));
        Wizard.transfer(msg.sender,currWizardAmount.sub(prevWizardAmount));

        // any residue sent back to buyer/seller
        uint256 curraxBNBAmount = axBNB.balanceOf(address(this));
        uint256 currmagicAmount = magic.balanceOf(address(this)); 

        if(currmagicAmount>prevmagicAmount)
            magic.transfer(msg.sender,currmagicAmount.sub(prevmagicAmount));
        
        if(curraxBNBAmount>prevaxBNBAmount)
            axBNB.transfer(msg.sender,curraxBNBAmount.sub(prevaxBNBAmount));

    }

    //  magic => Wizard
    function easyBuyFromMagicDirect(uint256 magicAmt) external nonReentrant
    {
        magic.transferFrom(msg.sender,address(this),magicAmt);
        
        address[] memory path = new address[](2);
        path[0] = address(magic);
        path[1] = address(Wizard);
        (uint256[] memory amountsMin) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), magicAmt, path);
        uint256 WizardOutMin = amountsMin[1].mul(SafeMath.sub(100000,SLIPPAGE_Wizard)).div(100000);// fee Wizard

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(magicAmt, WizardOutMin, path, msg.sender, block.timestamp);

    }

     //  Wizard => Magic
    function easySellToMagic(uint256 wizardAmt) external nonReentrant
    {

        Wizard.transferFrom(msg.sender,address(this),wizardAmt);

        address[] memory path = new address[](2);
        path[0] = address(Wizard);
        path[1] = address(magic);
        (uint256[] memory amountsMin) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), wizardAmt, path);
        uint256 magicOutMin = amountsMin[1].mul(SafeMath.sub(100000, SLIPPAGE_Wizard)).div(100000); // fee magic

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wizardAmt, magicOutMin, path, msg.sender, block.timestamp);

    }


    //  Wizard => axBNB
    function easySellToAXBNB(uint256 wizardAmt) external nonReentrant
    {
        uint256 prevmagicAmount = magic.balanceOf(address(this));
        uint256 prevaxBNBAmount = axBNB.balanceOf(address(this));

        Wizard.transferFrom(msg.sender,address(this),wizardAmt);
      
        address[] memory path = new address[](2);
        path[0] = address(Wizard);
        path[1] = address(magic);
        (uint256[] memory amountsMin) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), wizardAmt, path);
        uint256 magicOutMin = amountsMin[1].mul(SafeMath.sub(100000,SLIPPAGE_Wizard)).div(100000); 

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wizardAmt, magicOutMin, path, address(this), block.timestamp);

        uint256 magicAmtAfterSwap = magic.balanceOf(address(this));
        axBNBDirect.easySellToAXBNB(magicAmtAfterSwap.sub(prevmagicAmount));

        uint256 curraxBNBAmount = axBNB.balanceOf(address(this));
        axBNB.transfer(msg.sender,curraxBNBAmount.sub(prevaxBNBAmount));

        // any residue sent back to buyer/seller
        uint256 currmagicAmount = magic.balanceOf(address(this)); 
        if(currmagicAmount>prevmagicAmount)
            magic.transfer(msg.sender,currmagicAmount.sub(prevmagicAmount));
    }


    //  Wizard => BNB
    function easySellToBNB(uint256 wizardAmt) external nonReentrant
    {
        uint256 prevmagicAmount = magic.balanceOf(address(this));
        uint256 prevaxBNBAmount = axBNB.balanceOf(address(this));
        
        Wizard.transferFrom(msg.sender,address(this),wizardAmt);
            
        address[] memory path = new address[](2);
        path[0] = address(Wizard);
        path[1] = address(magic);
        (uint256[] memory amountsMin) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), wizardAmt, path);
        uint256 magicOutMin = amountsMin[1].mul(SafeMath.sub(100000,SLIPPAGE_Wizard)).div(100000); 

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(wizardAmt, magicOutMin, path, address(this), block.timestamp);
                                                                        
        uint256 magicAmtSwapped = magic.balanceOf(address(this)).sub(prevmagicAmount);

        uint256 axBNBAmt = axBNBDirect.easySellToAXBNB(magicAmtSwapped);

        uint remAmount = axBNBAmt;
        if(axBNB.isIgnored(msg.sender)==false){
            uint feeAmount= axBNBAmt.mul(axBNB.FEE()).div(100000);
            remAmount = axBNBAmt.sub(feeAmount);
            axBNB.transfer(axBNB.FEE_ADDRESS(), feeAmount);
        }

        axBNB.withdraw(remAmount);

        (bool success,) = msg.sender.call{ value: remAmount }("");
        require (success, "Transfer failed");
        
        // any residue sent back to buyer/seller
        if(magic.balanceOf(address(this))>prevmagicAmount)
            magic.transfer(msg.sender,magic.balanceOf(address(this)).sub(prevmagicAmount));
        
        if(axBNB.balanceOf(address(this))>prevaxBNBAmount)
            axBNB.transfer(msg.sender,axBNB.balanceOf(address(this)).sub(prevaxBNBAmount));

    }
}