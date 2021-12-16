/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// File: FNFT/contracts/interfaces/IGlobalGovernanceSettings.sol

pragma solidity ^0.8.0;

interface IGlobalGovernanceSettings {
    function minAuctionLength() external returns (uint);

    function maxAuctionLength() external returns (uint);

    function auctionLengthLowerBound() external returns (uint);

    function auctionLengthUpperBound() external returns (uint);

    function governanceFee() external returns (uint);

    function governenceFeeUpperBound() external returns (uint);

    function tradingFee() external returns (uint);

    function tradingFeeUpperBound() external returns (uint);

    function feeClaimer() external returns (address payable);

    function originalOwnerBuyoutFeeUpperBound() external returns (uint);

    function originalOwnerTradingFeeUpperBound() external returns (uint);

    function minBidIncrement() external returns (uint);

    function maxBidIncrement() external returns (uint);

    function bidIncrementLowerBound() external returns (uint);

    function bidIncrementUpperBound() external returns (uint);

    function minVotePercentageThreshold() external returns (uint);

    function maxVotePercentageThreshold() external returns (uint);

    function reservePriceLowerLimitPercentage() external returns (uint);

    function reservePriceUpperLimitPercentage() external returns (uint);

    function nftStoreHouse() external returns (address);

    function currencyToAcceptableForTrading(address) external returns (bool);
}
// File: FNFT/contracts/GlobalGovernanceSettings.sol

pragma solidity ^0.8.0;


