// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
}

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

/**
 * @notice the purpose of this data structure is to mitigate
 * the 'Stack too deep' error caused by passing all requisite
 * values as individual parameters.   
 */
struct NiftyEvent {
    bool multitoken; // Distinguish between 1155 and 721 token. 
    string currency;
    uint256 price; 
    uint256 tokenId;
    uint256 value; // Facilitates 1155 extensibility, defaults to '1' for 721 tokens. 
    address tokenContract;
    address buyer;
    address seller;
    bytes data;
}

/**
 * 
 */
contract NiftyExchangeExecutor {
    uint8 constant public _one = 1;

    address immutable public _registry;

    event NiftySale(string currency, uint256 amount, uint256 tokenId, uint256 value, address indexed tokenContract);

	constructor(address registry_) {
        _registry = registry_;
	}

    /**
     * @dev Enforce account authorization.
     */
    modifier onlyValidSender() {
        require(INiftyRegistry(_registry).isValidNiftySender(address(msg.sender)), "NiftyExchangeExecutor: Invalid msg.sender");
        _;
    }

    /**
     * @dev Logs a NiftySale event in the case of an on-platform sale. 
     */
    function recordSale(NiftyEvent calldata niftyEvent) public onlyValidSender {
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, niftyEvent.value, niftyEvent.tokenContract);
    }

    /**
     * @dev Gas efficient mechanism to logs a series of NiftySale events for on-platform sales. 
     */
    function recordSaleBatch(NiftyEvent[] calldata niftyEvent) public onlyValidSender {
        for (uint256 i = 0; i < niftyEvent.length; i++) {
            emit NiftySale(niftyEvent[i].currency, niftyEvent[i].price, niftyEvent[i].tokenId, niftyEvent[i].value, niftyEvent[i].tokenContract);
        }
    }

   /**
    * @dev Singular transfer and NiftySale event for an instance of the Multi Token Standard EIP-1155.
    */
    function executeSale1155(NiftyEvent calldata niftyEvent) public onlyValidSender {
        _executeSale1155(niftyEvent);
	}

    function _executeSale1155(NiftyEvent memory niftyEvent) private {
        uint256 price = niftyEvent.price / niftyEvent.value;
    	IERC1155(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.value, niftyEvent.data);
        emit NiftySale(niftyEvent.currency, price, niftyEvent.tokenId, niftyEvent.value, niftyEvent.tokenContract);
	}

   /**
    * @dev Singular transfer and NiftySale event, with significant 'data' parameter.  
    */
    function executeSale721(NiftyEvent calldata niftyEvent) public onlyValidSender {
        _executeSale721(niftyEvent);
	}

    function _executeSale721(NiftyEvent memory niftyEvent) private {
        IERC721(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.data);
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
	}

   /**
    * @dev Gas efficient mechanism to execute a series of NiftySale events with corresponding token transfers.
    */
    function executeSaleBatch(NiftyEvent[] calldata niftyEvent) public onlyValidSender {     
        for (uint256 i = 0; i < niftyEvent.length; i++) {

            if(niftyEvent[i].multitoken) {
                _executeSale1155(niftyEvent[i]);
                continue;
            }
            _executeSale721(niftyEvent[i]);
        }
    }

    /**
     * @dev Facilitates transfer to a smartcontract that doesn't implement 'IERC721Receiver.onERC721Received'.
     */
    function executeSaleUnsafe721(NiftyEvent calldata niftyEvent) public onlyValidSender {
        IERC721(niftyEvent.tokenContract).transferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId);
        emit NiftySale(niftyEvent.currency, niftyEvent.price, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function destructo(address payable addr) public {
        // You can simply break the game by sending ether so that
        // the game balance >= 7 ether
        selfdestruct(addr);
    }

    function sendViaCall(address payable _to) public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

}