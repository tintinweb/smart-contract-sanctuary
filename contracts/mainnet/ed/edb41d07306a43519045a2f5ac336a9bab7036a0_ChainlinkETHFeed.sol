/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

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

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface ETHFeed {
    function priceForEtherInUsdWei() external view returns (uint256);
}

contract ChainlinkETHFeed is ETHFeed {
    address public aggregator;

    constructor(address _aggregator) public {
        aggregator = _aggregator;
    }

    function priceForEtherInUsdWei() external view returns (uint256) {
        AggregatorInterface agg = AggregatorInterface(aggregator);
        uint256 currentPrice = uint256(agg.latestAnswer());
        uint256 decimals = agg.decimals();

        if (decimals == 18) {
            return currentPrice;
        } else if (decimals < 18) {
            //Convert price to wei
            uint256 factor = 10 ** (18 - decimals);
            uint256 convertedPrice = currentPrice * factor;

            return convertedPrice;
        } else {
            revert("Feed is using unsupported decimals");
        }
    }
}