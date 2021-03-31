// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface Token{
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}
contract SCoinPrivateDistribution  is Ownable{
    
    using SafeMath for uint256;
    
    uint256 coreContributionTeam = 2000; // 20%, multiplication factor 100
    uint256 legalComplianceTeams = 500; // 5%, multiplication factor 100
    uint256 marketingTeams = 1000; // 10%, multiplication factor 100
    
    uint256 public internalDistributionLeftCounter = 1; // a total of 1 times 
    
    uint256 public totalTokenAmount;
    uint256 public decimalFactor;
    uint256 public teamCount=3;
    
    mapping(uint256=>address) public internalTokenReceiverAddresses;
    address[] tempArray;
    //0->coreContributionTeam
    //1=>legalComplianceTeams
    //2=>marketingTeams
    
    mapping(address=>uint256) public bondTokensHolded;
    
    address public tokenContractAddress=0x1dfed394649BdCF973554Db52fE903f9e5e534a2;
    
    constructor(){
        decimalFactor=10**Token(tokenContractAddress).decimals();
        totalTokenAmount=600000000*decimalFactor;
    }
    
    function updateTokenContractAddress(address _tokenAddress) external onlyOwner{
        tokenContractAddress=_tokenAddress;
    }
    
    function saveInternalDistributions() public onlyOwner{
        require(internalDistributionLeftCounter!=0, "All tokens distributed");
        require((getTeamMember(0)!=address(0)) ,"Please enter core team distribution address.");
        require((getTeamMember(1)!=address(0)) ,"Please enter legal and  compliance team distribution address.");
        require((getTeamMember(2)!=address(0)) ,"Please enter lmarketing team distribution address.");


        //core get amount to be distributed
        uint256 amountTobeDistributedForCoreTeam = (coreContributionTeam
                                        .mul(totalTokenAmount))
                                        .div(10**4);
                                        
        //core team amount distribution
        distributeTokens(0,amountTobeDistributedForCoreTeam);
        
        //legalAndComplianceTeam get amount to be distributed
         uint256 amountTobeDistributedForLegalComplianceTeam = (legalComplianceTeams
                                                    .mul(totalTokenAmount))
                                                    .div(10**4);
        //leganAndCompliance amount distribution
        distributeTokens(1,amountTobeDistributedForLegalComplianceTeam);
        
        //marketingTeam get amount to be distributed
         uint256 amountTobeDistributedForMarketingTeam =( marketingTeams
                                                        .mul(totalTokenAmount))
                                                         .div(10**4);
        // marketingTeam amount distribution
        distributeTokens(2,amountTobeDistributedForMarketingTeam);
        
        internalDistributionLeftCounter = internalDistributionLeftCounter.sub(1);
        releaseTokenByAdmin();
    }
    
    function releaseTokenByAdmin() internal{
        releaseTokenToParticularTeam(getTeamMember(0));
        releaseTokenToParticularTeam(getTeamMember(1));
        releaseTokenToParticularTeam(getTeamMember(2));
    }
    
     function releaseTokenToParticularTeam(address teamAddress) internal{
        Token obj = Token(tokenContractAddress);
        require(bondTokensHolded[teamAddress]>0,"No token given");
        obj.transfer(teamAddress,bondTokensHolded[teamAddress]);
        bondTokensHolded[teamAddress] = 0;
    }
    
    
    function distributeTokens(uint256 index, uint256 amount) internal{
         address distributionAddress = internalTokenReceiverAddresses[index];
         bondTokensHolded[distributionAddress]=amount;
    }


    function addUpdateTeamMember(uint index,address memberAddress) public onlyOwner{
        require(index<teamCount,'Invalid index.');
        require(memberAddress!=address(0),'Invalid address.');
        internalTokenReceiverAddresses[index]=memberAddress;
    }
    
    function getTeamMember(uint index) public  view  returns(address){
        require(index<teamCount,'Invalid index.');
        return internalTokenReceiverAddresses[index];
    }
    
    function removeTeamMember(uint index) public onlyOwner{
        require(index<teamCount,'Invalid index.');
        delete internalTokenReceiverAddresses[index];
    }
    
    function getAllTeamMembers() public  returns(address[] memory){
        tempArray=new address[](0);
        for(uint i=0;i<teamCount;i++){
            tempArray.push(internalTokenReceiverAddresses[i]);
        }
        return tempArray;
    }
}