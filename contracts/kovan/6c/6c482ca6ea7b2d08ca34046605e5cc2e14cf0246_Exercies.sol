pragma solidity >= 0.3.0 <= 0.4.26;
//pragma solidity ^0.5.0;
import './ERC20.sol';

contract Exercies {
    
    uint256 public memCount ;
    TestToken public Token;
    mapping(address => bool) public isMember; // list member
    mapping(address => mapping(uint=> mapping (uint => bool))) internal isvoted;
    
    address public owner;
    
    
    event addMember(address indexed account, uint numVotes);
    event removeMember(address indexed account, uint numVotes);

    event transactiongroupDeposit(address indexed account, uint256 amount, uint voteCount);
    event transactionVotingToken(address indexed Votee, TestToken tokenAddr, uint256 _countVote, uint typeTransaction);
    
    event transactionETH(address indexed _member, uint256 _ethVal, string typeTransaction);
    event transactionETH__multi(address indexed _member, address _recipient, uint256 _ethVal, string typeTransaction);
    event transactionTOKEN(address indexed _member, TestToken indexed _token, uint256 _tokenVal, string typeTransaction);
    event transactionTOKEN_multi(address indexed _member,address _recipient, TestToken indexed _token,uint256 _tokenVal, string typeTransaction);
    event transactionVoting(address indexed epositVotee, uint256 _countVote, string typeTransaction);
    
    function () public payable{
            // do nothing here
    }
    
    //Candidate
   struct candidate {
        
        uint id;
        address candidateAddr;
        uint typeVote; //1 = add, 2 = remove, 3 = depositETH, 4 = withdrawETH
        uint256 amount;
        address recipient;
        uint numVotes;
    }
    
     //voting Session
    struct votingSession {
        uint id;  // starts from 1
        uint votename;
        uint votee;
        
    }
  
    mapping(uint =>mapping(uint => candidate)) public candidates;
    
    mapping(uint256  => votingSession) public votingArray;

     // Number of Candidates in pending status 
    uint public pendingAddCount = 0;
    uint public pendingRemoveCount = 0;
    uint public pendingDepositETHCount = 0;
    uint public pendingWithdrawETHCount = 0;
    uint public pendingDepositTokenCount = 0;
    uint public pendingWithdrawTokenCount = 0;

    //number of voting sesion
    uint public numVotingSession = 0;

    //Number of final result votes
    uint private finalResultAdd = 0;
    uint private finalResultRemove = 0;
    uint private finalResultDepositETH = 0;
    uint private finalResultDepositToken = 0;
    uint private finalResultWithdrawETH = 0;

    //variable used to store balance of contract, msg.sender, recipient when waiting vote deposit
    uint256 public totalETH ;
    uint256 public totalETHSender ;
    uint256 public totalETHRecipient;

    //state of voting session
    enum State { Created, Voting, finishVoting }
	State public state;

    constructor() public {
        
        owner = msg.sender;
        isMember[msg.sender]=true;
        memCount= 1;
        numVotingSession = 0;
        totalETH = address(this).balance; //store balance of contract
       
       
    }

    modifier inState(State _state) {
		require(state == _state);
		_;
	}

     modifier onlyMember() {
        require(isMember[ msg.sender ], "Not member");
        _;
    }
    

    //Create waiting pending vote 
     function pendingAdd (address candidateAddr) internal {
        pendingAddCount++;
        candidates[pendingAddCount][1] = candidate(pendingAddCount,candidateAddr,1, 0, 0x0 , 0);
        
    }
    
    function pendingRemove (address candidateAddr) internal {
        pendingRemoveCount++;
        candidates[pendingRemoveCount][2] = candidate(pendingRemoveCount,candidateAddr,2, 0, 0x0, 0);
        
    }
    
    function pendingDepositETH ( address candidateAddr, uint256 amount) internal {
        pendingDepositETHCount++;
        candidates[pendingDepositETHCount][3] = candidate(pendingDepositETHCount,candidateAddr,3, amount, address(this), 0);
        
    }
    
    function pendingWithdrawETH ( address candidateAddr, address recipient, uint256 amount) internal {
        pendingWithdrawETHCount++;
        candidates[pendingWithdrawETHCount][4] = candidate(pendingWithdrawETHCount,candidateAddr,4, amount,recipient, 0);
        
    }

    //initiate voting session
    function startVote() internal inState(State.Created){

        state = State.Voting;     
    }

    //call candidateID in waiting pending vote
    function vote (uint candidateID, uint votetype ) public {
        
        // require that they haven't voted before
        require( isMember[msg.sender], "not member");
 
        require((votetype == 1 && candidateID <= pendingAddCount) || (votetype == 2 && candidateID <= pendingRemoveCount) || (votetype == 3 && candidateID <= pendingDepositETHCount) || (votetype == 4 && candidateID <= pendingWithdrawETHCount), " ID is not in this type pending ");
        
        require(!isvoted[msg.sender][ candidateID][votetype], "already voted");
        
        // record that voter has voted
         isvoted[msg.sender][candidateID][votetype] = true;  // msg.sender is the caller address

        // update candidate vote Count
        ++candidates[candidateID][votetype].numVotes;
        
        numVotingSession++;
        //state = State.finishVoting;
        votingArray[numVotingSession] = votingSession(numVotingSession, votetype, candidateID);
        
        
    }
    

   //end and count votes
    function finalize( uint candidateID, uint votetype )
        public
        inState(State.Voting)
        returns (bool)
    {
        require(votetype == 1 || votetype == 2 || votetype == 3 || votetype == 4, " only return final Result for vote add or vote remove function ");
       
        
        if(votetype == 1 ){
            
            require(candidateID <= pendingAddCount, " ID not exist in pendingAdd ");
            
            finalResultAdd = candidates[candidateID][1].numVotes ;
            
            //enough votes add
            if(finalResultAdd * 100 >= 50* memCount){
                
                state = State.finishVoting;
                
                memCount++;
                
                isMember[candidates[candidateID][votetype].candidateAddr] = true;
                
                emit addMember (candidates[candidateID][votetype].candidateAddr, finalResultAdd);
                //voteCount[votee]=0;
            }else{
                
                state = State.Voting;
            }
        }
        
        
        if(votetype == 2 ){
            
            require(candidateID <= pendingRemoveCount, " ID not exist in pendingRemove ");
            
            finalResultRemove = candidates[candidateID][2].numVotes ;
            
             //enough votes remove
            if(finalResultRemove * 100 >= 50 * memCount)
            {
                state = State.finishVoting;
                memCount--;
                isMember[candidates[candidateID][votetype].candidateAddr] =  false;
                emit removeMember(candidates[candidateID][votetype].candidateAddr, finalResultRemove);
                
            }else{
                
                state = State.Voting;
            }
        }
       
        
        if(votetype == 3 ){
            
            require(candidateID <= pendingDepositETHCount, "ID not exist in pendingDeposit");
            
            finalResultDepositETH = candidates[candidateID][3].numVotes;
            
            //enough vote deposit
             if(finalResultDepositETH == memCount){
                 
                state = State.finishVoting;
    
                uint256  amountDeposit = candidates[candidateID][3].amount ;
                
                totalETH = totalETH + amountDeposit;
                totalETHSender =  totalETHSender - amountDeposit;
                 
            }else{
                
                state = State.Voting;
            }
        } 
        
            
        if( votetype == 4 ){
            
            require(candidateID <= pendingWithdrawETHCount , "ID not exist in pendingWithdraw");
            
            finalResultWithdrawETH = candidates[candidateID][4].numVotes;
            //enoungh vote withdraw
             if(finalResultWithdrawETH * 100 > 50 * memCount){
                 
                state = State.finishVoting;
    
                uint256  amountWithdraw = candidates[candidateID][4].amount ;
                
                totalETH = totalETH - amountWithdraw;
                totalETHRecipient =  totalETHRecipient + amountWithdraw;
                 
            }else{
                
                state = State.Voting;
            }
        } 
        
        
        return true;
    }
    
    //initiate vote Add session
    function addMem( address votee ) public returns(bool) {
        
        state = State.Created;
        //Kiểm tra xem người vote được vote hay ko
        require( isMember[msg.sender], "not member");
        require(!isMember[votee], "votee is already a member ");
        //require(votingSessionID > numVotingSession, "votingSessionID is already exist ");
        pendingAdd(votee);
        startVote();
        return true;
        
        
    }
    
    //initiate vote remove session 
    function removeMem( address votee ) public returns(bool) {
        state = State.Created;
        //Kiểm tra xem người vote được vote hay ko
        require(isMember[msg.sender], "not member");
        require(isMember[votee], "votee is not a member yet");
        pendingRemove(votee);
        startVote();
        return true;
      
    }
    
    //initiate vote deposit session
    function groupDepositETH(uint256 amountDeposit) public{
        
        state = State.Created;
        totalETHSender = msg.sender.balance ;
        amountDeposit = amountDeposit * (10 ** 18);
        require( isMember[msg.sender], "not member");
        require(amountDeposit<= msg.sender.balance, "not enough balance");
        pendingDepositETH(msg.sender, amountDeposit);
        startVote();
        
       
    }
    
    //initiate vote withdraw session
    function groupWithdrawETH(address recipient, uint256 amountWithdraw) public{
        
        require(isMember[msg.sender], "not member");
        amountWithdraw = amountWithdraw * (10 ** 18);
        require(totalETH >= amountWithdraw, "not enough balance");
        state = State.Created;
        totalETHRecipient = recipient.balance ;
        pendingWithdrawETH(msg.sender, recipient, amountWithdraw);
        startVote();
        
       
    }
    
    
    //get balance ETH or any token
    
    function balanceOfETH() public view returns (uint256) 
    {
        require(isMember[msg.sender], "not member");
        return address(this).balance;
        
    }
    
    function balanceOfTOKEN(address _tokenAddress, address _addressToQuery) public view returns (uint256) 
    {  
        require(isMember[msg.sender], "not member");
        //Lay balance của member đó tại địa chỉ token đó
       return TestToken(_tokenAddress).balanceOf(_addressToQuery);
        
    }
    
    
    // deposit ETH or any token
    
    function DepositETH() public payable {
        require(isMember[msg.sender], "not member");
        uint256 rate = ( address(this).balance*30)/100;
        if(address(this).balance != msg.value) {
            require(msg.value<=rate, "only deposit up to 30% total Token amount that the smart contract hold");
             emit transactionETH(msg.sender, msg.value, "deposit");
        }
        else {
             emit transactionETH(msg.sender, msg.value, "deposit");
        } 
         
    }
    
     function DepositTOKEN(TestToken _tokenAddress, uint256 _amount ) public  {
        require(isMember[msg.sender], "not member");
        uint256 rate = (TestToken(_tokenAddress).balanceOf(address(this))*30)/100;
        if(TestToken(_tokenAddress).balanceOf(address(this)) != 0){
            require(_amount<=rate, "only deposit up to 30% total Token amount that the smart contract hold");
            TestToken(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
             emit transactionTOKEN(msg.sender, _tokenAddress, _amount, "deposit");
        }
        else{
            TestToken(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
             emit transactionTOKEN(msg.sender, _tokenAddress, _amount, "deposit");
        } 
         
       
    }


    // withdraw ETH or any token from contract to sender, or from contract to other account
    
    function withdrawETH(uint256 _amount) public {
        require(isMember[msg.sender], "not member");
        require(address(this).balance >= _amount, "not enough balance");
        msg.sender.transfer(_amount);
    }
    
    function withdrawTOKEN(TestToken _token, uint256 _amount) public returns (bool) {
        require(isMember[msg.sender], "not member");
        require(TestToken(_token).balanceOf(address(this)) >= _amount, "not enough token");
        TestToken( _token).transfer(msg.sender, _amount);
        emit transactionTOKEN(msg.sender,  _token, _amount, "withdraw");
        return true;
        
        
    }
    
    function withdrawETH_multi(address _recipient, uint256 _amount ) public payable{
        require(isMember[msg.sender], "not member");
        require(address(this).balance >= _amount, "not enough balance");
        _recipient.transfer(_amount);
        emit transactionETH__multi( msg.sender, _recipient,  _amount, "withdraw");
    }
    
    function withdrawTOKEN_multi(TestToken _token, address  _recipient, uint256 _amount) public {
        require(isMember[msg.sender], "not member");
        require(TestToken(_token).balanceOf(address(this)) >= _amount, "not enough balance");
        emit transactionTOKEN_multi(msg.sender, _recipient,  _token, _amount, "withdraw");
        TestToken( _token).transfer( _recipient, _amount);
        
    }  
    
 }