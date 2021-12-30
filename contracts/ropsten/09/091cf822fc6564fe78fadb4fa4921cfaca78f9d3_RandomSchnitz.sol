/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

struct TokenMetadata {
	address token;
	uint256 register;
}

contract RandomSchnitz {
    TokenMetadata public c;
    uint256 public updated;
    
    
    function PutInSomething(TokenMetadata[] memory _a) public {
        if(_a.length > 1) {
            updated = updated + 1;
        }
    }
}