// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";



contract ERC721 is Context ,ERC165, IERC721, IERC721Metadata, Ownable, Pausable {

    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Auction {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 tokenId;
        uint256 minBidPrice;
        string auctionType;
    }

    struct Rate {
        uint256 id;
        uint256 cost;
        address owner;
        bool canBeCanceled;
    }

    event CloseAuction(uint256 indexed tokenId, address indexed toAddress,uint256 indexed price,uint256 auctionId);

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    event CreateAuction(uint256 indexed tokenId, address indexed owner,uint256 indexed minBidPrice,uint256 auctionId);

    event CreateRate(uint256 indexed auctionId, address indexed owner,uint256 indexed price);

    event CloseRate(uint256 indexed auctionId, address indexed owner);


    string private timeAuction = 'TimeAuction';
    string private notLimitAuction = 'NotLimitAuction';
    string private simpleAuction = 'SimpleAuction';


    // Auction of tokenId
    mapping (uint256 =>  Auction) public auctionOfToken;
    // Auction ID
    mapping (uint256 =>  Auction) public auctionMap;
    // Mapping from auction ID to rates array
    mapping (uint256 =>  Rate[]) public rateMap;

    // pending Auctions
    uint256[] public pendingAuctions;


    uint256 public auctionCount = 1;
    uint256 public rateCount = 1;

    ////////////////   Auction

    function withDraw() public onlyOwner(){
        address payable owner = payable(address(uint160(_msgSender())));
        owner.transfer(address(this).balance);
    }


    // Create auctions
    function createTokenAndTimeAuction(uint256 startTime,uint256 endTime,uint256 minBidPrice) public  {
        uint256 tokenId = createToken();
        createTimeAuction(tokenId,startTime,endTime,minBidPrice);
    }
    function createTimeAuction(uint256 tokenId,uint256 startTime,uint256 endTime,uint256 minBidPrice) public  {
        require(auctionOfToken[tokenId].id == 0, "Auction is exist");

        require(_owners[tokenId] == _msgSender(), "Transaction sender not owner token");

        _setAuctionToMap(tokenId,startTime,endTime,minBidPrice,timeAuction);

        emit CreateAuction(tokenId,_msgSender(),minBidPrice,auctionOfToken[tokenId].id);
    }


    function createNotLimitAuction(uint256 tokenId,uint256 minBidPrice) public  {
        require(auctionOfToken[tokenId].id == 0, "Auction is exist");

        require(_owners[tokenId] == _msgSender(), "Transaction sender not owner token");

        _setAuctionToMap(tokenId,0,0,minBidPrice,notLimitAuction);

        emit CreateAuction(tokenId,_msgSender(),minBidPrice,auctionOfToken[tokenId].id);
    }
    function createTokenAndNotLimitAuction(uint256 minBidPrice) public  {
        uint256 tokenId = createToken();
        createNotLimitAuction(tokenId,minBidPrice);
    }


    function createSimpleAuction(uint256 tokenId,uint256 minBidPrice) public  {
        require(auctionOfToken[tokenId].id == 0, "Auction is exist");

        require(_owners[tokenId] == _msgSender(), "Transaction sender not owner token");

        _setAuctionToMap(tokenId,0,0,minBidPrice,simpleAuction);

        emit CreateAuction(tokenId,_msgSender(),minBidPrice,auctionOfToken[tokenId].id);
    }
    function createTokenAndSimpleAuction(uint256 minBidPrice) public  {
        uint256 tokenId = createToken();
        createSimpleAuction(tokenId,minBidPrice);
    }

    // Rates
    function createRate(uint256 auctionId) public  payable  {
        uint256 cost = msg.value;

        require(auctionMap[auctionId].id != 0, "Auction not found");

        require(cost > 0, "Cost should be greater than zero.");

        require(cost >= auctionMap[auctionId].minBidPrice, "Cost should be greater than min price.");

        bool rateCanBeCanceled = false;

        if(keccak256(abi.encodePacked(auctionMap[auctionId].auctionType)) == keccak256(abi.encodePacked(notLimitAuction))){
            rateCanBeCanceled = true;
        }

        _setRateToArray(auctionId,_msgSender(),cost,rateCanBeCanceled);

        if(keccak256(abi.encodePacked(auctionMap[auctionId].auctionType)) == keccak256(abi.encodePacked(simpleAuction))){
            Rate storage singlerate = rateMap[auctionId][0];
            _approveRate(auctionId,singlerate.id);
            removeAuction(auctionId);
        }

        emit CreateRate(auctionId,_msgSender(),cost);
    }

    function getRatesByAuctionIndex(uint256 auctionId) public view returns(Rate[] memory) {
        return rateMap[auctionId];
    }

    function removeRate(uint256 _auctionId,uint256 _rateId) public {
        Rate[] storage rateArray = rateMap[_auctionId];

        for (uint i = 0; i<rateArray.length; i++) {
            Rate memory currentRate = rateArray[i];
            if(currentRate.id == _rateId) {
                require(currentRate.owner == _msgSender(), "Not approved or owner");
                require(currentRate.canBeCanceled, "It is forbidden to delete this rate");
                delete rateArray[i];
                address payable owner = payable(address(uint160(currentRate.owner)));
                owner.transfer(currentRate.cost);

                emit CloseRate(_auctionId,_msgSender());

                return;
            }

        }
        revert();
    }

    // Remove auction
    function removeAuction(uint256 _auctionId) private {
        _removeAuctionFromTokenMap(auctionMap[_auctionId].tokenId);
        _removeAuctionFromMap(_auctionId);
        _removeAuctionFromPendingArray(_auctionId);
    }

    function _setAuctionToMap(uint256 _tokenId, uint256 _startTime, uint256 _endTime, uint256 _minBidPrice,string memory _auctionType) private {

        Auction memory auction;

        auction.tokenId = _tokenId;
        auction.id = auctionCount;
        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.minBidPrice = _minBidPrice;
        auction.auctionType = _auctionType;

        auctionMap[auctionCount] = auction;
        auctionOfToken[_tokenId] = auction;


        if(keccak256(abi.encodePacked(_auctionType)) == keccak256(abi.encodePacked(timeAuction))){
            _setAuctionToPendingArray(auctionCount);
        }

        auctionCount++;
    }

    function _setRateToArray(uint256 auctionId,address rateOwnAddress,uint256 cost, bool _canBeCanceled) private {
        require(auctionMap[auctionId].id != 0 && auctionId != 0, "Auction not exist");

        Rate[] storage rates = rateMap[auctionId];

        Rate memory rate;
        rate.cost = cost;
        rate.owner = rateOwnAddress;
        rate.id = getRatesCount();
        rate.canBeCanceled = _canBeCanceled;

        rates.push(rate);
        incrementRateCount();
    }

    function _setAuctionToPendingArray(uint256 auctionId) private {
        pendingAuctions.push(auctionId);
    }

    function _removeAuctionFromPendingArray(uint256 auctionId) private {
        for (uint i = 0; i< pendingAuctions.length; i++) {
            uint256  currentAuction = pendingAuctions[i];
            if(currentAuction == auctionId) {
                delete pendingAuctions[i];
            }
        }
    }

    function _removeAuctionFromMap(uint256 _auctionId) private {
        delete auctionMap[_auctionId];
    }

    function _removeAuctionFromTokenMap(uint256 _tokenId) private {
        delete auctionOfToken[_tokenId];
    }

    function checkPendingAuctions() public {
        Rate memory localMaxRate;
        for (uint i = 0; i< pendingAuctions.length; i++) {
            uint256  currentAuctionId = pendingAuctions[i];

            // get max cost rate
            if(auctionMap[currentAuctionId].endTime <  block.timestamp) {
                Rate[] storage rates = rateMap[currentAuctionId];
                localMaxRate = rates[0];
                for (uint j = 1; j< rates.length; j++) {
                    Rate storage currentRate = rates[j];
                    if(currentRate.cost >  localMaxRate.cost) {
                        localMaxRate = currentRate;
                    }
                }
                _approveRate(currentAuctionId,localMaxRate.id);
                removeAuction(currentAuctionId);
            }
        }
    }

    /////////////
    //  Crete  //
    /////////////
    function createToken() public returns(uint256)  {
        uint256 tokenId = totalSupply();
        _safeMint(_msgSender(), tokenId);
        emit TokenCreated(tokenId,_msgSender());
        return tokenId;
    }

    function getRatesByAuctionIndexAndRateIndex(uint256 _auctionId,uint256 _rateId) public view returns(Rate memory) {
        Rate[] storage rateArray = rateMap[_auctionId];

        for (uint i=0; i<rateArray.length; i++) {
            Rate memory currentRate = rateArray[i];
            if(currentRate.id == _rateId) {
                return currentRate;
            }
        }
        revert();
    }

    function getRatesCount() public view returns(uint256) {
        return rateCount;
    }

    function incrementRateCount() private {
        rateCount = rateCount + 1;
    }

    function approveRate(uint256 _auctionId,uint256 rateId) public {

        Auction memory auction = auctionMap[_auctionId];

        require(keccak256(abi.encodePacked(auction.auctionType)) == keccak256(abi.encodePacked(notLimitAuction)),'The bet cannot be approve.Wrong auction type.');

        require(_owners[auction.tokenId] == _msgSender(), "Transaction sender not owner token");

        _approveRate(_auctionId,rateId);
        removeAuction(_auctionId);
    }

    function _approveRate(uint256 _auctionId,uint256 rateId) private {
        Auction memory auction = auctionMap[_auctionId];
        Rate memory winnRate = getRatesByAuctionIndexAndRateIndex(_auctionId,rateId);

        address payable owner = payable(address(uint160(ERC721.ownerOf(auction.tokenId))));


        // Transfer token
        safeTransferFrom(owner, winnRate.owner, auction.tokenId);

        // Process Payment
        owner.transfer(winnRate.cost);
        emit CloseAuction(auction.tokenId,winnRate.owner, winnRate.cost,auction.id);
        // Return Money from auction
        _returnMoneyFromRate(_auctionId,winnRate.id);

        delete rateMap[_auctionId];
    }

    function _returnMoneyFromRate(uint256 _auctionId,uint256 _winnRateId) private {
        Rate[] storage rateArray = rateMap[_auctionId];

        for (uint i = 0; i<rateArray.length; i++) {
            Rate memory currentRate = rateArray[i];
            if(currentRate.id == _winnRateId) {
                continue;
            }
            if(currentRate.owner == address(0)){
                continue;
            }
            address payable owner = payable(address(uint160(currentRate.owner)));
            owner.transfer(currentRate.cost);
        }
    }


    // Token name
    string private _name='Test Token';

    // Token symbol
    string private _symbol='TSTW';


    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;


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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "https://test.com/nft?id=";
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

        //TODO hide
        //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        //TODO hide
        //  require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        address owner = ERC721.ownerOf(tokenId);
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);

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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual  {

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;


    // PUBLIC
    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) private view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    // PUBLIC
    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) private view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");

        return _allTokens[index];
    }


    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].pop();

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }

}