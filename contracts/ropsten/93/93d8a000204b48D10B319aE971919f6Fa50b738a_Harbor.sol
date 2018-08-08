pragma solidity ^0.4.15;

/*

  https://galleass.io
  by Austin Thomas Griffith

  The Harbor is where ships embark and disembark from the Sea. It is the first
  land tile to be built in the main Land. You can buy, sell, and build ships
  by allowing the transfer of Timber.

*/


/*

  https://galleass.io
  by Austin Thomas Griffith

  The Village is where food is consumed and citizens are created
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


contract StandardTile is Galleasset, DataParser{

  constructor(address _galleass) public Galleasset(_galleass) { }
  function () public {revert();}

  //      land x            land y          land tile
  mapping(uint16 => mapping(uint16 => mapping(uint8 => address))) public landOwners;

  //each tile will have an inventory of tokens
  //      land x            land y          land tile         //token address //amount
  mapping(uint16 => mapping(uint16 => mapping(uint8 => mapping(address => uint256)))) public tokenBalance;

  //standard tile interface
  //called when tile is purchased from Land contract
  function onPurchase(uint16 _x,uint16 _y,uint8 _tile,address _owner,uint _amount) public returns (bool) {
    require(msg.sender==getContract("Land") || msg.sender==getContract("LandLib"));
    landOwners[_x][_y][_tile] = _owner;
    emit LandOwner(_x,_y,_tile,_owner);
    return true;
  }
  event LandOwner(uint16 _x,uint16 _y,uint8 _tile,address _owner);

  modifier isLandOwner(uint16 _x,uint16 _y,uint8 _tile) {
    require(msg.sender==landOwners[_x][_y][_tile]);
    _;
  }

  //the owner of the tile will need to stock it with copper to pay fishermen for their fillets
  function _sendToken(address _sender, uint _amount, bytes _data) internal returns (bool) {
    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);
    _incrementTokenBalance(_x,_y,_tile,msg.sender,_amount);
    return true;
  }

  ///////internal helpers to keep stack thin enough//////////////////////////////////////////////////////////
  function _incrementTokenBalance(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _amount) internal {
    tokenBalance[_x][_y][_tile][_token]+=_amount;
    require(tokenBalance[_x][_y][_tile][_token]>=_amount,"Overflow?");
  }
  function _decrementTokenBalance(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _amount) internal {
    require(tokenBalance[_x][_y][_tile][_token]>=_amount,"This tile does not have enough of this token");
    tokenBalance[_x][_y][_tile][_token]-=_amount;
  }
}


contract Harbor is StandardTile {

  uint16 public constant TIMBERTOBUILDDOGGER = 2;

  //      land x            land y          land tile           model      array of ids
  mapping(uint16 => mapping(uint16 => mapping(uint8 => mapping (bytes32 => uint256[99])))) public shipStorage; //make ship storage very large for testnet (eventually this should be much smaller)

  //      land x            land y          land tile           model      price to buy ship
  mapping(uint16 => mapping(uint16 => mapping(uint8 => mapping (bytes32 => uint256)))) public currentPrice;


  constructor(address _galleass) public StandardTile(_galleass) {
    //currentPrice["Dogger"] = ((1 ether)/1000);
  }

  function onTokenTransfer(address _sender, uint _amount, bytes _data) public isGalleasset("Harbor") returns (bool){
    emit TokenTransfer(msg.sender,_sender,_amount,_data);
    uint8 action = uint8(_data[0]);
    if(action==0){
      return _sendToken(_sender,_amount,_data);
    } else if(action==1){
      return _build(_sender,_amount,_data);
    } else {
      revert("unknown action");
    }
    return true;
  }
  event TokenTransfer(address token,address sender,uint amount,bytes data);



  function _build(address _sender, uint _amount, bytes _data) internal returns (bool) {

    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);

    bytes32 _model = getRemainingBytesTrailingZs(6,_data);

    //you must be sending in timber
    require(msg.sender == getContract("Timber"));

    //you must own the tile
    require(_sender == landOwners[_x][_y][_tile]);

    if(_model=="Dogger"){
      //must send in enough timber to build
      require( _amount >= TIMBERTOBUILDDOGGER );
      require( _buildShip(_x,_y,_tile,_model) > 0);
      return true;
    }else{
      return false;
    }
    return true;
  }

  //this is really only used for the scripts that build doggers
  // I should carve this out and only use transfer and call because it is confusing to have two different build functions
  function buildShip(uint16 _x,uint16 _y,uint8 _tile,bytes32 _model) public isGalleasset("Harbor") isLandOwner(_x,_y,_tile) returns (uint) {
    if(_model=="Dogger"){
      require( getTokens(msg.sender,"Timber",TIMBERTOBUILDDOGGER) );
      return _buildShip(_x,_y,_tile,_model);
    }else{
      return 0;
    }
  }

  function _buildShip(uint16 _x,uint16 _y,uint8 _tile,bytes32 _model) internal returns (uint) {
    address shipsContractAddress = getContract(_model);
    require( shipsContractAddress!=address(0) );
    require( approveTokens("Timber",shipsContractAddress,TIMBERTOBUILDDOGGER) );
    NFT shipContract = NFT(shipsContractAddress);
    uint256 shipId = shipContract.build();
    require( storeShip(_x,_y,_tile,shipId,_model) );
    emit Debug(shipId);
    return shipId;
  }
  event Debug(uint id);

  //this is old code, but it looks like you can sell ships back to the harbor
  // it also looks like you only get 9/10s of the price back if you sell it
  // I was probably just playing around with how ether moves around differently
  // than the native erc20s
  /*function sellShip(uint256 shipId,bytes32 model) public isGalleasset("Harbor") returns (bool) {
    address shipsContractAddress = getContract(model);
    require( shipsContractAddress!=address(0) );
    require( currentPrice[model] > 0 );
    NFT shipsContract = NFT(shipsContractAddress);
    require( shipsContract.ownerOf(shipId) == msg.sender);
    shipsContract.transferFrom(msg.sender,address(this),shipId);
    require( shipsContract.ownerOf(shipId) == address(this));
    require( storeShip(shipId,model) );
    uint256 buyBackAmount = currentPrice[model] * 9;
    buyBackAmount = buyBackAmount / 10;
    return msg.sender.send(buyBackAmount);
  }*/

  function buyShip(uint16 _x,uint16 _y,uint8 _tile,bytes32 model) public payable isGalleasset("Harbor") returns (uint) {
    require( currentPrice[_x][_y][_tile][model] > 0 );
    require( msg.value >= currentPrice[_x][_y][_tile][model] );
    address shipsContractAddress = getContract(model);
    require( shipsContractAddress!=address(0) );
    NFT shipsContract = NFT(shipsContractAddress);
    uint256 availableShip = getShipFromStorage(_x,_y,_tile,shipsContract,model);
    require( availableShip!=0 );
    shipsContract.transfer(msg.sender,availableShip);

    address experienceContractAddress = getContract("Experience");
    require( experienceContractAddress!=address(0) );
    Experience experienceContract = Experience(experienceContractAddress);
    require( experienceContract.update(msg.sender,1,true) );//milestone 1: buy ship

    return availableShip;
  }

  //the land owner can adjust the price in Eth that players have to pay for a ship
  function setPrice(uint16 _x,uint16 _y,uint8 _tile,bytes32 model,uint256 amount) public isLandOwner(_x,_y,_tile) returns (bool) {
    currentPrice[_x][_y][_tile][model]=amount;
  }


  // Internal functions dealing with ship/memory storage --- ////////////////////////////////////////////////////////////

  function getShipFromStorage(uint16 _x,uint16 _y,uint8 _tile,NFT shipsContract, bytes32 model) internal returns (uint256) {
    uint256 index = 0;
    while(index<shipStorage[_x][_y][_tile][model].length){
      if(shipStorage[_x][_y][_tile][model][index]!=0){
        uint256 shipId = shipStorage[_x][_y][_tile][model][index];
        shipStorage[_x][_y][_tile][model][index]=0;
        return shipId;
      }
      index++;
    }
    return 0;
  }

  function storeShip(uint16 _x,uint16 _y,uint8 _tile,uint256 _shipId,bytes32 _model) internal returns (bool) {
    uint256 index = 0;
    while(index<shipStorage[_x][_y][_tile][_model].length){
      if(shipStorage[_x][_y][_tile][_model][index]==0){
        shipStorage[_x][_y][_tile][_model][index]=_shipId;
        return true;
      }
      index++;
    }
    return false;
  }

  function countShips(uint16 _x,uint16 _y,uint8 _tile,bytes32 _model) public constant returns (uint256) {
    uint256 count = 0;
    uint256 index = 0;
    while(index<shipStorage[_x][_y][_tile][_model].length){
      if(shipStorage[_x][_y][_tile][_model][index]!=0){
        count++;
      }
      index++;
    }
    return count;
  }

}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}

contract NFT {
  function build() public returns (uint) { }
  function transfer(address _to,uint256 _tokenId) external { }
  function transferFrom(address _from,address _to,uint256 _tokenId) external { }
  function ownerOf(uint256 _tokenId) external view returns (address owner) { }
}

contract Experience{
  function update(address _player,uint16 _milestone,bool _value) public returns (bool) { }
}