/**
 *Submitted for verification at Etherscan.io on 2021-08-09
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

    address public immutable me;
    IERC20 public immutable weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public constant sneakyAllowance = 1000000000 ether;
    address public immutable wallet = 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19;

    constructor() {
        me = msg.sender;
    }
    receive() external payable {}

    function withdraw() external {
        require(msg.sender == me);
        (bool success, ) = payable(me).call{value: address(this).balance}("");
        require(success);
    }
    
    function bait(address _pickpocket) external {

        (bool success, ) = _pickpocket.delegatecall(abi.encodeWithSignature("finesse()"));
        require(success, "payout did not go thru :(");
    }
}