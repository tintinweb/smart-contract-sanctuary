/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
contract BankTest {
    
    function getStakeInputData() public view returns(string[3] memory) {
        string[3] memory data;
        data[0] = "USDT,BNB,MDX";
        data[1] = "12-31-2021,11-11-2021,01-01-2022";
        data[2] = "30,40,10";
        return data;
    }
    
}