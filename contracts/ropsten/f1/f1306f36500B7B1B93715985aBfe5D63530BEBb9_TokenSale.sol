pragma solidity ^0.4.21;
pragma solidity ^0.4.21;

// TODO DOC SafeMath


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


// TODO DOC main token
// mintable and burnable (to account for gold reserve fluctuation)
// ERC20 token

contract GoldBackedToken {
    // TODO DOC avoid under and overflows
    using SafeMath for uint256;

    // TODO DOC ERC20 vars
    address public owner;

    string public name = &quot;GoldBackedToken&quot;;
    string public symbol = &quot;GBT&quot;;
    uint8 public decimals = 0;

    uint256 totalSupply_ = 0;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    // TODO DOC ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    
    // TODO DOC ERC20 modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // TODO DOC constructor

    constructor() public {
        owner = msg.sender;
    }

    // TODO DOC ERC20 methods

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // TODO DOC Non-ERC but minting/burning related methods

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function burn_lost() public onlyOwner{
        _burn(address(0), balances[address(0)]);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    // TODO DOC ownership utility
    function changeOwner(address _new_owner) public onlyOwner {
        require(_new_owner != address(0));
        owner = _new_owner;
    }

}

contract TokenSale {
    using SafeMath for uint256;

    uint256 public price = 1000 wei;

    address public token;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        // Token should be provided as a constructor argument, not hardcoded
        token = 0x7989EC4402d1CD2EfC4AE8527988C9D001998502;
    }

    function changePrice(uint256 _new_price) public onlyOwner {
        require(_new_price > 0);
        price = _new_price;
    }
    
    function changeOwner(address _new_owner) public onlyOwner {
        require(_new_owner != address(0));
        owner = _new_owner;
    }

    function () public payable {
        require(msg.value > 0);
        require(price > 0);
        uint256 num_tokens = msg.value.div(price);
        require(GoldBackedToken(token).balanceOf(this) > num_tokens);
        GoldBackedToken(token).transfer(msg.sender, num_tokens);
    }

}