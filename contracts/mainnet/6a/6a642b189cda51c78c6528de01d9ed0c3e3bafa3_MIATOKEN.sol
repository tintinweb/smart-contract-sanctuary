pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply()public view returns(uint total_Supply);
    function balanceOf(address who)public view returns(uint256);
    function allowance(address owner, address spender)public view returns(uint);
    function transferFrom(address from, address to, uint value)public returns(bool ok);
    function approve(address spender, uint value)public returns(bool ok);
    function transfer(address to, uint value)public returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract MIATOKEN is ERC20
{
    using SafeMath for uint256;
    // Name of the token
    string public constant name = "MIATOKEN";

    // Symbol of token
    string public constant symbol = "MIA";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 35000000 * 10 ** 18; // 35 Million MIA Token
 
    address public owner;
    address superAdmin = 0x1313d38e988526A43Ab79b69d4C94dD16f4c9936;
    address socialOne = 0x52d4bcF6F328492453fAfEfF9d6Eb73D26766Cff;
    address socialTwo = 0xbFe47a096486B564783f261B324e198ad84Fb8DE;
    address founderOne = 0x5AD7cdD7Cd67Fe7EB17768F04425cf35a91587c9;
    address founderTwo = 0xA90ab8B8Cfa553CC75F9d2C24aE7148E44Cd0ABa;
    address founderThree = 0xd2fdE07Ee7cB86AfBE59F4efb9fFC1528418CC0E;
    address storage1 = 0x5E948d1C6f7C76853E43DbF1F01dcea5263011C5;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    modifier onlySuperAdmin() {
        require (msg.sender == superAdmin);
        _;
    }

    function MIATOKEN() public
    {
        owner = msg.sender;
        balances[superAdmin] = 12700000 * 10 ** 18;  // 12.7 million given to superAdmin
        balances[socialOne] = 3500000 * 10 ** 18;  // 3.5 million given to socialOne
        balances[socialTwo] = 3500000 * 10 ** 18;  // 3.5 million given to socialTwo
        balances[founderOne] = 2100000 * 10 ** 18; // 2.1 million given to FounderOne
        balances[founderTwo] = 2100000 * 10 ** 18; // 2.1 million given to FounderTwo
        balances[founderThree] = 2100000 * 10 ** 18; //2.1 million given to founderThree
        balances[storage1] = 9000000 * 10 ** 18; // 9 million given to storage1
        
        emit Transfer(0, superAdmin, balances[superAdmin]);
        emit Transfer(0, socialOne, balances[socialOne]);
        emit Transfer(0, socialTwo, balances[socialTwo]);
        emit Transfer(0, founderOne, balances[founderOne]);
        emit Transfer(0, founderTwo, balances[founderTwo]);
        emit Transfer(0, founderThree, balances[founderThree]);
        emit Transfer(0, storage1, balances[storage1]);
    }

    // what is the total supply of the ech tokens
    function totalSupply() public view returns(uint256 total_Supply) {
        total_Supply = _totalsupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner)public view returns(uint256 balance) {
        return balances[_owner];
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(_amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit  Transfer(_from, _to, _amount);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public returns(bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        emit  Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
        require(_owner != 0x0 && _spender != 0x0);
        return allowed[_owner][_spender];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    //In case the ownership needs to be transferred
    function transferOwnership(address newOwner)public onlySuperAdmin
    {
        require(newOwner != 0x0);
        owner = newOwner;
    }
}