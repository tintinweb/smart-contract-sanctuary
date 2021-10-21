/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

contract test {
    address nop;
    receive() external payable {
        require(msg.sender != nop);
    }
    function defineNop(address _nop) public {
        nop = _nop;
    }
}