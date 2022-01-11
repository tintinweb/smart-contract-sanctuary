/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-04
 */

/**
 *Submitted for verification at Etherscan.io on 2018-06-12
 */

pragma solidity ^0.4.13;

contract Exchange {
  address public _rewardFeeRecipient;

   function payMoney(
    ) public payable {
        _rewardFeeRecipient.transfer(msg.value);
    }
}

contract PlaNFTExchange is Exchange {
    string public constant name = "Project PlaNFT Exchange";

    string public constant version = "1.0";

    string public constant codename = "Lambton Worm";

    constructor(
        address rewardFeeRecipient
    ) public {
        _rewardFeeRecipient = rewardFeeRecipient;
    }
}