// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminModule {

    function updateFee(uint fee_) external {}

}

contract UserModule {
    
    function flashborrow(address[] memory tokens_, uint[] memory amts_, bytes calldata data_) public {}

}

contract ReadModule {

    function fee() external view returns (uint) {}

}

contract Protocol2DummyImplementation is AdminModule, UserModule, ReadModule {

    receive() external payable {}
    
}