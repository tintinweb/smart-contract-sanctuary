pragma solidity >= 0.3.0 <= 0.4.26;
import './ERC20.sol';

contract Exercies {
    
    uint256 public memCount ;
    TestToken public Token;
    mapping(address => bool) public isMember; // list member 
    mapping(address => mapping( address => bool) ) public isvoted;
    mapping(address => uint256 ) public voteCount;
    mapping(address => mapping( uint8 => uint256) ) public pendingDeposit;
    address public owner;
    
    
    event addMember(address indexed account);
    event removeMember(address indexed account);
    event transactionETH(address indexed _member, uint256 _ethVal, string typeTransaction);
    event transactionETH__multi(address indexed _member, address _recipient, uint256 _ethVal, string typeTransaction);
    event transactionTOKEN(address indexed _member, TestToken indexed _token, uint256 _tokenVal, string typeTransaction);
    event transactionTOKEN_multi(address indexed _member,address _recipient, TestToken indexed _token,uint256 _tokenVal, string typeTransaction);
    event transactionVoting(address indexed epositVotee, uint256 _countVote, string typeTransaction);
    
   function () public payable{
            // do nothing here
    }
    
    constructor() public {
        
        
        owner = msg.sender;
       isMember[msg.sender]=true;
       memCount= 1;
       
       
    }

    modifier onlyMember() {
        require(isMember[ msg.sender ], "Not member");
        _;
    }
    
    
    function voteAdd( address votee ) public {
        
        //Kiểm tra xem người vote được vote hay ko
        require( isMember[msg.sender], "bạn chưa phải là member nên không được vote");
        require(!isMember[votee], "Bạn đã là member rồi mà cần vote làm gì ");
        require(!isvoted[msg.sender][votee],"Bạn đã vote cho người này rồi");
        
        //set votee thành true
        isvoted[msg.sender][votee]==true;
        
        //
        voteCount[votee]++;
        //emit voting(msg.sender, votee);
        
        if(voteCount[votee]*100>= 50*memCount)
        {
            isMember[votee] = true;
            memCount++;
            emit addMember ( votee);
            voteCount[votee]=0;
        }
         
        
      
    }
    
     
    function voteRemove( address votee ) public {
       
        //Kiểm tra xem người vote được vote hay ko
        require( isMember[msg.sender], "bạn chưa phải là member nên không được vote");
        
        require(!isvoted[msg.sender][votee],"Bạn đã vote cho người này rồi");
        
        //set votee thành true
        isvoted[msg.sender][votee]==true;
        
        //
        voteCount[votee]++;
        //emit voting(msg.sender, votee);
        
        if(voteCount[votee]*100>= 50*memCount)
        {
            isMember[votee] = false;
            memCount--;
            emit removeMember( votee);
            voteCount[votee]=0;
        }
        
      
    }
    
    
    //get balance ETH or any token
    
    function balanceOfETH() public view returns (uint256) 
    {
        require(isMember[msg.sender], "Chi co member moi duoc xem balance ETH");
        return address(this).balance;
        
    }
    
    function balanceOfTOKEN(address _tokenAddress, address _addressToQuery) public view returns (uint256) 
    {  
        require(isMember[msg.sender], "Chi co member moi duoc xem balance Token");
        //Lay balance của member đó tại địa chỉ token đó
       return TestToken(_tokenAddress).balanceOf(_addressToQuery);
        
    }
    
    
    // deposit ETH or any token
    
    function DepositETH() public payable {
        require(isMember[msg.sender], "Chi co member moi duoc deposit");
        uint256 rate = ( address(this).balance*30)/100;
        if(address(this).balance != msg.value) {
            require(msg.value<=rate, "chi duoc deposit up to 30% total Token amount that the smart contract hold");
             emit transactionETH(msg.sender, msg.value, "deposit");
        }
        else {
             emit transactionETH(msg.sender, msg.value, "deposit");
        } 
         
    }
    
     function DepositTOKEN(TestToken _tokenAddress, uint256 _amount ) public  {
        require(isMember[msg.sender], "Chi co member moi duoc deposit Token");
        uint256 rate = (TestToken(_tokenAddress).balanceOf(this)*30)/100;
        if(TestToken(_tokenAddress).balanceOf(this) != 0){
            require(_amount<=rate, "chi duoc deposit up to 30% total Token amount that the smart contract hold");
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
        require(isMember[msg.sender], "Chi co member moi duoc withdraw");
        require(address(this).balance >= _amount, "balance cua contract khong du de thuc thi");
        msg.sender.transfer(_amount);
    }
    
    function withdrawTOKEN(TestToken _token, uint256 _amount) public returns (bool) {
        require(isMember[msg.sender], "Chi co member moi duoc withdraw");
        require(TestToken(_token).balanceOf(address(this)) >= _amount, "balance cua contract khong du de thuc thi");
        TestToken( _token).transfer(msg.sender, _amount);
        return true;
        emit transactionTOKEN(msg.sender,  _token, _amount, "withdraw");
        
    }
    
    function  withdrawETH_multi(address  _recipient, uint256 _amount ) public payable{
        require(isMember[msg.sender], "Chi co member moi duoc withdraw");
        require(address(this).balance >= _amount, "balance cua contract khong du de thuc thi");
        _recipient.transfer( _amount);
        emit transactionETH__multi( msg.sender, _recipient,  _amount, "withdraw");
    }
    
    function withdrawTOKEN_multi(TestToken _token, address  _recipient, uint256 _amount) public {
        require(isMember[msg.sender], "Chi co member moi duoc withdraw");
        require(TestToken(_token).balanceOf(address(this)) >= _amount, "balance cua contract khong du de thuc thi");
        emit transactionTOKEN_multi(msg.sender, _recipient,  _token, _amount, "withdraw");
        TestToken( _token).transfer( _recipient, _amount);
        
    }
    
    
    //group deposit
    function groupDepositETH(address depositVotee)  public payable{
        //Kiểm tra xem người vote được vote hay ko
        require( isMember[depositVotee], "bạn chưa phải là member nên không được deposit");
        require( isMember[msg.sender], "bạn chưa phải là member nên không được vote");
        require(!isvoted[msg.sender][depositVotee],"Bạn đã vote cho người này rồi");
        //set votee thành true
        isvoted[msg.sender][depositVotee]==true;
        //
        voteCount[depositVotee]++;
        //emit voting(msg.sender, votee);
        
        if(voteCount[depositVotee]== memCount)
        {
            emit transactionVoting(msg.sender,voteCount[depositVotee], "depositVoting");
            voteCount[depositVotee]=0;
            
        }
    }
  
    function groupWithdrawETH(address WithdrawVotee, uint256 _amount)  public payable{
        //Kiểm tra xem người vote được vote hay ko
        require( isMember[msg.sender], "bạn chưa phải là member nên không được vote");
        require(address(this).balance >= _amount, "balance cua contract khong du de thuc thi");
        require(!isvoted[msg.sender][WithdrawVotee],"Bạn đã vote cho người này rồi");
        //set votee thành true
        isvoted[msg.sender][WithdrawVotee]==true;
        
        //
        voteCount[WithdrawVotee]++;
        //emit voting(msg.sender, votee);
        
        if(voteCount[WithdrawVotee]== memCount)
        {
            emit transactionVoting(msg.sender,voteCount[WithdrawVotee], "depositVoting");
            msg.sender.transfer(_amount);
            voteCount[WithdrawVotee]=0;
            
        }
    }
 }