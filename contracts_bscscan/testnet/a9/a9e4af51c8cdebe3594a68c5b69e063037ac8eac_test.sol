/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.8.7;

contract test {

        uint256 EntropyStartTs;

        constructor(){
            EntropyStartTs = block.timestamp;
        }
       function EntropyTsToEnd(uint256 Ratio, uint256 NESplitAllValue) public view returns (uint256) {
        uint256 nowtime = block.timestamp;
        uint256 _ratio = Ratio/10**6;
        uint256 addBNBtotal = NESplitAllValue / _ratio;
                addBNBtotal = addBNBtotal / 10**18;
        uint256 dealine = (6 * 60 * 60) + (addBNBtotal * 600);
        uint256 timeFromStart = nowtime - EntropyStartTs;
        return (dealine > timeFromStart ? dealine - timeFromStart : 0);
    }
}