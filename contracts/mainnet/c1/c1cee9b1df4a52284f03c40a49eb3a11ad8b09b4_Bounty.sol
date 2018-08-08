pragma solidity 0.4.21;

contract ERC20Basic {

    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
	
}

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

contract BasicToken is ERC20Basic {
	
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract CerttifyToken is StandardToken {

    event Burn(address indexed burner, uint256 value, string message);
    event IssueCert(bytes32 indexed id, address certIssuer, uint256 value, bytes cert);

    string public name = "Certtify Token";
    string public symbol = "CTF";
    uint8 public decimals = 18;

    address public deployer;
    bool public lockup = true;

    function CerttifyToken(uint256 maxSupply) public {
        totalSupply = maxSupply.mul(10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
    }

    modifier afterLockup() {
        require(!lockup || msg.sender == deployer);
        _;
    }

    function unlock() public {
        require(msg.sender == deployer);
        lockup = false;
    }

    function transfer(address _to, uint256 _value) public afterLockup() returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public afterLockup() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value, string _message) public afterLockup() {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        totalSupply = totalSupply.sub(_value);
        balances[burner] = balances[burner].sub(_value);
        emit Burn(burner, _value, _message);
    }

    function issueCert(uint256 _value, bytes _cert) external afterLockup() {
        if (_value > 0) { 
            burn(_value, "");
        }
        emit IssueCert(keccak256(block.number, msg.sender, _value, _cert), msg.sender, _value, _cert);
    }

}

contract Ownable {
  
    address public owner;

    function Ownable(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

contract Bounty is Ownable {

    CerttifyToken public token;
    mapping(address => uint256) public bounties;
    bool public withdrawlEnabled = false;

    event BountySet(address indexed beneficiary, uint256 amount);
    event BountyWithdraw(address indexed beneficiary, uint256 amount);

    function Bounty(CerttifyToken _token, address _admin) Ownable(_admin) public {
        token = _token;
    }

    function setBounties(address[] beneficiaries, uint256[] amounts) external onlyOwner {
        require(beneficiaries.length == amounts.length);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            bounties[beneficiaries[i]] = amounts[i];
            emit BountySet(beneficiaries[i], amounts[i]);
        }
    }

    function enableWithdrawl() external onlyOwner {
        withdrawlEnabled = true;
    }

    function withdrawBounty() public {
        require(withdrawlEnabled);
        require(bounties[msg.sender] > 0);
        uint256 bountyWithdrawn = bounties[msg.sender];
        bounties[msg.sender] = 0;
        emit BountyWithdraw(msg.sender, bountyWithdrawn);
        token.transfer(msg.sender, bountyWithdrawn);
    }

    function () external {
        withdrawBounty();
    }

}