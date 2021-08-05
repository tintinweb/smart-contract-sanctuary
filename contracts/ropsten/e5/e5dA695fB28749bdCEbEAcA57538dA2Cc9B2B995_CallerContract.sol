/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

//SPDX-License-Identifier: GPL 3
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface ICallerContract {
  function callbackOracle(uint256 latestPrice, uint256 id) external;
  function callbackDB(string calldata value, uint256 id) external;
}

interface IBluzelleOracle {
    function getOracleValue(string calldata pair1, string calldata pair2, uint gasPrice) external returns (uint id);
    function getDBValue(string calldata uuid, string calldata key, uint gasPrice) external returns (uint id);
    function withdrawGas(address payable _to, uint _val) external payable;
    function rechargeGas(address _for) external payable;
}


/*
 This is just an example Caller Contract for the user's reference
 for interacting with the BluzelleOracle
 */

contract CallerContract is ICallerContract, Ownable {

    IBluzelleOracle private oracleInstance;
    address private oracleAddress;
    mapping(uint => bool) myRequests;
    uint public btcValue;
    string public dbValue;

    event OracleAddressUpdated(address oracleAddress);
    event ReceivedNewRequestId(uint id);
    event PriceUpdated(uint btcPrice, uint id);
    event DBValueUpdated(string value, uint id);

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not authorized");
    _;
    }

    modifier requestExists(uint id) {
        require(myRequests[id], "Not in pending list");
        _;
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        oracleAddress = _oracle;
        oracleInstance = IBluzelleOracle(oracleAddress);
        emit OracleAddressUpdated(oracleAddress);
    }

    function rechargeOracle() public payable {
        // the account must have ether to recharge
        oracleInstance.rechargeGas{value: msg.value}(address(this));
    }

    function withdrawGas(address payable _to, uint _amount) public onlyOwner {
        oracleInstance.withdrawGas(_to, _amount);
    }

    // currently testing the value only for the btc/usd pair
    function updateBtcValue(uint _gasPrice) public {
        uint id = oracleInstance.getOracleValue("btc", "usd", _gasPrice);
        myRequests[id] = true;
        emit ReceivedNewRequestId(id);
    }

    function updateDBValue(string calldata uuid, string calldata key, uint gasPrice) public {
        uint id = oracleInstance.getDBValue(uuid, key, gasPrice);
        myRequests[id] = true;
        emit ReceivedNewRequestId(id);
    }

    function callbackOracle(uint latestPrice, uint id) public override onlyOracle requestExists(id) {
        btcValue = latestPrice;
        delete myRequests[id];
        emit PriceUpdated(latestPrice, id);
    }

    function callbackDB(string calldata value, uint id) public override onlyOracle requestExists(id) {
        dbValue = value;
        delete myRequests[id];
        emit DBValueUpdated(value, id);
    }

    receive() external payable {

    }
}