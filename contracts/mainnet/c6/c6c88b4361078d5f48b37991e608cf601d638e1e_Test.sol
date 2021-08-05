/**
 *Submitted for verification at Etherscan.io on 2020-04-15
*/

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

	struct TokenMetadata {
		address token;
		string name;
		string symbol;
		uint8 decimals;
	}

contract Test {
    TokenMetadata public a;
    
    function createNewTokenMetadata() public {
        a.token = msg.sender;
        a.name = "Testing Me";
        a.symbol = "TSTME";
        a.decimals = 18;
    }
}