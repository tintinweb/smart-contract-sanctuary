/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap
{
     function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external returns (uint[] memory amounts);
     function WETH() external pure returns (address);
     function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
} 
 
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


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


interface IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
   // using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    // Token URI
   //string private _tokenURI;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    struct nftdeails
    {
        string mintname;
        uint256 timeofmint;
        string nftowner;
        string description;
        uint256 copies;
        string category;
        uint256 totalcopies;
    }
    
    mapping(uint256 => nftdeails) nftinfo;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    //     string memory baseURI = _baseURI();
    //     return bytes(baseURI).length > 0
    //         ? string(abi.encodePacked(baseURI, tokenId.toString()))
    //         : '';
    // }

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
    //  * by default, can be overriden in child contracts.
    //  */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    
    
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    
    
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
     
     
    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
            
    function mint(address to, uint256 tokenId,string memory _tokenURI,string memory _mintname,uint256 _timeperiod,string memory _nftowner,uint256 _copies,string memory description,string memory category) internal 
    {
        _mint(to,tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nftinfo[tokenId].mintname = _mintname;
        nftinfo[tokenId].timeofmint = _timeperiod;
        nftinfo[tokenId].nftowner = _nftowner;
        nftinfo[tokenId].copies = _copies;
        nftinfo[tokenId].description = description;
        nftinfo[tokenId].category = category;
        nftinfo[tokenId].totalcopies = _copies;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual 
    {
        //require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

contract MyToken is ERC721{
    
    address devwallet;
    
    struct collectioninfo
    {
        address collectionowner;
        bytes Cname;
        bytes Dname;
        bytes websiteURL;
        bytes description;
        bytes imghash;
        uint256 marketfees;
    }
    
    struct auction
    {
        uint256 time;
        uint256 minprice;
        bool inlist;
        uint256 biddingamount;
        
    }
    
    struct fixedsale
    {
        uint256 price;
        bool inlist;
    }
    
    struct Royalty
    {
        uint256 value;
        address _address;
        bool name;
        address originalowner;
        string [] properties;
    }
    
    struct completeinfo
    {
        fixedsale nftsale;
        uint256 [] collectionstored;
        collectioninfo collection;
        uint256 totalnft;
        uint256 salenftlist;
        uint256 auctionnftlist;
        bool tokenchoice;
    }

    address uniswapv2 = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    IUniswap immutable uniswap;
    uint256 public tokenidmint;
    uint256 public collectionform;
    uint256 evergrowcoinfees = 2; 
    uint256 auctionfees = 10;
    address owner;
    mapping(uint => completeinfo) nftdetailss; 
    mapping(address => uint256 []) public userinfo;
    mapping(address => uint256) public totalcollection;
    uint256 []  salenft;
    uint256 [] auctionnft;
    mapping(uint256=>mapping(uint256=>uint256)) idnumber;
    mapping(uint256 =>auction) timeforauction;
    mapping(uint256 =>mapping(address => uint256)) amountforauction;
    mapping(uint256 => uint256) public nftcollectionid;
    mapping(uint256 => address) finalowner;
    mapping(string => bool) stopduplicate;
    mapping(uint256 => Royalty) _royalty;

    constructor(string memory name_, string memory symbol_,address _owner,address _devwallet) ERC721(name_, symbol_) 
    {
       owner = _owner;
       devwallet = _devwallet;
       uniswap = IUniswap(uniswapv2);
    }
    
    function create(uint256 collectionid,address to,string memory _tokenURI,string memory _mintname,string memory _nftowner,uint256 _copies,string memory description,uint256 _royalti
    ,string memory category,bool nameRoyalty,string []  memory _properties) external 
    {
        require(!stopduplicate[_tokenURI],"value not allowed");
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        nftdetailss[collectionid].collectionstored.push(tokenidmint);
        nftdetailss[collectionid].totalnft+=1;
        idnumber[collectionid][tokenidmint]=nftdetailss[collectionid].totalnft-1;
        nftcollectionid[tokenidmint]=collectionid;
        mint(to,tokenidmint,_tokenURI,_mintname,timeperiod,_nftowner,_copies,description,category);
        stopduplicate[_tokenURI]=true;
        _royalty[tokenidmint] = Royalty(_royalti,to,nameRoyalty,to,_properties);
    }
    
    function createCopy(uint256 collectionid,address to,string memory _tokenURI,string memory _mintname,string memory _nftowner,uint256 _copies,string memory description,uint256 _royalti
    ,string memory category,bool nameRoyalty,string []  memory _properties) internal 
    {
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        nftdetailss[collectionid].collectionstored.push(tokenidmint);
        nftdetailss[collectionid].totalnft+=1;
        idnumber[collectionid][tokenidmint]=nftdetailss[collectionid].totalnft-1;
        nftcollectionid[tokenidmint]=collectionid;
        mint(to,tokenidmint,_tokenURI,_mintname,timeperiod,_nftowner,_copies,description,category);
        stopduplicate[_tokenURI]=true;
        _royalty[tokenidmint] = Royalty(_royalti,to,nameRoyalty,to,_properties); 
        
    }
    
    function createCollection(string memory _Cname,string memory _Dname,string memory _wensiteURL,string memory _description,string memory _imghash,uint256 _marketfee) external 
    {
        require(!stopduplicate[_imghash],"value not allowed");
        collectionform+=1;
        nftdetailss[collectionform].collection=collectioninfo(msg.sender,bytes(_Cname),bytes(_Dname),bytes(_wensiteURL),bytes(_description),bytes(_imghash),_marketfee);
        userinfo[msg.sender].push(collectionform);
        totalcollection[msg.sender]=collectionform;
        stopduplicate[_imghash]=true;
    }
    
    function fixedSales(uint256 tokenid,uint256 price,bool _tokenchoice) external
    {
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftdetailss[tokenid].nftsale.inlist,"already in sale");
        nftdetailss[tokenid].nftsale = fixedsale(price,true);
        nftdetailss[tokenid].salenftlist  = salenft.length;
        salenft.push(tokenid);
        nftdetailss[tokenid].tokenchoice=_tokenchoice;
        if(nftinfo[tokenid].copies==0)
        {
           address firstowner = ownerOf(tokenid);
           transferFrom(firstowner,address(this), tokenid);
        }
    }
    
    function cancelFixedSale(uint256 tokenid) external 
    {
      require(_royalty[tokenid].originalowner == msg.sender,"you are not original owner");
      nftdetailss[tokenid].nftsale.price= 0;
      nftdetailss[tokenid].nftsale.inlist=false;
      if(nftinfo[tokenid].copies==0)
      {
         _transfer(address(this),msg.sender,tokenid);
      }
      delete salenft[(nftdetailss[tokenid].salenftlist)];
    }
    
    function buyNft(uint256 _collectionid,uint256 tokenid,address token,address _to) external payable
    {
        require(nftinfo[tokenid].copies==0,"copies not finish yet");
        require(nftdetailss[tokenid].nftsale.inlist,"nft not in sale");
        uint256 val = uint256(100)-evergrowcoinfees;
        if(nftdetailss[tokenid].tokenchoice)
        {
           tokenTransfer(tokenid,token,val);
        }
        else
        {
            bnbTransfer(tokenid,token,val);
        }
        _transfer(address(this),_to,tokenid);
        nftinfo[tokenid].timeofmint = block.timestamp;
        changeCollection(_collectionid,tokenid,_to);
    }
    
    function buyCopies(address token,uint256 tokenid,address _to) external payable
    {
        require(nftinfo[tokenid].copies!=0,"no copies left");
        require(nftdetailss[tokenid].nftsale.inlist,"nft not in sale");
        uint256 val = uint256(100)-evergrowcoinfees;
        if(nftdetailss[tokenid].tokenchoice)
        {
           tokenTransfer(tokenid,token,val);
        }
        else
        {
            bnbTransfer(tokenid,token,val);
        }  
        uint256 collectionid = totalcollection[_to];
        uint256 id = tokenid;
        createCopy(collectionid,_to,tokenURI(id),nftinfo[id].mintname,nftinfo[id].nftowner,0,nftinfo[id].description,0,nftinfo[id].category,_royalty[id].name,_royalty[id].properties);
        nftinfo[tokenid].copies-=1;
        nftdetailss[tokenid].nftsale.price= 0;
        nftdetailss[tokenid].nftsale.inlist=false;
        delete salenft[(nftdetailss[tokenid].salenftlist)];    
    }
     
    function tokenTransfer(uint256 tokenid,address token,uint256 val) internal
    {
        require(IERC20(token).allowance(msg.sender,address(this)) >= nftdetailss[tokenid].nftsale.price,"price should be greater");
        uint256 totalamount = nftdetailss[tokenid].nftsale.price;
        uint256 amount   = (totalamount*uint256(val)/uint256(100));
        uint256 ownerinterest = (totalamount*uint256(evergrowcoinfees)/uint256(100)); 
        IERC20(token).transferFrom(msg.sender,address(this),totalamount);
        address firstowner    = _royalty[tokenid].originalowner; 
        if(_royalty[tokenid]._address != firstowner && _royalty[tokenid].value!=0)
        {
            uint256 royaltivalue = (amount*uint256(_royalty[tokenid].value)/uint256(100));
            amount-=royaltivalue;
            royaltyTransferToken(royaltivalue,tokenid,token);
        }
        IERC20(token).transfer(firstowner,amount);
        IERC20(token).transfer(devwallet,ownerinterest);   
    }
    
    function bnbTransfer(uint256 tokenid,address token,uint256 val) internal
    {
        uint256 values = msg.value;
        require(values >= nftdetailss[tokenid].nftsale.price,"price should be greater");
        uint256 amount   = (values*uint256(val)/uint256(100));
        uint256 ownerinterest = (values*uint256(evergrowcoinfees)/uint256(100)); 
        address firstowner    = _royalty[tokenid].originalowner;
        if(_royalty[tokenid]._address != firstowner && _royalty[tokenid].value!=0)
        {
            uint256 royaltivalue = (amount*uint256(_royalty[tokenid].value)/uint256(100));
            amount-=royaltivalue;
            royaltyTransferBnb(royaltivalue,tokenid,token);
        }
        (bool success,)  = firstowner.call{ value: amount}("");
        require(success, "refund failed");
        (bool evergrowcoins,)  = devwallet.call{ value: ownerinterest}("");
        require(evergrowcoins, "refund failed");
    }
    
    function changeCollection(uint256 _collectionid,uint256 tokenid,address _to) internal
    {
       delete nftdetailss[_collectionid].collectionstored[(idnumber[_collectionid][tokenid])];
       nftdetailss[(totalcollection[_to])].collectionstored.push(tokenid);
       nftdetailss[(totalcollection[_to])].totalnft+=1;
       idnumber[(totalcollection[_to])][tokenid]=nftdetailss[(totalcollection[_to])].totalnft-1;
       nftdetailss[tokenid].nftsale.price= 0;
       nftdetailss[tokenid].nftsale.inlist=false;
       _royalty[tokenid].originalowner= _to;
       nftcollectionid[tokenid]=totalcollection[_to];
       delete salenft[(nftdetailss[tokenid].salenftlist)];
    }
    
    function startAuction(uint256 tokenid,uint256 price,uint256 endday,uint256 endhours,uint256 min,bool choice) public 
    {
        require(!timeforauction[tokenid].inlist,"already in sale");
        require(!nftdetailss[tokenid].nftsale.inlist,"already in sale");
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        timeforauction[tokenid] = auction((block.timestamp +(endday * uint256(86400)) + (endhours*uint256(3600)) + (min*uint256(60))),price,true,price);
        nftdetailss[tokenid].auctionnftlist=auctionnft.length;
        auctionnft.push(tokenid);
        nftdetailss[tokenid].tokenchoice = choice;
        if(nftinfo[tokenid].copies==0)
        {
           address firstowner = ownerOf(tokenid);
           transferFrom(firstowner,address(this), tokenid);
        }
    }
    
    function buyAuction(uint256 tokenid,address token,uint256 amount) public payable
    {
        require(timeforauction[tokenid].inlist,"nft not in sale");
        require(timeforauction[tokenid].time >= block.timestamp,"auction end");
        if(nftdetailss[tokenid].tokenchoice)
        {
            require(IERC20(token).allowance(msg.sender,address(this)) >= timeforauction[tokenid].biddingamount,"amount should be greater");
            timeforauction[tokenid].biddingamount=amount;
            amountforauction[tokenid][msg.sender] = amount;
            finalowner[tokenid]=msg.sender;
            IERC20(token).transferFrom(msg.sender,address(this),amount);
            
        }
        else
        {
            require(msg.value >= timeforauction[tokenid].biddingamount,"amount should be greater");
            timeforauction[tokenid].biddingamount=msg.value;
            amountforauction[tokenid][msg.sender] = msg.value;
            finalowner[tokenid]=msg.sender;
            uint256 values = msg.value;
            (bool success,)  = address(this).call{ value:values}("");
            require(success, "refund failed");
        }
        
    }
                       
    function claim(uint256 collectionid,uint256 tokenid,address token,address _to) public
    {
        require(timeforauction[tokenid].inlist,"nft not in sale");
        require(nftinfo[tokenid].copies==0,"copies not finish yet");
        require(timeforauction[tokenid].time < block.timestamp,"auction not end");
       
        if(finalowner[tokenid] == msg.sender)
        {
            uint256 val = uint256(100)-evergrowcoinfees;
            uint256 totalamount = timeforauction[tokenid].biddingamount;
            uint256 amount   = (totalamount*uint256(val)/uint256(100));
            uint256 ownerinterest = (totalamount*uint256(evergrowcoinfees)/uint256(100)); 
            address firstowner    = _royalty[tokenid].originalowner;
            claimAmountTransfer(tokenid,token,amount,ownerinterest,firstowner);
            _transfer(address(this),_to,tokenid);
            changeAuctionCollection(collectionid,tokenid,_to);
        }
    }

    function auctionCopyClaim(uint256 tokenid,address token,address _to) public
    {
        require(timeforauction[tokenid].inlist,"nft not in sale");
        require(nftinfo[tokenid].copies!=0,"copies finish");
        require(timeforauction[tokenid].time < block.timestamp,"auction not end");
        
        if(finalowner[tokenid] == msg.sender)
        {
            uint256 val = uint256(100)-evergrowcoinfees;
            uint256 totalamount = timeforauction[tokenid].biddingamount;
            uint256 amount   = (totalamount*uint256(val)/uint256(100));
            uint256 ownerinterest = (totalamount*uint256(evergrowcoinfees)/uint256(100)); 
            address firstowner    = _royalty[tokenid].originalowner;
            claimAmountTransfer(tokenid,token,amount,ownerinterest,firstowner);
            delete auctionnft[(nftdetailss[tokenid].auctionnftlist)];
            timeforauction[tokenid] = auction(0,0,false,0);
            finalowner[tokenid] = address(0);
            uint256 collectionid = totalcollection[_to];
            uint256 id = tokenid;
            createCopy(collectionid,_to,tokenURI(id),nftinfo[id].mintname,nftinfo[id].nftowner,0,nftinfo[id].description,0,nftinfo[id].category,_royalty[id].name,_royalty[id].properties);
            nftinfo[tokenid].copies-=1;
        }
    }
    
    function upgradeAuction(uint256 tokenid,address token,bool choice,uint256 amount) external payable
    {
        require(timeforauction[tokenid].time >= block.timestamp,"auction end");
        uint256 val = uint256(100)-auctionfees;
        if(choice)
        {
            amountforauction[tokenid][msg.sender] += amount;
            if(amountforauction[tokenid][msg.sender] > timeforauction[tokenid].biddingamount)
            {
                timeforauction[tokenid].biddingamount=amountforauction[tokenid][msg.sender];
                finalowner[tokenid]=msg.sender;
                
                if(nftdetailss[tokenid].tokenchoice)
                {
                   IERC20(token).transferFrom(msg.sender,address(this),amount);
                }
                else
                {
                    uint256 values = msg.value;
                    (bool success,)  = address(this).call{ value:values}("");
                    require(success, "refund failed");
                }
            }
        }
        else
        {
           if(finalowner[tokenid]!=msg.sender)
           {
               require(amountforauction[tokenid][msg.sender]>0,"You dont allow");
               uint256 totalamount = amountforauction[tokenid][msg.sender];
               uint256 amo = (totalamount*uint256(val)/uint256(100));
               uint256 ownerinterest = (totalamount*uint256(auctionfees)/uint256(100)); 
               claimAmountTransfer(tokenid,token,amo,ownerinterest,msg.sender);
               amountforauction[tokenid][msg.sender]=0;  
           }
        }
    }

    function removesFromAuction(uint256 tokenid) external
    {
        require(_royalty[tokenidmint].originalowner == msg.sender,"You are not originalowner");
        timeforauction[tokenid].minprice= 0;
        timeforauction[tokenid].biddingamount=0;
        timeforauction[tokenid].inlist=false;
        timeforauction[tokenid].time=0;
        _transfer(address(this),msg.sender,tokenid);
        delete auctionnft[(nftdetailss[tokenid].auctionnftlist)];
    }

    function claimAmountTransfer(uint256 tokenid,address token,uint256 amount,uint256 ownerinterest,address firstowner) internal
    {
        if(nftdetailss[tokenid].tokenchoice)
        {
            IERC20(token).transfer(firstowner,amount);
            IERC20(token).transfer(devwallet,ownerinterest);  
        }
        else
        {
            (bool success,)  = firstowner.call{ value: amount}("");
            require(success, "refund failed");
            (bool evergrowcoins,)  = devwallet.call{ value: ownerinterest}("");
            require(evergrowcoins, "refund failed");   
        }
    }

    function changeAuctionCollection(uint256 _collectionid,uint256 tokenid,address _to) internal
    {
       delete nftdetailss[_collectionid].collectionstored[(idnumber[_collectionid][tokenid])];
       nftdetailss[(totalcollection[_to])].collectionstored.push(tokenid);
       nftdetailss[(totalcollection[_to])].totalnft+=1;
       idnumber[(totalcollection[_to])][tokenid]=nftdetailss[(totalcollection[_to])].totalnft-1;
       timeforauction[tokenid] = auction(0,0,false,0);
       finalowner[tokenid] = address(0);
       nftcollectionid[tokenid]=totalcollection[_to];
       _royalty[tokenid].originalowner = _to;
       delete auctionnft[(nftdetailss[tokenid].auctionnftlist)];
    }
    
    function  royaltyTransferToken(uint256 amount,uint256 tokenid,address token) internal
    {
        if(_royalty[tokenidmint].name)
        {
           IERC20(token).transfer(_royalty[tokenid]._address,amount);
        }
        else
        {
            swapEth(token,amount,tokenid);
        }
    }

    function royaltyTransferBnb(uint256 amount,uint256 tokenid,address token) internal
    {
        if(_royalty[tokenidmint].name)
        {
           swapToken(token,amount,tokenid);
        }
        else
        {
            (bool success,)  = _royalty[tokenid]._address.call{ value: amount}("");
            require(success, "refund failed");
        }
    }

    function swapToken(address token,uint256 amount,uint256 tokenid) internal 
    {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = token;
        uniswap.swapExactETHForTokens{value:amount}(
          0,
          path,
          _royalty[tokenid]._address,
          block.timestamp + 1800000
        );
    }
    
    function swapEth(address token,uint256 amount,uint256 tokenid) internal 
    {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        IERC20(token).approve(address(uniswapv2), amount);
        uniswap.swapExactTokensForETH(
          amount,
          0,
          path,
          _royalty[tokenid]._address,
          block.timestamp + 1800000
      );
    }

    function updatedevwallet(address _address) external 
    {
        require(msg.sender == devwallet,"not allowed");
        devwallet = _address;
    }
     
    function auctionDetail(uint256 tokenid) public view returns(uint256,address,bool) 
    {
        return (timeforauction[tokenid].biddingamount,finalowner[tokenid],nftdetailss[tokenid].tokenchoice);
    }
    
    function listOfSaleNft(uint256 tokenid) public view returns(uint256 [] memory,uint256 [] memory,uint256,uint256)
    {
        return (salenft,auctionnft,timeforauction[tokenid].minprice,nftdetailss[tokenid].nftsale.price);
    }
    
    function collectionDetails(uint256 id) public view returns(uint256,address,string memory,string memory,string memory,string memory,string memory,uint256)
    {
        string memory Cname  = string(nftdetailss[id].collection.Cname);  
        string memory Dname  = string(nftdetailss[id].collection.Dname);  
        string memory URL  = string(nftdetailss[id].collection.websiteURL);  
        string memory description  = string(nftdetailss[id].collection.description);  
        string memory imghash  = string(nftdetailss[id].collection.imghash);  
        uint256 value = id;
        uint256 fees = nftdetailss[value].collection.marketfees;
        address collectionowners =  nftdetailss[value].collection.collectionowner;
        return (value,collectionowners,Cname,Dname,URL,description,imghash,fees);
    }
    
    function nftInformation(uint256 id) public view returns(uint256,string memory,uint256,string memory,uint256,string memory,string memory,uint256,address,string memory,address)
    {
        uint256 value = id;
        return (id,nftinfo[value].mintname,nftinfo[value].timeofmint,nftinfo[value].nftowner,nftinfo[value].copies,nftinfo[value].description,tokenURI(value),nftcollectionid[value],ownerOf(value),nftinfo[value].category,_royalty[value].originalowner);
    }
    
    function  everGrowCoin(uint256 tokenid) external view returns(bool)
    {
        return (nftdetailss[tokenid].tokenchoice);
    }
    
    function properties(uint256 tokenid) external view returns(string [] memory)
    {
        return (_royalty[tokenid].properties);
    }

    function collectionNft(uint256 collectionid) external view returns(uint [] memory)
    {
        return (nftdetailss[collectionid].collectionstored);
    }
    
    function totalCollectionDetails() external view returns(uint [] memory)
    {
        return userinfo[msg.sender];
    }
    
    function numberOfCopies(uint256 tokenid) external view returns(uint256)
    {
        return nftinfo[tokenid].copies;
    }
    
    function timing(uint256 tokenid) external view returns(uint256)
    {
        if(timeforauction[tokenid].time>=block.timestamp)
        {
            return (timeforauction[tokenid].time-block.timestamp);
        }
        else
        {
            return uint256(0);
        }
    }
    
    receive() payable external {}

}