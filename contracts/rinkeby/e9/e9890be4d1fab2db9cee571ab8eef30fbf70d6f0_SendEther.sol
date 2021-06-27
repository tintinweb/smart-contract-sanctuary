/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-16
*/

pragma solidity 0.5.1;

contract SendEther {
    
    event Transferred(uint256 value , address sender);
    
    function() external payable{}
    
    function SendEtherToAddresses(address payable[] memory _addresses, uint256[] memory _amounts) public payable {
        
        for (uint256 i=0; i < _amounts.length; i++) {
            _addresses[i].transfer(_amounts[i]);
        }
        
        emit Transferred(msg.value, msg.sender);
    }
}