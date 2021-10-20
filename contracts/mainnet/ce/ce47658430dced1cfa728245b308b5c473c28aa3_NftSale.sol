/**
 *Submitted for verification at Etherscan.io on 2021-10-20
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

contract NftSale is Ownable {

	uint public constant MAX_UNITS_PER_TRANSACTION = 5;
	uint public constant MAX_NFT_TO_SELL = 7444;
	
	uint public constant INITIAL_PRICE = 3.3 ether;
	uint public constant FINAL_PRICE = 0.3 ether;
	uint public constant PRICE_DROP = 0.1 ether;
	uint public constant PRICE_DROP_TIME = 5 minutes;
	uint public constant START_TIME = 1634547907;
	
	address payable public receiver;
	
	INFT public nft;
	uint public tokensSold;

	constructor(address _nftAddress, address payable _receiverAddress) {
		nft = INFT(_nftAddress);
		
		//receiver - 0xD3db8094b50F2F094D164C1131BB9E604dfe0590
		receiver = _receiverAddress;
	}
	
	/*
	 * @dev calculate NFT price on current time. 
	 */
	function getCurrentPrice() public view returns(uint) {
		return getPriceOnTime(block.timestamp);
	}
	
	/*
	 * @dev calculate NFT price on exact time. 
	 * @param _time time for calculation
	 */
	function getPriceOnTime(uint _time) public pure returns(uint) {
		if(_time < START_TIME) {
			return 0;
		}
		uint maxRange = (INITIAL_PRICE - FINAL_PRICE) / PRICE_DROP;
		uint currentRange = (_time - START_TIME) / PRICE_DROP_TIME;

		if(currentRange >= maxRange) {
			return FINAL_PRICE;
		}
        
		return INITIAL_PRICE - (currentRange * PRICE_DROP);
	}

	/*
	 * @dev function to buy tokens. 
	 * @param _amount how much tokens can be bought.
	 */
	function buyBatch(uint _amount) external payable {
		require(block.timestamp >= START_TIME, "sale is not started yet");
		require(tokensSold + _amount <= MAX_NFT_TO_SELL, "exceed sell limit");
		require(_amount > 0, "empty input");
		require(_amount <= MAX_UNITS_PER_TRANSACTION, "exceed MAX_UNITS_PER_TRANSACTION");

		uint currentPrice = getCurrentPrice() * _amount;
		require(msg.value >= currentPrice, "too low value");
		if(msg.value > currentPrice) {
			//send the rest back
			(bool sent, ) = payable(msg.sender).call{value: msg.value - currentPrice}("");
        	require(sent, "Failed to send Ether");
		}
		
		tokensSold += _amount;
		nft.mintBatch(msg.sender, _amount);
		receiver.transfer(address(this).balance);
	}

	function cashOut(address _to) public onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(_to != address(0), "invalid address");
        
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}