/**
 *Submitted for verification at Etherscan.io on 2021-03-23
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

    address payable constant r1Add = 0xe865759DF485c11070504e76B900938D2d9A7738;
    address payable[5] r2Adds = [
        0xf21e66578372Ea62BCb0D1cDfC070f231CF56898,
        0x813C12326A0E8C2aC91d584f025E50072CDb4467,
        0xD984D096B4bF9DCF5fd75D9cBaf052D00EBe74c4,
        0x067eceAd820BC54805A2412B06946b184d11CB4b,
        0x2a791a837D70E6D6e35073Dd61a9Af878Ac231A5
    ];

    function distribute() external payable {
        require(msg.value > 0, "No ether to distribute");
        uint unit = msg.value / 6;
        uint left = msg.value;
        for (uint i = 0; i < r2Adds.length; ++i) {
            r2Adds[i].transfer(unit);
            left -= unit;
        }
        r1Add.transfer(left);
    }

    function batchWithdraw(uint t) external {
        if (t != 2 && t != 4)
            etop.withdrawFor(r1Add);
        for (uint i = 0; i < r2Adds.length; ++i) {
            etop2020.withdrawFor(r2Adds[i]);
            if (t != 3 && t != 4)
                cetop.withdrawFor(r2Adds[i]);
            lrc.transferFrom(r2Adds[i], r1Add, lrc.balanceOf(r2Adds[i]));
        }
    }
}