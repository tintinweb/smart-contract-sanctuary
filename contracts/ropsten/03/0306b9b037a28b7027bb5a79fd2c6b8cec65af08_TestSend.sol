/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// 'Test' token contract
//
// Deployed to : 0x40B03b22C99E0Ed05035DCCCa0bC002a8Ce25a58
// Symbol      : Test
// Name        : TTT
// Total supply: 100000000
// Decimals    : 18
// ----------------------------------------------------------------------------


contract SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}



abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

}




contract TestSend is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;

    uint8   public constant decimals = 18;
    uint256 public constant DECIMALFACTOR = 10 ** uint256(decimals);
    uint256 public AIRDROP_SUPPLY = 10000000 * uint256(DECIMALFACTOR);
    uint256 public _totalSupply = 1000000000000 * uint256(DECIMALFACTOR);
    uint256 public claimedTokens = 0;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) locked;

    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Locked(address indexed from, uint256 indexed amount);
  
    constructor() public {
        symbol = "TestSend";
        name = "TTS";
        balances[0x09d5291C6313dC6a42317C814BDE827EBACDB658] = _totalSupply;
        emit Transfer(address(0), 0x09d5291C6313dC6a42317C814BDE827EBACDB658, _totalSupply);
    }
    
    
    

    mapping (address => bool) public airdropReceivers;

    event AirDropped (
        address[] _recipients, 
        uint256 _amount, 
        uint256 claimedTokens);

   
    function airDrop(address[] calldata _recipients, uint256  _amount) external onlyOwner {
        require(_amount > 0);
        uint256 airdropped;
        uint256 amount = _amount * uint256(DECIMALFACTOR);
        for (uint256 index = 0; index < _recipients.length; index++) {
            if (!airdropReceivers[_recipients[index]]) {
                airdropReceivers[_recipients[index]] = true;
                this.transfer(_recipients[index], amount);
                airdropped = airdropped + amount;
            }
        }
    AIRDROP_SUPPLY = AIRDROP_SUPPLY - airdropped;
    _totalSupply = _totalSupply - airdropped;
    claimedTokens = claimedTokens + airdropped;
    emit AirDropped(_recipients, _amount, claimedTokens);
    }

    
     function lockedAmount(address _owner, uint256 _amount) public onlyOwner returns (uint256) {
        uint256 lockingAmount = locked[_owner] + _amount;
        require(balances[_owner] >= lockingAmount, "Locking amount must not exceed balance");
        locked[_owner] = lockingAmount;
        emit Locked(_owner, lockingAmount);
        return lockingAmount;
        }
    
    
        function unLockAmout(address _owner, uint256 _amount) onlyOwner public returns (uint256) {
        require(locked[_owner] > 0, "Cannot go negative. Already at 0 locked tokens.");
        uint256 lockingAmount = locked[_owner] - _amount;
        locked[_owner] = lockingAmount;
        emit Locked(_owner, lockingAmount);
        return lockingAmount;
        }

        function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;           
        _totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
        }
    
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowed[_from][msg.sender]);    
        balances[_from] -= _value;                         
        allowed[_from][msg.sender] -= _value;             
        _totalSupply -= _value;                           
        emit Burn(_from, _value);
        return true;
        }
    
        function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
        }
   
   
        function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
        }



   
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


   
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


 
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


  
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}