// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of the March 19th 2021 to April 5th 2021 March Madness Oracle with Associated Press
 *
 * All interested consumers can freely access the games from the "games" mapping
 * You may also listen for the "SetWinner" event.
 */
contract MarchMadness2021 is Ownable {

    /**
     * @dev Game struct for holding the Game data
     */
    struct Game {
        string id;
        string homeTeam;
        string awayTeam;
        uint winner; // 0: none, 1: home, 2: away
        uint homePoints;
        uint awayPoints;
        uint scheduled;
        uint round;
        /**
         *  @dev round
         *  0: "firstFour"
         *  1: "firstRound"
         *  2: "secondRound"
         *  3: "sweet16"
         *  4: "eliteEight"
         *  5: "finalFour"
         *  6: "nationalChampionship"
         */
    }

    mapping(string => Game) public allGames;
    string public ipfsFullData;

    /**
     *  @dev Event is called whenever a winner is called
     */
    event CallWinner(
        string id,
        string homeTeam,
        string awayTeam,
        uint winner,
        uint homePoints,
        uint awayPoints,
        uint scheduled
    );

    /**
     *  @dev Calls a Winner for a game
     */
    function callWinner(
        uint round,
        string calldata id,
        string calldata homeTeam,
        string calldata awayTeam,
        uint winner,
        uint homePoints,
        uint awayPoints,
        uint scheduled
    )
    external
    onlyOwner
    {
        allGames[id] = Game(id, homeTeam, awayTeam, winner, homePoints, awayPoints, scheduled, round);
        emit CallWinner(id, homeTeam, awayTeam, winner, homePoints, awayPoints, scheduled);
    }

    /**
     *  @dev Returns a specific game based on id
     */
    function getGame(string memory id) public view returns (Game memory){
        return allGames[id];
    }

    /**
     *  @dev Event is called whenever the ipfs hash is updated
     */
    event SetIPFS(string ipfsHash);

    /**
    *   @dev Sets the IPFS hash for the pinned json containing the data for March Madness
    */
    function setIpfsData(string calldata ipfsHash)
    external
    onlyOwner
    {
        ipfsFullData = ipfsHash;
        emit SetIPFS(ipfsHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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