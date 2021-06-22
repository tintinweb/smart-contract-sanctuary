// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";


contract THE_MAN_WHO_SOLD_THE_WORLD is ERC721 {
 

    string this_base_uri;
    address this_owner;
    
    constructor() ERC721("THE_MAN_WHO_SOLD_THE_WORLD", "WORLD") {
         this_owner = msg.sender;
         this_base_uri = "https://the-man-who-sold-the-world.com/metadata.php?id=";
    }
    
    function _baseURI() internal view override returns (string memory) {
        return this_base_uri;
    }
    
    function set_new_base_uri(string calldata new_base_uri)external{
        require(this_owner ==  msg.sender,"you are not allowed");
        this_base_uri = new_base_uri;
    }

   function claimPlot(uint16 token_id) external payable  {
        require(msg.value >= .01 ether , "price is too small");
        require(token_id>0 && token_id<10001,"token out of bounds");
       _safeMint(msg.sender, token_id);
       payable(this_owner).transfer(msg.value);
    }
    
    function premint(uint16[5] calldata token_ids ) external {
        require(this_owner ==  msg.sender,"you are not allowed");
        for (uint i = 0;i<5;i++){
            _safeMint(msg.sender, token_ids[i]);
        }
    }

}