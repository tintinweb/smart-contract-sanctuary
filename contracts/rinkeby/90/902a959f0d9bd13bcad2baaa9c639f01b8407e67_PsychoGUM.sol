// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";

///   +hhhhhhhhys/`    /shhhhhhhh:yhhhho     .yhhhh+ -+syhhhhhhh:hhhho    `hhhho    :ohddmdy+-         
///   yMMMMMMMMMMMNo `dMMMMMMMMMMN+dMMMMy`  -mMMMMs+mMMMMMMMMMMM+MMMMh    .MMMMy  +mMMMNyhNMMMd/       
///   yMMMMMMMMMMMMMs/MMMMMmddddddh:hMMMMh`:NMMMModMMMMMmddddddd/MMMMh    .MMMMy`dMMMMNmosmNMMMMy      
///   yMMMM/  -mMMMMN`dMMMMNo.````` `yMMMMmNMMMN/hMMMMy.`````````MMMMmoooosMMMMyyMMNNMMMNNMNNNMMM+     
///   yMMMMhyyyNMMMMh `/mMMMMm/`      oMMMMMMMm: MMMMm          `MMMMMMMMMMMMMMyNMMMN  MMMM  MMMMh     
///   yMMMMMMMMMMMMh.   `omMMMMd:      +NMMMMd.  NMMMN-         `MMMMMNNNNNMMMMymMMMM+dMMMMysMMMMy     
///   yMMMMNmmmmdy:`------/dMMMMM:      yMMMM:   +MMMMms:-------.MMMMd....:MMMMy/MMNdhmddddNdmMMN-     
///   yMMMM/...``  +NMMMMMMMMMMMM:      yMMMM-    +mMMMMMMMMMMMM+MMMMh    .MMMMy /mMMmd   :mdNMd-      
///   sMMMM-     `sMMMMMMMMMMMNm+       sMMMM-     .+dmNMMMMMMMM+MMMMh    .MMMMy  .+dNNn_:hNmh/`       
///   -::::`     ./+++++++++++/-.` `....:++/:`       .-/+++++//+:++++/..` `::::-     -/+oo+/-...       
///          `.+yhmNNMMMMMMMMMMMMd NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMy           .mMMMMMMMMMM:      
///        `+dMMMMMMMMMMMMMMMMMMMm NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMy         `dMMMMMMMMMMM:      
///      `oNMMMMMMMMMMMMMMMMMMMMMm NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMy        yMMMMMMMMMMMM:      
///     -mMMMMMMMMMMMMMMMMMMMMMMMm NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMy      sMMMMMMMMMMMMM:      
///    :NMMMMMMMMMdso++++++++++++/ NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMMy    +MMMMMMMMMMMMMM:      
///   `mMMMMMMMMy-`                NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMMMy  :NMMMMMMMMMMMMMM:      
///   +MMMMMMMMs                   NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMMMMy-NMMMMMMMMMMMMMMM:      
///   yMMMMMMMM`          ```````` NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMM:      
///   yMMMMMMMM`         ommmmmmmm NMMMMMMMy        :MMMMMMMM/sMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM:      
///   +MMMMMMMMs`        yMMMMMMMM NMMMMMMMh        /MMMMMMMM/sMMMMMMMM+NMMMMMMMMMMMMMmsMMMMMMMM:      
///   `mMMMMMMMMh:`      yMMMMMMMM hMMMMMMMM+`    `-mMMMMMMMM.sMMMMMMMM`:NMMMMMMMMMMMh./MMMMMMMM:      
///    :NMMMMMMMMMdyo++++dMMMMMMMM :MMMMMMMMMmyo+shNMMMMMMMMy sMMMMMMMM` -mMMMMMMMMMy` /MMMMMMMM:      
///     -mMMMMMMMMMMMMMMMMMMMMMMMM  +NMMMMMMMMMMMMMMMMMMMMMh` sMMMMMMMM`  .hMMMMMMMo   /MMMMMMMM:      
///      `oNMMMMMMMMMMMMMMMMMMMMMM   -dMMMMMMMMMMMMMMMMMMNo   sMMMMMMMM`   `yMMMMN/    /MMMMMMMM:      
///        `+dMMMMMMMMMMMMMMMMMMMM     /dMMMMMMMMMMMMMMmo.    sMMMMMMMM`     oMMN:     /MMMMMMMM:      
///           ./shmNMMMMMMMMMMMMMM       ./ydNMMMMNmho-       sMMMMMMMM`      /d.      /MMMMMMMM:      
///                                             `                                                      
/// @title  PSYCHO GUM COMIC - EPISODE 0 - PSYCHO DRIVERS
/// @author jolan.eth

