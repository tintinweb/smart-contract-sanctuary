// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

import "./interfaces/StchTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenSwap {

	AggregatorV3Interface internal priceFeed;
	StchTokenInterface internal token;
	uint rate = 1 * 10**18; //$1/token converted to wei

	event TokenPurchased(address receiver, uint amount, uint tokenPriceInEth);
	event TokenSold(address sender, uint tokenAmount, uint etherAmount);

	mapping (address => uint) public tokenHolders;

	constructor(address _tokenAddress, address _priceFeedAddress) {
		require(_tokenAddress != address(0x0), "Token address cannot be a null-address");
		priceFeed = AggregatorV3Interface(_priceFeedAddress);
		token = StchTokenInterface(_tokenAddress);
	}

	function currentEthPrice() private view returns (uint) {
    	(,int256 answer, , ,) = priceFeed.latestRoundData();
    	uint ethPrice = uint(answer);
    	return ethPrice / 10**8; //4590.56636667
    }

    function tokenPriceInEth() public view returns (uint) {
    	return rate / currentEthPrice(); //217838044399170.86
    }

    function buyToken() public payable {
    	uint tokenPrice = tokenPriceInEth();
    	require(msg.value >= tokenPrice, "You need enough Eth for at least 1 token");
    	uint tokenAmount = (msg.value / tokenPrice) * 10**18; //413xxxx
    	require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in the exchange");
    	tokenHolders[msg.sender] += tokenAmount;
    	token.transfer(msg.sender, tokenAmount);
    	emit TokenPurchased(msg.sender, tokenAmount, tokenPrice);
    }

    function sellToken(uint amount) public {
    	address payable seller = payable(msg.sender);
    	require(token.balanceOf(msg.sender) >= amount, "Not enough tokens");
    	require(tokenHolders[msg.sender] > 0, "Only token holders can sell back to the exchange");
    	//sell back at a 10% premium
    	uint sellRate = (((amount * tokenPriceInEth()) / 10**18) * 90) / 100;
    	require(address(this).balance >= sellRate, "Not enough ether in the exchange");
    	tokenHolders[msg.sender] -= amount;
    	token.transferFrom(msg.sender, address(this), amount); //get the tokens being sold back
    	seller.transfer(sellRate);//send the ether equivalent
    	emit TokenSold(msg.sender, amount, sellRate);
    }
}

// SPDX-License-Identifier: NO LICENSE
pragma solidity ^0.8.0;

interface StchTokenInterface {
	function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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