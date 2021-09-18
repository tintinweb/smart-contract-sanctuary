//Z test Gold Standard

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT 

import './Zref.sol';
import './libs.sol';

contract ZGoldStdTest3 is Context, Ownable{


    address ztoken_address = 0xB0790ad846f631Bd074aeF1198b97F4B13E6e6e7; //z testnet address
    address utoken_address = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684; //u testnet address
    address btoken_address = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //b testnet address
    
    //PancakeRouter testnet= https://testnet.bscscan.com/address/0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
    //PancakeRouter mainnet= https://bscscan.com/address/0x10ed43c718714eb63d5aa57b78b54704e256024e
    
    address dex_test = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address dex_main = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
      
      function getZBalance(address senderaddr) public view returns (uint256) {
                                                                   //address senderaddr = msg.sender; 
        return ERC20(ztoken_address).balanceOf(senderaddr);
      }
      
     function getZSupply() public view returns (uint256) {
        return ERC20(ztoken_address).totalSupply();
      }
      
     function getUBalance(address senderaddr) public view returns (uint256) {
        return ERC20(utoken_address).balanceOf(senderaddr);
      }
      
     function getUSupply() public view returns (uint256) {
        return ERC20(utoken_address).totalSupply();
      }
      
     function getBBalance(address senderaddr) public view returns (uint256) {
        return ERC20(btoken_address).balanceOf(senderaddr);
      }
      
     function getBSupply() public view returns (uint256) {
        return ERC20(btoken_address).totalSupply();
      }
      
      function getStatement() public view returns (string memory) {
          
           //DEX balances
          string memory strZd =  appendUintToString( "  DEX Z balance is ", getZBalance(dex_test));
          string memory strUd =  appendUintToString( ", DEX U balance is ", getUBalance(dex_test));
          string memory strBd =  appendUintToString( ", DEX B balance is ", getBBalance(dex_test));
          
          //GoldStd balances
          string memory strZg =  appendUintToString( ", GoldStd Z balance is ", getZBalance(msg.sender));
          string memory strUg =  appendUintToString( ", GoldStd U balance is ", getUBalance(msg.sender));
          string memory strBg =  appendUintToString( ", GoldStd B balance is ", getBBalance(msg.sender));
          
          return  AppendStr( strZd, strUd, strBd, strZg, strUg, strBg);
      }
      
      //========== concat ===========
      
        function AppendStr(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f) internal pure returns (string memory) {
            return string(abi.encodePacked(a, b, c, d, e, f));
        }
        
        function uintToString(uint v) private pure returns (string memory) {
            uint maxlength = 100;
            bytes memory reversed = new bytes(maxlength);
            uint i = 0;
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i++] = bytes1(uint8(48 + remainder));
            }
            bytes memory s = new bytes(i); // i + 1 is inefficient
            for (uint j = 0; j < i; j++) {
                s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
            }
            string memory str = string(s);  // memory isn't implicitly convertible to storage
            return str;
        }


        function appendUintToString(string memory inStr, uint v) private pure returns (string memory str) {
            uint maxlength = 100;
            bytes memory reversed = new bytes(maxlength);
            uint i = 0;
            while (v != 0) {
                uint remainder = v % 10;
                v = v / 10;
                reversed[i++] = bytes1(uint8(48 + remainder));
            }
            bytes memory inStrb = bytes(inStr);
            bytes memory s = new bytes(inStrb.length + i);
            uint j;
            for (j = 0; j < inStrb.length; j++) {
                s[j] = inStrb[j];
            }
            for (j = 0; j < i; j++) {
                s[j + inStrb.length] = reversed[i - 1 - j];
            }
            str = string(s);
        }

}