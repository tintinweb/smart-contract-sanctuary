// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BridgePair is Ownable {
    string public constant name = "BridgePair";

    struct Coin {
        string chain;
        string currency;
        address token;
        uint8 decimals;
        bool tag;
    }

    struct Pair {
        uint256 srcCid;
        uint256 dstCid;
        uint256 status;
    }

    uint256 public numCoins;
    uint256 public numPairs;

    mapping(bytes32 => bool) public _coins;
    mapping(bytes32 => bool) public _pairs;
    mapping(uint256 => Coin) public coins;
    mapping(uint256 => Pair) public pairs;

    event CreatedCoin(uint256 id, string chain, string currency, address token, uint8 decimals, bool tag);
    event CreatedPair(uint256 id, uint256 srcCid, uint256 dstCid, uint256 status);
    event UpdatedPair(uint256 id, uint256 srcCid, uint256 dstCid, uint256 status);

    constructor() {}

    function createCoin(string calldata chain, string calldata currency, address token, uint8 decimals, bool tag) external onlyOwner returns (uint256 coinId) {
        bytes32 key = keccak256((abi.encodePacked(chain, currency, token)));
        require(!_coins[key], "BridgePair:coin already exists");

        coinId = ++numCoins;
        coins[coinId] = Coin(chain, currency, token, decimals, tag);
        _coins[key] = true;

        emit CreatedCoin(coinId, chain, currency, token, decimals, tag);
    }

    function createPair(uint256 srcCid, uint256 dstCid, uint256 status) external onlyOwner returns (uint256 pairId) {
        bytes32 key = keccak256((abi.encodePacked(srcCid, dstCid)));
        require(!_pairs[key], "BridgePair:pair already exists");
        require(bytes(coins[srcCid].chain).length != 0, "BridgePair:src cid not exists");
        require(bytes(coins[dstCid].chain).length != 0, "BridgePair:dst cid not exists");

        pairId = ++numPairs;
        pairs[pairId] = Pair(srcCid, dstCid, status);
        _pairs[key] = true;

        emit CreatedPair(pairId, srcCid, dstCid, status);
    }

    function updatePair(uint256 pairId, uint256 status) external onlyOwner {
        require(pairs[pairId].srcCid != 0, "BridgePair:pair not exists");

        Pair storage pair = pairs[pairId];
        pair.status = status;

        emit UpdatedPair(pairId, pair.srcCid, pair.dstCid, status);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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