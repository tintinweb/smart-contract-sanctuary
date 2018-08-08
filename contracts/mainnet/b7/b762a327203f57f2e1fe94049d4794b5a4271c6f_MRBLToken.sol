pragma solidity ^0.4.21;
// We have to specify what version of compiler this code will compile with


contract MarbleEarth {


  struct NewMoon {

    uint timeAdded;
    MoonType moonType;
    uint64 votes;
    mapping (address => bool) supportMap;

  }


  enum MoonType { Verification, Purge}

  MRBLToken tokenContract;
  VerificationMoon verificationContract;
  PurgeMoon purgeContract;

  address[] addresses;
  bytes32[] identities;
  mapping (address => bytes32) voterMap;

  mapping (address => NewMoon) public proposedMoons;
  address[] public proposedMoonsIndex;

  address public verificationAddress;
  address public purgeAddress;
  address public tokenAddress;

  address public lastVerified;

//constructor

  function MarbleEarth(address verificationMoon, address purgeMoon) public {

    verificationMoon = verificationMoon;
    purgeMoon = purgeMoon;

  }

  function proposeNewMoon(address mAddress, MoonType moonType) public  {
    
    if ((block.timestamp - proposedMoons[proposedMoonsIndex[0]].timeAdded) > 172800) {

      delete proposedMoons[proposedMoonsIndex[0]];
      delete proposedMoonsIndex[0];

      }

    if (proposedMoonsIndex.length >= 1000) {
      return;
      }

      proposedMoons[mAddress] = NewMoon(block.timestamp, moonType, 1);
      proposedMoonsIndex.push(mAddress);

  }


  function supportNewMoon(address newMoonAddress) public {

    NewMoon storage newMoon = proposedMoons[newMoonAddress];

    if (!newMoon.supportMap[msg.sender]) {
      newMoon.supportMap[msg.sender] = true;
      newMoon.votes++;
      proposedMoons[newMoonAddress] = newMoon;
    }

    uint quotient = (newMoon.votes*100)/addresses.length;

    if (quotient >= 67) {
    
      replaceNewMoon(newMoon, newMoonAddress);
    }

  }

  function replaceNewMoon(NewMoon newMoon, address newMoonAddress) internal {

      if (newMoon.moonType == MoonType.Verification) {
       verificationAddress = newMoonAddress;
      }

      else if (newMoon.moonType == MoonType.Purge) {
        purgeAddress = newMoonAddress;
      }

      delete proposedMoons[newMoonAddress]; 

  }

  function proposePurge(address proposedAddress, bytes32 proof) public {

    purgeContract = PurgeMoon(purgeAddress);
    purgeContract.propose(proposedAddress, proof, addresses, identities);

  }

  function proposeVoter(bytes32 proof) public {

    verificationContract = VerificationMoon(verificationAddress);
    verificationContract.propose(msg.sender, proof, addresses, identities);

  }

  function addVoter(address voterAddress, address verifierAddress, bytes32 identity) public {
    
    if (msg.sender != verificationAddress)
      return;

    addresses.push(voterAddress);
    identities.push(identity);
    voterMap[voterAddress] = identity;

    tokenContract = MRBLToken(tokenAddress);
    tokenContract.transfer(voterAddress, newVoterAllocation());
    tokenContract.transfer(verifierAddress, verifierAllocation());
    lastVerified = voterAddress;

  }

  function getBalance() public returns (uint256) {
        tokenContract = MRBLToken(tokenAddress);            
        return tokenContract.getBalance(this);
    }

    function verifierAllocation() internal returns (uint) {
     
      uint contractBalance = getBalance();
      return (-contractBalance*addresses.length/100000000000 + 2*contractBalance/10000000000)*1/5;

    }

  function newVoterAllocation() internal returns (uint) {
            uint contractBalance = getBalance();
           if (addresses.length < 1000000) {runLottery(contractBalance); }

      return (-contractBalance*addresses.length/100000000000 + 2*contractBalance/10000000000)*4/5;

  }

  function runLottery(uint contractBalance) internal {

            bytes32 blockHash = block.blockhash(block.number);
            bytes32 randomHash = keccak256(lastVerified, blockHash);
            uint hashNumber = uint(randomHash);
     
        if (addresses.length < 1000 && hashNumber < 2**246) {
             tokenContract = MRBLToken(tokenAddress);
             tokenContract.transfer(lastVerified, contractBalance/5);
        }
        else if (hashNumber < 2**236)  {
             tokenContract = MRBLToken(tokenAddress);
             tokenContract.transfer(lastVerified, contractBalance/5);
       }

  }

  function purgeVoter(address purgedAddress, uint arrayIndex) public {
    
    if (msg.sender != purgeAddress)
      return;

    if (addresses[arrayIndex] != purgedAddress)
      return;

      delete addresses[arrayIndex];
      delete identities[arrayIndex];
      delete voterMap[purgedAddress];

  }

}


