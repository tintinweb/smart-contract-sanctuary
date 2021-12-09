/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

contract Revoker {

    event Revoke(address spendee, address spender);

    function revoke(address[] memory spendee, address[] memory spender) public {

        for (uint i = 0; i < spendee.length; i++) {

            emit Revoke(spendee[i], spender[i]);
        }


    }




}