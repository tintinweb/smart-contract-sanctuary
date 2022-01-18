/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract Log { // 0xDC37803E2F1D5444b8E059BD672F2d319Cb02B70

    event L(address indexed sender, uint256 indexed a,string s);

    //event BondCreated(uint256 deposit, index_topic_1 uint256 payout, index_topic_2 uint256 expires, index_topic_3 uint256 priceInUSD);

    function requireTest(uint256  a_) public {
        emit L(msg.sender,a_,"requireTest");
        require(a_ > 10," requireTest error");
    }   

    function assertTest(uint256  a_) public {
        emit L(msg.sender,a_,"assertTest1");
        assert(a_ > 10);
         emit L(msg.sender,a_,"assertTest2");
    }   
}