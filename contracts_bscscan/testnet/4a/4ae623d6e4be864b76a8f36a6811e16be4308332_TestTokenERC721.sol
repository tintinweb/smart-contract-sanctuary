/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract IContract{
    function recoverSigner(bytes32 message, bytes memory sig)
       internal
       pure
       returns (address)
    {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
  }
  function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
   {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
   }
}
/**
 * @title
 * @dev Implements ERC20 in combination with ERC721, and a transaction system between them.
 */
contract TestTokenERC721 is IContract {
    address private ChainOwner;
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;
    // Linked List with first, last
    mapping(uint256 => uint256) public _tokenLinkedList;
    uint256 public _lastTokenCreated;
    uint256 public _numberOfTokens;

    // The sale price of an token. Set to O if the item is not for sale
    mapping (uint256 => uint256) public salePrice;
    
    // Optional mapping for token URIs
    mapping(uint256 => string) public _tokenURIs;
    
    uint256[] public freeTokens;
    
    TestTokenERC20 public ERC20;
    
    constructor (){
        ChainOwner = _msgSender();
        ERC20 = new TestTokenERC20(ChainOwner, this);
    }
    /*
    constructor (address owner, TestTokenERC20 partner){
        ChainOwner = owner;
        ERC20 = partner;
    }
    // */
    /**
     * @dev Returns the token collection name.
     */
    function name() external pure returns (string memory){
        return "CheezeToken";
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external pure returns (string memory){
        return "CHZ";
    }
    
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function tokensOwned(address account) public view returns (uint256[] memory){
        uint256 iter = _tokenLinkedList[0x00];
        uint256[] memory result = new uint256[](_numberOfTokens);
        uint256 count;
        while (iter != 0x00)
        {
            if (_owners[iter] == account)
            {
                result[count] = iter;
                count++;
            }
            iter = _tokenLinkedList[iter];
        }
        uint256 freeTokenCount = freeTokens.length;
        uint256[] memory shrunkResult = new uint256[](count + freeTokenCount);
        for (uint256 i = 0; i < count; i++)
        {
            shrunkResult[i] = result[i];
        }
        for (uint256 i = 0; i<freeTokenCount; i++)
        {
            shrunkResult[i + count] = freeTokens[i];
        }
        return shrunkResult;
    }
    
    function balanceOf(address account) external view returns (uint256){
        uint256 iter = _tokenLinkedList[0x00];
        uint256[] memory result = new uint256[](_numberOfTokens);
        uint256 count;
        while (iter != 0x00)
        {
            if (_owners[iter] == account)
            {
                result[count] = iter;
                count++;
            }
            iter = _tokenLinkedList[iter];
        }
        uint256 freeTokenCount = freeTokens.length;
        
        return count + freeTokenCount;
    }
    /**
     * @dev Transfers `tokenId` token from `from` to `to` in ERC721.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public
    {
        require (from == msg.sender, "CHZ: Impersonating attack.");
        _transferERC721(from, to, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        require (from == msg.sender, "CHZ: Impersonating attack.");
        _transferERC721(from, to, tokenId);
    }
    
    /*
    function approve(address, uint256) external pure {
        _dontDoThis();
    }

    function setApprovalForAll(address, bool) external pure {
        _dontDoThis();
    }
    //*/
    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
     /*
    function getApproved(uint256 tokenId) external view returns (address operator){
        return _owners[tokenId];
    }
    //*/
    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
     /*
    function isApprovedForAll(address, address) external pure returns (bool)
    {
        return false;
    }
    //*/
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
    function _transferERC721(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        
        _owners[tokenId] = to;
        salePrice[tokenId] = 0;
    }
    
    function _transferERC721Partner(
        address from,
        address to,
        uint256 tokenId
    ) onlyPartnerContract public {
        _transferERC721(from, to, tokenId);
    }

    function setFreeTokens(uint256[] calldata tokens) public onlyOwner{
        freeTokens = tokens;
    }

    function mint(address to, uint256 tokenId) onlyOwner public {
        _mintERC721(to, tokenId);
    }

    function _mintERC721(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(tokenId != 0x00, "CHZ: token ID 0x00 is reserved.");

        _owners[tokenId] = to;
        _tokenLinkedList[_lastTokenCreated] = tokenId;
        _lastTokenCreated = tokenId;
        _numberOfTokens++;
        //require(_tokenLinkedList[_lastTokenCreated] == 0x00, "ERC721: unknown error - linked list loop.");
    }
    
    function ownsToken(address account, uint256 tokenId) internal view returns(bool){
        uint256 freeTokenCount = freeTokens.length;
        if (ownerOf(tokenId) == account){
            return true;
        }
        for (uint256 i = 0; i < freeTokenCount; i++)
        {
            if (tokenId == freeTokens[i])
                return true;
        }
        return false;
    }
    
    function breed(uint256 parent1, uint256 parent2) public {
        address to = _msgSender();
        require(ownsToken(to, parent1), "CHZ: parent 1 isn't owned.");
        require(ownsToken(to, parent2), "CHZ: parent 2 isn't owned.");
        require(parent1 != parent2, "CHZ: breeding same parent.");
        
        uint256 result;
        unchecked{
            // For byte 8-32, randomize function = circleshift(a,4,8) + b
            // circleshift 4 for each 8 bit segment
            uint256 circleshift = ((parent1 &
            0x00000000000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f)<<4) | ((parent1 &
            0x0000000000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0)>>4);
        
            // Add.
            uint256 statRandomize = (circleshift + parent2) &
            0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff;
            
            uint64 skills;
            uint64 refpar1;
            uint64 refpar2;
            uint64 random;
            random = uint64(statRandomize % 1000000007);
            // mainSkill
            if (random % 2 == 0) {
                refpar1 = uint64(parent1 >> 192);
                refpar2 = uint64(parent2 >> 192);
            }
            else {
                refpar1 = uint64(parent2 >> 192);
                refpar2 = uint64(parent1 >> 192);
            }
            skills = refpar1 & 0xffff000000000000;
            // secondarySkill
            if (random % 7 == 0) {
                skills = skills | ((refpar2 & 0xffff000000000000) >> 16);
            } else if (random % 7 < 4) {
                skills = skills |  (refpar1 & 0x0000ffff00000000);
            } else {
                skills = skills |  (refpar2 & 0x0000ffff00000000);
            }
            // supportSkill
            refpar1 = uint64(parent1 >> 192);
            refpar2 = uint64(parent2 >> 192);
            if (random % 5 < 2) {                               // 0,1
                skills = skills |  (refpar1 & 0x00000000ffff0000);
            } else {                                            // 2,3,4
                skills = skills | ((refpar1 & 0x000000000000ffff) << 16);
            }
            if ((random % 5) % 2 == 1) {                        // 1,3
                skills = skills | ((refpar2 & 0x00000000ffff0000) >> 16);
            } else if (random % 5 < 3) {                        // 0,2
                skills = skills |  (refpar2 & 0x000000000000ffff);
            } else {                                            // 4
                skills = skills | ((refpar1 & 0x00000000ffff0000) >> 16);
            }
            result = (uint256(skills) << 192) | statRandomize;
        }
        _mintERC721(to, result);
    }

    function _exists(uint256 tokenId) public view returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) public {
        address owner = ownerOf(tokenId);
        address sender = _msgSender();
        //require(owner != address(0), "ERC721URIStorage: URI set of nonexistent token");
        //ownerOf already checked for token exist.
        require(sender == owner || sender == ChainOwner, "ERC721URIStorage: not authorized.");
        _tokenURIs[tokenId] = _tokenURI;
    }
    /**
    function _approve(
        address,
        address,
        uint256
    ) internal pure {
        _dontDoThis();
    }
    
    function _dontDoThis() private pure {
        revert("CHZ: Not supported.");
    }
    //*/
    /**
     * The token is put on the market at the sale price.
     * Requirements:
     *  The sender of this message owns the token to be put on sale.
     */
    function setSalePrice(uint256 tokenId, uint256 price) public {
        require(msg.sender == ownerOf(tokenId), "CHZ: You don't own this token.");
        salePrice[tokenId] = price;
    }
    
    function cancelSale(uint256 tokenId) public {
        setSalePrice(tokenId, 0);
    }
    
    function buy(uint256 tokenId) public {
        uint256 buyPrice = salePrice[tokenId];
        require(buyPrice != 0, "CHZ: This token is not for sale.");
        address seller = ownerOf(tokenId);
        address buyer = msg.sender;
        ERC20._transferERC20Partner(buyer, seller, buyPrice);
        _transferERC721(seller, buyer, tokenId);
    }
    
    function buyWithBudget(uint256 tokenId, uint256 budget) public {
        require (budget >= salePrice[tokenId], "CHZ: Overbudget.");
        buy(tokenId);
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function getSalePrice(uint256 tokenId) public view returns (uint256){
        uint256 buyPrice = salePrice[tokenId];
        require(buyPrice != 0, "CHZ: This token is not for sale.");
        return buyPrice;
    }
    function browseMarketItems(uint256 indexFirst, uint256 amount) public view returns (uint256[] memory) {
        uint256 iter = _tokenLinkedList[0x00];
        uint256[] memory result = new uint256[](amount);
        uint256 count;
        while (iter != 0x00 && count < amount)
        {
            uint256 _salePrice = salePrice[iter];
            if (_salePrice != 0)
            {
                if (indexFirst > 0) {
                    indexFirst--;
                } else {
                    result[count] = iter;
                    count++;
                }
            }
            iter = _tokenLinkedList[iter];
        }
        return result;
    }
    
    /**
     * The message sender buys the tokenID with the sellPrice using an external Coupon.
     * The coupon is overridden by the sale price on this contract.
     * Requirements:
     *  The token exists.
     *  The buyer have enough money buy.
     *  The item is not on sale currently.
     *  The Coupon is real.
     */
    function buyWithCoupon(uint256 tokenId, uint256 sellPrice, bytes calldata signature) public {
        address seller = _owners[tokenId];
        address buyer = _msgSender();
        require (_exists(tokenId), "CHZ: this token does not exist");
        require (ERC20.balanceOf(buyer) >= sellPrice, "CHZ: you don't have enough to buy this token");
        require (getSalePrice(tokenId) == 0, "CHZ: this item is on sale on this contract, please set the price back to 0 to allow use of coupon or buy on this contract.");
        
        bytes32 message = keccak256(abi.encodePacked(tokenId, sellPrice, seller));
        require (recoverSigner(message, signature) == seller, "CHZ: the coupon is not valid");
        
        ERC20._transferERC20Partner(buyer, seller, sellPrice);
        _transferERC721(seller, buyer, tokenId);
    }
    
    function checkRealCoupon(uint256 tokenId, uint256 sellPrice, address seller, bytes calldata signature) pure public returns (bool) {
        if (signature.length != 65)
            return false;
        bytes32 message = keccak256(abi.encodePacked(tokenId, sellPrice, seller));
        return recoverSigner(message, signature) == seller;
    }
   modifier onlyOwner(){
       require(_msgSender() == ChainOwner);
       _;
   }
   modifier onlyPartnerContract(){
       require(address(ERC20) == _msgSender(), "CHZ-721: You're not my partner CHZ-20.");
       _;
   }
}


/**
 * @title
 * @dev Implements ERC20 in combination with ERC721, and a transaction system between them.
 */
contract TestTokenERC20 is IContract{
    address private ChainOwner;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    
    //Strategy functionStrategy;
    uint256 private _excessCurrency;
    uint64 private _levelField;
    
    // 1 unit ETH => _ethExchangeRate unit CHZ.
    uint128 public _ethExchangeRate;
    
    uint256 public _totalSupply;
    
    TestTokenERC721 public ERC721;
    /*
    constructor (){
        ChainOwner = _msgSender();
        _mintERC20(_msgSender(), 10**27);
        _ethExchangeRate = 100;
        ERC721 = new TestTokenERC721(ChainOwner, this);
    }
    // */
    constructor (address owner, TestTokenERC721 partner){
        ChainOwner = owner;
        _mintERC20(owner, 10**27);
        _ethExchangeRate = 100;
        ERC721 = partner;
    }
    
    /**
     * @dev Returns the token collection name.
     */
    function name() external pure returns (string memory){
        return "CheezeToken";
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external pure returns (string memory){
        return "CHZ";
    }
    
    /*
    function approve(address, uint256) external pure {
        _dontDoThis();
    }

    function setApprovalForAll(address, bool) external pure {
        _dontDoThis();
    }
    //*/
    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
     /*
    function getApproved(uint256 tokenId) external view returns (address operator){
        return _owners[tokenId];
    }
    //*/
    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
     /*
    function isApprovedForAll(address, address) external pure returns (bool)
    {
        return false;
    }
    //*/

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Balance of the money
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        _transferERC20(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
     /*
    function allowance(address, address) public pure   returns (uint256) {
        return 0;
    }
    //*/
    
    /**
     * Transfer money from one user to another
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public  returns (bool) {
        require (sender == msg.sender, "CHZ: Impersonating attack.");
        _transferERC20(sender, recipient, amount);

        return true;
    }
/*
    function increaseAllowance(address, uint256) public pure  returns (bool) {
        _dontDoThis();
    }
    function decreaseAllowance(address, uint256) public pure returns (bool) {
        _dontDoThis();
    }
//*/
    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transferERC20(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
    }
    function _transferERC20Partner(
        address sender,
        address recipient,
        uint256 amount
    ) onlyPartnerContract public {
        _transferERC20(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mintERC20(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }
    
    function mint(address to, uint256 amount) public payable {
        if (_msgSender() == ChainOwner)
            _mintERC20(to, amount);
        else {
            require(msg.value * _ethExchangeRate == amount, "CHZ: invalid amount");
            
            _mintERC20(to, msg.value * _ethExchangeRate);
        }
    }
    
    function addExcessCurrency(uint256 excess) public onlyOwner {
        _excessCurrency += excess;
    }
    
    function mintWithGameplay(address loser, uint timestamp, bytes calldata signature) public {
        require(_levelField != 0, "CHZ: FUNCTION DISABLED.");
        require(block.timestamp - timestamp < 1 days, "CHZ: Too late.");
        bytes32 message = keccak256(abi.encodePacked(loser, timestamp, "I lost."));
        require(recoverSigner(message, signature) == loser, "CHZ: Fake signature.");
        uint256 amount = seqBase(_excessCurrency / _levelField);
        _mintERC20(_msgSender(), amount);
    }
    
    function WinAmount() view public returns (uint256) {
        return seqBase(_excessCurrency / _levelField);
    }
    // 1+2+3+... + y = x = y(y+1)/2 => 8x + 1 = (2y + 1)^2
    function seqBase(uint256 x) internal pure returns (uint256 y) {
        x = x * 8 + 1;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        y = (y - 1) / 2;
    }
    
    function setExchangeRate(uint128 exchangeRate) public onlyOwner{
        _ethExchangeRate = exchangeRate;
    }
    
    function withdrawEth(uint256 amount) public {
        address to = _msgSender();
        uint256 balance = balanceOf(to);
        require(balance >= amount, "CHZ: Insufficient funds.");
        uint256 ethToSend = amount / _ethExchangeRate;
        _balances[to] = balance - ethToSend * _ethExchangeRate;
        (bool result, ) = to.call{value: ethToSend}("");
        require(result, "CHZ: failed to send Ether.");
    }
    /**
    function _approve(
        address,
        address,
        uint256
    ) internal pure {
        _dontDoThis();
    }
    
    function _dontDoThis() private pure {
        revert("CHZ: Not supported.");
    }
    //*/
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    /**
     * The message sender buys the tokenID with the sellPrice using an external Coupon.
     * The coupon is overridden by the sale price on this contract.
     * Requirements:
     *  The token exists.
     *  The buyer have enough money buy.
     *  The item is not on sale currently.
     *  The Coupon is real.
     */
   modifier onlyOwner(){
       require(_msgSender() == ChainOwner);
       _;
   }
   modifier onlyPartnerContract(){
       require(address(ERC721) == _msgSender(), "CHZ-20: You're not my partner CHZ-721.");
       _;
   }
}