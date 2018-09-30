pragma solidity ^0.4.18;

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

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BJCToken is ERC20, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public exchangeRate;
    uint256 initialSupply;
    uint256 totalSupply_;

    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    function BJCToken() public {
        name = "BJCToken";
        symbol = "BJC";
        decimals = 18;
        initialSupply = 10000000000;
        exchangeRate = 1000;
        totalSupply_ = initialSupply * 10 ** uint(18);
        balances[owner] = totalSupply_;
        Transfer(address(0), owner, totalSupply_);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    function getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
        return _weiAmount.mul(exchangeRate);
    }
    function random() public view returns (uint8) 
    {
        return uint8(uint256(keccak256(uint256(keccak256(block.timestamp, block.difficulty))%251,now)) % 10);
    }
    function () payable public {
        require(msg.value >= 0.0001 ether);
        uint256 tokens = getTokenAmount(msg.value);
        require(tokens <= balances[owner]);
        
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
       
        Transfer(owner, msg.sender, tokens);
    }
    
    function game(uint256 _value) public {
        require(msg.sender != address(0));
        require(_value <= balances[msg.sender]);
        require(_value.mul(2) <= balances[owner]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[owner] = balances[owner].add(_value);
        uint8 randomValue = random();
        //uint8 256
        //0123456789
        if(randomValue >= 5) {
            //x 3
            balances[owner] = balances[owner].sub(_value.mul(2));
            balances[msg.sender] = balances[msg.sender].add(_value.mul(2));
            Transfer(owner, msg.sender, _value);
        } else {
            //bye
            Transfer(msg.sender, owner, _value);
        }
        
    }


}