/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
@title  Flavors Chain Data
@author Ryan Dunn
@notice Due to the deterministic vanity address creation process,
        the contract bytecode must not change if we want to launch
        to another chain and use the same address. This function will
        check the chainId and properly name our token without having
        to launch a contract at a different address. Most of these
        will never be used but for future expansions to new chains
        having the exact same contract address across across the 
        board with bridges already in place will be very valuable
@dev    This contract's address must be entered during the Flavors 
        Token initialization process.
*/

contract FlavorsChainData {

    function tokenSymbol() public pure returns (string memory _tokenSymbol){ return "FLVR"; }

    /**
    @notice gets the EVM chainId
    @return _chainId the numerical chainId of the connected chain.
    */
    function chainId() public view returns (uint _chainId) {return block.chainid;}

    /**
      @notice This function provides the Flavors token with a chain specific name
      @return flavorsTokenName => The Flavors token name, as it applies to the connected chain.
    */
    function tokenName() public view returns (string memory flavorsTokenName) {
             if(chainId() == 1)         {return "FlavorsETH";     }   // ethereum => ETH
        else if(chainId() == 2)         {return "FlavorsEXP";     }   // expanse network => EXP
        else if(chainId() == 3)         {return "testROPS";       }   // ropsten test => ETH
        else if(chainId() == 4)         {return "testRINK";       }   // Rinkeby test net => ETH
        else if(chainId() == 5)         {return "testGOERLI";     }   // Rinkeby test net => ETH
        else if(chainId() == 42)        {return "testKOVAN";      }   // Kovan test net
        else if(chainId() == 56)        {return "FlavorsBSC";     }   // binance Smart Chain => WBNB
        else if(chainId() == 59)        {return "FlavorsEOS";     }   // eos mainnet => EOS
        else if(chainId() == 60)        {return "FlavorsGO";      }   // GoChain => GO
        else if(chainId() == 66)        {return "FlavorsOKEx";    }   // OKExChain Mainnet => OKEx
        else if(chainId() == 10)        {return "FlavorsOPT";     }   // Optimistic Ethereum
        else if(chainId() == 30)        {return "FlavorsRSK";     }   // RSK MainNet => RBTC
        else if(chainId() == 50)        {return "FlavorsXinFin";  }   // XinFin => XDC
        else if(chainId() == 60)        {return "FlavorsGO";      }   // GoChain => GO
        else if(chainId() == 70)        {return "FlavorsHOO";     }   // hoo => WHOO
        else if(chainId() == 78)        {return "FlavorsPETH";    }   // PrimusChain mainnet => 
        else if(chainId() == 80)        {return "FlavorsRNA";     }   // GeneChain => RNA
        else if(chainId() == 82)        {return "FlavorsMTR";     }   // Meter Mainnet => MTR
        else if(chainId() == 86)        {return "FlavorsGATE";    }   // GateChain Mainnet => GT
        else if(chainId() == 88)        {return "FlavorsTOMO";    }   // TomoChain => TOMO
        else if(chainId() == 97)        {return "testBSC";        }   // bsc testnet => TWBNB
        else if(chainId() == 100)       {return "FlavorsXDAI";    }   // dai => xDAI
        else if(chainId() == 108)       {return "FlavorsTT";      }   // ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return "FlavorsFUSE";    }   // Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return "FlavorsHECO";    }   // huobi eco => WHT
        else if(chainId() == 137)       {return "FlavorsPOLY";    }   // poly => WMATIC
        else if(chainId() == 250)       {return "FlavorsFTM";     }   // fantom => WFTM
        else if(chainId() == 256)       {return "testHECO";       }   // heco test => HTT
        else if(chainId() == 269)       {return "FlavorsHPB";     }   // High Performance Blockchain => 
        else if(chainId() == 321)       {return "FlavorsKCC";     }   // kcc => WKCS
        else if(chainId() == 1012)      {return "FlavorsNEW";     }   // Newton => NEW
        else if(chainId() == 1285)      {return "FlavorsMOVR";    }   // Moonriver => MOVR
        else if(chainId() == 1287)      {return "FlavorsALPHA";   }   // moonbase alpha => DEV
        else if(chainId() == 5197)      {return "FlavorsES";      }   // EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return "FlavorsTOOL";    }   // TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return "FlavorsBCH";     }   // Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return "FlavorsNRG";     }   // Energi Mainnet => NRG
        else if(chainId() == 42220)     {return "FlavorsCELO";    }   // celo mainnet => CELO
        else if(chainId() == 42161)     {return "FlavorsARB";     }   // Arbitrum One => AETH
        else if(chainId() == 43114)     {return "FlavorsAVA";     }   // avalanche => WAVAX
        else if(chainId() == 80001)     {return "testPOLY";       }   // Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return "FlavorsOLT";     }   // OneLedger Mainnet => OLT
        else {return "Flavors";}
    }    

    function wrappedNative() public view returns (address) {
             if(chainId() == 1)         {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// ethereum => ETH
        else if(chainId() == 2)         {return 0x0000000000000000000000000000000000000000;}// expanse network => EXP
        else if(chainId() == 3)         {return 0x0000000000000000000000000000000000000000;}// ropsten test => ETH
        else if(chainId() == 4)         {return 0x0000000000000000000000000000000000000000;}// Rinkeby test net => ETH
        else if(chainId() == 5)         {return 0x0000000000000000000000000000000000000000;}// Rinkeby test net => ETH
        else if(chainId() == 42)        {return 0x0000000000000000000000000000000000000000;}// Kovan test net
        else if(chainId() == 56)        {return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;}// binance Smart Chain => WBNB
        else if(chainId() == 59)        {return 0x0000000000000000000000000000000000000000;}// eos mainnet => EOS
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 66)        {return 0x0000000000000000000000000000000000000000;}// OKExChain Mainnet => OKEx
        else if(chainId() == 10)        {return 0x0000000000000000000000000000000000000000;}// Optimistic Ethereum
        else if(chainId() == 30)        {return 0x0000000000000000000000000000000000000000;}// RSK MainNet => RBTC
        else if(chainId() == 50)        {return 0x0000000000000000000000000000000000000000;}// XinFin => XDC
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 70)        {return 0x3EFF9D389D13D6352bfB498BCF616EF9b1BEaC87;}// hoo => WHOO
        else if(chainId() == 78)        {return 0x0000000000000000000000000000000000000000;}// PrimusChain mainnet => 
        else if(chainId() == 80)        {return 0x0000000000000000000000000000000000000000;}// GeneChain => RNA
        else if(chainId() == 82)        {return 0x0000000000000000000000000000000000000000;}// Meter Mainnet => MTR
        else if(chainId() == 86)        {return 0x0000000000000000000000000000000000000000;}// GateChain Mainnet => GT
        else if(chainId() == 88)        {return 0x0000000000000000000000000000000000000000;}// TomoChain => TOMO
        else if(chainId() == 97)        {return 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;}// bsc testnet => TWBNB
        else if(chainId() == 100)       {return 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;}// dai => xDAI
        else if(chainId() == 108)       {return 0x0000000000000000000000000000000000000000;}// ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return 0x0000000000000000000000000000000000000000;}// Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;}// huobi eco => WHT
        else if(chainId() == 137)       {return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;}// poly => WMATIC
        else if(chainId() == 250)       {return 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;}// fantom => WFTM
        else if(chainId() == 256)       {return 0x0000000000000000000000000000000000000000;}// heco test => HTT
        else if(chainId() == 269)       {return 0x0000000000000000000000000000000000000000;}// High Performance Blockchain => 
        else if(chainId() == 321)       {return 0x4446Fc4eb47f2f6586f9fAAb68B3498F86C07521;}// kcc => WKCS
        else if(chainId() == 1012)      {return 0x0000000000000000000000000000000000000000;}// Newton => NEW
        else if(chainId() == 1285)      {return 0x0000000000000000000000000000000000000000;}// Moonriver => MOVR
        else if(chainId() == 1287)      {return 0x0000000000000000000000000000000000000000;}// moonbase alpha => DEV
        else if(chainId() == 5197)      {return 0x0000000000000000000000000000000000000000;}// EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return 0x0000000000000000000000000000000000000000;}// TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return 0x0000000000000000000000000000000000000000;}// Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return 0x0000000000000000000000000000000000000000;}// Energi Mainnet => NRG
        else if(chainId() == 42220)     {return 0x0000000000000000000000000000000000000000;}// celo mainnet => CELO
        else if(chainId() == 42161)     {return 0x0000000000000000000000000000000000000000;}// Arbitrum One => AETH
        else if(chainId() == 43114)     {return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;}// avalanche => WAVAX
        else if(chainId() == 80001)     {return 0x0000000000000000000000000000000000000000;}// Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return 0x0000000000000000000000000000000000000000;}// OneLedger Mainnet => OLT
        // if we launch to another chain,we will have to manually update the address
        else {return 0x0000000000000000000000000000000000000000;}
    }

    function router() public view returns (address) {
             if(chainId() == 1)         {return 0x0000000000000000000000000000000000000000;}// ethereum => ETH
        else if(chainId() == 2)         {return 0x0000000000000000000000000000000000000000;}// expanse network => EXP
        else if(chainId() == 3)         {return 0x0000000000000000000000000000000000000000;}// ropsten test => ETH
        else if(chainId() == 4)         {return 0x0000000000000000000000000000000000000000;}// Rinkeby test net => ETH
        else if(chainId() == 5)         {return 0x0000000000000000000000000000000000000000;}// Rinkeby test net => ETH
        else if(chainId() == 42)        {return 0x0000000000000000000000000000000000000000;}// Kovan test net
        else if(chainId() == 56)        {return 0x10ED43C718714eb63d5aA57B78B54704E256024E;}// binance Smart Chain => WBNB
        else if(chainId() == 59)        {return 0x0000000000000000000000000000000000000000;}// eos mainnet => EOS
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 66)        {return 0x0000000000000000000000000000000000000000;}// OKExChain Mainnet => OKEx
        else if(chainId() == 10)        {return 0x0000000000000000000000000000000000000000;}// Optimistic Ethereum
        else if(chainId() == 30)        {return 0x0000000000000000000000000000000000000000;}// RSK MainNet => RBTC
        else if(chainId() == 50)        {return 0x0000000000000000000000000000000000000000;}// XinFin => XDC
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 70)        {return 0x0000000000000000000000000000000000000000;}// hoo => WHOO
        else if(chainId() == 78)        {return 0x0000000000000000000000000000000000000000;}// PrimusChain mainnet => 
        else if(chainId() == 80)        {return 0x0000000000000000000000000000000000000000;}// GeneChain => RNA
        else if(chainId() == 82)        {return 0x0000000000000000000000000000000000000000;}// Meter Mainnet => MTR
        else if(chainId() == 86)        {return 0x0000000000000000000000000000000000000000;}// GateChain Mainnet => GT
        else if(chainId() == 88)        {return 0x0000000000000000000000000000000000000000;}// TomoChain => TOMO
        else if(chainId() == 97)        {return 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;}// bsc testnet => TWBNB
        else if(chainId() == 100)       {return 0x0000000000000000000000000000000000000000;}// dai => xDAI
        else if(chainId() == 108)       {return 0x0000000000000000000000000000000000000000;}// ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return 0x0000000000000000000000000000000000000000;}// Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return 0x0000000000000000000000000000000000000000;}// huobi eco => WHT
        else if(chainId() == 137)       {return 0x0000000000000000000000000000000000000000;}// poly => WMATIC
        else if(chainId() == 250)       {return 0x0000000000000000000000000000000000000000;}// fantom => WFTM
        else if(chainId() == 256)       {return 0x0000000000000000000000000000000000000000;}// heco test => HTT
        else if(chainId() == 269)       {return 0x0000000000000000000000000000000000000000;}// High Performance Blockchain => 
        else if(chainId() == 321)       {return 0x0000000000000000000000000000000000000000;}// kcc => WKCS
        else if(chainId() == 1012)      {return 0x0000000000000000000000000000000000000000;}// Newton => NEW
        else if(chainId() == 1285)      {return 0x0000000000000000000000000000000000000000;}// Moonriver => MOVR
        else if(chainId() == 1287)      {return 0x0000000000000000000000000000000000000000;}// moonbase alpha => DEV
        else if(chainId() == 5197)      {return 0x0000000000000000000000000000000000000000;}// EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return 0x0000000000000000000000000000000000000000;}// TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return 0x0000000000000000000000000000000000000000;}// Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return 0x0000000000000000000000000000000000000000;}// Energi Mainnet => NRG
        else if(chainId() == 42220)     {return 0x0000000000000000000000000000000000000000;}// celo mainnet => CELO
        else if(chainId() == 42161)     {return 0x0000000000000000000000000000000000000000;}// Arbitrum One => AETH
        else if(chainId() == 43114)     {return 0x0000000000000000000000000000000000000000;}// avalanche => WAVAX
        else if(chainId() == 80001)     {return 0x0000000000000000000000000000000000000000;}// Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return 0x0000000000000000000000000000000000000000;}// OneLedger Mainnet => OLT
        // if we launch to another chain,we will have to manually update the address
        else {return 0x0000000000000000000000000000000000000000;}
    }

    
    // if someone sends us the native coin, just send it back.
    fallback() external payable { payable(msg.sender).transfer(msg.value); }
    receive() external payable { payable(msg.sender).transfer(msg.value); }
}