contract PsychoGUM is ERC721, Ownable {
    string SYMBOL = "PSYCHOGUM";
    string NAME = "PSYCHO GUM COMIC - EPISODE 0 - PSYCHO DRIVERS";

    string GiftCID;
    string FirstCID;
    string SecondCID;
    string ThirdCID;
    
    address public ADDRESS_SIGN = 0x1178808a1a8D46f498D7B5E1314Fe146baDA92ED;

    uint256 tokenId = 1;
    uint256 gitfId = 301;
    uint256 public totalSupply = 0;
    uint256 public maxMintSupply = 300;
    uint256 public tokenPrice = 0.1 ether;

    bool public mintAllowed = false;

    constructor() ERC721(NAME, SYMBOL) {}

    // @notice Withdraw function
    function withdrawEquity()
    public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    // @notice Open/close the mint
    function setMint()
    public onlyOwner {
        mintAllowed = mintAllowed ? false : true;
    }

    // @notice Allow the contract owner to gift nft
    function gift(address to)
    public onlyOwner {
        mintPsychoGUM(to, gitfId++);
    }

    // @notice Allow collectors to mint NFT with a price based on { tokenPrice }
    function mint() 
    public payable {
        require(mintAllowed, "error mintAllowed");
        require(tokenPrice == msg.value, "error tokenPrice");
        require(maxMintSupply >= tokenId, "error maxMintSupply");
        mintPsychoGUM(msg.sender, tokenId++);
        if (tokenId == 100 || tokenId == 200 || tokenId == 300) {
            mintAllowed = false;
        }
    }

    // @notice Private function that handle the mint, it first Mint the NFT into { ADDRESS_SIGN }
    //         and instantly transfer it to the { to } address, this ensure the first signature of the NFT
    //         is signed with the creator address
    function mintPsychoGUM(address to, uint256 _tokenId)
    private {
        _safeMint(ADDRESS_SIGN, _tokenId);
        _safeTransfer(ADDRESS_SIGN, to, _tokenId, "");
        totalSupply++;
    }

    // @notice Set the Metadata root CID from IPFS for Gift tokens
    function setGiftCID(string memory CID)
    public onlyOwner {
        GiftCID = string(abi.encodePacked("ipfs://", CID));
    }

    // @notice Set the Metadata root CID from IPFS for the first 100 tokens
    function setFirstCID(string memory CID)
    public onlyOwner {
        FirstCID = string(abi.encodePacked("ipfs://", CID));
    }

    // @notice Set the Metadata root CID from IPFS for second 100 tokens
    function setSecondCID(string memory CID)
    public onlyOwner {
        SecondCID = string(abi.encodePacked("ipfs://", CID));
    }

    // @notice Set the Metadata root CID from IPFS for third 100 tokens
    function setThirdCID(string memory CID)
    public onlyOwner {
        ThirdCID = string(abi.encodePacked("ipfs://", CID));
    }

    // @notice Return the tokenURI of an NFT based on { _tokenID }
    function tokenURI(uint256 _tokenId)
    public view virtual override returns (string memory URI) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_tokenId > 300)
            URI = string(abi.encodePacked(GiftCID, '/', Strings.toString(_tokenId)));
        if (_tokenId > 200 && _tokenId <= 300)
            URI = string(abi.encodePacked(ThirdCID, '/', Strings.toString(_tokenId)));
        if (_tokenId > 100 && _tokenId <= 200)
            URI = string(abi.encodePacked(SecondCID, '/', Strings.toString(_tokenId)));
        if (_tokenId > 0 && _tokenId <= 100)
            URI = string(abi.encodePacked(FirstCID, '/', Strings.toString(_tokenId)));
    }

    // @notice Required by ERC721 Standard
    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
    internal override(ERC721) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    // @notice Required by ERC721 Standard
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}