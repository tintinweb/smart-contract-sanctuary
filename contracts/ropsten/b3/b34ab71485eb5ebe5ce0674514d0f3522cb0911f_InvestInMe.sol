/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7; 

contract InvestInMe{
    
    mapping (uint => Profile) public userProfile; 
    mapping (uint => Investment) public investor; 

    uint public profileCount = 0; 
    
    address public owner; 

    struct Profile{
        uint id; 
        string firstName; 
        string lastName;
        uint goal; 
        uint balance;
        string avatar; 
        string website; 
        string videoUrl;
        string skills;  
        address creator;       
        uint payBackPercentage;  
        uint payBackTime;  
        bool isActive;         
    }

    struct Investment{
        address investor; 
        uint amount;
        uint investedOn; 
    }

    struct HomeCard{
        string title; 
        uint id;
    }
    
    //Events 
    event ProfileCreated(uint id); 
    event ProfileToggle(uint id); 
    event Invested(uint amount); 
    event Withdraw(uint id); 
    event PayBack(uint id); 

    enum State{Created, Active, Invested, Withdrawed, Ended}
    State public state; 

   
    //MODIFIERS 
    modifier onlyAdmin(){
        require(msg.sender == owner);
        _;
    }
    /*
    modifier onlyCreator(){
        require(msg.sender == userProfile.creator);
        _;
    }
    */
    modifier inState(State _state){
        require(state == _state); 
        _;
    }

    constructor(){
        owner = msg.sender; 
    }

    function createProfile(
        string memory _firstName, 
        string memory _lastName, 
        uint _goal,
        string memory _avatar,
        string memory _website,
        string memory _videoUrl,
        string memory _skills,
        uint _payBackPercentage,
        uint _payBackTime
    ) public {
        uint _profileId = profileCount; 
        address _creator = msg.sender;
        Profile memory newUser = Profile(_profileId, _firstName, _lastName, _goal, 0, _avatar, _website, _videoUrl, _skills, _creator, _payBackPercentage, _payBackTime, true);
        userProfile[_profileId] = newUser; 
        profileCount++; 
        emit ProfileCreated(_profileId); 
    }
    

    function invest(uint _InvestmentId) public payable {
        require(msg.sender != address(0), "Invalid Address"); 
        //check if the creator is the investor 
        Profile storage up = userProfile[_InvestmentId]; 
       require(msg.sender != up.creator, "You are the Owner"); //check if the address is creator address
        uint amount = msg.value; 
        up.balance += amount;  

        Investment memory newInvestor = Investment(msg.sender, amount, _InvestmentId); 
        investor[_InvestmentId] = newInvestor; 
        emit Invested(amount);
    }
    
    function withdraw(uint _projectId) public returns(bool){
        address payable accountWithDrawing = payable(msg.sender); 
        
        Profile storage up = userProfile[_projectId]; 
        //check if the balance has enough amount  
        require(msg.sender == up.creator, "You are not the Owner"); //only if the address is creator address
        require(up.balance > 0, "Not enough balance"); 

        if(accountWithDrawing.send(up.balance)){
            up.balance=0;
            emit Withdraw(_projectId);
            return true;
        }    
        
        return false;
    }
    
    function payBack() public {

    }

    function CountInvestor() internal {

    }
    
    function endInvestment() public  inState(State.Active) {
        //check if the profie is active
        state= State.Ended;
    }

    function toggleProfile(uint _index) external {
        Profile storage up = userProfile[_index]; 
        require(msg.sender == up.creator, "You are not the Owner"); //only if the address is creator address
        up.isActive = !up.isActive;     
        emit ProfileToggle(_index);
    }

    
    function getProfiles() public view returns(HomeCard[] memory){
        HomeCard[] memory cards = new HomeCard[](profileCount); 
        for(uint i =0; i<profileCount; i++){
            //check if the profile is active
            if(userProfile[i].isActive==true){
                HomeCard memory homeCard = HomeCard(userProfile[i].firstName, userProfile[i].id); 
                cards[i] = homeCard;         
            }
        }
        return cards; 
    }

    function getInvestor() public {
      
    }
}