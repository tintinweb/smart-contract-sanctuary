//SourceUnit: TATMCore.sol

pragma solidity >=0.4.23 <0.6.0;

contract SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
    require(msg.sender == owner, "should be owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "should be a valid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract TRC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// only interface to save gas
// contract RewardPool {
//   function refundFee(address _receiver, uint _amount) external;
// }


contract TATMCore is Ownable, SafeMath {

  event RegisterATM(address indexed atmOwner);
  event UpdateATM(address indexed atmOwner);
  event DeleteATM(address indexed atmOwner);
  event Sent(address indexed atmOwner, address indexed to, uint amount);

  struct ATM {
    bytes32 userId;       // user's id on TATM
    int32 lat;            // Latitude
    int32 lng;            // Longitude
    bytes2 countryId;     // countryID (in hexa), ISO ALPHA 2 https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    bytes16 postalCode;   // postalCode if present, in Hexa https://en.wikipedia.org/wiki/List_of_postal_codes

    int8 tokenType;       // 1(TRX), 2(TRC10), 3(TRC20)
    address tokenAddress; // If TRC20 then, token address
    uint tokenId;         // If TRC10 then, token ID
    uint amountATM;       // Amount of tokens or TRX, staked for an ATM

    int8 currencyId;      // 1 - 100 , e.g. 1(USD), 2(EUR)
    int16 sellRate;       // margin of ATMs , -999 - +9999 , corresponding to -99,9% x 10  , 999,9% x 10
    bool buyer;           // appear as a buyer as well on the map
    int16 buyRate;        // margin of ATMs of

    uint generalIndex;    // index of general mapping
    bool online;          // switch online/offline, if the ATM want to be inactive without deleting his point
  }

  address rewardPool;     // reward pool address
  uint feeATM;            // fee to create a ATM
  address TATMTRC20;// contract address of TATM TRC20 Token

  mapping(address => ATM) atms;
  address[] atmIndex; // unordered list of ATM register on it

  /**
  * @dev constructor - set TATM TRC20 contract and reward pool address
  */
  constructor(address _contractTATMTRC20, address _rewardPool, uint _feeATM) public {
    require(_contractTATMTRC20 != address(0), "should be a valid contract address");
    require(_rewardPool != address(0), "should be a valid address");
    require(_feeATM > 0, "should be a valid amount");

    TATMTRC20 = _contractTATMTRC20;
    rewardPool = _rewardPool;
    feeATM = _feeATM;
  }

  // return if teller or not
  function isATM(address _atm) public view returns (bool ){
    return (atms[_atm].countryId != bytes2(0x0));
  }

  /**
  * @dev createATM - create an ATM
  */
  function createATM(
    bytes32 _userId,
    int32 _lat,
    int32 _lng,
    bytes2 _countryId,
    bytes16 _postalCode,
    address _tokenAddress,
    uint _amountATM,
    int8 _currencyId,
    int16 _sellRate,
    bool _buyer,
    int16 _buyRate) public payable returns (bool) {

    require(!isATM(msg.sender), "already created the aTM");

    // send fee TATM tokens to reward pool, assuming that approve is already called
    TRC20Basic tatmContract = TRC20Basic(TATMTRC20);
    tatmContract.transferFrom(msg.sender, rewardPool, feeATM);

    if (msg.value > 0) { // if TRX
      atms[msg.sender].tokenType = 1;
      atms[msg.sender].amountATM = msg.value;
    } else if (msg.tokenvalue > 0) { // TRC10
      atms[msg.sender].tokenType = 2;
      atms[msg.sender].tokenId = msg.tokenid;
      atms[msg.sender].amountATM = msg.tokenvalue;
    } else if (_amountATM > 0) { // TRC20
      atms[msg.sender].tokenType = 3;
      atms[msg.sender].tokenAddress = _tokenAddress;
      atms[msg.sender].amountATM = _amountATM;

      TRC20Basic tokenContract = TRC20Basic(_tokenAddress);
      tokenContract.transferFrom(msg.sender, address(this), _amountATM);
    } else {
      // else failed to create ATM
      return false;
    }

    atms[msg.sender].userId = _userId;
    atms[msg.sender].lat = _lat;
    atms[msg.sender].lng = _lng;
    atms[msg.sender].countryId = _countryId;
    atms[msg.sender].postalCode = _postalCode;
    atms[msg.sender].currencyId = _currencyId;
    atms[msg.sender].sellRate = _sellRate;
    atms[msg.sender].buyer = _buyer;
    atms[msg.sender].buyRate = _buyRate;
    atms[msg.sender].generalIndex = atmIndex.push(msg.sender) - 1;
    atms[msg.sender].online = true;

    emit RegisterATM(msg.sender);
    return true;
  }

  /**
  * @dev updateATM - update an ATM, only ATM owner can update it
  */
  function updateATM(
    uint _amountATM,
    int8 _currencyId,
    int16 _sellRate,
    int16 _buyRate
   ) public payable returns (bool) {
    require(isATM(msg.sender), "should be an ATM");

    if (_currencyId != atms[msg.sender].currencyId && _currencyId != 0)
      atms[msg.sender].currencyId = _currencyId;
    if (atms[msg.sender].sellRate != _sellRate && _sellRate != 0)
      atms[msg.sender].sellRate = _sellRate;
    if (atms[msg.sender].buyRate != _buyRate && _buyRate != 0)
      atms[msg.sender].buyRate = _buyRate;

    // can only add funds
    if (msg.value > 0) { // if TRX
      atms[msg.sender].amountATM = SafeMath.add(atms[msg.sender].amountATM, msg.value);
    } else if (msg.tokenvalue > 0) { // TRC10
      atms[msg.sender].amountATM = SafeMath.add(atms[msg.sender].amountATM, msg.tokenvalue);
    } else if (_amountATM > 0) { // TRC20
      atms[msg.sender].amountATM = SafeMath.add(atms[msg.sender].amountATM, _amountATM);

      TRC20Basic tokenContract = TRC20Basic(atms[msg.sender].tokenAddress);
      tokenContract.transferFrom(msg.sender, address(this), _amountATM);
    }

    emit UpdateATM(msg.sender);
    return true;
  }

  /**
  * @dev deleteATM - delete an ATM, only ATM owner can delete it
  */
  function deleteATM() external returns (bool) {
    require(isATM(msg.sender), "should be an ATM");

    // refund TRX or tokens in the ATM to its owner
    uint toSend = atms[msg.sender].amountATM;
    int8 toTokenType = atms[msg.sender].tokenType;
    if (toSend > 0) {
      atms[msg.sender].amountATM = 0;
      if (toTokenType == 1) { // if TRX
        msg.sender.transfer(toSend);
      } else if (toTokenType == 2) {  // if TRC10
        msg.sender.transferToken(toSend, atms[msg.sender].tokenId);
      } else if (toTokenType == 3) { // if TRC20
        TRC20Basic tokenContract = TRC20Basic(atms[msg.sender].tokenAddress);
        tokenContract.transfer(msg.sender, toSend);
      } else {
        return false;
      }
    }

    // refund fee from the reward pool to the atm owner
    // RewardPool pool = RewardPool(rewardPool);
    // pool.refundFee(msg.sender, feeATM);

    // remove from mapping
    uint rowToDelete2 = atms[msg.sender].generalIndex;
    address keyToMove2 = atmIndex[atmIndex.length - 1];
    atmIndex[rowToDelete2] = keyToMove2;
    atms[keyToMove2].generalIndex = rowToDelete2;
    atmIndex.length--;
    delete atms[msg.sender];

    emit DeleteATM(msg.sender);

    return true;
  }

  /**
  * @dev getATMBrief - return brief details of an ATM info by atm owner's address
  */
  function getATMBrief(address _atmOwner) public view returns (
    bytes32 userId,
    int8 tokenType,
    address tokenAddress,
    uint tokenId,
    uint amountATM,
    int8 currencyId,
    int16 sellRate,
    bool buyer,
    int16 buyRate,
    uint generalIndex,
    bool online
    ) {
    ATM storage theATM = atms[_atmOwner];
    userId = theATM.userId;
    tokenType = theATM.tokenType;
    tokenAddress = theATM.tokenAddress;
    tokenId = theATM.tokenId;
    amountATM = theATM.amountATM;
    currencyId = theATM.currencyId;
    sellRate = theATM.sellRate;
    buyer = theATM.buyer;
    buyRate = theATM.buyRate;
    generalIndex = theATM.generalIndex;
    online = theATM.online;
  }

  /**
  * @dev getATMLocation - return location of an ATM info by atm owner's address
  */
  function getATMLocation(address _atmOwner) public view returns (
    int32 lat,
    int32 lng,
    bytes2 countryId,
    bytes16 postalCode
    ) {
    ATM storage theATM = atms[_atmOwner];
    lat = theATM.lat;
    lng = theATM.lng;
    countryId = theATM.countryId;
    postalCode = theATM.postalCode;
  }

  /**
  * @dev getAllATMs - return array of all ATM owners' addresses
  */
  function getAllATMs() public view returns (address[] memory) {
    return atmIndex;
  }

  /**
   * @dev sellCrypto - sell trx, trc10, trc20 from the ATM
   */
  function sellCrypto(address _to, uint _amount) external returns (bool) {
    require(isATM(msg.sender), "should be an ATM");
    require(_to != msg.sender, "shouldn't sell to yourself");
    require(atms[msg.sender].amountATM >= _amount, "should have sufficient balance");

    atms[msg.sender].amountATM = SafeMath.sub(atms[msg.sender].amountATM, _amount);
    if (_amount > 0) {
      if (atms[msg.sender].tokenType == 1) { // if TRX
        _to.transfer(_amount);
      } else if (atms[msg.sender].tokenType == 2) {  // if TRC10
        _to.transferToken(_amount, atms[msg.sender].tokenId);
      } else if (atms[msg.sender].tokenType == 3) { // if TRC20
        TRC20Basic tokenContract = TRC20Basic(atms[msg.sender].tokenAddress);
        tokenContract.transfer(_to, _amount);
      } else {
        return false;
      }
    }

    emit Sent(msg.sender, _to, _amount);
    return true;
  }

  /**
  * @dev changeRewardPool - set a new reward pool address, only owner can do it
  */
  function changeRewardPool(address _newRewardPool) public onlyOwner {
    require(_newRewardPool != address(0), "should be a valid address");
    rewardPool = _newRewardPool;
  }

  /**
  * @dev changefeeATM - set a new fee amount, only owner can do it
  */
  function changefeeATM(uint _newFeeATM) public onlyOwner {
    require(_newFeeATM > 0, "should be a valid amount");
    feeATM = _newFeeATM;
  }

  /**
  * @dev changefeeATM - set a new fee amount, only owner can do it
  */
  function changeTATMTokenContract(address _newContract) public onlyOwner {
    require(_newContract != address(0), "should be a valid address");
    TATMTRC20 = _newContract;
  }
}