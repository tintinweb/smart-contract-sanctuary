pragma solidity ^0.4.15;

/*

  https://galleass.io
  by Austin Thomas Griffith

  The Land contract tracks all the procedurally generated islands in Galleass.

  Tiles can be purchased and built upon.

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


/*

  https://galleass.io
  by Austin Thomas Griffith

  The DataParser library is extended to help parse ERC677 data
  Usually you parse out the x,y,tile then, there is a field or two
   of arbitrary value, then you take the remaining bytes to get
   a dyanmic sized set of data for a while bytes32 or uint256
*/


contract DataParser{

  function getX(bytes _data) internal constant returns (uint16 _x){
    return uint16(_data[1]) << 8 | uint16(_data[2]);
  }

  function getY(bytes _data) internal constant returns (uint16 _y){
    return uint16(_data[3]) << 8 | uint16(_data[4]);
  }

  function getTile(bytes _data) internal constant returns (uint8 _tile){
    return uint8(_data[5]);
  }

  function getRemainingBytesLeadingZs(uint8 _offset, bytes _data) internal constant returns (bytes32 result){
    uint8 b = 31;
    uint8 d = uint8(_data.length-1);
    while(d>_offset-1){
      result |= bytes32(_data[d--] & 0xFF) >> (b-- * 8);
    }
    return result;
  }


  function getRemainingBytesTrailingZs(uint _offset,bytes _data) internal constant returns (bytes32 result) {
    for (uint i = 0; i < 32; i++) {
      uint8 adjusted = uint8(_offset + i);
      if(adjusted<_data.length){
          result |= bytes32(_data[adjusted] & 0xFF) >> (i * 8);
      }else{
          result |= bytes32(0x00) >> (i * 8);
      }
    }
    return result;
  }

  function getRemainingUint(uint8 _offset,bytes _data) internal constant returns (uint) {
    uint result = 0;
    uint endsAt = _data.length;
    uint8 d = uint8(endsAt-1);
    while(d>_offset-1){
      uint c = uint(_data[d]);
      uint to_inc = c * ( 16 ** ((endsAt - d-1) * 2));
      result += to_inc;
      d--;
    }
    return result;
  }

  function getAddressFromBytes(uint8 _offset,bytes _data) internal constant returns (address) {
    uint result = 0;
    uint endsAt = _offset+20;
    uint8 d = uint8(endsAt-1);
    while(d>_offset-1){
      uint c = uint(_data[d]);
      uint to_inc = c * ( 16 ** ((endsAt - d-1) * 2));
      result += to_inc;
      d--;
    }
    return address(result);
  }


}


