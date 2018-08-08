pragma solidity ^0.4.23;

contract EtherDeltaI {

  uint public feeMake;
  uint public feeTake;

  mapping (address => mapping (address => uint)) public tokens;
  mapping (address => mapping (bytes32 => bool)) public orders;
  mapping (address => mapping (bytes32 => uint)) public orderFills;

  function deposit() payable;
  function withdraw(uint amount);
  function depositToken(address token, uint amount);
  function withdrawToken(address token, uint amount);
  function balanceOf(address token, address user) constant returns (uint);
  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce);
  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount);
  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool);
  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);
  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s);

}

contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract KeyValueStorage {

  mapping(address => mapping(bytes32 => uint256)) _uintStorage;
  mapping(address => mapping(bytes32 => address)) _addressStorage;
  mapping(address => mapping(bytes32 => bool)) _boolStorage;
  mapping(address => mapping(bytes32 => bytes32)) _bytes32Storage;

  /**** Get Methods ***********/

  function getAddress(bytes32 key) public view returns (address) {
      return _addressStorage[msg.sender][key];
  }

  function getUint(bytes32 key) public view returns (uint) {
      return _uintStorage[msg.sender][key];
  }

  function getBool(bytes32 key) public view returns (bool) {
      return _boolStorage[msg.sender][key];
  }

  function getBytes32(bytes32 key) public view returns (bytes32) {
      return _bytes32Storage[msg.sender][key];
  }

  /**** Set Methods ***********/

  function setAddress(bytes32 key, address value) public {
      _addressStorage[msg.sender][key] = value;
  }

  function setUint(bytes32 key, uint value) public {
      _uintStorage[msg.sender][key] = value;
  }

  function setBool(bytes32 key, bool value) public {
      _boolStorage[msg.sender][key] = value;
  }

  function setBytes32(bytes32 key, bytes32 value) public {
      _bytes32Storage[msg.sender][key] = value;
  }

  /**** Delete Methods ***********/

  function deleteAddress(bytes32 key) public {
      delete _addressStorage[msg.sender][key];
  }

  function deleteUint(bytes32 key) public {
      delete _uintStorage[msg.sender][key];
  }

  function deleteBool(bytes32 key) public {
      delete _boolStorage[msg.sender][key];
  }

  function deleteBytes32(bytes32 key) public {
      delete _bytes32Storage[msg.sender][key];
  }

}

contract StorageStateful {
  KeyValueStorage public keyValueStorage;
}

contract Token {
  function totalSupply() public returns (uint256);
  function balanceOf(address _owner) public returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint256 public decimals;
  string public name;
}


