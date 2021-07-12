/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: contracts/TestContract.sol

pragma experimental ABIEncoderV2;
pragma solidity >=0.4.21 <0.7.0;

contract TestContract {

struct TokenDetails {
        string name;
        string symbol;
        uint8 decimals;
        bytes4 category;
        string class;
        address issuer;
        string tokenURI;
    }

function newToken(TokenDetails memory _details) public pure returns (string memory, string memory)
    {
        return (_details.name, _details.symbol);
    }
}