contract LandLib is Galleasset, DataParser {

  mapping (bytes32 => uint16) public tileTypes;

  constructor(address _galleass) public Galleasset(_galleass) {
    //this is mainly just for human reference and to make it easier to track tiles mentally
    //it&#39;s expensive and probably won&#39;t be included in production contracts
    tileTypes["Water"]=0;

    tileTypes["MainHills"]=1;
    tileTypes["MainGrass"]=2;
    tileTypes["MainStream"]=3;

    tileTypes["Grass"]=50;
    tileTypes["Forest"]=51;
    tileTypes["Mountain"]=52;
    tileTypes["CopperMountain"]=53;
    tileTypes["SilverMountain"]=54;

    tileTypes["Harbor"]=100;
    tileTypes["Fishmonger"]=101;
    tileTypes["Market"]=102;

    tileTypes["TimberCamp"]=150;

    tileTypes["Village"]=2000;
    tileTypes["Castle"]=2010;
  }
  function () public {revert();}

  function setTileType(uint16 _tile,bytes32 _name) onlyOwner isBuilding public returns (bool) {
    tileTypes[_name] = _tile;
  }

  //erc677 receiver
  function onTokenTransfer(address _sender, uint _amount, bytes _data) public isGalleasset("LandLib") returns (bool) {
    TokenTransfer(msg.sender,_sender,_amount,_data);
    uint8 action = uint8(_data[0]);
    if(action==1){
      return _buyTile(_sender,_amount,_data);
    } else if(action==2){
      return _buildTimberCamp(_sender,_amount,_data);
    } else if(action==3){
      return _extractRawResource(_sender,_amount,_data);
    } else if(action==3){
      return _extractRawResource(_sender,_amount,_data);
    }
    return false;
  }
  event TokenTransfer(address token,address sender,uint amount,bytes data);

  function _buyTile(address _sender, uint _amount, bytes _data) internal returns (bool) {
    Land landContract = Land(getContract("Land"));
    address copperContractAddress = getContract("Copper");
    require(msg.sender == copperContractAddress);
    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);
    //must be for sale
    require(landContract.priceAt(_x,_y,_tile)>0);
    //must send at least enough as the price
    require(_amount>=landContract.priceAt(_x,_y,_tile));
    //transfer the copper to the Land Owner
    StandardToken copperContract = StandardToken(copperContractAddress);
    require(copperContract.transfer(landContract.ownerAt(_x,_y,_tile),_amount));
    //set the new owner to the sender
    landContract.setOwnerAt(_x,_y,_tile,_sender);
    //when a piece of land is purchased, an "onPurchase" function is called
    // on the contract to help the inner contract track events and owners etc
    if(landContract.contractAt(_x,_y,_tile)!=address(0)){
      StandardTile tileContract = StandardTile(landContract.contractAt(_x,_y,_tile));
      tileContract.onPurchase(_x,_y,_tile,landContract.ownerAt(_x,_y,_tile),landContract.priceAt(_x,_y,_tile));
    }
    //clear the price so it isn&#39;t for sale anymore
    landContract.setPriceAt(_x,_y,_tile,0);
    return true;
  }

  function buildTile(uint16 _x, uint16 _y,uint8 _tile,uint16 _newTileType) public isGalleasset("LandLib") returns (bool) {
    Land landContract = Land(getContract("Land"));
    //must be the owner of the tile to build here
    require(msg.sender==landContract.ownerAt(_x,_y,_tile));
    //get the current type of tile here to see what can be built on it
    uint16 tileType = landContract.tileTypeAt(_x,_y,_tile);
    if(tileType==tileTypes["MainHills"]||tileType==tileTypes["MainGrass"]){
      //they want to build on a main, blank spot whether hills or grass
      if(_newTileType==tileTypes["Village"]){
        //require( getTokens(msg.sender,"Timber",6) );
        StandardToken timberContract = StandardToken(getContract("Timber"));
        require( timberContract.galleassTransferFrom(msg.sender,getContract("Land"),6) ); //use 6 timber (moved to Land contract)
        //set tile type on the Land Contract
        landContract.setTileTypeAt(_x,_y,_tile,_newTileType);
        //set contract at tile to the Village
        address villageContract = getContract("Village");
        landContract.setContractAt(_x,_y,_tile,villageContract);
        //trigger the onPurchase for the contract (this is used for land contracts to track owners and initialize)
        StandardTile(villageContract).onPurchase(_x,_y,_tile,msg.sender,0);
        return true;
      }else{
        return false;
      }
    } else if(tileType==tileTypes["Village"]){
      //they want to build on a main, blank spot whether hills or grass
      if(_newTileType==tileTypes["Castle"]){
        //require( getTokens(msg.sender,"Timber",6) );
        StandardToken stoneContract = StandardToken(getContract("Stone"));
        require( stoneContract.galleassTransferFrom(msg.sender,getContract("Land"),20) ); //use 20 stone (moved to Land contract)
        //set tile type on the Land Contract
        landContract.setTileTypeAt(_x,_y,_tile,_newTileType);
        //set contract at tile to the Village
        address castleContract = getContract("Castle");
        landContract.setContractAt(_x,_y,_tile,castleContract);
        //trigger the onPurchase for the contract (this is used for land contracts to track owners and initialize)
        StandardTile(castleContract).onPurchase(_x,_y,_tile,msg.sender,0);
        return true;
      }else{
        return false;
      }
    } else {
      return false;
    }
  }

  function _buildTimberCamp(address _sender, uint _amount, bytes _data) internal returns (bool) {
    Land landContract = Land(getContract("Land"));
    //build timber camp
    address copperContractAddress = getContract("Copper");
    require(msg.sender == copperContractAddress);
    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);

    //they must own the tile
    require(landContract.ownerAt(_x,_y,_tile)==_sender);
    //they must send in 6 copper
    require(_amount>=6);
    //move that copper to the Land contract
    StandardToken copperContract = StandardToken(copperContractAddress);
    require(copperContract.transfer(getContract("Land"),_amount));
    //must be built on a forest tile
    require(landContract.tileTypeAt(_x,_y,_tile)==tileTypes["Forest"]);


    //assuming the we used the fist 6 bytes of the data for action,x,y,tile we will use the rest as the id of
    // the citizen that will be building the timber camp
    uint citizenId = uint(getRemainingBytesLeadingZs(6,_data));
    //uint citizenId = getRemainingUint(6,_data);

    //make sure that this address owns a citizen at this location with strength and stamina > 1
    // if everything is right, set the status to timber camp
    require(_useCitizenAsLumberjack(_sender,_x,_y,_tile,citizenId));
    //set new tile type
    landContract.setTileTypeAt(_x,_y,_tile,tileTypes["TimberCamp"]);

    //Debug(getContract("TimberCamp"));
    //set contract to timber camp
    landContract.setContractAt(_x,_y,_tile,getContract("TimberCamp"));
    StandardTile tileContract = StandardTile(landContract.contractAt(_x,_y,_tile));
    tileContract.onPurchase(_x,_y,_tile,landContract.ownerAt(_x,_y,_tile),landContract.priceAt(_x,_y,_tile));

    return true;
  }
  //event Debug(bytes32 citizenBytes,uint8 b,uint8 d, bytes32 thisByte);

  function _useCitizenAsLumberjack(address _sender, uint16 _x, uint16 _y, uint8 _tile,uint _citizen) internal returns (bool){
    Citizens citizensContract = Citizens(getContract("Citizens"));
    address owner;
    uint8 status;
    uint16 x;
    uint16 y;
    uint8 tile;
    bytes32 characteristics;
    (owner,status,,x,y,tile,,characteristics,) = citizensContract.getToken(_citizen);
    //sender must own citizen
    require(owner==_sender);
    //citizen must be idle
    require(status==1);
    //citizen must be at location
    require(_x==x);
    require(_y==y);
    require(_tile==tile);
    //citizen must have enough strength and stamina to be a lumberjack
    CitizensLib citizensLibContract = CitizensLib(getContract("CitizensLib"));
    uint16 strength;
    uint16 stamina;
    (strength,stamina,,,,,) = citizensLibContract.getCitizenCharacteristics(_citizen);
    require(strength>1);
    require(stamina>1);
    //set citizen status to TimberCamp tile type (lumberjack!)
    require(citizensLibContract.setStatus(_citizen,uint8(tileTypes["TimberCamp"])));
    return true;
  }

  function _extractRawResource(address _sender, uint _amount, bytes _data) internal returns (bool) {
    Land landContract = Land(getContract("Land"));
    address copperContractAddress = getContract("Copper");
    require(msg.sender == copperContractAddress);

    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);

    //they must own the tile
    require(landContract.ownerAt(_x,_y,_tile)==_sender);
    //move that copper to the Land contract
    StandardToken copperContract = StandardToken(copperContractAddress);
    require(copperContract.transfer(getContract("Land"),_amount));
    StandardToken resourceContract;

    if(landContract.tileTypeAt(_x,_y,_tile)==tileTypes["Forest"] || landContract.tileTypeAt(_x,_y,_tile)==tileTypes["TimberCamp"]){
      //they must send in 3 copper to extract 1 Timber
      require(_amount>=3);
      resourceContract = StandardToken(getContract("Timber"));
      require(resourceContract.galleassMint(_sender,1));
      return true;
    } else if(landContract.tileTypeAt(_x,_y,_tile)==tileTypes["Grass"] || landContract.tileTypeAt(_x,_y,_tile)==tileTypes["MainGrass"]){
      //they must send in 2 copper to extract 1 Greens
      require(_amount>=2);
      resourceContract = StandardToken(getContract("Greens"));
      require(resourceContract.galleassMint(_sender,1));
      return true;
    } else if(landContract.tileTypeAt(_x,_y,_tile)==tileTypes["Mountain"]) {
      //they must send in 4 copper to extract 1 Stone
      require(_amount>=4);
      resourceContract = StandardToken(getContract("Stone"));
      require(resourceContract.galleassMint(_sender,1));
      return true;
    }else{
      return false;
    }
  }

  function translateTileToWidth(uint16 _tileType) public constant returns (uint16) {
    if(_tileType==tileTypes["Water"]){
      return 95;
    }else if (_tileType>=1&&_tileType<50){
      return 120;
    }else if (_tileType>=50&&_tileType<100){
      return 87;
    }else if (_tileType>=100&&_tileType<150){
      return 120;
    }else if (_tileType>=150&&_tileType<200){
      return 87;
    }else{
      return 120;
    }
  }

  function translateToStartingTile(uint16 tilepart) public constant returns (uint16) {
    if(tilepart<12850){
      return tileTypes["Water"];
    }else if(tilepart<19275){
      return tileTypes["MainHills"];
    }else if(tilepart<24415){
      return tileTypes["MainGrass"];
    }else if(tilepart<26985){
      return tileTypes["MainStream"];
    }else if(tilepart<40606){
      return tileTypes["Grass"];
    }else if(tilepart<59624){
      return tileTypes["Forest"];
    }else if(tilepart<64250){
      return tileTypes["Mountain"];
    }else if(tilepart<65287){
      return tileTypes["CopperMountain"];
    }else{
      return tileTypes["SilverMountain"];
    }
  }

}

