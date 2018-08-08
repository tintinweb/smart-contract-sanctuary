pragma solidity ^ 0.4.24;

library ECRecovery {
  function recover(bytes32 hash, bytes sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return (address(0));
    }
    
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

contract ERC20 is ERC20Interface {
    using SafeMath for uint;

    uint _totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
}


contract ERC891 is ERC20 {
    using ECRecovery for bytes32;

    uint public constant maxReward = 50 * 10**18;
    mapping(address => bool) internal claimed;

    function claim() public {
        claimFor(msg.sender);
    }

    function claimFor(address _address) public returns(uint) {
        require(!claimed[_address]);
        
        uint reward = checkFind(_address);
        require(reward > 0);
        
        claimed[_address]   = true;
        balances[_address]  = balances[_address].add(reward);
        _totalSupply        = _totalSupply.add(reward);
        
        emit Transfer(address(0), _address, reward);
        
        return reward;
    }

    function checkFind(address _address) pure public returns(uint) {
        uint maxBitRun  = 0;
        uint data       = uint(bytes10(_address) & 0x3ffff);
        
        while (data > 0) {
            maxBitRun = maxBitRun + uint(data & 1);
            data = uint(data & 1) == 1 ? data >> 1 : 0;
        }
        
        return maxReward >> (18 - maxBitRun);
    }

    function claimWithSignature(bytes _sig) public {
        bytes32 hash = bytes32(keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender))
        )));
        
        address minedAddress = hash.recover(_sig);
        uint reward          = claimFor(minedAddress);

        allowed[minedAddress][msg.sender] = reward;
        transferFrom(minedAddress, msg.sender, reward);
    }
}

contract DigitalCarat is ERC891 {
    string  public constant name        = "Digital Carat";
    string  public constant symbol      = "DCD";
    uint    public constant decimals    = 18;
    uint    public version              = 0;
}