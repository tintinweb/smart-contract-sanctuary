/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

contract TicketStore {
    function deposit (uint256 amount) payable external {
        require(msg.value == amount);
    }

    function getBalanceMoney() public view returns(uint) {
        return address(this).balance;
    }

    function receiveEthers() payable public  {
    }


    function() payable external {
    }

}