/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.6.0;


interface CryptoPunk {
    function punkIndexToAddress(uint256) external view returns (address);
}

contract DataViewer {
    // Instance of cryptopunk smart contract
    CryptoPunk private punkContract;

    constructor(address _punkContract) public {
        punkContract = CryptoPunk(_punkContract);
    }

    function getPunksForAddress(address _user, uint256 userBal) external view returns(uint256[] memory) {
        uint256[] memory punks = new uint256[](userBal);
        uint256 j =0;
        uint256 i=0;
        for (i=0; i<10000; i++) {
            if ( punkContract.punkIndexToAddress(i) == _user ) {
                punks[j] = i;
                j++;
            }
        }

        return punks;
    }
}