contract VerificationMoon {
  
    struct NewVoter {


      uint timeAdded;
      uint64 votes;
      bytes32 argument;
      mapping (address => bool) supportMap;


  }

  address public marbleEarthAddress;
  mapping (address => NewVoter) public proposedVoters;
  uint16 public numberOfProposed;
  address[] public voterAddresses;
  bytes32[] public voterIdentities;

  function propose(address selfProposed, bytes32 argument, address[] addresses, bytes32[] identities) public {

    if (msg.sender != marbleEarthAddress)
      return;

    voterAddresses = addresses;
    voterIdentities = identities;

    if (addresses.length == 0) {
        addVoter(selfProposed, selfProposed, argument);
    }
    else {

    NewVoter memory newVoter;
    newVoter.argument = argument;
    newVoter.timeAdded = block.timestamp;
    proposedVoters[selfProposed] = newVoter;

    }

  }

  function addVoter(address verifiedAddress,address verifierAddress, bytes32 argument) internal {

         MarbleEarth marbleEarth = MarbleEarth(marbleEarthAddress);
         marbleEarth.addVoter(verifiedAddress, verifierAddress, argument);

  }

  function supportNewVoter(address _address) public {

    if ((block.timestamp - proposedVoters[0].timeAdded) > 604800) {

      delete proposedVoters[0];
      numberOfProposed--;

      }

    if (numberOfProposed >= 1000) {

      return;

      }

    if (!proposedVoters[_address].supportMap[msg.sender]) {
      proposedVoters[_address].supportMap[msg.sender] = true;
      proposedVoters[_address].votes++;
      numberOfProposed++;

    }

    if (proposedVoters[_address].votes*100 / voterAddresses.length > 50) {

        addVoter(_address, msg.sender, proposedVoters[_address].argument);
        delete proposedVoters[_address];
        numberOfProposed--;

    }
  }
}

contract PurgeMoon {
  
    struct NewPurge {

      uint timeAdded;
      uint64 votes;
      bytes32 argument;
      mapping (address => bool) supportMap;

  }

  address public marbleEarthAddress;
  mapping (address => NewPurge) public proposedPurges;
  uint16 public numberOfProposed;
  address[] public voterAddresses;
  bytes32[] public voterIdentities;

  function propose(address proposed, bytes32 argument, address[] addresses, bytes32[] identities) public {

    if (msg.sender != marbleEarthAddress)
      return;

    voterAddresses = addresses;
    voterIdentities = identities;

    NewPurge memory newPurge;
    newPurge.argument = argument;
    newPurge.timeAdded = block.timestamp;
    proposedPurges[proposed] = newPurge;

  }

  function purgeVoter(address purgedAddress, uint arrayIndex) internal {

         MarbleEarth marbleEarth = MarbleEarth(marbleEarthAddress);
         marbleEarth.purgeVoter(purgedAddress, arrayIndex);

  }

  function supportNewPurge(address _address, uint arrayIndex) public {

    if ((block.timestamp - proposedPurges[0].timeAdded) > 604800) {

      delete proposedPurges[0];
      numberOfProposed--;

      }

    if (numberOfProposed >= 1000) {

      return;

      }

    if (!proposedPurges[_address].supportMap[msg.sender]) {
      proposedPurges[_address].supportMap[msg.sender] = true;
      proposedPurges[_address].votes++;
      numberOfProposed++;

    }

    if (proposedPurges[_address].votes*100 / voterAddresses.length > 50) {

        purgeVoter(_address, arrayIndex);
        delete proposedPurges[_address];
        numberOfProposed--;

    }
  }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract MRBLToken {
    string public name = "Marble";
    string public symbol = "MRBL";
    uint256 public decimals = 18;
    uint256 public totalSupply = 100*1000*1000*1000*10**decimals;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    function MRBLToken() public {
        balanceOf[msg.sender] = totalSupply;                
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function getBalance(address _address) view public returns (uint256) {
        return balanceOf[_address];
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
}