/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TimeLock{
    using SafeERC20 for IERC20;

    address public owner;
    uint256 public beginTime;
    uint256 public dt;
    IERC20 public token;

    constructor() public{
        owner = msg.sender;
        beginTime=block.timestamp;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"not owner");
        _;
    }

    function setTokenDt(address _token,uint256 _dt) onlyOwner public{
        dt = _dt;
        token = IERC20(_token);
    }
    
    function withdraw() onlyOwner public{
        require(block.timestamp>=beginTime+dt);
        require(available()>0);
        token.safeTransfer(owner,available());
    }

    function available() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
    
  
}