/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

contract Event{
    event Reweight(address indexed _caller);
    function emitev() public {
        emit Reweight(msg.sender);
    }
}