//SPDX-License_Identifier: MIT
import "AggregatorV3Interface.sol";

pragma solidity >=0.6.0 <0.9.0;

contract Fundme{
    mapping(address=>uint256) adress_to_amount_funded;
    address owner;
    address[] funders;
    AggregatorV3Interface _price_feed;
    address _PriceFeedContractBSC = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
    
    function fund() public payable{
        uint256 minUSD = 50 * (10**18);
        require(getConversionRate(msg.value) >= minUSD, "minimum amount to participate is 50$");
        adress_to_amount_funded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    constructor(address PriceFeedAddress) public{
        _price_feed = AggregatorV3Interface(PriceFeedAddress);
        owner = msg.sender;
    }

    modifier _OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    //100000000000000000 => 0.1 * 532
    //https://docs.chain.link/docs/binance-smart-chain-addresses/
    function getPrice() public view returns(uint256){
        (,int256 answer,,,) = _price_feed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 v) public view returns(uint256){
        uint256 amountUSD = v * (getPrice()/100000000);
        //0.1 * 10**18 * 532 = 53200000000000000000 = 53.2$
        return amountUSD;
    }
    
    function Refund() public payable _OnlyOwner{
        for(uint256 i = 0 ; i < funders.length ; i++){
            uint256 value_to_refund = adress_to_amount_funded[funders[i]];
            payable(funders[i]).transfer(value_to_refund);
            adress_to_amount_funded[funders[i]] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}