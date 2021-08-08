//STHC_Conract SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";            


contract SmileTogether is  ERC721Enumerable, Ownable { 

    using SafeMath for uint256;

    uint256 public constant MAX_HappyFace = 5555;
    uint public CHARITY_FEE = 10;                   // % to Charity
    uint public OWNERSHIPPOOLCONTACT_FEE = 20;      // % to OWNERSHIPPOOL contract
    uint _security_mode;

    uint256 private _price = 0.04 ether;
    uint256 private _reserved_us = 100;             // 3 for the team, 97 for giveaways, promotions
    uint256 private _reserved_veefriends = 555;     // For Vee Friends holders
 


    string public STHC_PROVENANCE = "";
    uint256 public startingIndex;

    string public baseURI;
    bool private _saleStarted;

    address public constant CHARITY_ADDRESS = 0x97B22798586BdCF7491d050Ed0885431DCf60174;   // My address but the address of the charity will go here
    address OWNER_ADDRESS = 0x97B22798586BdCF7491d050Ed0885431DCf60174;                     // Owner address
    address OWNERSHIPPOOL_ADDRESS  = 0x97B22798586BdCF7491d050Ed0885431DCf60174;            // OWNERSHIPPOOL contract - My address but the address of the OWNERSHIPPOOL contract will go here
    address ADMIN_ADDRESS = 0x97B22798586BdCF7491d050Ed0885431DCf60174;                     // Security administrator address - My address but the Security administrator address will go here
    


    constructor() ERC721("Smile Together Happy Club", "STHC") {
        _saleStarted = false;
        _security_mode = 0;
        // setBaseURI("https://smiletogetherhappyclub.com/api");   
    }

    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }


    function mintHappyFace(uint256 numHappyFace) public payable{
        require(_saleStarted == true, "Sale hasn't started yet!");
        require(totalSupply() < MAX_HappyFace, "We already sold out. Thank you!");
        require(numHappyFace > 0 && numHappyFace <= 10, "You can mint minimum 1, maximum 10 Happy Faces.");
        require(totalSupply().add(numHappyFace) <= MAX_HappyFace - _reserved_us - _reserved_veefriends, "Not enough Happy Faces left.");
        require(totalSupply().add(numHappyFace) <= MAX_HappyFace, "Exceeds MAX_HappyFace.");
        require((numHappyFace * _price) <= msg.value, "Ether value sent is not correct.");
      
        for (uint i = 0; i < numHappyFace; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    // Make it possible to change the price: just in case
    function setPrice(uint256 _newPrice) external onlyOwner {
        require(_security_mode == 1, "Owner security is False!");        
        _price = _newPrice;
        _security_mode = 0;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        STHC_PROVENANCE = provenanceHash;
    }

    // Help to list all the Happy Faces of a connected wallet
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function claimReserved_us(uint256 _number, address _receiver) external onlyOwner {
        require(_number <= _reserved_us, "That would exceed the max reserved.");

        uint256 _tokenId = totalSupply();
        for (uint256 i; i < _number; i++) {
            _safeMint(_receiver, _tokenId + i);
        }

        _reserved_us = _reserved_us - _number;
    }

    function setSecurity() public {
        if (msg.sender == ADMIN_ADDRESS){
            _security_mode = 1;
        } else {
            _security_mode = 0;

        }
        
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
        require(_security_mode == 1,"Owner security is False");        
        uint256 _balance = address(this).balance;
        uint256 _toCHARITY = (_balance * CHARITY_FEE)/100;                          // CHARITY_FEE % to Charity
        uint256 _toOWNERSHIPPOOL = (_balance * OWNERSHIPPOOLCONTACT_FEE)/100;       // OWNERSHIPPOOLCONTACT_FEE % to OWNERSHIPPOOL contract
        uint256 _toOWNER = _balance - _toCHARITY - _toOWNERSHIPPOOL;                // The rest to owner

        payable(CHARITY_ADDRESS).transfer(_toCHARITY);
        payable(OWNERSHIPPOOL_ADDRESS).transfer(_toOWNERSHIPPOOL);
        payable(OWNER_ADDRESS).transfer(_toOWNER);
        _security_mode = 0;
        assert(address(this).balance == 0);
    }
}