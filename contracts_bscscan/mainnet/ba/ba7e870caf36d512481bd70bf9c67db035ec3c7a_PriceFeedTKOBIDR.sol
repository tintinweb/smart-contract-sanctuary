pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceFeedTKOBIDR is AggregatorV3Interface, Ownable {
    struct pricefeed {
        int256 answer;
        uint256 startedAt;
    }

    uint80 private latestRoundId;
    uint8 private decimals_; 
    string private description_;
    uint256 private version_;

    mapping(uint80 => pricefeed) private tkobidr;
    event Price(uint80 indexed roundId, int256 answer, uint256 startedAt);

    constructor(uint8 _decimals, string memory _description, uint256 _version) public {
        latestRoundId = 1;
        decimals_ = _decimals;
        description_ = _description;
        version_ = _version;
    }

    function updateDecimals(uint8 _decimals) external onlyOwner {
        decimals_ = _decimals;
    }

    function updateDescription(string memory _description) external onlyOwner {
        description_ = _description;
    }

    function updateVersion(uint256 _version) external onlyOwner {
        version_ = _version;
    }

    function updatePrice(int256 _answer) external onlyOwner {
        uint256 times = block.timestamp;
        tkobidr[latestRoundId] = pricefeed(_answer, times);
        emit Price(latestRoundId, _answer, times);
        latestRoundId += 1;
    }

    function decimals() external view virtual override returns(uint8) {
        return decimals_;
    }

    function description() external view virtual override returns(string memory) {
        return description_;
    }

    function version() external view virtual override returns(uint256) {
        return version_;
    }

    function getRoundData(uint80 _roundId) external view virtual override returns(uint80, int256, uint256, uint256, uint80) {
        pricefeed memory pf = tkobidr[_roundId];
        return (_roundId, pf.answer, pf.startedAt, block.timestamp, (latestRoundId - 1));
    }

    function latestRoundData() external view virtual override returns(uint80, int256, uint256, uint256, uint80) {
        uint80 _roundId = latestRoundId - 1;
        pricefeed memory pf = tkobidr[_roundId];
        return (_roundId, pf.answer, pf.startedAt, block.timestamp, _roundId);
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

