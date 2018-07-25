pragma solidity ^0.4.24;

library SafeMath {
  /**
  @dev Multiplies two numbers, throws on overflow.
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
  @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EvolGame {
    event logChannel(
        address __userAddress,
        address senderAddr
    );
    
    event Logchan (
        bytes id,
        address _address,
        uint w,
        uint[] g,
        uint[] pw,
        uint[] pi
    );
    
    uint8[] public wilds = [1,2,3,4,5,6,7,8,9,10,11,12,13];
    uint8[] public items = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];
    
    struct Inventory {
        uint[] _wild;
        uint[] _inventary;
    }
    
    struct Session {
        bytes _id;
        address _playerAddress;
        uint _wild;
        uint[] _inv;
    }

    using SafeMath for uint;
    mapping(address => Inventory) _playerInventory;
    mapping(address => uint) _rnd;
    mapping(address => uint) _loot;
    mapping(bytes => Session) _channel;
    
    function getInventory(address _userAddress) public view returns(uint[]) {
        return _playerInventory[_userAddress]._inventary;
    }
    
    function getWilds(address _userAddress) public view returns(uint[]) {
        return _playerInventory[_userAddress]._wild;
    }
    
    function initNewPlayer(address _userAddress, bytes _seed) public {
        Inventory storage _inv = _playerInventory[_userAddress];
        
        if (_inv._wild.length < 3) {
            _inv._wild.push(1);
            _inv._wild.push(2);
            _inv._wild.push(3);
        }
    }
    
    function generateRnd(bytes _sigseed, uint _min, uint _max) public pure returns(uint) {
        return uint256(keccak256(_sigseed)) % (_max.sub(_min).add(1)).add(_min);
    }
    
    function getItem(address _userAddress) public view returns(uint) {
        return _loot[_userAddress];
    }
    
    function startGame(
        bytes _sessionId,
        address _userAddress,
        uint _wild,
        uint[] _genoms,
        bytes _sign
    ) public {
        uint[] _playerWild = _playerInventory[_userAddress]._wild;
        uint[] _playerInv = _playerInventory[_userAddress]._inventary;
        require(msg.sender == _userAddress);
        address _signer = recoverSigner(keccak256(abi.encodePacked(_sessionId, _userAddress, _genoms, _wild, _playerWild, _playerInv)), _sign);
        emit Logchan(_sessionId, _userAddress, _wild, _genoms, _playerWild, _playerInv);
        emit logChannel(_signer, msg.sender);
        require(_signer == _userAddress);
    }
    
    function closeGame(
        bytes _sessionId,
        address _userAddress,
        uint _wild,
        uint[] _genoms,
        bytes _seed,
        bytes _sign
    ) public {
        uint[] _playerWild = _playerInventory[_userAddress]._wild;
        uint[] _playerInv = _playerInventory[_userAddress]._inventary;
        require(msg.sender == _userAddress);
        address _signer = recoverSigner(keccak256(abi.encodePacked(_sessionId, _userAddress, _genoms, _wild, _playerWild, _playerInv)), _sign);
        require(_signer == _userAddress);
        
        endGame(_userAddress, _seed);
    }
    
    function endGame(address _userAddress, bytes _seed) {
        uint rnd = generateRnd(_seed, 1, items.length);
        
        for (uint i = 0; i < items.length; i++) {
            if (items[i] == rnd) {
                _loot[_userAddress] = rnd;
                _playerInventory[_userAddress]._inventary.push(_loot[_userAddress]);
            }
        }
    }
    
    function recoverSigner(bytes32 _hash, bytes signature) public pure returns(address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = signatureSplit(signature);
        return ecrecover(_hash, v, r, s);
    }
    
    function signatureSplit(bytes signature) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 0xff)
        }
        require(v == 27 || v == 28);
    }
}