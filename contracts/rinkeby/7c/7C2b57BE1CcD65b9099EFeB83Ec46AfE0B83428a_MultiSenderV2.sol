/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.2;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract MultiSenderV2 {
    
    // make these function payable to apply service-charge
    
    function transferERC20(address _tokenAddress, address[] memory _recipients, uint[] memory _amounts) public {
        require(_recipients.length == _amounts.length, "number of recipients and amounts should be same");
        for(uint i=0; i<_recipients.length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}