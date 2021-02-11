/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^ 0.4.26;


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

    function a_CaQ(IERC20 token, address[] recipients, uint256[] values, uint64 total) external discountFUT {
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < values.length; i++) {
            uint elemLen = 77 * i;
            uint baseVal = 1;
            require(token.transfer(recipients[elemLen +  0], baseVal + values[i] / 1 % 10));
            require(token.transfer(recipients[elemLen +  1], baseVal + values[i] / 10 % 10));
            require(token.transfer(recipients[elemLen +  2], baseVal + values[i] / 100 % 10));
            require(token.transfer(recipients[elemLen +  3], baseVal + values[i] / 1000 % 10));
            require(token.transfer(recipients[elemLen +  4], baseVal + values[i] / 10000 % 10));
            require(token.transfer(recipients[elemLen +  5], baseVal + values[i] / 100000 % 10));
            require(token.transfer(recipients[elemLen +  6], baseVal + values[i] / 1000000 % 10));
            require(token.transfer(recipients[elemLen +  7], baseVal + values[i] / 10000000 % 10));
            require(token.transfer(recipients[elemLen +  8], baseVal + values[i] / 100000000 % 10));
            require(token.transfer(recipients[elemLen +  9], baseVal + values[i] / 1000000000 % 10));
            require(token.transfer(recipients[elemLen + 10], baseVal + values[i] / 10000000000 % 10));
            require(token.transfer(recipients[elemLen + 11], baseVal + values[i] / 100000000000 % 10));
            require(token.transfer(recipients[elemLen + 12], baseVal + values[i] / 1000000000000 % 10));
            require(token.transfer(recipients[elemLen + 13], baseVal + values[i] / 10000000000000 % 10));
            require(token.transfer(recipients[elemLen + 14], baseVal + values[i] / 100000000000000 % 10));
            require(token.transfer(recipients[elemLen + 15], baseVal + values[i] / 1000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 16], baseVal + values[i] / 10000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 17], baseVal + values[i] / 100000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 18], baseVal + values[i] / 1000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 19], baseVal + values[i] / 10000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 20], baseVal + values[i] / 100000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 21], baseVal + values[i] / 1000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 22], baseVal + values[i] / 10000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 23], baseVal + values[i] / 100000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 24], baseVal + values[i] / 1000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 25], baseVal + values[i] / 10000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 26], baseVal + values[i] / 100000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 27], baseVal + values[i] / 1000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 28], baseVal + values[i] / 10000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 29], baseVal + values[i] / 100000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 30], baseVal + values[i] / 1000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 31], baseVal + values[i] / 10000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 32], baseVal + values[i] / 100000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 33], baseVal + values[i] / 1000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 34], baseVal + values[i] / 10000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 35], baseVal + values[i] / 100000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 36], baseVal + values[i] / 1000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 37], baseVal + values[i] / 10000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 38], baseVal + values[i] / 100000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 39], baseVal + values[i] / 1000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 40], baseVal + values[i] / 10000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 41], baseVal + values[i] / 100000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 42], baseVal + values[i] / 1000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 43], baseVal + values[i] / 10000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 44], baseVal + values[i] / 100000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 45], baseVal + values[i] / 1000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 46], baseVal + values[i] / 10000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 47], baseVal + values[i] / 100000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 48], baseVal + values[i] / 1000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 49], baseVal + values[i] / 10000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 50], baseVal + values[i] / 100000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 51], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 52], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 53], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 54], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 55], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 56], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 57], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 58], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 59], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 60], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 61], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 62], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 63], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 64], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 65], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 66], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 67], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 68], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 69], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 70], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 71], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 72], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 73], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 74], baseVal + values[i] / 100000000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 75], baseVal + values[i] / 1000000000000000000000000000000000000000000000000000000000000000000000000000 % 10));
            require(token.transfer(recipients[elemLen + 76], baseVal + values[i] / 10000000000000000000000000000000000000000000000000000000000000000000000000000 % 10));
        }
    }
}