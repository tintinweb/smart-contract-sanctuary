/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity >=0.4.22 <0.6.0;

library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn&#39;t found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don&#39;t match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner ) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract ECP is Ownable{
    using StringUtils for string;
struct User {
        uint cnic; // user cnic
        string userType; // user type
        address Address; // blockchain address
        string consistancy; // NA or PA and contaning number like NA-45  
        string PollingStation;
     }
 struct Consistency{
        string name;
    }
struct PollingStation{
        string name;
        uint consistency;
        address ecpaddress;
        address roaddress;
        address POaddress;
        address caddress;
      }
   
struct CandidateResult{
  uint ValidVote;
  uint TenderedVote;
  uint ChallengeVote;
  uint ConsitituencyNO;
      }
     
struct F45{
    uint MVotes;
    uint FVotes;
    }
struct SrNumberOfbook{
    uint SrNumberOfbooksFrom;
    uint SrNumberOfbooksTo;
    }    
struct SrNOfBallotPapper{
    uint SrNumberOfBallotPapperFrom;
    uint SrNumberOfBallotPapperTo;
    }

struct SrNOfUnissuedBP{
    uint SrNumberOfUnissuedBallotPapperFrom;
    uint SrNumberOfUnissuedBallotPapperTo;
    }
    
struct F46{
    uint QuantityOfBallotPapers;
    uint NumberOFbooks;
    uint BallotPaperTakenOutfromBallotBox;
    uint TenderedBPaper;
    uint ChallengeBPaper;
    uint SpoilBpaper;
    }
   struct Approveps45{
        bool ECPVerify;
        bool  CANDVerify;
        bool  ROVerify;
   }
    struct Approveps46{
        bool ECPVerify;
        bool  CANDVerify;
        bool  ROVerify;
   }
    mapping(uint=>mapping(uint=>Approveps45))public status45;
    mapping(uint=>mapping(uint=>Approveps46))public status46;
    mapping(uint => CandidateResult)public CandidateResults;
    mapping(uint=>Consistency) public  consistencies;
    mapping(uint=>mapping(uint=>PollingStation)) public  pollingstations;// [1001][0], [1002][0] first index is consistencies no
    mapping(uint=>mapping(address=>CandidateResult)) public CandidatePollingResults;
    mapping(uint=>mapping(uint=>mapping(uint=>SrNOfUnissuedBP))) public UNISSUEDBALLOTPAPERS;
    mapping(uint=>mapping(uint=>mapping(uint=>SrNOfBallotPapper))) public SrNOfBallotPappers;
    mapping(uint=>mapping(uint=>mapping(uint=>SrNumberOfbook))) public SrNumberOfbooks;
    mapping(address=>User) public users;
    mapping(uint=>mapping(uint=>F45))public F45s;   //first index is consistencies no sencond index is pollingstations no
    mapping(uint=>mapping(uint=>F46)) public F46s;   //first index is consistencies no sencond index is pollingstations no
   
    User public ecp;
    modifier onlyPresidindOfficer() {
        require(users[msg.sender].userType.equal("PO"));
        _;
    }
    modifier onlyReturningOfficier() {
        require(users[msg.sender].userType.equal("RO"));
        _;
    }
    
    modifier onlyECP() {
        require(msg.sender == ecp.Address);
        _;
    }
  
    event EcpAdded(uint  _cnic, string userType , address Address);
    function approve45(address _userAddress,string memory _userType,uint _consistancy,uint _pollingstation) public{
     
      if(_userType.equal("RO"))
      {
        require(users[msg.sender].userType.equal(&#39;RO&#39;));      
          
        status45[_consistancy][_pollingstation]= Approveps45(status45[_consistancy][_pollingstation].ECPVerify,status45[_consistancy][_pollingstation].CANDVerify,true);//status[_consistancy][_pollingstation][ECPVerify];

      }
      
     else if(_userType.equal("ECP")){
        require(users[msg.sender].userType.equal(&#39;ECP&#39;));      
          
        status45[_consistancy][_pollingstation]= Approveps45(true,status45[_consistancy][_pollingstation].CANDVerify,status45[_consistancy][_pollingstation].ROVerify);//status[_consistancy][_pollingstation][ECPVerify];

      }
    else  if(_userType.equal("CAND")){
        require(users[msg.sender].userType.equal(&#39;CAND&#39;));      
          
        status45[_consistancy][_pollingstation]= Approveps45(status45[_consistancy][_pollingstation].ECPVerify,true,status45[_consistancy][_pollingstation].ROVerify);//status[_consistancy][_pollingstation][ECPVerify];

      }
   
    }
 
   function approve46(address _userAddress,string memory _userType,uint _consistancy,uint _pollingstation) public{
     
      if(_userType.equal("RO"))
      {
        require(users[msg.sender].userType.equal(&#39;RO&#39;));      
          
        status46[_consistancy][_pollingstation]= Approveps46(status46[_consistancy][_pollingstation].ECPVerify,status46[_consistancy][_pollingstation].CANDVerify,true);//status[_consistancy][_pollingstation][ECPVerify];

      }
      
     else if(_userType.equal("ECP")){
        require(users[msg.sender].userType.equal(&#39;ECP&#39;));      
          
        status46[_consistancy][_pollingstation]= Approveps46(true,status46[_consistancy][_pollingstation].CANDVerify,status46[_consistancy][_pollingstation].ROVerify);//status[_consistancy][_pollingstation][ECPVerify];

      }
    else  if(_userType.equal("CAND")){
        require(users[msg.sender].userType.equal(&#39;CAND&#39;));      
          
        status46[_consistancy][_pollingstation]= Approveps46(status46[_consistancy][_pollingstation].ECPVerify,true,status46[_consistancy][_pollingstation].ROVerify);//status[_consistancy][_pollingstation][ECPVerify];

      }
   
    }
 
   
    function addSrNumberOfbook(uint _SrNumberOfbooksFrom,  uint _SrNumberOfbooksTo,uint _consistancy,uint _pollingstation,uint _book)  public onlyPresidindOfficer returns(bool)
    {
        SrNumberOfbooks[_consistancy][_pollingstation][_book] = SrNumberOfbook(_SrNumberOfbooksFrom,_SrNumberOfbooksTo); 
         return true;
    }
    function addSrNOfBallotPapper(uint _SrNumberOfBallotPapperFrom ,uint _SrNumberOfBallotPapperTo,uint _consistancy,uint _pollingstation,uint _ballotpapper)public onlyPresidindOfficer returns(bool)
    {
        SrNOfBallotPappers[_consistancy][_pollingstation][_ballotpapper] = SrNOfBallotPapper(_SrNumberOfBallotPapperFrom,_SrNumberOfBallotPapperTo); 
         return true;
    }
    
     function addUNISSUEDBALLOTPAPERS(uint _UnissuedBallotPapperFrom,uint _UnissuedBallotPapperTo,uint _consistancy,uint _pollingstation,uint _unissuedballotpapper)public onlyPresidindOfficer returns(bool)
    {
        UNISSUEDBALLOTPAPERS[_consistancy][_pollingstation][_unissuedballotpapper] = SrNOfUnissuedBP(_UnissuedBallotPapperFrom,_UnissuedBallotPapperTo); 
         return true;
    }
    // can be used to create first ecp or update the first created ecp
    function createECP(uint _cnic, string memory _userType, address _ecpAddress) public onlyOwner returns(uint256) {
      _userType="ECP";
        ecp = User(_cnic , "ECP", _ecpAddress , "","");
        emit EcpAdded(_cnic, "ECP" , _ecpAddress);
        return 1;
    }
    
   

    function createRerturnigOfficierOrCandidate(uint _cnic , string memory _userType, address _userAddress , string memory _consistancy ) public onlyECP returns(bool){
        if(_userType.equal("RO") || _userType.equal("CAND")){
         users[_userAddress] = User(_cnic , _userType , _userAddress , _consistancy,"");
         return true;    
        }
        return false;
    } 
    
    function createPresidingOfficier(uint _cnic , address _userAddress , string memory _consistancy ,string memory _PollingStation) public onlyReturningOfficier returns(bool){
         
         users[_userAddress] = User(_cnic , "PO" , _userAddress , _consistancy,_PollingStation);
         return true;

    }
    
     function AddCandidateResult( uint pollinstationnumber, address _userAddress ,  uint _ValidVote, uint _TenderedVote,uint _ChallengeVote,uint _ConsitituencyNO)  public onlyPresidindOfficer returns(bool){
            
              CandidatePollingResults[pollinstationnumber][_userAddress] = CandidateResult(_ValidVote , _TenderedVote , _ChallengeVote , _ConsitituencyNO); 
              return true;
                     
   }
   
     function AddForm45( uint _MVotes,uint _FVotes,uint _consistancy,uint _pollingstation)  public onlyPresidindOfficer returns(bool){
              F45s[_consistancy][_pollingstation] = F45(_MVotes , _FVotes ); 
              return true;
                     
   }
  
   function AddForm46(uint _QBP, uint _NOB,uint _BPTakenOut ,uint _TBPaper,uint _CBPaper,uint _SPP,uint _consistancy,uint _pollingstation )  public onlyPresidindOfficer returns(bool){
            
               F46s[_consistancy][_pollingstation] = F46(_QBP,_NOB,_BPTakenOut,_TBPaper,_CBPaper,_SPP ); 
              return true;
                     
   }
   
     function AddConsistency(string memory _name , uint  _consistencyNo) onlyPresidindOfficer public  returns(bool){
             consistencies[_consistencyNo] = Consistency(_name);
              return true;
                      }
     function addPollingStation(address _poAddress,  address _caddress, address _ecpaddress, address _roaddress,uint _pollingstationNo,string memory _name,uint  _consistencyNo) onlyPresidindOfficer public  returns(bool){
            require(!consistencies[_consistencyNo].name.equal(&#39;&#39;));
            pollingstations[_consistencyNo][_pollingstationNo] = PollingStation(_name,_consistencyNo,_ecpaddress, _roaddress,_poAddress ,_caddress); 
            return true;
    }
    
    // get user detail
    function getUser(address _userAddress) public returns(uint , string memory){
        return (users[_userAddress].cnic , users[_userAddress].userType);
    }
   
    function getConsistency(uint _Consistency) public returns(string memory){
        return (consistencies[_Consistency].name );
    }
    
     function getPollingStation(uint _pollingstationNo,uint _consistencyNo) public returns(string memory ,address,uint){
        return (pollingstations[_consistencyNo][_pollingstationNo].name, pollingstations[_consistencyNo][_pollingstationNo].POaddress,pollingstations[_consistencyNo][_pollingstationNo].consistency);
    }
    
    function get45(uint _pollingstationNo,uint _consistencyNo) public returns(uint,uint,uint){
        return ( F45s[_consistencyNo][_pollingstationNo].MVotes,F45s[_consistencyNo][_pollingstationNo].FVotes ,F45s[_consistencyNo][_pollingstationNo].MVotes + F45s[_consistencyNo][_pollingstationNo].FVotes);
    }
     function get46(uint _pollingstationNo,uint _consistencyNo) public returns(uint,uint,uint,uint,uint,uint){
        return ( F46s[_consistencyNo][_pollingstationNo].QuantityOfBallotPapers,F46s[_consistencyNo][_pollingstationNo].NumberOFbooks ,F46s[_consistencyNo][_pollingstationNo].BallotPaperTakenOutfromBallotBox, F46s[_consistencyNo][_pollingstationNo].TenderedBPaper,F46s[_consistencyNo][_pollingstationNo].ChallengeBPaper,F46s[_consistencyNo][_pollingstationNo].SpoilBpaper);
    }
    function getCandidatePollingResesult(address _userAddress,uint _pollinstationnumber) public returns(uint,uint,uint,uint){
        return ( CandidatePollingResults[_pollinstationnumber][_userAddress].ValidVote,CandidatePollingResults[_pollinstationnumber][_userAddress].TenderedVote ,CandidatePollingResults[_pollinstationnumber][_userAddress].ChallengeVote, CandidatePollingResults[_pollinstationnumber][_userAddress].ConsitituencyNO);
    }
     function getBallotBook(uint _pollingstationNo ,uint _consistencyNo,uint _book) public returns(uint,uint){
        return ( SrNumberOfbooks[_consistencyNo][_pollingstationNo][_book].SrNumberOfbooksFrom,SrNumberOfbooks[_consistencyNo][_pollingstationNo][_book].SrNumberOfbooksTo);
    }
    function getBallotPapper(uint _pollingstationNo ,uint _consistencyNo,uint _papper) public returns(uint,uint){
        return ( SrNOfBallotPappers[_consistencyNo][_pollingstationNo][_papper].SrNumberOfBallotPapperFrom,SrNOfBallotPappers[_consistencyNo][_pollingstationNo][_papper].SrNumberOfBallotPapperTo);
    }
    function getUnissuedBP(uint _pollingstationNo ,uint _consistencyNo,uint _UnissuedBP) public returns(uint,uint){
        return ( UNISSUEDBALLOTPAPERS[_consistencyNo][_pollingstationNo][_UnissuedBP].SrNumberOfUnissuedBallotPapperFrom,UNISSUEDBALLOTPAPERS[_consistencyNo][_pollingstationNo][_UnissuedBP].SrNumberOfUnissuedBallotPapperTo);
    }
}