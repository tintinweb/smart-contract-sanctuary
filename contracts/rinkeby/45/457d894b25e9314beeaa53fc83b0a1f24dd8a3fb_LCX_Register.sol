/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.4.24;

library SafeMath {
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: modulo by zero');
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol

// SPDX-License-Identifier: MIT

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

contract LCX_Register {
    using Counters for Counters.Counter;

    /******************
    EVENTS
    ******************/
    event ProducerRegistered(uint256 producerId, address indexed wallet, address indexed token);
    event TransporterRegistered(uint256 transporterId, address indexed wallet, address indexed token);
    event HumanRegistered(uint256 humanId, address indexed wallet, address indexed token);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    Counters.Counter private producerId;
    Counters.Counter private transporterId;
    Counters.Counter private humanId;

    mapping(uint256 => Producer) public producers;
    mapping(uint256 => Transporter) public transporters;
    mapping(uint256 => Human) public humans;

    struct Producer {
        address token;
        string name;
        string place;
        string description;
        string productData;
        string logisticDetails;
    }

    struct Transporter {
        address token;
        uint256 pricePerKm;
        string name;
        string place;
        string description;
        string logisticCapability;
    }

    struct Human {
        address token;
        uint256 issueAmount;
        string name;
        string place;
        string description;
        string rawProduct;
        string logisticDetails;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    function registerProducer(
        address _token,
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _productData,
        string memory _logisticDetails
    ) public nonBurnAddress(_token) returns (uint256) {
        uint256 producerIndex = producerId.current();
        producerId.increment();

        producers[producerIndex] = Producer({
            token: _token,
            name: _name,
            place: _place,
            description: _description,
            productData: _productData,
            logisticDetails: _logisticDetails
        });

        emit ProducerRegistered(producerIndex, msg.sender, _token);

        return producerIndex;
    }

    function registerTransporter(
        address _token,
        uint256 _pricePerKm,
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _logisticCapability
    ) public nonBurnAddress(_token) returns (uint256) {
        uint256 transporterIndex = transporterId.current();
        transporterId.increment();

        transporters[transporterIndex] = Transporter({
            token: _token,
            pricePerKm: _pricePerKm,
            name: _name,
            place: _place,
            description: _description,
            logisticCapability: _logisticCapability
        });

        emit TransporterRegistered(transporterIndex, msg.sender, _token);

        return transporterIndex;
    }

    function registerHuman(
        address _token,
        uint256 _issueAmount,
        string memory _name,
        string memory _place,
        string memory _description,
        string memory _rawProduct,
        string memory _logisticDetails
    ) public nonBurnAddress(_token) returns (uint256) {
        uint256 humanIndex = humanId.current();
        humanId.increment();

        humans[humanIndex] = Human({
            token: _token,
            issueAmount: _issueAmount,
            name: _name,
            place: _place,
            description: _description,
            rawProduct: _rawProduct,
            logisticDetails: _logisticDetails
        });

        emit HumanRegistered(humanIndex, msg.sender, _token);

        return humanIndex;
    }

    /******************
    MODIFIERS
    *******************/
    modifier nonBurnAddress(address _token) {
        require(_token != address(0), 'LCX_Register: Zero address not allowed');
        _;
    }
}