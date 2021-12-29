pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721.sol";


// =========== =========== =========== =========== =========== 
//   |  |  |     |  |  |     |  |  |     |  |  |     |  |  |   
// =========== =========== =========== =========== =========== 
//   |     |     |     |     |     |     |     |     |     |   
//   |     |     |     |     |     |     |     |     |     |   


// =========== =========== =========== =========== =========== 
//   |  |  |     |  |  |     |  |  |     |  |  |     |  |  |   
// =========== =========== =========== =========== =========== 
//   |     |     |     |     |     |     |     |     |     |   
//   |     |     |     |     |     |     |     |     |     |   



//ZZZZZZZZZZZZZZZZZZZ  iiii                    jjjj                   
//Z:::::::::::::::::Z i::::i                  j::::j                  
//Z:::::::::::::::::Z  iiii                    jjjj                   
//Z:::ZZZZZZZZ:::::Z                                                  
//ZZZZZ     Z:::::Z  iiiiiiinnnn  nnnnnnnn   jjjjjjj  aaaaaaaaaaaaa   
//        Z:::::Z    i:::::in:::nn::::::::nn j:::::j  a::::::::::::a  
//       Z:::::Z      i::::in::::::::::::::nn j::::j  aaaaaaaaa:::::a 
//      Z:::::Z       i::::inn:::::::::::::::nj::::j           a::::a 
//     Z:::::Z        i::::i  n:::::nnnn:::::nj::::j    aaaaaaa:::::a 
//    Z:::::Z         i::::i  n::::n    n::::nj::::j  aa::::::::::::a 
//   Z:::::Z          i::::i  n::::n    n::::nj::::j a::::aaaa::::::a 
//ZZZ:::::Z     ZZZZZ i::::i  n::::n    n::::nj::::ja::::a    a:::::a 
//Z::::::ZZZZZZZZ:::Zi::::::i n::::n    n::::nj::::ja::::a    a:::::a 
//Z:::::::::::::::::Zi::::::i n::::n    n::::nj::::ja:::::aaaa::::::a 
//Z:::::::::::::::::Zi::::::i n::::n    n::::nj::::j a::::::::::aa:::a
//ZZZZZZZZZZZZZZZZZZZiiiiiiii nnnnnn    nnnnnnj::::j  aaaaaaaaaa  aaaa
//                                            j::::j                  
//                                  jjjj      j::::j                  
//                                 j::::jj   j:::::j                  
//                                 j::::::jjj::::::j                  
//                                  jj::::::::::::j                   
//                                    jjj::::::jjj                    
//                                       jjjjjj                       



// =========== =========== =========== =========== =========== 
//   |  |  |     |  |  |     |  |  |     |  |  |     |  |  |   
// =========== =========== =========== =========== =========== 
//   |     |     |     |     |     |     |     |     |     |   
//   |     |     |     |     |     |     |     |     |     |   


// =========== =========== =========== =========== =========== 
//   |  |  |     |  |  |     |  |  |     |  |  |     |  |  |   
// =========== =========== =========== =========== =========== 
//   |     |     |     |     |     |     |     |     |     |   
//   |     |     |     |     |     |     |     |     |     |   



