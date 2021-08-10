/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IPartyApes is IERC721Metadata {

    function totalSupply() external view returns (uint256);

}

contract PredictPartyApes {
    address public partyApes;
    uint256 public maxToken = 1000;

    constructor(address _partyApes) {
        partyApes = _partyApes;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _random() internal view returns(uint256) {
        uint256 _mintedCount = IPartyApes(partyApes).totalSupply();
        return uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(_msgSender())))) / block.timestamp) + block.number))) / (maxToken - _mintedCount);
    }

    function predictTokenExist() external view returns (uint256, string memory) {
        uint256 _mintedCount = IPartyApes(partyApes).totalSupply();
        uint256 _randomTokenId = _random() % (maxToken - _mintedCount);

        // Will throw error if token id not exist
        string memory uri = IPartyApes(partyApes).tokenURI(_randomTokenId);

        // Return the exist token id
        return (_randomTokenId, uri);

    }
}