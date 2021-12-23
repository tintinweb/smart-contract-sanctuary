// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// using contract for taking the conversion rate
import "AggregatorV3Interface.sol";


// contract name
contract PaymentsCon{

    // initializing the variable in the type of AggregatorV3Interface to assign the contract
    AggregatorV3Interface internal priceFeed;

    // here mapping with input as address and the output as uint256 to store the sender address and the value
    mapping(address => uint256) public amountMapp;

    // to store the sender address for future loop 
    address[] public fundingAddress;

    // variable to store the owners address
    address owner;

    constructor(address _priceFeed) public {
        
        // when this contract is deployed address is stored in owner
        owner = msg.sender;

        // in this we passing the AggregatorV3Interface rinkeby eth/usd address 
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function showVersion() public view returns(uint256){
        // displaying the version of the contract imported
        return priceFeed.version();
    }

    function getConvertedRate() public view returns(uint256) {
        // here taking the current price with mulptiplied by 10^ 8 and for which we dont want the variable 
        // we leaving it empty
        (,int price,,,) = priceFeed.latestRoundData();
        // multiplying by 10^10 to take wei account
        return uint256(price) * 10 ** 10;
    }

    function getAmount(uint256 _ethAmount) public view returns(uint256){
        uint256 price  = getConvertedRate();
        // calculating usd value to the given "wei" 
        return (_ethAmount * price)/ 10**18;
    }

    // while dealing with the payments the "payable should mention in the function"
    function getPayment() public payable {

        // checking the given value is equal to the 50 usd if not it will show this message
        require(getAmount(msg.value) >= (50 * 10 ** 18), "need to send more then 50 $");

        // storing the address and the value in the mapping
        amountMapp[msg.sender] = msg.value;
        // storing the address to the array
        fundingAddress.push(msg.sender);
    }

    // here the modifier which is equal to the middleware in the python /node
    modifier checkOwner {
        // checking the condition that the withdrawel taking user is owner is not
        require(msg.sender == owner, "your are not owner to take money");
        // if _; is put means the code will run after this condition
        // if it put in the top then code will run fist then it will check the condition
        _;
    }
    
    // function to withdraw eth
    function withdraw() payable checkOwner public {
        // here the sender address making payable to send the balance
        // transfer is used to send the balance
        // this refers to this contract and taking the balance from the address of this contract
        payable(msg.sender).transfer(address(this).balance);

        // after transfer we making all the value to 0 for all the address in mapping
        // taking address from the array and passing to the mapping to assign value
        for (uint256 loopVar = 0; loopVar < fundingAddress.length; loopVar++){
            amountMapp[address(fundingAddress[loopVar])] = 0;
        }
        // now emptying the array
        fundingAddress = new address[](0);
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