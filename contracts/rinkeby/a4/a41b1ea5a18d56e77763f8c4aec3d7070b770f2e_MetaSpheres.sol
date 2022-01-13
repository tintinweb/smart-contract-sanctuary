// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Sale.sol";


contract MetaSpheres is ERC721Sale{
    //maxTokens = "1024"  maxMint = "25" price = "90000000000000000"; // 0.09 ETH
    constructor() ERC721Sale("METASPHERES_TESTNET", "MSP", 1024,  10, 90000000000000000) {
        _pause();
    }


}