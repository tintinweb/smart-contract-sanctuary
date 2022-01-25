//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./interfaces/IReflectionDistributor.sol";

contract NullReflectionDistributor is IReflectionDistributor {
    receive() external payable {
    }

    function setShare(address shareholder, uint256 amount) external override {
    }

    function process(uint256 gas) external override payable {
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IReflectionDistributor {
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external payable;
}