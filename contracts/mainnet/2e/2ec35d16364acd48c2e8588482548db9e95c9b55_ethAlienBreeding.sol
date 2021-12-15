/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
// 
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

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




// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title nonReentrant module to prevent recursive calling of functions
 * @dev See https://medium.com/coinmonks/protect-your-solidity-smart-contracts-from-reentrancy-attacks-9972c3af7c21
 */
 
abstract contract nonReentrant {
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "cannot reenter a locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}


interface Ethalien {
    
    function tokensOfWalletOwner(address _owner) external view returns (uint[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    
}

interface BabyEthalien {
    
    function publicMint(uint256 _quantity, address _breederAddress) external ;
    
}

interface Star {
    
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
}

// ***********************************
//           Ethalien Breeding
// ***********************************
/*
 *     
 *
*/


pragma solidity ^0.8.0;

contract ethAlienBreeding is Ownable, nonReentrant{
	
	Ethalien public ethalien;
	BabyEthalien public ethbaby;
    Star public star;
    bool mintState = false;
	
	mapping(uint => bool) public hasBreeded;
    
    function setEthAlienAddress(address _ethAlienAddress) public onlyOwner {
        ethalien = Ethalien(_ethAlienAddress);
    }
	
    function setEthBabyAddress(address _ethBabyAddress) public onlyOwner {
        ethbaby = BabyEthalien(_ethBabyAddress);
    } 

    function setStarAddress(address _starAddress) public onlyOwner {
        star = Star(_starAddress);
    }


    function changeMintState() public onlyOwner {
        mintState = !mintState;
    } 


	// in website mint function, user must run a call to Ethalien contract to
	// approve(THIS CONTRACT ADDRESS, token ID)
	
	function alienOrgy(uint256[] memory tokenIds) public {
		require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(mintState == true, "Breeding must be active" );
        require(tokenIds.length % 2 == 0, "Odd number of Aliens!");

		for (uint i = 0; i < tokenIds.length/2; i++) {

            breedAlien(tokenIds[i*2], tokenIds[i*2+1]);

        }
		

	}
	
 function breedAlien(uint A, uint B) internal reentryLock{
        require(hasBreeded[A] == false && hasBreeded[B] == false, "Invalid breeding pair");
           require(ethalien.ownerOf(A) == msg.sender, "Claimant is not the owner");
   require(ethalien.ownerOf(B) == msg.sender, "Claimant is not the owner");
              
        hasBreeded[A] = true;
        hasBreeded[B] = true;

      star.transferFrom(msg.sender ,0x000000000000000000000000000000000000dEaD, 300 ether) ;
        ethbaby.publicMint(1, msg.sender);
                
    } 


    function checkaliens(uint A) public view returns (bool){
        return hasBreeded[A];
    }

    function checkState() public view returns (bool){
        return mintState;
    }

    
	

}