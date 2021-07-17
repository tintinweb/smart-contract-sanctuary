/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;


interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
 

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Poll  {
    uint256 private optionAVotes;
    uint256 private optionBVotes;
    uint256 private optionCVotes;
    uint256 private optionDVotes;
    string private A = 'a';
    string private B = 'b';
    string private C = 'c';
    string private D = 'd';
    string private userAnswer;
   string[] public options;
   string public Question;
   string private Answer;
   uint private time;
   address public _owner;
   IBEP20 public TOBA1;
   
   mapping (address => string) public userVote;
   mapping (address => uint) private score;
   mapping (address => bool) markVoter;
   
   
   
     constructor(address TOBEAddr, string memory _question, string memory _optionA, string memory _optionB, string memory _optionC, string memory _optionD) {
            options.push(_optionA);
            options.push(_optionB);
            options.push(_optionC);
            options.push(_optionD);
            Question = _question;
             TOBA1 = IBEP20(TOBEAddr);
              _owner = msg.sender;
        }
    

    
    modifier hasVoted {
        require(markVoter[msg.sender] != true, 'You have already voted');
        _;
        
    }
    
    modifier hasQuizStarted{
        require(time != 0, 'quiz has not started');
        _;
        
    }
    
    modifier hasQuizEnded {
        require(block.timestamp > time, 'quiz has not ended');
        _;
        
    }
    
    modifier isthereAnswer {
        bytes memory AnswerString = bytes(Answer);
        
        require(AnswerString.length != 0, 'Answer has not been set by smart contract owner');
        _;
    }
    
    
    
     function showBal(address _userAddress) public view  returns(uint256){
      uint256 bal = TOBA1.balanceOf(_userAddress)/10**18;
      
      return bal;
  }
  
  
    
    function setTime(uint _add) public {
        require(time == 0, 'you can only set the time once');
        require(msg.sender == _owner);
        time = block.timestamp + _add;
    }
    
    function setAnswer(string memory _answer) external {
        require(time != 0, 'quiz has not started');
        require(block.timestamp > time, 'quiz has not ended');
        require(msg.sender == _owner, 'not owner contract');
        Answer = _answer;
    }
    
  
    
    
    function getUserScore(address _userAddress) public view isthereAnswer returns(uint){
        require(time != 0, 'quiz has not started');
        require(block.timestamp > time, 'quiz has not ended');
        if(keccak256(abi.encodePacked((Answer))) == keccak256(abi.encodePacked((userVote[_userAddress])))){
            return 1;
        }
        
        return 0;
        
    }
    
    
    function showNumberOfVotes(string memory _option) public view hasQuizStarted hasQuizEnded returns(uint){
         if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((A)))){
             return optionAVotes;
         }else if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((B)))){
             return optionBVotes;
         }else  if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((C)))){
             return optionCVotes;
         }else  if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((D)))){
             return optionDVotes;
         }
         
         return 0;
         
         
    }
    
    
    
    
    
    function vote(string memory _option, address _receiver) public  hasVoted{
        require(time != 0, 'quiz has not started');
        require(block.timestamp < time, 'quiz has ended');
        require(TOBA1.balanceOf(msg.sender)/10**18 > 10);
        
        
         if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((A)))){
             TOBA1.transferFrom(msg.sender,_receiver, 10*10**18);
             markVoter[msg.sender] = true;
             userVote[msg.sender] = _option;
             userAnswer = _option;
             optionAVotes++;
        }else if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((B)))){
            TOBA1.transferFrom(msg.sender,_receiver, 10*10**18);
             markVoter[msg.sender] = true;
             userVote[msg.sender] = _option;
             userAnswer = _option;
            optionBVotes++;
        }else if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((C)))){
            TOBA1.transferFrom(msg.sender,_receiver, 10*10**18);
             markVoter[msg.sender] = true;
             userVote[msg.sender] = _option;
             userAnswer = _option;
            optionCVotes++;
        }else if(keccak256(abi.encodePacked((_option))) == keccak256(abi.encodePacked((D)))){
           TOBA1.transferFrom(msg.sender,_receiver, 10*10**18);
             markVoter[msg.sender] = true;
             userVote[msg.sender] = _option;
             userAnswer = _option;
            optionDVotes++;
        }
        
    }
    
}