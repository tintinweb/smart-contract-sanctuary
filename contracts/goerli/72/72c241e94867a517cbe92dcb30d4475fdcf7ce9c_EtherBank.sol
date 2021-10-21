/**
 *Submitted for verification at Etherscan.io on 2021-10-20
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