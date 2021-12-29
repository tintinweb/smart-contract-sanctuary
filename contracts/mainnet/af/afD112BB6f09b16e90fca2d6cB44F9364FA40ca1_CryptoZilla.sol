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
import "./ZillaToken.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

interface Opensea {
    function balanceOf(address tokenOwner, uint tokenId) external view returns (bool);

    function safeTransferFrom(address _from, address _to, uint _id, uint _value, bytes memory _data) external;
}

contract ERC721Namable is ERC721 {

    uint256 public nameChangePrice = 200 ether;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    event NameChange (uint256 indexed tokenId, string newName);

    constructor(string memory _name, string memory _symbol, string[] memory _names, uint256[] memory _ids) ERC721(_name, _symbol) {
        for (uint256 i = 0; i < _ids.length; i++)
        {
            toggleReserveName(_names[i], true);
            _tokenName[_ids[i]] = _names[i];
            emit NameChange(_ids[i], _names[i]);
        }
    }

    function changeName(uint256 tokenId, string memory newName) public virtual {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false;
        // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false;
        // Leading space
        if (b[b.length - 1] == 0x20) return false;
        // Trailing space

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false;
            // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    /**
    * @dev Converts the string to lowercase
    */
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

contract CryptoZilla is ERC721Namable, Ownable {

    event Arise(address indexed _to, uint indexed _tokenId);

    bytes32 public merkleRoot = ""; // Construct this from (oldId, newId) tuple elements
    address public openseaSharedAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public communityWallet = 0x6957671Aed561dDb564BC8F8e4f87CAC547ab377;
    uint public maxSupply = 1000; // Maximum tokens that can be minted
    uint public totalSupply = 0; // This is our mint counter as well
    string public _baseTokenURI;
    ZillaToken public zillaToken;
    mapping(address => uint256) public zillaBalance;

    constructor(string[] memory _names, uint256[] memory _ids) ERC721Namable("CryptoZilla", "ZILLA", _names, _ids){}

    function batchMigration(uint256[] memory oldIds, uint256[] memory newIds, bytes32[] memory leaves, bytes32[][] memory proofs) external {
        require(oldIds.length == newIds.length && newIds.length == leaves.length, "Some Data is missing (parameters have different sizes)");

        uint256 _amount = oldIds.length;
        // First check if all requirements are satisfied
        for (uint i = 0; i < _amount; i++) {
            // Don't allow reminting
            require(!_exists(newIds[i]), "Token already minted");

            // Verify that (oldId, newId) correspond to the Merkle leaf
            require(keccak256(abi.encodePacked(oldIds[i], newIds[i])) == leaves[i], "Ids don't match Merkle leaf");

            // Verify that (oldId, newId) is a valid pair in the Merkle tree
            require(verify(merkleRoot, leaves[i], proofs[i]), "Not a valid element in the Merkle tree");

            // Verify that msg.sender is the owner of the old token
            require(Opensea(openseaSharedAddress).balanceOf(msg.sender, oldIds[i]), "Only token owner can mintAndBurn");
        }

        // Mint new token
        for (uint j = 0; j < _amount; j++) {
            Opensea(openseaSharedAddress).safeTransferFrom(msg.sender, burnAddress, oldIds[j], 1, "");
            _mint(msg.sender, newIds[j]);
            totalSupply += 1;
            emit Arise(msg.sender, newIds[j]);
        }
        zillaBalance[msg.sender] += _amount;
        zillaToken.updateRewardOnArise(msg.sender, _amount);
    }

    //can only be called from owner to mint Zillas that were already burned before migration - the zilla will be sent to community wallet
    function mintBurnedZilla(uint256 oldId, uint256 newId) public onlyOwner {
        require(!_exists(newId), "Token already minted");
        require(Opensea(openseaSharedAddress).balanceOf(burnAddress, oldId), "Old Token still exists (isn't burned yet)");

        _mint(communityWallet, newId);
        emit Arise(communityWallet, newId);
        totalSupply += 1;
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

    // Sets the merkle root of the old - new token id tree
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Sets the ZillaToken contract address
    function setZillaToken(address _address) external onlyOwner {
        zillaToken = ZillaToken(_address);
    }

    // Let the user claim rewards
    function getReward() external {
        zillaToken.updateReward(msg.sender, address(0));
        zillaToken.getReward(msg.sender);
    }

    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function changeName(uint256 tokenId, string memory newName) public override {
        zillaToken.burn(msg.sender, nameChangePrice);
        super.changeName(tokenId, newName);
    }

    // Override the ERC-721 functions when trading the Genesis Zilla and update the $ZILLA mapping
    function transferFrom(address from, address to, uint256 tokenId) public override {
        zillaToken.updateReward(from, to);
        zillaBalance[from]--;
        zillaBalance[to]++;
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        zillaToken.updateReward(from, to);
        zillaBalance[from]--;
        zillaBalance[to]++;
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }
}