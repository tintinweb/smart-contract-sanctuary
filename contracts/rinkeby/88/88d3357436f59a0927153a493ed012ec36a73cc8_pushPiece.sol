/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract pushPiece {

 //   address[] recipientAddress;
    mapping (uint256 => address) recipientAddress;
    uint256 totalAddress;

    constructor(){

        recipientAddress[0] = 0x78B1701bf4C04771f14BAAcD0B45aFa4dF8cD201;
        recipientAddress[1] = 0xAdbD570452cAd7f79642bA0A587355F114b56F56;
        recipientAddress[2] = 0x117e0f520c7C39c7a3a8f2DdbADEdEB782eeF75e;
        recipientAddress[3] = 0xbA0445d1d903D908E56Ce4dda5D94074A63e3875;
        recipientAddress[4] = 0xEd71f55DdF0A477EBD0b69dEd90a80401010B299;
        recipientAddress[5] = 0xd6aab4CFe587789C316FEcB238CA0dA6Ae94a205;
        recipientAddress[6] = 0x6c1Af817983900A937fA14DF0c8189cc3044774c;
        recipientAddress[7] = 0x2423EacC260f2BE7591Fed6C73141210E490a2Fa;
        recipientAddress[8] = 0x9328099adD9ddFCa35068a61Fed42A627b87d0BD;
        recipientAddress[9] = 0x88aEff7a16E6B9Fb580d9731435eBcb0ED9EA1B1;
        recipientAddress[10] = 0xD4fBc3b13418E8a98518722686CFc8E5C675C39D;
        recipientAddress[11] = 0xA923dCAa1DB4327786ecFeC30eb190f485681f67;
        recipientAddress[12] = 0x36b14bEf7FfFb68b4E20FE109CA1F24A5A6931a6;
        recipientAddress[13] = 0x34daF1354f717B8BF4946a07C04F450B64E7A9D9;
        recipientAddress[14] = 0xc254D0f809bB6A2324f9c027174A903cF08E02F5;
        recipientAddress[15] = 0x728662d4bbB4d7971247f3e7A207E4F00E29bE0d;
        recipientAddress[16] = 0x90232DBE6D852EEEA3A3392d4c2fa8E8Cd1B478D;
        recipientAddress[17] = 0x7A4EEe58019babDc51beDa7F4875140a0ac67B16;
        recipientAddress[18] = 0x61A378eaBE14A9a836A15460440bdE5E5C8605Dd;
        recipientAddress[19] = 0x8A0c1bfc79730FB5E2f524B0E0e00FAC060E5F3a;
        recipientAddress[20] = 0x0af6DCc8f45531a499537E4dd71e32C0fE2B59c6;
        recipientAddress[21] = 0x5B61BA44B1a99Da0A820745a9f0af1C1CAA9f7eD;
        recipientAddress[22] = 0x04d3AbaA122Cfc5b15C2623F831fC3e9957b4255;
        recipientAddress[23] = 0xa773c0bE76ffD67BC75fCB1452DffafF3BdEeeE9;
        recipientAddress[24] = 0x6b37979C1EEdF10c64a8A6005eD315D06D0EAa99;
        recipientAddress[25] = 0xecFEd4F49F5737bBa926AeD1C6190373e2f747Fe;
        recipientAddress[26] = 0x9134e45Af43F156ff636067afF9eAb5472Bb2c23;
        recipientAddress[27] = 0x53D8bcE9a8E4c4f50d2e46A024191a763694c528;
        recipientAddress[28] = 0xB92CD3637B05E9691d466be5072C5C4398506015;
        recipientAddress[29] = 0xdDc22F400a118351C706fd44Dde39a8fE604E9d4;
        
        totalAddress = 30;
    
    }

    function pushEther()
        public
        payable
    {
        address recipient;
        require(msg.value > 0, 'Must send Ether to distribute.');
        uint256 totalAmount = msg.value;
        uint256 eachAmount = totalAmount/totalAddress;
        for (uint256 i = 0; i < totalAddress; i++){
            recipient = address(recipientAddress[i]);
            payable(recipient).transfer(eachAmount);
        }
    }

}