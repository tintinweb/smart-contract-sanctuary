pragma solidity 0.4.24;

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

// File: contracts/TokenTransferProxy.sol

/*
    Notice - This code is copyright 2017 ZeroEx Intl and licensed
    under the Apache License, Version 2.0;
*/

contract TokenTransferProxy is Ownable {

    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);

    /*
     * Public functions
     */

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        public
        onlyOwner
        targetNotAuthorized(target)
    {
        authorized[target] = true;
        authorities.push(target);
        emit LogAuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        public
        onlyOwner
        targetAuthorized(target)
    {
        delete authorized[target];
        for (uint i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit LogAuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Calls into ERC20 Token contract, invoking transferFrom.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    /// @return Success of transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyAuthorized
        returns (bool)
    {
        return Token(token).transferFrom(from, to, value);
    }

    /*
     * Public constant functions
     */

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        public
        constant
        returns (address[])
    {
        return authorities;
    }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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

/// @title The primary contract for Totle Inc
contract TotlePrimary is Ownable {
    // Constants
    uint256 public constant MAX_EXCHANGE_FEE_PERCENTAGE = 0.01 * 10**18; // 1%
    bool constant BUY = false;
    bool constant SELL = true;

    // State variables
    mapping(address => bool) public handlerWhitelist;
    address tokenTransferProxy;

    // Structs
    struct Tokens {
        address[] tokenAddresses;
        bool[]    buyOrSell;
        uint256[] amountToObtain;
        uint256[] amountToGive;
    }

    struct DEXOrders {
        address[] tokenForOrder;
        address[] exchanges;
        address[8][] orderAddresses;
        uint256[6][] orderValues;
        uint256[] exchangeFees;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

    /// @dev Constructor
    /// @param proxy Address of the TokenTransferProxy
    constructor(address proxy) public {
        tokenTransferProxy = proxy;
    }

    /*
    *   Public functions
    */

    /// @dev Set an exchange handler address to true/false
    /// @notice - onlyOwner modifier only allows the contract owner to run the code
    /// @param handler Address of the exchange handler which permission needs changing
    /// @param allowed Boolean value to set whether an exchange handler is allowed/denied
    function setHandler(address handler, bool allowed) public onlyOwner {
        handlerWhitelist[handler] = allowed;
    }

    /// @dev Synchronously executes an array of orders
    /// @notice The first four parameters relate to Token orders, the last eight relate to DEX orders
    /// @param tokenAddresses Array of addresses of ERC20 Token contracts for each Token order
    /// @param buyOrSell Array indicating whether each Token order is a buy or sell
    /// @param amountToObtain Array indicating the amount (in ether or tokens) to obtain in the order
    /// @param amountToGive Array indicating the amount (in ether or tokens) to give in the order
    /// @param tokenForOrder Array of addresses of ERC20 Token contracts for each DEX order
    /// @param exchanges Array of addresses of exchange handler contracts
    /// @param orderAddresses Array of address values needed for each DEX order
    /// @param orderValues Array of uint values needed for each DEX order
    /// @param exchangeFees Array indicating the fee for each DEX order (percentage of fill amount as decimal * 10**18)
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    function executeOrders(
        // Tokens
        address[] tokenAddresses,
        bool[]    buyOrSell,
        uint256[] amountToObtain,
        uint256[] amountToGive,
        // DEX Orders
        address[] tokenForOrder,
        address[] exchanges,
        address[8][] orderAddresses,
        uint256[6][] orderValues,
        uint256[] exchangeFees,
        uint8[] v,
        bytes32[] r,
        bytes32[] s,
        // Unique ID
        uint256 uniqueID
    ) public payable {

        require(
            tokenAddresses.length == buyOrSell.length &&
            buyOrSell.length      == amountToObtain.length &&
            amountToObtain.length == amountToGive.length,
            "TotlePrimary - trade length check failed"
        );

        require(
            tokenForOrder.length  == exchanges.length &&
            exchanges.length      == orderAddresses.length &&
            orderAddresses.length == orderValues.length &&
            orderValues.length    == exchangeFees.length &&
            exchangeFees.length   == v.length &&
            v.length              == r.length &&
            r.length              == s.length,
            "TotlePrimary - order length check failed"
        );

        // Wrapping order in structs to reduce local variable count
        internalOrderExecution(
            Tokens(
                tokenAddresses,
                buyOrSell,
                amountToObtain,
                amountToGive
            ),
            DEXOrders(
                tokenForOrder,
                exchanges,
                orderAddresses,
                orderValues,
                exchangeFees,
                v,
                r,
                s
            )
        );
    }

    /*
    *   Internal functions
    */

    /// @dev Synchronously executes an array of orders
    /// @notice The orders in this function have been wrapped in structs to reduce the local variable count
    /// @param tokens Struct containing the arrays of token orders
    /// @param orders Struct containing the arrays of DEX orders
    function internalOrderExecution(Tokens tokens, DEXOrders orders) internal {
        transferTokens(tokens);

        uint256 tokensLength = tokens.tokenAddresses.length;
        uint256 ordersLength = orders.tokenForOrder.length;
        uint256 etherBalance = msg.value;
        uint256 orderIndex = 0;

        for(uint256 tokenIndex = 0; tokenIndex < tokensLength; tokenIndex++) {
            // NOTE - check for repetitions in the token list?

            uint256 amountRemaining = tokens.amountToGive[tokenIndex];
            uint256 amountObtained = 0;

            while(orderIndex < ordersLength) {
                require(
                    tokens.tokenAddresses[tokenIndex] == orders.tokenForOrder[orderIndex],
                    "TotlePrimary - tokenAddress != tokenForOrder"
                );
                require(
                    handlerWhitelist[orders.exchanges[orderIndex]],
                    "TotlePrimary - handler not in whitelist"
                );

                if(amountRemaining > 0) {
                    if(tokens.buyOrSell[tokenIndex] == BUY) {
                        require(
                            etherBalance >= amountRemaining,
                            "TotlePrimary - not enough ether left to fill next order"
                        );
                    }
                    (amountRemaining, amountObtained) = performTrade(
                        tokens.buyOrSell[tokenIndex],
                        amountRemaining,
                        amountObtained,
                        orders, // NOTE - unable to send pointer to order values individually, as run out of stack space!
                        orderIndex
                        );
                }

                orderIndex = SafeMath.add(orderIndex, 1);
                // If this is the last order for this token
                if(orderIndex == ordersLength || orders.tokenForOrder[SafeMath.sub(orderIndex, 1)] != orders.tokenForOrder[orderIndex]) {
                    break;
                }
            }

            uint256 amountGiven = SafeMath.sub(tokens.amountToGive[tokenIndex], amountRemaining);

            require(
                orderWasValid(amountObtained, amountGiven, tokens.amountToObtain[tokenIndex], tokens.amountToGive[tokenIndex]),
                "TotlePrimary - amount obtained for was not high enough"
            );

            if(tokens.buyOrSell[tokenIndex] == BUY) {
                // Take away spent ether from refund balance
                etherBalance = SafeMath.sub(etherBalance, amountGiven);
                // Transfer back tokens acquired
                if(amountObtained > 0) {
                    require(
                        Token(tokens.tokenAddresses[tokenIndex]).transfer(msg.sender, amountObtained),
                        "TotlePrimary - failed to transfer tokens bought to msg.sender"
                    );
                }
            } else {
                // Add ether to refund balance
                etherBalance = SafeMath.add(etherBalance, amountObtained);
                // Transfer back un-sold tokens
                if(amountRemaining > 0) {
                    require(
                        Token(tokens.tokenAddresses[tokenIndex]).transfer(msg.sender, amountRemaining),
                        "TotlePrimary - failed to transfer remaining tokens to msg.sender after sell"
                    );
                }
            }
        }

        // Send back acquired/unspent ether - throw on failure
        if(etherBalance > 0) {
            msg.sender.transfer(etherBalance);
        }
    }

    /// @dev Iterates through a list of token orders, transfer the SELL orders to this contract & calculates if we have the ether needed
    /// @param tokens Struct containing the arrays of token orders
    function transferTokens(Tokens tokens) internal {
        uint256 expectedEtherAvailable = msg.value;
        uint256 totalEtherNeeded = 0;

        for(uint256 i = 0; i < tokens.tokenAddresses.length; i++) {
            if(tokens.buyOrSell[i] == BUY) {
                totalEtherNeeded = SafeMath.add(totalEtherNeeded, tokens.amountToGive[i]);
            } else {
                expectedEtherAvailable = SafeMath.add(expectedEtherAvailable, tokens.amountToObtain[i]);
                require(
                    TokenTransferProxy(tokenTransferProxy).transferFrom(
                        tokens.tokenAddresses[i],
                        msg.sender,
                        this,
                        tokens.amountToGive[i]
                    ),
                    "TotlePrimary - proxy failed to transfer tokens from user"
                );
            }
        }

        // Make sure we have will have enough ETH after SELLs to cover our BUYs
        require(
            expectedEtherAvailable >= totalEtherNeeded,
            "TotlePrimary - not enough ether available to fill all orders"
        );
    }

    /// @dev Performs a single trade via the requested exchange handler
    /// @param buyOrSell Boolean value stating whether this is a buy or sell order
    /// @param initialRemaining The remaining value we have left to trade
    /// @param totalObtained The total amount we have obtained so far
    /// @param orders Struct containing all DEX orders
    /// @param index Value indicating the index of the specific DEX order we wish to execute
    /// @return Remaining value left after trade
    /// @return Total value obtained after trade
    function performTrade(bool buyOrSell, uint256 initialRemaining, uint256 totalObtained, DEXOrders orders, uint256 index)
        internal returns (uint256, uint256) {
        uint256 obtained = 0;
        uint256 remaining = initialRemaining;

        require(
            orders.exchangeFees[index] < MAX_EXCHANGE_FEE_PERCENTAGE,
            "TotlePrimary - exchange fee was above maximum"
        );

        uint256 amountToFill = getAmountToFill(remaining, orders, index);

        if(amountToFill > 0) {
            remaining = SafeMath.sub(remaining, amountToFill);

            if(buyOrSell == BUY) {
                obtained = ExchangeHandler(orders.exchanges[index]).performBuy.value(amountToFill)(
                    orders.orderAddresses[index],
                    orders.orderValues[index],
                    orders.exchangeFees[index],
                    amountToFill,
                    orders.v[index],
                    orders.r[index],
                    orders.s[index]
                );
            } else {
                require(
                    Token(orders.tokenForOrder[index]).transfer(
                        orders.exchanges[index],
                        amountToFill
                    ),
                    "TotlePrimary - token transfer to handler failed for sell"
                );
                obtained = ExchangeHandler(orders.exchanges[index]).performSell(
                    orders.orderAddresses[index],
                    orders.orderValues[index],
                    orders.exchangeFees[index],
                    amountToFill,
                    orders.v[index],
                    orders.r[index],
                    orders.s[index]
                );
            }
        }

        return (obtained == 0 ? initialRemaining: remaining, SafeMath.add(totalObtained, obtained));
    }

    /// @dev Get the amount of this order we are able to fill
    /// @param remaining Amount we have left to spend
    /// @param orders Struct containing all DEX orders
    /// @param index Value indicating the index of the specific DEX order we wish to execute
    /// @return Minimum of the amount we have left to spend and the available amount at the exchange
    function getAmountToFill(uint256 remaining, DEXOrders orders, uint256 index) internal returns (uint256) {

        uint256 availableAmount = ExchangeHandler(orders.exchanges[index]).getAvailableAmount(
            orders.orderAddresses[index],
            orders.orderValues[index],
            orders.exchangeFees[index],
            orders.v[index],
            orders.r[index],
            orders.s[index]
        );

        return Math.min256(remaining, availableAmount);
    }

    /// @dev Checks whether a given order was valid
    /// @param amountObtained Amount of the order which was obtained
    /// @param amountGiven Amount given in return for amountObtained
    /// @param amountToObtain Amount we intended to obtain
    /// @param amountToGive Amount we intended to give in return for amountToObtain
    /// @return Boolean value indicating whether this order was valid
    function orderWasValid(uint256 amountObtained, uint256 amountGiven, uint256 amountToObtain, uint256 amountToGive) internal pure returns (bool) {

        if(amountObtained > 0 && amountGiven > 0) {
            // NOTE - Check the edge cases here
            if(amountObtained > amountGiven) {
                return SafeMath.div(amountToObtain, amountToGive) <= SafeMath.div(amountObtained, amountGiven);
            } else {
                return SafeMath.div(amountToGive, amountToObtain) >= SafeMath.div(amountGiven, amountObtained);
            }
        }
        return false;
    }

    function() public payable {
        // Check in here that the sender is a contract! (to stop accidents)
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        require(size > 0, "TotlePrimary - can only send ether from another contract");
    }
}