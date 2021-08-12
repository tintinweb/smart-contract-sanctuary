/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}






interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}





library MerkleProof {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}




interface IMerkleDistributor {
    function token() external view returns (address);
    function merkleRoot() external view returns (bytes32);
    function isClaimed(uint256 index) external view returns (bool);
    function claim(uint256 index, address account, uint256 amount, uint256 tokenId, bytes32[] calldata merkleProof) external;

    event Claimed(uint256 index, address account, uint256 amount);
}





contract ERC1155TokenReceiver {

   function onERC1155Received(
        address, /* _operator */
        address, /* _from */
        uint256, /* _id */
        uint256, /* _value */
        bytes calldata /* _data */
    ) external pure  returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

   
    function onERC1155BatchReceived(
        address, /* _operator */
        address, /* _from */
        uint256[] calldata, /* _ids */
        uint256[] calldata, /* _values */
        bytes calldata /* _data */
    ) external pure  returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}


pragma solidity =0.6.11;


contract MerkleDistributor is IMerkleDistributor, ERC1155TokenReceiver {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    bytes emptyData = bytes("");

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, uint256 tokenId, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        bytes32 node = keccak256(abi.encodePacked(index, account, amount, tokenId));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        _setClaimed(index);
        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, emptyData);
        emit Claimed(index, account, amount);
    }
}