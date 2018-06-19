pragma solidity ^0.4.18;
      
contract MultiTransfer {
    function multiTransfer(address token, address[] _addresses, uint256 amount) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(amount);
        }
    }
}