contract ExchangeImplementation is StorageStateful, SafeMath {

    address public admin;
    address public feeAccount;
    
    struct EtherDeltaInfo {
        uint256 feeMake;
        uint256 feeTake;
    }
    
    EtherDeltaInfo public etherDeltaInfo;
    
    uint256 public feeTake;
    address public etherDelta;
    bytes32 public typeHash;
    
    mapping (address => mapping (uint256 => bool)) nonceCheck;
    mapping (address => mapping (address => uint256)) public tokens;
    mapping (address => mapping (bytes32 => bool)) public orders;
    mapping (address => mapping (bytes32 => uint256)) public orderFills;
    
    address internal implementation;
    address public proposedImplementation;
    uint256 public proposedTimestamp;
    
    event Order(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive, uint256 nonce, address indexed user);
    event Cancel(address indexed tokenGet, uint256 amountGet, address indexed tokenGive, uint256 amountGive,uint256 nonce, address indexed user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenGet, uint256 amountGet, address tokenGive, uint256 amountGive, address indexed get, address indexed give, uint8 exchange);
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyEtherDelta {
        require(msg.sender == etherDelta);
        _;
    }

    function setEtherDeltaFees() public onlyAdmin {
        etherDeltaInfo.feeMake = EtherDeltaI(etherDelta).feeMake();
        etherDeltaInfo.feeTake = EtherDeltaI(etherDelta).feeTake();
    }
    
    function() public payable onlyEtherDelta {
    }

    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    function changeFeeAccount(address _feeAccount) public onlyAdmin {
        require(_feeAccount != address(0));
        feeAccount = _feeAccount;
    }

    function changeFeeTake(uint256 _feeTake) public onlyAdmin {
        feeTake = _feeTake;
    }
    
    function changeTypeHash(bytes32 _typeHash) public onlyAdmin {
        typeHash = _typeHash;
    }

    function deposit() public payable {
        tokens[address(0)][msg.sender] = add(tokens[address(0)][msg.sender],msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }

    function depositToken(address _token, uint256 _amount) public {
        require(_token != address(0));
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] = add(tokens[_token][msg.sender],_amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }
    
    function processDeposit(address _token, uint256 _amount) internal {
        if (_token == address(0)) {
            deposit();
        } else {
            depositToken(_token, _amount);
        }
    }
  
    function withdraw(uint256 _amount) public {
        if (tokens[address(0)][msg.sender] < _amount) revert("User does not have enough Eth to withdraw");
        tokens[address(0)][msg.sender] = sub(tokens[address(0)][msg.sender], _amount);
        if (!msg.sender.call.value(_amount)()) revert("User did not provide enough eth");
        emit Withdraw(address(0), msg.sender, _amount, tokens[address(0)][msg.sender]);
    }
    
    function withdrawToken(address _token, uint256 _amount) public {
        if (tokens[_token][msg.sender] < _amount) revert("User does not have enough Eth to withdraw");
        tokens[_token][msg.sender] = sub(tokens[_token][msg.sender], _amount);
        if (!Token(_token).transfer(msg.sender, _amount)) revert("User did allow transfer of tokensh");
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }
    
    function withdrawEthMaker(uint256 _amount, address _maker) internal {
        if (tokens[address(0)][_maker] < _amount) revert("User does not have enough Eth to withdraw");
        tokens[address(0)][_maker] = sub(tokens[address(0)][_maker], _amount);
        if (!msg.sender.call.value(_amount)()) revert("User did not provide enough eth");
        emit Withdraw(address(0), _maker, _amount, tokens[address(0)][_maker]);
    }
    
    function withdrawTokenMaker(address _token, uint256 _amount, address _maker) internal {
        if (tokens[_token][_maker] < _amount) revert("User does not have enough Eth to withdraw");
        tokens[_token][_maker] = sub(tokens[_token][_maker], _amount);
        if (!Token(_token).transfer(_maker, _amount)) revert("User did allow transfer of tokens");
        emit Withdraw(_token, _maker, _amount, tokens[_token][_maker]);
    }
    
    function withdrawTaker(address _token, uint256 _amount) internal {
        if (_token == address(0)) {
            withdraw(_amount);
        } else {
            withdrawToken(_token, _amount);
        }
    }
    
    function withdrawMaker(address _token, uint256 _amount, address _maker) internal {
        if (_token == address(0)) {
            withdrawEthMaker(_amount, _maker);
        } else {
            withdrawTokenMaker(_token, _amount, _maker);
        }
    }
    
    function balanceOf(address _token, address _user) public constant returns (uint256) {
        return tokens[_token][_user];
    }
    
    function createOrder(address _tokenBuy, uint256 _amountBuy, address _tokenSell, 
                         uint256 _amountSell, uint256 _nonce) public payable {
        processDeposit(_tokenSell, _amountSell);
        bytes32 orderHash = keccak256(abi.encodePacked(this, _tokenBuy, _amountBuy, _tokenSell, _amountSell, _nonce));
        orders[msg.sender][orderHash] = true;
        emit Order(_tokenBuy, _amountBuy, _tokenSell, _amountSell, _nonce, msg.sender);
    }
    
    function cancelOrder(address _tokenBuy, uint256 _amountBuy, address _tokenSell, 
                         uint256 _amountSell, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 orderHash = keccak256(abi.encodePacked(this, _tokenBuy, _amountBuy, _tokenSell, _amountSell, _nonce));
        if (!orders[msg.sender][orderHash]) revert("Order does not exist");
        if (!verifySignature(_v, _r, _s, msg.sender, orderHash)) revert("Signature is invalid");
        if (_tokenSell == address(0)) {
            withdraw(sub(_amountSell, orderFills[msg.sender][orderHash]));
        } else {
            withdrawToken(_tokenSell, sub(_amountSell, orderFills[msg.sender][orderHash]));
        }
        orderFills[msg.sender][orderHash] = _amountBuy;
        emit Cancel(_tokenBuy, _amountBuy, _tokenSell, _amountSell, _nonce, msg.sender, _v, _r, _s);
      }
    
    function verifySignature(uint8 _v, bytes32 _r, bytes32 _s, address _user, 
                             bytes32 _tradeHash) public view returns (bool) {
        return (ecrecover(keccak256(abi.encodePacked(typeHash, _tradeHash)), _v, _r, _s) == _user);
    }
    
    function trade(address _tokenBuy, uint256 _amountBuy, address _tokenSell, 
                    uint256 _amountSell, uint256 _nonce, address _user, uint8 _v, 
                    bytes32 _r, bytes32 _s, uint256 _amount) public payable {
        processDeposit(_tokenBuy, mul(_amountBuy, _amount) / _amountSell);
        bytes32 orderHash = keccak256(abi.encodePacked(this, _tokenBuy, _amountBuy, _tokenSell, _amountSell, _nonce));
        if (!verifySignature(_v, _r, _s, _user, orderHash)) revert("Order hash signature is not valid");
        if (!orders[_user][orderHash]) revert("Owner of order never created order");
        if (!(add(orderFills[_user][orderHash], _amount) <= _amountBuy)) revert("Order filled");
        
        _trade(_tokenBuy, _amountBuy, _tokenSell, _amountSell, _user, _amount);
        withdrawTaker(_tokenSell, mul(_amountSell, _amount) / _amountBuy);
        withdrawMaker(_tokenBuy, tokens[_tokenBuy][_user], _user);
        
        orderFills[_user][orderHash] = add(orderFills[_user][orderHash], _amount);
    }
    
    function _trade(address _tokenBuy, uint256 _amountBuy, address _tokenSell,
                    uint256 _amountSell, address _user, uint256 _amount) internal returns (bool) {
        uint256 feeTakeXfer = mul(_amount, feeTake) / 1 ether;
        tokens[_tokenBuy][msg.sender] = sub(tokens[_tokenBuy][msg.sender], add(_amount, feeTakeXfer));
        tokens[_tokenBuy][_user] = add(tokens[_tokenBuy][_user], _amount);
        tokens[_tokenBuy][feeAccount] = add(tokens[_tokenBuy][feeAccount], feeTakeXfer);
        tokens[_tokenSell][_user] = sub(tokens[_tokenSell][_user], mul(_amountSell, _amount) / _amountBuy);
        tokens[_tokenSell][msg.sender] = add(tokens[_tokenSell][msg.sender], mul(_amountSell, _amount) / _amountBuy);
        
        return true;
    }

}