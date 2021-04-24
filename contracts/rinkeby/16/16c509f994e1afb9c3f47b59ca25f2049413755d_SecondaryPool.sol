pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

import "./PoolToken.sol";
import "./IERC20.sol";
import "./Affectable.sol";
import "./ISecondaryCollateralizationBWT.sol";
import "./PrimaryPoolBWT.sol";
import "./DSMath.sol";

contract SecondaryPool is PoolTokenERC20, Affectable, DSMath {
    using SafeMath for uint256;

    bool public _eventStarted = false;

    address public _governanceAddress;
    address public _eventContractAddress;
    address public _baseCollateralizationAddress;
    address public _investorWalletAddress;
    address public _governanceWalletAddress;
    /*
    Founders wallets
    */
    address public _vWalletAddress;
    address public _aWalletAddress;
    address public _dWalletAddress;
    address public _yWalletAddress;

    event GovernanceAddressChanged(
        address previousAddress,
        address governanceAddress
    );
    event PrimaryPoolAddressChanged(
        address previousAddress,
        address primaryPoolAddress
    );
    event EventContractAddressChanged(
        address previousAddress,
        address eventContractAddress
    );
    
    event WithdrawLiquidity(uint256 poolTokens, uint256 bwAmount);
    event AddLiquidity(address user, uint256 amount);
    event BuyBlack(address user, uint256 amount, uint256 price);
    event BuyWhite(address user, uint256 amount, uint256 price);
    event SellBlack(address user, uint256 amount, uint256 price);
    event SellWhite(address user, uint256 amount, uint256 price);
    

    IERC20 public _whiteToken;
    IERC20 public _blackToken;
    IERC20 public _bwToken;
    IERC20 public _collateralToken;
    ICollateralization public _thisCollateralization;
    PrimaryPool public _primaryPool;

    uint256 public _blackLiquidity;
    uint256 public _whiteLiquidity;

    uint256 public _whitePrice; // in 1e18
    uint256 public _blackPrice; // in 1e18

    uint256 BW_DECIMALS = 18;

    // in percents (1e18 == 100%)
    uint256 public _currentEventPercentChange;


    // 0.3% (1e18 == 100%)
    uint256 public constant FEE = 0.003 * 1e18;

    // governance token holders fee: initial – 20% of total FEE
    uint256 public _governanceFee = 0.2 * 1e18;

    // team fee: initial – 20% of total FEE
    uint256 public _teamFee = 0.2 * 1e18;

    // initial pool fee: 20% of total FEE
    uint256 public _bwInitialFee = 0.2 * 1e18;

    // liquidity provider fee: initial 40% of total FEE


    /*
    Part which will be sent as governance incentives
    Only not yet distributed fees.
    */
    uint256 public _feeGovernanceCollected;

    /*
    Part which will sent to the team
    Only not yet distributed fees.
    */
    uint256 public _teamFeeCollected;

    /*
    Part which will be added to the Black and White tokens price
    Only not yet distributed fees.
    */
    uint256 public _feeBWAdditionCollected;

    /*
    Total team fee collected
    */
    uint256 public _totalTeamFeeCollected;

    uint256 public _collateralForBlack;
    uint256 public _collateralForWhite;

    uint256 public _blackBought;
    uint256 public _whiteBought;

    uint256 public _whiteBoughtThisCycle;
    uint256 public _blackBoughtThisCycle;
    uint256 public _whiteSoldThisCycle;
    uint256 public _blackSoldThisCycle;

    uint256 public constant MAX_TEAM_FEE = 2 * 1e7 * 1e18; // 20,000,000
    
    uint public constant MIN_HOLD = 2 * 1e18; //Minimum amount of tokens pool should hold after initial actions.

    constructor(
        address thisCollateralizationAddress,
        address collateralTokenAddress,
        address whiteTokenAddress,
        address blackTokenAddress,
        address bwtAddress,
        address primaryPoolAddress,
        address eventContractAddress,
        address payable baseCollateralizationAddress,
        address payable governanceWalletAddress,
        address payable investorWalletAddress,
        address payable vWalletAddress,
        address payable aWalletAddress,
        address payable dWalletAddress,
        address payable yWalletAddress,
        uint256 whitePrice,
        uint256 blackPrice
    ) {
        require(
            whiteTokenAddress != address(0),
            "WHITE token address should be not null"
        );
        require(
            bwtAddress != address(0),
            "BWT address should be not null"
        );
        require(
            blackTokenAddress != address(0),
            "BLACK token address should be not null"
        );
        require(
            vWalletAddress != address(0),
            "vWalletAddress should be not null"
        );
        require(
            aWalletAddress != address(0),
            "aWalletAddress address should be not null"
        );
        require(
            dWalletAddress != address(0),
            "dWalletAddress address should be not null"
        );
        require(
            yWalletAddress != address(0),
            "yWalletAddress address should be not null"
        );

        _vWalletAddress = vWalletAddress;
        _aWalletAddress = aWalletAddress;
        _dWalletAddress = dWalletAddress;
        _yWalletAddress = yWalletAddress;

        _primaryPool = PrimaryPool(primaryPoolAddress);

        _thisCollateralization = ICollateralization(
            thisCollateralizationAddress
        );
        _collateralToken = IERC20(collateralTokenAddress);

        _whiteToken = IERC20(whiteTokenAddress);
        _blackToken = IERC20(blackTokenAddress);
        _bwToken = IERC20(bwtAddress);

        _governanceAddress = msg.sender;
        _eventContractAddress = eventContractAddress == address(0)
            ? msg.sender
            : eventContractAddress;
        _baseCollateralizationAddress = baseCollateralizationAddress ==
            address(0)
            ? msg.sender
            : baseCollateralizationAddress;
        _governanceWalletAddress = governanceWalletAddress == address(0)
            ? msg.sender
            : governanceWalletAddress;
        _investorWalletAddress = investorWalletAddress == address(0)
            ? msg.sender
            : investorWalletAddress;

        _whitePrice = whitePrice;
        _blackPrice = blackPrice;
    }

    modifier noEvent {
        require(
            _eventStarted == false,
            "Function cannot be called during ongoing event"
        );
        _;
    }

    modifier onlyGovernance {
        require(
            _governanceAddress == msg.sender,
            "CALLER SHOULD BE GOVERNANCE"
        );
        _;
    }

    modifier onlyEventContract {
        require(
            _eventContractAddress == msg.sender,
            "CALLER SHOULD BE EVENT CONTRACT"
        );
        _;
    }

    struct EventEnd {
        uint256 currentbwPricePrimaryPool;
        uint256 whitePrice;
        uint256 blackPrice;
        uint256 whiteWinVolatility;
        uint256 blackWinVolatility;
        uint256 changePercent;
        uint256 whiteCoefficient;
        uint256 blackCoefficient;
        uint256 totalFundsInSecondaryPool;
        uint256 allWhiteCollateral;
        uint256 allBlackCollateral;
        uint256 spentForWhiteThisCycle;
        uint256 spentForBlackThisCycle;
        uint256 collateralForWhite;
        uint256 collateralForBlack;
        uint256 whiteBought;
        uint256 blackBought;
        uint256 receivedForWhiteThisCycle;
        uint256 receivedForBlackThisCycle;
    }

    event CurrentWhitePrice(uint256 currrentWhitePrice);
    event CurrentBlackPrice(uint256 currentBlackPrice);
    event WhiteBoughtThisCycle(uint256 whiteBoughtThisCycle);
    event BlackBoughtThisCycle(uint256 blackBoughtThisCycle);
    event WhiteSoldThisCycle(uint256 whiteSoldThisCycle);
    event BlackSoldThisCycle(uint256 blackSoldThisCycle);
    event WhiteBought(uint256 whiteBought);
    event BlackBought(uint256 blackBought);
    event ReceivedForWhiteThisCycle(uint256 receivedForWhiteThisCycle);
    event ReceivedForBlackThisCycle(uint256 receivedForBlackThisCycle);
    event SpentForWhiteThisCycle(uint256 spentForWhiteThisCycle);
    event SpentForBlackThisCycle(uint256 spentForBlackThisCycle);
    event AllWhiteCollateral(uint256 allWhiteCollateral);
    event AllBlackCollateral(uint256 allBlackCollateral);
    event TotalFunds(uint256 totalFundsInSecondaryPool);
    event WhiteCefficient(uint256 whiteCoefficient);
    event BlackCefficient(uint256 blackCoefficient);
    event ChangePercent(uint256 changePercent);
    event WhiteWinVolatility(uint256 whiteWinVolatility);
    event BlackWinVolatility(uint256 blackWinVolatility);
    event CollateralForWhite(uint256 collateralForWhite);
    event CollateralForBlack(uint256 collateralForBlack);
    event WhitePrice(uint256 whitePrice);
    event BlackPrice(uint256 blackPrice);
    event SecondaryPoolBWPrice(uint256 secondaryPoolBWPrice);
    event WhitePriceCase1(uint256 whitePrice);
    event WhitePricecase2(uint256 whitePrice);
    event BlackPriceCase1(uint256 blackPrice);
    event BlackPriceCase2(uint256 blackPrice);

    /**
     * Receive event results. Receives result of an event in value between -1 and 1. -1 means
     * Black won,1 means white-won.
     */
    function submitEventResult(int8 _result)
        external
        override
        onlyEventContract
    {
        require(
            _result == -1 || _result == 1 || _result == 0,
            "Result has inappropriate value. Should be -1 or 1"
        );

        _eventStarted = false;

        if (_result == 0) {
            return;
        }

        EventEnd memory eend;
        //Cells are cell numbers from SECONDARY POOL FORMULA DOC page

        //Get Black + White price from primaryPool. 
        eend.currentbwPricePrimaryPool = _primaryPool.getBWprice().mul(2); //cell 2 , cell 47

        // Cell 3
        uint256 currentWhitePrice = _whitePrice;
        emit CurrentWhitePrice(currentWhitePrice);

        // Cell 4
        uint256 currentBlackPrice = _blackPrice;
        emit CurrentBlackPrice(currentBlackPrice);

        //Cell 7
        uint256 whiteBoughtThisCycle = _whiteBoughtThisCycle;
        _whiteBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.
        emit WhiteBoughtThisCycle(whiteBoughtThisCycle);

        //Cell 8
        uint256 blackBoughtThisCycle = _blackBoughtThisCycle;
        _blackBoughtThisCycle = 0; // We need to start calculations from zero for the next cycle.
        emit BlackBoughtThisCycle(blackBoughtThisCycle);

        // Cell 10
        uint256 whiteSoldThisCycle = _whiteSoldThisCycle;
        _whiteSoldThisCycle = 0; // We need to start calculations from zero for the next cycle.
        emit WhiteSoldThisCycle(whiteSoldThisCycle);

        // Cell 11
        uint256 blackSoldThisCycle = _blackSoldThisCycle;
        _blackSoldThisCycle = 0; // We need to start calculations from zero for the next cycle.
        emit BlackSoldThisCycle(blackSoldThisCycle);


        // Cell 13
        eend.whiteBought = _whiteBought;
        emit WhiteBought(eend.whiteBought);
        if(eend.whiteBought == 0) {
            return;
        }

        // Cell 14
        eend.blackBought = _blackBought;
        emit BlackBought(eend.blackBought);
        if(eend.blackBought == 0) {
            return;
        }

        // Cell 16
        eend.receivedForWhiteThisCycle = wmul(whiteBoughtThisCycle, currentWhitePrice);
        emit ReceivedForWhiteThisCycle(eend.receivedForWhiteThisCycle);

        // Cell 17
        eend.receivedForBlackThisCycle = wmul(blackBoughtThisCycle, currentBlackPrice);
        emit ReceivedForBlackThisCycle(eend.receivedForBlackThisCycle);

        // Cell 19
        eend.spentForWhiteThisCycle = wmul(whiteSoldThisCycle, currentWhitePrice);
        emit SpentForWhiteThisCycle(eend.spentForWhiteThisCycle);
        
        // Cell 20
        eend.spentForBlackThisCycle = wmul(blackSoldThisCycle, currentBlackPrice);
        emit SpentForBlackThisCycle(eend.spentForBlackThisCycle);


        // Cell 22
        eend.allWhiteCollateral = _collateralForWhite
            .add(eend.receivedForWhiteThisCycle)
            .sub(eend.spentForWhiteThisCycle);
        emit AllWhiteCollateral(eend.allWhiteCollateral);
            
        if(eend.allWhiteCollateral == 0) {
            return;
        }

        // Cell 23
        eend.allBlackCollateral = _collateralForBlack
            .add(eend.receivedForBlackThisCycle)
            .sub(eend.spentForBlackThisCycle);
        emit AllBlackCollateral(eend.allBlackCollateral);
        
        if(eend.allBlackCollateral == 0) {
            return;
        }

        // Cell 24
        eend.totalFundsInSecondaryPool = eend.allWhiteCollateral.add(
            eend.allBlackCollateral
        );
        emit TotalFunds(eend.totalFundsInSecondaryPool);

        // To exclude division by zero There is a check for a non zero eend.allWhiteCollateral above
        // Cell 26
        eend.whiteCoefficient = wdiv(eend.allBlackCollateral, eend.allWhiteCollateral);
        emit WhiteCefficient(eend.whiteCoefficient);

        // To exclude division by zero There is a check for a non zero eend.allBlackCollateral above
        // Cell 27
        eend.blackCoefficient = wdiv(eend.allWhiteCollateral, eend.allBlackCollateral);
        emit BlackCefficient(eend.blackCoefficient);

        // Cell 29
        eend.changePercent = _currentEventPercentChange;
        emit ChangePercent(eend.changePercent);

        // Cell 30
        eend.whiteWinVolatility = wmul(eend.whiteCoefficient, eend.changePercent);
        emit WhiteWinVolatility(eend.whiteWinVolatility);

        // Cell 31
        eend.blackWinVolatility = wmul(eend.blackCoefficient, eend.changePercent);
        emit BlackWinVolatility(eend.blackWinVolatility);

        // white won
        if (_result == 1) {
            // Cell 33, 43
            eend.collateralForWhite = wmul(eend.allWhiteCollateral, WAD.add(eend.whiteWinVolatility));
            emit CollateralForWhite(eend.collateralForWhite);

            // Cell 36, 44
            eend.collateralForBlack = wmul(eend.allBlackCollateral, WAD.sub(eend.changePercent));
            emit CollateralForBlack(eend.collateralForBlack);

            // To exclude division by zero There is a check for a non zero eend.whiteBought above
            // Like Cell 47
            eend.whitePrice = wdiv(eend.collateralForWhite, eend.whiteBought); 
            emit WhitePrice(eend.whitePrice);

            // To exclude division by zero There is a check for a non zero eend.blackBought above
            // Like Cell 48
            eend.blackPrice = wdiv(eend.collateralForBlack, eend.blackBought);
            emit BlackPrice(eend.blackPrice);

            // Cell 48
            uint256 secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);
            emit SecondaryPoolBWPrice(secondaryPoolBWPrice);

            // Cell 55, 57, 58
            uint256 bwPriceDiff = 0;
            if (secondaryPoolBWPrice > eend.currentbwPricePrimaryPool) {
                bwPriceDiff = secondaryPoolBWPrice.sub(
                    eend.currentbwPricePrimaryPool
                );
                eend.whitePrice = eend.whitePrice.sub(bwPriceDiff);
                emit WhitePriceCase1(eend.whitePrice);
            } else {
                bwPriceDiff = eend.currentbwPricePrimaryPool.sub(
                    secondaryPoolBWPrice
                );
                eend.whitePrice = eend.whitePrice.add(bwPriceDiff);
                emit WhitePricecase2(eend.whitePrice);
            }
        }

        // black won
        if (_result == -1) {
            // Cell 34, 43
            eend.collateralForWhite = wmul(eend.allWhiteCollateral, WAD.sub(eend.changePercent));
            emit CollateralForWhite(eend.collateralForWhite);

            // Cell 35, 44
            eend.collateralForBlack = wmul(eend.allBlackCollateral, WAD.add(eend.blackWinVolatility));
            emit CollateralForBlack(eend.collateralForBlack);

            // To exclude division by zero There is a check for a non zero eend.whiteBought above
            // Like Cell 47
            eend.whitePrice = wdiv(eend.collateralForWhite, eend.whiteBought);
            emit WhitePrice(eend.whitePrice);

            // To exclude division by zero There is a check for a non zero eend.blackBought above
            // Like Cell 48
            eend.blackPrice = wdiv(eend.collateralForBlack, eend.blackBought);
            emit BlackPrice(eend.blackPrice);

            // Cell 48
            uint256 secondaryPoolBWPrice = eend.whitePrice.add(eend.blackPrice);
            emit SecondaryPoolBWPrice(secondaryPoolBWPrice);

            // Cell 55, 57, 58
            uint256 bwPriceDiff = 0;
            if (secondaryPoolBWPrice > eend.currentbwPricePrimaryPool) {
                bwPriceDiff = secondaryPoolBWPrice.sub(
                    eend.currentbwPricePrimaryPool
                );
                eend.blackPrice = eend.blackPrice.sub(bwPriceDiff);
                emit BlackPriceCase1(eend.blackPrice);
            } else {
                bwPriceDiff = eend.currentbwPricePrimaryPool.sub(
                    secondaryPoolBWPrice
                );
                eend.blackPrice = eend.blackPrice.add(bwPriceDiff);
                emit BlackPriceCase2(eend.blackPrice);
            }
        }

        _whitePrice = eend.whitePrice;
        _blackPrice = eend.blackPrice;

        _collateralForWhite = eend.collateralForWhite;
        _collateralForBlack = eend.collateralForBlack;
    }

    /**
     * @param currentEventPriceChangePercent - from 1% to 40% (with 1e18 math: 1e18 == 100%)
     * */
    function submitEventStarted(uint256 currentEventPriceChangePercent)
        external
        override
        onlyEventContract
    {
        require(
            currentEventPriceChangePercent <= 0.4 * 1e18,
            "Too high event price change percent submitted: no more than 40%"
        );
        require(
            currentEventPriceChangePercent >= 0.01 * 1e18,
            "Too lower event price change percent submitted: at least 1%"
        );

        _currentEventPercentChange = currentEventPriceChangePercent;

        _eventStarted = true;
    }

    function sellBlack(uint256 tokensAmount, uint256 minPrice) public noEvent {
        require(_blackBought > tokensAmount.add(MIN_HOLD), "Cannot buyback more than sold from the pool");

        (uint256 collateralAmountWithFee, uint256 collateralToSend) =
            genericSell(
                _blackToken,
                _blackPrice,
                minPrice,
                tokensAmount,
                false
            );
        _blackBought = _blackBought.sub(tokensAmount);
        _collateralForBlack = _collateralForBlack.sub(collateralAmountWithFee);
        _blackSoldThisCycle = _blackSoldThisCycle.add(tokensAmount);
        emit SellBlack(msg.sender, collateralToSend, _blackPrice);
    }

    function sellWhite(uint256 tokensAmount, uint256 minPrice) public noEvent {
        require(_whiteBought > tokensAmount.add(MIN_HOLD), "Cannot buyback more than sold from the pool");

        (uint256 collateralAmountWithFee, uint256 collateralToSend) =
            genericSell(_whiteToken, _whitePrice, minPrice, tokensAmount, true);
        _whiteBought = _whiteBought.sub(tokensAmount);
        _collateralForWhite = _collateralForWhite.sub(collateralAmountWithFee);
        _whiteSoldThisCycle = _whiteSoldThisCycle.add(tokensAmount);
        emit SellWhite(msg.sender, collateralToSend, _whitePrice);
    }

    function genericSell(
        IERC20 token,
        uint256 price,
        uint256 minPrice,
        uint256 tokensAmount,
        bool isWhite
    ) private returns (uint256, uint256) {
        require(
            token.allowance(msg.sender, address(_thisCollateralization)) >=
                tokensAmount,
            "Not enough delegated tokens"
        );
        require(
            price >= minPrice,
            "Actual price is lower than acceptable by the user"
        );

        uint256 collateralWithFee = wmul(tokensAmount, price);
        uint256 feeAmount = wmul(collateralWithFee, FEE);
        uint256 collateralToSend = collateralWithFee.sub(feeAmount);

        updateFees(feeAmount);

        require(
            _collateralToken.balanceOf(address(_thisCollateralization)) > collateralToSend,
            "Not enought collateral liquidity in the pool"
        );

        _thisCollateralization.buyBackSeparately(
            msg.sender,
            tokensAmount,
            isWhite,
            collateralToSend
        );

        return (collateralWithFee, collateralToSend);
    }

    function buyBlack(uint256 maxPrice, uint256 payment) public noEvent {
        (uint256 tokenAmount, uint256 collateralToBuy) =
            genericBuy(maxPrice, _blackPrice, _blackToken, false, payment);
        _collateralForBlack = _collateralForBlack.add(collateralToBuy);
        _blackBought = _blackBought.add(tokenAmount);
        _blackBoughtThisCycle = _blackBoughtThisCycle.add(tokenAmount);
        emit BuyBlack(msg.sender, tokenAmount, _blackPrice);
    }

    function buyWhite(uint256 maxPrice, uint256 payment) public noEvent {
        (uint256 tokenAmount, uint256 collateralToBuy) =
            genericBuy(maxPrice, _whitePrice, _whiteToken, true, payment);
        _collateralForWhite = _collateralForWhite.add(collateralToBuy);
        _whiteBought = _whiteBought.add(tokenAmount);
        _whiteBoughtThisCycle = _whiteBoughtThisCycle.add(tokenAmount);
        emit BuyWhite(msg.sender, tokenAmount, _whitePrice);
    }

    function genericBuy(
        uint256 maxPrice,
        uint256 price,
        IERC20 token,
        bool isWhite,
        uint256 payment
    ) private returns (uint256, uint256) {
        require(
            price <= maxPrice,
            "Actual price is higher than acceptable by the user"
        );
        require(
            _collateralToken.allowance(msg.sender, address(_thisCollateralization)) >= payment, 
            "Not enough delegated tokens"
        );
            
        uint256 feeAmount = wmul(payment, FEE);

        updateFees(feeAmount);

        uint256 paymentToBuy = payment.sub(feeAmount);
        uint256 tokenAmount = wdiv(paymentToBuy, price);
        require(
            token.balanceOf(address(_thisCollateralization)) > tokenAmount,
            "Not enought liquidity in the pool"
        );

        _thisCollateralization.buySeparately(
            msg.sender,
            tokenAmount,
            isWhite,
            payment
        );
        return (tokenAmount, paymentToBuy);
    }

    function updateFees(uint256 feeAmount) internal {
        // update team fee collected
        if (_totalTeamFeeCollected < MAX_TEAM_FEE) {
            _teamFeeCollected = _teamFeeCollected.add(wmul(feeAmount, _teamFee));
        }

        // update governance fee collected
        _feeGovernanceCollected = _feeGovernanceCollected.add(
            wmul(feeAmount, _governanceFee)
        );
        
        // update BW addition fee collected
        _feeBWAdditionCollected = _feeBWAdditionCollected.add(
            wmul(feeAmount, _bwInitialFee)
        );
    }

    function addLiquidity(uint256 tokensAmount) public {
        _thisCollateralization.addLiquidity(msg.sender, tokensAmount);

        _blackLiquidity = _blackLiquidity.add(tokensAmount);
        _whiteLiquidity = _whiteLiquidity.add(tokensAmount);

        uint256 poolTokensToSend = wdiv(tokensAmount, poolTokenPriceInBW());

        _mint(msg.sender, poolTokensToSend);
        emit AddLiquidity(msg.sender, tokensAmount);
    }

    function withdrawLiquidity(uint256 poolTokensAmount) public {
        require(
            allowance[msg.sender][address(this)] >= poolTokensAmount,
            "Not enough delegated pool tokens on user balance"
        );

        uint256 tokensToSend = wmul(poolTokensAmount, poolTokenPriceInBW());
        
        uint256 thisBlackBalance =
            _blackToken.balanceOf(address(_thisCollateralization));

        uint256 thisWhiteBalance =
            _whiteToken.balanceOf(address(_thisCollateralization));
            
        uint256 maxWithdraw = 0;
        
        if(thisWhiteBalance < thisBlackBalance) {
            maxWithdraw = thisWhiteBalance;
        } else {
            maxWithdraw = thisBlackBalance;
        }
        
        require(maxWithdraw >= tokensToSend, "Not enough BLACK or WHITE tokens to withdraw");

        _thisCollateralization.withdraw(msg.sender, tokensToSend);

        _blackLiquidity = _blackLiquidity.sub(tokensToSend);
        _whiteLiquidity = _whiteLiquidity.sub(tokensToSend);

        _burn(msg.sender, poolTokensAmount);
        emit WithdrawLiquidity(poolTokensAmount, tokensToSend);
    }

    /*
        B from ethForBlack +
        W from ethForWhite +
        Black & white tokens 
    */
    function poolTokenPriceInBW() public view returns (uint256) {
        uint256 totalCollateralForBW = _collateralForBlack.add(_collateralForWhite);
        uint256 contractCollateral = _collateralToken.balanceOf(address(_thisCollateralization));

        // avoid dividing totalEthForBW by zero
        if (contractCollateral == 0 || totalCollateralForBW == 0) {
            return WAD;
        }

        uint256 contractCollateralWithoutNotMmFee =
            contractCollateral.sub(_feeGovernanceCollected).sub(_teamFeeCollected).sub(
                _feeBWAdditionCollected
            );
        uint256 collateralAddition = contractCollateralWithoutNotMmFee.sub(totalCollateralForBW);
        uint256 collateralAdditionPart = wdiv(collateralAddition, totalCollateralForBW);

        return WAD.add(collateralAdditionPart);
    }

    function changeGovernanceAddress(address governanceAddress)
        public
        onlyGovernance
    {
        require(
            governanceAddress != address(0),
            "New Gouvernance address should be not null"
        );
        _governanceAddress = governanceAddress;
    }

    function changePrimaryPoolAddress(address primaryPoolAddress)
        public
        onlyGovernance
    {
        require(
            primaryPoolAddress != address(0),
            "New PrimaryPool address should be not null"
        );

        _primaryPool = PrimaryPool(primaryPoolAddress);
    }

    function changeEventContractAddress(address evevntContractAddress)
        public
        onlyGovernance
    {
        require(
            evevntContractAddress != address(0),
            "New event contract address should be not null"
        );

        _eventContractAddress = evevntContractAddress;
    }

    function changeCollateralizationContractAddress(address payable newAddress)
        public
        onlyGovernance
    {
        require(
            newAddress != address(0),
            "New Collateralization address should be not null"
        );

        _baseCollateralizationAddress = newAddress;
    }

    function changeGovernanceWalletAddress(address payable newAddress)
        public
        onlyGovernance
    {
        require(
            newAddress != address(0),
            "New Gouvernance wallet address should be not null"
        );

        _governanceWalletAddress = newAddress;
    }

    function distributeProjectIncentives() public {
        _thisCollateralization.withdrawCollateral(_governanceWalletAddress, _feeGovernanceCollected);
        _feeGovernanceCollected = 0;
        _thisCollateralization.withdrawCollateral(_baseCollateralizationAddress, _feeBWAdditionCollected);
        _feeBWAdditionCollected = 0;

        if (_totalTeamFeeCollected < MAX_TEAM_FEE) {
            uint256 teamFee = _teamFeeCollected.mul(70).div(100);
            uint256 yFee = teamFee.div(5);

            _thisCollateralization.withdrawCollateral(_yWalletAddress, yFee);
            uint256 pFee = teamFee.mul(266).div(1000);
            _thisCollateralization.withdrawCollateral(_vWalletAddress, pFee);
            _thisCollateralization.withdrawCollateral(_aWalletAddress, pFee);
            _thisCollateralization.withdrawCollateral(_dWalletAddress, pFee);
            
            uint256 bwPrice = _blackPrice.add(_whitePrice);
            uint256 teamDistributed = yFee.add(pFee.mul(3));

            uint256 investorIncentives = _teamFeeCollected.mul(30).div(100);

            _thisCollateralization.withdrawCollateral(_investorWalletAddress, investorIncentives);

            uint256 distributed = teamDistributed.add(investorIncentives);
            _teamFeeCollected = _teamFeeCollected.sub(distributed);

            /*
            Next variable calculate collected in B&W tokens
            */
            _totalTeamFeeCollected = _totalTeamFeeCollected.add(wdiv(distributed, bwPrice));

            // remove teamFee and update governance and lp fees
            if (_totalTeamFeeCollected >= MAX_TEAM_FEE) {
                _governanceFee = 0.3 * 1e18;
                _teamFee = 0;
            }
        }
    }
}