/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.4.24;
//声明合约
contract Cx{
    
    mapping(address => address []) public referrersArr; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count


    function setA(address _user, address _referrer) public returns (bool) {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referralsCount[_user] <=2
        ) {
            referrersArr[_user].push(_referrer);
            referralsCount[_user] += 1;
        }
        return true;
    }
    
    function getReferralsCount(address _user) public  view returns (uint256) {
        return referralsCount[_user];
    }
    
    function getV1(address _user) public  view returns (address) {
        return referrersArr[_user][0];
    }
    function getV2(address _user) public  view returns (address) {
        return referrersArr[_user][1];
    }
}