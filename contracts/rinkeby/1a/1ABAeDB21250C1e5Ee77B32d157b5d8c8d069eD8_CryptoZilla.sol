// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/*
▒███████▒ ██▓ ██▓     ██▓    ▄▄▄
▒ ▒ ▒ ▄▀░▓██▒▓██▒    ▓██▒   ▒████▄
░ ▒ ▄▀▒░ ▒██▒▒██░    ▒██░   ▒██  ▀█▄
  ▄▀▒   ░░██░▒██░    ▒██░   ░██▄▄▄▄██
▒███████▒░██░░██████▒░██████▒▓█   ▓██▒
░▒▒ ▓░▒░▒░▓  ░ ▒░▓  ░░ ▒░▓  ░▒▒   ▓▒█░
░░▒ ▒ ░ ▒ ▒ ░░ ░ ▒  ░░ ░ ▒  ░ ▒   ▒▒ ░
░ ░ ░ ░ ░ ▒ ░  ░ ░     ░ ░    ░   ▒
  ░ ░     ░      ░  ░    ░  ░     ░  ░
*/

import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

interface Opensea {
    function balanceOf(address tokenOwner, uint tokenId) external view returns (bool);
    function safeTransferFrom(address _from, address _to, uint _id, uint _value, bytes memory _data) external;
}

contract CryptoZilla is ERC721, Ownable {

    event Arise(address indexed _to, uint indexed _tokenId);

    bytes32 public merkleRoot = ""; // Construct this from (oldId, newId) tuple elements
    //address public openseaSharedAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address public openseaSharedAddress = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public maxSupply = 1000; // Maximum tokens that can be minted
    uint public totalSupply = 0; // This is our mint counter as well
    string public _baseTokenURI;

    constructor() ERC721("CryptoZilla", "ZILLA") {}





    //    function batchMintAndBurn(uint256[] memory oldID, uint256[] memory newId, bytes32[] memory leaves, bytes32[j][] memory proofs) external {
    function batchMigration(uint256[] memory oldIds, uint256[] memory newIds, bytes32[] memory leaves, bytes32[][] memory proofs) external returns(address){
        for (uint i = 0; i < oldIds.length; i++) {
            // Don't allow reminting
            require(!_exists(newIds[i]), "Token already minted");

            // Verify that (oldId, newId) correspond to the Merkle leaf
            require(keccak256(abi.encodePacked(oldIds[i], newIds[i])) == leaves[i], "Ids don't match Merkle leaf");

            // Verify that (oldId, newId) is a valid pair in the Merkle tree
            //require(verify(merkleRoot, leaves[i], proofs[i]), "Not a valid element in the Merkle tree");

            // Verify that msg.sender is the owner of the old token
            require(Opensea(openseaSharedAddress).balanceOf(msg.sender, oldIds[i]), "Only token owner can mintAndBurn");
        } 

        for (uint j = 0; j < oldIds.length; j++) {
            Opensea(openseaSharedAddress).safeTransferFrom(msg.sender, burnAddress, oldIds[j], 1, "");
			_mint(msg.sender, newIds[j]);
			emit Arise(msg.sender, newIds[j]);
            totalSupply += 1;
		}
    }

    //the existing _exists function is private, but we need to access it from outside
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Updates the base token URI for the metadata
     */
    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}