/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
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

interface INFT {
	function mint(address _to) external;
	function mintBatch(address _to, uint _amount) external;
}

contract NftSale is Ownable {

	uint public constant MAX_UNITS_PER_TRANSACTION = 5;
	uint public constant MAX_NFT_TO_SELL = 9500;
	
	uint public constant SALE_PRICE = 0.12 ether;
	uint public constant START_TIME = 1640001600;
	
    address payable public paymentAddress;
	
	INFT public nft;
	uint public tokensSold;

	constructor(address _nftAddress, address _paymentAddress) {
		nft = INFT(_nftAddress);
		
		paymentAddress = payable(_paymentAddress);
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

		uint totalPrice = SALE_PRICE * _amount;
		require(msg.value >= totalPrice, "too low value");
		if(msg.value > totalPrice) {
			//send the rest back
			(bool sent, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
        	require(sent, "Failed to send Ether");
		}
		
		tokensSold += _amount;
		nft.mintBatch(msg.sender, _amount);		
	}

    function cashOut() public onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.

        (bool sent, ) = paymentAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with receiver");
    }
}