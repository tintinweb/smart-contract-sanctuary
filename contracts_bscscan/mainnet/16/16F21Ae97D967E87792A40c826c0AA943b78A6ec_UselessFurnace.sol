pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

/**
 * Created Sept 2 2021
 * Developed by Markymark (MoonMark)
 * USELESS Furnace Contract to stablize the Useless Liquidity Pool
 */
 
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";

/**
 * 
 * BNB Sent to this contract will be used to automatically manage the Useless Liquidity Pool
 * Ideally keeping Liquidity Pool Size between 7% - 12.5% of the circulating supply of Useless
 * Liquidity over 20% - LP Extraction
 * Liquidity over 12.5% - Buy/Burn Useless
 * Liquidity between 6.67 - 12.5%  - reverse SAL
 * Liquidity under 6.67% - inject LP from sidetokenomics or trigger SAL from previous LP Extractions
 *
 */
contract UselessFurnace {
    
  using Address for address;
  using SafeMath for uint256;
  
  // useless total supply
  uint256 constant private totalSupply = 1000000000 * 10**6 * 10**9;
  uint256 constant private maxPercent = 100;
    // burn wallet address
  address constant private _burnWallet = 0x000000000000000000000000000000000000dEaD;
  // address of USELESS Smart Contract
  address private _uselessAddr = 0x2cd2664Ce5639e46c6a3125257361e01d0213657;

  // address of wrapped bnb 
  address private _bnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  // useless liquidity pool address
  address private _uselessLP = 0x08A6cD8a2E49E3411d13f9364647E1f2ee2C6380;
  // Initialize Pancakeswap Router
  IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
  
  // 100,000,000 useless
  uint256 public pairLiquidityUSELESSThreshold = 10**17;
  // 0.01 bnb
  uint256 public pairLiquidityBNBThreshold = 10**16;
  
  // liquidity operations
  bool public canPairLiquidity = true;
  bool public canPullLiquidity = true;
  
  /** Expressed as 100 / x */
  uint256 public pullLiquidityRange = 5;
  /** Expressed as 100 / x */
  uint256 public buyAndBurnRange = 8;
  /** Expressed as 100 / x */
  uint256 public reverseSALRange = 15;
  // how much bnb to trigger automate
  uint256 public automateThreshold = 15 * 10**15;
  
  bool automating;
  modifier isAutomating {require(!automating, 'Mid Automation!'); _;}
  
  address _owner;
  modifier onlyOwner {require(msg.sender == _owner, 'Only Owner Function'); _;}
  
  constructor() {
      _owner = msg.sender;
  }

  function BURN_IT_DOWN_BABY() external isAutomating {
        if (address(this).balance >= automateThreshold) {
            automate();
        }
  } 
  
  /**
   * Automates the Buy/Burn, SAL, or reverseSAL operations based on the state of the LP
   */ 
  function triggerAutomation() external onlyOwner isAutomating {
    automate();
  }

  /**
   * Automates the Buy/Burn, SAL, or reverseSAL operations based on the state of the LP
   */ 
  function triggerReverseSAL() external onlyOwner {
    reverseSwapAndLiquify();
  }

  /**
   * Automates the Buy/Burn, SAL, or reverseSAL operations based on the state of the LP
   */ 
  function triggerPullLiquidity(uint256 percent) external onlyOwner {
    pullLiquidity(percent);
  }

  /**
   * Automates the Buy/Burn, SAL, or reverseSAL operations based on the state of the LP
   */ 
  function triggerBuyAndBurn(uint256 percent) external onlyOwner {
    buyAndBurn(percent);
  }
   
   /**
    * Tries and forces a liquidity pairing. Transaction will fail if thresholds are not met
    */
   function manuallyPairLiquidity() external onlyOwner {
    uint256 uAMT = IERC20(_uselessAddr).balanceOf(address(this));
    pairLiquidity(uAMT, address(this).balance);
   }

  function automate() private {
    // check useless standing
    checkUselessStanding();
    // determine the health of the lp
    uint256 dif = determineLPHealth();
    // check cases
    dif = clamp(dif, 1, 100);
    
    if (dif <= pullLiquidityRange && canPullLiquidity) {
        // pull liquidity
        pullLiquidity(maxPercent.div(dif));
    } else if (dif <= buyAndBurnRange) {
        // if LP is over 12.5% of Supply we buy burn useless
        buyAndBurn(maxPercent.div(dif));
    } else if (dif <= reverseSALRange) {
        // if LP is between 6.666%-12.5% of Supply we call reverseSAL
        reverseSwapAndLiquify();
    } else {
        // if LP is under 6.666% of Supply we provide a pairing if one exists, else we call reverseSAL
        (bool success, uint256 uAMT) = pairLiquidityThresholdReached();
        if (success && canPairLiquidity) {
            pairLiquidity(uAMT, address(this).balance);
        } else {
            reverseSwapAndLiquify();
        }
    }
  }

  function checkUselessStanding() private {
      uint256 uselessSupply = totalSupply.sub(IERC20(_uselessAddr).balanceOf(_burnWallet));
      uint256 threshold = uselessSupply.div(100);
      uint256 uselessBalance = IERC20(_uselessAddr).balanceOf(address(this));
      if (uselessBalance > threshold) {
          // burn 1/3 of balance
          try IERC20(_uselessAddr).transfer(_burnWallet, uselessBalance.div(3)) {} catch {}
      }
  }

  /**
   * Buys USELESS Tokens and sends them to the burn wallet
   * @param percentOfBNB - Percentage of BNB Inside the contract to buy/burn with
   */ 
  function buyAndBurn(uint256 percentOfBNB) private {
      
    percentOfBNB = clamp(percentOfBNB, 1, 100);
    // amount of bnb
    uint256 buyBurnBalance = address(this).balance.mul(percentOfBNB).div(10**2);
    // buy and burn it
    buyAndBurnUseless(buyBurnBalance);
    // tell blockchain
    emit BuyAndBurn(buyBurnBalance);
  }
  
   /**
   * Uses BNB in Contract to Purchase Useless, pairs with remaining BNB and adds to Liquidity Pool
   * Similar to swapAndLiquify
   */
   function reverseSwapAndLiquify() private {
      
    // BNB Balance before the swap
    uint256 initialBalance = address(this).balance;
    
    // USELESS Balance before the Swap
    uint256 contractBalance = IERC20(_uselessAddr).balanceOf(address(this));
    
    // Swap 50% of the BNB in Contract for USELESS Tokens
    justBuyBack(50);

    // how much bnb was spent on the swap
    uint256 bnbInSwap = initialBalance.sub(address(this).balance);
    
    // how many USELESS Tokens were received
    uint256 diff = IERC20(_uselessAddr).balanceOf(address(this)).sub(contractBalance);

    if (bnbInSwap > address(this).balance) {
        bnbInSwap = address(this).balance;
    }
    
    // add liquidity to Pancakeswap
    bool success = addLiquidity(diff, bnbInSwap);
        
    if (success) emit ReverseSwapAndLiquify(diff, bnbInSwap);
    else emit FailedReverseSwapAndLiquify(diff, bnbInSwap);
   }
   
   /**
    * Pairs BNB and USELESS in the contract and adds to liquidity if we are above thresholds 
    */
   function pairLiquidity(uint256 uselessInContract, uint256 bnbInContract) private {
        // make sure we have enough bnb in the contracmemory
        require(bnbInContract <= address(this).balance, 'Cannot swap more than contracts supply');
        // get amount of useless in the pool 
        uint256 uselessLP = IERC20(_uselessAddr).balanceOf(_uselessLP);
        // amount of bnb in the pool
        uint256 bnbLP = IERC20(_bnb).balanceOf(_uselessLP);
        // make sure we have tokens in LP
        require(bnbLP > 0 && uselessLP > 0, 'cannot have zero LP!!');
        // how much BNB do we need to pair with our useless
        uint256 bnbbal = getTokenInToken(_uselessAddr, _bnb, uselessInContract);
        //if there isn't enough bnb in contract
        if (address(this).balance < bnbbal) {
            // recalculate with bnb we have
            uint256 nUseless = uselessInContract.mul(address(this).balance).div(bnbbal);
            addLiquidity(nUseless, address(this).balance);
            emit LiquidityPairAdded(nUseless, address(this).balance);
        } else {
            // pair liquidity as is 
            addLiquidity(uselessInContract, bnbbal);
            emit LiquidityPairAdded(uselessInContract, bnbbal);
        }
   }
   
  /**
   * Returns the health of the LP, more specifically circulatingSupply / sizeof(lp)
   */ 
  function checkLPHealth() public view returns(uint256) {
      return determineLPHealth();
  }

   
   /**
    * Returns true if both useless and bnb quantities have reached their thresholds
    */
   function pairLiquidityThresholdReached() private view returns(bool, uint256) {
       
       // amount of useless in our contract
       uint256 uselessInContract = IERC20(_uselessAddr).balanceOf(address(this));
 
       return(uselessInContract >= pairLiquidityUSELESSThreshold && address(this).balance >= pairLiquidityBNBThreshold, uselessInContract);
       
   }
   /** Returns the price of tokenOne in tokenTwo according to Pancakeswap */
   function getTokenInToken(address tokenOne, address tokenTwo, uint256 amtTokenOne) internal view returns (uint256){
        address[] memory path = new address[](2);
        path[0] = tokenOne;
        path[1] = tokenTwo;
        
        return uniswapV2Router.getAmountsOut(amtTokenOne, path)[1];
   } 

  /**
   * Internal Function which calls UniswapRouter function 
   */ 
  function buyAndBurnUseless(uint256 bnbAmount) private {
    
    // Uniswap pair path for BNB -> USELESS
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = _uselessAddr;
    
    // Swap BNB for USELESS
    uniswapV2Router.swapExactETHForTokens{value: bnbAmount}(
        0, 
        path,
        _burnWallet, // Burn Address
        block.timestamp.add(300)
    );

  }
  
  /** Clamps a variable between a min and a max */
  function clamp(uint256 variable, uint256 min, uint256 max) private pure returns (uint256){
      if (variable < min) {
          return min;
      } else if (variable > max) {
          return max;
      } else {
          return variable;
      }
  }
  
   /**
   * Buys USELESS with BNB Stored in the contract, and stores the USELESS in the contract
   * @param ratioOfBNB - Percentage of contract's BNB to Buy
   */ 
  function justBuyBack(uint256 ratioOfBNB) private {
      
    ratioOfBNB = clamp(ratioOfBNB, 1, 100);
    // calculate the amount being transfered 
    uint256 transferAMT = address(this).balance.mul(ratioOfBNB).div(10**2);
    
    // Uniswap pair path for BNB -> USELESS
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = _uselessAddr;
    
    // Swap BNB for USELESS
    uniswapV2Router.swapExactETHForTokens{value: transferAMT}(
        0, // accept any amount of USELESS
        path,
        address(this), // Store in Contract
        block.timestamp.add(30)
    );  
      
    emit BuyBack(transferAMT);
  }
  
  /**
   * Swaps USELESS for BNB using the USELESS/BNB Pool
   */ 
  function swapTokensForBNB(uint256 tokenAmount) private {
    // generate the uniswap pair path for token -> weth
    address[] memory path = new address[](2);
    path[0] = _uselessAddr;
    path[1] = uniswapV2Router.WETH();

    IERC20(_uselessAddr).approve(address(uniswapV2Router), tokenAmount);

    // swap useless for bnb
    uniswapV2Router.swapExactTokensForETH(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
    );
    }
    /**
     * Determines the Health of the LP
     * returns the percentage of the Circulating Supply that is in the LP
     */ 
    function determineLPHealth() private view returns(uint256) {
        
        // Find the balance of USELESS in the liquidity pool
        uint256 lpBalance = IERC20(_uselessAddr).balanceOf(_uselessLP);
        // Circulating supply is total supply - burned supply
        uint256 circSupply = totalSupply.sub(IERC20(_uselessAddr).balanceOf(_burnWallet));
         
        if (lpBalance < 1) {
            return 6;
        } else {
            return circSupply.div(lpBalance);
        }
    }
    
  /**
   * Adds USELESS and BNB to the USELESS/BNB Liquidity Pool
   */ 
  function addLiquidity(uint256 uselessAmount, uint256 bnbAmount) private returns (bool){
       
    IERC20(_uselessAddr).approve(address(uniswapV2Router), uselessAmount);

      // add the liquidity
      try uniswapV2Router.addLiquidityETH{value: bnbAmount}(
        _uselessAddr,
        uselessAmount,
        0,
        0,
        address(this),
        block.timestamp.add(30)
      ) {} catch{return false;}
    
      return true;
    
    }

    /**
     * Removes Liquidity from the pool and stores the BNB and USELESS in the contract
     */
   function pullLiquidity(uint256 percentLiquidity) private returns (bool){
       // Percent of our LP Tokens
       uint256 pLiquidity = IERC20(_uselessLP).balanceOf(address(this)).mul(percentLiquidity).div(10**2);
       // Approve Router 
       IERC20(_uselessLP).approve(address(uniswapV2Router), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
       // remove the liquidity
       try uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            _uselessAddr,
            pLiquidity,
            0,
            0,
            address(this),
            block.timestamp.add(30)
        ) {} catch {return false;}
        
        return true;
   }
   
   function approveMax() private {
       uint256 max = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
       // Approve Router LP
       IERC20(_uselessLP).approve(address(uniswapV2Router), max);
       // Approve Router Tokens
       IERC20(_uselessAddr).approve(address(uniswapV2Router), max);
   }
  
  /**
   * Amount of BNB in this contract
   */ 
  function getContractLPBalance() public view returns (uint256) {
    return IERC20(_uselessLP).balanceOf(address(this));
  }
  
  function getPercentageOfLPTokensOwned() public view returns (uint256) {
      return uint256(10**18).mul(IERC20(_uselessLP).balanceOf(address(this))).div(IERC20(_uselessLP).totalSupply());
  }
  
  /**
   * 
   * Updates the Uniswap Router and Uniswap pairing for ETH In Case of migration
   */
  function setUniswapV2Router(address _uniswapV2Router) external onlyOwner {
    uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    approveMax();
    emit UpdatedPancakeswapRouter(_uniswapV2Router);
  }
  
  /**
   * Updates the Uniswap Router and Uniswap pairing for ETH In Case of migration
   */
  function setUselessLPAddress(address nUselessLP) external onlyOwner {
    _uselessLP = nUselessLP;
    approveMax();
    emit UpdatedUselessLPAddress(nUselessLP);
  }

  /**
   * Updates the Contract Address for USELESS
   */
  function setUSELESSContractAddress(address payable newUselessAddress) external onlyOwner {
    _uselessAddr = newUselessAddress;
    approveMax();
    emit UpdatedUselessContractAddress(newUselessAddress);
  }
  
  function setCanPairPullLiquidity(bool canPair, bool canPull) external onlyOwner {
      canPairLiquidity = canPair;
      canPullLiquidity = canPull;
      emit UpdatedLiquidityAlteringBools(canPair, canPull);
  }
  
  function setPairLiquidityThresholds(uint256 uselessTH, uint256 bnbTH) external onlyOwner {
      pairLiquidityUSELESSThreshold = uselessTH;
      pairLiquidityBNBThreshold = bnbTH;
      emit UpdatedPairLiquidityThresholds(uselessTH, bnbTH);
  }

  function setRanges(uint256 _buyAndBurnRange, uint256 _pullLiquidityRange, uint256 _reverseSALRange) external onlyOwner {
      buyAndBurnRange = _buyAndBurnRange;
      pullLiquidityRange = _pullLiquidityRange;
      reverseSALRange = _reverseSALRange;
      emit UpdatedLPRanges(_buyAndBurnRange, _pullLiquidityRange, _reverseSALRange);
  }

  /**
   * Updates the BNB Threshold Needed For Automation
   */
  function setAutomateThresholdAddress(uint256 newTH) external onlyOwner {
        automateThreshold = newTH;
        emit UpdatedAutomationThreshold(newTH);
  }

  /**
   * Updates the Address for WBNB
   */
  function setWBNBAddress(address nwBNB) external onlyOwner {
        _bnb = nwBNB;
        emit UpdatedWBNBAddress(nwBNB);
  }
  
  function getWrappedBNBInLP() public view returns (uint256) {
      return IERC20(_bnb).balanceOf(_uselessLP);
  }
  
  function killContract() external onlyOwner {
      uint256 bal = IERC20(_uselessAddr).balanceOf(address(this));
      if (bal > 0) {
          IERC20(_uselessAddr).transfer(msg.sender, bal);
      }
      emit ContractDestroyed();
      selfdestruct(payable(msg.sender));
  }
  
  function transferOwnership(address newOwner) external onlyOwner {
      _owner = newOwner;
      emit TransferOwnership(newOwner);
  }
  
  // EVENTS 
  
  event BuyAndBurn(uint256 amountBNBUsed);
  event BuyBack(uint256 amountBought);
  event ReverseSwapAndLiquify(uint256 uselessAmount,uint256 bnbAmount);
  event LiquidityPairAdded(uint256 uselessAmount,uint256 bnbAmount);
  event FailedReverseSwapAndLiquify(uint256 uselessAmount, uint256 bnbAmount);
  event ContractDestroyed();
  event UpdatedWBNBAddress(address newWBNB);
  event UpdatedAutomationThreshold(uint256 newThreshold);
  event UpdatedLPRanges(uint256 buyBurnRange, uint256 pullLiquidityRange, uint256 reverseSALRange);
  event UpdatedPairLiquidityThresholds(uint256 uselessThreshold, uint256 bnbThreshold);
  event UpdatedLiquidityAlteringBools(bool canPair, bool calPull);
  event UpdatedUselessContractAddress(address newAddress);
  event UpdatedUselessLPAddress(address newLP);
  event UpdatedPancakeswapRouter(address newRouter);
  event TransferOwnership(address newOwner);

    // Receive BNB
    receive() external payable { }
    
}