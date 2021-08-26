/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.8.7;

interface IAggregatorInterface {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PairPriceFeedMock is IAggregatorInterface {
    uint8 private _decimals;
    int256 private _latestAnswer;

    constructor() {
        _latestAnswer = 321566085546;
        _decimals = 8;
    }

    function setMockData(int256 price, uint8 decimals_) external {
        _decimals = decimals_;
        _latestAnswer = price;
    }

    function decimals() external override view returns (uint8){
        return _decimals;
    }

    function latestAnswer() external view override returns (int256 answer) {
        return _latestAnswer;
    }
}