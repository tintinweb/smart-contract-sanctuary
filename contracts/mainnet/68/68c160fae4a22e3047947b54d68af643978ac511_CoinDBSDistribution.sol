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
contract CoinDBSDistribution  is Ownable{
    
    using SafeMath for uint256;
    
    uint256 internalTeamContribution = 2000; // 20%, multiplication factor 100
    uint256 internalSoftwareDevTeams = 2000; // 20%, multiplication factor 100
    uint256 bugBountyTeam = 1000; // 10%, multiplication factor 100
    uint256 advisoryBoard = 2000; // 20%, multiplication factor 100
    uint256 marketingAndSales = 3000; // 30%, multiplication factor 100
    
    uint256 public internalDistributionLeftCounter = 4; // a total of 4 times 
    uint256 periodicInternalDistributonDays = 90 days; // quaterly
    uint256 public lastTimeStampOfAttempt; //when last time tokens were distributed
    
    uint256 totalTokenAmount;
    uint256 decimalFactor;
    
    mapping(uint256=>address[]) public internalTokenReceiverAddresses;
    address[] tempArray;
    //0->internalTeamContribution
    //1=>internalSoftwareDevTeams
    //2=>bugBountyTeam
    //3=>advisoryBoard
    //4=>marketingAndSales
    mapping(address=>uint256) public bondTokensHolded;
    
    address public tokenContractAddress=0x0666BC06Fc0c4a1eFc27557E7effC7bd91a1E671;
    
    constructor(){
        decimalFactor=10**Token(tokenContractAddress).decimals();
        totalTokenAmount=5000000*decimalFactor;
    }
    
    function saveInternalDistributions() public onlyOwner{
        require(block.timestamp.sub(lastTimeStampOfAttempt) > periodicInternalDistributonDays, "Please wait for 90 days to complete");
        require(internalDistributionLeftCounter!=0, "All tokens distributed");
        require((getInternalTeamContributionAddress().length>0 && getInternalTeamContributionAddress()[0]!=address(0)) ,"Please enter internal team distribution address all the arrays");
        require((getInternalSoftwareDevTeamsAddress().length>0 && getInternalSoftwareDevTeamsAddress()[0]!=address(0)),"Please enter software development team distribution address all the arrays");
        require((getBugBountyTeamAddress().length>0 && getBugBountyTeamAddress()[0]!=address(0)),"Please enter Bug bounty team distribution address all the arrays");
        require((getAdvisoryBoardAddress().length>0 && getAdvisoryBoardAddress()[0]!=address(0)),"Please enter advisory board distribution address all the arrays");
        require((getMarketingAndSalesAddress().length>0 && getMarketingAndSalesAddress()[0]!=address(0)),"Please enter marketing and sales distribution address all the arrays");
        
        //internal team distribution
        uint256 amountTobeDistributed = (internalTeamContribution
                                        .mul(totalTokenAmount))
                                        .div(10**4*4);
        //get internal team distribution address
        distributeTokens(0,amountTobeDistributed);
        
        //internalSoftwareDevTeams distribution
         uint256 amountTobeDistributedForDevTeam = (internalSoftwareDevTeams
                                                    .mul(totalTokenAmount))
                                                    .div(10**4*4);
        //get internalSoftwareDevTeams address
        distributeTokens(1,amountTobeDistributedForDevTeam);
        
        //bugBountyTeam distribution
         uint256 amountTobeDistributedForbugBountyTeam =( bugBountyTeam
                                                        .mul(totalTokenAmount))
                                                         .div(10**4*4);
        //get bugBountyTeam address
        distributeTokens(2,amountTobeDistributedForbugBountyTeam);
        
        //advisoryBoard distribution
         uint256 amountTobeDistributedForadvisoryBoardTeam = (advisoryBoard
                                                            .mul(totalTokenAmount))
                                                            .div(10**4*4);
        //get advisoryBoard address
        distributeTokens(3,amountTobeDistributedForadvisoryBoardTeam);
        
        //marketingAndSales distribution
         uint256 amountTobeDistributedFormarketingAndSalesTeam =( marketingAndSales
                                                                .mul(totalTokenAmount))
                                                                .div(10**4*4);
        //get marketingAndSales address
        distributeTokens(4,amountTobeDistributedFormarketingAndSalesTeam);
        
        internalDistributionLeftCounter = internalDistributionLeftCounter.sub(1);
        lastTimeStampOfAttempt = block.timestamp;
        // releaseTokenByAdmin();
    }
    
    
    function distributeTokens(uint256 index, uint256 amount) internal{
         address[] memory distributionAddresses = internalTokenReceiverAddresses[index];
        for(uint256 l=0;l<distributionAddresses.length;l++){
            //saves the amount of tokens will be distributed
              uint256 distributionAmount=(amount.div(distributionAddresses.length));
              bondTokensHolded[distributionAddresses[l]] += distributionAmount;
        }
    }
    
    function releaseTokenByAdmin() internal{
        releaseTokenToParticularTeam(getInternalTeamContributionAddress());
        releaseTokenToParticularTeam(getInternalSoftwareDevTeamsAddress());
        releaseTokenToParticularTeam(getBugBountyTeamAddress());
        releaseTokenToParticularTeam(getAdvisoryBoardAddress());
        releaseTokenToParticularTeam(getMarketingAndSalesAddress());
       
    }
    function releaseTokenToParticularTeam(address[] memory addressArray) internal{
        Token obj = Token(tokenContractAddress);
        for(uint256 i=0;i<addressArray.length;i++){
            require(bondTokensHolded[addressArray[i]]>0,"No token given");
            obj.transfer(addressArray[i],bondTokensHolded[addressArray[i]]);
            bondTokensHolded[addressArray[i]] = 0;
        }
    }
    function releaseMyTokens() public{
        require(bondTokensHolded[msg.sender]>0,"No token given");
        Token obj = Token(tokenContractAddress);
        obj.transfer(msg.sender,bondTokensHolded[msg.sender]);
        bondTokensHolded[msg.sender] = 0;
    }
    
    function getInternalTeamContributionAddress() public view returns(address[] memory){
        return internalTokenReceiverAddresses[0];
    }
    function getInternalSoftwareDevTeamsAddress() public view returns(address[] memory){
        return internalTokenReceiverAddresses[1];
    }
    function getBugBountyTeamAddress() public view returns(address[] memory){
        return internalTokenReceiverAddresses[2];
    }
    function getAdvisoryBoardAddress() public view returns(address[] memory){
        return internalTokenReceiverAddresses[3];
    }
    function getMarketingAndSalesAddress() public view returns(address[] memory){
        return internalTokenReceiverAddresses[4];
    }
    function addInternalTeamContributionAddress(address userAddress) public onlyOwner{
        require(!(addressAvailable(userAddress,0)),"Address already exists");
        internalTokenReceiverAddresses[0].push(userAddress);
    }
    function addInternalSoftwareDevTeamsAddress(address userAddress) public onlyOwner{
        require(!(addressAvailable(userAddress,1)),"Address already exists");
         internalTokenReceiverAddresses[1].push(userAddress);
    }
    function addBugBountyTeamAddress(address userAddress) public onlyOwner{
        require(!(addressAvailable(userAddress,2)),"Address already exists");
         internalTokenReceiverAddresses[2].push(userAddress);
    }
    function addAdvisoryBoardAddress(address userAddress) public onlyOwner{
        require(!(addressAvailable(userAddress,3)),"Address already exists");
         internalTokenReceiverAddresses[3].push(userAddress);
    }
    function addmarketingAndSalesAddress(address userAddress) public onlyOwner{
        require(!(addressAvailable(userAddress,4)),"Address already exists");
         internalTokenReceiverAddresses[4].push(userAddress);
    }
    
    function addressAvailable(address userAddress, uint256 index) internal view returns(bool){
         bool isAvailable=false;
        for(uint256 i=0;i<internalTokenReceiverAddresses[index].length;i++){
            if(internalTokenReceiverAddresses[index][i]==userAddress){
                isAvailable=true;
            }
        }
        return isAvailable;
    }
    
    function deleteInternalTeamContributionAddress(uint256 index) public onlyOwner{
         internalTokenReceiverAddresses[0]=removeIndex(index,internalTokenReceiverAddresses[0]);
    }
    function deleteInternalSoftwareDevTeamsAddress(uint256 index) public onlyOwner{
         internalTokenReceiverAddresses[1]=removeIndex(index,internalTokenReceiverAddresses[1]);
    }
    function deleteBugBountyTeamAddress(uint256 index) public onlyOwner{
         internalTokenReceiverAddresses[2]=removeIndex(index,internalTokenReceiverAddresses[2]);
    }
    function deleteAdvisoryBoardAddress(uint256 index) public onlyOwner{
         internalTokenReceiverAddresses[3]=removeIndex(index,internalTokenReceiverAddresses[3]);
    }
    function deleteMarketingAndSalesAddress(uint256 index) public onlyOwner{
         internalTokenReceiverAddresses[4]=removeIndex(index,internalTokenReceiverAddresses[4]);
    }
    
    function removeIndex(uint256 index, address[] memory addressArray) internal returns(address[] memory){
        tempArray=new address[](0);
        for(uint256 i=0;i<addressArray.length;i++){
            if(i!=index){
                tempArray.push(addressArray[i]);
            }
        }
        return tempArray;
    }
}
