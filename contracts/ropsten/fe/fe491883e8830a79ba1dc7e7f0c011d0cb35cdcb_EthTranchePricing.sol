pragma solidity ^0.4.24;
contract Ownable {
  address private _owner;


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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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
contract EthTranchePricing is Ownable {
    using SafeMath for uint256;
    bool public _trancheTimeStatus = false;
    bool public _trancheWeiStatus = false;
    uint256 public _stageRaised = 0;
    uint256 _decimals = 18;
    uint256 public _nextTrancheStage=0;
    uint256 public _nextTranchePrice=0;
    uint256 public _sum = 0;
    uint256 public _rest = 0;
    uint256 public _restValue = 0;
    
    uint256 public constant MAX_TRANCHES = 8;
   
    
    
    struct Tranches {
        uint256 _stage;
        uint256 _price;
    }

    Tranches[MAX_TRANCHES] public _tranches;
    uint256 trancheCount;
    
    modifier onlyTrancheStatus(){
       require(_trancheTimeStatus == false);
       require(_trancheWeiStatus == false);
        _;
    }
    
    
    function setTranchTime(uint256[] tranches)public  onlyTrancheStatus onlyOwner {
        require(!(tranches.length % 2 == 1 || tranches.length >= MAX_TRANCHES*2));

        trancheCount = _tranches.length / 2;
        uint8 j;
        for(uint8 i=0; i<_tranches.length/2; i++) {
         j = i;
         
         if(tranches[j*2] < 6){
             require(block.timestamp >= tranches[j*2] && tranches[j*2] < tranches[j*2+2] );
         }else if(tranches[j*2] == 6){
             require(tranches[j*2] > tranches[j*2-2]  );
         }
          _tranches[i]._stage = tranches[i*2];
          
          _tranches[i]._price = tranches[i*2+1];
          
            
        }
        _trancheTimeStatus = true;
    }
    function setTranchWei(uint256[] tranches)public  onlyTrancheStatus onlyOwner{
        require(!(tranches.length % 2 == 1 || tranches.length >= MAX_TRANCHES*2));
        trancheCount = _tranches.length / 2 ; 
        uint256 highestAmount = 0;
        require(_tranches[0]._stage == 0);
        for(uint i=0; i<_tranches.length/2; i++){
            _tranches[i]._stage = tranches[i*2] * 10 ** _decimals;
            _tranches[i]._price = tranches[i*2+1] * 10 ** _decimals;
            
            require(!((highestAmount != 0) && (_tranches[i]._stage <= highestAmount)));
            highestAmount = _tranches[i]._stage;
        }
        require(_tranches[0]._stage == 0);
        require(_tranches[trancheCount-1]._price == 0);
        _trancheWeiStatus = true;
    }
    
    function getTranche(uint256 n) public constant returns (uint256, uint256) {
    return (_tranches[n]._stage, _tranches[n]._price);
  }
  
  function getFirstTranche() private constant returns (Tranches) {
    return _tranches[0];
  }
  
  function getLastTranche() private constant returns (Tranches) {
    return _tranches[trancheCount-1];
  }

  function getPricingStartsAt() public constant returns (uint256) {
    return getFirstTranche()._stage;
  }

  function getPricingEndsAt() public constant returns (uint256) {
    return getLastTranche()._stage;
  }

    function getCurrentTranche(uint256 stageRaised) private constant returns (Tranches) {
    uint256 i;
    for(i=0; i < _tranches.length; i++) {
      if(stageRaised < _tranches[i]._stage) {
        return _tranches[i-1];
      }
    }
  }
  function getNextTranche(uint256 stageRaised) private  returns (Tranches) {
    uint256 i;
    for(i=0; i < _tranches.length; i++) {
      if(stageRaised <= _tranches[i]._stage) {
        if(i == 3){
            _tranches[3]._stage = _tranches[i]._stage;
            _tranches[3]._price = _tranches[i-1]._price;
            return _tranches[3];
        }else{
            return _tranches[i];
        }
        
      }
    }
  }

    function getCurrentPrice(uint stageRaised) public constant returns (uint256 result) {
    return getCurrentTranche(stageRaised)._price;
  }

function calculatePrice(uint256 value) external  returns (uint256) {
    
    uint256 multiplier = 10 ** _decimals;
    uint256 _result;
    uint256 price;
   
    if(_trancheTimeStatus == true && _trancheWeiStatus == false ){
        _stageRaised = block.timestamp;
        price = getCurrentPrice(_stageRaised);
        _result = value.mul(multiplier).div(price);
        
    }else if(_trancheTimeStatus == false && _trancheWeiStatus == true){
        
        _nextTrancheStage = getNextTranche(_stageRaised)._stage;
        
        _nextTranchePrice = getNextTranche(_stageRaised)._price;
        
        _sum = _stageRaised.add(value);
          
        if(  _sum >= _nextTrancheStage ){
            
            _rest =  _sum.sub(_nextTrancheStage);
            _restValue = value;
            _restValue = _restValue.sub(_rest);
            
            uint256 _price = getCurrentPrice(_stageRaised);
             _result = ((_restValue.mul(multiplier).div(_price)).add(_rest.mul(multiplier).div(_nextTranchePrice)));
        }else{
             price = getCurrentPrice(_stageRaised);
            _result = value.mul(multiplier).div(price);
        }
     
         _stageRaised = _stageRaised.add(value);
    }    
    return _result;
  }

  function()public payable {
    require(false); // No money on this contract
  }
  
  
}