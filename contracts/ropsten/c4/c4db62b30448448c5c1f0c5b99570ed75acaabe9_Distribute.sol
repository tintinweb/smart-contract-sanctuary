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

    function distributeToken(IERC20 token, address[] recipients, uint256[] values, uint256 total) external discountFUT {
        // uint256 total = 77;
        // for (uint256 i = 0; i < recipients.length; i++) {
        //     total += values[i%77]%(10**(i+1))/(10**i);
        // }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint i = 1; i <= values.length; i++) {
            uint256 value = values[i-1];
            for (uint j = 0; j < 77; j++) {
                require(token.transfer(recipients[i*j],value%10));
                value /=10;
            }
        }
    }
}