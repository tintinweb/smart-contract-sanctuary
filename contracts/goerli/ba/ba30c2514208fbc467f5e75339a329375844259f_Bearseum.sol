// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;


import './ReentrancyGuard.sol';
import './Ownable.sol';
import './BearGenerator.sol';
import './ERC721Burnable.sol';
import './ERC721Enumerable.sol';
import './ERC721Pausable.sol';
import './MerkleProof.sol';


contract Bearseum is ERC721Enumerable, ERC721Burnable, ERC721Pausable, ReentrancyGuard, Ownable {


    bytes32 public rootFreeMinting;
    bytes32 public rootPresale;

    bool private isPausedPublicSale;
    bool private isPausedFreeMinting;
    bool private isPausedPresale;
    ERC721Enumerable public _Bullseum;

    using BearGenerator for BearGenerator.Gene;


    BearGenerator.Gene internal geneGenerator;

    uint256 internal conteoNFTs;
    uint256 public constant maxSupply = 10000;
    uint256 public bearsFreeMinted;

    uint256 public BearsMintedForPromotion;
    uint256 public unitBearPrice;

    mapping (uint256 => uint256) internal _genes;
    mapping (address => uint256) public bearsAvailable;
    mapping (address => bool) public isApprovedForFree;


    event BearMinted(uint256 indexed tokenId, uint256 newGene);
    event BearPriceChanged(uint256 unitBearPrice);




    constructor() public {

        unitBearPrice = 0.08 ether;
        geneGenerator.random();
        isPausedPublicSale = true;
        isPausedFreeMinting = true;
        isPausedPresale = true;

    }

    function setPausePublicSale(bool paused) public onlyOwner {
        isPausedPublicSale = paused;
    }

     function setPauseFreeMinting(bool paused) public onlyOwner {
        isPausedFreeMinting = paused;
    }

     function setPausePresale(bool paused) public onlyOwner {
        isPausedPresale = paused;
    }


    function setRootFreeMinting(bytes32 _root) public onlyOwner {
        rootFreeMinting = _root;
    }

    function setRootPresale(bytes32 _root) public onlyOwner {
        rootPresale = _root;
    }

    function verifyFreeMint(address leaf, uint256 amount,bytes32[] memory proof) public view returns (bool){
        bytes32 _leaf = keccak256(abi.encodePacked(leaf,amount));
        return MerkleProof.verify(proof, rootFreeMinting, _leaf);
    }

    function verifyPreSale(address leaf, bytes32[] memory proof) public view returns (bool){
        bytes32 _leaf = bytes32(bytes20(leaf));
        return MerkleProof.verify(proof, rootPresale, _leaf);
    }

    function getApprovedToFreeMint(uint256 bullsAmount, address leaf, bytes32[] memory proof) external nonReentrant {
         require(msg.sender == leaf, 'Sender must be the leaf');
         require(isPausedFreeMinting == false, 'Free minting is paused');
         require(verifyFreeMint(leaf,bullsAmount, proof) == true, 'You are not on the whitelist');
         uint256 bears = bullsAmount/2;
         isApprovedForFree[msg.sender] = true;
         bearsAvailable[msg.sender] = bears;
    }


    function claimMyFreeBears(uint256 bearsToMint) external nonReentrant {
        require(isPausedFreeMinting == false, 'Free minting is paused');
        require(isApprovedForFree[msg.sender] == true, 'You are not approved for free minting');
        require(bearsAvailable[msg.sender] - bearsToMint >= 0, 'You cant mint too many bears');
        require(bearsFreeMinted + bearsToMint <= 2500, 'No more than 5000 bears can be minted');
        bearsAvailable[msg.sender] -= bearsToMint;
        bearsFreeMinted += bearsToMint;
        mintHelper(msg.sender, bearsToMint);
    }

    function setUnitBearPrice(uint256 newBearPrice) public onlyOwner {
        unitBearPrice = newBearPrice;
        emit BearPriceChanged(newBearPrice);
    }


    function mintPublicSale(uint256 amount) public payable nonReentrant returns(bool){
      require(isPausedPublicSale == false, 'Public Sale has not started');
      require(conteoNFTs+amount <= maxSupply, "Total supply reached");
      require(msg.value == unitBearPrice*amount, 'You need to send 0.07 ether per Bear desired');

      mintHelper(_msgSender(), amount);
      return true;
    }

    function mintPreSale(uint256 amount, address leaf, bytes32[] memory proof) public payable nonReentrant returns(bool){
      require(msg.sender == leaf, 'Sender must be the leaf');
      require(isPausedPresale == false, 'Public Sale has not started');
      require(verifyPreSale(leaf, proof) == true, 'You are not whitelisted');
      require(conteoNFTs+amount <= maxSupply, "Total supply reached");
      require(msg.value == unitBearPrice*amount, 'You need to send 0.07 ether per Bear desired');

      mintHelper(_msgSender(), amount);
      return true;
    }

    function mintForPromotion(uint256 amount) public onlyOwner returns(bool){
      require(BearsMintedForPromotion + amount <= 150, 'Cant mint more Bears for promotion');
      require(conteoNFTs+(amount) <= maxSupply, "Total supply reached");
      BearsMintedForPromotion += amount;
      mintHelper(_msgSender(), amount);
      return true;
    }



    function mintHelper(address sender, uint256 amount) internal {

      for (uint256 i = 0; i < amount; i++) {


          uint256 tokenId = totalSupply();
          _genes[tokenId] = geneGenerator.random();
          _mint(sender, tokenId);
          ++conteoNFTs;
          emit BearMinted(tokenId, _genes[tokenId]);
      }

    }


    function setBaseURI(string memory _baseURI, uint256 id) public virtual onlyOwner{
        _setBaseURI(_baseURI,id);
    }

    function geneOf(uint256 tokenId) public view returns (uint256 gene) {
        return _genes[tokenId];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override ( ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

    }




}