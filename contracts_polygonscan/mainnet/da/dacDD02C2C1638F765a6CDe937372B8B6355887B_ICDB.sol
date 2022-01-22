/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Fully commented standard ERC721 Distilled from OpenZeppelin Docs
    Base for Building ERC721 by Martin McConnell
    All the utility without the fluff.
*/


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    //@dev Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //@dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //@dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //@dev Returns the number of tokens in ``owner``'s account.
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
    function safeTransferFrom(address from,address to,uint256 tokenId) external;

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
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    //@dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
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

interface IERC721Metadata is IERC721 {
    //@dev Returns the token collection name.
    function name() external view returns (string memory);

    //@dev Returns the token collection symbol.
    function symbol() external view returns (string memory);

    //@dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
    address private _game;

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

    modifier ownerAndGame() {
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

    function _setGame(address newOwner) private {
        address oldOwner = _game;
        _game = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt to reenter a locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
    function safeTransferFrom(address from,address to,uint256 tokenId) external{}
    function transferFrom(address from, address to, uint256 tokenId) external{}
    function approve(address to, uint256 tokenId) external{}
    function getApproved(uint256 tokenId) external view returns (address operator){}
    function setApprovalForAll(address operator, bool _approved) external{}
    function isApprovedForAll(address owner, address operator) external view returns (bool){}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{}
}

interface ERC721Enumerable {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


// ******************************************************************************************************************************
// **************************************************  Start of Main Contract ***************************************************
// ******************************************************************************************************************************

struct CollectionData {
    address wallet;
    uint256 score;
    uint256[] completed;
}

contract ICDB is IERC721, Ownable, Functional {

    using Address for address;
    event CollectionCompleted(address indexed to, uint256 collectionId, uint256 score);
    event Traded(address indexed to, uint256[] tokenIds);
    event Minted(address indexed to, uint256 pack);
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    // URI Root Location for Json Files
    string private _baseURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Specific Functionality
    bool public mintActive;
    bool private _hideTokens;  //for URI redirects
    uint256 public price;
    uint256 public price3;
    uint256 public price5;
    uint256 public totalTokens;
    uint256 public numberMinted;
    uint256 public maxPerWallet;
    uint256 public reservedTokens;

    mapping(address => uint256) private _tokensMintedby;
    mapping(address => uint256[]) private _collectionsCompleted;
    mapping(address => uint256) private _collectionScore;

    address dev               = payable(0x3782eA4700a17671f73076F90B7EbD13F107E600);
    address community         = payable(0x9FaDD6d4D475bE9FA3bf30857A099A63B97FA241);
    address marketing         = payable(0xcb400C972f2939c322FCdF8f0bdbBDE2039970B1);
    address cofounder         = payable(0xA7Af8028951367cfC983922844309e1d5b5fc6ce);
    address gameWallet        = address(0x0e89Fe6B3153E6eb69ec42cF94317309d9977F59);

    address venlyWallet       = payable(0x01BFC2bB0078F8B0bFbA88B0bC155dbc86da8597);
    address venlyWallet2      = payable(0x193A8Ce649147428F282b0d25EfF89fFc0F51C87);

    address supporter         = payable(0x193A8Ce649147428F282b0d25EfF89fFc0F51C87);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {
        _name = "ICDB NFT";
        _symbol = "ICDB";
        _baseURI = "https://www.icdb.io/metadata/";
        _hideTokens = true;
        
        totalTokens = 10000; // 0-9999
        price = 10 * (10 ** 18);
        price3 = 25 * (10 ** 18);
        price5 = 40 * (10 ** 18);
        maxPerWallet = 60;
        reservedTokens = 300; // reserved for giveaways and such

    }

    //@dev See {IERC165-supportsInterface}. Interfaces Supported by this Standard
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return  interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                interfaceId == type(IERC165).interfaceId ||
                interfaceId == ICDB.onERC721Received.selector;
    }
    
    // Standard Withdraw function for the owner to pull the contract
    function withdraw() external onlyOwner {
        uint256 sendAmount = address(this).balance;
        
        bool success;
        (success, ) = dev.call{value: ((sendAmount * 25)/100)}("");
        require(success, "Transaction Unsuccessful");
        
        (success, ) = community.call{value: ((sendAmount * 20)/100)}("");
        require(success, "Transaction Unsuccessful");
        
        (success, ) = marketing.call{value: ((sendAmount * 20)/100)}("");
        require(success, "Transaction Unsuccessful");
        
        (success, ) = cofounder.call{value:  ((sendAmount * 25)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = venlyWallet.call{value:  ((sendAmount * 2)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = venlyWallet2.call{value:  ((sendAmount * 3)/100)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = supporter.call{value:  ((sendAmount * 5)/100)}("");
        require(success, "Transaction Unsuccessful");
    
     }

    

    function ownerMint(address _to, uint256 qty) external reentryLock {
        require(_msgSender() == owner() || _msgSender() == gameWallet, "Only the owner or the game can mint tokens");
        require((numberMinted + qty) > numberMinted, "Math overflow error");
        require(qty > 0, "Cannot mint 0 tokens");
        // Game can always mint!
        if((numberMinted + qty) < totalTokens) {
            totalTokens++;
        }
        
        uint256 mintSeedValue = numberMinted; //Store the starting value of the mint batch
        if (reservedTokens >= qty) {
            reservedTokens -= qty;
        } else {
            reservedTokens = 0;
        }
        
        for(uint256 i = 0; i < qty; i++) {
            _safeMint(_to, mintSeedValue + i);
            numberMinted ++;  //reservedTokens can be reset, numberMinted can not
        }
    }
    
    function airDrop(address[] memory _to) external onlyOwner {
        uint256 qty = _to.length;
        require((numberMinted + qty) > numberMinted, "Math overflow error");
        require((numberMinted + qty) < totalTokens, "Cannot fill order");
        
        uint256 mintSeedValue = numberMinted;
        if (reservedTokens >= qty) {
            reservedTokens -= qty;
        } else {
            reservedTokens = 0;
        }
        
        for(uint256 i = 0; i < qty; i++) {
            _safeMint(_to[i], mintSeedValue + i);
            numberMinted ++;  //reservedTokens can be reset, numberMinted can not
        }
    }

    function mint(uint256 packtype, uint256 amount) external payable reentryLock {
        
        require(packtype == 1 || packtype == 3 || packtype == 5, "Packtype must be 1,3 or 5");
        uint256 qty = 1 * packtype * amount;

        require((qty + reservedTokens + numberMinted) < totalTokens, "Mint: Not enough avaialability");
        require((_tokensMintedby[_msgSender()] + qty) <= maxPerWallet, "Mint: Max tokens per wallet exceeded");


        uint256 mintPrice = price;
        if(packtype == 1) {
            mintPrice = price;
        } else if(packtype == 2) {
            mintPrice = price3;
        } else if(packtype == 3) {
            mintPrice = price5;
        }
        
       
        require(msg.value >= qty * mintPrice, "Mint: Insufficient Funds");
        
        uint256 mintSeedValue = numberMinted; //Store the starting value of the mint batch
        
        //Handle ETH transactions
        uint256 cashIn = msg.value;
        uint256 cashChange = cashIn - (qty * mintPrice);
        
        //send tokens
        for(uint256 i = 0; i < qty; i++) {
            _safeMint(_msgSender(), mintSeedValue + i);
            numberMinted ++;
            _tokensMintedby[_msgSender()] ++;
        }
                
        if (cashChange > 0){
            (bool success, ) = msg.sender.call{value: cashChange}("");
            require(success, "Mint: unable to send change to user");
        }

        emit Minted(_msgSender(), packtype);
    }

    function trade(uint256[] memory token) external {
        require((reservedTokens + numberMinted) < totalTokens, "Mint: Not enough availability");
        require(token.length == 3, "Trade: can only trade 3 token at once");
        for (uint256 i; i < token.length; i++) {
            require(ownerOf(token[i]) == _msgSender(), "You don't own the token!");
            // Transfer to trade wallet
            transferFrom(_msgSender(), address(0x9FaDD6d4D475bE9FA3bf30857A099A63B97FA241), token[i]);
        }
        uint256 mintSeedValue = numberMinted; //Store the starting value of the mint batch
        _mint(_msgSender(), mintSeedValue + 1);
        numberMinted ++;
        emit Traded(_msgSender(), token);
    }

    function gameMint(address to, uint256 qty) external reentryLock {
        require((_msgSender() == gameWallet), "Game Wallet Only");
        require((numberMinted + qty) > numberMinted, "Math overflow error");
        require((numberMinted + qty) < totalTokens, "Cannot fill order");
        
        uint256 mintSeedValue = numberMinted; //Store the starting value of the mint batch
        if (reservedTokens >= qty) {
            reservedTokens -= qty;
        } else {
            reservedTokens = 0;
        }
        
        for(uint256 i = 0; i < qty; i++) {
            _safeMint(to, mintSeedValue + i);
            numberMinted ++;  //reservedTokens can be reset, numberMinted can not
        }
    }

    function completeCollection(address to, uint256 collectionId, uint256 score) external reentryLock {
         require((_msgSender() == gameWallet), "Game Wallet Only");
        _collectionsCompleted[to].push(collectionId);
        _collectionScore[to] = _collectionScore[to] + score;
        emit CollectionCompleted(to, collectionId, score);

    }
    
    // Safe transfer from one address to another, used in top trumps part to transfer cards
    // to the winner
    function gameTransfer(uint256 tokenId, address from, address to) external reentryLock {
        require((_msgSender() == gameWallet), "Game Wallet Only");
        require(ownerOf(tokenId) == from, "From does not own the token!");
        transferFrom(from, to, tokenId);
    }

    //////////////////////////////////////////////////////////////
    //////////////////// Setters and Getters /////////////////////
    //////////////////////////////////////////////////////////////
    
    function collectionCompleted(address to) public view returns (uint256) {
        return _collectionsCompleted[to].length;
    }
    function collectionInfo(address to) public view returns (uint256) {
        return _collectionScore[to];
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        _baseURI = newURI;
    }
    
    function activateMint() public onlyOwner {
        mintActive = true;
    }
    
    function deactivateMint() public onlyOwner {
        mintActive = false;
    }

    function setPrice(uint256 single, uint256 tripple, uint256 five) public onlyOwner {
        price = single;
        price3 = tripple;
        price5 = five;
    }
    
    function setTotalTokens(uint256 numTokens) public onlyOwner {
        totalTokens = numTokens;
    }

    function totalSupply() external view returns (uint256) {
        return numberMinted; //stupid bs for etherscan's call
    }
    
    function hideTokens() external onlyOwner {
        _hideTokens = true;
    }
    
    function revealTokens() external onlyOwner {
        _hideTokens = false;
    }
    
    function getBalance(address tokenAddress) view external returns (uint256) {
        //return _balances[tokenAddress]; //shows 0 on etherscan due to overflow error
        return _balances[tokenAddress] / (10**15); //temporary fix to report in finneys
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    // *********************** ERC721 Token Receiver **********************
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
        //InterfaceID=0x150b7a02
        return this.onERC721Received.selector;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    // **************************************** Metadata Standard Functions **********
    //@dev Returns the token collection name.
    function name() external view returns (string memory){
        return _name;
    }

    //@dev Returns the token collection symbol.
    function symbol() external view returns (string memory){
        return _symbol;
    }

    //@dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) external view returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory tokenuri;
        
        if (_hideTokens) {
            //redirect to mystery box
            tokenuri = string(abi.encodePacked(_baseURI, "mystery.json"));
        } else {
            //Input flag data here to send to reveal URI
            tokenuri = string(abi.encodePacked(_baseURI, toString(tokenId), ".json")); /// 0.json 135.json
        }
        
        return tokenuri;
    }
    
    function contractURI() public view returns (string memory) {
            return string(abi.encodePacked(_baseURI,"contract.json"));
    }
    // *******************************************************************************


    receive() external payable {}
    
    fallback() external payable {}
}