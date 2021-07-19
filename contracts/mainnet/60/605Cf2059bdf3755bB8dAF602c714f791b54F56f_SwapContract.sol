/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma experimental ABIEncoderV2;
pragma solidity 0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155  {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


contract SwapContract {

  struct Swap {
      
       string swapID; 
       address payable openTrader;
       address payable closeTrader;
       uint[] swapChoice;    // 0: ether, 1: erc20, 2:erc721, 3: erc1155
       address[] contractAddress;
       uint256[] swapValue;
       uint[] trader;  // 1: openTrader, 2: closeTrader
       uint256 States;  // 1: open, 2: closed, 3: expired
       uint256 swapDate;
       mapping (address => uint256) ERC1155Value;  
     
  }

  mapping (string => Swap) private swaps;
  string[] private swapList;


   constructor()  {
       
   }
   
  
  function openERC20(string memory _swapID, uint256 _openValueERC20, address _openContractAddress, address payable _closeTrader) public {
       
             IERC20 openERC20Contract = IERC20(_openContractAddress);
           //  uint256 val = _openValueERC20*1000000000000000000;
             openERC20Contract.transferFrom(msg.sender, address(this), _openValueERC20);
             bytes memory identifiant = bytes(swaps[_swapID].swapID);

        if(identifiant.length == 0) {
             swaps[_swapID].swapID = _swapID;
      
      swaps[_swapID].openTrader = payable(msg.sender);
      
      swaps[_swapID].closeTrader = _closeTrader;
      swaps[_swapID].States = 1;
       swapList.push(_swapID);
        }
      swaps[_swapID].swapChoice.push(1);
      
      swaps[_swapID].contractAddress.push(_openContractAddress);
      
      swaps[_swapID].swapValue.push(_openValueERC20);
      
      swaps[_swapID].trader.push(1);
      
  }
  
   function openERC721(string memory _swapID, uint256 _openIdERC721, address _openContractAddress, address payable _closeTrader) public {
       
             IERC721 openERC721Contract = IERC721(_openContractAddress);
             openERC721Contract.transferFrom(msg.sender, address(this), _openIdERC721);
             bytes memory identifiant = bytes(swaps[_swapID].swapID);

        if(identifiant.length == 0) {
                  swaps[_swapID].swapID = _swapID;
      
      swaps[_swapID].openTrader = payable(msg.sender);
      
      swaps[_swapID].closeTrader = _closeTrader;
      swaps[_swapID].States = 1;
       swapList.push(_swapID);
        }

      
      swaps[_swapID].swapChoice.push(2);
      
      swaps[_swapID].contractAddress.push(_openContractAddress);
      
      swaps[_swapID].swapValue.push(_openIdERC721);
      
      swaps[_swapID].trader.push(1);
      
      
  }
   
   
   function openERC1155(string memory _swapID, uint256 _openValueERC1155, uint256 _openIdERC1155, address _openContractAddress, address payable  _closeTrader, bytes calldata _data) public {
       
              IERC1155  openERC1155Contract = IERC1155(_openContractAddress);
             openERC1155Contract.safeTransferFrom(msg.sender, address(this),_openIdERC1155, _openValueERC1155, _data);
            bytes memory identifiant = bytes(swaps[_swapID].swapID);

        if(identifiant.length == 0) {
             swaps[_swapID].swapID = _swapID;
      
      swaps[_swapID].openTrader = payable(msg.sender);
      
      swaps[_swapID].closeTrader = _closeTrader;
       swaps[_swapID].States = 1;
        swapList.push(_swapID);
        }
     
      
      swaps[_swapID].swapChoice.push(3);
      
      swaps[_swapID].contractAddress.push(_openContractAddress);
      
      swaps[_swapID].swapValue.push(_openIdERC1155);
      
      swaps[_swapID].ERC1155Value[_openContractAddress] = _openValueERC1155;
      
      swaps[_swapID].trader.push(1);
      
     
   
    
      
  }
   
  
   function closeERC20(string memory _swapID, uint256 _closeValueERC20, address _closeContractAddress) public  {
       
       
        IERC20 closeERC20Contract = IERC20(_closeContractAddress);
        
        closeERC20Contract.transferFrom(msg.sender, address(this), _closeValueERC20);
        
        swaps[_swapID].swapChoice.push(1);
      
        swaps[_swapID].contractAddress.push(_closeContractAddress);
      
        swaps[_swapID].swapValue.push(_closeValueERC20);
        
        swaps[_swapID].trader.push(2);
        swaps[_swapID].States = 2;
        

  }
  
   function closeER721(string memory _swapID, uint256 _closeIdERC721, address _closeContractAddress) public  {
       
           IERC721 closeERC721Contract = IERC721(_closeContractAddress);
           
           closeERC721Contract.transferFrom(swaps[_swapID].closeTrader, address(this), _closeIdERC721);
           
           swaps[_swapID].swapChoice.push(2);
      
           swaps[_swapID].contractAddress.push(_closeContractAddress);
      
           swaps[_swapID].swapValue.push(_closeIdERC721);
           
           swaps[_swapID].trader.push(2);
           swaps[_swapID].States = 2;
        
  }
   
    function closeERC1155(string memory _swapID, uint256 _closeIdERC1155, uint256 _closeValueERC1155, address _closeContractAddress, bytes calldata _data) public  {
       
           IERC1155 closeERC1155Contract = IERC1155(_closeContractAddress);
           
           closeERC1155Contract.safeTransferFrom(swaps[_swapID].closeTrader,address(this), _closeIdERC1155, _closeValueERC1155, _data);
           
           swaps[_swapID].swapChoice.push(3);
      
           swaps[_swapID].contractAddress.push(_closeContractAddress);
      
           swaps[_swapID].swapValue.push(_closeIdERC1155);
      
           swaps[_swapID].ERC1155Value[_closeContractAddress] = _closeValueERC1155;
           
           swaps[_swapID].trader.push(2);
           swaps[_swapID].States = 2;
      
  }
  
  function finalClose(string memory _swapID, bytes calldata _data) public  {
     
      
        for(uint256 i=0; i<swaps[_swapID].swapChoice.length; i++) {
                 if(swaps[_swapID].swapChoice[i] == 1) {
                       IERC20 closeERC20Contract = IERC20(swaps[_swapID].contractAddress[i]);
                   if(swaps[_swapID].trader[i] == 1) {
                       
                        closeERC20Contract.transfer(swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i]);
                        
                   } else if(swaps[_swapID].trader[i] == 2) {
                       
                        closeERC20Contract.transfer(swaps[_swapID].openTrader, swaps[_swapID].swapValue[i]);
                        
                   }
            
           
                 } else if(swaps[_swapID].swapChoice[i] == 2) {
                         IERC721 closeERC721Contract = IERC721(swaps[_swapID].contractAddress[i]);
                            if(swaps[_swapID].trader[i] == 1) {
                                
                              closeERC721Contract.transferFrom(address(this), swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i]);
              
                          } else if(swaps[_swapID].trader[i] == 2) {
                              closeERC721Contract.transferFrom(address(this), swaps[_swapID].openTrader, swaps[_swapID].swapValue[i]);
                             }
                 } else if(swaps[_swapID].swapChoice[i] == 3) {
                     
          uint256 value = swaps[_swapID].ERC1155Value[swaps[_swapID].contractAddress[i]];
          IERC1155 closeERC1155Contract = IERC1155(swaps[_swapID].contractAddress[i]);
           if(swaps[_swapID].trader[i] == 1) {
               
                         closeERC1155Contract.safeTransferFrom(address(this), swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i], value, _data);

           } else if(swaps[_swapID].trader[i] == 2) {
               
                         closeERC1155Contract.safeTransferFrom(address(this), swaps[_swapID].openTrader, swaps[_swapID].swapValue[i], value, _data);
           }
          
      }
        }
          swaps[_swapID].swapDate = block.timestamp;
          swaps[_swapID].States = 3;
  
  }


