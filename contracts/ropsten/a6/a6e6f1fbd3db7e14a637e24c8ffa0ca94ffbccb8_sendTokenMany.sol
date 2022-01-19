/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

interface IERC20 { 
function approve(address spender, uint256 amount) external returns (bool); 
function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 

// ERC-1155
function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes calldata _data
) external;


}


contract sendTokenMany{
    address public  owner;
    constructor() public {
        owner = msg.sender;
    }
    
    function investment2(address[] memory addresses) public payable {
        uint amount;
        for(uint8 i = 0; i < addresses.length; i++) {
           amount = msg.value;
            address(uint160(addresses[i])).transfer(amount);
            
        }
    }


    function multiTransfer(IERC20 _token, address[] calldata addresses, uint256 _amount) external { 
         uint256 requiredAmount = addresses.length * _amount;
        _token.approve(address(this), requiredAmount);
    
        uint i = 0;
        for(i; i < addresses.length; i++){
            _token.transferFrom(msg.sender, addresses[i], _amount);
        }
    }
    
     
}