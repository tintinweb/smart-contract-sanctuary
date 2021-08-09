/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _setOwner(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IIndexHolder {
    function latestAnswer () external view returns (int256);
    function latestTimestamp () external view returns (uint256);
}

contract OracleGateway is Ownable {
    IIndexHolder public holder;
    string public identifier;

    constructor (string memory _identifier) public {
        identifier = _identifier;
    }

    function setNewHolder (address _holder) external {
        holder = IIndexHolder(_holder);
    }

    function latestAnswer () external view returns (int256) {
        return holder.latestAnswer();
    }

    function latestTimestamp () external view returns (uint256) {
        return holder.latestTimestamp();
    }
}