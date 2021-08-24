/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MockCS {

    address public owner = 0xD1BdD1B9D5401E89DeC1E51e4DC350b6057e7382;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function rescueERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }
    
    function delegateCall(address _target, uint _value, bytes calldata _data) external payable onlyOwner
    {
        _target.call{value: _value}(_data);
    }
}