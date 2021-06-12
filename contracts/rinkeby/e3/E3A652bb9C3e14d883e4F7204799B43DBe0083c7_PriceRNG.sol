// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceRNG is Ownable {

  uint public numOfPairs;

  struct PairAddresses {
    address tokenA;
    address tokenB;
    address pair;

    uint lastUpdateTimeStamp;
  }

  mapping(uint => PairAddresses) public pairs;

  event RandomNumber(address indexed requester, uint randomNumber);
  event PairAdded(address pair, address tokenA, address tokenB);

  constructor() {}

  /// @dev Add a UniswapV2 pair to draw randomness from.
  function addPair(
    address pair, 
    address tokenA, 
    address tokenB
  ) external onlyOwner {
    require(IUniswapV2Pair(pair).MINIMUM_LIQUIDITY() == 1000, "Invalid pair address provided.");

    pairs[numOfPairs] = PairAddresses({
      tokenA: tokenA,
      tokenB: tokenB,
      pair: pair,
      lastUpdateTimeStamp: block.timestamp
    });

    numOfPairs += 1;

    emit PairAdded(pair, tokenA, tokenB);
  }

  /// @dev Returns a random number within the given range;
  function getRandomNumber(uint range) external returns (uint randomNumber) {
    require(numOfPairs > 0, "No Uniswap pairs available to draw randomness from.");

    bool acceptableEntropy;
    uint blockSignature = uint(keccak256(abi.encodePacked(msg.sender, uint(blockhash(block.number - 1)))));

    for(uint i = 0; i < numOfPairs; i++) {
      PairAddresses memory pairInfo = pairs[i];
      (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) = getReserves(pairInfo.pair, pairInfo.tokenA, pairInfo.tokenB);
      
      uint randomMod = (reserveA + reserveB) % 73;
      blockSignature += randomMod;

      if(lastUpdateTimeStamp > pairInfo.lastUpdateTimeStamp) {
        acceptableEntropy = true;
        
        pairInfo.lastUpdateTimeStamp = lastUpdateTimeStamp;
        pairs[i] = pairInfo;
      }
    }

    require(acceptableEntropy, "Cannot generate a sufficiently random number.");
    randomNumber = blockSignature % range;

    emit RandomNumber(msg.sender, randomNumber);
  }
  
  /// @notice See `UniswapV2Library.sol`
  function getReserves(
    address pair, 
    address tokenA, 
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, uint blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
    (reserveA, reserveB, lastUpdateTimeStamp) = tokenA == token0 ? (reserve0, reserve1, blockTimestampLast) : (reserve1, reserve0, blockTimestampLast);
  }

  /// @notice See `UniswapV2Library.sol`
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}