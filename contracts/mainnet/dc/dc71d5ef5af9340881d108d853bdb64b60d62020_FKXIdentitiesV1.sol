pragma solidity ^0.4.21;

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
// END OF library SafeMath

contract Roles {
    // Master Key access, always ONE and ONE ONLY 
    address public superAdmin ;

    address public canary ; 


    // initiators and validators can be many
    mapping (address => bool) public initiators ; 
    mapping (address => bool) public validators ;  
    address[] validatorsAcct ; 

    // keep track of the current qty. of initiators around 
    uint public qtyInitiators ; 

    // hard-code the max amount of validators/voters in the system 
    // this is required to initialize the storage for each new proposal 
    uint constant public maxValidators = 20 ; 

    // keep track of the current qty. of active validators around 
    uint public qtyValidators ; 

    event superAdminOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event initiatorAdded(address indexed newInitiator);
    event validatorAdded(address indexed newValidator);
    event initiatorRemoved(address indexed removedInitiator);
    event validatorRemoved(address indexed addedValidator);
    event canaryOwnershipTransferred(address indexed previousOwner, address indexed newOwner) ; 


    
    constructor() public 
    { 
      superAdmin = msg.sender ;
      
    }

    modifier onlySuperAdmin {
        require( msg.sender == superAdmin );
        _;
    }

    modifier onlyCanary {
        require( msg.sender == canary );
        _;
    }

    modifier onlyInitiators {
        require( initiators[msg.sender] );
        _;
    }
    
    modifier onlyValidators {
        require( validators[msg.sender] );
        _;
    }
    

function transferSuperAdminOwnership(address newOwner) public onlySuperAdmin 
{
  require(newOwner != address(0)) ;
  superAdmin = newOwner ;
  emit superAdminOwnershipTransferred(superAdmin, newOwner) ;  
}

function transferCanaryOwnership(address newOwner) public onlySuperAdmin 
{
  require(newOwner != address(0)) ;
  canary = newOwner ;
  emit canaryOwnershipTransferred(canary, newOwner) ;  
}


function addValidator(address _validatorAddr) public onlySuperAdmin 
{
  require(_validatorAddr != address(0));
  require(!validators[_validatorAddr]) ; 
  validators[_validatorAddr] = true ; 
  validatorsAcct.push(_validatorAddr) ; 
  qtyValidators++ ; 
  emit validatorAdded(_validatorAddr) ;  
}

function revokeValidator(address _validatorAddr) public onlySuperAdmin
{
  require(_validatorAddr != address(0));
  require(validators[_validatorAddr]) ; 
  validators[_validatorAddr] = false ; 
  
  for(uint i = 0 ; i < qtyValidators ; i++ ) 
    {
      if (validatorsAcct[i] == _validatorAddr)
         validatorsAcct[i] = address(0) ; 
    }
  qtyValidators-- ; 
  emit validatorRemoved(_validatorAddr) ;  
}

function addInitiator(address _initiatorAddr) public onlySuperAdmin
{
  require(_initiatorAddr != address(0));
  require(!initiators[_initiatorAddr]) ;
  initiators[_initiatorAddr] = true ; 
  qtyInitiators++ ; 
  emit initiatorAdded(_initiatorAddr) ; 
}

function revokeInitiator(address _initiatorAddr) public onlySuperAdmin
{
  require(_initiatorAddr != address(0));
  require(initiators[_initiatorAddr]) ; 
  initiators[_initiatorAddr] = false ;
  qtyInitiators-- ; 
  emit initiatorRemoved(_initiatorAddr) ; 
}
  

} // END OF Roles contract 


contract Storage {

  // We store here the whole storage implementation, decoupling the logic 
  // which will be defined in FKXIdentitiesV1, FKXIdentitiesV2..., FKXIdentitiesV1n

uint scoringThreshold ; 

struct Proposal 
  {
    string ipfsAddress ; 
    uint timestamp ; 
    uint totalAffirmativeVotes ; 
    uint totalNegativeVotes ; 
    uint totalVoters ; 
    address[] votersAcct ; 
    mapping (address => uint) votes ; 
  }

// storage to keep track of all the proposals 
mapping (bytes32 => Proposal) public proposals ; 
uint256 totalProposals ; 

// helper array to keep track of all rootHashes proposals
bytes32[] rootHashesProposals ; 


// storage records the final && immutable ipfsAddresses validated by majority consensus of validators
mapping (bytes32 => string) public ipfsAddresses ; 

// Helper vector to track all keys (rootHasshes) added to ipfsAddresses
bytes32[] ipfsAddressesAcct ;

}


