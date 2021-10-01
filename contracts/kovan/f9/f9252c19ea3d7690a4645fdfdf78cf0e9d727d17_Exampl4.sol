/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
    
contract Exampl4 {
    struct Store {
        string id;         
        address time;         
    }
 
 
 string a;
 string b;
 string c;
 string d;
 
   Store public purchases;
    
    constructor() {
        
        a = "dodao";
        b = "rdrqwrqwodao";
        c = "dodarwqrqwo";
        d = "dodarqwrqwo";
    Store memory sik;
    purchases = sik; 
    }

      function getData() public pure returns (bytes32, bytes32) {
        bytes32 y = "abcd";
        bytes32 u = "wxyz";
        return (y, u);
      }
        
    function out() public view returns (string memory, string memory, string memory, string memory) {
        return (a, b, c, d);
    }


function oeut() public view returns (string memory) {
        return a;
        
    
    }
    
function oeugwt() public view returns (string memory, string memory) {
        return (a,b);
        
    
    }
    

    
    
function oeuwt() public pure returns (string memory, string memory, string memory) {
        string memory j = "dodao";
        string memory k = "rdrqwrqwodao";
        string memory l = "dodarwqrqwo";
return (j,k,l);}
    
    function set(string calldata _id, address  _time) public returns(bool) {
        purchases.id = _id;
        purchases.time = _time;
        return true;
    }

    function get() public view returns(Store memory) {
        return purchases;
    }
    
}