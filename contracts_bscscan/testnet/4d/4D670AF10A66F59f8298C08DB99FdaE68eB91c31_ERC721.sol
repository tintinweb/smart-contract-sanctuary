// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./IERC20.sol";


contract ERC721 is Context ,ERC165, IERC721, IERC721Metadata, Ownable {

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
        uint256 auctionType;
        address tokenAddress;
    }

    struct Rate {
        uint256 id;
        uint256 cost;
        address owner;
    }

    event CloseAuction(uint256 indexed tokenId, address indexed toAddress,uint256 indexed price,uint256 auctionId);

    event TokenCreated(uint256 indexed tokenId, address indexed owner);

    event MultipleTokenCreated(uint256 [] tokenIds, address indexed owner);

    event CreateAuction(uint256 indexed tokenId, address indexed owner,uint256 indexed minBidPrice,uint256 auctionId);

    event CreateRate(uint256 indexed auctionId, address indexed owner,uint256 indexed price);

    event CloseRate(uint256 indexed auctionId, address indexed owner,uint256 indexed rateId);

    event ChangeMinBid(uint256 indexed auctionId,uint256 indexed newMinBid);


    uint256 private timeAuction = 1;
    uint256 private simpleAuction = 2;

    //percent of close auction <system> NFT token
    uint256 public systemPercent = 5;

    //percent rate step
    uint256 public rateStepPercent = 10;

    //min bid amount  WEI
    uint256 public minBid = 100;

    //system address
    address public systemAddress = 0xD458a0Aa3f2F8B5Dd734c848E0f5ef7b7Aeed5c2;


    // Auction of tokenId
    mapping (uint256 =>  Auction) public auctionOfToken;

    // rate of auctionId
    mapping (uint256 =>  Rate) public rateOfAuctionId;

    // creator of tokenId
    mapping (uint256 =>  address) public tokenOfCreator;

    // admin addresses
    mapping (address => bool) public adminPool;

    // percent of transfer token
    mapping (uint256 =>  uint256) public creatorsPercents;

    uint256 public auctionCount = 1;
    uint256 public rateCount = 1;
    uint256 private tokensCounter = 0;


    modifier onlyAdmin() {
        require(adminPool[_msgSender()], "Caller is not the admin");
        _;
    }

    // Fee
    function setSystemFeePercent(uint256 percent) public onlyOwner(){
        systemPercent = percent;
    }

    function setMinBidAmount(uint256 _minBid) public onlyOwner(){
        minBid = _minBid;
    }

    function setSystemAddress(address _address) public onlyOwner(){
        systemAddress = _address;
    }

    function setRateStepPercent(uint256 percent) public onlyOwner(){
        rateStepPercent = percent;
    }

    function addToAdminPool(address _address) public onlyOwner() {
        adminPool[_address] = true;
    }

    function removeFromAdminPool(address _address) public onlyOwner() {
        adminPool[_address] = false;
    }

    // Create auctions
    function createTokenAndTimeAuction(uint256 startTime,uint256 endTime,uint256 minBidPrice,address tokenAddress,uint256 _creatorPercent) public  {
        uint256 tokenId = createToken(_creatorPercent);
        createTimeAuction(tokenId,startTime,endTime,minBidPrice,tokenAddress);
    }

    // Close auction by user
    function closeAuctionByUser(uint256 tokenId) public  {
        Auction memory auction = auctionOfToken[tokenId];
        require(auction.id != 0, "Auction not exist");

        require(ERC721.ownerOf(tokenId) == _msgSender(), "ERC721: transfer of token that is not own");

        if(auction.auctionType == timeAuction ){
            require(rateOfAuctionId[auction.id].id == 0, "Auction have rate");
            delete auctionOfToken[tokenId];
            delete rateOfAuctionId[auction.id];
            emit CloseAuction(tokenId,address(0),0,auction.id);

        }

        if(auction.auctionType == simpleAuction){
            delete auctionOfToken[tokenId];
            emit CloseAuction(auction.tokenId,address(0), 0,auction.id);
        }
    }

    // Change price auction by user
    function changeCostSimpleAuction(uint256 tokenId,uint256 newCost) public  {
        Auction memory auction = auctionOfToken[tokenId];

        require(ERC721.ownerOf(tokenId) == _msgSender(), "ERC721: transfer of token that is not own");
        require(newCost >= minBid, "Min amount error");

        if(auction.auctionType == simpleAuction){
            auction.minBidPrice = newCost;
            auctionOfToken[tokenId] = auction;
            emit ChangeMinBid(auction.id,newCost);
        }
    }

    // Close auction by admin
    function closeAuctionByAdminAndReturnRate(uint256 tokenId) onlyAdmin()  public  {
        Auction memory auction = auctionOfToken[tokenId];
        require(auction.id != 0, "Auction not exist");

        if(auction.auctionType == timeAuction ){
            delete auctionOfToken[tokenId];
            delete rateOfAuctionId[auction.id];
        }

        if(auction.auctionType == simpleAuction){
            delete auctionOfToken[tokenId];
        }

        returnRateToUser(tokenId);

        emit CloseAuction(auction.tokenId,address(0), 0,auction.id);
    }

    function closeAuctionByAdmin(uint256 tokenId) onlyAdmin()  public  {
        Auction memory auction = auctionOfToken[tokenId];
        require(auction.id != 0, "Auction not exist");

        if(auction.auctionType == timeAuction ){
            delete auctionOfToken[tokenId];
            delete rateOfAuctionId[auction.id];
        }

        if(auction.auctionType == simpleAuction){
            delete auctionOfToken[tokenId];
        }

        emit CloseAuction(auction.tokenId,address(0), 0,auction.id);
    }

    function returnRateToUser(uint256 tokenId) private  {
        Auction memory auction = auctionOfToken[tokenId];
        Rate memory oldRate = rateOfAuctionId[auction.id];

        if(oldRate.id != 0) {
            address payable owner = payable(address(uint160(oldRate.owner)));

            if(auction.tokenAddress == address(0)) {
                owner.transfer(oldRate.cost);
            } else {
                require(IERC20(auction.tokenAddress).transfer(owner,oldRate.cost),"Payment token transfer error.");
            }
        }
    }

    // Time auction
    function createTimeAuction(uint256 tokenId,uint256 startTime,uint256 endTime,uint256 minBidPrice,address tokenAddress) public  {
        require(auctionOfToken[tokenId].id == 0, "Auction is exist");

        require(_owners[tokenId] == _msgSender(), "Transaction sender not owner token");

        require(minBidPrice >= minBid, "Min amount error");

        _setAuctionToMap(tokenId,startTime,endTime,minBidPrice,timeAuction,tokenAddress);

        emit CreateAuction(tokenId,_msgSender(),minBidPrice,auctionOfToken[tokenId].id);
    }

    // Simple auction
    function createSimpleAuction(uint256 tokenId,uint256 minBidPrice,address tokenAddress) public  {
        require(auctionOfToken[tokenId].id == 0, "Auction is exist");

        require(_owners[tokenId] == _msgSender(), "Transaction sender not owner token");

        require(minBidPrice >= minBid, "Min amount error");


        _setAuctionToMap(tokenId,0,0,minBidPrice,simpleAuction,tokenAddress);

        emit CreateAuction(tokenId,_msgSender(),minBidPrice,auctionOfToken[tokenId].id);
    }

    function createTokenAndSimpleAuction(uint256 minBidPrice,address tokenAddress,uint256 _creatorPercent) public  {
        uint256 tokenId = createToken(_creatorPercent);
        createSimpleAuction(tokenId,minBidPrice,tokenAddress);
    }

    function createRate(uint256 tokenId,uint256 tokensAmount) public  payable  {
        require(auctionOfToken[tokenId].id != 0, "Auction not exist");

        Auction memory auction = auctionOfToken[tokenId];

        bool isBnbTransaction = auction.tokenAddress == address(0);

        if(isBnbTransaction) tokensAmount = msg.value;


        if(auction.auctionType == timeAuction ){
            uint256 nextStepPercent = tokensAmount.mul(100).div(auction.minBidPrice) - 100;

            require(nextStepPercent >= rateStepPercent, "Cost should be greater than min price {rateStepPercent}%");
            require(auction.endTime >  block.timestamp && auction.startTime <  block.timestamp,'The auction time error');

            if(!isBnbTransaction){
                require(IERC20(auction.tokenAddress).allowance(_msgSender(), address(this)) >= tokensAmount,"Tokens not approve");
                require(IERC20(auction.tokenAddress).transferFrom(_msgSender(), address(this),tokensAmount),"Payment token transfer error.");
            }

            auctionOfToken[tokenId].minBidPrice = tokensAmount;

            _setRateToAuction(auction.id,_msgSender(),tokensAmount,tokenId);
            emit CreateRate(auction.id,_msgSender(),tokensAmount);
        }


        if(auction.auctionType == simpleAuction){
            require(tokensAmount >= auction.minBidPrice, "Cost should be greater than min price");
            address payable owner = payable(address(uint160(ERC721.ownerOf(auction.tokenId))));
            address payable _systemAddress = payable(address(uint160(systemAddress)));
            address payable _creatoAddress = payable(address(uint160(tokenOfCreator[tokenId])));

            // Transfer token to new owner
            _safeTransfer(owner, _msgSender(), auction.tokenId, '');
            // Process Payment
            uint256 creatorPercent = creatorsPercents[tokenId];
            uint256 ownerPercent = 100 - creatorPercent - systemPercent;

            //Send money to old owner
            if(!isBnbTransaction) {
                require(IERC20(auction.tokenAddress).transferFrom(_msgSender(), owner, getQuantityByTotalAndPercent(tokensAmount,ownerPercent)),"Payment token transfer error.");
                //Send money to creator
                require(IERC20(auction.tokenAddress).transferFrom(_msgSender(), _creatoAddress, getQuantityByTotalAndPercent(tokensAmount,creatorPercent)),"Payment token transfer error.");
                //Send money to system
                require(IERC20(auction.tokenAddress).transferFrom(_msgSender(), _systemAddress, getQuantityByTotalAndPercent(tokensAmount,systemPercent)),"Payment token transfer error.");
            } else {
                //Send money to old owner
                owner.transfer(getQuantityByTotalAndPercent(msg.value,ownerPercent));
                //Send money to creator
                _creatoAddress.transfer(getQuantityByTotalAndPercent(msg.value,creatorPercent));
                //Send money to system
                _systemAddress.transfer(getQuantityByTotalAndPercent(msg.value,systemPercent));
            }

            delete auctionOfToken[tokenId];

            emit CloseAuction(auction.tokenId,_msgSender(),tokensAmount,auction.id);
        }
    }

    function getMinBidFromAuction(uint256 tokenId) public view returns (uint256) {
        require(auctionOfToken[tokenId].id != 0, "Auction not exist");
        Auction memory auction = auctionOfToken[tokenId];
        uint256 minAmount = 0;

        if(auction.auctionType == timeAuction ){
            minAmount = (100 + rateStepPercent + 1).mul(auction.minBidPrice).div(100);
        }


        if(auction.auctionType == simpleAuction){
            minAmount = auction.minBidPrice;
        }
        require(minAmount > 0, "Cost should be greater than min price");
        return minAmount;
    }

    function _setAuctionToMap(uint256 _tokenId, uint256 _startTime, uint256 _endTime, uint256 _minBidPrice,uint256 _auctionType,address tokenAddress) private {
        Auction memory auction;

        auction.tokenId = _tokenId;
        auction.id = auctionCount;
        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.minBidPrice = _minBidPrice;
        auction.auctionType = _auctionType;
        auction.tokenAddress = tokenAddress;

        auctionOfToken[_tokenId] = auction;

        auctionCount++;
    }

    function _setRateToAuction(uint256 auctionId,address rateOwnAddress,uint256 cost,uint256 tokenId) private {
        Rate memory oldRate = rateOfAuctionId[auctionId];
        Auction memory auction = auctionOfToken[tokenId];


        if(oldRate.id != 0) {
            address payable owner = payable(address(uint160(oldRate.owner)));

            if(auction.tokenAddress == address(0)) {
                owner.transfer(oldRate.cost);
            } else {
                require(IERC20(auction.tokenAddress).transfer(owner,oldRate.cost),"Payment token transfer error.");
            }
        }

        Rate memory rate;
        rate.cost = cost;
        rate.owner = rateOwnAddress;
        rate.id = rateCount;

        rateCount = rateCount + 1;
        rateOfAuctionId[auctionId] = rate;
    }

    function checkPendingAuction(uint256 tokenId) public {

        Auction memory auction = auctionOfToken[tokenId];

        require(auction.endTime <  block.timestamp,'This is active auction');

        Rate memory maxRate = rateOfAuctionId[auction.id];

        if(maxRate.owner != address(0)) {
            address payable owner = payable(address(uint160(ERC721.ownerOf(tokenId))));
            address payable _systemAddress = payable(address(uint160(systemAddress)));
            address payable _creatoAddress = payable(address(uint160(tokenOfCreator[tokenId])));

            // Transfer token
            _safeTransfer(owner, maxRate.owner, auction.tokenId, '');
            // Process Payment
            uint256 creatorPercent = creatorsPercents[tokenId];
            uint256 ownerPercent = 100 - creatorPercent - systemPercent;

            if(auction.tokenAddress == address(0)) {
                //Send money to old owner
                owner.transfer(getQuantityByTotalAndPercent(maxRate.cost,ownerPercent));
                //Send money to creator
                _creatoAddress.transfer(getQuantityByTotalAndPercent(maxRate.cost,creatorPercent));
                //Send money to system
                _systemAddress.transfer(getQuantityByTotalAndPercent(maxRate.cost,systemPercent));
            } else {
                //Send money to old owner
                require(IERC20(auction.tokenAddress).transfer(owner, getQuantityByTotalAndPercent(maxRate.cost,ownerPercent)),"Payment token transfer error.");
                //Send money to system
                require(IERC20(auction.tokenAddress).transfer(_systemAddress, getQuantityByTotalAndPercent(maxRate.cost,systemPercent)),"Payment token transfer error.");
                //Send money to creator
                require(IERC20(auction.tokenAddress).transfer(_creatoAddress, getQuantityByTotalAndPercent(maxRate.cost,creatorPercent)),"Payment token transfer error.");
            }

        }
        delete auctionOfToken[tokenId];
        delete rateOfAuctionId[auction.id];

        emit CloseAuction(tokenId,maxRate.owner, maxRate.cost,auction.id);
    }

    // Create tokens
    function createToken(uint256 _creatorPercent) public returns(uint256)  {
        require(_creatorPercent <= 50 , "Max limit 50 percents");
        uint256 tokenId = tokensCounter;
        _safeMint(_msgSender(), tokenId);

        tokenOfCreator[tokenId] = _msgSender();

        creatorsPercents[tokenId] = _creatorPercent;
        emit TokenCreated(tokenId,_msgSender());
        return tokenId;
    }

    function createMultipleTokens(uint count) public returns(uint256[] memory)  {
        require(count <= 50 , "Max limit 50 tokens");
        uint256[] memory tokensArray = new uint256 [](count);

        for (uint i = 0; i < count; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(_msgSender(), tokenId);
            tokensArray[i] = tokenId;
        }
        emit MultipleTokenCreated(tokensArray,_msgSender());
        return tokensArray;
    }

    function getQuantityByTotalAndPercent(uint256 totalCount,uint256 percent) public pure returns (uint256) {

        if(percent == 0)
            return 0;

        require(percent <= 100 ,'Incorrect percent');

        return totalCount.mul(percent).div(100);
    }

    function changeTokensOwner(address newAddress) public {
        uint256 [] memory tokens = tokensOfOwner(_msgSender());

        for (uint i = 0; i < tokens.length; i++) {
            _safeTransfer(_msgSender(), newAddress, tokens[i], '');
            tokenOfCreator[tokens[i]] = newAddress;
        }
    }


    function withDraw(address _address) public onlyOwner(){
        address payable owner = payable(address(uint160(_msgSender())));

        if(_address == address(0)){
            owner.transfer(address(this).balance);
        } else {
            require(IERC20(_address).transfer(_msgSender(),IERC20(_address).balanceOf(address(this))),"Payment token transfer error.");
        }
    }

    // Token name
    string private _name='Artbay';

    // Token symbol
    string private _symbol='ARTBAY';


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
        return "https://artbay.com/token/";
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
        tokensCounter += 1;
        _owners[tokenId] = to;


        emit Transfer(address(0), to, tokenId);
    }


    function burn(uint256 tokenId) public onlyAdmin() {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _balances[owner] -= 1;
        _owners[tokenId] = address(0);

        emit Transfer(owner,address(0), tokenId);
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

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _ownedTokens[from].pop();
    }

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