/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
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
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }
}