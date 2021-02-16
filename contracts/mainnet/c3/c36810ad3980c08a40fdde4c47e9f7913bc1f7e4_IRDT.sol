pragma solidity ^0.4.0;

import "./Erc20Token.sol";
import "./TokenContractWithTokenFee.sol";

/**
 * Website: IRDT.io
 **/
contract IRDT is TokenContractWithTokenFee {
    constructor (address[] BoDAddress, address[] accessors) public {
        BoDAddresses = BoDAddress;
        mintAccessorAddress = accessors[0];
        mintDestChangerAddress = accessors[1];
        blackListAccessorAddress = accessors[2];
        blackFundDestroyerAccessorAddress = accessors[3];
        mintAddress = accessors[4];
    }
}