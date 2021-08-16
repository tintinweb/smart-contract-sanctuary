//STHC_Conract SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";            


contract HappyContract is  ERC721Enumerable, Ownable { 

    using SafeMath for uint256;

    uint256 public constant MAX_HappyFace = 5555;
    uint public CHARITY_1_FEE = 25;                     // % to Charity chosen by us
    uint public CHARITY_2_FEE = 25;                     // % to Charity chosen by us
    uint public OTHER_CHARITY_FEE = 50;                 // % to Charity chosen by the community
    uint public OWNERSHIPPOOLCONTACT_FEE = 200;         // % to OWNERSHIPPOOL contract
    //uint public 100PERCENT = 1000;                       // => 100 % 
    

    uint256 private _price = 0.04 ether;
    uint256 private _reserved = 100;                // 3 for the team, 97 for giveaways, promotions
 


    string public STHC_PROVENANCE = "";
    uint256 public startingIndex;

    string public baseURI;
    bool private _saleStarted;
    bool private _presaleStarted;
    address[] private _addresses_for_canpresale;


    address public constant CHARITY_1_ADDRESS = 0x97B22798586BdCF7491d050Ed0885431DCf60174;   // My address but the address of the charity will go here
    address public constant CHARITY_2_ADDRESS = 0x3c5e1CDf5D58d4ad4d0a334119658865Fc977BbC;   // My address but the address of the charity will go here
    address public constant OTHER_CHARITY_ADDRESS = 0x821044bA53882095d274D7380D7326dE4EcBF370;   // My address but the address of the charity will go here
    address OWNER_ADDRESS = 0x5Ffe79DAA7fB7837599DDe96f5FE844Ae57fd008;                     // Owner address
    address OWNERSHIPPOOL_ADDRESS  = 0x6cE91d8cc1f447bE3619C066A8E4F8a1773abF82;            // OWNERSHIPPOOL contract - My address but the address of the OWNERSHIPPOOL contract will go here
    


    constructor() ERC721("Smile Together Happy Club", "STHC") {
        _saleStarted = false;
        _presaleStarted = false;
        baseURI = "https://metadata.smiletogetherhappyclub.com/api/";   
    }


    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }


    function mintHappyFace(uint256 numHappyFace) public payable{
        require(_saleStarted == true, "Sale hasn't started yet!");
        require(totalSupply() < MAX_HappyFace, "We already sold out. Thank you!");
        require(numHappyFace > 0 && numHappyFace <= 10, "You can mint minimum 1, maximum 10 Happy Faces.");
        require(totalSupply().add(numHappyFace) <= MAX_HappyFace - _reserved, "Not enough Happy Faces left.");
        require(totalSupply().add(numHappyFace) <= MAX_HappyFace, "Exceeds MAX_HappyFace.");
        require((numHappyFace * _price) <= msg.value, "Ether value sent is not correct.");
      
        for (uint i = 0; i < numHappyFace; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
    function premintHappyFace(uint256 numHappyFace) public payable{
        require(_presaleStarted == true, "Pre-sale hasn't started yet!");
        require(totalSupply() < MAX_HappyFace, "We already sold out. Thank you!");
        require(numHappyFace > 0 && numHappyFace <= 10, "You can mint minimum 1, maximum 10 Happy Faces.");
        require(totalSupply().add(numHappyFace) <= MAX_HappyFace - _reserved, "Not enough Happy Faces left.");
        require((numHappyFace * _price) <= msg.value, "Ether value sent is not correct.");
        require (_addresses_for_canpresale.length > 0, "Haven't pre-sale address in contract." );

        bool _inpresale = false;

        for (uint i = 0; i < _addresses_for_canpresale.length; i++ ) {
            if (_addresses_for_canpresale[i] == msg.sender){
                _inpresale = true;
            }
        }
        require(_inpresale, "This address not eligible for pre-sale purchases");

        for (uint i = 0; i < numHappyFace; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;

        if ( _saleStarted && _presaleStarted) {
            _presaleStarted = false;
        }

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }
    function flipPreSaleStarted() external onlyOwner {
        _presaleStarted = !_presaleStarted;

        if ( _saleStarted && _presaleStarted) {
            _saleStarted = false;
        }

        if (_presaleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }
   function presaleAddresses() public view returns(address[] memory) {
        return _addresses_for_canpresale;
    }

    function presaleAddrCount() public view returns(uint256) {
        return _addresses_for_canpresale.length;
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }
   function presaleStarted() public view returns(bool) {
        return _presaleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    // THis makes it possible to change the price // just in case
    function setPrice(uint256 _newPrice) external onlyOwner {
         _price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        STHC_PROVENANCE = provenanceHash;
    }

    // Help to list all the Happy Faces of a connected wallet // it's for the Ownership Pool
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner {
        require(_number <= _reserved, "That would exceed the max reserved.");

        uint256 _tokenId = totalSupply();
        for (uint256 i; i < _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved = _reserved - _number;
    }

     function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");

        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % MAX_HappyFace;

        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 _toCHARITY1 = (_balance * CHARITY_1_FEE)/1000;                           // CHARITY_1_FEE % to Charity
        uint256 _toCHARITY2 = (_balance * CHARITY_2_FEE)/1000;                           // CHARITY_2_FEE % to Charity
        uint256 _toOTHERCHARITY = (_balance * OTHER_CHARITY_FEE)/1000;                   // OTHER_CHARITY_FEE % to Charity
        uint256 _toOWNERSHIPPOOL = (_balance * OWNERSHIPPOOLCONTACT_FEE)/1000;           // OWNERSHIPPOOLCONTACT_FEE % to OWNERSHIPPOOL contract
        uint256 _toOWNER = _balance - _toCHARITY1 - _toCHARITY2 - _toOTHERCHARITY - _toOWNERSHIPPOOL;   // The rest to owner

        payable(CHARITY_1_ADDRESS).transfer(_toCHARITY1);
        payable(CHARITY_2_ADDRESS).transfer(_toCHARITY2);
        payable(OTHER_CHARITY_ADDRESS).transfer(_toOTHERCHARITY);
        payable(OWNERSHIPPOOL_ADDRESS).transfer(_toOWNERSHIPPOOL);
        payable(OWNER_ADDRESS).transfer(_toOWNER);
        assert(address(this).balance == 0);
    }
}