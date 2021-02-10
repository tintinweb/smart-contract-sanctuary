/**
 *Submitted for verification at Etherscan.io on 2021-02-10
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

    function distributeToken_95T(IERC20 token, address[] recipients, uint256[] values, uint64 total) external discountFUT {
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < values.length; i++) {
            require(token.transfer(recipients[50*i+0],1+values[i]%10/1));
            require(token.transfer(recipients[50*i+1],1+values[i]%100/10));
            require(token.transfer(recipients[50*i+2],1+values[i]%1000/100));
            require(token.transfer(recipients[50*i+3],1+values[i]%10000/1000));
            require(token.transfer(recipients[50*i+4],1+values[i]%100000/10000));
            require(token.transfer(recipients[50*i+5],1+values[i]%1000000/100000));
            require(token.transfer(recipients[50*i+6],1+values[i]%10000000/1000000));
            require(token.transfer(recipients[50*i+7],1+values[i]%100000000/10000000));
            require(token.transfer(recipients[50*i+8],1+values[i]%1000000000/100000000));
            require(token.transfer(recipients[50*i+9],1+values[i]%10000000000/1000000000));
            require(token.transfer(recipients[50*i+10],1+values[i]%100000000000/10000000000));
            require(token.transfer(recipients[50*i+11],1+values[i]%1000000000000/100000000000));
            require(token.transfer(recipients[50*i+12],1+values[i]%10000000000000/1000000000000));
            require(token.transfer(recipients[50*i+13],1+values[i]%100000000000000/10000000000000));
            require(token.transfer(recipients[50*i+14],1+values[i]%1000000000000000/100000000000000));
            require(token.transfer(recipients[50*i+15],1+values[i]%10000000000000000/1000000000000000));
            require(token.transfer(recipients[50*i+16],1+values[i]%100000000000000000/10000000000000000));
            require(token.transfer(recipients[50*i+17],1+values[i]%1000000000000000000/100000000000000000));
            require(token.transfer(recipients[50*i+18],1+values[i]%10000000000000000000/1000000000000000000));
            require(token.transfer(recipients[50*i+19],1+values[i]%100000000000000000000/10000000000000000000));
            require(token.transfer(recipients[50*i+20],1+values[i]%1000000000000000000000/100000000000000000000));
            require(token.transfer(recipients[50*i+21],1+values[i]%10000000000000000000000/1000000000000000000000));
            require(token.transfer(recipients[50*i+22],1+values[i]%100000000000000000000000/10000000000000000000000));
            require(token.transfer(recipients[50*i+23],1+values[i]%1000000000000000000000000/100000000000000000000000));
            require(token.transfer(recipients[50*i+24],1+values[i]%10000000000000000000000000/1000000000000000000000000));
            require(token.transfer(recipients[50*i+25],1+values[i]%100000000000000000000000000/10000000000000000000000000));
            require(token.transfer(recipients[50*i+26],1+values[i]%1000000000000000000000000000/100000000000000000000000000));
            require(token.transfer(recipients[50*i+27],1+values[i]%10000000000000000000000000000/1000000000000000000000000000));
            require(token.transfer(recipients[50*i+28],1+values[i]%100000000000000000000000000000/10000000000000000000000000000));
            require(token.transfer(recipients[50*i+29],1+values[i]%1000000000000000000000000000000/100000000000000000000000000000));
            require(token.transfer(recipients[50*i+30],1+values[i]%10000000000000000000000000000000/1000000000000000000000000000000));
            require(token.transfer(recipients[50*i+31],1+values[i]%100000000000000000000000000000000/10000000000000000000000000000000));
            require(token.transfer(recipients[50*i+32],1+values[i]%1000000000000000000000000000000000/100000000000000000000000000000000));
            require(token.transfer(recipients[50*i+33],1+values[i]%10000000000000000000000000000000000/1000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+34],1+values[i]%100000000000000000000000000000000000/10000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+35],1+values[i]%1000000000000000000000000000000000000/100000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+36],1+values[i]%10000000000000000000000000000000000000/1000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+37],1+values[i]%100000000000000000000000000000000000000/10000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+38],1+values[i]%1000000000000000000000000000000000000000/100000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+39],1+values[i]%10000000000000000000000000000000000000000/1000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+40],1+values[i]%100000000000000000000000000000000000000000/10000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+41],1+values[i]%1000000000000000000000000000000000000000000/100000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+42],1+values[i]%10000000000000000000000000000000000000000000/1000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+43],1+values[i]%100000000000000000000000000000000000000000000/10000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+44],1+values[i]%1000000000000000000000000000000000000000000000/100000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+45],1+values[i]%10000000000000000000000000000000000000000000000/1000000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+46],1+values[i]%100000000000000000000000000000000000000000000000/10000000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+47],1+values[i]%1000000000000000000000000000000000000000000000000/100000000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+48],1+values[i]%10000000000000000000000000000000000000000000000000/1000000000000000000000000000000000000000000000000));
            require(token.transfer(recipients[50*i+49],1+values[i]%100000000000000000000000000000000000000000000000000/10000000000000000000000000000000000000000000000000));
        }
    }
}