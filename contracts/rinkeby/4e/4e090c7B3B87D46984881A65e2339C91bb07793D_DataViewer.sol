/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.6.0;


interface ICryptoPunk {
    function punkIndexToAddress(uint256 punkIndex) external returns (address);
    function punksOfferedForSale(uint256 punkIndex) external returns (bool, uint256, address, uint256, address);
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}

interface CryptoPunk {
    function punkIndexToAddress(uint256) external view returns (address);
}

contract DataViewer {
    // Instance of cryptopunk smart contract
    CryptoPunk private punkContract;

    constructor(address _punkContract) public {
        punkContract = CryptoPunk(_punkContract);
    }

    function getPunksForAddress(address _user) external view returns(uint256[10000] memory) {
        uint256[10000] memory punks;

        uint256 j=0;
        for (uint256 i=0; i<10000; i++) {
            if ( punkContract.punkIndexToAddress(i) == _user ) {
                punks[j] = i;
                j++;
            }
        }

        punks[j] = uint256(11111);

        return punks;
    }
}