contract Citizens {
  function getToken(uint256 _id) public view returns (address owner,uint8 status,uint data,uint16 x,uint16 y,uint8 tile, bytes32 genes,bytes32 characteristics,uint64 birth) { }
}
contract CitizensLib {
  function getCitizenCharacteristics(uint256 _id) public view returns (uint16 strength,uint16 stamina,uint16 dexterity,uint16 intelligence,uint16 ambition,uint16 rigorous,uint16 industrious,uint16 ingenuity) { }
  function setStatus(uint _id,uint8 _status) public returns (bool){ }
}

contract Land {
  uint16 public mainX;
  uint16 public mainY;
  uint256 public nonce=0;
  mapping (bytes32 => uint16) public tileTypes;
  mapping (uint16 => mapping (uint16 => uint16[18])) public tileTypeAt;
  mapping (uint16 => mapping (uint16 => address[18])) public contractAt;
  mapping (uint16 => mapping (uint16 => address[18])) public ownerAt;
  mapping (uint16 => mapping (uint16 => uint256[18])) public priceAt;
  mapping (uint16 => mapping (uint16 => uint16)) public totalWidth;
  function setTileTypeAt(uint16 _x, uint16 _y, uint8 _tile,uint16 _type) public returns (bool) { }
  function setContractAt(uint16 _x, uint16 _y, uint8 _tile,address _address) public returns (bool) { }
  function setOwnerAt(uint16 _x, uint16 _y, uint8 _tile,address _owner) public returns (bool) { }
  function setPriceAt(uint16 _x, uint16 _y, uint8 _tile,uint _price) public returns (bool) { }
}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function galleassTransferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function galleassMint(address _to,uint _amount) public returns (bool){ }
}

contract StandardTile {
  function onPurchase(uint16 _x,uint16 _y,uint8 _tile,address _owner,uint _amount) public returns (bool) { }
}