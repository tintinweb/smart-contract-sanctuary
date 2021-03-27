/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.8.3;


interface IERC20 {
    function award(uint256  id,address recipient,uint256 amount,bytes32[] memory proof)external;
}


contract RewardXDeFi{
    
    function claimAll(uint256 id,IERC20 token, address[] calldata recipients, uint256[] calldata _amounts, bytes32[][] memory  proofs) external{
        for (uint256 i = 0;i < recipients.length ; i++){
            token.award(id,recipients[i],_amounts[i],proofs[i]);
        }
    }
    
}