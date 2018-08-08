pragma solidity ^0.4.8;

///address -> uint256 mapping.
library IterableMapping
{
    struct IndexValue { uint keyIndex; uint value; }
    struct KeyFlag { address key; bool deleted; }
    struct itmap
    {
        mapping(address => IndexValue) data;
        KeyFlag[] keys;
        uint size;
    }

    function insert(itmap storage self, address key, uint value) internal returns (bool replaced)
    {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else
        {
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }
    function remove(itmap storage self, address key) internal returns (bool success)
    {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }
    function contains(itmap storage self, address key) internal returns (bool)
    {
        return self.data[key].keyIndex > 0;
    }
    function iterate_start(itmap storage self) internal returns (uint keyIndex)
    {
        return iterate_next(self, uint(-1));
    }
    function iterate_valid(itmap storage self, uint keyIndex) internal returns (bool)
    {
        return keyIndex < self.keys.length;
    }
    function iterate_next(itmap storage self, uint keyIndex) internal returns (uint r_keyIndex)
    {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }
    function iterate_get(itmap storage self, uint keyIndex) internal returns (address key, uint value)
    {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

/**
 *Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal returns (uint){
        uint c = a * b;
        assert(a == 0 || c / a ==b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        //assert(b > 0); //Solidity automatically throws when dividing by 0
        uint c = a/b;
        // assert(a == b * c + a% b); //There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b<=a);
        return a-b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if(!assertion){
            throw;
        }
    }
}


/**
 * title ERC20 Basic
 * dev Simpler version of ERC20 interface
 * dev see https://github.com/ethereum/EIPs/issues/20
 *
 */
contract ERC20Basic{
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * title Basic token
 * dev Basic version of StandardToken, eith no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;
    /**
    * dev Fix for eht ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4){
            throw;
        }
        _;
    }
}


/**
* title ERC20 interface
* dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
* title Standard ERC20 token
*
* dev Implemantation of the basic standart token.
* dev https://github.com/ethereum/EIPs/issues/20
* dev Based on code by FirstBlood:http://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
**/
contract StandardToken is BasicToken, ERC20{
    mapping (address => mapping (address => uint)) allowed;
    event Burn(address from, address to, uint value);
    event TransferFrom(address from, uint value);
    event Dividends(address from, address to, uint value);

    /**
    * dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
    * param _spender The address which will spend the funds.
    * param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) {
        //To change the approve amount you first have to reduce the addresses
        // allowance to zero by calling approve(_spender, 0) if if it not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuscomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
    * dev Function to check the amount of token rhan an owner allowed to a spender.
    * param _owner address Thr address whivh owns the funds.
    * param _spender address The address which will spend the funds.
    * return A uint specifing the amount of tokrns still avaible for the spender.
    **/
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {
    address public owner;

    function Ownable(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender != owner){
            throw;
        }
        _;
    }

//    function transferOwnership(address newOwner) onlyOwner{
//        if (newOwner != address(0)){
//            owner = newOwner;
//        }
//    }
}

contract GlobalCoin is Ownable, StandardToken{
    uint256 public decimals = 8;
    string public name = "GBCToken";
    string public symbol = "GBC";
    uint public totalSupply = 1000000000000000;//1后面15个0 ,发行1000，0000 ，后面是00000000,对应小数点后8个0
    address public dividendAddress = 0x1D33776a090a2F321FF596C0C011F2f414f3A527;//分红地址
    address public burnAddress = 0x0000000000000000000000000000000000000000; //销毁GBC地址
    uint256 private globalShares = 0;
    mapping (address => uint256) private balances;
    mapping (address => uint256) private vips;
    using IterableMapping for IterableMapping.itmap;
    IterableMapping.itmap public data;
    using SafeMath for uint256;

    modifier noEth() {
        if (msg.value < 0) {
            throw;
        }
        _;
    }
    function() {
        // 当有人发送eth或者Token，会触发这个事件
        if (msg.value > 0)
            TransferFrom(msg.sender, msg.value);
    }

    function insert(address k, uint v) internal returns (uint size)
    {
        IterableMapping.insert(data, k, v);
        return data.size;
    }
        //预计分多少红
    function expectedDividends(address user) constant returns (uint Dividends){
        return balances[dividendAddress] / globalShares * vips[user];
    }

//    //显示有多少GBC
    function balanceOf(address addr) constant returns (uint balance) {
        return balances[addr];
    }
    //显示有多少股
    function yourShares(address addr) constant returns (uint shares) {
        return vips[addr];
    }

    function transfer(address to, uint256 amount) onlyPayloadSize(2 * 32)
    {
        if (to == burnAddress) {
            return burn(amount);
        }
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        Transfer(msg.sender, to, amount);
    }
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

    //Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }
    function burn (uint256 amount) //获得分红
    {
        if (amount >= 100000000000) {
            vips[msg.sender] += amount / 100000000000;
            globalShares += amount / 100000000000;
            insert(msg.sender, vips[msg.sender]);
            balances[msg.sender] = balances[msg.sender].sub(amount);
            balances[burnAddress] = balances[burnAddress].add(amount);
            Burn(msg.sender, burnAddress, amount);
        }
    }


    //查看全球一共多少股
    function totalShares() constant returns (uint shares){
        return globalShares;
    }


    //为每个股民发送分红
    function distributeDividends() onlyOwner public noEth(){
        for (var i = IterableMapping.iterate_start(data); IterableMapping.iterate_valid(data, i); i = IterableMapping.iterate_next(data, i))
        {
            var (key, value) = IterableMapping.iterate_get(data, i);
            uint tmp = balances[dividendAddress] / globalShares * value;
            balances[key] = balances[key].add(tmp);
            Dividends(dividendAddress, key, tmp);
        }
        balances[dividendAddress] = balances[dividendAddress].sub(balances[dividendAddress] / globalShares * globalShares);
    }

    function GlobalCoin() onlyOwner {
        balances[owner] = totalSupply;
    }

}