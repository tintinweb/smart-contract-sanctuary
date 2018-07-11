pragma solidity ^0.4.23;

/*

https://galleass.io
by Austin Thomas Griffith

The market facilitates the buying and selling of different tokens

*/


/*

  https://galleass.io
  by Austin Thomas Griffith

  A standard tile has mapping for land owners and inventory hodl/send etc
*/




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
    require(msg.sender==getContract(&quot;Land&quot;) || msg.sender==getContract(&quot;LandLib&quot;));
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
    require(tokenBalance[_x][_y][_tile][_token]>=_amount,&quot;Overflow?&quot;);
  }
  function _decrementTokenBalance(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _amount) internal {
    require(tokenBalance[_x][_y][_tile][_token]>=_amount,&quot;This tile does not have enough of this token&quot;);
    tokenBalance[_x][_y][_tile][_token]-=_amount;
  }
}


contract Market is StandardTile {

  constructor(address _galleass) public StandardTile(_galleass) { }

  //      land x            land y          land tile
  mapping(uint16 => mapping(uint16 => mapping(uint8 => mapping (address => uint)))) public buyPrices; //how much the market will buy items for
  mapping(uint16 => mapping(uint16 => mapping(uint8 => mapping (address => uint)))) public sellPrices; //how much the market will sell items for

  function setBuyPrice(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _price) public isGalleasset(&quot;Market&quot;) isLandOwner(_x,_y,_tile) returns (bool) {
    buyPrices[_x][_y][_tile][_token] = _price;
    return true;
  }
  function setSellPrice(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _price) public isGalleasset(&quot;Market&quot;) isLandOwner(_x,_y,_tile) returns (bool) {
    sellPrices[_x][_y][_tile][_token] = _price;
    return true;
  }

  //if the market has permission to galleassTransferFrom your token you can call sell directly
  // it&#39;s better to 667 them in without special galeeass permission
  /*function sell(uint16 _x,uint16 _y,uint8 _tile,address _token,uint _amount) public isGalleasset(&quot;Market&quot;) returns (bool) {
    //token must have a buy price
    require(buyPrices[_x][_y][_tile][_token]>0);
    //move their tokens in
    StandardToken tokenContract = StandardToken(_token);
    require(tokenContract.galleassTransferFrom(msg.sender,address(this),_amount));
    //send them the correct amount of copper
    StandardToken copperContract = StandardToken(getContract(&quot;Copper&quot;));
    require(copperContract.transfer(msg.sender,buyPrices[_x][_y][_tile][_token]*_amount));
  }*/

  function onTokenTransfer(address _sender, uint _amount, bytes _data) public isGalleasset(&quot;Market&quot;) returns (bool){
    emit TokenTransfer(msg.sender,_sender,_amount,_data);
    uint8 action = uint8(_data[0]);
    if(action==0){
      return _sendToken(_sender,_amount,_data);
    } else if(action==1){
      return _buy(_sender,_amount,_data);
    } else if(action==2){
      return _sell(_sender,_amount,_data);
    }else {
      revert(&quot;unknown action&quot;);
    }
  }
  event TokenTransfer(address token,address sender,uint amount,bytes data);

  function _buy(address _sender, uint _amount, bytes _data) internal returns (bool) {
    //you must be sending in copper
    require(msg.sender == getContract(&quot;Copper&quot;));
    //increment tile&#39;s copper balance
    _incrementTokenBalance(_x,_y,_tile,msg.sender,_amount);
    //parse land location out of data
    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);
    address _tokenAddress = getAddressFromBytes(6,_data);

    //token must have a sell price
    require(sellPrices[_x][_y][_tile][_tokenAddress]>0);
    //increment tile&#39;s token balance
    _incrementTokenBalance(_x,_y,_tile,_tokenAddress,_amount);

    uint amountOfTokensToSend = _amount/sellPrices[_x][_y][_tile][_tokenAddress];

    //make sure this tile has enough of this token to send
    _decrementTokenBalance(_x,_y,_tile,_tokenAddress,amountOfTokensToSend);
    //send them their new tokens
    StandardToken tokenContract = StandardToken(_tokenAddress);
    require(tokenContract.transfer(_sender,amountOfTokensToSend));

    emit Buy(_x,_y,_tile,_amount,_tokenAddress,amountOfTokensToSend);

    return true;
  }
  event Buy(uint16 _x,uint16 _y,uint8 _tile,uint copperSpent, address _tokenAddress,uint amountOfTokensToSend);

  //player is sending some token to the market and expecting payment in copper based on the buyPrice the market is willing to pay for the incoming token
  function _sell(address _sender, uint _amount, bytes _data) internal returns (bool) {
    uint16 _x = getX(_data);
    uint16 _y = getY(_data);
    uint8 _tile = getTile(_data);

    //token must have a buy price
    require(buyPrices[_x][_y][_tile][msg.sender]>0);

    //increment tile&#39;s balance of this token
    _incrementTokenBalance(_x,_y,_tile,msg.sender,_amount);

    emit Sell(_x,_y,_tile,msg.sender,_amount,_sender);
    
    uint amountOfCopperToSend = _amount*buyPrices[_x][_y][_tile][msg.sender];
    //make sure this tile has enough copper to buy the token
    _decrementTokenBalance(_x,_y,_tile,getContract(&quot;Copper&quot;),amountOfCopperToSend);
    StandardToken copperContract = StandardToken(getContract(&quot;Copper&quot;));
    require(copperContract.transfer(_sender,amountOfCopperToSend));
    return true;
  }
  event Sell(uint16 _x,uint16 _y,uint8 _tile,address _tokenAddress,uint _amount,address _sender);

}

contract StandardToken {
  bytes32 public image;
  function galleassTransferFrom(address _from, address _to, uint256 _value) public returns (bool) { }
  function transfer(address _to, uint256 _value) public returns (bool) { }
  function balanceOf(address _owner) public view returns (uint256 balance) { }
}