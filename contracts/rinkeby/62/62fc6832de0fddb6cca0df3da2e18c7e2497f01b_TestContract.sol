/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity 0.8.6;

interface IRealitio {
  function isFinalized(bytes32 question_id) external view returns (bool);
  function getFinalAnswer(bytes32 question_id) external view returns (bytes32);    
}

interface IConditionalTokens {
  function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
}

contract TestContract {
   address private realityContractAddress = 0x3D00D77ee771405628a4bA4913175EcC095538da;
   address private conditionalTokenAddress = 0x36bede640D19981A82090519bC1626249984c908;
   
   bytes32 resolvedToYes = 0x0000000000000000000000000000000000000000000000000000000000000001;
   bytes32 resolvedToNo = 0x0000000000000000000000000000000000000000000000000000000000000000;
   bytes32 resolvedToInvalid = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

   function getGnonisAnswerForRealityFinalAnswer(bytes32 final_answer) view internal returns (uint256 [] memory){
        if(final_answer==resolvedToInvalid){
            uint256[] memory noData = new uint256[](0);
            return noData;
        }
        
        uint256[] memory dataToBeReturned = new uint256[](2);
        if(final_answer==resolvedToYes){
            dataToBeReturned[0] = 1;
            dataToBeReturned[1] = 0;
            return dataToBeReturned;
        }
        
        if(final_answer==resolvedToNo){
            dataToBeReturned[0] = 0;
            dataToBeReturned[1] = 1;
            return dataToBeReturned;
        }
   }
   
   function resolveMarket(bytes32 question_id) external{
       bool isFinalized = IRealitio(realityContractAddress).isFinalized(question_id);
       if(isFinalized==true){
          bytes32 final_answer = IRealitio(realityContractAddress).getFinalAnswer(question_id); 
          uint256[] memory resolutionResult = new uint256[](2);
          resolutionResult = getGnonisAnswerForRealityFinalAnswer(final_answer);

          if(resolutionResult.length > 0){
            IConditionalTokens(conditionalTokenAddress).reportPayouts(question_id, resolutionResult);
          }

       }
        
   }
   
}