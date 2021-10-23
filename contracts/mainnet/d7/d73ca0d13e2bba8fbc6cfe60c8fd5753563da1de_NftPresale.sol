/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

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

interface INFT {
	function mint(address _to) external;
	function mintBatch(address _to, uint _amount) external;
}
interface INftPresale {
	function buy(uint _amount, bytes memory _signature) external payable;
}

contract NftPresale is INftPresale, Ownable {

	uint public constant START_TIME = 1634929200;
	uint public constant FINISH_TIME = 1635015600;
	uint public constant PRE_SALE_PRICE = 0.2 ether;

	INFT public nft;
	
	address public verifyAddress = 0x142581fda5769fe7f8d3b50794dBda454DA4F3ac;
	mapping(address => bool) public buyers;
	
	address payable public receiver;

	constructor(address _nftAddress, address payable _receiverAddress) {
		nft = INFT(_nftAddress);
		
		//receiver - 0xD3db8094b50F2F094D164C1131BB9E604dfe0590
		receiver = _receiverAddress;
	}

	/*
	 * @dev function to buy tokens. Can be bought only 1. 
	 * @param _amount how much tokens can be bought.
	 * @param _signature Signed message from verifyAddress private key
	 */
	function buy(uint _amount, bytes memory _signature) external override payable {
	    require(_amount == 1, "only 1 token can be bought on presale");
	    require(block.timestamp >= START_TIME && block.timestamp < FINISH_TIME, "not a presale time");
		require(msg.value == PRE_SALE_PRICE, "token price 0.2 ETH");
		require(!buyers[msg.sender], "only one token can be bought on presale");
		require(verify(_signature), "invalid signature");
		buyers[msg.sender] = true;

		nft.mintBatch(msg.sender, _amount);
		(bool sent, ) = receiver.call{value: address(this).balance}("");
        require(sent, "Something wrong with receiver");
	}
	
	/*
	 * @dev function to withdraw all tokens
	 * @param _to ETH receiver address
	 */
	function cashOut(address _to) public onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

	/// signature methods.
	function verify(bytes memory _signature) internal view returns(bool) {
		bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, address(this))));
        return (recoverSigner(message, _signature) == verifyAddress);
	}

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(sig, (uint8, bytes32, bytes32));

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}