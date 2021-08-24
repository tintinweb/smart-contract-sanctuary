/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

interface Diamond{
    function interact(uint256[] calldata _tokenIds) external;
    
}

contract petWrapper{
    Diamond ghstPetter = Diamond(0x86935F11C86623deC8a25696E1C19a8659CbF95d);
    
    constructor() {
        
    }
    
    function interact(uint256[] calldata _tokenIds) public{
        ghstPetter.interact(_tokenIds);
    }
}