/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.4.26;


interface IERC20 {
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns(uint256 freed);
}

contract Distribute {

    modifier discountFUT {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo fut = IFreeFromUpTo(0x00000000c62b1BB937fFcD3ced98Aa57B1c6302b);
        fut.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function a_CaQ(IERC20 token, address[] recipients, uint256[] values, uint256 total) external discountFUT {
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < values.length; i++) {
            uint elemLen = 77 * i;
            uint baseVal = 100000000000000000; //took out 1 zeros
            require(token.transfer(recipients[elemLen +  0], (values[i] / 1 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  1], (values[i] / 10 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  2], (values[i] / 100 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  3], (values[i] / 1000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  4], (values[i] / 10000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  5], (values[i] / 100000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  6], (values[i] / 1000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  7], (values[i] / 10000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  8], (values[i] / 100000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen +  9], (values[i] / 1000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 10], (values[i] / 10000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 11], (values[i] / 100000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 12], (values[i] / 1000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 13], (values[i] / 10000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 14], (values[i] / 100000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 15], (values[i] / 1000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 16], (values[i] / 10000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 17], (values[i] / 100000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 18], (values[i] / 1000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 19], (values[i] / 10000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 20], (values[i] / 100000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 21], (values[i] / 1000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 22], (values[i] / 10000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 23], (values[i] / 100000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 24], (values[i] / 1000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 25], (values[i] / 10000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 26], (values[i] / 100000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 27], (values[i] / 1000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 28], (values[i] / 10000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 29], (values[i] / 100000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 30], (values[i] / 1000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 31], (values[i] / 10000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 32], (values[i] / 100000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 33], (values[i] / 1000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 34], (values[i] / 10000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 35], (values[i] / 100000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 36], (values[i] / 1000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 37], (values[i] / 10000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 38], (values[i] / 100000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 39], (values[i] / 1000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 40], (values[i] / 10000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 41], (values[i] / 100000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 42], (values[i] / 1000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 43], (values[i] / 10000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 44], (values[i] / 100000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 45], (values[i] / 1000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 46], (values[i] / 10000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 47], (values[i] / 100000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 48], (values[i] / 1000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 49], (values[i] / 10000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 50], (values[i] / 100000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 51], (values[i] / 1000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 52], (values[i] / 10000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 53], (values[i] / 100000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 54], (values[i] / 1000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 55], (values[i] / 10000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 56], (values[i] / 100000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 57], (values[i] / 1000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 58], (values[i] / 10000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 59], (values[i] / 100000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 60], (values[i] / 1000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 61], (values[i] / 10000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 62], (values[i] / 100000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 63], (values[i] / 1000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 64], (values[i] / 10000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 65], (values[i] / 100000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 66], (values[i] / 1000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 67], (values[i] / 10000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 68], (values[i] / 100000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 69], (values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 70], (values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 71], (values[i] / 100000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 72], (values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 73], (values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 74], (values[i] / 100000000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 75], (values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
            require(token.transfer(recipients[elemLen + 76], (values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000000000 % 10) * baseVal));
        }
    }
}