pragma solidity ^0.4.24;
contract TestCC{
    uint256 testflag = 8847514;
    string  teststr = "this is a test string !!!!!!!";
    mapping (address => uint256) userkeys;
    
    function getflag() public view returns(uint256) {
        return testflag;    
    }
    
    
    function getstr() public view returns(string) {
        return teststr;    
    }
    
    function getnum(address _sender) public view returns (uint256) {
        return userkeys[_sender];
    }
    
    function() payable public{
        userkeys[msg.sender] = userkeys[msg.sender] + (msg.value / 10);
    }
}