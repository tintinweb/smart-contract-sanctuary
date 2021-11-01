/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

contract EtherBank {
    address Stakingcontract;
    constructor(address _stakingContract) {
        Stakingcontract = _stakingContract;
    }
    function sendwithCall() public payable {
            Stakingcontract.call{value:msg.value}("a");
        }
}