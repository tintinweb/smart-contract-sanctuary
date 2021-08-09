/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


    // 0.01 ether contributors Address and details are stored ________________ Completed;
    
    // set time limit for registration ____________________________ inProgress;
/* taking ideas from FirstBlood token */
contract Math {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

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
}

contract Token {
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



/*  ERC 20 token */
contract StandardToken is Token {
    
    mapping (address => uint256) balances;
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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
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

    
    
contract citizenRegister is StandardToken , Math {
    
    address public  proposer; // address of the proposer
    
    uint  public currentBalance;
    
    uint  endApplicationRegister;
    
    mapping(address => uint)public contributions;
    
    
    constructor (uint _endApplicationRegister, uint _totalSupply){
        proposer = msg.sender;
        endApplicationRegister = _endApplicationRegister;
        totalSupply = _totalSupply;
    }
    
    modifier _onlyProposer(){
        proposer = msg.sender;
        _;
    }
    
    struct Applicant {
        address contributorsAddress;
        uint amount;
        uint applicantID;
        string eMailID;
    }
    Applicant[]  applicants;
    uint nextId = 1;
    
    address[] public Address;
    
    //  15000000
    modifier _checkStatus(){
        require(block.timestamp < endApplicationRegister , "applicantRegistryCompleted");
        _;
    }
    
    event success(string registered_eMailID);
    error failure(string failedToRegister);
        // public function payable application fee and applicant registry
    
    function applicationForCitizenship(string memory _eMailID) public payable   { 
        require(block.timestamp <= endApplicationRegister, "contract expired");
        if ((msg.value <= 0.015 ether) && msg.value >= 0.0148 ether){ 
        payable(proposer).transfer(msg.value);
        Address.push(msg.sender);
        contributions[msg.sender] = contributions[msg.sender] + (msg.value);
        currentBalance = currentBalance + (msg.value);
        applicants.push(Applicant({contributorsAddress : (msg.sender),amount : (msg.value), applicantID : nextId, eMailID : _eMailID}));
        nextId++;
        emit success(_eMailID); 
        }   else {
            revert();
        }  
    }
    
        // private function for only proposer to view the applicantDetails
        // in order to maintain user privacy contributors E-Mail address kept private
    function applicantDetails(address contributorsAddress) public _onlyProposer  returns (bool registered,address addr,uint citizenID, string memory eMailID) {
        for (uint i=0 ; i < applicants.length ; i++) {
            if (applicants[i].contributorsAddress == contributorsAddress ){
                return (true,applicants[i].contributorsAddress, applicants[i].applicantID, applicants[i].eMailID);
            } 
        }
    }
    
    // this functions sends the tokens to the contributors Address after the citizenRegistry contract Expiry
    function sendTokens() public payable {
        // require(block.timestamp >= endApplicationRegister, "Contract need to expire");
        require(contributions[msg.sender] >0, "You are Not a Contributor");
        uint amount = 100;
        balances[msg.sender] += amount;
    }
}