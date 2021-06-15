/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.5.0;

contract Claims {

    uint claimCount = 0;

    event Claim(string dataHash, string dataPointer);
    
    function claim(string memory dataHash, string memory dataPointer) public {

        claimCount++;

        emit Claim(dataHash, dataPointer);
        
    }

    function getClaimCount() public view returns (uint) {

        return claimCount;

    }

}