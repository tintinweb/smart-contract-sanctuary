// SPDX-License-Identifier: MIT

//Assignment 4 BCC Q3
//PIAIC ROLL # PIAIC79180 Name Abdul Basit Abbasi
//deployment address 0x8f4a69c79667ED87016AE2B83702E388569F1FB9


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

contract myNFT is IERC165, IERC721 {
    
    mapping(address => uint) balances;
    mapping(uint => address) owners;
    mapping(uint => address) tokenApproval;
    mapping(address => mapping(address => bool)) approvalForAll;
    address contractOwner;
    uint price;
    uint public totalSupply;
    string public Name;
    string public symbol;
    string URI;
    uint saleTime;
    uint supplyCount;

    
    constructor() {
        
            contractOwner = msg.sender;
            price = 1000000000;
            totalSupply = 3;
            Name = "myNFT";
            symbol = "MNFT";
            URI = "https://my-json-server.typicode.com/Abasit0097/YatchNFT/nfts/";
            saleTime = block.timestamp;
    }

    

    
        function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
            
            return interfaceId == type(IERC721).interfaceId;
            
        }
        
        function balanceOf(address owner) external view override returns (uint256 balance) {
            
            require(owner != address(0), "Address can not be zero address");
            
            return balances[owner];
                
        }

        function ownerOf(uint256 tokenId) external view override returns (address) {
            
            address owner = owners[tokenId];
            
            require(owner != address(0), "Address can not be zero address");
            
            return owner;
            
        }
        
        function safeTransferFrom(address from, address to,uint256 tokenId) external override {
            
            require(msg.sender == owners[tokenId] || msg.sender == tokenApproval[tokenId] || isApprovedForAll(msg.sender, to) == true, "Only owner or Approvee can transfer token");
            require(from != address(0) && to != address(0) && to != owners[tokenId], "Address can not be Zero Address or Already owner of Tokken");
            require(from == owners[tokenId] || from == tokenApproval[tokenId] || isApprovedForAll(from, to) == true, "Only owner or Approver can transfer Token");
            
            balances[from] -= 1;
            balances[to] += 1;
            owners[tokenId] = to;
            
            emit Approval (from, to, tokenId);
            
        }
        
        function transferFrom(address from, address to, uint256 tokenId) external override {
            
            require(msg.sender == owners[tokenId] || msg.sender == tokenApproval[tokenId] || isApprovedForAll(msg.sender, to) == true, "Only owner or Approvee can transfer token");
            require(from != address(0) && to != address(0), "Address can not be Zero Address");
            require(from == owners[tokenId] || from == tokenApproval[tokenId] || isApprovedForAll(from, to) == true, "Only owner or Approver can transfer Token");
            
            balances[from] -= 1;
            balances[to] += 1;
            owners[tokenId] = to;
            
            emit Approval (from, to, tokenId);
        }
        
        function approve(address to, uint256 tokenId) external override {
            
            address owner = owners[tokenId];
            
            require(owner != to, "Owner can not get approval");
            require(msg.sender == owner, "Owner can call this function");
            
           _approve(to, tokenId);
            
            
            emit Approval(owner, to, tokenId);
            
        
        
        }
        
        function _approve(address to, uint256 tokenId) internal {
            
            tokenApproval[tokenId] =  to;
        }
        
        function getApproved(uint256 tokenId) external view override returns (address operator) {
            
            require(_exist(tokenId), "TokenID does Not exist");
            
            return tokenApproval[tokenId];
            
        }
        
        function _exist(uint tokenId) internal view returns(bool) {
            
            return owners[tokenId] != address(0);
        }
        
        function setApprovalForAll(address operator, bool _approved) external override {
            require(msg.sender != operator, "owner can not be operator");
            require(balances[msg.sender]>=1, "you do not have any token");
            
            approvalForAll[msg.sender][operator] = _approved;
            emit ApprovalForAll(msg.sender,operator,_approved);
        }
        
        function isApprovedForAll(address owner, address operator) public view override returns (bool) {
            
            return approvalForAll[owner][operator];
        }
        
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external override {
            
            require(msg.sender == owners[tokenId] || msg.sender == tokenApproval[tokenId] || isApprovedForAll(msg.sender, to) == true, "Only owner or Approvee can transfer token");
            require(from != address(0) && to != address(0), "Address can not be Zero Address");
            require(from == owners[tokenId] || from == tokenApproval[tokenId] || isApprovedForAll(from, to) == true, "Only owner or Approver can transfer Token");
            
            balances[from] -= 1;
            balances[to] += 1;
            owners[tokenId] = to;
            
            emit Approval (from, to, tokenId);
        }
        
        function mint(uint tokenId) external {
            
            require(msg.sender == contractOwner && supplyCount < totalSupply, "Only owner can mint token or Total supplt reached");
            require(_exist(tokenId) == false && contractOwner != address(0), "Token Id Already exist or invalid address");
            
            balances[contractOwner] += 1;
            owners[tokenId] = contractOwner;
            supplyCount++;
            
            emit Transfer (address(0),contractOwner,tokenId);
        }
        
        function baseURI(string memory tokenId) external view returns (string memory) {
            return bytes(URI).length > 0 ? string(abi.encodePacked(URI,tokenId)) : "";
        }
        
        function buyToken(uint tokenId) external payable {
            require(_exist(tokenId), "Token does not exist");
            require(msg.sender != contractOwner && msg.sender != owners[tokenId], "Owner can not buy token");
            require(msg.value == price, "Please enter correct amount");
            require(block.timestamp >= saleTime + 5 minutes && block.timestamp <= saleTime + 30 days, "Not a sale time");
            
            balances[msg.sender] +=1;
            balances[contractOwner] -=1;
            owners[tokenId] = msg.sender;
        }
        
        function setPrice(uint amount) external {
            require(msg.sender == contractOwner, "Owner can change price");
            price = amount;
        }
        
}

