/////////////////////////////////////////////////////////////////////
//                 ######  ####### #     # #######                 //        
//                 #     # #       ##   ## #     #                 //
//                 #     # #       # # # # #     #                 //
//                 #     # #####   #  #  # #     #                 //
//                 #     # #       #     # #     #                 //
//                 #     # #       #     # #     #                 //
//                 ######  ####### #     # #######                 //
/////////////////////////////////////////////////////////////////////

// creator info
//
//
//
//

/////////////////////////////////////////////////////////////////////
// message message message message message message                 //
// message message message message message message                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.0;

import "./OpenZeppelinERC721.sol";

contract _________ is ERC721URIStorage {

    string Messagefrom___CreatorName___ = "_______This message is written in BlockChain_______";

    event Mint();

    constructor() ERC721("____________" , "_____" ) {
        require( _msgSender() == 0xE35B827177398D8d2FBA304d9cF53bc8fC1573B7 );
        _safeMint(_msgSender() , 1);
        _setTokenURI( 1 , "ipfs://Qma55BXzo9mWt21mzpMzXiCyikDNSwwYrCi1Daw2Adpf43" );
        emit Mint();
    } 
}