pragma solidity ^0.6.0;

abstract contract ILoanShifter {
    function getLoanAmount(uint, address) public virtual returns (uint);
    function getUnderlyingAsset(address _addr) public view virtual returns (address);
}
