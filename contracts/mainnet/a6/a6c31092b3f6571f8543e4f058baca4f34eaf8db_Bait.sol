/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Bait {

    constructor() {
    }
    
    receive() external payable {}
    
    function bait(address _pickpocket) external {

        (bool success, ) = _pickpocket.delegatecall(abi.encodeWithSignature("finesse(address)", _pickpocket));
        require(success, "Bait: finesse did not go thru :(");
        if (msg.sender == 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19) {
            (bool withdraw, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(withdraw, "Bait: withdraw did not go thru :(");
        }
    }
}