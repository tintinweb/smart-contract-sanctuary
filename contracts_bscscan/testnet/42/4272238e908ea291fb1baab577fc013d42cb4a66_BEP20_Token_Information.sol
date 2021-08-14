/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

interface BEP20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}


contract BEP20_Token_Information {
    BEP20 private CA_INSTANCE;
    address private TOKEN_CA;
    
    struct TokenINFO {
        string name;
        string symbol;
        uint8 decimals;
    }
    
    mapping(address => TokenINFO) public toke_information;
    

    constructor(address _token_ca) {
        TOKEN_CA = _token_ca;
        CA_INSTANCE = BEP20(_token_ca);
        
        TokenINFO storage tinfo = toke_information[_token_ca];

        tinfo.name = CA_INSTANCE.name();
        tinfo.symbol = CA_INSTANCE.symbol();
        tinfo.decimals = 88;
        
    }
}