function expire(string memory _swapID, bytes calldata _data) public payable {
     
      
        for(uint256 i=0; i<swaps[_swapID].swapChoice.length; i++) {
            
                  if(swaps[_swapID].swapChoice[i] == 0) {
                       if(swaps[_swapID].trader[i] == 1) {
                           
                           address payable openTraderr = swaps[_swapID].openTrader;
       
                           openTraderr.transfer(msg.value);
                           
                       } else if(swaps[_swapID].trader[i] == 2) { 
                           
                           address payable closeTraderr = swaps[_swapID].closeTrader;
       
                           closeTraderr.transfer(msg.value);
                           
                       }
                     
                      
                  } else if(swaps[_swapID].swapChoice[i] == 1) {
                       IERC20 closeERC20Contract = IERC20(swaps[_swapID].contractAddress[i]);
                   if(swaps[_swapID].trader[i] == 1) {
                       
                        closeERC20Contract.transfer(swaps[_swapID].openTrader, swaps[_swapID].swapValue[i]);
                        
                   } else if(swaps[_swapID].trader[i] == 2) {
                       
                        closeERC20Contract.transfer(swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i]);
                        
                   }
            
           
                 } else if(swaps[_swapID].swapChoice[i] == 2) {
                         IERC721 closeERC721Contract = IERC721(swaps[_swapID].contractAddress[i]);
                            if(swaps[_swapID].trader[i] == 1) {
                                
                              closeERC721Contract.transferFrom(address(this), swaps[_swapID].openTrader, swaps[_swapID].swapValue[i]);
              
                          } else if(swaps[_swapID].trader[i] == 2) {
                  
                              closeERC721Contract.transferFrom(address(this), swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i]);
                  
                             }
   


                 } else if(swaps[_swapID].swapChoice[i] == 3) {
                     
          uint256 value = swaps[_swapID].ERC1155Value[swaps[_swapID].contractAddress[i]];
          IERC1155 closeERC1155Contract = IERC1155(swaps[_swapID].contractAddress[i]);
           if(swaps[_swapID].trader[i] == 1) {
               
                         closeERC1155Contract.safeTransferFrom(address(this), swaps[_swapID].openTrader, swaps[_swapID].swapValue[i], value, _data);

           } else if(swaps[_swapID].trader[i] == 2) {
               
                         closeERC1155Contract.safeTransferFrom(address(this), swaps[_swapID].closeTrader, swaps[_swapID].swapValue[i], value, _data);

           }
          
          
          
      }
        }

          swaps[_swapID].States = 4;
  
  }


   function getSwapList() public view returns (uint256) {
       return swapList.length;
       
   }
   function getSwapsId() public view returns (string [] memory ) {
     return swapList;
   }
 
   function checkSwap(string memory _swapID) public view returns (string memory swapId, address closeTrader, address openTrader, uint256 States, uint256 date) {
   return (swaps[_swapID].swapID, swaps[_swapID].closeTrader, swaps[_swapID].openTrader, swaps[_swapID].States, swaps[_swapID].swapDate);
    //Swap memory swap = swaps[_swapID];
   // return (swap.swapID, swap.closeTrader, swap.openTrader, swap.States, swap.swapDate);
  }
  
   function gettrCaSvSc(string memory _swapID)public view returns( uint  [] memory, address  [] memory, uint256  [] memory, uint  [] memory){
    return (swaps[_swapID].trader, swaps[_swapID].contractAddress, swaps[_swapID].swapValue, swaps[_swapID].swapChoice);
}
function getValERC11(string memory _swapID, address contractAddress) public view returns(uint256) {
    
    return(swaps[_swapID].ERC1155Value[contractAddress]);
}


   
}