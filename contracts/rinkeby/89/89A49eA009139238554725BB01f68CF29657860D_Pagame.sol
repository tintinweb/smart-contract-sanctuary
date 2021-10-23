// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "AggregatorV3Interface.sol";

contract Pagame {
    mapping(address => uint256) public addressAsociadaMontoPagado;
    address[] public pagadores;
    address public duenioAddress;

    constructor() public {
        duenioAddress = msg.sender;
    }

    function pagar() public payable {
        uint256 minimoUsd = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimoUsd,
            "You need to spend more ETH!"
        );
        addressAsociadaMontoPagado[msg.sender] += msg.value;
        pagadores.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface precioFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return precioFeed.version();
    }

    function getPrecio() public view returns (uint256) {
        AggregatorV3Interface precioFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = precioFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethMonto) public view returns (uint256) {
        uint256 ethPrecio = getPrecio();
        uint256 ethMontoEnUsd = (ethPrecio * ethMonto) / 1000000000000000000;
        return ethMontoEnUsd;
    }

    modifier soloDuenio() {
        require(msg.sender == duenioAddress);
        _;
    }

    function retirar() public payable soloDuenio {
        for (
            uint256 pagadorIndice = 0;
            pagadorIndice < pagadores.length;
            pagadorIndice++
        ) {
            address pagador = pagadores[pagadorIndice];
            addressAsociadaMontoPagado[pagador] = 0;
        }
        pagadores = new address[](0);
        payable(msg.sender).transfer(address(this).balance);
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