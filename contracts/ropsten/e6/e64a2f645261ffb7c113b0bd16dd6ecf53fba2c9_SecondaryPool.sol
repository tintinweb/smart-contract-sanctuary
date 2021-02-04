pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

import 'PoolToken.sol';
import "IERC20.sol";
import "Affectable.sol";
import "ICollateralization.sol";
import "PrimaryPool.sol";

contract SecondaryPool is PoolTokenERC20, Affectable {
    
    using SafeMath for uint;
    
    bool public _eventStarted = false;
    
    address public _primaryPoolAddress;
    address public _governanceAddress;
    address public _eventContractAddress;
    address public _whiteTokenAddress;
    address public _blackTokenAddress;
    address payable public _baseCollateralizationAddress;
    address payable public _investorWalletAddress;
    address payable public _governanceWalletAddress;
    address public _thisCollateralizationAddress;
    /*
    Founders wallets
    */
    address payable public _vWalletAddress;
    address payable public _aWalletAddress;
    address payable public _dWalletAddress;
    address payable public _yWalletAddress;
    
    event GovernanceAddressChanged (address previousAddress,address governanceAddress);
    event PrimaryPoolAddressChanged (address previousAddress,address primaryPoolAddress);
    event EventContractAddressChanged (address previousAddress,address eventContractAddress);

    event AddLiquidity(address user, uint amount);
    event WithdrawLiquidity(address user, uint amount);
    event BuyBlack(address user, uint amount, uint price);
    event BuyWhite(address user, uint amount, uint price);
    event SellBlack(address user,uint amount,uint price);
    event SellWhite(address user,uint amount,uint price);
    
    IERC20 _whiteToken;
    IERC20 _blackToken;
    ICollateralization _thisCollateralization;
    PrimaryPool _primaryPool;
    
    uint public _blackLiquidity;
    uint public _whiteLiquidity;
    
    uint public _whitePrice;
    uint public _blackPrice;
    
    /*
    Actually it is not a percent but 0.01 precision of percent. 0.0001 of a whole
    */
    uint8 public _currentEventPercentChange;
    
    /*
    1 fee is 0.0001%
    */
    uint public _feePart = 30;
    
    /*
    Part of the fee percent dedicated to governance token holders
    */
    uint public _governanceFeePart = 6;
    
    /*
    Fee part to add to B&W tokens in initial pool
    */
    uint public _bwInitialFeePart = 6;
    
    /*
    Team fee part
    */
    uint public _teamFeePart = 6;
    
    /*
    Part which will be sent as governance incentives
    Only not yet distributed fees.
    */
    uint public _feeGovernanceCollected;
    
    /*
    Part which will sent to the team
    Only not yet distributed fees.
    */
    uint public _teamFeeCollected;

    /*
    Part which will be added to the Black and White tokens price
    Only not yet distributed fees.
    */
    uint public _feeBWAdditionCollected;
    
    /*
    Total team fee collected
    */
    uint public _totalTeamFeeCollected;
    
    uint public _collateralForBlack;
    uint public _collateralForWhite;
    
    uint public _blackBought;
    uint public _whiteBought;
    
    uint public _whiteBoughtThisCycle;
    uint public _blackBoughtThisCycle; 
    uint public _whiteSoldThisCycle;
    uint public _blackSoldThisCycle; 
    
    
    uint private _FEE_DIVISOR = 10000;
    uint public _MAX_TEAM_FEE = 200000000000000000;
    
    constructor(
        address thisCollateralizationAddress,
        address whiteTokenAddress, 
        address blackTokenAddress,
        address primaryPoolAddress,
        address governanceAddress,
        address eventContractAddress,
        address payable baseCollateralizationAddress,
        address payable governanceWalletAddress,
        address payable investorWalletAddress,
        address payable vWalletAddress,
        address payable aWalletAddress,
        address payable dWalletAddress,
        address payable yWalletAddress,
        uint whitePrice,
        uint blackPrice
        ) {
        
        require (whiteTokenAddress != address(0), "WHITE TOKEN ADDRESS SHOULD BE NOT NULL");
        require (blackTokenAddress != address(0), "BLACK TOKEN ADDRESS SHOULD BE NOT NULL");
        require (thisCollateralizationAddress != address(0), "COLLATERIZATION ADDRESS SHOULD BE NOT NULL");
        require (vWalletAddress != address(0), "vWalletAddress SHOULD BE NOT NULL");
        require (aWalletAddress != address(0), "aWalletAddress ADDRESS SHOULD BE NOT NULL");
        require (dWalletAddress != address(0), "dWalletAddress ADDRESS SHOULD BE NOT NULL");
        require (yWalletAddress != address(0), "yWalletAddress ADDRESS SHOULD BE NOT NULL");
        
        _vWalletAddress = vWalletAddress;
        _aWalletAddress = aWalletAddress;
        _dWalletAddress = dWalletAddress;
        _yWalletAddress = yWalletAddress;
        _whiteTokenAddress = whiteTokenAddress;
        _blackTokenAddress = blackTokenAddress;
        
        _primaryPoolAddress = primaryPoolAddress;
        _primaryPool = PrimaryPool(primaryPoolAddress);

        _thisCollateralization = ICollateralization(thisCollateralizationAddress);
        _thisCollateralizationAddress = thisCollateralizationAddress;
        
       _whiteToken = IERC20(whiteTokenAddress);
       _blackToken = IERC20(blackTokenAddress);
       
       _governanceAddress  = governanceAddress  == address(0) ? msg.sender : governanceAddress;
       _eventContractAddress = eventContractAddress == address(0) ? msg.sender : eventContractAddress;
       _baseCollateralizationAddress = baseCollateralizationAddress == address(0) ? msg.sender : baseCollateralizationAddress;
       _governanceWalletAddress = governanceWalletAddress == address(0) ? msg.sender : governanceWalletAddress;
       _investorWalletAddress = investorWalletAddress == address(0) ? msg.sender : investorWalletAddress;
       
       _whitePrice = whitePrice;
       _blackPrice = blackPrice;
    }

    modifier noEvent {
        require(_eventStarted == false, "Function cannot be called during ongoing event");
        _;
    }
    
    modifier onlyGovernance {
        require (_governanceAddress == msg.sender, "CALLER SHOULD BE GOVERNANCE");
        _;
    }
    
    modifier onlyEventContract {
        require (_eventContractAddress == msg.sender, "CALLER SHOULD BE EVENT CONTRACT");
        _;
    }
    
    struct EventEnd {
        uint currentbwPricePrimaryPool;
        uint whitePrice;
        uint blackPrice;
        uint whiteWinVolatility;
        uint blackWinVolatility;
        uint changePercent;
        uint whiteCoefficient;
        uint blackCoefficient;
        uint totalFundsInSecondaryPool;
        uint allWhiteCollateral;
        uint allBlackCollateral;
        uint spentForWhiteThisCycle;
        uint spentForBlackThisCycle;
        uint collateralForWhite;
        uint collateralForBlack;
        uint whiteBought;
        uint blackBought;
        uint receivedForWhiteThisCycle;
        uint receivedForBlackThisCycle;
    }
    
    /**
     * Receive event results. Receives result of an event in value between -1 and 1. -1 means 
     * Black won,1 means white-won. 
     */
     function submitEventResult(int8 _result) 
     override
     external 
     onlyEventContract {
         require( _result == -1 || _result == 1 || _result == 0, "Result has inappropriate value. Should be -1 or 1");
         
         _eventStarted = false;
         
         if(_result == 0) {
             return;
         }
         
         EventEnd memory eend;
         
         //Get Black + White price from primaryPool. Cells are cell numbers from SECONDARY POOL FORMULA DOC page
         eend.currentbwPricePrimaryPool = _primaryPool.getBWprice();  //cell 2 , cell 47
         
         // Cell 3
         uint currentWhitePrice = _whitePrice;
         
         // Cell 4
         uint currentBlackPrice = _blackPrice;

         //Cell 7
         uint whiteBoughtThisCycle = _whiteBoughtThisCycle;
         _whiteBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.
         
         //Cell 8
         uint blackBoughtThisCycle = _blackBoughtThisCycle;
         _blackBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.
         
         // Cell 10
         uint whiteSoldThisCycle = _whiteSoldThisCycle;
         // Cell 11
         uint blackSoldThisCycle = _blackSoldThisCycle;
         
         // Cell 13
         eend.whiteBought = _whiteBought;
         
         // Cell 14
         eend.blackBought = _blackBought;
         
         // Cell 16
         eend.receivedForWhiteThisCycle = whiteBoughtThisCycle.mul(currentWhitePrice);
         
         // Cell 17
         eend.receivedForBlackThisCycle = blackBoughtThisCycle.mul(currentBlackPrice);
         
         // Cell 19 
         eend.spentForWhiteThisCycle = whiteSoldThisCycle.mul(currentWhitePrice);
         
         // Cell 20
         eend.spentForBlackThisCycle = blackSoldThisCycle.mul(currentBlackPrice);
         
         // Cell 22
         eend.allWhiteCollateral = _collateralForWhite.add(eend.receivedForWhiteThisCycle).sub(eend.spentForWhiteThisCycle);

         // Cell 23
         eend.allBlackCollateral = _collateralForBlack.add(eend.receivedForBlackThisCycle).sub(eend.spentForBlackThisCycle);

         // Cell 24 
         eend.totalFundsInSecondaryPool = eend.allWhiteCollateral.add(eend.allBlackCollateral);

         // Cell 26 
         eend.whiteCoefficient =  eend.allBlackCollateral.div(eend.allWhiteCollateral);
         
         // Cell 27  
         eend.blackCoefficient = eend.allWhiteCollateral.div(eend.allBlackCollateral);

         // Cell 29
        eend.changePercent = _currentEventPercentChange;
        
        // Cell 30 
        eend.whiteWinVolatility = eend.changePercent.mul(eend.whiteCoefficient);
        
        // Cell 31
        eend.blackWinVolatility = eend.changePercent.mul(eend.blackCoefficient);

        /*
         * We need additionally div for 10000 because in previous calculation steps 
         we did not calculated it as a 0.01 part of a percent
         */
        if(_result == 1) {
            // Cell 33, 43
            eend.collateralForWhite = eend.allWhiteCollateral.add(eend.allWhiteCollateral.mul(eend.whiteWinVolatility).div(10000));
            
            // Cell 36, 44
            eend.collateralForBlack = eend.allBlackCollateral.sub(eend.allBlackCollateral.mul(eend.changePercent).div(10000));
            
            // Like Cell 47
            eend.whitePrice = eend.collateralForWhite.div(eend.whiteBought);
            
            // Like Cell 48 
            eend.blackPrice = eend.collateralForBlack.div(eend.blackBought);
            
            // Cell 48
            uint secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);
            
            // Cell 55, 57, 58
            uint bwPriceDiff = 0;
            if(secondaryPoolBWPrice > eend.currentbwPricePrimaryPool) {
                bwPriceDiff = eend.currentbwPricePrimaryPool.sub(secondaryPoolBWPrice);
                eend.whitePrice = eend.whitePrice.sub(bwPriceDiff);
            } else {
                bwPriceDiff = secondaryPoolBWPrice.sub(eend.currentbwPricePrimaryPool);
                eend.whitePrice = eend.whitePrice.add(bwPriceDiff);
            }
        }
        
        if(_result == -1) {
            // Cell 34, 43
            eend.collateralForWhite = eend.allWhiteCollateral.sub(eend.allWhiteCollateral.mul(eend.changePercent).div(10000));
                        
            // Cell 35, 44
            eend.collateralForBlack = eend.allBlackCollateral.add(eend.allBlackCollateral.mul(eend.blackWinVolatility).div(10000));
            
            // Like Cell 47
            eend.whitePrice = eend.collateralForWhite.div(eend.whiteBought);
            
            // Like Cell 48 
            eend.blackPrice = eend.collateralForBlack.div(eend.blackBought);
            
            _collateralForWhite = eend.collateralForWhite;
            _collateralForBlack = eend.collateralForBlack;
            
            // Cell 48
            uint secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);
            
            // Cell 55, 57, 58
            uint bwPriceDiff = 0;
            if(secondaryPoolBWPrice > eend.currentbwPricePrimaryPool) {
                bwPriceDiff = eend.currentbwPricePrimaryPool.sub(secondaryPoolBWPrice);
                eend.blackPrice = eend.blackPrice.sub(bwPriceDiff);
            } else {
                bwPriceDiff = secondaryPoolBWPrice.sub(eend.currentbwPricePrimaryPool);
                eend.blackPrice = eend.blackPrice.add(bwPriceDiff);
            }
        }
        
        _whitePrice = eend.whitePrice;
        _blackPrice = eend.blackPrice;
        
        _collateralForWhite = eend.collateralForWhite;
        _collateralForBlack = eend.collateralForBlack;
     }
    
    
    /**
     * @param currentEventPriceChangePercent - 0 if has no value;
    Actually it is not a percent but 0.01 precision of percent. 0.0001 of a whole
     * */
    function submitEventStarted(uint8 currentEventPriceChangePercent) 
    override
    external
    onlyEventContract {
        require(currentEventPriceChangePercent <= 4000, "Too high event price change percent submitted");
        require(currentEventPriceChangePercent >= 100, "Too lower event price change percent submitted");
        
        _currentEventPercentChange = currentEventPriceChangePercent;

        _eventStarted = true;
    }
    
    function sellBlack(uint tokensAmount, uint minPrice) 
    public
    noEvent {
        (uint collateralAmountWithFee, uint ethToSend) = genericSell(_blackToken, _blackPrice, minPrice, tokensAmount, false);
        _blackBought = _blackBought.sub(tokensAmount);
        _collateralForBlack = _collateralForBlack.sub(collateralAmountWithFee);
        _blackSoldThisCycle = _blackSoldThisCycle.add(tokensAmount);
        emit SellBlack(msg.sender, ethToSend, _blackPrice);
    }
    
     function sellWhite(uint tokensAmount, uint minPrice) 
        public 
        noEvent {
        (uint collateralAmountWithFee, uint ethToSend) = genericSell(_whiteToken, _whitePrice, minPrice, tokensAmount, true);
        _whiteBought = _whiteBought.sub(tokensAmount);
        _collateralForWhite = _collateralForWhite.sub(collateralAmountWithFee);
        _whiteSoldThisCycle = _whiteSoldThisCycle.add(tokensAmount);
        emit SellWhite(msg.sender, ethToSend, _whitePrice);
    }
    
    function genericSell(
        IERC20 token, 
        uint price, 
        uint minPrice, 
        uint tokensAmount,
        bool isWhite)
    private 
    returns (uint, uint){
        require (token.allowance(msg.sender, _thisCollateralizationAddress) >= tokensAmount, "NOT ENOUGH DELEGATED WHITE TOKENS ON USER BALANCE");
        require(price >= minPrice, "Actual price is lower than acceptable by the user");

        uint ethAmountWithFee = tokensAmount.mul(price);
        uint feeAmount = ethAmountWithFee.mul(_feePart).div(_FEE_DIVISOR);
        uint ethAmountToSend = ethAmountWithFee.sub(feeAmount);
        
        updateFees(feeAmount);

        require(_thisCollateralizationAddress.balance > ethAmountToSend, "Not enought Ethereum liquidity in the pool");
        
        _thisCollateralization.buyBackSeparately(
        msg.sender, 
        tokensAmount, 
        isWhite, 
        ethAmountToSend);
        
        return (ethAmountWithFee, ethAmountToSend);
    }
    
    function buyBlack(uint maxPrice) 
    public 
    payable
    noEvent {
       (uint tokenAmount, uint collateralToBuy) = genericBuy(maxPrice, _blackPrice, _blackToken, msg.value, false);
       _collateralForBlack = _collateralForBlack.add(collateralToBuy);
       _blackBought = _blackBought.add(tokenAmount);
       _blackBoughtThisCycle = _blackBoughtThisCycle.add(tokenAmount);
       emit BuyBlack(msg.sender, tokenAmount, _blackPrice);
    }
    
    function buyWhite(uint maxPrice) 
    public 
    payable
    noEvent {
       (uint tokenAmount, uint collateralToBuy) = genericBuy(maxPrice, _whitePrice, _whiteToken, msg.value, true); 
       _collateralForWhite = _collateralForWhite.add(collateralToBuy);
       _whiteBought = _whiteBought.add(tokenAmount);
       _whiteBoughtThisCycle = _whiteBoughtThisCycle.add(tokenAmount);
       emit BuyWhite(msg.sender, tokenAmount, _whitePrice);
    }
    
    function genericBuy(uint maxPrice,uint price, IERC20 token, uint ethValue, bool isWhite) 
    private 
    returns (uint, uint){
        require(price <= maxPrice, "Actual price is higher than acceptable by the user");
        uint receivedEth = ethValue;
        uint feeAmount = receivedEth.mul(_feePart).div(_FEE_DIVISOR);

        updateFees(feeAmount);
        
        uint ethToBuy = receivedEth.sub(feeAmount);
        uint tokenAmount = ethToBuy.div(price);
        require(token.balanceOf(_thisCollateralizationAddress) > tokenAmount, "Not enought liquidity in the pool");
        
        _thisCollateralization.buySeparately{value: msg.value}(
        msg.sender, 
        tokenAmount, 
        isWhite);
        return (tokenAmount, ethToBuy);
    }
    
    function updateFees(uint feeAmount) internal {
        if(_MAX_TEAM_FEE > _totalTeamFeeCollected) {
            uint addition = feeAmount.div(_feePart.div(_teamFeePart));
            _teamFeeCollected = _teamFeeCollected.add(addition);
        } 
        _feeGovernanceCollected = _feeGovernanceCollected.add(feeAmount.div(_feePart.div(_governanceFeePart)));
        /*
         * We need to add next two lines because after some time governance fee part will not have pure interger
         * result being a divisor for _feePart. When feePart is 30 and _governanceFeePart = 9 there will be mod 266
         * which we should not loose.
         * Other numbers always have clean integer division result in that operation. So we not performing mod calculations for them.
         */ 
        uint govFeeMod = _feePart.mod(_governanceFeePart); 
        _feeGovernanceCollected = _feeGovernanceCollected.add(feeAmount.div(_feePart.div(govFeeMod)));
        _feeBWAdditionCollected = _feeBWAdditionCollected.add(feeAmount.div(_feePart.div(_bwInitialFeePart)));
    }
    
    function addLiquidity(uint tokensAmount) 
    public {
        require (_whiteToken.allowance(msg.sender, address(this)) >= tokensAmount, "NOT ENOUGH DELEGATED WHITE TOKENS ON USER BALANCE");
        require (_blackToken.allowance(msg.sender, address(this)) >= tokensAmount, "NOT ENOUGH DELEGATED BLACK TOKENS ON USER BALANCE");
        
        _whiteToken.transferFrom(msg.sender, _thisCollateralizationAddress, tokensAmount);
        _blackToken.transferFrom(msg.sender, _thisCollateralizationAddress, tokensAmount);
        
        _blackLiquidity = _blackLiquidity.add(tokensAmount);
        _whiteLiquidity = _whiteLiquidity.add(tokensAmount);
        
        uint poolTokensToSend = tokensAmount.div(poolTokenPriceInBW());
        
        _mint(msg.sender, poolTokensToSend);
        emit AddLiquidity(msg.sender, tokensAmount);
    }
    
   function withdrawLiquidity(uint poolTokensAmount) public {
        require (allowance[msg.sender][address(this)] >= poolTokensAmount, "NOT ENOUGH DELEGATED POOL TOKENS ON USER BALANCE");

        uint tokensToSend = poolTokensAmount.mul(poolTokenPriceInBW());
        
        uint thisBlackBalance = _blackToken.balanceOf(_thisCollateralizationAddress);
        uint ethToReturn = 0;
        uint notEnoughBlack = 0;
        uint notEnoughWhite = 0;
        
        if(thisBlackBalance < tokensToSend) {
            notEnoughBlack = tokensToSend.sub(thisBlackBalance);
            ethToReturn = ethToReturn.add(notEnoughBlack.mul(_blackPrice));
        }
        
        uint thisWhiteBalance = _whiteToken.balanceOf(_thisCollateralizationAddress);
        if(thisWhiteBalance < tokensToSend) {
            notEnoughWhite = tokensToSend.sub(thisWhiteBalance);
            ethToReturn = ethToReturn.add(notEnoughWhite.mul(_whitePrice));
        }
        
        if(ethToReturn > 0) {
            // Case when not enough black and white tokens to send
            msg.sender.transfer(ethToReturn);
            _thisCollateralization.buyBackSeparately(
                msg.sender, 
                0, 
                false, 
                ethToReturn);
        
            tokensToSend = tokensToSend.sub(notEnoughWhite);
            tokensToSend = tokensToSend.sub(notEnoughBlack);
        } 
        
        _thisCollateralization.buy(
        msg.sender, 
        tokensToSend);
        
        _blackLiquidity = _blackLiquidity.sub(tokensToSend);
        _whiteLiquidity = _whiteLiquidity.sub(tokensToSend);
        
        _burn(msg.sender, poolTokensAmount);
        emit WithdrawLiquidity(msg.sender, tokensToSend);
    }
    /*
        B from ethForBlack +
        W from ethForWhite +
        Black & white tokens 
    */
    function poolTokenPriceInBW() 
    view
    public
    returns (uint) {
        uint totalEthForBW = _collateralForBlack.add(_collateralForWhite);
        uint contractEth = _thisCollateralizationAddress.balance;
        uint contractEthWithoutNotMmFee = contractEth.sub(_feeGovernanceCollected).sub(_teamFeeCollected).sub(_feeBWAdditionCollected);
        uint ethAddition = contractEthWithoutNotMmFee.sub(totalEthForBW);
        uint ethAdditionPart = totalEthForBW.div(ethAddition);
        uint bwPrice = _whitePrice.add(_blackPrice);
        uint poolTokenPriceEth = bwPrice.add(bwPrice.mul(ethAdditionPart));
        uint poolTokenPriceBW = poolTokenPriceEth.div(bwPrice);
        return poolTokenPriceBW;
    }
    
    function changeGovernanceAddress (address governanceAddress) 
    public 
    onlyGovernance {
    require (governanceAddress != address(0), "NEW GOVERNANCE ADDRESS SHOULD BE NOT NULL");
        _governanceAddress = governanceAddress;
    }
    
    function changePrimaryPoolAddress (address primaryPoolAddress) 
    public 
    onlyGovernance {
        require (primaryPoolAddress != address(0), "NEW POOL ADDRESS SHOULD BE NOT NULL");
        
        _primaryPoolAddress = primaryPoolAddress;
        _primaryPool = PrimaryPool(primaryPoolAddress);

    }
    
    function changeEventContractAddress (address evevntContractAddress) 
    public 
    onlyGovernance {
        require (evevntContractAddress != address(0), "NEW EVENT CONTRACT ADDRESS SHOULD BE NOT NULL");
        
        _eventContractAddress = evevntContractAddress;

    }
    
    function changeCollateralizationContractAddress(address payable newAddress) 
    public 
    onlyGovernance {
        require (newAddress != address(0), "NEW CONTRACT ADDRESS SHOULD BE NOT NULL");
        
        _baseCollateralizationAddress = newAddress;
    }
    
    function changeGovernanceWalletAddress(address payable newAddress) 
    public 
    onlyGovernance {
        require (newAddress != address(0), "NEW CONTRACT ADDRESS SHOULD BE NOT NULL");

        _governanceWalletAddress = newAddress;
    }
    
    function distributeProjectIncentives() public {
    
    _governanceWalletAddress.transfer(_feeGovernanceCollected);
    _feeGovernanceCollected = 0;
    _baseCollateralizationAddress.transfer(_feeBWAdditionCollected);
    _feeBWAdditionCollected = 0;
    
    if(_MAX_TEAM_FEE > _totalTeamFeeCollected) {
        uint teamFee = _teamFeeCollected.mul(70).div(100);
        uint yFee = teamFee.div(5);
        _yWalletAddress.transfer(yFee);
        uint pFee = teamFee.mul(266).div(1000);
        _vWalletAddress.transfer(pFee);
        _aWalletAddress.transfer(pFee);
        _dWalletAddress.transfer(pFee);
        uint bwPrice = _blackPrice.add(_whitePrice);
        uint teamDistributed = yFee.add(pFee.mul(3));
    
        uint investorIncentives = _teamFeeCollected.mul(30).div(100);
        _investorWalletAddress.transfer(investorIncentives);
    
        uint distributed = teamDistributed.add(investorIncentives);
        _teamFeeCollected = _teamFeeCollected.sub(distributed);
   
        /*
        Next variable calculate collected in B&W tokens
        */
        _totalTeamFeeCollected.add(distributed.div(bwPrice));
        
        if(_MAX_TEAM_FEE < _MAX_TEAM_FEE.add(_totalTeamFeeCollected)) {
            _governanceFeePart = 9;
        }
    }

    }
}