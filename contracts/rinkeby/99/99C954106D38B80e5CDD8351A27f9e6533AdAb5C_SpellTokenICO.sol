// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface GetStudents {
    function getStudentsList() external view returns (string[] memory students);
}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

contract SpellTokenICO {

    AggregatorV3Interface internal priceFeedETHUSD;
    AggregatorV3Interface internal priceFeedDAIUSD;
    address public owner;
    address private studentContractAddress;
    address private tokenAddress;
    address private daiTokenAddress;
    address private nftSSUTokenAddress;

    constructor(address _tokenAddress, address _daiTokenAddress, address _studentContractAddress, address _chainLinkETHUSDRinkeby, address _chainLinkDAIUSDRinkeby, address _nftSSUTokenAddress) {
        owner = msg.sender;
        priceFeedETHUSD = AggregatorV3Interface(_chainLinkETHUSDRinkeby);
        priceFeedDAIUSD = AggregatorV3Interface(_chainLinkDAIUSDRinkeby);
        studentContractAddress = _studentContractAddress;
        tokenAddress = _tokenAddress;
        daiTokenAddress = _daiTokenAddress;
        nftSSUTokenAddress = _nftSSUTokenAddress;
    }

    receive() external payable {
        buyForETH();
    }

    fallback() external payable {
        buyForETH();
    }

    function buyForETH() public payable {
        require(ERC721(nftSSUTokenAddress).balanceOf(msg.sender) > 0, "You need special NFT on you balance to get tokens");
        require(msg.value > 0, "Send ETH to buy some tokens");
        
        ( , int priceETHUSD, , , ) = priceFeedETHUSD.latestRoundData();
        uint studentsCount = GetStudents(studentContractAddress).getStudentsList().length;
        uint tokenAmount =  msg.value * uint(priceETHUSD) / studentsCount / (10 ** priceFeedETHUSD.decimals());

        try ERC20(tokenAddress).transfer(msg.sender, tokenAmount) {
        } catch Error(string memory) {
            (bool success, ) = msg.sender.call{ value: msg.value }("Sorry, there is not enough tokens to buy");
            require(success, "External call failed");
        } catch (bytes memory reason) {
            (bool success, ) = msg.sender.call{ value: msg.value }(reason);
            require(success, "External call failed");
        }
    }

    function buyForDAI(uint daiAmount) public {
        require(daiAmount > 0, "Non-zero DAI amount is required");
        require(ERC20(daiTokenAddress).allowance(msg.sender, address(this)) >= daiAmount, "Spending DAI is not allowed");
        require(ERC721(nftSSUTokenAddress).balanceOf(msg.sender) > 0, "You need special NFT on you balance to get tokens");

        ( , int priceDAIUSD, , , ) = priceFeedDAIUSD.latestRoundData();
        uint tokenAmount = daiAmount * uint(priceDAIUSD) / (10 ** priceFeedDAIUSD.decimals());

        ERC20(daiTokenAddress).transferFrom(msg.sender, address(this), daiAmount);
        ERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    function returnDAI() public {
        require(msg.sender == owner, "Only owner can return DAI");
        ERC20(daiTokenAddress).transfer(msg.sender, ERC20(daiTokenAddress).balanceOf(address(this)));
    }

    function returnETH() public {
        require(msg.sender == owner, "Only owner can return ETH");
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
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