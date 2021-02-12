/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Oraclize{
    function oracleCallback(uint256 requestId,uint256 balance) external returns(bool);
    function oraclePriceAndBalanceCallback(uint256 requestId,uint256 priceA,uint256 priceB,uint256[] calldata balances) external returns(bool);
}

contract Oracle is Ownable{
    
    uint256 public requestIdCounter;

    mapping(address => bool) public isAllowedAddress;
    mapping(address => bool) public isSystemAddress;
    mapping(uint256 => bool) public requestFullFilled;
    mapping(uint256 => address) public requestedBy;

    
    event BalanceRequested(uint256 indexed requestId,uint256 network,address token,address user);
    event PriceAndBalanceRequested(uint256 indexed requestId,address tokenA,address tokenB,uint256 network,address token,address[] user);
    event BalanceUpdated(uint256 indexed requestId,uint256 balance);
    event PriceAndBalanceUpdated(uint256 indexed requestId,uint256 priceA,uint256 priceB,uint256[] balances);
    event SetSystem(address system, bool isActive);

    // only system wallet can send oracle response
    modifier onlySystem() {
        require(isSystemAddress[msg.sender],"Not System");
        _;
    }

    // only system wallet can send oracle response
    function setSystem(address system, bool isActive) external onlyOwner {
        isSystemAddress[system] = isActive;
        emit SetSystem(system, isActive);
    }

    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

    // parameter pass networkId like eth_mainNet = 1,ropsten = 97 etc 
    // token parameter is which token balance you want for native currency pass address(0)
    // user which address you want to show
    function getBalance(uint256 network,address token,address user) external returns(uint256){
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        requestIdCounter +=1;
        requestedBy[requestIdCounter] = msg.sender;
        emit BalanceRequested(requestIdCounter,network,token,user);
        return requestIdCounter;
    }
    
    function getPriceAndBalance(address tokenA,address tokenB,uint256 network,address token,address[] calldata user) external returns(uint256){
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        requestIdCounter +=1;
        requestedBy[requestIdCounter] = msg.sender;
        emit PriceAndBalanceRequested(requestIdCounter,tokenA,tokenB,network,token,user);
        return requestIdCounter;
    }
    
    function oracleCallback(uint256 _requestId,uint256 _balance) external onlySystem returns(bool){
        require(requestFullFilled[_requestId]==false,"ERR_REQUESTED_IS_FULFILLED");
        address _requestedBy = requestedBy[_requestId];
        Oraclize(_requestedBy).oracleCallback(_requestId,_balance);
        emit BalanceUpdated(_requestId,_balance);
        requestFullFilled[_requestId] = true;
        return true;
    }
    
    
    function oraclePriceAndBalanceCallback(uint256 _requestId,uint256 _priceA,uint256 _priceB,uint256[] calldata _balances) external onlySystem returns(bool){
        require(requestFullFilled[_requestId]==false,"ERR_REQUESTED_IS_FULFILLED");
        address _requestedBy = requestedBy[_requestId];
        Oraclize(_requestedBy).oraclePriceAndBalanceCallback(_requestId,_priceA,_priceB,_balances);
        emit PriceAndBalanceUpdated(_requestId,_priceA,_priceB,_balances);
        requestFullFilled[_requestId] = true;
        return true;
    }
}