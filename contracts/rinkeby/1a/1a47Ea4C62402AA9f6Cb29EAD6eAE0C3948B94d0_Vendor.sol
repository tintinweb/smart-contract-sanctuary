//deployed at https://rinkeby.etherscan.io/address/0x1Eda90C3f62eE217aF9775E3DE9B5634ecCF30F4

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
    address internal myTokenContractAddress;
    address studentsContractAddress = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
    address DAIContractAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
    AggregatorV3Interface internal priceFeed;
    address owner;
    IERC20 DAITokenContract = IERC20(DAIContractAddress);
    IERC20 myTokenContract = IERC20(myTokenContractAddress);

    uint256 public _tokenPrice;
    uint256 public _tokensAmountToBuy;

    constructor(address tokenContractAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        myTokenContractAddress = tokenContractAddress;
        DAITokenContract = IERC20(DAIContractAddress);
        myTokenContract = IERC20(myTokenContractAddress);
    }

    function buyTokens() public payable {
        uint256  studentsAmount = getStudentsAmount();
        int  latestPrice = getLatestPrice()/100000000;
        uint256 tokenPrice = uint256(latestPrice) / studentsAmount;
        _tokenPrice = tokenPrice;
        uint256  amountOfTokensToBuy = msg.value/tokenPrice;
        _tokensAmountToBuy = amountOfTokensToBuy;

        if(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy){
            (bool sent,) = msg.sender.call{value:msg.value}("Sorry, there is not enough tokens");
            return;
        }

        myTokenContract.transfer(msg.sender, amountOfTokensToBuy);
    }

    function buyTokensForDAI(uint256 amount) public {
        require(amount > 0, "Maybe you would like to buy something greater than 0?");
        uint256  amountOfTokensToBuy = amount;
        require(myTokenContract.balanceOf(address(this)) < amountOfTokensToBuy, "Sorry, there is not enough tokens on my balance");
        require(DAITokenContract.balanceOf(msg.sender) < amountOfTokensToBuy, "Sorry, you do not have enough DAI-tokens for swap");

        uint256 allowance = DAITokenContract.allowance(msg.sender, address(this));
        require(allowance >= amountOfTokensToBuy, "Check the token allowance");

        DAITokenContract.transferFrom(msg.sender, address(this), amount);
        myTokenContract.transfer(msg.sender, amountOfTokensToBuy);

        return;
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
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