// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// // Import from the chainlink code in NPM: https://www.npmjs.com/package/@chainlink/contracts
// // which links to the repository code at: https://github.com/smartcontractkit/chainlink
// // what is being imported: 
// // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
import "AggregatorV3Interface.sol";
// // The chainlink contract is an interface.
// // Interfaces compile down to an Application Binary Interface (ABI)
// // ABI tells solidity and other programming languages how it can interact with another contract
// // What this means is that anytime is needed to interact with an already deployed smart contract, this contract's ABI is needed

// All the funds received by this contract are owned by it
contract FundMe {
    // // It checks for overflow in numbers when they go over the maximum storing possible for them
    // // and signals that corrections need to be done. This is only from versions of Solidity
    // // lower than 0.8. From 0.8, the compiler includes this check
    // using SafeMathChainlink for uint256;

//    address ETH_USDC_price = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address payable public owner;
    AggregatorV3Interface public priceFeed;

    // Keeping track of all the addresses and amounts received from them
    mapping(address => uint256) public addressToAmountFunded;
    
    // array of addresses named "funders"
    address[] public funders;

    // constructor executes a function the moment the contract gets deployed
    constructor(address _priceFeed) public {

        priceFeed = AggregatorV3Interface(_priceFeed);

        // Sets the owner of the contract to however deploys it
        owner = payable(msg.sender);
    }

    // payable = To indicate that the function can pay or receive ETH
    function fund() public payable {

        // Set minimum threeshold of USD to accept in the contract
        // The value is in Gwei

        uint256 minimumUSD = 50 * 10**8;

        // require function in Solidity stops contract from executing if a parameter is not met
        // Validates that received ETH does meets the required minimum
        // if not, the deposited ETH is returned with a message
        // Convert ETH -> USDC
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");

        // msg.sender and msg.value are key words for who interacted with the function
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    // Returns the aggregator version
    function getVersion() public view returns (uint256){
        // The address comes from the ETH/USD data feed for Rinkeby Testnet: https://docs.chain.link/docs/ethereum-addresses/
//        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETH_USDC_price);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
//        AggregatorV3Interface priceFeed = AggregatorV3Interface(ETH_USDC_price);
        
        // Stored the returned latest price values into a tupple
        // // It is possible to return blank values for unused variables. So, from:
        // (uint80 roundId,
        // int256 answer,
        // uint256 startedAt,
        // uint256 updatedAt,
        // uint80 answeredInRound) = priceFeed.latestRoundData();

        // to:

        // (,
        // int256 answer,
        // ,
        // ,
        // ) = priceFeed.latestRoundData();

        // reorganizing it:

        (, int256 answer,,,) = priceFeed.latestRoundData();


        // Cast the type of the return variable
        // value returned is in gwei
        return uint256(answer);

        // Decimals do not work in Solidity. The values returned are multiplied by 10 raised to the 8:
        // E.g. 380320500000 is returned by an Oracle. That value comes from:
        // 3,803.20500000 * 10**8 = 380320500000

        // The return values is in units of gwei
        // to convert the return value wei, it would need ten zeros:
        // return uint256(answer * 10**10);
        // or 
        // return uint256(answer * 10000000000);

    }


    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();

        // Divides by 10**8 because values are quoted in gwei
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**8;
        return ethAmountInUsd;
        // returned value would require more decimals until having 8:
        // 381109715073 => 3811.09715073
    }

    modifier onlyOwner{
                // Only admin /owner of contract can execute
        require(msg.sender == owner, "You are not the owner");

        // The underscore indicates where the rest of the function withdraw would execute
        _;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD to accept as fund
        uint256 mimimumUSD = 50 * 10**18;

        // current price of ETH in USD
        uint256 price = getPrice();

        // Get right amount of zeros - wei
        uint256 precision = 1 * 10**18;

        // return value of ETH in USD
        return (mimimumUSD * precision) / price;
    }

    function withdraw() payable onlyOwner public {

        // address(this).balance means that it is using the address of the current smart contract
        payable(msg.sender).transfer(address(this).balance);
        
        // since the funds are withdrawn, it resets for all the funds that have been provided
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Resets the funder array
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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