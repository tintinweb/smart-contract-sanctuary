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
        uint256[] memory decompressedValues = new uint256[] (recipients.length);
        for (uint256 i = 0; i < values.length; i++) {
            decompressedValues[4*i+0] = (values[i]) % 10000000000000000000;
            decompressedValues[4*i+1] = (values[i]-decompressedValues[4*i+0]) / 10000000000000000000 % 10000000000000000000;
            decompressedValues[4*i+2] = (values[i]-decompressedValues[4*i+0]-decompressedValues[4*i+1]*10000000000000000000) / 100000000000000000000000000000000000000 % 10000000000000000000;
            decompressedValues[4*i+3] = (values[i]-decompressedValues[4*i+0]-decompressedValues[4*i+1]*10000000000000000000-decompressedValues[4*i+2]*100000000000000000000000000000000000000) / 1000000000000000000000000000000000000000000000000000000000 % 10000000000000000000;
            total += decompressedValues[4*i+0] + decompressedValues[4*i+1] + decompressedValues[4*i+2] + decompressedValues[4*i+3];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], decompressedValues[i]));
    }
}