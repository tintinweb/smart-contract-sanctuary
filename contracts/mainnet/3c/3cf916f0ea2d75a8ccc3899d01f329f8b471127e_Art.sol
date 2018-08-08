pragma solidity >0.4.23 <0.5.0;
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
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

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    // delete extra methods
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


contract Art is StandardToken {
    string public name = "Northern Turquoise";
    string public symbol = "NT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1 ether;

    // Struct
    address public artist = msg.sender;
    string public artistName = "Zhang Ji";
    string public artistEmail= "six@beslab.xyz";
    string public Explain= "A liquid information poetry.";
    string public Hash= "39a6e92df56f29f0c9c961d2483df06b"; //Art Hash
    string public Description = "A romanticized documentary for the true experience of different understandings of value that carried by objects through different ages, background and crew, etc.";
    string public Copyright = "Token holder has full copyright of this art piece including its interpretation, commercial use, ownership transfer, derivatives production, etc. ";
    uint256 public transferLimit = 1 ether;
    string public artUrlList = "https://www.dropbox.com/s/0v99yw0i7w8qwz6/northern%20turquoise.cryptoart?dl=0,https://drive.google.com/file/d/1CzezHZfrKDKvQkWdd_b5He5dQQD68EX8/view?usp=sharing";

    constructor() public {
        totalSupply_ = totalSupply;
        balances[artist] = totalSupply;
        emit Transfer(0x0, artist, totalSupply);
    }

    event TransferOwner(address newOwner, address lastOwner);
    modifier onlyArtist() {
        require(msg.sender == artist, "Only artist can do this.");
        _;
    }

    function changeOwner(address newOwner) internal onlyArtist returns (bool) {
        artist = newOwner;
    }

    function changeExplain(string newExplain) public onlyArtist returns (bool) {
        Explain = newExplain;
    }

    function changeArtName(string newName, string newSymbol) public onlyArtist returns (bool) {
        name = newName;
        symbol = newSymbol;
    }

    function changeArtUrl(string newUrl) public onlyArtist returns (bool) {
        artUrlList = newUrl;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value == transferLimit, "Art only one.");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        changeOwner(_to);
        emit TransferOwner(_to,msg.sender);
        return true;
    }
}