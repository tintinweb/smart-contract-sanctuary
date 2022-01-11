/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        string Imagetitle;
        uint256 timeofmint;
        string Imagedescription;
        bool physicalasset;
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

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

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
            
    function mint(address to, uint256 tokenId,string memory _tokenURI,string memory _Imagetitle,uint256 _timeofmint,string memory _Imagedescription,bool _physicalasset) internal 
    {
        _mint(to,tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nftinfo[tokenId].Imagetitle = _Imagetitle;
        nftinfo[tokenId].timeofmint = _timeofmint;
        nftinfo[tokenId].Imagedescription = _Imagedescription;
        nftinfo[tokenId].physicalasset = _physicalasset;
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
    
    //using SafeMath for uint256;
    address devwallet1 = address(0x78549De1595FE319dFf9A461Ed915Ff2B87550E0);
    address devwallet2 = address(0);
    
    uint256 tokenidmint;
    address owner;
    mapping(string => bool) stopduplicate;
    mapping(string => uint256 []) fiatlink;

    struct auction
    {
        address owner;
        uint256 time;
        uint256 minprice;
        bool inlist;
        uint256 biddingamount;
        uint256 auctionnftlist;
    }
    
    struct fixedsale
    {
        uint256 price;
        bool inlist;
        uint256 salenftlist;
    }
    
    struct Royalty
    {
        uint256 value;
        address originalowner;
    }
    
    uint256 totalpercent = uint256(100);
    uint256 metagoldenfees = 5; 
    uint256 []  salenft;
    uint256 [] auctionnft;
    mapping(uint256 =>auction) auctionsaledetails;
    mapping(uint256 =>fixedsale) fixedsaledetails;
    mapping(uint256 => Royalty) _royalty;
    mapping(uint256 =>mapping(address => uint256)) amountforauction;
    mapping(uint256 => address) finalowner;
    
    constructor(string memory name_, string memory symbol_,address _owner) ERC721(name_, symbol_) 
    {
       owner = _owner;
    }
    
    function createNftWallet(address to,string memory _tokenURI,string memory _Imagetitle,string memory _Imagedescription,bool physicalasset,uint256 _value) external 
    {
        require(!stopduplicate[_tokenURI],"value not allowed");
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        mint(to,tokenidmint,_tokenURI,_Imagetitle,timeperiod,_Imagedescription,physicalasset);
        stopduplicate[_tokenURI]=true;
        _royalty[tokenidmint] = Royalty(_value,msg.sender);
    }
    
    function createfiatWallet(address to,string memory _tokenURI,string memory _Imagetitle,string memory _Imagedescription,string memory email,bool physicalasset) external 
    {
        require(!stopduplicate[_tokenURI],"value not allowed");
        tokenidmint+=1;
        uint256 timeperiod = block.timestamp;
        fiatlink[email].push(tokenidmint);
        mint(to,tokenidmint,_tokenURI,_Imagetitle,timeperiod,_Imagedescription,physicalasset);
        stopduplicate[_tokenURI]=true;
    }
    
    function fiatnfttransfer(string memory email,address _address,uint256 _value) external
    {
        require(msg.sender == owner,"not devwallet");
        for(uint256 i=0; i<fiatlink[email].length;i++)
        {
            _transfer(ownerOf((fiatlink[email][i])),_address,fiatlink[email][i]);  
            _royalty[(fiatlink[email][i])] = Royalty(_value,_address);
        }
    }
    
    function fixedsales(uint256 tokenid,uint256 price) external
    {
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        require(!auctionsaledetails[tokenid].inlist,"already in auction");
        require(!fixedsaledetails[tokenid].inlist,"already in sale");
        fixedsaledetails[tokenid] =  fixedsale(price,true,salenft.length);
        salenft.push(tokenid);
        transferFrom(ownerOf(tokenid),address(this), tokenid);
    }

    function buyNft(uint256 tokenid,address _to) public payable
    {
        require(fixedsaledetails[tokenid].inlist,"nft not in sale");
        uint256 val = totalpercent - metagoldenfees;
        bnbTransfer(tokenid,val);
        _transfer(address(this),_to,tokenid);
    }

    function bnbTransfer(uint256 tokenid,uint256 val) internal
    {
        uint256 values = msg.value;
        require(values >= fixedsaledetails[tokenid].price,"price should be greater");
        uint256 amount   = ((values*val)/uint256(100));
        uint256 ownerinterest = ((values*(metagoldenfees))/uint256(100)); 
        address firstowner    = _royalty[tokenid].originalowner;
        if(ownerOf(tokenid) != firstowner && _royalty[tokenid].value!=0)
        {
            uint256 royaltivalue = (amount*uint256(_royalty[tokenid].value)/uint256(100));
            amount-=royaltivalue;
            royaltyTransferBnb(royaltivalue,tokenid);
        }
        amounttransfer(firstowner,amount,ownerinterest); 
    }
    
    function cancelFixedSale(uint256 tokenid) external 
    {
        require(_royalty[tokenid].originalowner == msg.sender,"you are not original owner");
        fixedsaledetails[tokenid].price= 0;
        fixedsaledetails[tokenid].inlist=false;
        _transfer(address(this),msg.sender,tokenid);
        delete salenft[(fixedsaledetails[tokenid].salenftlist)];
    }

    function startAuction(uint256 tokenid,uint256 price,uint256 endday,uint256 endhours,uint256 min) public 
    {
        require(ownerOf(tokenid) == msg.sender,"You are not owner");
        require(!auctionsaledetails[tokenid].inlist,"already in auction");
        require(!fixedsaledetails[tokenid].inlist,"already in sale");
        auctionsaledetails[tokenid] = auction(msg.sender,(block.timestamp +(endday * uint256(86400)) + (endhours*uint256(3600)) + (min*uint256(60))),price,true,price,auctionnft.length);
        auctionnft.push(tokenid);
        address firstowner = ownerOf(tokenid);
        transferFrom(firstowner,address(this), tokenid);
    }
    
    function buyauction(uint256 tokenid) external payable
    {
        require(auctionsaledetails[tokenid].inlist,"not in auction");
        require(msg.value >= auctionsaledetails[tokenid].minprice,"amount should be greater");
        require(msg.value > auctionsaledetails[tokenid].biddingamount,"previous bidding amount");
        require(auctionsaledetails[tokenid].time >= block.timestamp,"auction end");
        auctionsaledetails[tokenid].biddingamount=msg.value;
        amountforauction[tokenid][msg.sender] = msg.value;
        finalowner[tokenid]=msg.sender;
        uint256 values = msg.value;
        (bool success,)  = address(this).call{ value:values}("");
        require(success, "refund failed");
    }

    function upgradeauction(uint256 tokenid,bool choice) external payable
    {
        require(auctionsaledetails[tokenid].time >= block.timestamp,"auction end");
        uint256 val = totalpercent - metagoldenfees;
        if(choice)
        {
            amountforauction[tokenid][msg.sender] += msg.value;
            if(amountforauction[tokenid][msg.sender] > auctionsaledetails[tokenid].biddingamount)
            {
                auctionsaledetails[tokenid].biddingamount=msg.value;
                finalowner[tokenid]=msg.sender;
                uint256 values = msg.value;
                (bool success,)  = address(this).call{ value:values}("");
                require(success, "refund failed");
            }
        }
        else
        {
           if(finalowner[tokenid]!=msg.sender)
           {
              require(amountforauction[tokenid][msg.sender]>0,"You dont allow");
              uint256 totalamount = amountforauction[tokenid][msg.sender];
              uint256 amount = (totalamount*uint256(val)/uint256(100));
              uint256 ownerinterest = (totalamount*uint256(metagoldenfees)/uint256(100)); 
              amounttransfer(msg.sender,amount,ownerinterest); 
              amountforauction[tokenid][msg.sender]=0;
           }
        }
    }

    function claim(uint256 tokenid) external
    {
        require(auctionsaledetails[tokenid].inlist,"nft not in sale");
        require(auctionsaledetails[tokenid].time < block.timestamp,"auction not end");
        uint256 val = totalpercent - metagoldenfees;
        if(finalowner[tokenid] == msg.sender)
        {
            uint256 totalamount = auctionsaledetails[tokenid].biddingamount;
            uint256 amount   = (totalamount*uint256(val)/uint256(100));
            uint256 ownerinterest = (totalamount*uint256(metagoldenfees)/uint256(100)); 
            address firstowner    = auctionsaledetails[tokenid].owner;
            amounttransfer(firstowner,amount,ownerinterest); 
            _transfer(address(this),msg.sender,tokenid);
        }
    }

    function removesfromauction(uint256 tokenid) external
    {
        require(auctionsaledetails[tokenid].owner == msg.sender,"You are not originalowner");
        auctionsaledetails[tokenid].minprice= 0;
        auctionsaledetails[tokenid].biddingamount=0;
        auctionsaledetails[tokenid].inlist=false;
        auctionsaledetails[tokenid].time=0;
        auctionsaledetails[tokenid].owner=address(0);
        _transfer(address(this),msg.sender,tokenid);
        delete auctionnft[(auctionsaledetails[tokenid].auctionnftlist)];
    }
    
    function royaltyTransferBnb(uint256 amount,uint256 tokenid) internal
    {
        (bool success,)  = _royalty[tokenid].originalowner.call{ value: amount}("");
        require(success, "refund failed");
    }  

    function amounttransfer(address firstowner,uint256 amount,uint256 ownerinterest) internal
    {
        (bool success,)  = firstowner.call{ value: amount}("");
        require(success, "refund failed");
        (bool dev1,)  = devwallet1.call{ value: (ownerinterest/uint256(2))}("");
        require(dev1, "refund failed");
        (bool dev2,)  = devwallet2.call{ value: (ownerinterest/uint256(2))}("");
        require(dev2, "refund failed");
    }

    function nftinformation(uint256 tokenId) external view returns(string memory,uint256,string memory,bool)
    {
       return  (nftinfo[tokenId].Imagetitle,nftinfo[tokenId].timeofmint,nftinfo[tokenId].Imagedescription,nftinfo[tokenId].physicalasset);
    }

    function saledetails() external view returns(uint256 [] memory,uint256 [] memory)
    {
        return (salenft,auctionnft);
    }

    function auctiondetails(uint256 tokenid) external view returns(auction memory)
    {
        return auctionsaledetails[tokenid];
    }

    function fixedsaleinfo(uint256 tokenid) external view returns(fixedsale memory)
    {
        return fixedsaledetails[tokenid];
    }

    function fiatdetails(string memory email) external view returns(uint256 [] memory)
    {
        return fiatlink[email];
    }

    receive() payable external {}
}