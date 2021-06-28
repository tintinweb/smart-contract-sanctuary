/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

contract LuckyFlokiLottery {
    address private _owner;

    event Payout(address target, uint amount);

    constructor (address addr) public {
        _owner = addr;
    }
}