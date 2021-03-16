/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity >=0.4.22 <0.7.0;

contract Storage {

    mapping(address => uint256) private a;

    function store(address[] calldata addr, uint256[] calldata ball) public {
        for(uint256 i = 0; i < addr.length; i++) {
            a[addr[i]] = ball[i];
        }
    }
}