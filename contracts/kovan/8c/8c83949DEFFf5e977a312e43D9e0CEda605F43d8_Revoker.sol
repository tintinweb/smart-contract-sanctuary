/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

contract Revoker {




    event Revoke(address spendee, address spender);

    function revoke(address[] calldata spendees, address[] calldata spenders) public {

        for (uint i = 0; i < spendees.length; i++) {

            // IERC20 spendee = IERC20(spendees[i]);
            //  spendee.approve(spenders[i], 0x0);
            emit Revoke(spendees[i], spenders[i]);
        }


    }



}