pragma solidity 0.4.21;

// File: contracts/ExchangeHandler.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Kyber.sol

interface Kyber {
    function trade(Token src, uint srcAmount, Token dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId) public payable returns (uint);
}

contract KyberHandler is ExchangeHandler {
    // State variables
    Kyber public exchange;
    Token constant public ETH_TOKEN_ADDRESS = Token(0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    // Constructor
    function KyberHandler(address _exchange) public {
        exchange = Kyber(_exchange);
    }

    // Public functions
    function getAvailableAmount(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        // return amountToGive
        return orderValues[0];
    }

    function performBuy(
        address[8] orderAddresses, // 0: tokenToGet (dest), 1: destAddress (primary), 2: walletId
        uint256[6] orderValues, // 0: srcAmount (amountToGive), 1: dstAmount (amountToGet), 2: maxDestAmount, 3: minConversionRate
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external payable returns (uint256) {
        require(msg.value == orderValues[0]);

        uint256 tokenAmountObtained = trade(
            ETH_TOKEN_ADDRESS, // ERC20 src
            orderValues[0],    // uint srcAmount
            Token(orderAddresses[0]), // ERC20 dest
            orderAddresses[1], // address destAddress (where tokens are sent to after trade)
            orderValues[2],    // uint maxDestAmount
            orderValues[3],    // uint minConversionRate
            orderAddresses[2]  // address walletId
        );

        // If Kyber has sent us back some excess ether
        if(this.balance > 0) {
            msg.sender.transfer(this.balance);
        }

        return tokenAmountObtained;
    }

    function performSell(
        address[8] orderAddresses, // 0: tokenToGive (src), 1: destAddress (primary), 2: walletId
        uint256[6] orderValues, // 0: srcAmount (amountToGive), 1: dstAmount (amountToGet), 2: maxDestAmount, 3: minConversionRate
        uint256 exchangeFee, // ignore
        uint256 amountToFill, // ignore
        uint8 v, // ignore
        bytes32 r, // ignore
        bytes32 s // ignore
    ) external returns (uint256) {

        require(Token(orderAddresses[0]).approve(address(exchange), orderValues[0]));

        uint256 etherAmountObtained = trade(
            Token(orderAddresses[0]), // ERC20 src
            orderValues[0],    // uint srcAmount
            ETH_TOKEN_ADDRESS, // ERC20 dest
            orderAddresses[1], // address destAddress (where tokens are sent to after trade)
            orderValues[2],    // uint maxDestAmount
            orderValues[3],    // uint minConversionRate
            orderAddresses[2]  // address walletId
        );

        return etherAmountObtained;
    }

    function trade(
        Token src,
        uint srcAmount,
        Token dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) internal returns (uint256) {
        uint256 valToSend = 0;
        if(src == ETH_TOKEN_ADDRESS) {
            valToSend = srcAmount;
        }

        return exchange.trade.value(valToSend)(
            src,
            srcAmount,
            dest,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId
        );
    }

    function() public payable {
        require(msg.sender == address(exchange));
    }
}