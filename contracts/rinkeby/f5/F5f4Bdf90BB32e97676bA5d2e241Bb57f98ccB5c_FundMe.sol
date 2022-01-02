/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    // TYPES

    struct Funder
    {
        bool isFunder;
        uint256 index;
        uint256 amountFunded;
    }

    // VARIABLES

    address public m_Owner;
    address private m_AggV3Interface_address = 0x9326BFA02ADD2366b30bacB125260Af641031331;

    address[] public m_Funders;
    mapping(address => Funder) public m_AddressToFunderData;

    // MODIFIERS

    modifier onlyOwner()
    {
        require(msg.sender == m_Owner, "Only the owner of the contract can run this function");
        _; // Resume
    }

    modifier onlyFunder()
    {
        require(this._isFunder(msg.sender), "Only funders of the contract can run this function");
        _; // Resume
    }

    // METHODS

    constructor()
    {
        m_Owner = msg.sender;
    }

    function fund() public payable
    {
        uint256 minimumUSD = 50;

        require(this._weiToUsd(msg.value) >= minimumUSD, "Try spending more $ETH !");

        // Add funder to data if first time
        if (this._isFunder(msg.sender) == false)
        {
            m_Funders.push(msg.sender);
            m_AddressToFunderData[msg.sender] = Funder({
                isFunder: true,
                index: m_Funders.length - 1,
                amountFunded: 0
            });
        }
        m_AddressToFunderData[msg.sender].amountFunded += msg.value;
    }

    function withdrawWei(uint256 _amount) public
    {
        require(m_AddressToFunderData[msg.sender].amountFunded >= _amount);
        require(address(this).balance >= _amount);

        payable(msg.sender).transfer(_amount);
        m_AddressToFunderData[msg.sender].amountFunded -= _amount;

        if (m_AddressToFunderData[msg.sender].amountFunded == 0)
        {
            delete(m_Funders[m_AddressToFunderData[msg.sender].index]);
            delete(m_AddressToFunderData[msg.sender]);
        }
    }

    function hello() public view onlyFunder returns(string memory)
    {
        return ("Hello");
    }

    function setPriceAddress(address _address) public onlyOwner
    {
        m_AggV3Interface_address = _address;
    }

    function _getVersion() public view returns(uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(m_AggV3Interface_address);
        return priceFeed.version();
    }

    // Gets price in with value * (10^8)
    function _getPrice() public view returns(uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(m_AggV3Interface_address);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function _ethToUsd(uint256 ethAmount) public view returns(uint256)
    {
        return this._weiToUsd(ethAmount * (10**18));
    }

    function _weiToUsd(uint256 weiAmount) public view returns(uint256)
    {
        uint256 ethPrice = this._getPrice(); // 10^8 too high
        uint256 usdValue = ethPrice * weiAmount / (10 ** 26); // Divide by (10^18) * (10^8) == (10^26)

        return usdValue;
    }

    function _isFunder(address _address) public view returns(bool)
    {
        return m_AddressToFunderData[_address].isFunder;
    }
}