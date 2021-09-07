// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract ETHDonuts is ERC721, Ownable{

    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    // Front-end notification events.
    event NewAsset(uint indexed tokenId, string tokenURI);

    // Metadata (example) which could be randomized / generated / fixed / inputted
    struct AssetMetadata{
        uint8 icing_type;
        uint8 icing_color;
        uint8 dough_color;
        uint8 background_color;
    //So possible varaints from these traits are : 11*8*4*255 = 89,760
    }

    // A nonce for addition to randomization
    uint private nonce;

    // Base URI where meta lives
    string baseURI;

    // Minting start time
    uint256 constant public MINTING_OPENS = 1631296800; // change to 1631296800

    // Maximum mint NR. by default set to 555
    uint256 constant public MAX_MINT_NR = 555;

    uint256 public actualMintNr;
    
    // Team gets 55 free mints
    uint256 constant TEAM_MINT_NR = 55; // change to 55
    
    // Team gets 55 free mints
    bool public mintedForTeam = false;

    // Mint Price
    uint256 constant public MINT_PRICE = 125*1e15; // change to 125*1e15

    // An array of assets
    AssetMetadata[] public assets;

    // Mapping: an asset to owner
    mapping (uint => address) assetToOwner;
    // Mapping: how many assets each owner has ?
    mapping (address => uint) ownerAssetCount;
    // Mapping: Approval transfers
    mapping (uint => address) assetApprovals;

    // Mapping: TokenURIs
    //mapping (uint => string) tokenURIs;

    modifier onlyOwnerOf(uint tokenId) {
        require(msg.sender == assetToOwner[tokenId]);
        _;
    }

    constructor() ERC721("ETHDonuts", "DONUTS") {
        // Token URI
        _setBaseTokenURI("https://ethdonuts.art/donuts/");
        actualMintNr = 0;
    }
    
    function mintForTeam() external payable onlyOwner {
        require(mintedForTeam == false, "You've already minted for your team");
        // Mint 55 from the contract for the team
        // 20 mints costs 0.12 ETH in gas
        for (uint8 i=0; i<TEAM_MINT_NR; i++) {    

            AssetMetadata memory newAsset = AssetMetadata(random(255),random(255),random(255),random(255));

            mint(newAsset); 
        }
        mintedForTeam = true;
    }
    
    function timeRemaining() public view returns (uint256) {
        return MINTING_OPENS - block.timestamp;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, uint2str(tokenId)));
    }


    function _setBaseTokenURI(string memory _baseURI) public onlyOwner{
        baseURI = _baseURI;
    }

    // Called internallby by either constructor for creating assets for contract owner or called by claim() function
    function mint (AssetMetadata memory assetMetadata) internal{  
        require(isOwner() == true || msg.value >= MINT_PRICE, "Claiming an Asset costs 0.125 ETH");
        require(actualMintNr < MAX_MINT_NR);      
        // Add it to our list of assets 
        assets.push(assetMetadata);

        //ID
        uint id = assets.length -1;
        // We could create our own _safeMint and call Transfer() afterwards but
        // it is simpler calling it from base class
        super._safeMint(msg.sender,id);
        
        string memory _tokenURI = tokenURI(id);
        
        // Assign an owner to this asset ID
        assetToOwner[id] = msg.sender;

        //Increase the nr. of assets each address have
        ownerAssetCount[msg.sender] = ownerAssetCount[msg.sender].add(1);

        //Increase actual mint number
        actualMintNr = actualMintNr.add(1);

        //Notify front-end
        emit NewAsset(id,_tokenURI);
        
        if(isOwner() == false) {
            payable(owner()).transfer(MINT_PRICE);
        }
    }

    // Basically the exposed "mint" function to 'public'
    // Randomly creates / mints an asset
    function claim() external payable{
        require(isOwner() == false, "The owner may not mint this way");
        require(block.timestamp > MINTING_OPENS, "Minting has not opened yet");
        require(msg.value >= MINT_PRICE, "Claiming a Asset costs 0.125 ETH");
        require(ownerAssetCount[msg.sender] <= 3, "Claiming too many assets per address");

        AssetMetadata memory newAsset = AssetMetadata(random(255),random(255),random(255),random(255));

        return mint(newAsset);
    }

    // Random helper function for mintibg attributes
    function random(uint8 modulus) internal returns (uint8) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % modulus;
        nonce = nonce.add(1);
        return uint8(randomnumber);
    }

    // Check who is the owner of a specific asset. 
    function ownerOf(uint256 _tokenId) public override view returns (address) {
        return assetToOwner[_tokenId];
    }

    // How many items an owner has ?
    function balanceOf(address _owner) public view override returns(uint256) {
        return ownerAssetCount[_owner];
    }

    // Internal _transfer function which is actually transferring the ownership between addresses
    function _transfer(address _from, address _to, uint256 _tokenId) internal override {
        require(ERC721.ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address.");

        // Clear approvals from the previous owner
        super._approve(address(0), _tokenId);

        ownerAssetCount[_to] = ownerAssetCount[_to].add(1);
        ownerAssetCount[msg.sender] = ownerAssetCount[msg.sender].sub(1);
        assetToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    // Public function either new (if approved) or old owner can call
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        require (assetToOwner[_tokenId] == msg.sender || assetApprovals[_tokenId] == msg.sender);
        _transfer(_from, _to, _tokenId);
    }

    // Old owner can approve 'new owner' and so new owner can initiate the transfer function
    function approve(address _approved, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
        assetApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    // Token information getter
    function getAsset(uint _tokenId) external view returns(
        uint8 icing_type,
        uint8 icing_color,
        uint8 dough_color,
        uint8 background_color
    ){
        require(_exists(_tokenId), "Token not minted");

        AssetMetadata memory asset = assets[_tokenId];
        return (
            asset.icing_type, 
            asset.icing_color, 
            asset.dough_color,
            asset.background_color
            );
    }

    function get_ActualMintNr() external view returns(uint256 _mintedNr){
        return actualMintNr;
    }

    //Helper functions

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
}