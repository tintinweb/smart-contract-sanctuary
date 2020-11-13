pragma solidity 0.5.17;

contract GasStation {
  mapping(address => mapping(uint256 => uint256)) gasDeposits;

  function depositGas(address addr) internal {
    setDeposit(addr, 1);
  }

  function releaseGas(address addr) internal {
    setDeposit(addr, 0);
  }

  function setDeposit(address addr, uint256 val) internal {
    for (uint256 i = 0; i < gasDepositSize(); i++) {
      gasDeposits[addr][i] = val;
    }
  }

  function gasDepositSize() internal pure returns (uint256);
}
