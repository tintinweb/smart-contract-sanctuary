/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity >=0.6.0 <0.8.4;


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// Administrators
// ----------------------------------------------------------------------------
contract Admined is Owned {

    mapping (address => bool) public admins;

    event AdminAdded(address addr);
    event AdminRemoved(address addr);

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address addr) public returns (bool) {
        return (admins[addr] || owner == addr);
    }
    function addAdmin(address addr) public onlyOwner {
        require(!admins[addr] && addr != owner);
        admins[addr] = true;
        emit AdminAdded(addr);
    }
    function removeAdmin(address addr) public onlyOwner {
        require(admins[addr]);
        delete admins[addr];
        emit AdminRemoved(addr);
    }
}



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


contract MetadataDeveryERC721Wrapper is IERC721, IERC721Metadata, Admined{


    address public token;
    IERC721 public tokenContract;
    mapping (uint256 => string) private _tokenURIs;

    function setERC721(address _token) public onlyAdmin {
        token = _token;
        tokenContract = IERC721(_token);
    }

    function balanceOf(address owner) public virtual override  view returns  (uint256 balance){
        return tokenContract.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public virtual override view returns (address owner){
        return tokenContract.ownerOf(tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override{
          (bool success, bytes memory data) = token.delegatecall(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from,to, tokenId)
        );
    }

    function transferFrom(address from, address to, uint256 tokenId )public virtual override{
         (bool success, bytes memory data) = token.delegatecall(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from,to, tokenId)
        );
    }

    function approve(address to, uint256 tokenId)public virtual override{
     (bool success, bytes memory data) = token.delegatecall(
            abi.encodeWithSignature("approve(address,uint256)",to, tokenId)
        );
    }

    function getApproved(uint256 tokenId) public virtual override view returns (address operator){
        return tokenContract.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool _approved) public virtual override{
         (bool success, bytes memory data) = token.delegatecall(
            abi.encodeWithSignature("setApprovalForAll(address,bool)",operator, _approved)
        );
    }

    function isApprovedForAll(address owner, address operator) public virtual override view returns (bool){
        return tokenContract.isApprovedForAll(owner, operator);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override{
         (bool success, bytes memory data) = token.delegatecall(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)",from, to, tokenId, data)
        );
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of a token can set its metadata");
        _tokenURIs[tokenId] = _tokenURI;
    }


    function supportsInterface(bytes4 interfaceId)  public virtual override view returns (bool){
        return true;
    }

    function name()  public virtual override view  returns (string memory){
        return "Devery NFT";
    }
    
    function symbol()  public virtual override view  returns (string memory){
        return "EVENFT";
    }
    
    function tokenURI(uint256 tokenId) public virtual override view returns (string memory){
        return _tokenURIs[tokenId];
    }
}