// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;
interface Employee{
    function EmpId(uint i) external;
    function EmpName(string memory n) external;
    function EmpDep(string memory d)  external;
    function EmpSalary(uint s) external;
}
contract Ayush is Employee{
    uint  public  _i;
    string public _n;
    string  public  _d;
    uint   public _s;
    function EmpId(uint i) public override
     { 
          _i=i;
     }
    function EmpName(string memory n) public override
    {
        _n=n;
    }
    function EmpDep(string memory d) public override
    {
        _d=d;
    }
    function EmpSalary(uint s) public override
    {
        _s=s;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}