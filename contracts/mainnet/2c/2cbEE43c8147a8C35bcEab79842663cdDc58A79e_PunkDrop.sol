/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: IPunk

interface IPunk {
	function transferPunk(address to, uint punkIndex) external;
	function balanceOf(address) external view returns(uint256);
	function punkIndexToAddress(uint) external view returns(address);
}

// Part: OpenZeppelin/[email protected]/Context

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// File: PunkDrop.sol

contract PunkDrop is Ownable {

	IPunk PUNKS = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

	uint256 public  punksToDrop;
	mapping(uint256 => uint256) public  punkSet;
	uint256 public ticketsLeft;
	mapping(uint256 => address) public tickets;

	event PunkDropped(address winner, uint256 id);

	function logSet(uint256[] calldata _ids) external onlyOwner {
		uint256 currentIndex = punksToDrop;
		require(currentIndex + _ids.length <= 150, "PunkDrop: Too many logged punks.");
		for (uint256 i = 0; i < _ids.length; i++)
			punkSet[currentIndex + i] = _ids[i];
		punksToDrop += _ids.length;
	}

	function logAddresses(address[] calldata _addresses) external onlyOwner {
		uint256 _tickets = ticketsLeft;
		require(_tickets + _addresses.length <= 150, "PunkDrop: Too many logged tickets");
		for (uint256 i = 0; i < _addresses.length; i++) {
			tickets[i + _tickets] = _addresses[i];
		}
		ticketsLeft += _addresses.length;
	}

	function dropPunk(string calldata _seed) external onlyOwner {
		require(punksToDrop > 0, "PunkDrop: Party is over.");
		// keccak the seed then find punk to send
		uint256 raw = uint256(keccak256(abi.encodePacked(_seed)));
		uint256 wonPunk = punkSet[raw % punksToDrop];
		//put last punk in mapping in the won punk's slot
		punkSet[raw % punksToDrop] = punkSet[punksToDrop - 1];
		delete punkSet[punksToDrop - 1];
		// get last map for cheaper gas to avoid sstore again
		address winner = tickets[ticketsLeft - 1];
		delete tickets[ticketsLeft - 1];
		ticketsLeft--;
		punksToDrop--;
		PUNKS.transferPunk(winner, wonPunk);
		emit PunkDropped(winner, wonPunk);
	}

	function evacPunk(uint256 _id) external onlyOwner{
		PUNKS.transferPunk(msg.sender, _id);
	}
}