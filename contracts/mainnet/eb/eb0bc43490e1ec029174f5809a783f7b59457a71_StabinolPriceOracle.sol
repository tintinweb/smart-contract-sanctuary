/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// Price Oracle for Stabinol Token
// This contract uses both Chainlink and Uniswap to obtain the token price
// It initially uses 10 minute averages but can be updated on the fly by governance

pragma solidity 0.6.6;


interface AggregatorV3Interface {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface UniswapV2Pair {
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract StabinolPriceOracle {

    address public owner;
    bool private _firstCapture = true;
    uint256 private _stolUSDPrice = 0;
    uint256 private _stolPriceWindow = 0; // The time period this price was calculated over, determines its weight
    uint256 private _tokenIndex = 0;
    uint256 public lastSTOLPriceUpdate; // The last time the price was updated
    uint256 public updateFrequency = 10 minutes; // Oracle can be updated at least every 10 minutes
    
    address constant CHAINLINK_ETH_ORACLE = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    uint256 constant DIVISION_FACTOR = 100000;
    
    // TWAP details
    address public stolLiquidity;
    uint256 private lastTWAPCumulativePrice;
    uint32 private lastTWAPBlockTime;
    uint256 private lastTWAPPrice;
    
    // Events
    event NoLiquidity();
    event FirstPriceCapture(); // First time price update is called, must wait til another time to update
    event FailedPriceCapture(); // Not quick enough price movement for a twap to be calculated
    
    constructor(address _lp, uint256 _index) public {
        owner = msg.sender;
        stolLiquidity = _lp; // This is the address to the Uniswap pair
        _tokenIndex = _index; // STOL could be in either position 1 or position 2
    }
    
    modifier onlyGovernance() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function getETHUSD() public view returns (uint256) {
        // Returns this price with 18 decimal places
        AggregatorV3Interface ethOracle = AggregatorV3Interface(CHAINLINK_ETH_ORACLE);
        ( , int intEthPrice, , , ) = ethOracle.latestRoundData(); // We only want the answer 
        return uint256(intEthPrice) * 1e10;
    }
    
    function getLatestSTOLUSD() external view returns (uint256) {
        // Returns the stored price
        return _stolUSDPrice;
    }
    
    function governanceChangeFrequency(uint256 _freq) external onlyGovernance {
        updateFrequency = _freq;
    }
    
    function updateSTOLPrice() external {
        if(now < lastSTOLPriceUpdate + updateFrequency){ return; } // Do nothing if update is called too soon
        uint256 period = now - lastSTOLPriceUpdate; // Get the time between the last update and now
        lastSTOLPriceUpdate = now;
        // We will use a combination of the Twap and weighted averages to determine the current price
        UniswapV2Pair pair = UniswapV2Pair(stolLiquidity);
        (, uint112 reserve1, uint32 _blockTime) = pair.getReserves();
        if(reserve1 == 0){
            // Liquidity is gone/non-existant, can't update the price
            // Reset the oracle
            _stolUSDPrice = 0;
            _stolPriceWindow = 0;
            lastTWAPBlockTime = 0;
            lastTWAPCumulativePrice = 0;
            _firstCapture = true;
            emit NoLiquidity();
            return;
        }
        if(lastTWAPBlockTime != _blockTime){
            // Uniswap twap price has updated, update our twap price
            if(_firstCapture == true){
                // Never had a price before, save the price accumulators
                if(_tokenIndex == 0){
                    lastTWAPCumulativePrice = pair.price0CumulativeLast();
                }else{
                    lastTWAPCumulativePrice = pair.price1CumulativeLast();
                }
                lastTWAPBlockTime = _blockTime;
                _firstCapture = false;
                emit FirstPriceCapture();
                return;
            }else{
                // We already have a price cumulative, capture a new price
                uint256 cumuPrice = 0;
                if(_tokenIndex == 0){
                    cumuPrice = pair.price0CumulativeLast();
                }else{
                    cumuPrice = pair.price1CumulativeLast();
                }
                // This is price in relationship to base pair
                lastTWAPPrice = ((cumuPrice - lastTWAPCumulativePrice) / (_blockTime - lastTWAPBlockTime) * 1e18) >> 112;
                lastTWAPCumulativePrice = cumuPrice;
                lastTWAPBlockTime = _blockTime;
            }
        }
        if(lastTWAPPrice == 0){
            // Still no price calculation possible since no action on trading pair since last call
            emit FailedPriceCapture();
            return;
        }
        if(_stolPriceWindow == 0){
            // First time price is calculated, set it to the twap price in USD
            _stolPriceWindow = updateFrequency;
            // Now calculate USD price from ETH Price
            _stolUSDPrice = getETHUSD() / 1e10 * lastTWAPPrice / 1e8;
        }else{
            // There is already a price window and price, use weighted averages to determine the weight
            uint256 price = getETHUSD() / 1e10 * lastTWAPPrice / 1e8;
            _stolUSDPrice = (_stolUSDPrice * (_stolPriceWindow * DIVISION_FACTOR / (_stolPriceWindow + period)) / DIVISION_FACTOR);
            _stolUSDPrice += (price * (period * DIVISION_FACTOR / (_stolPriceWindow + period)) / DIVISION_FACTOR);
            _stolPriceWindow = period; // Set the window to the new period
        }
    }

}