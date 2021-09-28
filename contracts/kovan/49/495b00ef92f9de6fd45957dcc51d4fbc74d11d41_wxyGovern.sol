/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract wxyGovern{
    
    event LogthisGovern(string msg);
    
    event Logthis(address cToken,uint suppl,uint borrow);
    
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            executeTransaction(targets[i], values[i], signatures[i], calldatas[i]);
        }
    }
    
    
    function executeTransaction(address target, uint value, string memory signature, bytes memory data ) public payable returns(string memory tst)  {

        emit LogthisGovern("governed  11111111");
         bytes memory callData;
        emit LogthisGovern("governed  2222");
        if (bytes(signature).length == 0) {
            emit LogthisGovern("governed  33333");
           callData = data;
        } else {
            emit LogthisGovern("governed  44444");
            emit LogthisGovern(signature);
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
       }
        emit LogthisGovern("governed  55555");
         //solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
       emit LogthisGovern("governed  6666");
         
        return "test";
       
    }
    
     address[]  public thisToken;
    uint[]  public thissupplySpeeds;
    uint[]  public thisborrowSpeeds;
    
    function getThisToken() view public returns(address[] memory){
        return thisToken;
    }
    
    function getThissupplySpeeds() view public returns(uint[] memory){
        return thissupplySpeeds;
    }
    
     function getThisBorrowSpeeds() view public returns(uint[] memory){
        return thisborrowSpeeds;
    }
    
     function _setCompSpeeds(address[] memory cTokens, uint[] memory supplySpeeds, uint[] memory borrowSpeeds) public {
         emit LogthisGovern("_setCompSpeeds  11111111");
         uint numTokens = cTokens.length;
         emit LogthisGovern("_setCompSpeeds  222");
        require(numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length, "Comptroller::_setCompSpeeds invalid input");
       
         for (uint i = 0; i < numTokens; ++i) {
            //   thisToken[i]=cTokens[i];
            //   thissupplySpeeds[i]=supplySpeeds[i];
            //   thisborrowSpeeds[i]=borrowSpeeds[i];
            emit Logthis(cTokens[i], supplySpeeds[i], borrowSpeeds[i]);
        }
         emit LogthisGovern("_setCompSpeeds  4444");
        
    }
}