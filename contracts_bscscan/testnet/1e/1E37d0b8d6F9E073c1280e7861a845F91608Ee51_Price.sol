// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPrice.sol";

contract Price is IPrice, Ownable {
    address public prediction;
    
    constructor(address _prediction) {
        prediction = _prediction;
    }
    
    modifier onlyPrediction {
        require(msg.sender == prediction, "PRICE: Only call by prediction");
        _;
    }
    
    /**
     * @dev get last price provided by chainlink (https://docs.chain.link/docs/get-the-latest-price)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     */
    function getLastPrice(address _address) public override view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_address);
        (
            /* uint80 roundID */, 
            int price,
            uint startedAt,
            uint timeStamp,
            /* uint80 answeredInRound */ 
        ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        string memory description = priceFeed.description();
        return (price, decimals, startedAt, timeStamp, description);
    }
    
    /**
     * @dev get historical price provided by chainlink (https://docs.chain.link/docs/historical-price-data)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     * @param roundId id of round
     */
    function getHistoricalPrice(address _address, uint80 roundId) public override view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_address);
        (
            /* uint80 id */,
            int price,
            uint startedAt,
            uint timeStamp,
            /* uint80 answeredInRound */
        ) = priceFeed.getRoundData(roundId);
        require(timeStamp > 0, "PRICE: Round not complete");
        uint8 decimals = priceFeed.decimals();
        string memory description = priceFeed.description();
        return (price,decimals, startedAt, timeStamp, description);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IPrice {
     /**
     * @dev get last price provided by chainlink (https://docs.chain.link/docs/get-the-latest-price)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     */
     function getLastPrice(address _address) external view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description);

     /**
     * @dev get historical price provided by chainlink (https://docs.chain.link/docs/historical-price-data)
     * @param _address Chainlink Price Feed contracts address (https://docs.chain.link/docs/reference-contracts)
     * @param roundId id of round
     */
     function getHistoricalPrice(address _address, uint80 roundId) external view returns (int _price, uint8 _decimals, uint _startedAt, uint _timeStamp, string memory _description);
}

