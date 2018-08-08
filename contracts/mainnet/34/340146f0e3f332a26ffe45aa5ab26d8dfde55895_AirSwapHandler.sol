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

// File: contracts/WETH9.sol

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
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
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/AirSwapHandler.sol

/**
 * @title AirSwap interface.
 */
interface AirSwapInterface {
    /// @dev Mapping of order hash to bool (true = already filled).
    function fills(
        bytes32 hash
    ) external view returns (bool);

    /// @dev Fills an order by transferring tokens between (maker or escrow) and taker.
    /// Maker is given tokenA to taker.
    function fill(
        address makerAddress,
        uint makerAmount,
        address makerToken,
        address takerAddress,
        uint takerAmount,
        address takerToken,
        uint256 expiration,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

/**
 * @title AirSwap wrapper contract.
 * @dev Assumes makers and takers have approved this contract to access their balances.
 */
contract AirSwapHandler is ExchangeHandler, Ownable {
    /// @dev AirSwap exhange address
    AirSwapInterface public airSwap;
    WETH9 public weth;
    address public totle;
    uint256 constant MAX_UINT = 2**256 - 1;

    modifier onlyTotle() {
        require(msg.sender == totle, "AirSwapHandler - Only TotlePrimary allowed to call this function");
        _;
    }

    /// @dev Constructor
    constructor(
        address _airSwap,
        address _wethAddress,
        address _totle
    ) public {
        require(_airSwap != address(0x0));
        require(_wethAddress != address(0x0));
        require(_totle != address(0x0));

        airSwap = AirSwapInterface(_airSwap);
        weth = WETH9(_wethAddress);
        totle = _totle;
    }

    /// @dev Get the available amount left to fill for an order
    /// @param orderValues Array of uint values needed for this DEX order
    /// @return Available amount left to fill for this order
    function getAvailableAmount(
        address[8],
        uint256[6] orderValues,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external returns (uint256) {
        return orderValues[1];
    }

    /// @dev Perform a buy order at the exchange
    /// @param orderAddresses Array of address values needed for each DEX order
    /// @param orderValues Array of uint values needed for each DEX order
    /// @param amountToFill Amount to fill in this order
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    /// @return Amount filled in this order
    function performBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    onlyTotle
    payable
    returns (uint256) {
        return fillBuy(orderAddresses, orderValues, v, r, s);
    }

    /// @dev Perform a sell order at the exchange
    /// @param orderAddresses Array of address values needed for each DEX order
    /// @param orderValues Array of uint values needed for each DEX order
    /// @param amountToFill Amount to fill in this order
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameter r
    /// @param s ECDSA signature parameter s
    /// @return Amount filled in this order
    function performSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint256,
        uint256 amountToFill,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    onlyTotle
    returns (uint256) {
        return fillSell(orderAddresses, orderValues, v, r, s);
    }

    function setTotle(address _totle)
    external
    onlyOwner {
        require(_totle != address(0), "Invalid address for totlePrimary");
        totle = _totle;
    }

    /// @dev The contract is not designed to hold and/or manage tokens.
    /// Withdraws token in the case of emergency. Only an owner is allowed to call this.
    function withdrawToken(address _token, uint _amount)
    external
    onlyOwner
    returns (bool) {
        return ERC20(_token).transfer(owner, _amount);
    }

    /// @dev The contract is not designed to hold ETH.
    /// Withdraws ETH in the case of emergency. Only an owner is allowed to call this.
    function withdrawETH(uint _amount)
    external
    onlyOwner
    returns (bool) {
        owner.transfer(_amount);
    }

    function approveToken(address _token, uint amount) external onlyOwner {
        require(ERC20(_token).approve(address(airSwap), amount), "Approve failed");
    }

    function() public payable {
    }

    /** Validates order arguments for fill() and cancel() functions. */
    function validateOrder(
        address makerAddress,
        uint makerAmount,
        address makerToken,
        address takerAddress,
        uint takerAmount,
        address takerToken,
        uint256 expiration,
        uint256 nonce)
    public
    view
    returns (bool) {
        // Hash arguments to identify the order.
        bytes32 hashV = keccak256(makerAddress, makerAmount, makerToken,
                                  takerAddress, takerAmount, takerToken,
                                  expiration, nonce);
        return airSwap.fills(hashV);
    }

    /// orderAddresses[0] == makerAddress
    /// orderAddresses[1] == makerToken
    /// orderAddresses[2] == takerAddress
    /// orderAddresses[3] == takerToken
    /// orderValues[0] = makerAmount
    /// orderValues[1] = takerAmount
    /// orderValues[2] = expiration
    /// orderValues[3] = nonce
    function fillBuy(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (uint) {
        airSwap.fill.value(msg.value)(orderAddresses[0], orderValues[0], orderAddresses[1],
                                      address(this), orderValues[1], orderAddresses[3],
                                      orderValues[2], orderValues[3], v, r, s);

        require(validateOrder(orderAddresses[0], orderValues[0], orderAddresses[1],
                              address(this), orderValues[1], orderAddresses[3],
                              orderValues[2], orderValues[3]), "AirSwapHandler - Buy order validation failed.");

        require(ERC20(orderAddresses[1]).transfer(orderAddresses[2], orderValues[0]), "AirSwapHandler - Failed to transfer token to taker");

        return orderValues[0];
    }

    /// orderAddresses[0] == makerAddress
    /// orderAddresses[1] == makerToken
    /// orderAddresses[2] == takerAddress
    /// orderAddresses[3] == takerToken
    /// orderValues[0] = makerAmount
    /// orderValues[1] = takerAmount
    /// orderValues[2] = expiration
    /// orderValues[3] = nonce
    function fillSell(
        address[8] orderAddresses,
        uint256[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private
    returns (uint)
    {
        require(orderAddresses[1] == address(weth), "AirSwapHandler - makerToken is not WETH for sell order");

        uint takerAmount = orderValues[1];

        if(ERC20(orderAddresses[3]).allowance(address(this), address(airSwap)) == 0) {
            require(ERC20(orderAddresses[3]).approve(address(airSwap), MAX_UINT), "AirSwapHandler - unable to set token approval for sell order");
        }

        airSwap.fill(orderAddresses[0], orderValues[0], orderAddresses[1],
                     address(this), takerAmount, orderAddresses[3],
                     orderValues[2], orderValues[3], v, r, s);

        require(validateOrder(orderAddresses[0], orderValues[0], orderAddresses[1],
                              address(this), takerAmount, orderAddresses[3],
                              orderValues[2], orderValues[3]), "AirSwapHandler - sell order validation failed.");

        weth.withdraw(orderValues[0]);
        msg.sender.transfer(orderValues[0]);

        return orderValues[0];
    }
}