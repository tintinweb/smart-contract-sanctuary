/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

// Math operations with safety checks that throw on error
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
    }

}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {

    function balanceOf(address _address) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


// Token contract
contract TEST {
    struct abc {
        address a;
        uint256 b;
    }
    mapping(address => abc[]) public abcs;
    
    constructor() public {
        
    }
    
    // 设置
    function setAbc(address _address, uint256 _value) public returns (bool success) {
        abcs[_address].push(abc(_address, _value));
        success = true;
    }
    
    // 用户查询自己的全部提取记录
    function getA(address _address) public view returns (abc[] memory r) {
        uint256 a = abcs[_address].length;
        r = new abc[](a);
    }
    
    // 用户查询自己的全部提取记录
    function getB(address _address) public view returns (uint256 a) {
        a = abcs[_address].length;
    }
    
    // 用户查询自己的全部提取记录
    function getAbcs(address _address) public view returns (abc[] memory r) {
        uint256 a = abcs[_address].length;
        r = new abc[](a);
        for(uint256 i = 0; i < a; i++) {
            // r[i] = records[msg.sender][i];
            r[i] = abcs[_address][i];
        }
        
    }
    
    

}