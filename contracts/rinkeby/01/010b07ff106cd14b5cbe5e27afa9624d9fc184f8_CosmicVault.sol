/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface StoredContract {
    function previousOwner() external view returns (address);
    function transferOwnership(address addr)  external;
    function getUnlockTime() external view returns(uint256);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

contract CosmicVault is Context, Ownable {
    
    uint256 public unlockFee = 1 ether;
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 - ETH/USD ETHMainnet
        // 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e - ETH/USD BSCMainnet
    }

    
    function updateUnlockFee(uint amountUSD) external onlyOwner {
        (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        // unlockFee = (amountUSD / (uint(price) / 1e8) * (1 ether);
        uint ethPrice = uint(price) / 1e8;
        unlockFee = ((amountUSD* 1e5 / ethPrice + 5) / 10) * 1e14;
    }
    
    function checkUnlockTime(StoredContract contractAddress) public view returns(uint256) {
        return contractAddress.getUnlockTime();
    }
    
    function checkPreviousOwner(StoredContract contractAddress) public view returns(address) {
        return contractAddress.previousOwner();
    }
    
    function restoreContract(StoredContract contractAddress) public payable {
        require(msg.value == unlockFee, 'Vault: Unlock fee mismatch');
        address _lastOwner = contractAddress.previousOwner();
        uint256 _unlockTime = contractAddress.getUnlockTime();
        require(_lastOwner == msg.sender, 'Vault: Sender/lastOwner mismatch');
        require(_unlockTime <= block.timestamp ,'Vault: Lockup period has not elapsed');
        contractAddress.transferOwnership(msg.sender);
    }
    
    function withdraw() external onlyOwner {
        address payable wallet = payable(msg.sender);
        wallet.transfer(address(this).balance);
    }

    function getPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price / 1e8;
    }
    
}