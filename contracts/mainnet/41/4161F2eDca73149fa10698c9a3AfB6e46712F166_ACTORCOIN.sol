pragma solidity ^0.4.23;

// SafeMath
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


// Ownable
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

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// ERC223
contract ERC223 {
    uint public totalSupply;

    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 // ContractReceiver
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

        /*
         * tkn variable is analogue of msg variable of Ether transaction
         * tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
         * tkn.value the number of tokens that were sent   (analogue of msg.value)
         * tkn.data is data of token transaction   (analogue of msg.data)
         * tkn.sig is 4 bytes signature of function if data of token transaction is a function execution
         */
    }
}


// ACTOR COIN
contract ACTORCOIN is ERC223, Ownable {
    using SafeMath for uint256;

    string public name = "actor coin";
    string public symbol = "ACT";
    uint8 public decimals = 16;
    uint256 public totalSupply;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 7 days; // minimum age for coin age: 7D
    uint public stakeMaxAge = 120 days; // stake age of full weight: 120D

    uint256 public maxTotalSupply = 50e9 * 1e16;
    uint256 public initialTotalSupply = 20e9 * 1e16;

    struct transferInStruct{
      uint256 amount;
      uint64 time;
    }

    address public admin = 0x96e80228c243dbCB7Af0f9af3eAA3FC01E1CfE8f;
    address public presale = 0xA1C9457Eb8C11c053Ef317680f3dE734Bf7604Bc;
    address public develop = 0x7279E1294a037a6dFFa0E01BA524181652F66DfE;
    address public pr = 0xd710eB2Fc91b90dB33006BD777d35C7381030a1E;
    address public manage = 0xb89cb493b9399aD693A797f969FE27F41799D02a;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping(address => transferInStruct[]) public transferIns;

    event Burn(address indexed burner, uint256 value);
    event PosMint(address indexed _address, uint _reward);

    constructor () public {
        owner = admin;
        totalSupply = initialTotalSupply;
        balanceOf[owner] = totalSupply;

        chainStartTime = now;
        chainStartBlockNumber = block.number;
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    // transfer
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transfer(address _to, uint _value, bytes _data) public  returns (bool success) {
        require(_value > 0);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        require(_value > 0);

        if (isContract(_to)) {
            require(balanceOf[msg.sender] >= _value);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            emit Transfer(msg.sender, _to, _value);

            if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
            uint64 _now = uint64(now);
            transferIns[msg.sender].push(transferInStruct(uint256(balanceOf[msg.sender]),_now));
            transferIns[_to].push(transferInStruct(uint256(_value),_now));

            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint256(balanceOf[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint256(_value),_now));

        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint256(balanceOf[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint256(_value),_now));

        return true;
    }

    // transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        if(transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint256(balanceOf[_from]),_now));
        transferIns[_to].push(transferInStruct(uint256(_value),_now));

        return true;
    }

    // approve
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // allowance
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    // airdrop
    function airdrop(address[] addresses, uint[] amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length);

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && addresses[j] != 0x0);

            amounts[j] = amounts[j].mul(1e16);
            totalAmount = totalAmount.add(amounts[j]);
        }
        require(balanceOf[msg.sender] >= totalAmount);

        uint64 _now = uint64(now);
        for (j = 0; j < addresses.length; j++) {
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]);
            emit Transfer(msg.sender, addresses[j], amounts[j]);

            transferIns[addresses[j]].push(transferInStruct(uint256(amounts[j]),_now));
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balanceOf[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint256(balanceOf[msg.sender]),_now));

        return true;
    }

    function setStakeStartTime(uint timestamp) onlyOwner public {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) onlyOwner public {
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balanceOf[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        initialTotalSupply = initialTotalSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        emit Burn(msg.sender, _value);
    }

    function getBlockNumber() constant public returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function posMint() canPoSMint public returns (bool) {
        if(balanceOf[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint256(balanceOf[msg.sender]),uint64(now)));

        emit PosMint(msg.sender, reward);
        return true;
    }

    function coinAge() constant public returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount).mul(nCoinSeconds).div(1 days));
        }
    }

    function getReward(address _address) internal view returns (uint reward) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint64 _now = uint64(now);
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        reward = _coinAge.mul(50).div(1000).div(365);
        return reward;
    }

}