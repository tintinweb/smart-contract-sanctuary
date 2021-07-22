/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// File: @openzeppelin/contracts/utils/Context.sol

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



// File: contracts/IOracle.sol

interface IOracle {
	// returns a fraction num/den
	function getPrice(string memory base, string memory quote) external view returns (uint num, uint den);
}



// File: contracts/Oracle.sol

contract Oracle is IOracle, Ownable {
	struct Fraction {
		uint num;
		uint den;
	}
	
	mapping(string => mapping(string => Fraction)) public prices;

	function getPrice(string memory base, string memory quote) public override view returns (uint num, uint den) {
		if (keccak256(abi.encodePacked(base)) == keccak256(abi.encodePacked(quote)))
			return (1, 1);
		Fraction storage price = prices[base][quote];
		if (price.num > 0)
			return (price.num, price.den);
		// try a reverse fraction
		price = prices[quote][base];
		if (price.num > 0)
			return (price.den, price.num);
		return (0, 0);
	}

	// zero den is ok - infinite price
	// both zeros: stopped trading, no price
	function setPrice(string memory base, string memory quote, uint num, uint den) onlyOwner public {
		Fraction storage reverse_price = prices[quote][base];
		bool reverse_price_exists = (reverse_price.num > 0 || reverse_price.den > 0);
		if (!reverse_price_exists)
			prices[base][quote] = Fraction({num: num, den: den});
		else
			prices[quote][base] = Fraction({num: den, den: num});
	}

}