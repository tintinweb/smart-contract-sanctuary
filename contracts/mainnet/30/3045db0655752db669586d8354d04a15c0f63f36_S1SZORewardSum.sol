/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

pragma solidity 0.5.17;

contract Permissions {

  address public permits;

  constructor() public {
    permits = msg.sender;
  }

  
  modifier onlyPermits(){
    require(msg.sender == permits);
    _;
  }

}



 
contract SZOReward{
      function getReward(address _contract,address _wallet) public view returns(uint256);
      
}
 
 
 contract S1SZORewardSum is Permissions{
     uint256 public version = 1;
     mapping(address=>bool) disPools;
     address[] public allowPools;
     
     SZOReward szoReward;
     
     // All are Goerli
     constructor() public{
        allowPools.push(0xE29659A35260B87264eBf1155dD03B7DE17d9B26); // Pool Dai
        allowPools.push(0x1C69D1829A5970d85bCe8dD4A4f7f568DB492c81); // Pool USDT
        allowPools.push(0x93347FFA6020a3904790220E84f38594F35bac7D); // Pool USDC
        
        szoReward = SZOReward(0xceC492583F9C8A382502C5b9feE5DB777810a89a);
     }
     
     function setSZOReward(address _addr) public onlyPermits{
          szoReward = SZOReward(_addr);
     }
     
     function summarySZOReward(address _addr) public view returns(uint256 sumBalance,uint256[] memory _pool){
         _pool = new uint256[](allowPools.length);
         
         for(uint256 i=0;i<allowPools.length;i++){
             if(disPools[allowPools[i]] == false){
                 _pool[i] = szoReward.getReward(allowPools[i],_addr);
                 sumBalance += _pool[i];
             }
         }
     }
     
   
     
 }