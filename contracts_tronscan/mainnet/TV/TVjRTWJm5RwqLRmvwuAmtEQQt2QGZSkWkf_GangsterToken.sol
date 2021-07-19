//SourceUnit: token.sol

pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {return 0;}
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}

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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract TRC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StandardToken is TRC20Basic, Ownable {
    using SafeMath for uint256;
    
    uint256 totalSupply_;
    
    bool public mintingFinished = false;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

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
    
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_to != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract GangsterToken is StandardToken {

    struct Stats {
        uint256 txs;
        uint256 minted;
    }

    string public constant name = "Gangster Finance: OGT";
    string public constant symbol = "OGT";
    uint8 public constant decimals = 6;
    uint256 public constant MAX_INT = 2**256 - 1;
    uint256  public constant targetSupply = MAX_INT;
    uint256 public totalTxs;
    uint256 public players;
    uint256  private mintedSupply_;

    mapping(address => Stats) private stats;

    constructor() Ownable() public {
        mint(owner,1e11); // 100k pre-mine
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        if (_amount == 0 || mintedSupply_.add(_amount) > targetSupply) {return false;}

        super.mint(_to, _amount);
        mintedSupply_ = mintedSupply_.add(_amount);

        if (mintedSupply_ == targetSupply) {
            mintingFinished = true;
            emit MintFinished();
        }

        if (stats[_to].txs == 0) {players += 1;}

        stats[_to].txs += 1;
        stats[_to].minted += _amount;
        totalTxs += 1;

        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {return false;}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        super.transferFrom(_from, _to, _value);

        if (stats[_to].txs == 0) {players += 1;}

        stats[_to].txs += 1;
        stats[_from].txs += 1;
        totalTxs += 1;

        return true;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {

        super.transfer(_to, _value);

        if (stats[_to].txs == 0) {players += 1;}

        stats[_to].txs += 1;
        stats[msg.sender].txs += 1;
        totalTxs += 1;

        return true;
    }

    function remainingMintableSupply() public view returns (uint256) {
        return targetSupply.sub(mintedSupply_);
    }
    
    function mintedSupply() public view returns (uint256) {
        return mintedSupply_;
    }

    function statsOf(address player) public view returns (uint256, uint256, uint256){
        return (balanceOf(player), stats[player].txs, stats[player].minted);
    }
    
    function mintedBy(address player) public view returns (uint256){
        return stats[player].minted;
    }
}