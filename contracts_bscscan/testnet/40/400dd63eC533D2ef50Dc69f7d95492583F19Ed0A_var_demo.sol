/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity^0.6.0;

contract var_demo {
    string public authName; //作家名字
    uint256 public authAge; //作家年龄
    int256 authSal; // 薪水
    bytes32 public authHash; // 作家hash地址
    
    constructor(string memory _name, uint256 _age, int256 _sal) public {
        authName = _name;
        authAge = _age;
        authSal = _sal;
        
        authHash = keccak256(abi.encode(_name, _age, _sal));

    }
}