// SPDX-License-Identifier: MIT


import "./StratManager.sol";
import "./FeeManager.sol";
import "./GasThrottler.sol";
import "./SafeERC20.sol";
import "./IUniswapRouterETH.sol";
import "./IUniswapV2Pair.sol";
import "./Pausable.sol";

pragma solidity ^0.6.0;

contract LiquidGenerator is StratManager, FeeManager, GasThrottler {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address constant public xscr = address(0x9980ad0D67A7D15551D659a4bC0AbA3f79b3F722);
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public btcb = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    address constant public busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant public eth  = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    address constant public bifi = address(0xCa3F508B8e4Dd382eE878A314789373D80A5190A);

    address constant public XSCR_WBNB_LP_Token = address (0x4eaaA803dF65D8c18C0Bd87d54e641813B2BFEAC);
    address constant public XSCR_BTCB_LP_Token = address (0x7Cd72B9e75fDB0c70ccA79860ac5C1572bc597e6);
    address constant public XSCR_BUSD_LP_Token = address (0xA4e250A9EaFdEb560aA4107E4e734681a1060B58);
    address constant public XSCR_ETH_LP_Token = address (0x9a2f30824D54831B4235b3974A86B6aD659cff7C);
    address constant public XSCR_BIFI_LP_Token = address (0x54cB640f24d437764d0F254857E9C0719Bd94328);

   // Routes
    address[] public wbnbToBtcbRoute = [wbnb, btcb];
    address[] public wbnbToBusdRoute = [wbnb, busd];
    address[] public wbnbToEthRoute = [wbnb, eth];
    address[] public wbnbToBifiRoute = [wbnb, bifi];
    address[] public wbnbToXSCRRoute = [wbnb, btcb, xscr];


    uint256 public lp1PercentBuy = 20;
    uint256 public lp2PercentBuy = 50;
    uint256 public lp3PercentBuy = 10;
    uint256 public lp4PercentBuy = 10;
    uint256 public lp5PercentBuy = 10;


   function setLp1PercentBuy(uint256 _lp1PercentBuy) external onlyOwner {
        lp1PercentBuy = _lp1PercentBuy;
    }

    function setLp2PercentBuy(uint256 _lp2PercentBuy) external onlyOwner {
        lp2PercentBuy = _lp2PercentBuy;
    }

    function setLp3PercentBuy(uint256 _lp3PercentBuy) external onlyOwner {
        lp3PercentBuy = _lp3PercentBuy;
    }

    function setLp4PercentBuy(uint256 _lp4PercentBuy) external onlyOwner {
        lp4PercentBuy = _lp4PercentBuy;
    }

   function setLp5PercentBuy(uint256 _lp5PercentBuy) external onlyOwner {
        lp5PercentBuy = _lp5PercentBuy;
    }
    

    // performance fees
    function chargeFees() internal {
        uint256 FeeAmount = IERC20(wbnb).balanceOf(address(this)).div(100).mul(feePercentBuy);

        if (FeeAmount < 0){
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(FeeAmount, 0, wbnbToXSCRRoute, address(this), now);

        uint256 FeeAmountXSCR = IERC20(xscr).balanceOf(address(this));

        uint256 callFeeAmount = FeeAmountXSCR.div(100).mul(callFee);
        if (callFeeAmount < 0){
        IERC20(xscr).safeTransfer(msg.sender, callFeeAmount);
        }

        uint256 TeamFeeAmount = FeeAmountXSCR.div(100).mul(XSCRFee);
        if (TeamFeeAmount < 0){
        IERC20(xscr).safeTransfer(teamVault, TeamFeeAmount);
        }}
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 LP1 = IERC20(wbnb).balanceOf(address(this)).div(100).mul(lp1PercentBuy).div(2);
        uint256 LP2 = IERC20(wbnb).balanceOf(address(this)).div(100).mul(lp2PercentBuy).div(2);
        uint256 LP3 = IERC20(wbnb).balanceOf(address(this)).div(100).mul(lp3PercentBuy).div(2);
        uint256 LP4 = IERC20(wbnb).balanceOf(address(this)).div(100).mul(lp4PercentBuy).div(2);
        uint256 LP5 = IERC20(wbnb).balanceOf(address(this)).div(100).mul(lp5PercentBuy).div(2);

        // LP 1 wbnb - xscr
        // has wbnb
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP1, 0, wbnbToXSCRRoute, address(this), now);

        uint256 lp0Bal = IERC20(wbnb).balanceOf(address(this));
        uint256 lp1Bal = IERC20(xscr).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(wbnb, xscr, lp0Bal, lp1Bal, 1, 1, address(this), now);
    
    
        //LP 2 btcb - xscr
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP2, 0,  wbnbToBtcbRoute, address(this), now);
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP2, 0,  wbnbToXSCRRoute, address(this), now);

        uint256 lp2Bal = IERC20(btcb).balanceOf(address(this));
        uint256 lp3Bal = IERC20(xscr).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(btcb, xscr, lp2Bal, lp3Bal, 1, 1, address(this), now);
        

        //LP 3 busd - xscr
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP3, 0, wbnbToBusdRoute, address(this), now);
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP3, 0, wbnbToXSCRRoute, address(this), now);

        uint256 lp4Bal = IERC20(busd).balanceOf(address(this));
        uint256 lp5Bal = IERC20(xscr).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(busd, xscr, lp4Bal, lp5Bal, 1, 1, address(this), now);
        

        //LP 4 eth - xscr
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP4, 0, wbnbToEthRoute, address(this), now);
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP4, 0, wbnbToXSCRRoute, address(this), now);

        uint256 lp6Bal = IERC20(eth).balanceOf(address(this));
        uint256 lp7Bal = IERC20(xscr).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(eth, xscr, lp6Bal, lp7Bal, 1, 1, address(this), now);


        //LP 5 bifi - xscr
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP5, 0, wbnbToBifiRoute, address(this), now);
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(LP5, 0, wbnbToXSCRRoute, address(this), now);

        uint256 lp8Bal = IERC20(bifi).balanceOf(address(this));
        uint256 lp9Bal = IERC20(xscr).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(bifi, xscr, lp8Bal, lp9Bal, 1, 1, address(this), now);
    }

    function transferToVault() internal {

        uint256 LPAmount_XSCR_WBNB = IERC20(XSCR_WBNB_LP_Token).balanceOf(address(this));
        if (LPAmount_XSCR_WBNB < 0){
        IERC20(XSCR_WBNB_LP_Token).safeTransfer(vault, LPAmount_XSCR_WBNB);
        }

        uint256 LPAmount_XSCR_BTCB = IERC20(XSCR_BTCB_LP_Token).balanceOf(address(this));
        if (LPAmount_XSCR_BTCB < 0){
        IERC20(XSCR_BTCB_LP_Token).safeTransfer(vault, LPAmount_XSCR_BTCB);
        }

        uint256 LPAmount_XSCR_BUSD = IERC20(XSCR_BUSD_LP_Token).balanceOf(address(this));
        if (LPAmount_XSCR_BUSD < 0){
        IERC20(XSCR_BUSD_LP_Token).safeTransfer(vault, LPAmount_XSCR_BUSD);
        }

        uint256 LPAmount_XSCR_ETH = IERC20(XSCR_ETH_LP_Token).balanceOf(address(this));
        if (LPAmount_XSCR_ETH < 0){
        IERC20(XSCR_ETH_LP_Token).safeTransfer(vault, LPAmount_XSCR_ETH);
        }
        
        uint256 LPAmount_XSCR_BIFI = IERC20(XSCR_BIFI_LP_Token).balanceOf(address(this));
        if (LPAmount_XSCR_BIFI < 0){
        IERC20(XSCR_BIFI_LP_Token).safeTransfer(vault, LPAmount_XSCR_BIFI);
        }
    }

    // compounds earnings and charges performance fee
    function harvest() external whenNotPaused gasThrottle {
       
        chargeFees();
        addLiquidity();
        transferToVault();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

 function _giveAllowances() external {

        IERC20(wbnb).safeApprove(unirouter, 0);
        IERC20(wbnb).safeApprove(unirouter, uint256(-1));
        
        IERC20(btcb).safeApprove(unirouter, 0);
        IERC20(btcb).safeApprove(unirouter, uint256(-1));

        IERC20(busd).safeApprove(unirouter, 0);
        IERC20(busd).safeApprove(unirouter, uint256(-1));

        IERC20(eth).safeApprove(unirouter, 0);
        IERC20(eth).safeApprove(unirouter, uint256(-1));
        
        IERC20(bifi).safeApprove(unirouter, 0);
        IERC20(bifi).safeApprove(unirouter, uint256(-1));

        IERC20(xscr).safeApprove(unirouter, 0);
        IERC20(xscr).safeApprove(unirouter, uint256(-1));
    }

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay it to the vault.
     */
    function withdraw(address _token , uint256 _bal) public onlyOwner {
        IERC20(_token).transfer(vault, _bal);
        }
    }