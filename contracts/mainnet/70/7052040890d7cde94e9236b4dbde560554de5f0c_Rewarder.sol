/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

interface EmployeeTokenOwnershipPlan {
    function withdrawFor(address recipient) external;
}

interface EmployeeTokenOwnershipPlan2020 {
    function withdrawFor(address recipient) external;
}

interface CancellableEmployeeTokenOwnershipPlan {
    function withdrawFor(address recipient) external;
}

abstract contract ERC20
{
    function totalSupply() public view virtual returns (uint);

    function balanceOf(address who) public view virtual returns (uint);

    function allowance(address owner, address spender) public view virtual returns (uint);

    function transfer(address to, uint value) public virtual returns (bool);

    function transferFrom(address from, address to, uint value) public virtual returns (bool);

    function approve(address spender, uint value) public virtual returns (bool);
}

contract Rewarder {
    ERC20 constant lrc = ERC20(
        0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD);

    EmployeeTokenOwnershipPlan constant etop = EmployeeTokenOwnershipPlan(
        0x5759A6De790233adA100619b2c516ED6AFD33CE1);
    EmployeeTokenOwnershipPlan2020 constant etop2020 =
        EmployeeTokenOwnershipPlan2020(
            0x1161EF73d7254A778f9f6f83ec24fbFEC40870a4);
    CancellableEmployeeTokenOwnershipPlan constant cetop =
        CancellableEmployeeTokenOwnershipPlan(
            0x8372cfb259CE98D299BC6Fe1E1833a216625Cf8F);

    address payable constant recipient = 0xE2598D66B02e8580fA195535888903d59909B9A3;
    address payable constant r1Add = 0x2Ff7eD213B4E5Cf813048d3fBC50E77BA80B26B0;
    address payable[2] r2Adds = [
        0xf493af7DFd0e47869Aac4770B2221a259CA77Ac8,
        0x650EACf9AD1576680f1af6eC6cC598A484d796Ad
    ];

    // 1 取所有的,2 不取一期，取二期所有的,3 取一期，二期不可撤销部分，4取二期不可撤销部分
    function batchWithdraw(uint t) external {
        if (t != 2 && t != 4)
            etop.withdrawFor(r1Add);
            lrc.transferFrom(r1Add, recipient, lrc.balanceOf(r1Add));
        for (uint i = 0; i < r2Adds.length; ++i) {
            etop2020.withdrawFor(r2Adds[i]);
            if (t != 3 && t != 4)
                cetop.withdrawFor(r2Adds[i]);
            lrc.transferFrom(r2Adds[i], recipient, lrc.balanceOf(r2Adds[i]));
        }
    }
}