contract GlobalGovernanceSettings is IGlobalGovernanceSettings {
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xD92E713d051C37EbB2561803a3b5FBAbc4962431; // 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant eth = address(0);
    
    mapping(address => bool) public override currencyToAcceptableForTrading;
    address[] public currenciesAcceptableForTrading = [weth, dai, usdc, usdt, eth];
    
    uint public override minAuctionLength;
    uint public override maxAuctionLength;
    uint public override immutable auctionLengthLowerBound;
    uint public override immutable auctionLengthUpperBound;
    
    uint public override governanceFee; // In terms of 0.01%
    uint public override immutable governenceFeeUpperBound;
    uint public override tradingFee; // In terms of 0.01%
    uint public override immutable tradingFeeUpperBound;
    address payable public override feeClaimer;
    
    uint public immutable override originalOwnerBuyoutFeeUpperBound;
    uint public immutable override originalOwnerTradingFeeUpperBound;

    uint public override minBidIncrement;
    uint public override maxBidIncrement;
    uint public override immutable bidIncrementLowerBound;
    uint public override immutable bidIncrementUpperBound;
    
    uint public override immutable minVotePercentageThreshold;
    uint public override immutable maxVotePercentageThreshold;
    
    uint public override reservePriceLowerLimitPercentage;
    uint public override reservePriceUpperLimitPercentage;
    
    address public owner;
    
    address public override immutable nftStoreHouse;
    
    event UpdateMinAuctionLength(uint oldValue, uint newValue);
    event UpdateMaxAuctionLength(uint oldValue, uint newValue);
    event UpdateGovernanceFee(uint oldValue, uint newValue);
    event UpdateTradingFee(uint oldValue, uint newValue);
    event UpdateFeeClaimer(address oldValue, address newValue);
    event UpdateMinBidIncrement(uint oldValue, uint newValue);
    event UpdateMaxBidIncrement(uint oldValue, uint newValue);
    event UpdateReservePriceLowerLimitPercentage(uint oldValue, uint newValue);
    event UpdateReservePriceUpperLimitPercentage(uint oldValue, uint newValue);
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner) {
        minAuctionLength = 10 minutes;
        maxAuctionLength = 3 days;
        auctionLengthLowerBound = 10 minutes;
        auctionLengthUpperBound = 3 days;
        
        governanceFee = 1000;
        governenceFeeUpperBound = 1000;
        tradingFee = 1000;
        tradingFeeUpperBound = 1000;
        feeClaimer = payable(_owner);
        
        originalOwnerBuyoutFeeUpperBound = 1000;
        originalOwnerTradingFeeUpperBound = 1000;
        
        minBidIncrement = 100;
        maxBidIncrement = 5000;
        bidIncrementLowerBound = 10;
        bidIncrementUpperBound = 10000;
        
        owner = _owner;
        
        minVotePercentageThreshold = 100;
        maxVotePercentageThreshold = 8000;
        reservePriceLowerLimitPercentage = 1000;
        reservePriceUpperLimitPercentage = 100000;
        nftStoreHouse = msg.sender;
        
        currencyToAcceptableForTrading[weth] = true;
        currencyToAcceptableForTrading[dai] = true;
        currencyToAcceptableForTrading[usdc] = true;
        currencyToAcceptableForTrading[usdt] = true;
        currencyToAcceptableForTrading[eth] = true;
    }
    
    function setMinAuctionLength(uint _minAuctionLength) public onlyOwner {
        require(_minAuctionLength >= auctionLengthLowerBound);
        require(_minAuctionLength < maxAuctionLength);
        emit UpdateMinAuctionLength(minAuctionLength, _minAuctionLength);
        minAuctionLength = _minAuctionLength;
    }
    
    function setMaxAuctionLength(uint _maxAuctionLength) public onlyOwner {
        require(_maxAuctionLength <= auctionLengthUpperBound);
        require(_maxAuctionLength > minAuctionLength);
        emit UpdateMaxAuctionLength(maxAuctionLength, _maxAuctionLength);
        maxAuctionLength = _maxAuctionLength;
    }
    
    function setTradingFee(uint _tradingFee) public onlyOwner {
        require(_tradingFee <= tradingFeeUpperBound);
        emit UpdateTradingFee(tradingFee, _tradingFee);
        tradingFee = _tradingFee;
    }
    
    function setGovernanceFee(uint _governanceFee) public onlyOwner {
        require(_governanceFee <= governenceFeeUpperBound);
        emit UpdateGovernanceFee(governanceFee, _governanceFee);
        governanceFee = _governanceFee;
    }
    
    function setFeeClaimer(address _feeClaimer) public onlyOwner {
        emit UpdateFeeClaimer(feeClaimer, _feeClaimer);
        feeClaimer = payable(_feeClaimer);
    }
    
    function setMinBidIncrement(uint _minBidIncrement) public onlyOwner {
        require(_minBidIncrement >= bidIncrementLowerBound);
        require(_minBidIncrement < maxBidIncrement);
        emit UpdateMinBidIncrement(minBidIncrement, _minBidIncrement);
        minBidIncrement = _minBidIncrement;
    }
    
    function setMaxBidIncrement(uint _maxBidIncrement) public onlyOwner {
        require(_maxBidIncrement <= bidIncrementUpperBound);
        require(_maxBidIncrement > minBidIncrement);
        emit UpdateMaxBidIncrement(maxBidIncrement, _maxBidIncrement);
        maxBidIncrement = _maxBidIncrement;
    }
    
    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function setReservePriceLowerLimitPercentage(uint _reservePriceLowerLimitPercentage) public onlyOwner {
        require(_reservePriceLowerLimitPercentage < reservePriceUpperLimitPercentage);
        emit UpdateReservePriceLowerLimitPercentage(reservePriceLowerLimitPercentage, _reservePriceLowerLimitPercentage);
        reservePriceLowerLimitPercentage = _reservePriceLowerLimitPercentage;
    }
    
    
    function setReservePriceUpperLimitPercentage(uint _reservePriceUpperLimitPercentage) public onlyOwner {
        require(reservePriceLowerLimitPercentage < _reservePriceUpperLimitPercentage);
        emit UpdateReservePriceUpperLimitPercentage(reservePriceUpperLimitPercentage, _reservePriceUpperLimitPercentage);
        reservePriceUpperLimitPercentage = _reservePriceUpperLimitPercentage;
    }
    
    function addAcceptableCurrency(address _currency) public onlyOwner {
        if (!currencyToAcceptableForTrading[_currency]) {
            currencyToAcceptableForTrading[_currency] = true;
            currenciesAcceptableForTrading.push(_currency);
        }
    }
    
    function removeAcceptableCurrency(address _currency) public onlyOwner {
        if (currencyToAcceptableForTrading[_currency]) {
            currencyToAcceptableForTrading[_currency] = false;
            for (uint i = 0; i < currenciesAcceptableForTrading.length; i++) {
                if (currenciesAcceptableForTrading[i] == _currency) {
                    currenciesAcceptableForTrading[i] = currenciesAcceptableForTrading[currenciesAcceptableForTrading.length - 1];
                    break;
                }
            }
            currenciesAcceptableForTrading.pop();
        }
    }
}