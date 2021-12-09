// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./IERC1155_EXT.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ERC1155.sol";
import "./IERC1155Receiver.sol";

contract OpenChestOfFortune is
    VRFConsumerBase,
    IERC1155_EXT,
    ERC1155,
    Ownable,
    IERC1155Receiver
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IERC1155_EXT public nft;

    uint256 public nextID = 1;

    mapping(uint256 => address) internal _tokenMaker;
    mapping(uint256 => uint256) internal _tokenInitAmount;

    mapping(uint256 => EnumerableSet.AddressSet) internal _tokenIdToOwners;
    mapping(address => EnumerableSet.UintSet) internal _ownedTokens;
    mapping(uint256 => string) internal _tokenIdToHash;
    mapping(uint256 => uint256) internal _tokenInitAmountHandler;

    string[] private commonRewards;
    string[] private rareRewards;
    string[] private superRareRewards;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private randomResult;
    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => uint256) public requestIdToRequestNumberIndex;
    mapping(uint256 => address) public requestNumberToId;
    mapping(address => bool) public mintProgress;
    mapping(uint256 => bool) validTokenId;

    uint256 public requestCounter;
    uint256 public fulfilledCounter;

    event MintTreasure(
        address _owner,
        uint256 _amount,
        string _hash,
        uint256 _tokenID
    );
    event DestroyTreasure(address _owner, uint256 _tokenID, uint256 _amount);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: BSC Mainnet
     * Chainlink VRF Coordinator address: 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31
     * LINK token address:                0x404460C6A5EdE2D891e8297795264fDe62ADBB75
     * Key Hash: 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c
     * Fee :     0.2 * 10 ** 18 //0.2 LINK
     *
     *
     * Network: BSC Testnet
     * Chainlink VRF Coordinator address: 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C
     * LINK token address:                0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
     * Key Hash: 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186
     * Fee :     0.1 * 10 ** 18 //0.1 LINK
     */
    constructor(address _nftAddress)
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK Token
        )
        ERC1155("https://ipfs.io/ipfs/")
    {
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10**18;
        require(
            _nftAddress.isContract() &&
                _nftAddress != address(0) &&
                _nftAddress != address(this)
        );
        nft = IERC1155_EXT(_nftAddress);
    }

    function openChest(
        address to,
        uint256 value,
        string memory _hash,
        bytes memory data
    ) internal {
        emit MintTreasure(to, 1, _hash, nextID);
        _mint(to, nextID, value, data);
        processSetHashFromMint(_hash);
    }

    function destroyYourTreasure(uint256 id, uint256 value) public {
        require(_ownedTokens[_msgSender()].contains(id), "Not Token Owner");
        emit DestroyTreasure(_msgSender(), id, value);
        _burn(_msgSender(), id, value);
        burnHashHandler(id, value);
    }

    function burnHashHandler(uint256 id, uint256 value) internal {
        _tokenInitAmountHandler[id] = _tokenInitAmountHandler[id] - value;
        if (_tokenInitAmountHandler[id] == 0) {
            delete _tokenIdToHash[id];
        }
    }

    function ownerOf(address owner, uint256 id)
        external
        view
        override
        returns (bool)
    {
        return _ownedTokens[owner].contains(id);
    }

    function getHashFromTokenID(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenIdToHash[tokenId];
    }

    function getTokenAmount(address owner)
        external
        view
        override
        returns (uint256)
    {
        return _ownedTokens[owner].length();
    }

    function getHashBatch(uint256[] memory tokenIds)
        external
        view
        returns (string[] memory)
    {
        string[] memory tokenHash = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenHash[i] = getHashFromTokenID(tokenIds[i]);
        }
        return tokenHash;
    }

    function getOwnersFromTokenId(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {
        uint256 index = _tokenIdToOwners[tokenId].length();
        address[] memory owners = new address[](index);
        for (uint256 i; i < index; i++) {
            owners[i] = _tokenIdToOwners[tokenId].at(i);
        }
        return owners;
    }

    function getTokenMaker(uint256 tokenId) external view returns (address) {
        return _tokenMaker[tokenId];
    }

    function getTokenInitAmount(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _tokenInitAmount[tokenId];
    }

    function getAllTokenHash(address owner)
        external
        view
        returns (string[] memory)
    {
        uint256[] memory tokenIds = this.getAllTokenIds(owner);
        string[] memory tokenHash = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenHash[i] = getHashFromTokenID(tokenIds[i]);
        }
        return tokenHash;
    }

    function getAllTokenIds(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 index = _ownedTokens[owner].length();
        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokenIds[i] = _ownedTokens[owner].at(i);
        }
        return tokenIds;
    }

    function processSetHashFromMint(string memory newHash) private {
        require(bytes(newHash).length > 0, "hash_ can not be empty string");
        setHashToTokenID(nextID, newHash);
        nextID++;
    }

    function setHashToTokenID(uint256 tokenId, string memory newHash) internal {
        _tokenIdToHash[tokenId] = newHash;
    }

    function updateTokenID(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        if (from == address(0)) {
            _tokenMaker[id] = to;
            _tokenInitAmount[id] = amount;
            _tokenInitAmountHandler[id] = amount;
        }

        if (from != address(0)) {
            uint256 fromBalance = balanceOf(from, id);
            if (amount == fromBalance) {
                _ownedTokens[from].remove(id);
                _tokenIdToOwners[id].remove(from);
            }
        }

        if (to != address(0)) {
            _ownedTokens[to].add(id);
            _tokenIdToOwners[id].add(to);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        operator;
        data;
        for (uint256 i = 0; i < ids.length; i++) {
            updateTokenID(from, to, ids[i], amounts[i]);
        }
    }

    function openTreasureChest(uint256 _tokenId)
        public
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(validTokenId[_tokenId], "Not a Valid Token ID");
        nft.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "0x");

        requestId = requestRandomness(keyHash, fee);
        requestIdToAddress[requestId] = msg.sender;
        requestIdToRequestNumberIndex[requestId] = requestCounter;
        requestCounter += 1;
        mintProgress[msg.sender] = true;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness.mod(255).add(1);
        uint256 totalChance = 256;
        address requestAddress = requestIdToAddress[requestId];
        uint256 requestNumber = requestIdToRequestNumberIndex[requestId];
        requestNumberToId[requestNumber] = requestAddress;
        string memory hash;
        uint256 randomLength;
        if (randomResult < 240) {
            randomLength = randomResult.mod(commonRewards.length);
            hash = commonRewards[randomLength];
        } else if (randomResult == (totalChance).div(2)) {
            //Congratulations you won a super rare card
            randomLength = randomResult.mod(superRareRewards.length);
            hash = superRareRewards[randomLength];
        } else {
            //Congratulations on won a rare card
            randomLength = randomResult.mod(rareRewards.length);
            hash = rareRewards[randomLength];
        }
        openChest(requestAddress, 1, hash, "0x");
        fulfilledCounter += 1;
        mintProgress[requestAddress] = false;
    }

    function withdrawLink(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        require(_tokenAddress != address(0), "Should be a valid Address");
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) > 0,
            "Not enough balance of the token mentioned"
        );
        require(
            IERC20(_tokenAddress).transfer(
                msg.sender,
                IERC20(_tokenAddress).balanceOf(address(this))
            ),
            "Transfer Failed"
        );
        return true;
    }

    function addCommonRewards(string calldata _hash)
        external
        onlyOwner
        returns (bool)
    {
        commonRewards.push(_hash);
        return true;
    }

    function addRareRewards(string calldata _hash)
        external
        onlyOwner
        returns (bool)
    {
        rareRewards.push(_hash);
        return true;
    }

    function addSuperRareRewards(string calldata _hash)
        external
        onlyOwner
        returns (bool)
    {
        superRareRewards.push(_hash);
        return true;
    }

    function addValidTokenId(uint256 _tokenId, bool _status)
        external
        onlyOwner
    {
        validTokenId[_tokenId] = _status;
    }

    function removeCommonReward(uint256 index)
        external
        onlyOwner
        returns (bool)
    {
        _burnCommon(index);
        return true;
    }

    function removeRareReward(uint256 index) external onlyOwner returns (bool) {
        _burnRare(index);
        return true;
    }

    function removeSuperRareReward(uint256 index)
        external
        onlyOwner
        returns (bool)
    {
        _burnSuperRare(index);
        return true;
    }

    function _burnCommon(uint256 index) internal {
        require(index < commonRewards.length);
        commonRewards[index] = commonRewards[commonRewards.length - 1];
        commonRewards.pop();
    }

    function _burnRare(uint256 index) internal {
        require(index < rareRewards.length);
        rareRewards[index] = rareRewards[rareRewards.length - 1];
        rareRewards.pop();
    }

    function _burnSuperRare(uint256 index) internal {
        require(index < superRareRewards.length);
        superRareRewards[index] = superRareRewards[superRareRewards.length - 1];
        superRareRewards.pop();
    }

    function viewCommonRewards()
        public
        view
        onlyOwner
        returns (string[] memory)
    {
        return commonRewards;
    }

    function viewRareRewards() public view onlyOwner returns (string[] memory) {
        return rareRewards;
    }

    function viewSuperRareRewards()
        public
        view
        onlyOwner
        returns (string[] memory)
    {
        return superRareRewards;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        //Not allowed
        // return "";
        revert();
    }
}