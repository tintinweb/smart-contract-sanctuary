/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
    
contract Example3 {
    struct Store {
        string a;         
        string b;
        string c;         
        string d;         
    }
 
    //mapping (uint => Store) public purchases;
    Store public purchases;
    
    constructor(){
        purchases.a = "telegram: https://t.me/xxx";
        purchases.b = "website: https://website.com";
        purchases.c = "twitter: https://twitter.com/xxx";
        purchases.d = "gitbook: https://gitbook.com/xxx";
        
    }
    
    
    
    //Store public sik;

   // function set(string memory _id, uint _time) public returns(bool) {
    //    purchases[1].a = _a;
     //   purchases[1].b = _b;
      //  purchases[1].c = _c;
    //    purchases[1].d = _d;
     //   return true;
    //}
    function get() public view returns(Store memory) {
        return purchases;
    }
}