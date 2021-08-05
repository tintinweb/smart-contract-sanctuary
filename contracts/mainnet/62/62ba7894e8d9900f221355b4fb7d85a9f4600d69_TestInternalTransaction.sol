/**
 *Submitted for verification at Etherscan.io on 2020-05-01
*/

pragma solidity >=0.4.21 <0.7.0;
contract TestInternalTransaction {
    address public toAddress = 0x01b347e1d44d8bf466C1762b7C6D2D2a60462ED4;
    
    function () external payable {
        address(uint160(toAddress)).send(msg.value);
    }
    function changeAddress(address _newAddress) public {
        toAddress = _newAddress;
        
    }
    
}