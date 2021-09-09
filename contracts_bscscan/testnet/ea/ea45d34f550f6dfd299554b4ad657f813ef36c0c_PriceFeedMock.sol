/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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
abstract contract Ownable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address ownerAddress) {
        require(ownerAddress != address(0), "Ownable: zero address");
        _owner = ownerAddress;
        emit OwnershipTransferred(address(0), ownerAddress);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function newOwner() public view virtual returns (address) {
        return _newOwner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner());
        _newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner(), "Ownable: caller is not the new owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchPrice() external returns (uint);
}

contract PriceFeedMock is Ownable, IPriceFeed {

    uint public lastGoodPrice;

    constructor(address owner) Ownable(owner) {
        lastGoodPrice = 20216579702450000000000;
    }

    function fetchPrice() external view override returns (uint) {
        return lastGoodPrice;
    }

    function setPrice(uint amount) external onlyOwner {
        lastGoodPrice = amount;
    }
}