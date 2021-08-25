// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract MultiSend is Ownable {
    
    event TransferETH(address _to, uint _amount);
    
    function multiSendETH(address[] memory _addresses, uint[] memory _amounts) public onlyOwner {
        require(_amounts.length == _addresses.length, "Lists should be equal in length");
        
        for (uint i = 0; i <_addresses.length; i++) {
            (bool sent,) = _addresses[i].call{value: _amounts[i]}("");
            require(sent, "Failed to send Ether");
            emit TransferETH(_addresses[i], _amounts[i]);
        }
    }

    function multisendERC20(address _tokenAddress, address[] memory _addresses, uint[] memory _amounts) public onlyOwner {
        require(_amounts.length == _addresses.length, "Lists should be equal in length");
        
        IERC20 token = IERC20(_tokenAddress);
        
        for (uint i = 0; i <_addresses.length; i++) {
            token.transfer(_addresses[i],_amounts[i]);
        }
    }

    receive() external payable{}    

}