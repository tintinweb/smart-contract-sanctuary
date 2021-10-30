// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Auth.sol";

contract DevPool is Auth {

    constructor(address _owner_) Auth(_owner_) {}

    function deposit() external payable {}

    function transfer(address _to_, uint256 _bnb_) external onlyAuthorized {
        require(_bnb_ <= address(this).balance, 'INSUFFICIENT_AMOUNT');
        payable(_to_).transfer(_bnb_);
    }
}