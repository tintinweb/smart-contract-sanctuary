//SourceUnit: DecentralizedBet.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ITRC20.sol";

/* 
   [̲̅S][̲̅O][̲̅C][̲̅C][̲̅E][̲̅R][̲̅C][̲̅R][̲̅Y][̲̅P][̲̅T]
   
   &

   𝕄𝕒𝕥𝕔𝕙 𝕋𝕠𝕜𝕖𝕟 𝕋𝕖𝕒𝕞

*/

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract DecentralizedBet is Owner{

  using SafeMath for uint256;
  using SafeMath64 for uint64;

  uint64 public MINIMUM_BET = 1000000;
  uint64 private constant PROVIDER_FEE = 300;
  uint64 private constant REFERRAL_FEE = 100;
  uint64 constant public DIVIDER = 10000;
  uint64 constant public DIVIDER_ODDS = 100;
  address public providerAddress = address(0x41620841a7d9b729b8b5904254b88cb32f4407989e) ; 
  address public refereeAddress = address(0x41620841a7d9b729b8b5904254b88cb32f4407989e) ; 
  
  address private constant matchContract = address(0x41e8558dd6776df8f635fc0b566b1c3074a2d07a25);
  mapping (uint64 => Order) internal orders;
  mapping (bytes32 => uint64[]) internal orderGroups;

  mapping(address => Reff) internal reffSystem;
  mapping(uint64 => Token) internal allowedTokens;

  struct Token{
    ITRC20 trc20;
    address _address;
  }
  struct Reff{
    address referrer;
    uint64 claimable;
  }
  struct Order{
    bool makerClaimed;
    bool takerClaimed;
    uint8 winner; 
    uint8 betType ;
    uint8 status; 
    uint16 valueBetType;
    uint32 odds; 
    uint32 startTime;
    uint64 matchId;
    uint64 orderId;
    uint64 makerPot; 
    uint64 makerTotalPot; 
    uint64 takerPot; 
    address makerSide;
    address takerSide;
    uint64 tokenCode;
    
  }

  
  constructor() public {

    addToken(matchContract,100);
  }

  //log
  event Claimed(address indexed user, uint64 orderId, uint64 amount);
  event OrderCreated(bytes32 _groupId, uint64 _matchId, uint64 _orderId,uint256 createdTime);
  event MatchSettled(bytes32 _groupId);



  function recoverAddress(bytes memory abiEncoded, bytes memory signature) internal pure returns(address){

    bytes32 hashed = keccak256(abiEncoded);

    bytes32  r = convertToBytes32(slice(signature, 0, 32));
    bytes32  s = convertToBytes32(slice(signature, 32, 32));
    byte  v1 = slice(signature, 64, 1)[0];
    uint8 v = uint8(v1);
    return (ecrecover(hashed, v,r,s));
  }

  function slice(bytes memory data, uint start, uint len) internal pure returns (bytes memory){
      bytes memory b = new bytes(len);
      for(uint i = 0; i < len; i++){
          b[i] = data[i + start];
      }
      return b;
  }

  function convertToBytes32(bytes memory source) internal pure returns (bytes32 result) {
      assembly {
          result := mload(add(source, 32))
      }
  }

  
  function createOrder(uint64[] memory makerParams,uint64 _orderId, bytes32 orderGroupId, uint64 _takerPot, bytes memory makerSignature,bytes memory refereeSignature,address referrer) public returns(bool){

    require(!isContract(msg.sender),"Contract is not allowed");
    bytes memory prefix = "\x19TRON Signed Message:\n32";

    require(makerParams.length == 9 , "Invalid makerParams");
    require(allowedTokens[makerParams[8]]._address != address(0), "Invalid tokens");
    require(_orderId > 0 , "Invalid takerParams");
    require(_takerPot >= MINIMUM_BET,"Raise your bet!");

    bytes memory encoded = abi.encodePacked(prefix,makerParams);
    address addrMaker = recoverAddress(encoded,makerSignature);

    //require(addrMaker == maker,"Invalid maker");

    Order storage order = orders[_orderId];
    require(order.orderId == 0 , "Duplicate Order ID");

    order.matchId = makerParams[0];
    order.odds = uint32(makerParams[1]);
    order.startTime = uint32(makerParams[2]);
    order.makerTotalPot = makerParams[4];
    order.betType = uint8(makerParams[5]);
    order.status = 99;
    order.valueBetType = uint16(makerParams[6]);
    order.orderId = _orderId;
    order.takerPot = _takerPot;
    order.makerSide = addrMaker;
    order.makerClaimed=false;
    order.takerClaimed=false;
    order.tokenCode = makerParams[8];

    require(block.timestamp<= makerParams[7],"Maker order Expired");
    require(block.timestamp < makerParams[2],"The match already started");
    require(makerParams[2] < makerParams[3],"StartTime > EndTime");
    require(order.odds > 100,"Minimum Odds 101");

    //require(memOrder.makerSide!= msg.sender,"Maker == Taker"); //maker != taker

    encoded = abi.encodePacked(prefix,_orderId,orderGroupId,makerSignature);
    require(recoverAddress(encoded,refereeSignature) == refereeAddress, "Invalid Referee");
    order.takerSide = msg.sender;

    emit OrderCreated(orderGroupId,order.matchId,order.orderId,block.timestamp);
    uint64 makerTotalPotUsed = 0;
    uint makerOrdersLength = orderGroups[orderGroupId].length;
    for(uint i=0 ; i < makerOrdersLength ; i++){
      uint64 loopOrderId = orderGroups[orderGroupId][i];
      if(orders[loopOrderId].odds > 0){
        require(orders[loopOrderId].odds == order.odds,"Duplicate order on Maker Side for one Match!");
      }
      makerTotalPotUsed = makerTotalPotUsed.add(orders[loopOrderId].makerPot);
    }
    order.makerTotalPot = order.makerTotalPot.sub(makerTotalPotUsed);
    order.makerPot = uint64(order.odds).sub(100).mul(order.takerPot).div(100);
    require(order.makerPot<=order.makerTotalPot,"Maker Pot Limit Exceeded");

    ITRC20 trc20 = allowedTokens[order.tokenCode].trc20;
    require(trc20.allowance(order.makerSide,address(this))>=order.makerPot,"insufficient maker allowance");
    require(trc20.allowance(order.takerSide,address(this))>=order.takerPot,"insufficient taker allowance");

    require(trc20.balanceOf(order.makerSide)>=order.makerPot,"insufficient maker balance");
    require(trc20.balanceOf(order.takerSide)>=order.takerPot,"insufficient taker balance");

    trc20.transferFrom(order.makerSide,address(this),order.makerPot);
    trc20.transferFrom(order.takerSide,address(this),order.takerPot);


    order.status = 0;
    orderGroups[orderGroupId].push(order.orderId);


    if(reffSystem[msg.sender].referrer == address(0) && order.tokenCode==100  ){
       if (referrer != providerAddress && referrer != msg.sender ){
        reffSystem[msg.sender].referrer = referrer;
      }
    }
   
    return true;
  }

  function getReffClaimable(address addr) public view returns(uint64){
    return reffSystem[addr].claimable;
  }

  function claimReferralFee() public{
    require(reffSystem[msg.sender].claimable > 0,"");
   require(allowedTokens[100]._address != address(0), "Invalid tokens");
    uint64 claimable = reffSystem[msg.sender].claimable;
    reffSystem[msg.sender].claimable =0;
    allowedTokens[100].trc20.transfer(msg.sender,claimable);
  
  }

  function getOrderById(uint64 orderId) public view returns(uint256[] memory){
     Order memory order = orders[orderId];
     uint256[] memory rInt = new uint256[](17);
     rInt[0] = uint256(order.orderId);
     rInt[1] = uint256(order.matchId);
     rInt[2] = uint256(order.odds);
     rInt[3] = uint256(order.takerSide);
     rInt[4] = uint256(order.makerSide);
     rInt[5] = uint256(order.makerPot);
     rInt[6] = uint256(order.makerTotalPot);
     rInt[7] = uint256(order.takerPot);
     rInt[8] = uint256(order.betType);
     rInt[9] = uint256(order.status);
     rInt[10] = uint256(order.valueBetType);
     rInt[11] = uint256(order.startTime);
     rInt[13] = order.makerClaimed?1:0;
     rInt[14] = order.takerClaimed?1:0;
     rInt[15] = uint256(order.winner);
     rInt[16] = uint256(order.tokenCode);
     return rInt;
  }

  function getAllowedTokens(uint64 codeToken) public view returns(address){
 
    return allowedTokens[codeToken]._address;
  }

  function getOrderIdsByGroup(bytes32 groupId) public view returns(uint64[] memory){

    return orderGroups[groupId];

  }

  function claim(uint64 orderId) public returns(bool) {

    require(!isContract(msg.sender),"Contract is not allowed");
    Order storage order = orders[orderId];
    require(order.status == 1 || order.status == 100,"Invalid Order");
    require(allowedTokens[order.tokenCode]._address != address(0), "Invalid token");
     ITRC20 trc20 = allowedTokens[order.tokenCode].trc20;
    if(order.status == 1){
      require(order.winner == 1 || order.winner == 2 ,"Invalid Winner");
      require(order.makerClaimed== false && order.takerClaimed == false,"Invalid Claim");
      if(order.winner == 1){
       require(order.makerSide == msg.sender,"Invalid Maker Side");
        uint64 pot = order.takerPot;
        uint64 fee = pot.mul(PROVIDER_FEE).div(DIVIDER);
        pot = pot.sub(fee).add(order.makerPot);

        if(reffSystem[order.takerSide].referrer != address(0) && order.tokenCode == 100){
          uint64 rFee = fee.mul(REFERRAL_FEE).div(DIVIDER);
          fee = fee.sub(rFee);
          reffSystem[reffSystem[order.takerSide].referrer].claimable = reffSystem[reffSystem[order.takerSide].referrer].claimable.add(rFee);
        }
        trc20.transfer(providerAddress,fee);
        trc20.transfer(msg.sender,pot);
        emit Claimed(msg.sender, order.orderId, pot);
        order.makerClaimed=true;
        return true;

      }else if(order.winner == 2){
        require(order.takerSide == msg.sender,"Invalid Taker Side");
        uint64 pot = order.makerPot;
        uint64 fee = pot.mul(PROVIDER_FEE).div(DIVIDER);
        pot = pot.sub(fee).add(order.takerPot);
        if(reffSystem[order.takerSide].referrer != address(0)&& order.tokenCode == 100){
          uint64 rFee = fee.mul(REFERRAL_FEE).div(DIVIDER);
          fee = fee.sub(rFee);
          reffSystem[reffSystem[order.takerSide].referrer].claimable = reffSystem[reffSystem[order.takerSide].referrer].claimable.add(rFee);
        }
        trc20.transfer(providerAddress,fee);
        trc20.transfer(msg.sender,pot);
        emit Claimed(msg.sender,order.orderId, pot);
        order.takerClaimed=true;
        return true;

      }

    }else if (order.status == 100){
      require(order.winner == 100 ,"Invalid Winner");
      if(order.makerSide == msg.sender){
        require(order.makerClaimed == false ,"Invalid Maker Claim");
        trc20.transfer(msg.sender,order.makerPot);
        order.makerClaimed = true;
        emit Claimed(msg.sender,order.orderId, order.makerPot);
      }else if(order.takerSide == msg.sender){
        require(order.takerClaimed == false,"Invalid Taker Claim");
        trc20.transfer(msg.sender,order.takerPot);
        order.takerClaimed = true;
        emit Claimed(msg.sender,order.orderId, order.takerPot);
        return true;
      }
    }
  }


  function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
  }

   function setMatchResult(bool winner,bytes32 groupId) public returns(bool){

    require(msg.sender == refereeAddress,"Invalid requestor");

    uint256 length = orderGroups[groupId].length;

    for(uint64 i = 0 ; i < length ; i ++){
      Order storage order = orders[orderGroups[groupId][i]];

      require(order.matchId>0,"invalid order");
      require(order.status == 0,"invalid order status");
      require(order.startTime+6300 < block.timestamp, "not finished yet"); //total 45 mins first half, 15 mins break, 45 mins second half 
      order.status = 1;
      if(winner){
          order.winner = 2;
         
      }else{
          order.winner=1;
      }
    }
    
    emit MatchSettled(groupId);
    return length>0?true:false;
  }

  function cancelByOrderGroup(bytes32 groupId) public{

    uint256 length = orderGroups[groupId].length;

    for(uint64 i = 0 ; i < length ; i ++){
      Order storage order = orders[orderGroups[groupId][i]];
       require(order.startTime>0,"Invalid Match");
      uint256 currTime = block.timestamp-(24*3600); //24 hours waiting time. will be written in FAQ

      require(order.status == 0 ,"Invalid Match");
      require((msg.sender == order.takerSide) || (msg.sender == order.makerSide) || (msg.sender == refereeAddress),"You're not allowed to do this");

      if(msg.sender == refereeAddress){
        require(block.timestamp > order.startTime+14400,"Cancel Failed. Invalid Time (Ref)");
      }else{
          require(currTime > order.startTime+6300,"Cancel Failed. Invalid Time");
      }
       order.status = 100;
       order.winner = 100;
    }

   
  }

  function cancel(uint64 _orderId) public{

    require(orders[_orderId].startTime>0,"Invalid Match");
    uint256 currTime = block.timestamp-(24*3600); //24 hours waiting time. will be written in FAQ
    Order storage _order = orders[_orderId];

    require(_order.status == 0 ,"Invalid Match");
    require((msg.sender == _order.takerSide) || (msg.sender == _order.makerSide) || (msg.sender == refereeAddress),"You're not allowed to do this");

    if(msg.sender == refereeAddress){
      require(block.timestamp > _order.startTime+14400,"Cancel Failed. Invalid Time (Ref)");
    }else{
          require(currTime > _order.startTime+6300,"Cancel Failed. Invalid Time");
    }
     _order.status = 100;
     _order.winner = 100;
  }

  function addToken(address token,uint64 code) public onlyOwner{
    allowedTokens[code]._address = token;
    allowedTokens[code].trc20 = ITRC20(allowedTokens[code]._address);
  }

  function removeToken(uint64 code)public onlyOwner{
    allowedTokens[code]._address = address(0);
  }
  function setMinimumBet(uint64 _MINIMUM_BET) public onlyOwner {
      MINIMUM_BET = _MINIMUM_BET;
  }

  function setReferee(address _refereeAddress) public onlyOwner{
    refereeAddress = _refereeAddress;
  }

   function setProviderAddress(address _providerAddress) public onlyOwner{
    providerAddress = _providerAddress;
  }

}

//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }


}

library SafeMath64 {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint64 a, uint64 b) internal pure returns (uint64) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint64 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint64 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b <= a);
        uint64 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint64 a, uint64 b) internal pure returns (uint64) {
        uint64 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0);
        return a % b;
    }


}