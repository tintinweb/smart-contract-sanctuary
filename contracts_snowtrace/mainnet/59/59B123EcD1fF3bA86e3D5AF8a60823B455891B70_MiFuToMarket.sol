/**
 *Submitted for verification at snowtrace.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
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




/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}




/**
 * @dev Collection of functions related to the address type
 */
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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








/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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




/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}






contract MiFuToMarket is Ownable,Pausable{
    
    
    uint256 public constant MAX_TOKENS = 10000;
    
    
    address nftMainContractAddress = address(0x276e5D147fb855938815de63bb6910A7dE10249f);
    
    
    uint8[MAX_TOKENS] public tiers;
    
    
    struct TokenIdentifier{
        address nftContractAddress;
        uint256 tokenId;
    }
    
    struct Sale{
        uint256 enumIndex;
        uint256 price;
        address seller;
        address nftContractAddress;
        uint256 tokenId;
    }
    
    
    struct NFTCollection{
        
        uint256 enumIndex;
        uint256 tokensForSale;
        address nftContractAddress;
        
    }
    
    
    
    mapping(address => mapping(uint256 => Sale)) public sales;
    
    TokenIdentifier[] public salesEnumeration;
    
    
    
    
    
    mapping(address => NFTCollection) public collections;
    
    address[] public collectionsEnumeration;
    
    
    
    
    
    mapping(uint256 => uint256) public withdrawnBalancesForToken;
    
    
    
    uint256 public statAllTimeMaxBuyPrice;
    uint256 public statSoldTokens;
    
    

    
    
    address public approvedAuxContractAddress;
    
    function setApprovedAuxContractAddress(address _contractAddress) public onlyOwner{
        approvedAuxContractAddress = _contractAddress;
    }
    
    modifier onlyAuxContract(){
        require((_msgSender()==approvedAuxContractAddress) && (approvedAuxContractAddress!=address(0)),"Denied: caller is not the aux contract");
        _;
    }
    
    
    
    
    // filters=0 ---> no filters
    // if filterTier is set, filterCollection is ignored
    function getGlobalMarketStats(address filterCollection, uint8 filterTier) public view returns (uint256[4] memory retArray){
        
        retArray[0] = 1000000000000000000000000; // 1000000 AVAX
        retArray[1] = 0;
        retArray[2] = statAllTimeMaxBuyPrice;
        retArray[3] = statSoldTokens;
        
        if(salesNumber() == 0){
            return retArray;
        }
        
        if(filterCollection==address(0) && filterTier==0){
            
            for(uint256 i = 0; i < salesNumber(); i++){
            
                Sale memory currentSale = getIthSale(i);
                    
                if(retArray[0] > currentSale.price){
                    retArray[0] = currentSale.price;
                }
                if(retArray[1] < currentSale.price){
                    retArray[1] = currentSale.price;
                }
                
            }
            
        }else if(filterTier!=0){
            
            for(uint256 i = 0; i < salesNumber(); i++){
            
                Sale memory currentSale = getIthSale(i);
                
                if(currentSale.nftContractAddress == nftMainContractAddress){
                    
                    uint8 tier = tiers[currentSale.tokenId];
                    
                    if(tier == filterTier){
                        
                        if(retArray[0] > currentSale.price){
                            retArray[0] = currentSale.price;
                        }
                        if(retArray[1] < currentSale.price){
                            retArray[1] = currentSale.price;
                        }
                        
                    }

                }
                
            }
            
        }else if(filterCollection!=address(0)){
            
            for(uint256 i = 0; i < salesNumber(); i++){
            
                Sale memory currentSale = getIthSale(i);
                
                if(currentSale.nftContractAddress == filterCollection){
                    
                    if(retArray[0] > currentSale.price){
                        retArray[0] = currentSale.price;
                    }
                    if(retArray[1] < currentSale.price){
                        retArray[1] = currentSale.price;
                    }
                    
                }
                
            }
            
        }
        
        return retArray;
        
    }
    
    
    
    function collectionsNumber() public view returns (uint256){
        return collectionsEnumeration.length;
    }
    
    function salesNumber() public view returns (uint256){
        return salesEnumeration.length;
    }
    
    
    
    
    
    function _insertCollectionInList(address nftContractAddress) internal{
        
        uint256 index = collectionsEnumeration.length;
        
        collections[nftContractAddress] = NFTCollection({
            enumIndex: index,
            tokensForSale: 0,
            nftContractAddress: nftContractAddress
        });
        
        collectionsEnumeration.push(nftContractAddress);
        
    }
    
    
    function _removeCollectionFromList(address nftContractAddress) internal{
        
        require(collections[nftContractAddress].nftContractAddress != address(0), "Collection is not in array");
        
        uint256 lastIndex = collectionsEnumeration.length-1;
        
        uint256 collectionIndex = collections[nftContractAddress].enumIndex;
        
        if(collectionIndex != lastIndex){
            
            address lastCollectionAddress = collectionsEnumeration[lastIndex];
            
            collectionsEnumeration[collectionIndex] = lastCollectionAddress;
            
            collections[lastCollectionAddress].enumIndex = collectionIndex;
            
        }
        
        delete collections[nftContractAddress];
        collectionsEnumeration.pop();
        
    }
    
    
    
    
    
    
    
    
    
    function _insertSaleInList(address nftContractAddress, uint256 tokenId, uint256 price, address seller) internal{
        
        require(price > 0, "Price must be > 0");
        
        require(sales[nftContractAddress][tokenId].price==0, "This NFT is already for sale");

        uint256 index = salesEnumeration.length;
        
        sales[nftContractAddress][tokenId] = Sale({
            enumIndex: index,
            price: price,
            seller: seller,
            nftContractAddress: nftContractAddress,
            tokenId: tokenId
        });
        
        salesEnumeration.push(
            TokenIdentifier({
                nftContractAddress: nftContractAddress,
                tokenId: tokenId
            }) 
        );
        
        
        if(collections[nftContractAddress].nftContractAddress == address(0)){
            
            _insertCollectionInList(nftContractAddress);
            
        }
        
        collections[nftContractAddress].tokensForSale ++;
        
    }
    
    
    function _removeSaleFromList(address nftContractAddress, uint256 tokenId) internal{
        
        require(sales[nftContractAddress][tokenId].price>0, "This NFT is not for sale or not exists");
        
        uint256 lastIndex = salesEnumeration.length-1;
        
        uint256 tokenIndex = sales[nftContractAddress][tokenId].enumIndex;
        
        if(tokenIndex != lastIndex){
            
            TokenIdentifier memory lastTokenIdentifier = salesEnumeration[lastIndex];
            
            salesEnumeration[tokenIndex] = lastTokenIdentifier;
            
            sales[lastTokenIdentifier.nftContractAddress][lastTokenIdentifier.tokenId].enumIndex = tokenIndex;
            
        }
        
        delete sales[nftContractAddress][tokenId];
        salesEnumeration.pop();
        
        
        collections[nftContractAddress].tokensForSale --;
        
        
        if(collections[nftContractAddress].tokensForSale == 0){
            
            _removeCollectionFromList(nftContractAddress);
            
        }
        
    }
    
    
    
    
    
    
    function marketHasApprovalForToken(address nftContractAddress, uint256 tokenId, address owner) public view returns(bool){
        
        IERC721 nftContract = IERC721(nftContractAddress);
        
        return (nftContract.getApproved(tokenId)==address(this)) || nftContract.isApprovedForAll(owner, address(this));
        
    }
    
    
    function sellerIsOwner(address nftContractAddress, uint256 tokenId) public view returns(bool){
        
        IERC721 nftContract = IERC721(nftContractAddress);
        
        return nftContract.ownerOf(tokenId)==sales[nftContractAddress][tokenId].seller;
        
    }
    
    
    
    
    
    
    
    
    function addSale(address nftContractAddress, uint256 tokenId, uint256 price) external whenNotPaused{
        
        IERC721 nftContract = IERC721(nftContractAddress);
        
        require(nftContract.ownerOf(tokenId)==_msgSender(), "You are not the owner of this NFT");
        
        require(marketHasApprovalForToken(nftContractAddress, tokenId, _msgSender()), "You must first approve the market's contract to handle your NFT");
        
        _insertSaleInList(nftContractAddress, tokenId, price, _msgSender());
        
    }
    
    
    function addSaleAuxContract(address nftContractAddress, uint256 tokenId, uint256 price, address seller) public onlyAuxContract{
        
        _insertSaleInList(nftContractAddress, tokenId, price, seller);
        
    }
    
    
    
    function removeSale(address nftContractAddress, uint256 tokenId) public whenNotPaused{
        
        IERC721 nftContract = IERC721(nftContractAddress);
        
        require(nftContract.ownerOf(tokenId)==_msgSender(), "You are not the owner of this NFT");
        
        _removeSaleFromList(nftContractAddress, tokenId);
        
    }
    
    
    
    function removeSaleAuxContract(address nftContractAddress, uint256 tokenId) public onlyAuxContract{
        
        _removeSaleFromList(nftContractAddress, tokenId);
        
    }
    
    


    function setWithdrawnBalancesForToken(uint256 tokenId, uint256 withdrawnBalance) public onlyAuxContract{

        withdrawnBalancesForToken[tokenId] = withdrawnBalance;
        
    }




    
    
    
    
    function buyTokenInSale(address nftContractAddress, uint256 tokenId) public payable whenNotPaused{
        
        require(sales[nftContractAddress][tokenId].price == msg.value, "Wrong price");
        
        
        IERC721 nftContract = IERC721(nftContractAddress);
        
        
        require(sales[nftContractAddress][tokenId].price>0, "This NFT is not for sale");
        
        require(sellerIsOwner(nftContractAddress, tokenId), "Seller of this NFT is not its owner anymore (maybe this NFT was sold elsewhere)");
        
        require( marketHasApprovalForToken(nftContractAddress, tokenId, sales[nftContractAddress][tokenId].seller), "The seller revoked market approval for this NFT");
        
        
        require(sales[nftContractAddress][tokenId].seller != _msgSender(), "You are trying to buy a NFT you already own");
        
        
        address _seller = sales[nftContractAddress][tokenId].seller; 
        
        
        _removeSaleFromList(nftContractAddress, tokenId);
        
        
        nftContract.safeTransferFrom(_seller, _msgSender(), tokenId);
        
        
        uint256 fees = msg.value / globalFeeDivider;
        
        splitReflection(fees);
        
        
        payable(_seller).transfer(msg.value-fees);
        
        
        statSoldTokens ++;
        
        statAllTimeMaxBuyPrice = getMax256(statAllTimeMaxBuyPrice, msg.value);
        
    }
    
    
    
    
    
    function getMax256(uint256 a, uint256 b) pure internal returns(uint256){
        
        if(a>b) 
            return a;
        else 
            return b;
        
    }
    
    function getMin256(uint256 a, uint256 b) pure internal returns(uint256){
        
        if(a<b) 
            return a;
        else 
            return b;
        
    }
    
    
    
    
    
    
    function getIthCollection(uint256 i) public view returns(NFTCollection memory _collection){
        
        address collectionAddress = collectionsEnumeration[i];
        
        _collection = collections[collectionAddress];

        return _collection;
        
    }
    
    
    
    // Return a list of all collections
    function getCollectionsList(uint256 offset, uint256 maxItemsNumber) external view returns(NFTCollection[] memory _collections){
        
        require(offset <= collectionsNumber(), "offset must be <= collectionsNumber");
        
        uint256 itemsNumber = getMin256(maxItemsNumber, collectionsNumber()-offset);
        
        _collections = new NFTCollection[](itemsNumber);
        
        for(uint256 i = 0; i < itemsNumber; i++){
            
            _collections[i] = getIthCollection(i+offset);

        }
        
        return _collections;
        
    }
    
    
    
    
    
    
    
    
    function getIthSale(uint256 i) public view returns(Sale memory _sale){
        
        TokenIdentifier memory tokenIdentifier = salesEnumeration[i];
        
        _sale = sales[tokenIdentifier.nftContractAddress][tokenIdentifier.tokenId];

        return _sale;
        
    }
    
    
    
    // Return a list of all sales
    function getSalesList(uint256 offset, uint256 maxItemsNumber) external view returns(Sale[] memory _sales){
        
        require(offset <= salesNumber(), "offset must be <= salesNumber");
        
        uint256 itemsNumber = getMin256(maxItemsNumber, salesNumber()-offset);
        
        _sales = new Sale[](itemsNumber);
        
        for(uint256 i = 0; i < itemsNumber; i++){
            
            _sales[i] = getIthSale(i+offset);

        }
        
        return _sales;
        
    }
    
    
    // if tier > 0 , collectionAddress is ignored
    function getSalesListFiltered(uint256 offset, uint256 maxItemsNumber, address collectionAddress, uint8 tier) external view returns(Sale[] memory _sales){
        
        uint256 totalItems = salesNumber();
        
        uint256 foundItems = 0;
        
        uint256 maxFoundItems = offset+maxItemsNumber;
        
        Sale[] memory _salesTemp = new Sale[](maxItemsNumber);
        
        
        for(uint256 i = 0; (i<totalItems)&&(foundItems<maxFoundItems); i++){
            
            Sale memory currentSale = getIthSale(i);
            
            if( (currentSale.nftContractAddress==collectionAddress && tier==0) || (currentSale.nftContractAddress==nftMainContractAddress && tier==tiers[currentSale.tokenId]) ){
                
                if(foundItems >= offset){
                    
                    uint256 indexRet = foundItems-offset;
                    
                    _salesTemp[indexRet] = currentSale;
                    
                }
                
                foundItems++;
                
            }
            
        }
        
        
        uint256 retArrayLength = foundItems-offset;
        
        _sales = new Sale[](retArrayLength);
        
        for(uint256 j = 0; j<retArrayLength; j++){
            _sales[j] = _salesTemp[j];
        }
        
        return _sales;
        
    }
    
    
    
    
    
    
    
    
    uint256 public globalFeeDivider = 25; //4%
    
    uint256 public dividerTier1 = 32521; // 23% / 7480
    uint256 public multiplierTier2 = 5;
    uint256 public multiplierTier3 = 300;
    
    uint256 public quantityTokensTier1 = 7480;
    uint256 public quantityTokensTier2 = 2500;
    uint256 public quantityTokensTier3 = 20;
    
    
    
    function setReflectionParams(uint256 _globalFeeDivider,uint256 _dividerTier1,uint256 _multiplierTier2,uint256 _multiplierTier3,uint256 _quantityTokensTier1,uint256 _quantityTokensTier2,uint256 _quantityTokensTier3) external onlyOwner{
        
        globalFeeDivider = _globalFeeDivider;
    
        dividerTier1 = _dividerTier1;
        multiplierTier2 = _multiplierTier2;
        multiplierTier3 = _multiplierTier3;
    
        quantityTokensTier1 = _quantityTokensTier1;
        quantityTokensTier2 = _quantityTokensTier2;
        quantityTokensTier3 = _quantityTokensTier3;
    
    }
    
    
    
    uint256 public accumulatedRewardsForGroup1 = 0; // common
    uint256 public accumulatedRewardsForGroup2 = 0; // rare
    uint256 public accumulatedRewardsForGroup3 = 0; // legendary
    uint256 public totalRemainingFees = 0;    // market
    
    
    function splitReflection(uint256 fees) internal{
        
          uint256 rewardsForGroup1 = fees / dividerTier1;
          uint256 rewardsForGroup2 = rewardsForGroup1 * multiplierTier2;
          uint256 rewardsForGroup3 = rewardsForGroup1 * multiplierTier3;
        
          accumulatedRewardsForGroup1 += rewardsForGroup1;
          accumulatedRewardsForGroup2 += rewardsForGroup2;
          accumulatedRewardsForGroup3 += rewardsForGroup3;
          
          totalRemainingFees += fees - ((rewardsForGroup1*quantityTokensTier1)+(rewardsForGroup2*quantityTokensTier2)+(rewardsForGroup3*quantityTokensTier3));
          
    }
    
    
    
    
    
    function initTierList(uint256 iFrom, uint256 iToInclusive, uint8 tier) external onlyOwner{
        
        for(uint256 i = iFrom; i <= iToInclusive; i++){
            
            tiers[i] = tier;
            
        }

    }
    
    
    
    function balanceOf(address owner) public view returns (uint256){
        
        require(owner != address(0), "non-existent address");
        
        IERC721Enumerable nftContract = IERC721Enumerable(nftMainContractAddress);
        
        uint256 numTokens = nftContract.balanceOf(owner);
        
        uint256 balance = 0;
        
        for(uint256 i=0; i<numTokens; i++){
            
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(owner, i);
            
            if(tiers[tokenId]==1){
                
                balance += accumulatedRewardsForGroup1 - withdrawnBalancesForToken[tokenId];
                
            }else if(tiers[tokenId]==2){
                
                balance += accumulatedRewardsForGroup2 - withdrawnBalancesForToken[tokenId];
                
            }else if(tiers[tokenId]==3){
                
                balance += accumulatedRewardsForGroup3 - withdrawnBalancesForToken[tokenId];
                
            }
            
        }
        
        return balance;
        
    }
    
    
    function withdrawReward() public whenNotPaused{
        
        IERC721Enumerable nftContract = IERC721Enumerable(nftMainContractAddress);
        
        uint256 numTokens = nftContract.balanceOf(_msgSender());
        
        uint256 rewards = 0;
        
        for(uint256 i=0; i<numTokens; i++){
            
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(_msgSender(), i);
            
            uint256 tokenBalance = 0;
            
            if(tiers[tokenId]==1){
                
                tokenBalance = accumulatedRewardsForGroup1 - withdrawnBalancesForToken[tokenId];
                
            }else if(tiers[tokenId]==2){
                
                tokenBalance = accumulatedRewardsForGroup2 - withdrawnBalancesForToken[tokenId];
                
            }else if(tiers[tokenId]==3){
                
                tokenBalance = accumulatedRewardsForGroup3 - withdrawnBalancesForToken[tokenId];
                
            }
            
            withdrawnBalancesForToken[tokenId] += tokenBalance;
            
            rewards += tokenBalance;
            
        }
        
        require(rewards<=address(this).balance, "There are not enough AVAX on the smart contract to pay the transaction. Please contact us, something went wrong");
        
        require(rewards>0, "Rewards are 0");
        
        payable(_msgSender()).transfer(rewards);
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    function withdrawRemainingFees() onlyOwner external {
        
        require(totalRemainingFees<=address(this).balance, "Not enough AVAX");
        
        payable(owner()).transfer(totalRemainingFees);
        
        totalRemainingFees = 0;
        
    }
    
    
    function withdrawAmount(uint256 amount) onlyOwner external {
        
        payable(owner()).transfer(amount);
        
    }
    
    function deposit() public payable onlyOwner{
        // it deposits in the contract balance
    }
    
    
    function pause() onlyOwner external{
        _pause();
    }

    function unpause() onlyOwner external{
        _unpause();
    }
    
    
    
    
    
}