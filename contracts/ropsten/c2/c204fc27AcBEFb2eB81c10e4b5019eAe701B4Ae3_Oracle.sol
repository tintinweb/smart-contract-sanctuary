/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: IPriceOracle

interface IPriceOracle {

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: IOracle

interface IOracle {
    // Needs to output the same number for the whole epoch
    function getRandNum(uint salt) external view returns (uint);

    function getPriceOracle() external view returns (IPriceOracle);

    function getAUTOPerETH() external view returns (uint);

    function getGasPriceFast() external view returns (uint);

    function setPriceOracle(IPriceOracle newPriceOracle) external;

    function defaultPayIsAUTO() external view returns (bool);

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external;
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: Oracle.sol

contract Oracle is IOracle, Ownable {

    IPriceOracle private _priceOracle;
    bool private _defaultPayIsAUTO;


    constructor(IPriceOracle priceOracle, bool defaultPayIsAUTO) Ownable() {
        _priceOracle = priceOracle;
        _defaultPayIsAUTO = defaultPayIsAUTO;
    }


    function getRandNum(uint seed) external override view returns (uint) {
        return uint(blockhash(seed));
    }

    function getPriceOracle() external override view returns (IPriceOracle) {
        return _priceOracle;
    }

    function getAUTOPerETH() external override view returns (uint) {
        return _priceOracle.getAUTOPerETH();
    }

    function getGasPriceFast() external override view returns (uint) {
        return _priceOracle.getGasPriceFast();
    }

    function setPriceOracle(IPriceOracle newPriceOracle) external override onlyOwner {
        _priceOracle = newPriceOracle;
    }

    function defaultPayIsAUTO() external override view returns (bool) {
        return _defaultPayIsAUTO;
    }

    function setDefaultPayIsAUTO(bool newDefaultPayIsAUTO) external override onlyOwner {
        _defaultPayIsAUTO = newDefaultPayIsAUTO;
    }
}