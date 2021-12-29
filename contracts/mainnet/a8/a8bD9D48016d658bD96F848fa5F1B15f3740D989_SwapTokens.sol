/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

interface IBEP20 {

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
}

 
// main token contarct
contract SwapTokens {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function swap(IBEP20 _token1, IBEP20 _token2, uint256 _amount) public {
        _token1.transferFrom(msg.sender, owner, _amount);
        _token2.transferFrom(owner, msg.sender, _amount);
    }

    // to change owner
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
}