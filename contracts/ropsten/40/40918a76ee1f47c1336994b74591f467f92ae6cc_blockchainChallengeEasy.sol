/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.18;

contract blockchainChallengeEasy{
    
    string Data0;
    string Data1;
    string Data2;
    string Data3;
    string Data4;
    
    function setCat(string _Data0, string _Data1, string _Data2, string _Data3, string _Data4) public {
        Data0 = _Data0;
        Data1 = _Data1;
        Data2 = _Data2;
        Data3 = _Data3;
        Data4 = _Data4;
    }
    
    function getData() public view returns (string, string, string, string, string) {
        return (Data0, Data1, Data2, Data3, Data4);
    }
    
}