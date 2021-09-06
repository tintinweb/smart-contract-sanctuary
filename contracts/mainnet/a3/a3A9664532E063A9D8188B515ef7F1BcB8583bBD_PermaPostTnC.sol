/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.5.16;

contract PermaPostTnC {

    string public constant termsAndConditions = "Our content is public and available for all to see. Your post will create a transaction on the blockchain and its content will be stored inside the transaction’s data. Your post is permanent and cannot be removed or modified. Unless you make yourself publicly known by stating your name on the post, no additional information will be stored in terms of your identity. You should know that, ultimately, there may be ways to track the wallet address back to you, although this is very difficult and there are no easy ways to perform this action. The fact that you accepted these terms will be stored as your first post on the blockchain, as proof that we made you aware of the risks. The developers of Permapost reserve the right to deploy future versions of the platform that hides your content from the public eye. We resist this move ideologically but may face legal or other pressure that forces our hand.";
    
    event Accepted(address indexed signee);
    
    mapping (address => bool) public acceptedTnCs;
    
    function acceptTermsAndConditions() 
        external 
        {
            acceptedTnCs[msg.sender] = true;
            emit Accepted(msg.sender);
        }
}