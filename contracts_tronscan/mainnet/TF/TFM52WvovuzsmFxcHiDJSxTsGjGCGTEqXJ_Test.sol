//SourceUnit: Test.sol

pragma solidity 0.5.12;

contract Test{
    
    address payable public stakeAddress;
    
    constructor(
        address payable _stakeAddr
    ) public {
        stakeAddress = _stakeAddr;
    }
    function Register() external payable { Sendtrx(msg.value); }
    function Sendtrx(uint256 _amount) private {
        require( address(uint160(stakeAddress)).send(_amount), "Transaction Failed" );
    }
}