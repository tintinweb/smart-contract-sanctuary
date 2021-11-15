pragma solidity ^0.8.0;

/*

      |>(|)<|
      .-'^'-.
     '/"'"^"\'
    :( *   * ):
    ::)  ,| (::
    '(       )'          _.
     '\ --- /'          / /
   .-'       '-.      .__D
 ,"      |      \    / : (=|
:   Y    |    \  \  /  : (=|
|   |o__/ \__o:   \/  " \ \
|   |          \     '   "-.
|    `.    ___ \:._.'
 ".__  "-" __ \ \
  .|''---''------|               _
  / -.          _""-.--.        C )
 '    '/.___.--'        '._    : |
|     --_   ^"--...__      ''-.' |
|        ''---.o)    ""._        |
 ^'--.._      |o)        '`-..._./
        '--.._|o)
              'O)

*/

/* proof is:

0x63b8398f3ebcf782015a0019a4300bc20e74cf94e6626e4b18f93dd85d150f34

*/
interface IERC20 {
    function mint(address to, uint256 amount) external;
}

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash == root;
    }
}

contract Airdrop {
    IERC20 public immutable token;
    bytes32 public immutable merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(IERC20 token_, bytes32 merkleRoot_) {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(bytes calldata node, bytes32[] calldata merkleProof)
        external
    {
        uint256 index;
        uint256 amount;
        address recipient;
        (index, recipient, amount) = abi.decode(
            node,
            (uint256, address, uint256)
        );

        require(recipient == msg.sender);
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        require(
            MerkleProof.verify(merkleProof, merkleRoot, keccak256(node)),
            "MerkleDistributor: Invalid proof."
        );

        _setClaimed(index);
        token.mint(msg.sender, amount * 10 * 1 ether);
    }
}

