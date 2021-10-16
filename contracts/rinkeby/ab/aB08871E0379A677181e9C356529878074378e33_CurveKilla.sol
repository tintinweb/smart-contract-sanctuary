//SPDX-License-Identifier: MIT
//pragma
pragma solidity ^0.8.0;


//imports
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "./Derpys.sol";


//interfaces
interface DerpysContract {
	function currentSupply() external returns (uint256);
	function getCatchCost() external returns (uint256);
	function catchDerpy(uint256 numDerpys) external payable;
	function withdrawMissionBounty() external;
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferOwnership(address newOwner) external;
	function owner() external returns (address);
}

/***********************/
/* >>> CURVE KILLA <<< */
/***********************/

//order of operations
//1 give ownership of Derpys to CK -- manual via hardhat console
//2 make sure CK has a float
//3 users call mintFromTarget and pay MINT_PRICE per mint
//4 CurveKilla sends requested ether to Derpys when minting
//5 CurveKilla owner can skim ether and leave a 50 ETH
//  buffer in CK so minting can continue
//6 CurveKilla owner can reclaim ownership of Derpys
//7 CurveKilla owner can withdraw all ether from CK
//8 CurveKilla owner can manually prompt CK to top up 
//  by withdrawing from Derpys
//9 CurveKilla owner can set a new mint price and 
//  ether buffer in CK


//contracts
contract CurveKilla is IERC721Receiver, Ownable, ReentrancyGuard {
	//state vars
	address payable public immutable targetAddress;
	uint256 public MINT_PRICE = 0.05 ether;
	uint256 public MIN_BUFFER = 50 ether; //max cost to mint 50 derpys

	//events
	event Deposited(address, uint256);

	//***functions***
	//constructor
	constructor(address _targetAddress) {
		targetAddress = payable(_targetAddress);
	}

	receive() external payable {
		//allow deposits to the contract, used to overcome
		//higher prices in the target contract
	}

	//no fallback fn
	//no external fns
	//public fns:

	function setMintPrice(uint256 newWeiPrice) public onlyOwner {
		MINT_PRICE = newWeiPrice;
	}

	function setMinBuffer(uint256 newWeiBuffer) public onlyOwner {
		MIN_BUFFER = newWeiBuffer;
	}

	function mintFromTarget(uint256 numToMint) 
	public 
	payable 
	nonReentrant 
	{
		DerpysContract targetContract = DerpysContract(payable(targetAddress));

		//CHECKS
		require(
			numToMint > 0 && numToMint <= 50,
			"you can mint between 1 and 50 tokens"
		);
		require(
			msg.value >= numToMint * MINT_PRICE,
			"sent value is not enough"
		);

		uint256 targetSupply = targetContract.currentSupply();
		require(
			targetSupply + numToMint <= 10000,
			"not enough tokens remaining in the target"
		);

		//if this contract does not have enough ether
		//top up from target
		uint256 targetMintCost = numToMint * targetContract.getCatchCost();
		if (
			address(this).balance < targetMintCost &&
			targetContract.owner() == address(this)
		) 
		{
			targetContract.withdrawMissionBounty();
		}
		require(
			address(this).balance >= targetMintCost,
			"target mint price too high: top up this contract"
		);

		//EFFECTS (none)

		//INTERACTIONS
		//mint requested tokens to this contract
		//this reverts by default if the minting fails
		//because CK is ERC721Receiver
		targetContract.catchDerpy{value: targetMintCost}(numToMint);

		//forward tokens to msg.sender
		for (uint256 ii = 0; ii < numToMint; ii++) {
			uint256 itoken = targetSupply + ii;
			targetContract.safeTransferFrom(
				address(this), 
				msg.sender, 
				itoken
			);
		}
	}

	//get some ETH out as minting continues
	function skim() public payable onlyOwner {
		require(
			address(this).balance > MIN_BUFFER,
			"this ether needs to remain in CurveKilla"
		);

		uint256 amount = address(this).balance - MIN_BUFFER;
		payable(msg.sender).transfer(amount);
	}

	function withdraw() public payable onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	//This contract must become owner of targetContract 
	//This functions returns control of targetContract to owner
	function reclaimOwnershipOfTarget() public onlyOwner {
		DerpysContract targetContract = DerpysContract(payable(targetAddress));

		require(
			targetContract.owner() == address(this),
			"CurveKilla does not own targetContract"
		);
		targetContract.transferOwnership(this.owner());
	}
	
	//manually prompt this contract to top itself up by 
	//withdrawing from the targetContract
	function manualWithdrawFromTarget() public onlyOwner {
		DerpysContract targetContract = DerpysContract(payable(targetAddress));

		require(
			targetContract.owner() == address(this), 
			"CurveKilla does not own targetContract"
		);
		targetContract.withdrawMissionBounty();
	}

	function onERC721Received(
		address operator, 
		address from, 
		uint256 tokenId, 
		bytes calldata data
	)
		public 
		virtual 
		override 
		returns (bytes4) 
	{
		return this.onERC721Received.selector;
	}

	//no private fns
	//no internal fns
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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