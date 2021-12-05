// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface studentsInterface {
    function getStudentsList() external view returns (string[] memory studentsList);
}


contract Vendor {
    address studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
    address aggregatorAddressFor_ETH_USD = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address aggregatorAddressFor_DAI_USD = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF;
    address owner;
    IERC20 DAITokenContract;
    IERC20 myTokenContract;

    constructor(address tokenContractAddress, address DAITokenContractAddress) {
        owner = msg.sender;
        DAITokenContract = IERC20(DAITokenContractAddress);
        myTokenContract = IERC20(tokenContractAddress);
    }

    function buyTokens() public payable {
        uint256  studentsAmount = getStudentsAmount();
        int  latestPrice = getLatestPrice(aggregatorAddressFor_ETH_USD)/100000000;
        uint256 tokenPrice = uint256(latestPrice) / studentsAmount;
        uint256  amountOfTokensToBuy = msg.value/tokenPrice;

        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool sent,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            return;
        }

        myTokenContract.transfer(msg.sender, amountOfTokensToBuy);
    }

    function buyTokensForDAI(uint256 amountToBuy) public {
        require(amountToBuy > 0, "Maybe you would like to buy something greater than 0?");
        int  latestPrice = getLatestPrice(aggregatorAddressFor_DAI_USD)/100000000;
        uint256  amountOfDAITokensToPay = amountToBuy/uint256(latestPrice);

        require(DAITokenContract.balanceOf(msg.sender) >= amountOfDAITokensToPay, "Sorry, you do not have enough DAI-tokens for swap");
        require(myTokenContract.balanceOf(address(this)) >= amountToBuy, "Sorry, there is not enough tokens on my balance");

        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        require(allowance >= amountToBuy, "Check the token allowance please");

        DAITokenContract.transferFrom(msg.sender, address(this), amountToBuy);
        myTokenContract.transfer(msg.sender, amountToBuy);

        return;
    }

    function getLatestPrice(address aggregatorAddress) internal returns (int256) {
        (,int price,,,) = AggregatorV3Interface(aggregatorAddress).latestRoundData();
        return int256(price);
    }

    function getStudentsAmount() internal view returns(uint256) {
        string[] memory studentsList = studentsInterface(studentsContractAddress).getStudentsList();
        return studentsList.length;
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