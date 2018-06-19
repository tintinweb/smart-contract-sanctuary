pragma solidity ^0.4.21;

contract MineContractAddress {
    function mine(
        address _account, 
        uint _nonce
    ) public pure returns(address _contract) {
        if (_nonce == 0) _nonce = 128;
        _contract = address(keccak256(bytes2(0xd694), _account, byte(_nonce)));
    }
}