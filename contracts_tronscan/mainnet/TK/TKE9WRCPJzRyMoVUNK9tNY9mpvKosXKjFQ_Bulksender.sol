//SourceUnit: BulksenderTron_final.sol

pragma solidity ^0.4.25;


/**
 * @title BulkSender, support ETH、ERC-20 Tokens and TRX 、BTT、SEED、WINK and any TRC20 or TRC10 Tokens
 * @dev To Use this Dapp: https://bulksender.app https://tron.bulksender.app
*/

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}


interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);

}


contract Ownable is EternalStorage {

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }


    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }


    function setOwner(address newOwner) internal {
        addressStorage[keccak256("owner")] = newOwner;
    }



}

/**
 * @title BulkSender, support ETH、ERC-20 Tokens and TRX 、BTT、SEED、WINK and any TRC20 or TRC10 Tokens
 * @dev To Use this Dapp: https://bulksender.app https://tron.bulksender.app
*/

contract Bulksender is Ownable{

    using SafeMath for uint;
    event LogTokenBulkSent(address token,uint256 total);
    event LogTRC10BulkSent(trcToken id,uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    /*
  *  get balance
  */
  function getBalance(IERC20 token, trcToken id) onlyOwner public {
      address _receiverAddress = getReceiverAddress();
      if(token == address(0)){
          require(_receiverAddress.send(address(this).balance));
          return;
      }
      if(id > 1000000){
          _receiverAddress.transferToken(trc10TokenBalance(id, address(this)), id);
          return;
      }
      uint256 balance = token.balanceOf(this);
      token.transfer(_receiverAddress, balance);
      emit LogGetToken(token,_receiverAddress,balance);
  }

  function trc10TokenBalance(trcToken id, address _toAddress) public view returns (uint256){
      return _toAddress.tokenBalance(id);
  }

  function initialize(address _owner) public{
        require(!initialized());
        setOwner(_owner);
        setReceiverAddress(_owner);
        setTxFee(100*10**6);
        setVIPFee(30000*10**6);

        boolStorage[keccak256("initialized")] = true;


  }

  function() public payable {}

  function initialized() public view returns (bool) {
        return boolStorage[keccak256("initialized")];
  }

   /*
  *  Register VIP
  */
  function registerVIP() payable public {
      require(msg.value >= VIPFee());
      address _receiverAddress = getReceiverAddress();
      require(_receiverAddress.send(msg.value));
      boolStorage[keccak256(abi.encodePacked("vip", msg.sender))] = true;
  }



  /*
  *  VIP list
  */
  function addToVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      boolStorage[keccak256(abi.encodePacked("vip", _vipList[i]))] = true;
    }
  }

  /*
    * Remove address from VIP List by Owner
  */
  function removeFromVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      boolStorage[keccak256(abi.encodePacked("vip", _vipList[i]))] = false;
    }
   }

    /*
        * Check isVIP
    */
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner() || boolStorage[keccak256(abi.encodePacked("vip",_addr))];
    }

    /*
        * set receiver address
    */
    function setReceiverAddress(address _addr) onlyOwner public {
        require(_addr != address(0));
        addressStorage[keccak256("receiverAddress")] = _addr;

    }

    /*
        * get receiver address
    */
    function getReceiverAddress() public view returns  (address){
        address _receiverAddress = addressStorage[keccak256("receiverAddress")];
        if(_receiverAddress == address(0)){
            return owner();
        }
        return _receiverAddress;
    }

     /*
        * get vip fee
    */
    function VIPFee() public view returns (uint256) {
        return uintStorage[keccak256("vipFee")];
    }


     /*
        * set vip fee
    */
    function setVIPFee(uint256 _fee) onlyOwner public {
        uintStorage[keccak256("vipFee")] = _fee;
    }

    /*
        * set tx fee
    */
    function setTxFee(uint256 _fee) onlyOwner public {
        uintStorage[keccak256("txFee")] = _fee;
    }

    function txFee() public view returns (uint256) {
        return uintStorage[keccak256("txFee")];
    }

    function checkTxExist(bytes32 _txRecordId)  public view returns  (bool){
        return boolStorage[keccak256(abi.encodePacked("txRecord", msg.sender, _txRecordId))];
    }

    function addTxRecord(bytes32 _txRecordId) internal{
        boolStorage[keccak256(abi.encodePacked("txRecord", msg.sender, _txRecordId))] = true;
    }

    function _bulksendEther(address[] _to, uint256[] _values) internal {

        uint sendAmount = _values[0];
  uint remainingValue = msg.value;

     bool vip = isVIP(msg.sender);
        if(vip){
            require(remainingValue >= sendAmount);
        }else{
            require(remainingValue >= sendAmount.add(txFee())) ;
        }
  require(_to.length == _values.length);

  for (uint256 i = 1; i < _to.length; i++) {
   remainingValue = remainingValue.sub(_values[i]);
   require(_to[i].send(_values[i]));
  }
     emit LogTokenBulkSent(0x000000000000000000000000000000000000bEEF,msg.value);

    }

    function _bulksendToken(IERC20 _token, address[] _to, uint256[] _values)  internal  {
  uint sendValue = msg.value;
     bool vip = isVIP(msg.sender);
        if(!vip){
      require(sendValue >= txFee());
        }
  require(_to.length == _values.length);

        uint256 sendAmount = _values[0];
        _token.transferFrom(msg.sender,address(this), sendAmount);

  for (uint256 i = 1; i < _to.length; i++) {
      _token.transfer(_to[i], _values[i]);
  }
        emit LogTokenBulkSent(_token,sendAmount);

    }

    function _bulksendTokenSimple(IERC20 _token, address[] _to, uint256[] _values)  internal  {
  uint sendValue = msg.value;
     bool vip = isVIP(msg.sender);
        if(!vip){
      require(sendValue >= txFee());
        }
  require(_to.length == _values.length);

        uint256 sendAmount = _values[0];
  for (uint256 i = 1; i < _to.length; i++) {
      _token.transferFrom(msg.sender, _to[i], _values[i]);
  }
        emit LogTokenBulkSent(_token,sendAmount);

    }

function _bulksendTRC10(trcToken id, address[] _to, uint256[] _values)  internal  {
    uint sendValue = msg.value;
     bool vip = isVIP(msg.sender);
        if(!vip){
      require(sendValue >= txFee());
        }
    require(_to.length == _values.length);

    uint256 sendAmount = _values[0];
    for (uint256 i = 1; i < _to.length; i++) {
       _to[i].transferToken( _values[i], id);
    }
        emit LogTRC10BulkSent(id,sendAmount);

    }
    function bulksendTRC10(trcToken id,address[] _to, uint256[] _values, bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value));//refund the tx fee to msg send if the tx already exists
        }else{
            addTxRecord(_uniqueId);
         _bulksendTRC10(id, _to, _values);
        }
    }

    function bulksendTokenSimple(IERC20 _token, address[] _to, uint256[] _values, bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value));//refund the tx fee to msg send if the tx already exists
        }else{
            addTxRecord(_uniqueId);
         _bulksendTokenSimple(_token, _to, _values);
        }
    }

    function bulksendToken(IERC20 _token, address[] _to, uint256[] _values, bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value));//refund the tx fee to msg send if the tx already exists
        }else{
            addTxRecord(_uniqueId);
         _bulksendToken(_token, _to, _values);
        }
    }

    function bulksendEther(address[] _to, uint256[] _values,bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value));//refund the tx fee to msg send if the tx already exists
        }else{
            addTxRecord(_uniqueId);
         _bulksendEther(_to, _values);
        }
    }

}