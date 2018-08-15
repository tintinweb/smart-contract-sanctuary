pragma solidity 0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    uint256 public _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    function totalSupply() public constant returns (uint256 supply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20

contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/**
 * @title ERC677 transferAndCall token interface
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and
 *      discussion.
 */
contract ERC677 {
    event Transfer(address indexed _from, address indexed _to, uint256 _amount, bytes _data);

    function transferAndCall(address _receiver, uint _amount, bytes _data) public;
}


/**
 * @title Receiver interface for ERC677 transferAndCall
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and
 *      discussion.
 */
contract ERC677Receiver {
    function tokenFallback(address _from, uint _amount, bytes _data) public;
}

contract ERC677Token is ERC677, ERC20Token {
    function transferAndCall(address _receiver, uint _amount, bytes _data) public {
        require(super.transfer(_receiver, _amount));

        emit Transfer(msg.sender, _receiver, _amount, _data);

        // call receiver
        if (isContract(_receiver)) {
            ERC677Receiver to = ERC677Receiver(_receiver);
            to.tokenFallback(msg.sender, _amount, _data);
        }
    }

    function isContract(address _addr) internal view returns (bool) {
        uint len;
        assembly {
            len := extcodesize(_addr)
        }
        return len > 0;
    }
}

contract Splitable is ERC677Token, Ownable {
    uint32 public split;
    mapping (address => uint32) public splits;

    event Split(address indexed addr, uint32 multiplyer);

    constructor() public {
        split = 0;
    }

    function splitShare() onlyOwner public {
        require(split * 2 >= split);
        if (split == 0) split = 2;
        else split *= 2;
        claimShare();
    }

    function isSplitable() public view returns (bool) {
        return splits[msg.sender] != split;
    }

    function claimShare() public {
        uint32 s = splits[msg.sender];
        if (s == split) return;
        if (s == 0) s = 1;

        splits[msg.sender] = split;
        uint b = balances[msg.sender];
        uint nb = b * split / s;

        balances[msg.sender] = nb;
        _totalSupply += nb - b;
    }

    function claimShare(address _u1, address _u2) public {
        uint32 s = splits[_u1];
        if (s != split) {
            if (s == 0) s = 1;

            splits[_u1] = split;
            uint b = balances[_u1];
            uint nb = b.mul(split / s);

            balances[_u1] = nb;
            _totalSupply += nb - b;
        }
        s = splits[_u2];
        if (s != split) {
            if (s == 0) s = 1;

            splits[_u2] = split;
            b = balances[_u2];
            nb = b.mul(split / s);
            
            balances[_u2] = nb;
            _totalSupply += nb - b;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (splits[msg.sender] != splits[_to]) claimShare(msg.sender, _to);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (splits[_from] != splits[_to]) claimShare(msg.sender, _to);
        return super.transferFrom(_from, _to, _value);
    }

    function transferAndCall(address _receiver, uint _amount, bytes _data) public {
        if (splits[_receiver] != splits[_receiver]) claimShare(msg.sender, _receiver);
        return super.transferAndCall(_receiver, _amount, _data);
    }
}

contract Lockable is ERC20Token, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) public lockAmounts;

    // function lock(address to, uint amount) public onlyOwner {
    //     lockAmounts[to] = lockAmounts[to].add(amount);
    // }

    function unlock(address to, uint amount) public onlyOwner {
        lockAmounts[to] = lockAmounts[to].sub(amount);
    }

    function issueCoin(address to, uint amount) public onlyOwner {
        lockAmounts[to] = lockAmounts[to].add(amount);
        transfer(to, amount);
    //  balances[to] = balances[to].add(amount);
    //  balances[owner] = balances[owner].sub(amount);
    //  emit Transfer(owner, to, amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value + lockAmounts[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value + lockAmounts[_from]);
        return super.transferFrom(_from, _to, _value);
    }
}

contract VCoin is ERC677Token, Ownable, Splitable, Lockable {
    uint32 public purchaseNo;
    event Purchase(uint32 indexed purchaseNo, address from, uint value, bytes data);

    constructor() public {
        symbol = "VICT";
        name = "Victory Token";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);

        purchaseNo = 1;
    }

    function () public payable {
        require(!isContract(msg.sender));
        owner.transfer(msg.value);
        emit Purchase(purchaseNo++, msg.sender, msg.value, msg.data);
        //emit Transfer(owner, msg.sender, msg.value);
    }
}