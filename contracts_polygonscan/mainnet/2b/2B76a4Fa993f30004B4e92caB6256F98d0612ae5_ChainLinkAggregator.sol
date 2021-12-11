//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLinkAggregator is Ownable {
    mapping(address => address) public oracles;
    mapping(address => mapping(address => address)) public directOracles;

    function addOracle(address _token, address _oracle) public onlyOwner {
        oracles[_token] = _oracle;
    }

    function addOracleBatch(address[] memory _token, address[] memory _oracle)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _token.length; i++) {
            oracles[_token[i]] = _oracle[i];
        }
    }

    function addDirectOracle(
        address _token1,
        address _token2,
        address _oracle
    ) public onlyOwner {
        directOracles[_token1][_token2] = _oracle;
    }

    function addDirectOracleBatch(
        address[] memory _token1,
        address[] memory _token2,
        address[] memory _oracle
    ) public onlyOwner {
        for (uint256 i = 0; i < _token1.length; i++) {
            directOracles[_token1[i]][_token2[i]] = _oracle[i];
        }
    }

    function getOracle(address _token) public view returns (address) {
        return oracles[_token];
    }

    function getDirectOracle(address _token1, address _token2)
        public
        view
        returns (address)
    {
        return directOracles[_token1][_token2];
    }

    function getPrice(address _token1, address _token2)
        external
        view
        returns (int256 price)
    {
        address oracle1 = directOracles[_token1][_token2];
        address oracle2 = directOracles[_token2][_token1];

        if (oracle1 != address(0)) {
            // If direct Oracle is Availabe
            return getOracleFeed(oracle1);
        } else if (oracle2 != address(0)) {
            // If reverse oracle is availabe
            return 10**36 / getOracleFeed(oracle2);
        }
        // If no direct oracel availabe check for Token/USD oracle for both Token1 and Token2
        oracle1 = oracles[_token1];
        oracle2 = oracles[_token2];
        if (oracle1 != address(0) && oracle2 != address(0)) {
            return (getOracleFeed(oracle1) * 10**18) / getOracleFeed(oracle2);
        }
        // If no oracle availabe return 0.
        return 0;
    }

    function getOracleFeed(address _oracle) public view returns (int256) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(_oracle);
        (, int256 price, , uint256 timeStamp, ) = aggregator.latestRoundData();
        // console.log("Current price", uint256(price));
        return scalePrice(price, aggregator.decimals(), 18);
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
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