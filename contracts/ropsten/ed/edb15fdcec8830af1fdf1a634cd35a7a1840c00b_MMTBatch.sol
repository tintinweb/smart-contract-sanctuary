pragma solidity ^0.4.16;

contract MMTBatch {
    
    function batchTransfer(address _tokenAddress, address[] _receivers, uint256[] _values) {
        
        require(_receivers.length == _values.length && _receivers.length >= 1);
        bytes4 methodId = bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint256 i = 0 ; i < _receivers.length; i++){
            if(!_tokenAddress.call(methodId, msg.sender, _receivers[i], _values[i])) {
                revert();
            }
        }
    }
}