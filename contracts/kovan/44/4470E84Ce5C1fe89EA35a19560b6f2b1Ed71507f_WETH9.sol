/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

//                 .                                            .
//      *   .                  .              .        .   *          .
//   .         .                     .       .           .      .        .
//         o                             .                   .
//          .              .                  .           .
//           0     .
//                  .          .                 ,                ,    ,
//  .          \          .                         .
//       .      \   ,
//    .          o     .                 .                   .            .
//      .         \                 ,             .                .
//                #\##\#      .                              .        .
//              #  #O##\###                .                        .
//    .        #*#  #\##\###                       .                     ,
//         .   ##*#  #\##\##               .                     .
//       .      ##*#  #o##\#         .                             ,       .
//           .     *#  #\#     .                    .             .          ,
//                       \          .                         .
// ____^/\___^--____/\____O______________/\/\---/\___________---______________
//    /\^   ^  ^    ^                  ^^ ^  '\ ^          ^       ---
//          --           -            --  -      -         ---  __       ^
//    --  __                      ___--  ^  ^                         --  __
//
// The largest leveraged tokens market protocol.
//
// website: https://risedle.com
// twitter: @risedle
// github: risedle

// Verified using https://dapp.tools

// hevm: flattened sources of src/tokens/WETH9.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

////// src/tokens/WETH9.sol

// Risedle WETH9 Implementation
// The deployer will get 1_000_000 WETH by default
// The initial minted token will be used as initial liquidity on uniswap
// This is only used for testing or on testnet
/* pragma solidity >=0.6.0; */

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 internal totalMinted = 0;

    constructor() {
        // Set the deployer balance to 1_000_000 WETH
        balanceOf[msg.sender] = 1_000_000 ether;
        totalMinted += 1_000_000 ether;
        emit Transfer(address(this), msg.sender, 1_000_000 ether);
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        totalMinted += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        totalMinted -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    // used for overflow testing
    function testSetBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}