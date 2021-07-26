/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity ^0.4.11;

contract Burner {
    uint256 public totalBurned;

    function Purge() public {
        // the caller of purge action receives 0.01% out of the
        // current balance.
        msg.sender.transfer(this.balance / 1000);
        assembly {
            mstore(0, 0x30ff)
            // transfer all funds to a new contract that will selfdestruct
            // and destroy all ether in the process.
            create(balance(address), 30, 2)
            pop
        }
    }

    function Burn() payable {
        totalBurned += msg.value;
    }
}