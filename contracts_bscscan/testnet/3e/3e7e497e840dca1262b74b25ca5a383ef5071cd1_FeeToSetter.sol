/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

// this contract serves as feeToSetter, allowing owner to manage fees in the context of a specific feeTo implementation
contract FeeToSetter {
    // immutables
    address public factory;
    uint public vestingEnd;
    address public feeTo;

    address public owner;

    constructor(address factory_, uint vestingEnd_, address owner_, address feeTo_) public {
        require(vestingEnd_ > block.timestamp, 'FeeToSetter::constructor: vesting must end after deployment');
        factory = factory_;
        vestingEnd = vestingEnd_;
        owner = owner_;
        feeTo = feeTo_;
    }

    // allows owner to change itself at any time
    function setOwner(address owner_) public {
        require(msg.sender == owner, 'FeeToSetter::setOwner: not allowed');
        owner = owner_;
    }

    // allows owner to change feeToSetter after vesting
    function setFeeToSetter(address feeToSetter_) public {
        require(block.timestamp >= vestingEnd, 'FeeToSetter::setFeeToSetter: not time yet');
        require(msg.sender == owner, 'FeeToSetter::setFeeToSetter: not allowed');
        IUniswapV2Factory(factory).setFeeToSetter(feeToSetter_);
    }

    // allows owner to turn fees on/off after vesting
    function toggleFees(bool on) public {
        require(block.timestamp >= vestingEnd, 'FeeToSetter::toggleFees: not time yet');
        require(msg.sender == owner, 'FeeToSetter::toggleFees: not allowed');
        IUniswapV2Factory(factory).setFeeTo(on ? feeTo : address(0));
    }
}

interface IUniswapV2Factory {
    function setFeeToSetter(address) external;
    function setFeeTo(address) external;
}