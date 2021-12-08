// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC777.sol";

contract AT777 is ERC777 {
    constructor(
        uint256 initialSupply,
        address[] memory at
        //address _trustedSigner
    )
    ERC777("AT777", "AT7", at)
    //GSNRecipientSignature(_trustedSigner)
   
    {
        _mint(msg.sender, initialSupply, "","");
    }

}