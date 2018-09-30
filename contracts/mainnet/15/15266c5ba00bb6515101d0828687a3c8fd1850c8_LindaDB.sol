contract LindaDB {

  struct Identity {
    uint entityData;
    bytes32 gender;
    bytes32 firstName;
    bytes32 lastName;
    bytes32 nationality;
    bytes32 imageUrl;
    bytes32 socialUrl;
    bytes32 homeplace;
    uint256 birthdate;
    bool isEntity;
  }

  mapping(address => Identity) public IdentityStructs;
  mapping(address => address) public IdentityToDad;
  mapping(address => address) public IdentityToMom;
  mapping(address => address) public testimonies;
  
  event NewIdentity(uint id);  
  
  address[] public identityList;

  function isEntity(address entityAddress) public constant returns(bool isIndeed) {
      return IdentityStructs[entityAddress].isEntity;
  }
  
  function getMom(address identityAddress) public constant returns(address isIndeed) {
      return IdentityToMom[identityAddress];
  }
  
  function getDad(address identityAddress) public constant returns(address isIndeed) {
      return IdentityToDad[identityAddress];
  }

  function getEntityCount() public constant returns(uint entityCount) {
    return identityList.length;
  }

  function newIdentityL1(
      address entityAddress, 
      bytes32 gender,
      bytes32 firstName,
      bytes32 lastName,
      bytes32 nationality, 
      uint256 birthdate )
    public returns(uint rowNumber) {
        
    if(isEntity(entityAddress)) throw;

    IdentityStructs[entityAddress].gender = gender;
    IdentityStructs[entityAddress].firstName = firstName;
    IdentityStructs[entityAddress].lastName = lastName;
    IdentityStructs[entityAddress].nationality = nationality;
    IdentityStructs[entityAddress].birthdate = birthdate;
    
    IdentityStructs[entityAddress].isEntity = true;
    NewIdentity(rowNumber);
    return identityList.push(entityAddress) - 1;
  }

  function updateIdentityImageURL(
    address entityAddress,
    bytes32 imageUrl)
    public returns(bool success) {
        
    if(!isEntity(entityAddress)) throw;
    IdentityStructs[entityAddress].imageUrl = imageUrl;
    return true;
  }
  
  function updateIdentitySocialURL(
    address entityAddress,
    bytes32 socialUrl)
    public returns(bool success) {
        
    if(!isEntity(entityAddress)) throw;
    IdentityStructs[entityAddress].socialUrl = socialUrl;
    return true;
  }
  
  function addMomRelation(
      address momAddress
      )
    public returns(bool success) {
        require(getMom(msg.sender) == 0x0000000000000000000000000000000000000000);
        IdentityToMom[msg.sender] = momAddress;
        return true;
    }
    
  function addDadRelation(
      address dadAddress
      )
    public returns(bool success) {
        require(getDad(msg.sender) == 0x0000000000000000000000000000000000000000);
        IdentityToDad[msg.sender] = dadAddress;
        return true;
    }
    
  function addTestimony(
      address testimonyAddress
      )
    public returns(bool success) { 
        testimonies[msg.sender] = testimonyAddress;
        return true;
    }

}