contract Torii is  ERC721URIStorage , ERC721Enumerable{

    address public owner;
    uint public nftid = 0;
    mapping(uint => string) toriiMessage;

    //zinja metadata
    string[5] z;

    //O-torii metadata
    string[4] o;

    //senbon-torii metadata
    string[4] s;

    mapping(uint=>string) builtyear;

    function multiMint(uint qty) public {
        require( _msgSender() == owner );
        uint target = nftid - 1 + qty;
        for (uint i = nftid; i <= target; i++ ){
            _safeMint( owner , nftid);
            builtyear[nftid] = calcYear();
            nftid++;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721,ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721,ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721,ERC721URIStorage)
        returns (string memory)
    {
        if(tokenId == 0){
            string memory Otorii = string(abi.encodePacked(z[0],o[0],Strings.toString(tokenId),o[1],z[1],o[2],z[2],o[3],builtyear[tokenId],z[3],readToriiMessage(tokenId),z[4]));
            return Otorii;
        }
        string memory json = string(abi.encodePacked(z[0],s[0],Strings.toString(tokenId),s[1],z[1],s[2],z[2],s[3],builtyear[tokenId],z[3],readToriiMessage(tokenId),z[4]));
        return json;
    }

    function setToriiMessage(uint _tokenId , string memory _toriiMessage ) public {
        require(_msgSender() == ownerOf(_tokenId));
        toriiMessage[_tokenId] = _toriiMessage;
    }

    function readToriiMessage(uint _tokenId ) public view returns(string memory){
        if(keccak256(abi.encodePacked(toriiMessage[_tokenId])) == keccak256(abi.encodePacked("")) ){
            return "no name";
        }
        return toriiMessage[_tokenId];
    }

    function calcYear() public view returns (string memory){
        return Strings.toString(calcYearLogic(block.timestamp));
    }

    function calcYearLogic(uint _unixtime) public pure returns (uint){
        return 1970 + _unixtime/((31536000 * 3 + 31622400)/4);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721,ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("torii" , "TORII" ) {

        z[0] = "data:application/json;utf8,{\"name\":\"";
        s[0] = "\u3010\u5343\u672c\u9ce5\u5c45\u3011Engrave name on the Senbon-Torii #";
        o[0] = "\u3010\u5275\u5efa\u8a18\u5ff5 \u5927\u9ce5\u5c45\u3011Engrave name on the O-Torii";
        s[1] = "\",\"description\":\"Metaverse\u306b\u5275\u5efa\u3055\u308c\u308bCrypto Zinja\u306b\u5b58\u5728\u3059\u308b\u5343\u672c\u9ce5\u5c45\u306b\u540d\u524d\u3092\u523b\u3080\u6a29\u5229\u306eNFT\u3067\u3059\u3002\u540d\u524d\u3092\u523b\u3080\u3053\u3068\u306f\u30d7\u30ed\u30b8\u30a7\u30af\u30c8\u3092\u5171\u306b\u652f\u3048\u3066\u4e0b\u3055\u308b\u8a3c\u3068\u306a\u308a\u307e\u3059\u3002";
        o[1] = "\",\"description\":\"Metaverse\u306b\u5275\u5efa\u3055\u308c\u308bCrypto Zinja\u306e\u4e2d\u592e\u306b\u5b58\u5728\u3059\u308b\u5927\u9ce5\u5c45\u306b\u540d\u524d\u3092\u523b\u3080\u6a29\u5229\u306eNFT\u3067\u3059\u3002\u8a18\u5ff5\u3059\u3079\u304d\u5275\u5efa\u8a18\u5ff5\u306e\u5927\u9ce5\u5c45\u306b\u540d\u524d\u3092\u523b\u3080\u3053\u3068\u306f\u30d7\u30ed\u30b8\u30a7\u30af\u30c8\u3092\u5927\u304d\u304f\u652f\u3048\u3066\u4e0b\u3055\u308b\u8a3c\u3068\u306a\u308a\u307e\u3059\u3002";
        z[1] = "Crypto Zinja\u306e\u6b63\u5f0f\u30aa\u30fc\u30d7\u30f3\u3068\u5171\u306b\u3053\u3061\u3089\u306e\u30da\u30fc\u30b8\u304b\u3089\u540d\u524d\u3092\u523b\u3080\u4e8b\u304c\u51fa\u6765\u307e\u3059\u3002 https://conata.world/zinja \u3000\u523b\u3080\u540d\u524d\u306b\u95a2\u3057\u3066\u306f\u304a\u540d\u524d\u3001\u4f01\u696d\u540d\u3001\u30d7\u30ed\u30b8\u30a7\u30af\u30c8\u540d\u306a\u3069\u597d\u304d\u306a\u6587\u5b57\u3092\u523b\u3093\u3067\u9802\u304f\u3053\u3068\u304c\u3067\u304d\u307e\u3059\u3002Crypto Zinja\u306f\u65e5\u672c\u53e4\u6765\u306e\u6587\u5316\u3092\u984c\u6750\u306b\u73fe\u5b9f\u7a7a\u9593\u3092\u5dfb\u304d\u8fbc\u307f\u62e1\u5f35\u3057\u3066\u3044\u304f\u30d7\u30ed\u30b8\u30a7\u30af\u30c8\u3067\u3059\u3002\u3053\u306e\u7a7a\u9593\u3092\u5171\u306b\u80b2\u3066\u3066\u304f\u3060\u3055\u308b\u3042\u306a\u305f\u306b\u611f\u8b1d\u3092\u8fbc\u3081\u3066\u3002  \\n  \\nThis is an NFT for the right to have your name engraved on the ";
        s[2] = "Senbon";
        o[2] = "O";
        z[2] = "-Torii gate of Crypto Zinja, which will be built in Metaverse. You can inscribe your name on this page when Crypto Zinja is officially opened: https://conata.world/zinja You can inscribe your name, company name, project name, etc. Crypto Zinja is a project to involve and expand the real space based on the ancient Japanese culture. I would like to express our gratitude to you who will nurture this space with us.\",\"animation_url\":\"";
        s[3] = "https://arweave.net/NsU6pqKl04X6m0E7_fEKut3j5kBYQ1421cf1NW9gtGY\",\"image\":\"https://arweave.net/7FdbwyAuZ80xjZMm71Fz7ssCovFd1wtmKhGTqEvu-7U\",\"external_url\":\"https://conata.world/zinja\",\"attributes\":[{ \"trait_type\": \"Artist\", \"value\": \"AIMI SEKIGUCHI\"},{\"trait_type\": \"Tori-name\", \"value\": \"Senbon-Torii\"},{\"trait_type\": \"Year\", \"value\": \"";
        o[3] = "https://arweave.net/ioEuPnHgNSwwP1lrh4t6JKl0tTE-lkymCHAnDBLaCF4\",\"image\":\"https://arweave.net/Fl6pX4mF5RvldLIlVq5FFlWw9MGaV7GdxSfuO2hpXFw\",\"external_url\":\"https://conata.world/zinja\",\"attributes\":[{ \"trait_type\": \"Artist\", \"value\": \"AIMI SEKIGUCHI\"},{\"trait_type\": \"Tori-name\", \"value\": \"O-Torii\"},{\"trait_type\": \"Year\", \"value\": \"";
        z[3] = "\"},{\"trait_type\": \"Dedication Name\", \"value\": \"";
        z[4] = "\"}]}";
        owner = _msgSender();
        _safeMint( owner , nftid);


        builtyear[0] = "2021";
        nftid++;
    } 
}