contract Registry is Storage, Roles {

    address public logic_contract;

    function setLogicContract(address _c) public onlySuperAdmin returns (bool success){
        logic_contract = _c;
        return true;
    }

    function () payable public {
        address target = logic_contract;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}


contract FKXIdentitiesV1 is Storage, Roles {

using SafeMath for uint256;

event newProposalLogged(address indexed initiator, bytes32 rootHash, string ipfsAddress ) ; 
event newVoteLogged(address indexed voter, bool vote) ;
event newIpfsAddressAdded(bytes32 rootHash, string ipfsAddress ) ; 


constructor() public 
{
  qtyInitiators = 0 ; 
  qtyValidators = 0 ; 
  scoringThreshold = 10 ;
}

// Set the score parameter that once reached would eliminate/revoke
// validators with scores greater than _scoreMax from the list of authorized validators
function setScoringThreshold(uint _scoreMax) public onlySuperAdmin
{
  scoringThreshold = _scoreMax ; 
}


// An initiator writes a new proposal in the proposal storage area 

function propose(bytes32 _rootHash, string _ipfsAddress) public onlyInitiators
{
  // proposal should not be present already, i.e timestamp has to be in an uninitialized state, i.e. zero 
  require(proposals[_rootHash].timestamp == 0 ) ;

  // writes the proposal for the _ipfsAddress, timestamp it &#39;now&#39; and set the qty to zero (i.e. no votes yet)
  address[] memory newVoterAcct = new address[](maxValidators) ; 
  Proposal memory newProposal = Proposal( _ipfsAddress , now, 0, 0, 0, newVoterAcct ) ; 
  proposals[_rootHash] = newProposal ; 
  emit newProposalLogged(msg.sender, _rootHash, _ipfsAddress ) ; 
  rootHashesProposals.push(_rootHash) ; 
  totalProposals++ ; 
}


// obtain, for a given rootHash, the definitive immutable stored _ipfsAddress 
function getIpfsAddress(bytes32 _rootHash) constant public returns (string _ipfsAddress)
{
  return ipfsAddresses[_rootHash] ; 
}

// obtain, for a given rootHash, the proposed (not definitively voted yet) _ipfsAddress
function getProposedIpfs(bytes32 _rootHash) constant public returns (string _ipfsAddress)
{
  return proposals[_rootHash].ipfsAddress ; 
}

// how many voters have voted for a given proposal? 
function howManyVoters(bytes32 _rootHash) constant public returns (uint)
{
  return proposals[_rootHash].totalVoters ; 
}

// Validator casts one vote to the proposed ipfsAddress stored in the _rootHash key in the proposals storage area 
// if _vote == true means voting affirmatively, else if _vote == false, means voting negatively
function vote(bytes32 _rootHash, bool _vote) public onlyValidators
{
  // if timestamp == 0 it means such proposal does not exist, i.e. was never timestamped hence 
  //  contains the &#39;zero&#39; uninitialized value
  require(proposals[_rootHash].timestamp > 0) ;

  // checks this validator have not already voted for this proposal
  // 0 no voted yet
  // 1 voted affirmatively
  // 2 voted negatively 

  require(proposals[_rootHash].votes[msg.sender]==0) ; 

  // add this validator address to the array of voters. 
  proposals[_rootHash].votersAcct.push(msg.sender) ; 

  if (_vote ) 
    { 
      proposals[_rootHash].votes[msg.sender] = 1 ; // 1 means votes affirmatively
      proposals[_rootHash].totalAffirmativeVotes++ ; 
    } 
       else 
        { proposals[_rootHash].votes[msg.sender] = 2 ; // 2 means votes negatively
          proposals[_rootHash].totalNegativeVotes++ ; 
        } 

  emit newVoteLogged(msg.sender, _vote) ;
  proposals[_rootHash].totalVoters++ ; 

  // check if a majority consensus was obtained and if so, it records the final result in the definitive 
  // immutable storage area: ipfsAddresses 
  if ( isConsensusObtained(proposals[_rootHash].totalAffirmativeVotes) )
  {
  // need to make sure the consensuated vote had not already been written to the storage area ipfsAddresses
  // so we don&#39;t write duplicate info again, just to save some gas :) and also b/c it&#39;s the right thing to do 
  // to minimize entropy in the universe... hence, we need to check for an empty string
    bytes memory tempEmptyString = bytes(ipfsAddresses[_rootHash]) ; 
    if ( tempEmptyString.length == 0 ) 
      { 
        ipfsAddresses[_rootHash] = proposals[_rootHash].ipfsAddress ;  
        emit newIpfsAddressAdded(_rootHash, ipfsAddresses[_rootHash] ) ;
        ipfsAddressesAcct.push(_rootHash) ; 

      } 

  }

} 


// returns the total number of ipfsAddresses ever stored in the definitive immutable storage &#39;ipfsAddresses&#39;
function getTotalQtyIpfsAddresses() constant public returns (uint)
{ 
  return ipfsAddressesAcct.length ; 
}

// returns one rootHash which is stored at a specific _index position
function getOneByOneRootHash(uint _index) constant public returns (bytes32 _rootHash )
{
  require( _index <= (getTotalQtyIpfsAddresses()-1) ) ; 
  return ipfsAddressesAcct[_index] ; 
}

// consensus obtained it is true if and only if n+1 validators voted affirmatively for a proposal 
// where n == the total qty. of validators (qtyValidators)
function isConsensusObtained(uint _totalAffirmativeVotes) constant public returns (bool)
{
 // multiplying by 10000 (10 thousand) for decimal precision management
 // note: This scales up to 9999 validators only

 require (qtyValidators > 0) ; // prevents division by zero 
 uint dTotalVotes = _totalAffirmativeVotes * 10000 ; 
 return (dTotalVotes / qtyValidators > 5000 ) ;

}


// Validators:
// returns one proposal (the first one) greater than, STRICTLY GREATER THAN the given _timestampFrom 
// timestamp > _timestampFrom 
function getProposals(uint _timestampFrom) constant public returns (bytes32 _rootHash)
{
   // returns the first rootHash corresponding to a timestamp greater than the parameter 
   uint max = rootHashesProposals.length ; 

   for(uint i = 0 ; i < max ; i++ ) 
    {
      if (proposals[rootHashesProposals[i]].timestamp > _timestampFrom)
         return rootHashesProposals[i] ; 
    }

}

// returns, for one proposal 
// identified by a rootHash, the timestamp UNIX epoch time associated with it

function getTimestampProposal(bytes32 _rootHash) constant public returns (uint _timeStamp) 
{
  return proposals[_rootHash].timestamp ; 
}



// returns the total quantity of active validators
// only &#39;active&#39; ones quantity  
function getQtyValidators() constant public returns (uint)
{
  return qtyValidators ; 
}

// It returns the address of an active validator in the specific &#39;_t&#39; vector position of active validators 
// vector positions start at zero and ends at &#39;getQtyValidators - 1&#39; so in order to get all vaidators 
// you have to iterate one by one from 0 to &#39; getQtyValidators -1 &#39;
function getValidatorAddress(int _t) constant public returns (address _validatorAddr)
{
   int x = -1 ; 
   uint size = validatorsAcct.length ; 

   for ( uint i = 0 ; i < size ; i++ )
   {

      if ( validators[validatorsAcct[i]] ) x++ ; 
      if ( x == _t ) return (validatorsAcct[i]) ;  
   }
}
 
// returns true if the rootHash was impacted, i.e. it&#39;s available and exists in the ipfsAddresses array
// and false if otherwise

function getStatusForRootHash(bytes32 _rootHash) constant public returns (bool)
{
 bytes memory tempEmptyStringTest = bytes(ipfsAddresses[_rootHash]); // Uses memory
 if (tempEmptyStringTest.length == 0) {
    // emptyStringTest is an empty string, hence the _rootHash was not impacted there so does not exist
    return false ; 
} else {
    // emptyStringTest is not an empty string
    return true ; 
}

} 

} // END OF FKXIdentities contract 


// DEBUG info below IGNORE 
// rootHash examples below, always 32 bytes in the format:
// 0x12207D5A99F603F231D53A4F39D1521F98D2E8BB279CF29BEBFD0687DC98458E
// 0x12207D5A99F603F231D53A4F39D1521F98D2E8BB279CF29BEBFD0687DC98458F
// ipfs address, string: "whatever here",

// JUN-5 v1 contract deployed at https://rinkeby.etherscan.io/address/0xbe2ee825339c25749fb8ff8f6621d304fb2e2be5
// JUN-5 v1 contract deployed at https://ropsten.etherscan.io/address/0xbe2ee825339c25749fb8ff8f6621d304fb2e2be5

// SuperOwner account is: 0xFA8f851b63E3742Eb5909C0735017C75b999B043 (macbook chrome)


// returns the vote status for a given proposal for a specific validator Address 
// 0 no voted yet / blank vote 
// 1 voted affirmatively
// 2 voted negatively 
// function getVoterStatus(bytes32 _rootHash, address _validatorAddr) constant public returns (uint _voteStatus)
// {

 // proposals[_rootHash].votes[_validatorAddr] ; 

// }