/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

/******************************************/
/*            NRVToken starts here        */
/******************************************/

abstract contract NrvToken

{
    function setGovernance(address _nrvGov) external virtual;

    function setRates(uint256 _nrvRate, uint256 _baseRate) external virtual;

    function setBase(address _base) external virtual;

    function addNrv(address _nrv) external virtual;

    function removeNrv(uint256 _index) external virtual;
}

/******************************************/
/*            NRV starts here             */
/******************************************/

abstract contract Nrv 

{
    function setFees(uint256 _taskFee, uint256 _betFee) external virtual;

    function setGovernance(address _nrvGov) external virtual;
}



/******************************************/
/*          NrvGov starts here            */
/******************************************/
contract NerveGov is Ownable {

    Nrv public nrv;
    NrvToken public nrvToken;
    bool internal initialized;
    
    function initialize(address _nrv, address _nrvToken) public {
        require(initialized == false, "Already initialized.");
        initialized = true;
        nrv = Nrv(_nrv);
        nrvToken = NrvToken(_nrvToken);
    }

    function setGovernance(address _nrvGov) external onlyOwner {
        nrvToken.setGovernance(_nrvGov);
        nrv.setGovernance(_nrvGov);
    }

    function setRates(uint256 _nrvRate, uint256 _baseRate) external onlyOwner {
        nrvToken.setRates(_nrvRate, _baseRate); 
    }

    function setBase(address _base) external onlyOwner {
        nrvToken.setBase(_base);  
    }

    function addNrv(address _nrv) external onlyOwner {
        nrvToken.addNrv(_nrv);
    }

    function removeNrv(uint256 _index) external onlyOwner {
        nrvToken.removeNrv(_index);
    }

    function setFees(uint256 _taskFee, uint256 _betFee) external onlyOwner {
        nrv.setFees(_taskFee, _betFee);
    }

}