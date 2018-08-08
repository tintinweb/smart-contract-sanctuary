pragma solidity ^0.4.24;

// import { ERC20 as Token } from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import { ExchangeHandler } from "./ExchangeHandler.sol";

// pragma solidity ^0.4.24;

contract Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/// @title Interface for all exchange handler contracts
interface ExchangeHandler {

    /// @dev Get the available amount left to fill for an order
    /// @param orderAddresses Array of address values needed for this DEX order
    /// @param orderValues Array of uint values needed for this DEX order
    /// @param exchangeFee Value indicating the fee for this DEX order
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    /// @return Available amount left to fill for this order
    function getAvailableAmount(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    /// @dev Perform a buy order at the exchange
    /// @param orderAddresses Array of address values needed for each DEX order
    /// @param orderValues Array of uint values needed for each DEX order
    /// @param exchangeFee Value indicating the fee for this DEX order
    /// @param amountToFill Amount to fill in this order
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    /// @return Amount filled in this order
    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256);

    /// @dev Perform a sell order at the exchange
    /// @param orderAddresses Array of address values needed for each DEX order
    /// @param orderValues Array of uint values needed for each DEX order
    /// @param exchangeFee Value indicating the fee for this DEX order
    /// @param amountToFill Amount to fill in this order
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    /// @return Amount filled in this order
    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);
}


interface BancorConverter {
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
}

contract BancorHandler is ExchangeHandler {

    // Public functions
    function getAvailableAmount(
        address[8] orderAddresses, // [converterAddress, conversionPath ... ]
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external returns (uint256) {
        // Return amountToGive
        return orderValues[0];
    }

    function performBuy(
        address[8] orderAddresses, // [converterAddress, conversionPath ... ]
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external payable returns (uint256 amountObtained) {
        address destinationToken;
        (amountObtained, destinationToken) = trade(orderAddresses, orderValues);
        transferTokenToSender(destinationToken, amountObtained);
    }

    function performSell(
        address[8] orderAddresses, // [converterAddress, conversionPath ... ]
        uint256[6] orderValues, // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external returns (uint256 amountObtained) {
        approveExchange(orderAddresses[0], orderAddresses[1], orderValues[0]);
        (amountObtained, ) = trade(orderAddresses, orderValues);
        transferEtherToSender(amountObtained);
    }

    function trade(
        address[8] orderAddresses, // [converterAddress, conversionPath ... ]
        uint256[6] orderValues // [amountToGive, minReturn, EMPTY, EMPTY, EMPTY, EMPTY]
    ) internal returns (uint256 amountObtained, address destinationToken) {
        // Find the length of the conversion path
        uint256 len;
        for(len = 1; len < orderAddresses.length; len++) {
            if(orderAddresses[len] == 0) {
                require(len > 1, "First element in conversion path was 0");
                destinationToken = orderAddresses[len - 1];
                len--;
                break;
            } else if(len == orderAddresses.length - 1) {
                destinationToken = orderAddresses[len];
                break;
            }
        }
        // Create an array of that length
        address[] memory conversionPath = new address[](len);

        // Move the contents from orderAddresses to conversionPath
        for(uint256 i = 0; i < len; i++) {
            conversionPath[i] = orderAddresses[i + 1];
        }

        amountObtained = BancorConverter(orderAddresses[0])
                            .quickConvert.value(msg.value)(conversionPath, orderValues[0], orderValues[1]);
    }

    function transferTokenToSender(address token, uint256 amount) internal {
        Token(token).transfer(msg.sender, amount);
    }

    function transferEtherToSender(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function approveExchange(address exchange, address token, uint256 amount) internal {
        Token(token).approve(exchange, amount);
    }

    function() public payable {
    }
}