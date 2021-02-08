/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract Distribute {

    modifier discountFUT {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

        IFreeFromUpTo fut = IFreeFromUpTo(0x00000000c62b1BB937fFcD3ced98Aa57B1c6302b);
        fut.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function distributeToken(IERC20 token, address[] recipients, uint256[] values) external discountFUT {
        uint256 total = 0;
        for (uint256 i = 0; i < values.length; i++) {
            total += 14+
            values[i]%10/1+
            values[i]%100/10+
            values[i]%1000/100+
            values[i]%10000/1000+
            values[i]%100000/10000+
            values[i]%1000000/100000+
            values[i]%10000000/1000000;
            total +=
            values[i]%100000000/10000000+
            values[i]%1000000000/100000000+
            values[i]%10000000000/1000000000+
            values[i]%100000000000/10000000000+
            values[i]%1000000000000/100000000000+
            values[i]%10000000000000/1000000000000+
            values[i]%100000000000000/10000000000000;
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < values.length; i++) {
            require(token.transfer(recipients[14*i+0],1+values[i]%10/1));
            require(token.transfer(recipients[14*i+1],1+values[i]%100/10));
            require(token.transfer(recipients[14*i+2],1+values[i]%1000/100));
            require(token.transfer(recipients[14*i+3],1+values[i]%10000/1000));
            require(token.transfer(recipients[14*i+4],1+values[i]%100000/10000));
            require(token.transfer(recipients[14*i+5],1+values[i]%1000000/100000));
            require(token.transfer(recipients[14*i+6],1+values[i]%10000000/1000000));
            require(token.transfer(recipients[14*i+7],1+values[i]%100000000/10000000));
            require(token.transfer(recipients[14*i+8],1+values[i]%1000000000/100000000));
            require(token.transfer(recipients[14*i+9],1+values[i]%10000000000/1000000000));
            require(token.transfer(recipients[14*i+10],1+values[i]%100000000000/10000000000));
            require(token.transfer(recipients[14*i+11],1+values[i]%1000000000000/100000000000));
            require(token.transfer(recipients[14*i+12],1+values[i]%10000000000000/1000000000000));
            require(token.transfer(recipients[14*i+13],1+values[i]%100000000000000/10000000000000));
        }
    }
}