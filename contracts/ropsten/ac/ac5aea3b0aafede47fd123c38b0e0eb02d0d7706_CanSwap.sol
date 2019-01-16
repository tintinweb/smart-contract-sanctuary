pragma solidity 0.4.25;


// CanYaCoinToken Functions used in this contract
contract ERC20 {
  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function burn(uint256 value) public returns (bool success);
  function transfer (address _to, uint256 _value) public returns (bool success);
}

// ERC223
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// Owned Contract
contract Owned {
  modifier onlyOwner { require(msg.sender == owner); _; }
  address public owner = msg.sender;
  event NewOwner(address indexed old, address indexed current);
  function setOwner(address _new) onlyOwner public { emit NewOwner(owner, _new); owner = _new; }
}



// AssetSplit Contract
contract CanSwap is Owned {
    
  using SafeMath for uint256;

  // Public Variables
  address public addrCAN;
  uint256 public bal_CAN;
  uint256 public intPools;
  
  ERC20 public CAN20;
  
  // Arrays 
  address[] public arrayTokens;
  uint256[] public arrayCAN;
  uint256[] public arrayTKN;

  // Events


  // Mapping
    mapping(address => uint256) TKNBalances_;                   // Map TKNbalances
    mapping(address => uint256) CANBalances_;                   // Map CANbalances
    mapping(address => uint256) TKNFeeBalances_;                // Map TKNFeebalances
    mapping(address => uint256) CANFeeBalances_;                // Map CANFeebalances
    
    mapping(address => mapping(address => uint256)) Stakes_;    // Map Stakes
    
  constructor (
    address _addrCAN) public {
        addrCAN = _addrCAN;
        CAN20 = ERC20(_addrCAN);
  }

  // Accepts ether from anyone
  function() public payable { } 
  
    // Swap Function
  function swap(address _from, address _to, uint256 _value) public returns (bool success) {
      swapFunction(_from, _to, _value, msg.sender);
      return true;
  }
      
  // Swap Function
  function swapAndSend(address _from, address _to, uint256 _value, address _dest) public returns (bool success) {
      swapFunction(_from, _to, _value, _dest);
      return true;
  }
  
  // Swap Function
  function swapFunction(address _from, address _to, uint256 _x, address _dest) private returns (bool success) {
      
      bool Single = false;
      uint256 sendValue;
      
      if(_from == addrCAN){
          if(_to == addrCAN){
          }
          Single = true;
      } else {
          if(_to == addrCAN){
              Single = true;
          }
      }
      
      if(Single){
        
        uint256 balX = getCANBalance(_from);
        uint256 balY = getTKNBalance(_to);
        uint256 feeY = getTKNFeeBalance(_to);
        
        uint256 y = getOutput(_x, balX, balY);
        uint256 liqFeeY = getLiqFee(_x, balX, balY);
        
        balX = balX.add(_x);
        balY = balY.sub(y);
        feeY = feeY + liqFeeY;
        
        CANBalances_[_from] = balX;
        TKNBalances_[_to] = balY;
        TKNFeeBalances_[_to] = feeY;
     
        sendValue = y;
        
      } else{
        
        
      }
      
        ERC20 poolToken = ERC20(_to);
        poolToken.transfer(_dest, sendValue);
        
        return true;
    }
    
    function getOutput(uint256 x, uint256 X, uint256 Y) private returns (uint256 outPut){
        uint256 numerator = (x.mul(Y)).mul(X);
        uint256 denom = x.add(X);
        uint256 denominator = denom.mul(denom);
        outPut = numerator.div(denominator);
        return outPut;
    }
    
    function getLiqFee(uint256 x, uint256 X, uint256 Y) private returns (uint256 liqFee){
        uint256 numerator = (x.mul(x)).mul(Y);
        uint256 denom = x.add(X);
        uint256 denominator = denom.mul(denom);
        liqFee = numerator.div(denominator);
        return liqFee;
    }

    // function getPool(uint256 _pool) private returns (address poolAddr){}
    
    function getTKNBalance(address _pool) private returns (uint256 _tknbalance){
        _tknbalance = TKNBalances_[_pool];
        return _tknbalance;
    }
    
    function getCANBalance(address _pool) private returns (uint256 _canbalance){
        _canbalance = CANBalances_[_pool];
        return _canbalance;
    }

    function getCANFeeBalance(address _pool) private returns (uint256 _canfeebalance){
        _canfeebalance = CANFeeBalances_[_pool];
        return _canfeebalance;    
    }
    
    function getTKNFeeBalance(address _pool) private returns (uint256 _tknfeebalance){
        _tknfeebalance = TKNFeeBalances_[_pool];
        return _tknfeebalance;    
    }
    
    // CreatePool
  function createPool(address _token, uint256 _amountCAN, uint256 _amountTKN) public returns (bool success) {

      intPools += 1;
            
      address[] storage arrayTokens;
      arrayTokens.push(_token);
      
      uint256[] storage arrayCAN;
      arrayCAN.push(_amountCAN);
      
      uint256[] storage arrayTKN;
      arrayCAN.push(_amountTKN);
      
      uint256 StakeAve = (_amountTKN.add(_amountCAN)).div(2);
      
      CANBalances_[_token] = _amountCAN;
      TKNBalances_[_token] = _amountTKN;
      Stakes_[msg.sender][_token] = StakeAve;
      
      ERC20 token = ERC20(_token);
      
      CAN20.transferFrom(msg.sender, address(this), _amountCAN);
      token.transferFrom(msg.sender, address(this), _amountTKN);
      
      return true;
  }

}