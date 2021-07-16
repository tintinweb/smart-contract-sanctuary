pragma solidity ^0.5.0;

interface INft {
    function mintWithTokenURI(address to, string calldata tokenURI,uint256 quantity, bool flag) external returns (bool);
}

pragma solidity ^0.5.0;

import "./InterfaceForMarketPlace.sol";

contract testcase {

address private xanaliaDEX;
  constructor() public {
    xanaliaDEX = 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1;
  }
  function _mintNfts() public {
      INft(xanaliaDEX).mintWithTokenURI(msg.sender,"1",1,true);
    }
}