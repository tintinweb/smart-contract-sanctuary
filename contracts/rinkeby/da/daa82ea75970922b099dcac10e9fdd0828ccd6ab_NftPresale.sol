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

interface INftPresale {
	function buy(uint _amount, bytes memory _signature) external payable;
}

contract NftPresale is INftPresale, Ownable {

	uint public constant START_TIME = 1640001600;
	uint public constant FINISH_TIME = 1704024000;
	uint public constant PRE_SALE_PRICE = 0.06 ether;

	INFT public nft;
	
	address public verifyAddress = 0x033712221E621eA831543Bd36b203A0D19b2621b;
	mapping(address => bool) public buyers;
	
	address payable public paymentAddress;

    constructor(address _nftAddress, address _paymentAddress)
	{
		nft = INFT(_nftAddress);
		
		paymentAddress = payable(_paymentAddress);
	}

	/*
	 * @dev function to buy tokens. Can be bought only 1. 
	 * @param _amount how much tokens can be bought.
	 * @param _signature Signed message from verifyAddress private key
	 */
	function buy(uint _amount, bytes memory _signature) external override payable {
	    require(_amount == 1, "only 1 token can be bought on presale");
	    require(block.timestamp >= START_TIME && block.timestamp < FINISH_TIME, "not a presale time");
		require(msg.value == PRE_SALE_PRICE, "token price 0.06 ETH");
		require(!buyers[msg.sender], "only one token can be bought on presale");
		require(verify(_signature), "invalid signature");
		buyers[msg.sender] = true;

		nft.mintBatch(msg.sender, _amount);
	}
	
	/*
	 * @dev function to withdraw all tokens
	 * @param _to ETH receiver address
	 */
    function cashOut() public onlyOwner{
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        
        (bool sent, ) = paymentAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with receiver");
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