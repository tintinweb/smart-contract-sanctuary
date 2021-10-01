/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title 
 * @dev Implements ERC20 in combination with ERC721, and a transaction system between them.
 */
contract TestToken {
    address private ChainOwner;
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // List of tokens from 0..n
    mapping(uint64 => uint256) private tokenList;
    uint64 private tokenAmount;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    
    // The sale price of an token. Set to O if the item is not for sale
    mapping (uint256 => uint256) private salePrice;
    
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    
    
    uint256 private _totalSupply;
    
    constructor (){
        ChainOwner = _msgSender();
        _mintERC20(_msgSender(), 10**27);
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
    
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function tokensOwned(address account) public view returns (uint256[] memory){
        uint256[] memory ownedToken = new uint256[](tokenAmount);
        uint64 amount = 0;
        for (uint64 i = 0; i<tokenAmount; i++)
        {
            uint256 token = tokenList[i];
            if (ownerOf(token) == account){
                ownedToken[amount] = token;
                amount++;
            }
        }
        uint256[] memory result = new uint256[](amount);
        for (uint64 i=0;i<amount; i++){ 
            result[i] = ownedToken[i];
        }
        return result;
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
    ) external
    {
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
    function getApproved(uint256 tokenId) external view returns (address operator){
        return _owners[tokenId];
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address, address) external pure returns (bool)
    {
        return false;
    }


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
    function allowance(address, address) public pure   returns (uint256) {
        return 0;
    }
    
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
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        salePrice[tokenId] = 0;
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
    function _mintERC20(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }
    
    function mint(address to, uint256 tokenId) public {
        require(_msgSender() == ChainOwner, "CHZ: must be owner to mint");
        _mintERC721(to, tokenId);
    }
    
    function _mintERC721(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = to;
        tokenList[tokenAmount] = tokenId;
        tokenAmount++;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
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
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
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
        _transferERC20(buyer, seller, buyPrice);
        _transferERC721(seller, buyer, tokenId);
    }
    
    function buyWithBudget(uint256 tokenId, uint256 budget) public {
        require (budget > salePrice[tokenId], "CHZ: Overbudget.");
        buy(tokenId);
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}