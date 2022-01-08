/**
 *Submitted for verification at snowtrace.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGothERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract GothTokenTimelock {

    IGothERC20 private immutable _token;
    address private immutable _beneficiary;
    uint256 private immutable _releaseTime;

    constructor(IGothERC20 token_, address beneficiary_, uint256 releaseTime_) {
        
        //console.log("block timestamp:", block.timestamp);
        //console.log("block release time:", releaseTime_);
        //console.log("block num:", block.number);

        require(releaseTime_ > block.timestamp, "GothTokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    function token() public view virtual returns (IGothERC20) {
        return _token;
    }

    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    function release(uint256 amount) public {
      require(block.timestamp >= _releaseTime, "Tokens are still locked");
      require(amount > 0, "You cannot send a negative amount");
      _token.transfer(_beneficiary, amount);
    }
}