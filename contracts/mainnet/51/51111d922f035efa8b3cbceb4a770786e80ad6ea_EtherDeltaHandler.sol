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

// File: contracts/EtherDelta.sol

interface EtherDelta {

    function deposit() public payable;

    function withdraw(uint amount) public;

    function depositToken(address token, uint amount) public;

    function withdrawToken(address token, uint amount) public;

    function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) public;

    function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
}

contract EtherDeltaHandler is ExchangeHandler {
    // State variables
    EtherDelta public exchange;

    // Constructor
    function EtherDeltaHandler(address _exchange) public {
        exchange = EtherDelta(_exchange);
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

        if(block.number > orderValues[2]) {
            // Order has expired
            return 0;
        }

        uint256 availableVolume = exchange.availableVolume(
            orderAddresses[2],
            orderValues[1],
            orderAddresses[1],
            orderValues[0],
            orderValues[2],
            orderValues[3],
            orderAddresses[0],
            v,
            r,
            s
        );

        // Adds the exchange fee onto the available amount
        return getPartialAmount(availableVolume, SafeMath.sub(1 ether, exchangeFee), 1 ether);
    }

    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (uint256) {
        require(msg.value == amountToFill);

        deposit(amountToFill);

        uint256 amountToTrade;
        uint256 fee;

        (amountToTrade, fee) = substractFee(exchangeFee, amountToFill);

        trade(
            orderAddresses,
            orderValues,
            amountToTrade,
            v,
            r,
            s
        );

        uint256 tokenAmountObtained = getPartialAmount(orderValues[0], orderValues[1], amountToTrade);

        withdrawToken(orderAddresses[1], tokenAmountObtained);
        transferTokenToSender(orderAddresses[1], tokenAmountObtained);

        return tokenAmountObtained;
    }

    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 exchangeFee,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        depositToken(orderAddresses[2], amountToFill);

        uint256 amountToTrade;
        uint256 fee;

        (amountToTrade, fee) = substractFee(exchangeFee, amountToFill);

        trade(
            orderAddresses,
            orderValues,
            amountToTrade,
            v,
            r,
            s
        );

        uint256 etherAmountObtained = getPartialAmount(orderValues[0], orderValues[1], amountToTrade);

        withdraw(etherAmountObtained);
        transferEtherToSender(etherAmountObtained);

        return etherAmountObtained;
    }

    // Internal functions
    function trade(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256 amountToTrade,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        exchange.trade(
            orderAddresses[2],
            orderValues[1],
            orderAddresses[1],
            orderValues[0],
            orderValues[2],
            orderValues[3],
            orderAddresses[0],
            v,
            r,
            s,
            amountToTrade
        );
    }

    function substractFee(uint256 feePercentage, uint256 amount) internal pure returns (uint256, uint256) {
        uint256 fee = getPartialAmount(amount, 1 ether, feePercentage);
        return (SafeMath.sub(amount, fee), fee);
    }

    function deposit(uint256 amount) internal {
        exchange.deposit.value(amount)();
    }

    function depositToken(address token, uint256 amount) internal {
        require(Token(token).approve(address(exchange), amount));
        exchange.depositToken(token, amount);
    }

    function withdraw(uint256 amount) internal {
        exchange.withdraw(amount);
    }

    function withdrawToken(address token, uint256 amount) internal {
        exchange.withdrawToken(token, amount);
    }

    function transferTokenToSender(address token, uint256 amount) internal {
        require(Token(token).transfer(msg.sender, amount));
    }

    function transferEtherToSender(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target) internal pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }

    function() public payable {
        require(msg.sender == address(exchange));
    }
}