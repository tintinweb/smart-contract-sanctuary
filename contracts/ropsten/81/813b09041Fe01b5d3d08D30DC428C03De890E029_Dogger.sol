pragma solidity ^0.4.15;

/*

  https://galleass.io
  by Austin Thomas Griffith

  The Dogger is the main fishing boat in Galleass.

*/




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract Galleasset is Ownable {

  address public galleass;

  constructor(address _galleass) public {
    galleass=_galleass;
  }

  function upgradeGalleass(address _galleass) public returns (bool) {
    require(msg.sender == galleass);
    galleass=_galleass;
    return true;
  }

  function getContract(bytes32 _name) public view returns (address){
    Galleass galleassContract = Galleass(galleass);
    return galleassContract.getContract(_name);
  }

  function hasPermission(address _contract,bytes32 _permission) public view returns (bool){
    Galleass galleassContract = Galleass(galleass);
    return galleassContract.hasPermission(_contract,_permission);
  }

  function getGalleassTokens(address _from,bytes32 _name,uint256 _amount) internal returns (bool) {
    return StandardTokenInterface(getContract(_name)).galleassTransferFrom(_from,address(this),_amount);
  }

  function getTokens(address _from,bytes32 _name,uint256 _amount) internal returns (bool) {
    return StandardTokenInterface(getContract(_name)).transferFrom(_from,address(this),_amount);
  }

  function approveTokens(bytes32 _name,address _to,uint256 _amount) internal returns (bool) {
    return StandardTokenInterface(getContract(_name)).approve(_to,_amount);
  }

  function withdraw(uint256 _amount) public onlyOwner isBuilding returns (bool) {
    require(address(this).balance >= _amount);
    assert(owner.send(_amount));
    return true;
  }
  function withdrawToken(address _token,uint256 _amount) public onlyOwner isBuilding returns (bool) {
    StandardTokenInterface token = StandardTokenInterface(_token);
    token.transfer(msg.sender,_amount);
    return true;
  }

  //this prevents old contracts from remaining active
  //if you want to disable functions after the contract is retired,
  //add this as a modifier
  modifier isGalleasset(bytes32 _name) {
    Galleass galleassContract = Galleass(galleass);
    require(address(this) == galleassContract.getContract(_name));
    _;
  }

  modifier isBuilding() {
    Galleass galleassContract = Galleass(galleass);
    require(galleassContract.stagedMode() == Galleass.StagedMode.BUILD);
    _;
  }

}


contract Galleass {
  function getContract(bytes32 _name) public constant returns (address) { }
  function hasPermission(address _contract, bytes32 _permission) public view returns (bool) { }
  enum StagedMode {PAUSED,BUILD,STAGE,PRODUCTION}
  StagedMode public stagedMode;
}

contract StandardTokenInterface {
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function galleassTransferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function transfer(address _to, uint256 _value) public returns (bool) { }
  function approve(address _spender, uint256 _value) public returns (bool) { }
}


//https://github.com/ethereum/EIPs/issues/721
// thanks to Dieter Shirley && http://axiomzen.co

contract NFT {

  function NFT() public { }

  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;

  function transfer(address _to,uint256 _tokenId) external {
      require(_to != address(0));
      require(_to != address(this));
      require(_owns(msg.sender, _tokenId));
      _transfer(msg.sender, _to, _tokenId);
  }
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
      ownershipTokenCount[_to]++;
      tokenIndexToOwner[_tokenId] = _to;
      if (_from != address(0)) {
          ownershipTokenCount[_from]--;
          delete tokenIndexToApproved[_tokenId];
      }
      emit NFTTransfer(_from, _to, _tokenId);
  }
  //
  //for some reason transactions never return a receipt if this is "Transfer" even though there is no conflict with the name
  // I have no effing clue what I&#39;m doing wrong but I had to rename this to "NFTTransfer" and it works now :(
  //
  event NFTTransfer(address from, address to, uint256 tokenId);

  function transferFrom(address _from,address _to,uint256 _tokenId) external {
      require(_to != address(0));
      require(_to != address(this));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));
      _transfer(_from, _to, _tokenId);
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToOwner[_tokenId] == _claimant;
  }
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToApproved[_tokenId] == _claimant;
  }
  function _approve(uint256 _tokenId, address _approved) internal {
      tokenIndexToApproved[_tokenId] = _approved;
  }

  function approve(address _to,uint256 _tokenId) external {
      require(_owns(msg.sender, _tokenId));
      _approve(_tokenId, _to);
      emit NFTApproval(msg.sender, _to, _tokenId);
  }
  //
  // see NFTTransfer for explanation on weird function name here
  //
  event NFTApproval(address owner, address approved, uint256 tokenId);

  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address owner) {
      owner = tokenIndexToOwner[_tokenId];
      require(owner != address(0));
  }

  function allowance(address _claimant, uint256 _tokenId) public view returns (bool) {
      return _approvedFor(_claimant,_tokenId);
  }
}


contract Dogger is Galleasset, NFT {

    string public constant name = "Galleass Dogger";
    string public constant symbol = "G_DOGGER";

    constructor(address _galleass) Galleasset(_galleass) public {
      //0 index should be a blank item owned by no one
      Item memory _item = Item({
        strength: 0,
        speed: 0,
        luck: 0,
        birth: 0
      });
      items.push(_item);
    }
    function () public {revert();}

    struct Item{
      uint16 strength;
      uint16 speed;
      uint8 luck;
      uint64 birth;
    }

    Item[] private items;

    function build() public isGalleasset("Dogger") returns (uint){
      require( hasPermission(msg.sender,"buildDogger") );
      require( getTokens(msg.sender,"Timber",2) );

      //when citizens are introduced to the game,
      //their level of craftsmanship will play a role
      //in the attrubutes, but for now, default
      uint16 strength = 1;
      uint16 speed = 512;
      uint8 luck = 1;

      Build(msg.sender,strength,speed,luck);
      return _create(msg.sender,strength,speed,luck);
    }
    event Build(address _sender,uint16 strength,uint16 speed,uint8 luck);


    function galleassetTransferFrom(address _from,address _to,uint256 _tokenId) external {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(_from, _tokenId));
        require(hasPermission(msg.sender,"transferDogger"));
        _transfer(_from, _to, _tokenId);
    }

    function _create(address _owner,uint16 strength,uint16 speed,uint8 luck) internal returns (uint){
        Item memory _item = Item({
          strength: strength,
          speed: speed,
          luck: luck,
          birth: uint64(now)
        });
        uint256 newId = items.push(_item) - 1;
        _transfer(0, _owner, newId);
        return newId;
    }

    function totalSupply() public view returns (uint) {
        return items.length - 1;
    }

    function getToken(uint256 _id) public view returns (address owner,uint16 strength,uint16 speed,uint8 luck,uint64 birth) {
      return (
        tokenIndexToOwner[_id],
        items[_id].strength,
        items[_id].speed,
        items[_id].luck,
        items[_id].birth
        );
    }

    function tokensOfOwner(address _owner) external view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;
            for (id = 1; id <= total; id++) {
                if (tokenIndexToOwner[id] == _owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }
            return result;
        }
    }
}