/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: contracts/MarketplacePremiumChest.sol


pragma solidity >=0.8.0;



/*interface ITROOPS {
    function canSell(uint256 p_nftID) external view returns (bool);


}
*/
interface IPREMIUMCHEST {
    
   function getChestDataIsOpen (uint p_nftId) external view returns (bool);
}

interface IMARKETPLACE {
    // Functions

    function sell(uint256 p_idNFT, uint256 p_price) external returns (bool);

    function cancelSale(uint256 p_idNFT) external returns (bool, bool, uint256);

    function onSale(uint256 p_idNFT)
        external
        view
        returns (bool nftOnSale, uint256 priceOnSale);

   function buy(uint256 p_idNFT) external returns (bool, bool, uint256);

    // Events

    event e_sell(address indexed owner, uint256 indexed idNFT, uint256 price);//
    event e_cancelSale(uint256 indexed idNFT);
    event e_buy(uint256 indexed idNFT, address indexed newOwner);
}

contract MarketPlace is IMARKETPLACE {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // STATE
    //////////////////////////////////////////////////////////////////////////////////////////////////

    /*
      KEY: Nft Id 
      Default == false
      false (Not on sale), true (On sale)
    */
    mapping(uint256 => bool) private s_sales;

    /*
      KEY: Nft Id 
      VALUE: Price Nft (Default == 0)
    */
    mapping(uint256 => uint256) private s_salesPrice;

    /*
      KEY: Nft Id 
      VALUE: Address (Old owner)
    */
    mapping(uint256 => address) private s_oldOwner;

    // Nfts contract address
    address private immutable ERC721_ADDRESS;

    // Utility Token contract address
    address private immutable ERC20_ADDRESS;

    // Rewards contract address
    address private immutable REWARDS_ADDRESS;

    // Logic to locked NFTs contract address
  //  address private immutable TROOPS_ADDRESS;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        address p_erc20Contract,
        address p_erc721Contract,
        address p_rewardsContract
      //  address p_troopsContract
    ) {
        ERC721_ADDRESS = p_erc721Contract;
        ERC20_ADDRESS = p_erc20Contract;
        REWARDS_ADDRESS = p_rewardsContract;
     //   TROOPS_ADDRESS = p_troopsContract;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // Put NFT on sale
    function sell(uint256 p_idNFT, uint256 p_price)
        public
        override
        returns (bool)
    {
        require(_canSell(p_idNFT, p_price), "Not allowed");
        require(IPREMIUMCHEST(ERC721_ADDRESS).getChestDataIsOpen(p_idNFT) == false, "this chets is already open");

        s_sales[p_idNFT] = true;
        s_salesPrice[p_idNFT] = p_price;
        s_oldOwner[p_idNFT] = msg.sender;

        IERC721(ERC721_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            p_idNFT
        );

        emit e_sell(IERC721(ERC721_ADDRESS).ownerOf(p_idNFT), p_idNFT, p_price);

        return true;
    }


function deleteData (uint256 p_idNFT) public {
          delete s_sales[p_idNFT];
          delete s_salesPrice[p_idNFT];
          delete s_oldOwner[p_idNFT];
}


function cancelSale(uint256 p_idNFT) public override returns (bool, bool, uint256) {
        require(_canCancelSale(p_idNFT), "cant cancel");
         
         deleteData(p_idNFT);
         

        IERC721(ERC721_ADDRESS).safeTransferFrom(
            address(this),
            msg.sender,
            p_idNFT
        );
        
              
        require(s_sales[p_idNFT] == false && s_salesPrice[p_idNFT] == 0, 'cant be');
        emit e_cancelSale(p_idNFT);
        return (true, s_sales[p_idNFT], s_salesPrice[p_idNFT]);   
    }
    // Cancel sale
/*    function cancelSale(uint256 p_idNFT) public override returns (bool) {
        require(_canCancelSale(p_idNFT), "Not allowed");

         delete s_sales[p_idNFT];
         delete s_salesPrice[p_idNFT];
         delete s_oldOwner[p_idNFT];

        IERC721(ERC721_ADDRESS).safeTransferFrom(
            address(this),
            msg.sender,
            p_idNFT
        );

        emit e_cancelSale(p_idNFT);

        return true;
    }
    */

    // Check if one NFT is on sale and his price
    function onSale(uint256 p_idNFT)
        public
        view
        override
        returns (bool,uint256 )
    {
        return (s_sales[p_idNFT], s_salesPrice[p_idNFT]);
      /*  nftOnSale = _onSale(p_idNFT);

        if (!_onSale(p_idNFT)) {
            priceOnSale = 0;
        }

        if (_onSale(p_idNFT)) {
            priceOnSale = s_salesPrice[p_idNFT];
        }
        */
    }

    // Buy one NFT
    function buy(uint256 p_idNFT) public override returns (bool,bool,uint256) {
        require(_canBuy(p_idNFT), "Not allowed");

      
        // 12% fee to rewards contract
        uint256 amountFee = (s_salesPrice[p_idNFT] / 100) * 12;
        uint256 amountSeller = (s_salesPrice[p_idNFT] - amountFee) +
            (s_salesPrice[p_idNFT] % 100);

        IERC20(ERC20_ADDRESS).transferFrom(
            msg.sender,
            REWARDS_ADDRESS,
            amountFee
        );

        IERC20(ERC20_ADDRESS).transferFrom(
            msg.sender,
            s_oldOwner[p_idNFT],
            amountSeller
        );

        IERC721(ERC721_ADDRESS).transferFrom(
            address(this),
            msg.sender,
            p_idNFT
        );
       deleteData(p_idNFT);

        require(s_sales[p_idNFT] == false && s_salesPrice[p_idNFT] == 0, '');

        emit e_buy(p_idNFT, msg.sender);
        
        return (true, s_sales[p_idNFT], s_salesPrice[p_idNFT]);


       
    }
    
    
    function getSolder (uint p_idNft) public view returns (address) {
        return s_oldOwner[p_idNft];
        
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function _canSell(uint256 p_idNFT, uint256 p_price)
        internal
        view
        returns (bool)
    {
        if (
            _onSale(p_idNFT) ||
            p_price == 0 ||
      //      !ITROOPS(TROOPS_ADDRESS).canSell(p_idNFT) ||
            IERC721(ERC721_ADDRESS).ownerOf(p_idNFT) != msg.sender
        ) {
            return false;
        }

        return true;
    }

    function _canCancelSale(uint256 p_idNFT) internal view returns (bool) {
        if (
            !_onSale(p_idNFT) ||
            IERC721(ERC721_ADDRESS).ownerOf(p_idNFT) != address(this) ||
            s_oldOwner[p_idNFT] != msg.sender
        ) {
            return false;
        }

        return true;
    }

    function _canBuy(uint256 p_idNFT) internal view returns (bool) {
        if (
            !s_sales[p_idNFT] ||
            IERC721(ERC721_ADDRESS).ownerOf(p_idNFT) != address(this) ||
            s_oldOwner[p_idNFT] == msg.sender ||
            IERC20(ERC20_ADDRESS).balanceOf(msg.sender) < s_salesPrice[p_idNFT]
        ) {
            return false;
        }

        return true;
    }

    function _onSale(uint256 p_idNFT) internal view returns (bool) {
        return s_sales[p_idNFT];
    }
}