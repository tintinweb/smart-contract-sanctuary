//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./ERC1155.sol";

//  *******   ******** **   ** **********
//  /**////** /**///// /**  ** /////**/// 
//  /**   /** /**      /** **      /**    
//  /*******  /******* /****       /**    
//  /**///**  /**////  /**/**      /**    
//  /**  //** /**      /**//**     /**    
//  /**   //**/********/** //**    /**    
//  //     // //////// //   //     // 
//
//  REKT your favorite NFT by right click + save it on-chain
//  Mint is free + gas, purpose is null, mint only to REKT
//  You shouldn't trade this on secondary, it's a game, an experience, a meme, have fun
//  REKT exist only if the Original exist, it's not a copy, but a metamorphing
//  You can REKT an Original only once, multiple REKT not allowed
//  You can REKT a REKT (that have been REKT by a REKT... The chain is infinite until you follow the REKT id)
//  You can REKT any ERC721 or ERC1155 standardized.
//  Supply is infinite, if you are angry because your Original got REKT, consider that Internet is a land of freedom
//  And virtual ownership an illusion, don't mind it.
//  People own REKT as you own your Original
//  Enjoy REKT, get REKT
//
//  REKT HAVE NO VALUE
//  DON'T BE OFFENDED

contract REKT is ERC721 {

    string NAME = "REKT";
    string SYMBOL = "REKT";
    
    // map REKT Id => contract address, expose metamorphing origin contract
    mapping (uint256 => address) public _fromContract;
    
    // map REKT Id => contract token id, expose metamorphing origin token id
    mapping (uint256 => uint256) public _fromTokenId;
    
    // map REKT Id => string, expose the standard type of the metamorph
    mapping (uint256 => string) public _fromStandard;
    
    // map contract address => (map contract token id => bool), expose token Id already metamorphed (if true, cannot mint again)
    mapping (address => mapping (uint256 => bool)) public _isMinted;
    
    uint256 nextIndexToAssign = 0;
    
    constructor() ERC721(NAME, SYMBOL) {}
    
    // Those functions use a contract address and a token id to create a perfect copy named REKT.
    // Contract addresses are not hardcoded but given by the user that wanna mint a REKT.
    // The validity of a given contract/tokenId combination is controlled by the standard ERC721.tokenURI() and ERC1155.uri()
    // A REKT NFT replicate the metadata of any standardized ERC721 or ERC1155
    // The particularity is that REKT NFT constantly fetch the ORIGINAL metadata of the token metamorphed once minted
    // If the original metadata come to be updated or destroyed, it will reflect upon REKT NFT
    // That's why REKT only exist if the Original exist. And that's why it's beyond copy/paste something.
    // You cannot mint a REKT if you didn't have chose an Original to metamorph first.
    // This is possible because the TokenURI is something public and linked to your NFT as a public read only function
    // in the contract from where your Original NFT come from. This can be view as a right click + save, tokenized and consistant.
    // It is made for fun purpose, use it as a meme, abuse it, you can litteraly copy any NFT on the Ethereum Blockchain
    // Well almost anys. 
    //
    // It works for every standardized contracts using ERC721 or ERC1155, so almost every contracts published from there
    // in the NFT space. But there is exceptions you cannot metamorph.
    //
    // CryptoPunks are from those, you cannot directly metamorph a CryptoPunks with this method because in the initial contract there is litteraly
    // no way to compute the metadata, the only thing that relate the CryptoPunks origin is the image Hash.
    //
    // Some community members have built a contract named CryptopunksData, who allow to retrieve punks metadata on-chain
    // In fact, I could write some expections to make CryptoPunks REKT-friendly using this, by computing the metadata from this source
    // But the simple fact that the main contract of punks do not have this issue is enough to do not extend it.
    //
    // You cannot REKT two times the same tokenId from a contract, this is a rule set because why not.
    // You can REKT the REKT Id that REKT an Original. Indefinitely.
    // If one day, metadata of the Original change, the whole REKT Chain will update regarding the Original.
    // This is not easy to get, but if you get it, that's cool.
    //
    // In some sort, this project allow any NEWBIES to enter NFTs on Ethereum Blockchain. As soon as they have gas..
    // And the best is that they can mostly chose ANY NFTs they ever dreamed of (aside of some exceptions).
    // REKT don't hold any value at the basis. Metamorphing a super priced NFT using this contract
    // doesn't have for purpose to give it value. Owning Mona Lisa and a post card of Mona Lisa differ.
    // It's even cooler if you ownn something big to entertain your community
    // You can giveaway an unlimited amount of copy of it (that is tracabely not the Original) using REKT Chain, and this for no cost (+gas)
    //
    // Use REKT Community as something educative.
    // Avoid trading REKT for money on secondary, educate people about REKT.
    // At the end you are free to do whatever the fuck you want
    // REKT is your NFT
    //
    // Btw, no royalties will be applied
    //
    // Purely free (why always payable?) but I cannot control gas.
    
    function _REKT721(address contractAddress, uint256 tokenId)
    private {
        require(contractAddress != address(0), "address cannot be zero");
        require(!_isMinted[contractAddress][tokenId], "already REKT");
        require(bytes32(abi.encodePacked(ERC721(contractAddress).ownerOf(tokenId))).length > 0, "This token doesn't exist");
        
        uint256 REKTId = nextIndexToAssign;
        nextIndexToAssign++;
        
        _isMinted[contractAddress][tokenId] = true;
        _fromContract[REKTId] = contractAddress;
        _fromTokenId[REKTId] = tokenId;
        _fromStandard[REKTId] = "721";
        
        _safeMint(msg.sender, REKTId);
    }
    
    // If you want to REKT an ERC721 use this function
    function REKT721(address contractAddress, uint256 tokenId)
    public {
        _REKT721(contractAddress, tokenId);
    }
    
    function _REKT1155(address contractAddress, uint256 tokenId)
    private {
        require(contractAddress != address(0), "address cannot be zero");
        require(!_isMinted[contractAddress][tokenId], "This token is already REKT");
        require(bytes32(abi.encodePacked(ERC1155(contractAddress).uri(tokenId))).length > 0, "This token doesn't exist");
        
        uint256 REKTId = nextIndexToAssign;
        nextIndexToAssign++;
        
        _isMinted[contractAddress][tokenId] = true;
        _fromContract[REKTId] = contractAddress;
        _fromTokenId[REKTId] = tokenId;
        _fromStandard[REKTId] = "721";
        
        _safeMint(msg.sender, REKTId);
    }
    
    // If you want to REKT an ERC1155 use this function
    function REKT1155(address contractAddress, uint256 tokenId)
    public {
        _REKT1155(contractAddress, tokenId);
    }
    
    function tokenURI(uint256 tokenId)
    public view virtual override returns (string memory result) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (bytes32(abi.encodePacked(_fromStandard[tokenId])) == bytes32("721")) 
            result = ERC721(_fromContract[tokenId]).tokenURI(_fromTokenId[tokenId]);
        if (bytes32(abi.encodePacked(_fromStandard[tokenId])) == bytes32("1155"))
            result = ERC1155(_fromContract[tokenId]).uri(_fromTokenId[tokenId]);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}