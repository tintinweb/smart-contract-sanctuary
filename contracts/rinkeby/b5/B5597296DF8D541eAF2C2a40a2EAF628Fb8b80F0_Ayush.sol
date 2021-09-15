// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;
interface Employee{
    function EmpId(uint i, string memory name, string memory dep, uint salary) external;
   // function EmpName(string memory n) external;
    //function EmpDep(string memory d)  external;
    //function EmpSalary(uint s) external;
}
contract Ayush is Employee{
    uint  public  _empid;
    string public _emName;
    string  public _empdep ;
    uint   public _empsalary;
    function EmpId(uint i, string memory name, string memory dep, uint salary) public override
     { 
        _empid=i;
        _emName=name;
        _empdep=dep ;
       _empsalary=salary;
        
     }
    // function EmpName(string memory n) public override
    // {
    //     _n=n;
    // }
    // function EmpDep(string memory d) public override
    // {
    //     _d=d;
    // }
    // function EmpSalary(uint s) public override
    // {
    //     _s=s;
    // }
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