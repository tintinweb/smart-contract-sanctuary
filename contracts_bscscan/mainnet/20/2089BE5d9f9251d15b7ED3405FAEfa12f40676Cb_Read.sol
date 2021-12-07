/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Mining {
    function calculatePool(uint pool_, address addr_) external view returns (uint rew_);
    function userPool(address addr_, uint pool_) external view returns (uint, uint, uint, uint);
    function checkPoudage(uint amount_) external view returns (uint rew_, uint burn_, uint pool_);
    function checkRew(address addr_, uint pool_) external view returns (uint);
    function done(address addr_) external view returns(bool);
}

contract Read {
    Mining public old = Mining(0xAd29a38E29f43e8376eA904B06f3d7b39101587E);
    Mining public news = Mining(0x9b793016c3a299c5307807d335D1efF3ab0e450C);
    
    function read (address addr_, uint pool_) external view returns(uint){
         
        
        (,,uint toClaim,) = old.userPool(addr_, pool_);
        if(!news.done(addr_)) {
            uint tempAmount = old.calculatePool(pool_,addr_) + toClaim;
            (uint rew,,) = old.checkPoudage(tempAmount);
            return rew;
        }else{
            return news.checkRew(addr_, pool_);
        }
    }
}