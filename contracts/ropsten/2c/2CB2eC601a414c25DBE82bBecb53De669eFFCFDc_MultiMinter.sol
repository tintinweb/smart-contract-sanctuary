/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.5.0;

// import './GenArtMinterV2_DoodleLabs.sol';


contract MultiMinter  {
    address public genArtCore;

    constructor(address _genArtCore) public {
        genArtCore = _genArtCore;
    }

}