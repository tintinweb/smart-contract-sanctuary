/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

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

// File: Distribution.sol

pragma solidity ^0.6.7;



library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



interface IERC20 {
    
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
}

library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

}

contract DistributionContract {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public token;
    AggregatorV3Interface internal priceFeed;
    address public owner;
    IERC20 public IUSDT;
    uint256 public tokenSold;
    
    event PriceUpdate(uint256 updatedPrice, uint256 previousPrice);
    

    uint256 public tokenPrice = 1*10**18; // price in usd
    
    constructor(address _token) public {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        owner =msg.sender;
        token = IERC20(address(_token));
        IUSDT = IERC20(0xF1Ae021614989a5d4D9A7b83D80B41b94868C072);
    }



    function changeTokenPrice(uint256 updatedPrice) public {
        require(msg.sender == owner,"UnAuthorized");
        emit PriceUpdate(updatedPrice,tokenPrice);
        tokenPrice = updatedPrice;
        
    }






    function buyTokens()public payable{
        uint256 noOfTokens = ethereumToTokens(msg.value);
        safeTokenTransfer(noOfTokens,msg.sender);
    }
    
    
    
    function safeTokenTransfer(uint256 amount,address user) internal{
        require(getTokenBalance()>=amount,"Insufficient Token Balance");
        token.transfer(user,amount);
        tokenSold= tokenSold.add(amount);
    }
    
    
    
    function getUSDBalance() public view returns(uint256){
        return IUSDT.balanceOf(address(this));
    }
    
    
    
    function getTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }
    
    
    
    
    function getETHBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    
    
    
    function withdrawUSDT() public {
        require(msg.sender== owner,"Not Autorized");
        IUSDT.transfer(owner,getUSDBalance());
    }
    
    
    
    
     function withdrawTokens() public {
        require(msg.sender== owner,"Not Autorized");
        token.transfer(owner,getTokenBalance());
    }
    
    
     
     function withdrawEth() public {
        require(msg.sender== owner,"Not Autorized");
        payable(owner).transfer(getETHBalance());
    }
    
    


   function ethereumToTokens(uint256 ethAmount) public view returns( uint256){
        uint256 _ethInUsd =ethToUsd().mul(ethAmount);
        
        uint256 numberOfTokens =_ethInUsd.div(tokenPrice);
        numberOfTokens = numberOfTokens.div(1e18);

        return numberOfTokens.mul(1e18);
        
    }
    

  
   
    function ethToUsd() public view returns (uint256) {
        (, int price,,,) = priceFeed.latestRoundData();
        return uint256(price).mul(1**10);
    }
    
    
}