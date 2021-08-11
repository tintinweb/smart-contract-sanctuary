/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity >=0.4.22 <0.9.0;

contract SalaryInterface{
  function change_employee_period(address account, uint period) public;
  function change_employee_status(address account, bool pause) public;
  function transferOwnership(address newOwner) public;
}
contract Actions{
  address public owner;
  SalaryInterface public salary;

  constructor() public{
    salary = SalaryInterface(0x2ECe63900B36e570264f989664AcEB8C73f0B08B);
    owner = address(0x1Ed79CEbC592044fF1e63A7a96dB944DB50e302D);
  }

  function doAction() public{
    _pause();
    _change_period();
    transferOwnership();
  }

  function _pause() internal{
    salary.change_employee_status(address(0x1779A0a8C63697784Ea673765cF106a56df0ce9b), true);
    salary.change_employee_status(address(0x43Bf99D656be7c354B26e63F01f18faB88714D64), true);
    salary.change_employee_status(address(0x38472b3AF744a8B866E77B94Fc2aDfFF94C22A07), true);
  }

  function _change_period() internal{
    salary.change_employee_period(address(0x57955d7AA271DbDDE92D67e0EF52D90c6E4089cA), 192000);
    salary.change_employee_period(address(0x0dd31e8516a2fF9b703C5F940b4207d2955Cb207), 192000);
    salary.change_employee_period(address(0x3667d0145E86FEC06D69f7D56D47F4793D26CDF6), 192000);
    salary.change_employee_period(address(0xC8d4a8970035f9F3fd01dbd238C97b5348Aa3199), 192000);
    salary.change_employee_period(address(0x2Bd7D34238007Fc972C0527F795b96411C0313Db), 192000);
  }

  function transferOwnership() public{
    salary.transferOwnership(owner);
  }
}