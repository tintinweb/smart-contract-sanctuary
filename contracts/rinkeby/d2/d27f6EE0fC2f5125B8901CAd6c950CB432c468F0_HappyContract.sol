//STHC_Conract SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";            


contract HappyContract is  ERC721Enumerable, Ownable { 

    using SafeMath for uint256;

    uint256 public constant MAX_HappyFace = 5555;
    uint public CHARITY_1_FEE = 25;                     // 2.5% to Charity chosen by us (Autism Speaks)
    uint public CHARITY_2_FEE = 25;                     // 2.5% to Charity chosen by us (Autism Radio)
    uint public OTHER_CHARITY_FEE = 50;                 // 5%   to Charity chosen by the community
    uint public HCBW_FEE = 120;                         // 12%  to Happy Club Business Wallet
    uint public CSW_FEE = 80;                           // 8%   to Community Support Wallet      //8+12=20% to Ownership Pool
    //uint public 100PERCENT = 1000;                    // => 100 % 
    

    uint256 private _price = 0.04 ether;                
    uint256 private _reserved = 100;                    // 3 for the team, 97 for giveaways, promotions
 


    string public STHC_PROVENANCE = "";
    uint256 public startingIndex;

    string public baseURI;
    bool private _saleStarted;
    bool private _presaleStarted;
    address[] private _addresses_for_canpresale;


    address public constant CHARITY_1_ADDRESS = 0x0ade51c2b4c417fC6d4Fd9FE2701c60038EBfd42;     // Autism Speaks - Twitter: https://twitter.com/autismspeaks
    address public constant CHARITY_2_ADDRESS = 0x5dC22B9c05a4cD0E369A4C164686d7E293E1170f;     // Autism Radio - Twitter: https://twitter.com/autismradio
    address public constant OTHER_CHARITY_ADDRESS = 0x8d727A0ac890f89218Dc9391a8d3d9B36692a4D5; // The community will choose where we should donate this money
    address OWNER_ADDRESS = 0x5Ffe79DAA7fB7837599DDe96f5FE844Ae57fd008;                         // Owner address
    address HCBW_ADDRESS  = 0x3F4c5C7542D032eecfc07FD650A9c04bb1cD67EA;                         // Happy Club Business Wallet
    address CSW_ADDRESS  = 0x029747a0Ed88796DabDa13E948e0E40Ab56C9f91;                          // Community Support Wallet
    


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
        uint i = 0;

        for (i=0;i < _addresses_for_canpresale.length;i++ ){
        //while ((i < _addresses_for_canpresale.length) &&  (_inpresale == false)) {
            if (_addresses_for_canpresale[i] == msg.sender){
                _inpresale = true;
                i =_addresses_for_canpresale.length;
            }
        //    i++;
        }
        require(_inpresale, "This address not eligible for pre-sale purchases");

        for (i = 0; i < numHappyFace; i++){
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

    function Add_presaleAddresses(address[] memory _addr) external  onlyOwner {
        for (uint i=0;i < _addr.length;i++ ){
              _addresses_for_canpresale.push(_addr[i]);
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
        uint256 _toCHARITY1 = (_balance * CHARITY_1_FEE)/1000;                          // CHARITY_1_FEE % to Charity (Autism Speaks)
        uint256 _toCHARITY2 = (_balance * CHARITY_2_FEE)/1000;                          // CHARITY_2_FEE % to Charity (Autism Radio)
        uint256 _toOTHERCHARITY = (_balance * OTHER_CHARITY_FEE)/1000;                  // OTHER_CHARITY_FEE % to Charity
        uint256 _toHCBW = (_balance * HCBW_FEE)/1000;                                   // HCBW_FEE % to Happy Club Business Wallet
        uint256 _toCSW = (_balance * CSW_FEE)/1000;                                     // CSW_FEE % to Community Support Wallet
        uint256 _toOWNER = _balance - _toCHARITY1 - _toCHARITY2 - _toOTHERCHARITY - _toCSW - _toHCBW;   // The rest to owner

        payable(CHARITY_1_ADDRESS).transfer(_toCHARITY1);
        payable(CHARITY_2_ADDRESS).transfer(_toCHARITY2);
        payable(OTHER_CHARITY_ADDRESS).transfer(_toOTHERCHARITY);
        payable(HCBW_ADDRESS).transfer(_toHCBW);
        payable(CSW_ADDRESS).transfer(_toCSW);
        payable(OWNER_ADDRESS).transfer(_toOWNER);
        assert(address(this).balance == 0);
    }
}