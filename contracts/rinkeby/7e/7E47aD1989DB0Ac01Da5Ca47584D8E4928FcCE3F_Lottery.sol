/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: OpenZeppelin/[email protected]/Context

/**
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
        return msg.data;
    }
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: lottery.sol

contract Lottery is Ownable{
    address payable[] public players;
    address payable public recentWinner;
    uint256 usdEntryFee;
    uint256 randomness;
    uint256 start_timestamp;
    uint256 lottery_seconds_open;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {OPEN, CLOSED} //0, 1

    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeedAddress) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        require(msg.value + address(this).balance < 1 * (10**18), "Prize limit reached, no more participants can join!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns(uint256) {
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData();  // 8 decimals
        uint256 adjustedPrice = uint256(price) * (10**10);  // 18 decimals
        uint256 costToEnter = (usdEntryFee * (10**18) / adjustedPrice);
        return costToEnter;
    }

    function startLottery(uint _lottery_seconds_open) public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet!");
        start_timestamp = block.timestamp;
        lottery_seconds_open = _lottery_seconds_open;
        lottery_state = LOTTERY_STATE.OPEN;
    } 

    function endLottery() public {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery is not open so you cannot end it");
        require(block.timestamp >= start_timestamp + lottery_seconds_open * 1 seconds, "Lottery cannot be closed yet"); //days
        // need to close it with another transaction by calling this function after defined time passes

        uint256 indexOfWinner = genRandomness(players.length);
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        //Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function genRandomness(uint _range) public view onlyOwner returns(uint) {
        /*
        This is insecure if all of the following events happen:
        1. Malicious actor with mining node participates in this lottery
        2. Malicious actor computes correct hash of block preceding a block with endLottery transaction
           (which is called after some defined time by anyone)
        3. Malicious actor doesnt announce correct hash if it would make him lose,
           instead, he looks for new valid one that will make him win this lottery.
        4. Prize of this lottery is higher than single block ETH reward,
           so not publishing successful mining is profitable
        
        - with limiting max amount of ETH, it is not profitable to resign from block mining reward and cheat 
        - winner is determined by previous block hash, but malicious actor cannot use this knowledge 
          to modify modulo value (_range) because in "current" block when endLottery is called,
          no more participants can be added
        */
        bytes32 last_block_hash = blockhash(block.number - 1);
        uint random_number = uint(last_block_hash) % _range;
        return random_number;
    }
}