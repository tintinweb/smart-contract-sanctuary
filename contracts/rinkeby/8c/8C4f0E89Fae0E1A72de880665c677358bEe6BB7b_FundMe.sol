// SPDX-License-Identifier: MIT
//-- if you dont have this ,solidity yell you
//At the top this important
//Control + S to Save
pragma solidity ^0.8.0;

//Import from NPM Package
import "AggregatorV3Interface.sol";

//import "AggregatorV3Interface.sol";

//https://www.npmjs.com/package/@chainlink/contracts

//Defining a contract
contract FundMe {
    //Avoid overflow in 0.6.6 version in newers versions this not happen
    //using SafeMathChainlink for uint256;

    //Attaching library to uint - overflow
    //Who is sending the funding
    //Mapping addres and the value
    mapping(address => uint256) public addresToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //Call the instance when this get deploy
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; //whos deploy the contract
    }

    //Payable - This accept payments ETH/Ethereum
    //Button its read because its payable
    function fund() public payable {
        uint256 minimalUSD = 50 * 10**18;
        //1 gwei < $50
        //If its less than 50 , this transaction stop and dont consume gas
        require(
            getConversionRate(msg.value) >= minimalUSD,
            "You need to spend more ETH"
        );
        //Who is sending the funding - Keywords
        //Msg.sender its the sender about whos call
        //msg.value the value they sent
        addresToAmountFunded[msg.sender] += msg.value;
        //For now ignore and can be rendudant
        //To avoid loop through every key
        funders.push(msg.sender);
        //What the ETH -> USD Conversion rate
    }

    function getVersion() public view returns (uint256) {
        // SimpleStorage simpleStorage= SimpleStorage(address (simpleStorageArray[_simpleStorageIndex]));
        //Finding priceFeed address
        //This address its located in testnet

        //If this is located in that addres, then return the price
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (
            ,
            //Unused types variables , leave in blank,in the same mode that the fucntion
            int256 answer,
            ,
            ,

        ) = priceFeed.latestRoundData();
        //casting - change the type value to another
        //gwei mode  - matching units
        //everything has 18 decimal places
        return uint256(answer * 10000000000);
        //Result in wei mode
    }

    // 1000000000 = 1ETH =  Gwei
    //Conversion to gwei
    //ETH to USD
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); //WEI
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        /*
                 4199265703350			   1.- Process Result Get Conversion Rate
          0.000004199265703350  WEI        2.- Add 18 to left  = RWEI
            123456789012345678        
        	RWEI x 1000000000			   3.- Multiply by RWEI value
        	4199.265703350	    
         
       */
    }

    //modifiers is used to change the behavior of a function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Only callable by the owner
    //Before run withdraw code , then go first onlyOwner
    function withdraw() public payable onlyOwner {
        //Only the owner can get his money
        //if you have ton of contracts, this is awful to write this line here    require(msg.sender == owner);

        //Send one amount to another address
        //To send all the money in the contract
        //msg.sender.transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
        //Reset balance to 0, funders balance because you withdraw all your balance
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            /*
			[A,20.3]
			[A,40.2]
			*/
            addresToAmountFunded[funder] = 0;
            //Reset one address to zero
        }
        //new blank array index - why new blank array index,beucause its saved in memory
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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