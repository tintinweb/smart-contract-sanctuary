// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
}

interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

interface INiftyRegistry {
   function isValidNiftySender(address sending_key) external view returns (bool);
}

/**
 *
 */
contract NiftyExchangeExecutor {
    address immutable public _registry;
    uint8 immutable public _one;

    struct NiftyEvent {
        string currency;
        uint256 amount; 
        uint256 tokenId;
        uint256 value;
        address tokenContract;
        address buyer;
        address seller;
        bytes data;
    }

    event NiftySale(string currency, uint256 amount, uint256 tokenId, uint256 value, address indexed tokenContract);

	constructor(address registry_) {
        _registry = registry_;
        _one = 1;
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
        emit NiftySale(niftyEvent.currency, niftyEvent.amount, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
    }

    /**
     * @dev Gas efficient mechanism to logs a series of NiftySale events for on-platform sales. 
     */
    function recordSaleBatch(NiftyEvent[] calldata niftyEvent) public onlyValidSender {
        for (uint256 i = 0; i < niftyEvent.length; i++) {
            emit NiftySale(niftyEvent[i].currency, niftyEvent[i].amount, niftyEvent[i].tokenId, _one, niftyEvent[i].tokenContract);
        }
    }

    /**
     * @dev Facilitates transfer to a smartcontract that doesn't implement 'IERC721Receiver.onERC721Received'.
     */
    function executeSaleTransfer(NiftyEvent calldata niftyEvent) public onlyValidSender {
        IERC721(niftyEvent.tokenContract).transferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId);
        emit NiftySale(niftyEvent.currency, niftyEvent.amount, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
    }

   /**
    * @dev Gas efficient mechanism to execute a series of NiftySale events with corresponding token transfers.
    */
    function executeSaleSafeTransferBatch(NiftyEvent[] calldata niftyEvent) public onlyValidSender {     
        for (uint256 i = 0; i < niftyEvent.length; i++) {
            IERC721(niftyEvent[i].tokenContract).safeTransferFrom(niftyEvent[i].seller, niftyEvent[i].buyer, niftyEvent[i].tokenId);
            emit NiftySale(niftyEvent[i].currency, niftyEvent[i].amount, niftyEvent[i].tokenId, _one, niftyEvent[i].tokenContract);
        }
    }

   /**
    * @dev Singular transfer and NiftySale event, with significant 'data' parameter.  
    */
    function executeSaleSafeTransfer(NiftyEvent calldata niftyEvent) public onlyValidSender {
        IERC721(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.data);
        emit NiftySale(niftyEvent.currency, niftyEvent.amount, niftyEvent.tokenId, _one, niftyEvent.tokenContract);
	}

    function executeSaleMultiToken(NiftyEvent calldata niftyEvent) public onlyValidSender {
    	IERC1155(niftyEvent.tokenContract).safeTransferFrom(niftyEvent.seller, niftyEvent.buyer, niftyEvent.tokenId, niftyEvent.value, niftyEvent.data);
        emit NiftySale(niftyEvent.currency, niftyEvent.amount, niftyEvent.tokenId, niftyEvent.value, niftyEvent.tokenContract);
	}

}