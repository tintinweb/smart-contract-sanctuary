// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import './Ownable.sol';
import './SproutGenerator.sol';
import './ERC721Enumerable.sol';
import './ERC721.sol';
import './MerkleProof.sol';

contract SoundSprouts is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;

    // thanks 0x1cBB182322Aee8ce9F4F1f98d7460173ee30Af1F
    using SproutGenerator for SproutGenerator.Gene;

    SproutGenerator.Gene internal geneGenerator;

    enum State {
      Pending,
      Sale,
      Finished
    }

    bytes32 public rootMerkle;

    // Uris cant be locked until november 22th 2022
    uint256 public constant MIN_TIME = 1669096800;
    uint256 public constant M_O_D = 296;
    uint256 public constant RES = 15;
    uint256 public constant MAX_SOUNDSPROUTS = 9999;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant AMOUNT_RESERVED = 120;

    State public _state;

    bool public lockedUris;
    uint256 public SOUNDSPROUT_PRICE = 0.08 ether;

    uint256 public SproutsMintedForPromotion;
    string public arweaveAssetsJSON;

    mapping(uint256 => uint256) internal _genes;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => bool) private _rewardGiven;

    event SproudMinted(uint256 indexed tokenId);
    event SproudPriceChanged(uint256 unitSproutPrice);

    // Base URI
    string private _ipfsHash;
    string private _storage;

    constructor() {
        geneGenerator.random();
        _storage = "https://gateway.pinata.cloud/ipfs/";
    }

    function mintSoundSprout(uint256 amount) external payable {
      require(_state == State.Sale, "SoundSprouts have not germinated yet");
      require(amount <= MAX_PURCHASE, "Cant mint that many SoundSprotus");
      require(totalSupply()+amount <= (MAX_SOUNDSPROUTS-AMOUNT_RESERVED), "No that many germinated SoundSprouts left");
      require(msg.value == SOUNDSPROUT_PRICE*amount, "That is not the right price");

      mintHelper(msg.sender, amount);
    }

    function mintForPromotion(address whoToSend, uint256 amount) external onlyOwner {
      _mintForPromotion(whoToSend, amount);
    }

    function _mintForPromotion(address whoToSend, uint256 amount) internal {
      require(SproutsMintedForPromotion + amount <= AMOUNT_RESERVED, 'Cant mint more SoundSprouts for promotion');
      require(totalSupply()+ amount <= MAX_SOUNDSPROUTS, "Too many SoundSprouts requested");
      SproutsMintedForPromotion += amount;
      mintHelper(whoToSend, amount);
    }

    function mintHelper(address sender, uint256 amount) internal {

      for (uint256 i = 0; i < amount; i++) {

          uint256 tokenId = totalSupply() + 1;
          _genes[tokenId] = geneGenerator.random();
          _mint(sender, tokenId);

          emit SproudMinted(tokenId);
      }
    }

    function mintReward(uint256 amount, address leaf, bytes32[] memory proof) external {
        require(_state == State.Sale, "SoundSprouts have not germinated yet");
        require(verifyReward(amount, leaf, proof), 'You are not whitelisted');
        require(!_rewardGiven[leaf]);

        _rewardGiven[leaf] = true;

        _mintForPromotion(leaf, amount);
    }

    function verifyReward(uint256 amount, address leaf, bytes32[] memory proof) public view returns (bool) {
      bytes32 _leaf = keccak256(abi.encodePacked(leaf, amount));
      return MerkleProof.verify(proof, rootMerkle, _leaf);
    }


    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        if(bytes(_tokenURI).length > 0){
          return _tokenURI;
        }

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(_storage,baseURI,tokenId.toString(), ".json")) : "https://arweave.net/WaFzC0B8RB7GLghG8Gg8mDpA884SjMLrlGzwSrtJ7YQ";
    }

    function setRootMerkle(bytes32 _root) external onlyOwner {
      rootMerkle = _root;
    }

    function setStorageURL(string memory newStorage) external onlyOwner {
      _storage = newStorage;
    }

    function _baseURI() internal view override returns (string memory) {
        return _ipfsHash;
    }

    function setBaseURI(string memory _newbaseURI) external virtual onlyOwner{
        require(!lockedUris, "tokenURIS cant change");
        _ipfsHash = _newbaseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(tokenId), "URI set of nonexistent token");
        require(!lockedUris, "tokenURIS cant change");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setArweaveAssetsJSON(string memory arweave) external onlyOwner {
        require(!lockedUris, "tokenURIS cant change"); /// This can change if im able to deploy to arweave before minting
        arweaveAssetsJSON = arweave;
    }

    function setLockedUris(bool value) external onlyOwner {
        require(MIN_TIME < block.timestamp);
        lockedUris = value;
    }

    function geneOf(uint256 tokenId) public view returns (uint256 gene) {
        return _genes[tokenId];
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function changePrice(uint256 newPrice) external onlyOwner {
      SOUNDSPROUT_PRICE = newPrice;
      emit SproudPriceChanged(newPrice);
    }

    function setStatus(State status) external onlyOwner {
        _state = status;
    }

    function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override ( ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }




}