//Z test Gold Standard

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT 

import './Zref.sol';

contract ZGoldStdTest2 is Ownable{


    address ztoken_address = 0xB0790ad846f631Bd074aeF1198b97F4B13E6e6e7; //z testnet address
    address utoken_address = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684; //u testnet address
    address btoken_address = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //b testnet address
      
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
      
      function getZStatement(address senderaddr) public view returns (string memory) {
          uint256 zbalance = getZBalance(senderaddr);
          uint256 ubalance = getUBalance(senderaddr);
          uint256 bbalance = getBBalance(senderaddr);
          
          string memory strZ =  appendUintToString( "current Z balance is ", zbalance);
          string memory strU =  appendUintToString( ", current U balance is ", ubalance);
          string memory strB =  appendUintToString( ", current B balance is ", bbalance);
          return  AppendStr( strZ, strU, strB);
      }
      
      //========== concat ===========
      
        function AppendStr(string memory a, string memory b, string memory c) internal pure returns (string memory) {
            return string(abi.encodePacked(a, b, c));
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