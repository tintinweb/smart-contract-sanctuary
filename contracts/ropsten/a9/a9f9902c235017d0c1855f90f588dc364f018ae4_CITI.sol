/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;


    // 0.01 ether contributors Address and details are stored ________________ Completed;
    
    // set time limit for registration ____________________________ inProgress;

contract Math {

    
    function Add(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function Sub(uint256 x, uint256 y) internal pure returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function Mul(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    function Div(uint256 x, uint256 y)internal pure returns(uint256){
        uint256 z = x / y;
        assert(x != 0 && y != 0);
        return z;
    }
    
}



contract Token {
    uint256 public totalSupply;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

/*  ERC 20 token */
contract StandardToken is Token {
    
    mapping (address => uint256)public balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function transfer(address _to, uint256 _value) public  returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address Addr) public view returns (uint256 balance) {
        return balances[Addr];
    }

    function approve(address _spender, uint256 _value)public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    
}


contract CITI is StandardToken , Math {
    
    // metadata
    string public constant name = "Decentalised Citizen Token";
    string public constant symbol = "CITI";
    uint256 public constant decimals = 18;
    uint256 public endBlock = 10849000;
    uint256 public constant ETHExchangeRate = 10000; // 10000 DNC tokens per 1 ETH
    uint256 public constant MaxtokenCreation =  1 * (10**6) * 10**decimals;
    uint public currentBalance;
    address private creator = msg.sender; // address of the creator
    event CreateDCT(address indexed _to, uint256 _value);    
    mapping(address => uint)public contributions;
    
    
    
   /** modifier _onlyCreator(){
        require(creator == msg.sender,"only creator can view details");
        _;
    }*/
    
    struct Applicant {
        address contributorsAddress;
        uint amount;
        uint applicantID;
        string eMailID;
    }
    Applicant[] public Citizen;
    uint nextId = 1;
    
    address[] public Address;
    
    //  15000000
    //  14800000
    modifier _checkAddr(){
        for (uint i = 0; i < Address.length; i++){
        require(msg.sender != Address[i], "you are already registered");
        }
        _;
    }
    modifier _supplyCap{
        require(totalSupply <= MaxtokenCreation,"cannot create new tokens");
        _;
    }
    event success(uint applicantID);
    
    function citizenCount() public view returns(uint noOfCitizens){
        return noOfCitizens = Address.length;
    }
        /** public payable function applicationForCitizenship recieves ether
         * registers the msg.sender, creates and sends tokens to that Address in proportion to contribution
         * with in the preset timeStamp, ths creted tokens is the totalSupply
         * after the timeStamp only application fee is taken and registers the citizen but no new tokens are created.
         */
    uint tokens;
    function applicationForCitizenship(string memory _eMailID)  _checkAddr _supplyCap public payable   { 
        
        if(msg.value > 0.01 ether  && block.number < endBlock){
        payable(creator).transfer(msg.value);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        currentBalance = currentBalance + (msg.value);
        Citizen.push(Applicant({contributorsAddress : (msg.sender), amount : Div(msg.value,(10**14)), applicantID : nextId, eMailID : _eMailID}));
        nextId++;
        Address.push(msg.sender);
        uint newtokens = Div(msg.value,(10**14));
        balances[msg.sender] += newtokens;
        tokens = tokens + newtokens;
        totalSupply = tokens;
        emit success(nextId); 
        
    }   else if(block.number > endBlock && msg.value == 0.001 ether){
        //balances[msg.sender] -= 10;
        //balances[creator] += 10;
        Citizen.push(Applicant({contributorsAddress : (msg.sender), amount : (msg.value), applicantID : nextId, eMailID : _eMailID}));
        nextId++;
        Address.push(msg.sender);
        
        }
    }    
    
        // private function for only creator to view the applicantDetails
        // in order to maintain user privacy contributors E-Mail address kept private
    function applicantDetails(address contributorsAddress) internal view   returns (address addr /**,uint amount,uint citizenID, string memory eMailID*/) {
        for (uint i=0 ; i < Citizen.length ; i++) {
            if(Citizen[i].contributorsAddress == contributorsAddress ){
                return (Citizen[i].contributorsAddress/**, Citizen[i].amount, Citizen[i].applicantID, Citizen[i].eMailID*/);
            } 
        }
    }
    
    address public elector; // elected representative
    mapping(address => voter) public voters;
    mapping(address => uint) public fund;
    uint endReg;
    
    function setEnd(uint _endReg) public {
        endReg = _endReg;
    }
    struct proposal{
        uint proposalID;
        string projectName;
        address proposer;
        uint budget;
        uint voteCount;
    }
    struct voter {
        bool voted;
        uint voteIndex;
        uint weight;
    }
    proposal[] public proposals;
    uint nextProposalID = 1;
    
    modifier _onlyElector(){
        require (elector == msg.sender,"not a elector");
        _;
    }
    
    modifier _check(){
        require(block.number < endReg, "voting process completed");
        _;
    }
    event winner(uint proposalID,string  projectName,address proposer,uint budget, uint voteCount);
    
    function proposalRegistry(string memory _projectName, address _proposer, uint _budget) public _onlyElector  {
        proposals.push(proposal({proposalID : nextProposalID, projectName : _projectName, proposer : _proposer, budget : _budget, voteCount : 0 }));
        nextProposalID++;
    }
    
function vote(uint voteIndex) public {
        
        require(applicantDetails(msg.sender) == msg.sender, "winner not yet declared" );
        if(balances[msg.sender] > 0){
            require(!voters[msg.sender].voted,"you are already voted"); 
            voters[msg.sender].weight = 1; 
            voters[msg.sender].voted = true;
            voters[msg.sender].voteIndex = voteIndex;
            proposals[voteIndex].voteCount += voters[msg.sender].weight;
        } 
    }
    
    function winningProject() public view returns (address winningProposalAddress) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalAddress = proposals[i].proposer;
            }
        }
        
    }
    
    function fundProject() public  payable {
        payable(winningProject()).transfer(msg.value);
    }
    
    
}