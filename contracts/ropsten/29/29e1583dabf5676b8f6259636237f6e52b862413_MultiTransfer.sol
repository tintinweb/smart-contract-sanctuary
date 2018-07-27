pragma solidity ^0.4.18;

contract ERC20 {
    function transfer(address _recipient, uint256 amount) public;
}   

contract MultiTransfer {
    
    function multiTransfer(address _tokenAddress, address[] _addresses, uint256 amount) public {
        ERC20 token = ERC20(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
}