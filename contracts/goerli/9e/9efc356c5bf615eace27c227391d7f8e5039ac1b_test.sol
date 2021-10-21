/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

contract test {
    receive() external payable {
        require(msg.sender != 0x75CBee70523521eF7dB8704b4e9031612e434941);
    }
}