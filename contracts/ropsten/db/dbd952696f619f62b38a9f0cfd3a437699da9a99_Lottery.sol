pragma solidity ^0.4.24;

/**
 * title SafeMath
 * @dev Math operations with safety checks that throw on error
*/

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}

contract Lottery is Ownable{
    using SafeMath for uint;
    
    uint private point;
    uint private nonce;
    mapping(bytes32 => bytes32) private keys;
    mapping(bytes32 => uint) private balances;
    mapping(bytes32 => uint) private holds;
    mapping(bytes32 => uint[]) private blocks;
    
    constructor(uint _point) public {
        point = _point;
    }
    
    function draw(uint minBalance, bytes32[] _uids) payable onlyOwner public returns (bytes32) {
        uint sum = 0;
        uint i = 0;
        for (i = 0; i < _uids.length; i++) {
            if (holds[keccak256(abi.encodePacked(_uids[i]))] < minBalance) {
                return "fail";
            }
        }
        for (i = 0; i < _uids.length; i++) {
            sum = sum.add(uint(keys[keccak256(abi.encodePacked(_uids[i]))]) % point);
            balances[keccak256(abi.encodePacked(_uids[i]))] = balances[keccak256(abi.encodePacked(_uids[i]))].sub(minBalance);
            holds[keccak256(abi.encodePacked(_uids[i]))] = holds[keccak256(abi.encodePacked(_uids[i]))].sub(minBalance);

        }
        uint index = uint(sum % _uids.length);
        bytes32 winner = keccak256(abi.encodePacked(_uids[index]));
        uint balance = minBalance.mul(_uids.length);
        uint percent = balance.div(100).mul(15);
        balances[keccak256(abi.encodePacked(winner))].add(balance.sub(percent));
        return winner;
    }
    
    function join(uint fee, bytes32 _uid) onlyOwner public returns(bool) {
        if (balances[keccak256(abi.encodePacked(_uid))] < fee) {
            return false;
        }
        holds[keccak256(abi.encodePacked(_uid))] = holds[keccak256(abi.encodePacked(_uid))].add(fee);
        return true;
    }
    
    function widraw(uint value, address _to, bytes32 _uid) payable onlyOwner public {
	balances[keccak256(abi.encodePacked(_uid))] = balances[keccak256(abi.encodePacked(_uid))].sub(value);
        _to.transfer(value);
    }
    
    function balanceOf(bytes32 _uid) public view returns(uint) {
        return balances[keccak256(abi.encodePacked(_uid))];
    }
    
    function holdOf(bytes32 _uid) public view returns(uint) {
        return holds[keccak256(abi.encodePacked(_uid))];
    }
    
    function () payable public {
        nonce++;
        if (msg.value == 0) {
            revert();
        }
        bytes32 _uid = keccak256(abi.encodePacked(msg.data));
        bytes32 seed = keccak256(abi.encodePacked(block.number, now, nonce, blockhash(block.number)));
        keys[_uid] = keccak256(abi.encodePacked(owner, msg.sender, seed));
        balances[_uid] = balances[_uid].add(msg.value);
        blocks[_uid].push(block.number);
    }
}