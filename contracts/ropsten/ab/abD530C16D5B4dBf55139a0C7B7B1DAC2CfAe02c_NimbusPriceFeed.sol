/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.5.17;

interface IPriceFeedsExt {
    function latestAnswer() external view returns (uint256);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NimbusPriceFeed is IPriceFeedsExt, Ownable {
    
    uint256 private _latestRate;
    uint256 private _lastUpdateTimestamp;
    
    function setLatestAnswer(uint256 rate) external onlyOwner {
        _lastUpdateTimestamp = block.timestamp;
        _latestRate = rate;
    }
    
    function lastUpdateTimestamp() external view returns (uint256) {
        return _lastUpdateTimestamp;
    } 
    
    function latestAnswer() external view returns (uint256) {
        return _latestRate;
    }
}