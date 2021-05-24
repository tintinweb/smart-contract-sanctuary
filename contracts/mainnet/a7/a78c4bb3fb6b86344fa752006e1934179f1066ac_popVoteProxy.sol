/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

interface IVoteProxy {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _voter) external view returns (uint256);
}

contract popVoteProxy {
    IVoteProxy public voteProxy;
    address public governance;

    constructor() public {
        governance = msg.sender;
    }

    function name() external pure returns (string memory) {
        return "POP Vote Power";
    }

    function symbol() external pure returns (string memory) {
        return "POP VP";
    }

    function decimals() external view returns (uint8) {
        return voteProxy.decimals();
    }

    function totalSupply() external view returns (uint256) {
        return voteProxy.totalSupply();
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return voteProxy.balanceOf(_voter);
    }

    function setVoteProxy(IVoteProxy _voteProxy) external {
        require(msg.sender == governance, "!governance");
        voteProxy = _voteProxy;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
}