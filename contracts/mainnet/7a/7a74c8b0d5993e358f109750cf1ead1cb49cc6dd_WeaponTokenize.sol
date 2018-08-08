pragma solidity ^0.4.17;

// source : https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
}

contract WeaponTokenize {
    /*  State variables */
    address public owner;
    uint[] weaponList;
    address[] authorizedOwners;

    /* mappings */
    mapping (uint => string) gameDataOf;
    mapping (uint => string) publicDataOf;
    mapping (uint => string) ownerDataOf;
    mapping (uint => address) ownerOf;
    
    mapping (address => bool) isAuthorizedOwner;
    


    /* Events */
    event WeaponAdded(uint indexed weaponId, string gameData, string publicData, string ownerData);
    event WeaponUpdated(uint indexed weaponId, string gameData, string publicData, string ownerData);
    event OwnershipTransferred(address indexed _oldOwner, address indexed _newOwner);
    event WeaponOwnerUpdated (uint indexed  _weaponId, address indexed  _oldOwner, address indexed  _newOwner);
    event AuthorizedOwnerAdded(address indexed _addeduthorizedOwner);
    event AuthorizedOwnerRemoved(address indexed _removedAuthorizedOwner);  
    
    /* Modifiers */    
    modifier onlyOwnerOfContract() { 
      require(msg.sender == owner);
      _; 
    }

    modifier onlyAuthorizedOwner() { 
     require(isAuthorizedOwner[msg.sender]);
     _;
    }
    
     
    /*  constructor */
    function WeaponTokenize () public {
      owner = msg.sender;
      isAuthorizedOwner[msg.sender] =  true;
      authorizedOwners.push(msg.sender);

    }

    //////////////////////////////////////////
    // OWNER SPECIFIC FUNCTIONS
    //////////////////////////////////////////

    /* Add authrized owners */
    function addAuthorizedOwners (address _newAuthorizedUser) public onlyOwnerOfContract returns(bool res) {
      require(!isAuthorizedOwner[_newAuthorizedUser]);
      isAuthorizedOwner[_newAuthorizedUser] =  true;
      authorizedOwners.push(_newAuthorizedUser);
      emit AuthorizedOwnerAdded(_newAuthorizedUser);
      return true;
    }
    
    /*  Remove authorized users */
    function removeAuthorizeduser(address _authorizedUser) public onlyOwnerOfContract returns(bool res){
        require(isAuthorizedOwner[_authorizedUser]);
        delete(isAuthorizedOwner[_authorizedUser]);
        for(uint i=0; i< authorizedOwners.length;i++){
          if(authorizedOwners[i] == _authorizedUser){
            delete authorizedOwners[i];
            break;
          }
        }
        emit AuthorizedOwnerRemoved(_authorizedUser);
        return true;
    }

    /* Change ownership */
    function transferOwnership (address _newOwner) public onlyOwnerOfContract returns(bool res) {
      owner = _newOwner;
      emit OwnershipTransferred(msg.sender, _newOwner);
      return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwnerOfContract returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _value);
    }
    
    

    //////////////////////////////////////////
    // AUTHORIZEED USERS FUNCTIONALITY
    //////////////////////////////////////////

    /* Add weapon */
    function addWeapon (uint _id, string _gameData, string _publicData, string _ownerData, address _ownerAddrress) public onlyAuthorizedOwner returns(bool res) {
      gameDataOf[_id] = _gameData;
      publicDataOf[_id] = _publicData;
      ownerDataOf[_id] = _ownerData;
      ownerOf[_id] =  _ownerAddrress;
      weaponList.push(_id);
      emit WeaponAdded(_id, _gameData, _publicData, _ownerData);
      return true;
    }

    /* update all weapon details */
    function updateWeapon (uint _id, string _gameData, string _publicData, string _ownerData) public onlyAuthorizedOwner returns(bool res) {
      gameDataOf[_id] = _gameData;
      publicDataOf[_id] = _publicData;
      ownerDataOf[_id] = _ownerData;
      //emit WeaponAdded(_id, _gameData, _publicData, _ownerData);
      return true;
    }

    /*  update game proprietary data */
    function updateGameProprietaryData (uint _id, string _gameData) public onlyAuthorizedOwner returns(bool res) {
      gameDataOf[_id] = _gameData;
      emit WeaponUpdated(_id, _gameData, "", "");
      return true;
    }

    /* update public data */
    function updatePublicData (uint _id,  string _publicData) public onlyAuthorizedOwner returns(bool res) {
      publicDataOf[_id] = _publicData;
      emit WeaponUpdated(_id, "", _publicData, "");
      return true;
    }

    /* update owner proprietary data */
    function updateOwnerProprietaryData (uint _id, string _ownerData) public onlyAuthorizedOwner returns(bool res) {
      ownerDataOf[_id] = _ownerData;
      emit WeaponUpdated(_id, "", "", _ownerData);
      return true;
    }

    /* change owner of weapon */
    function updateOwnerOfWeapon (uint _id, address _newOwner) public onlyAuthorizedOwner returns(bool res) {
      address oldOwner = ownerOf[_id];
      ownerOf[_id] =  _newOwner;
      emit WeaponOwnerUpdated(_id, oldOwner, _newOwner);
      return true;
    }
    

    //////////////////////////////////////////
    // PUBLICLY ACCESSIBLE METHODS (CONSTANT)
    //////////////////////////////////////////

    /* Get Weapon Data */
    function getGameProprietaryData (uint _id) public view returns(string _gameData) {
      return gameDataOf[_id];
    }

    function getPublicData (uint _id) public view returns(string _pubicData) {
      return publicDataOf[_id];
    }

    function getOwnerProprietaryData (uint _id) public view returns(string _ownerData) {
      return ownerDataOf[_id] ;
    }

    function getAllWeaponData (uint _id) public view returns(string _gameData,string _pubicData,string _ownerData ) {
      return (gameDataOf[_id], publicDataOf[_id], ownerDataOf[_id]);
    }

    function getOwnerOf (uint _weaponId) public view returns(address _owner) {
      return ownerOf[_weaponId];
    }

    function getWeaponList () public view returns(uint[] tokenizedWeapons) {
      return weaponList;
    }

    function getAuthorizedOwners () public view returns(address[] authorizedUsers) {
      return authorizedOwners;
    }
    

    // ------------------------------------------------------------------------
    // Prevents contract from accepting ETH
    // ------------------------------------------------------------------------
    function () public payable {
      revert();
    }

}