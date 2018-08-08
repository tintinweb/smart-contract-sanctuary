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


contract Land is Galleasset {

  uint16 public mainX;
  uint16 public mainY;

  function setMainLocation(uint16 _mainX,uint16 _mainY) onlyOwner isBuilding public returns (bool) {
    mainX=_mainX;
    mainY=_mainY;
  }

  uint256 public nonce=0;

  mapping (uint16 => mapping (uint16 => uint16[18])) public tileTypeAt;
  mapping (uint16 => mapping (uint16 => address[18])) public contractAt;
  mapping (uint16 => mapping (uint16 => address[18])) public ownerAt;
  mapping (uint16 => mapping (uint16 => uint256[18])) public priceAt;

  mapping (uint16 => mapping (uint16 => uint16)) public totalWidth;

  function Land(address _galleass) public Galleasset(_galleass) { }
  function () public {revert();}

  function generateLand() onlyOwner isBuilding public returns (bool) {

    LandLib landLib = LandLib(getContract("LandLib"));

    //islands are procedurally generated based on a randomish hash
    bytes32 id = keccak256(nonce++,block.blockhash(block.number-1));
    uint16 x = uint16(id[0]) << 8 | uint16(id[1]);
    uint16 y = uint16(id[2]) << 8 | uint16(id[3]);
    bytes32 landParts1 = keccak256(id);
    bytes32 landParts2 = keccak256(landParts1);

    //don&#39;t allow land at 0&#39;s (those are viewed as empty)
    if(x==0) x=1;
    if(y==0) y=1;

    for(uint8 index = 0; index < 18; index++){
      uint16 thisUint16 = uint16(landParts1[index]) << 8 | uint16(landParts2[index]);
      tileTypeAt[x][y][index] = landLib.translateToStartingTile(thisUint16);
      ownerAt[x][y][index] = msg.sender;
    }

    //scan tiles and insert base spots
    uint8 landCount = 0;
    for(uint8 landex = 0; landex < 18; landex++){
      if(tileTypeAt[x][y][landex]==0){
        if(landCount>0){
          //right edge
          tileTypeAt[x][y][landex-(landCount%2+landCount/2)]=1;//MAIN TILE
          landCount=0;
        }
      }else{
        if(landCount==0){
          //left edge
        }
        landCount++;
      }
    }
    if(landCount>0){
      //final right edge
      tileTypeAt[x][y][17-(landCount/2)]=1; //MAIN TILE
      landCount=0;
    }

    if(mainX==0||mainY==0){
      mainX=x;
      mainY=y;
    }

    totalWidth[x][y] = getTotalWidth(x,y);

    LandGenerated(x,y);
  }
  event LandGenerated(uint16 _x,uint16 _y);


  function editTile(uint16 _x, uint16 _y,uint8 _tile,uint16 _update,address _contract) onlyOwner isBuilding public returns (bool) {
    tileTypeAt[_x][_y][_tile] = _update;
    contractAt[_x][_y][_tile] = _contract;
    if(contractAt[_x][_y][_tile]!=address(0)){
       StandardTile tileContract = StandardTile(contractAt[_x][_y][_tile]);
       tileContract.onPurchase(_x,_y,_tile,ownerAt[_x][_y][_tile],priceAt[_x][_y][_tile]);
    }
    ownerAt[_x][_y][_tile]=msg.sender;
  }

  function buyTile(uint16 _x,uint16 _y,uint8 _tile) public isGalleasset("Land") returns (bool) {
    require(priceAt[_x][_y][_tile]>0);//must be for sale
    StandardToken copperContract = StandardToken(getContract("Copper"));
    require(copperContract.transferFrom(msg.sender,ownerAt[_x][_y][_tile],priceAt[_x][_y][_tile]));
    ownerAt[_x][_y][_tile]=msg.sender;
    //when a piece of land is purchased, an "onPurchase" function is called
    // on the contract to help the inner contract track events and owners etc
    if(contractAt[_x][_y][_tile]!=address(0)){
       StandardTile tileContract = StandardTile(contractAt[_x][_y][_tile]);
       tileContract.onPurchase(_x,_y,_tile,ownerAt[_x][_y][_tile],priceAt[_x][_y][_tile]);
    }
    BuyTile(_x,_y,_tile,ownerAt[_x][_y][_tile],priceAt[_x][_y][_tile],contractAt[_x][_y][_tile]);
    priceAt[_x][_y][_tile]=0;
    return true;
  }
  event BuyTile(uint16 _x,uint16 _y,uint8 _tile,address _owner,uint _price,address _contract);

/*

  MOVED TO LANDLIB
  
  function buildTile(uint16 _x, uint16 _y,uint8 _tile,uint16 _newTileType) public isGalleasset("Land") returns (bool) {
    require(msg.sender==ownerAt[_x][_y][_tile]);
    LandLib landLib = LandLib(getContract("LandLib"));
    uint16 tileType = tileTypeAt[_x][_y][_tile];
    if(tileType==landLib.tileTypes("MainHills")||tileType==landLib.tileTypes("MainGrass")){
      //they want to build on a main, blank spot whether hills or grass
      if(_newTileType==landLib.tileTypes("Village")){
        //require( getTokens(msg.sender,"Timber",6) );
        StandardToken timberContract = StandardToken(getContract("Timber"));
        require( timberContract.galleassTransferFrom(msg.sender,address(this),6) ); //charge 6 timber
        tileTypeAt[_x][_y][_tile] = _newTileType;
        contractAt[_x][_y][_tile] = getContract("Village");
        StandardTile(contractAt[_x][_y][_tile]).onPurchase(_x,_y,_tile,msg.sender,0);
        return true;
      }else{
        return false;
      }
    } else {
      return false;
    }
  }
*/

  //erc677 receiver
  function onTokenTransfer(address _sender, uint _amount, bytes _data) public isGalleasset("Land") returns (bool) {
    TokenTransfer(msg.sender,_sender,_amount,_data);
    //THIS HAS MOVED TO LANDLIB FOR FASTER DEV LOOP/UPGRADABILITY
    //LandLib landLib = LandLib(getContract("LandLib"));
    //landLib.onTokenTransfer(_sender,_amount,_data)
    return false;
  }
  event TokenTransfer(address token,address sender,uint amount,bytes data);

  //allow LandLib to set storage on Land contract
  //this allows me to redeploy the LandLib as I need and leave the
  //generated land alone
  function setTileTypeAt(uint16 _x, uint16 _y, uint8 _tile,uint16 _type) public isGalleasset("Land") returns (bool) {
    require(msg.sender==getContract("LandLib"));
    tileTypeAt[_x][_y][_tile] = _type;
    return true;
  }
  function setContractAt(uint16 _x, uint16 _y, uint8 _tile,address _address) public isGalleasset("Land") returns (bool) {
    require(msg.sender==getContract("LandLib"));
    contractAt[_x][_y][_tile] = _address;
    return true;
  }
  function setOwnerAt(uint16 _x, uint16 _y, uint8 _tile,address _owner) public isGalleasset("Land") returns (bool) {
    require(msg.sender==getContract("LandLib"));
    ownerAt[_x][_y][_tile] = _owner;
    return true;
  }
  function setPriceAt(uint16 _x, uint16 _y, uint8 _tile,uint _price) public isGalleasset("Land") returns (bool) {
    require(msg.sender==getContract("LandLib"));
    priceAt[_x][_y][_tile] = _price;
    return true;
  }

  //the land owner can also call setPrice directly
  function setPrice(uint16 _x,uint16 _y,uint8 _tile,uint256 _price) public isGalleasset("Land") returns (bool) {
    require(msg.sender==ownerAt[_x][_y][_tile]);
    priceAt[_x][_y][_tile]=_price;
    return true;
  }

  /* function setTileContract(uint16 _x,uint16 _y,uint8 _tile,address _contract) public isGalleasset("Land") returns (bool) {
    require(msg.sender==ownerAt[_x][_y][_tile]);
    contractAt[_x][_y][_tile]=_contract;
    return true;
  } */

  function transferTile(uint16 _x,uint16 _y,uint8 _tile,address _newOwner) public isGalleasset("Land") returns (bool) {
    require(msg.sender==ownerAt[_x][_y][_tile]);
    ownerAt[_x][_y][_tile]=_newOwner;
    priceAt[_x][_y][_tile]=0;
    return true;
  }

  function getTile(uint16 _x,uint16 _y,uint8 _index) public constant returns (uint16 _tile,address _contract,address _owner,uint256 _price) {
    return (tileTypeAt[_x][_y][_index],contractAt[_x][_y][_index],ownerAt[_x][_y][_index],priceAt[_x][_y][_index]);
  }

  function getTileLocation(uint16 _x,uint16 _y,address _address) public constant returns (uint16) {
    LandLib landLib = LandLib(getContract("LandLib"));
    uint8 tileIndex = findTileByAddress(_x,_y,_address);
    if(tileIndex==255) return 0;
    uint16 widthOffset = 0;
    bool foundLand = false;
    for(uint8 t = 0;t<tileIndex;t++){
      widthOffset+=landLib.translateTileToWidth(tileTypeAt[_x][_y][t]);
      if(tileTypeAt[_x][_y][t]!=0&&!foundLand){
        foundLand=true;
        widthOffset+=114;
      }else if(tileTypeAt[_x][_y][t]==0&&foundLand){
        foundLand=false;
        widthOffset+=114;
      }
    }
    if(!foundLand){
      widthOffset+=114;
    }
    widthOffset = widthOffset+(landLib.translateTileToWidth(tileTypeAt[_x][_y][tileIndex])/2);

    uint16 halfTotalWidth = totalWidth[_x][_y]/2;
    return 2000 - halfTotalWidth + widthOffset;
  }

  function getTotalWidth(uint16 _x,uint16 _y) public constant returns (uint16){
    LandLib landLib = LandLib(getContract("LandLib"));
    uint16 totalWidth = 0;
    bool foundLand = false;
    for(uint8 t = 0;t<18;t++){
      totalWidth+=landLib.translateTileToWidth(tileTypeAt[_x][_y][t]);
      if(tileTypeAt[_x][_y][t]!=0&&!foundLand){
        foundLand=true;
        totalWidth+=114;
      }else if(tileTypeAt[_x][_y][t]==0&&foundLand){
        foundLand=false;
        totalWidth+=114;
      }
    }
    if(foundLand) totalWidth+=114;
    return totalWidth;
  }

  function findTile(uint16 _x,uint16 _y,uint16 _lookingForType) public constant returns (uint8) {
    uint8 index = 0;
    while(tileTypeAt[_x][_y][index]!=_lookingForType){
      index++;
      if(index>=18) return 255;
    }
    return index;
  }

  function findTileByAddress(uint16 _x,uint16 _y,address _address) public constant returns (uint8) {
    uint8 index = 0;
    while(contractAt[_x][_y][index]!=_address){
      index++;
      if(index>=18) return 255;
    }
    return index;
  }

}

contract LandLib {
  mapping (bytes32 => uint16) public tileTypes;
  function translateTileToWidth(uint16 _tileType) public constant returns (uint16) { }
  function translateToStartingTile(uint16 tilepart) public constant returns (uint16) { }
}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function galleassTransferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
}

contract StandardTile {
  function onPurchase(uint16 _x,uint16 _y,uint8 _tile,address _owner,uint _amount) public returns (bool) { }
}