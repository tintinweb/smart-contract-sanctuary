pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract Wallet {
    address owner = msg.sender;
    
    
    function externalCall(address payable[] memory _to, bytes[] memory _data) public {
        require(msg.sender == owner);
        
        for(uint16 i = 0; i < _to.length; i++) {
            cast(_to[i], _data[i], 0);
        }
        
    }
    
    function externalCallEth(address payable[] memory  _to, bytes[] memory _data, uint256[] memory ethAmount) public payable {
        require(msg.sender == owner);
        
        
        for(uint16 i = 0; i < _to.length; i++) {
            cast(_to[i], _data[i], ethAmount[i]);
        }
        
    }
    
    function cast(address payable _to, bytes memory _data, uint256 ethAmount) internal {
        bytes32 response;
        
        assembly {
            let succeeded := call(sub(gas, 5000), _to, ethAmount, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)
            switch iszero(succeeded)
            case 1 {
                revert(0, 0)
            }
        }
    }
}