/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity >=0.8.0;
    interface IERC20 { 
    function approve(address spender, uint256 amount) external returns (bool); 
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool); 
    }
    
    contract MultiTransfer { 
    function multiTransfer(IERC20 _token, address[] calldata _addresses, uint256 _amount) external { uint256 requiredAmount = _addresses.length * _amount;
        _token.approve(address(this), requiredAmount);
        
        uint i = 0;
        for(i; i < _addresses.length; i++){
            _token.transferFrom(msg.sender, _addresses[i], _amount);
        }
    } 
    }