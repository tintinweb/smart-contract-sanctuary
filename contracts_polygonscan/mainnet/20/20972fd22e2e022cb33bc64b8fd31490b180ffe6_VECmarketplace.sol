// SPDX-License-Identifier: MIT
/*

                                                                                
                                                                                
       /############%%(/,                ((########(           (#######(        
       /####################             %#########&           (#######(        
       /####################(*           /##########           (#######(        
       /#####################%          ,###########*          (#######(        
       /#####################(         #(############%         (#######(        
       /#######      (########         &#############&         (#######(        
       /#######       (######(         *######/######(         (#######(        
       /#######      /(######(        *####### #######(        (#######(        
       /#######    # (#######/        %######* *######(&       (#######(        
       /###################(%         #######   #######        (#######(        
       /##################*.         ,######(   (######/       (#######(        
       /#####################/      (#######(   (########      (#######(        
       /######################      %#######*    #######/      (#######(        
       /#######       .########(    (######/,,,,,/#######      (#######(        
       /#######        %#######%   ,#####################/     (#######(        
       /#######       &(#######%   #######################%    (#######(        
       /#######       *########%  &#######################,    (#######(        
       /#######################(  /########################    (#######(        
       /######################,  *#######/         /#######(   (#######(        
       /#####################%   %#######%         %#######(&  (#######(        
       /####################&    ########(         (########.  (#######(        
       /##############/*        *#######/           /#######(  (#######(        
                                                                                
                                                                                
	https://BlockAI.site

*/
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title 'Virtual<=>Ecommerce Marketplace'
 * Used for manual purchasing exclusive amounts of virtual assets (including crypto) by fiat money vouchers and vice versa - used for manual purchasing exclusive amounts of eCommerce goods by crypto.
 * www.BlockAI.site www.BlockAI.in
*/

contract VECmarketplace is ERC721Tradable {
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("VECmarketplace", "VEC", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://blockai.site/API/VECmarketplace/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://blockai.site/API/VECmarketplace/collection.json";
    }
}