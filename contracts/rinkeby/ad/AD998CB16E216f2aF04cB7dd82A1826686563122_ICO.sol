pragma solidity >=0.7.0 <0.9.0;

import "./DummyCoin.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

contract ICO {

    DummyCoin public token;

    uint256 public rate;

    address payable owner;

    AggregatorV3Interface internal priceFeed;

    event Received(address, uint);

    constructor(address _token, uint256 _rate, address _aggregator) {
        token = DummyCoin(_token);
        owner = payable(msg.sender);
        rate = _rate;
        priceFeed = AggregatorV3Interface(_aggregator);
    }

    receive() external payable {
        uint ethPrice = uint(getLatestPrice())*10**10;
        require(msg.value * ethPrice >= 50*10**18, "value too low");
        token.transfer(msg.sender, msg.value * rate);
        owner.transfer(msg.value);
        emit Received(msg.sender, msg.value);
    }

    function getLatestPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DummyCoin {
    uint256 public totalSupply = 21000*10**18;
    string public name = "DummyCoin";
    string public symbol = "DC";
    uint8 public decimals = 18;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf(_from) >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}