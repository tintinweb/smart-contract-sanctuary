/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

contract CryptoPhunksV2 {
    function ownerOf(uint256 tokenId) external view returns (address owner) {}

    function balanceOf(address owner) external view returns (uint256 balance) {}

    function tokenURI(uint256 tokenId) public view returns (string memory) {}
}

contract Thunks {
    CryptoPhunksV2 phunks;

    constructor(address phunksAddress) {
        phunks = CryptoPhunksV2(phunksAddress);
    }

    function name() public view returns (string memory) {
        return "THUNKS";
    }

    function symbol() public view returns (string memory) {
        return "TH";
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return phunks.ownerOf(tokenId);
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return phunks.balanceOf(owner);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return phunks.tokenURI(tokenId);
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        revert();
    }

    function approve(address to, uint256 tokenId) external {
        revert();
    }

    function getApproved(uint256 tokenId) external view returns (address operator) {
        revert();
    }


    function setApprovalForAll(address operator, bool _approved) external {
        revert();
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        revert();
    }

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
}