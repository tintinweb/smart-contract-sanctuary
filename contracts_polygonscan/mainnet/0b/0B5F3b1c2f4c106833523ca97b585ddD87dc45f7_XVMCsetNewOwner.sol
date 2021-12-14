/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IacPool {
    function setAdmin() external;
}

interface IMasterChef {
    function owner() external returns (address);
}

interface Iclassic {
    function changeGovernor() external;
}

contract XVMCsetNewOwner {
    address public immutable masterchef = 0x9BD741F077241b594EBdD745945B577d59C8768e;
    address public immutable acPool1 = 0xD00a313cAAe665c4a828C80fF2fAb3C879f7B08B;
    address public immutable acPool2 = 0xa999A93221042e4Ecc1D002E0935C4a6c67FD242;
    address public immutable acPool3 = 0x0E6f5D3e65c0D3982275EE2238eb7452EBf8F31D;
    address public immutable acPool4 = 0x0e4f23dE638bd6032ab0146B02f82F5Da0c407aF;
    address public immutable acPool5 = 0xEa76E32F7626B3A1bdA8C2AB2C70A85A8fdebaAB;
    address public immutable acPool6 = 0xD582d1DF416F421288aa4E8E5813661E1d5b3D5f;

    address public immutable consensusContract = 0x65671eeF95BEc99Be3729C3f25329b0f5A96c5E7;
    address public immutable fibonacceningContract = 0x486DCcdFC03B25Bddda24E53aF908D64970A63Bc;
    address public immutable raContract = 0x131DA2F8FBc014E76Fde92b49966612f497EDf14;
    address public immutable farmContract = 0x108E0e38acCadE1829809e00238fe73c9e4F1e9b; //for setpool
    address public immutable basicContract = 0xE211Ed823aD18f9658b0Df24B51b3634381892f0; //setCallfee, rolloverbonus
    
    //Addresses for treasuryWallet and NFT wallet
    address public treasuryWallet = 0xeF8470c63d4597A401993E02709847620dbd6778;
    address public nftWallet = 0xF803e35A79ea815980D1e6bbC87450D2476d2441;

    function setAll() external {
        IacPool(acPool1).setAdmin();
        IacPool(acPool2).setAdmin();
        IacPool(acPool3).setAdmin();
        IacPool(acPool4).setAdmin();
        IacPool(acPool5).setAdmin();
        IacPool(acPool6).setAdmin();

        Iclassic(consensusContract).changeGovernor();
        Iclassic(fibonacceningContract).changeGovernor();
        Iclassic(raContract).changeGovernor();
        Iclassic(farmContract).changeGovernor();
        Iclassic(basicContract).changeGovernor();

        Iclassic(treasuryWallet).changeGovernor();
        Iclassic(nftWallet).changeGovernor();
    }

    function setPools() external {
        IacPool(acPool1).setAdmin();
        IacPool(acPool2).setAdmin();
        IacPool(acPool3).setAdmin();
        IacPool(acPool4).setAdmin();
        IacPool(acPool5).setAdmin();
        IacPool(acPool6).setAdmin();
    }

    function setSideContracts() external {
        Iclassic(consensusContract).changeGovernor();
        Iclassic(fibonacceningContract).changeGovernor();
        Iclassic(raContract).changeGovernor();
        Iclassic(farmContract).changeGovernor();
        Iclassic(basicContract).changeGovernor();

        Iclassic(treasuryWallet).changeGovernor();
        Iclassic(nftWallet).changeGovernor();
    }
}