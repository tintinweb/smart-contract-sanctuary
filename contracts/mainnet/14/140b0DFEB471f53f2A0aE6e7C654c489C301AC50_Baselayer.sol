/**
 *Submitted for verification at Etherscan.io on 2020-09-24
*/

pragma solidity ^0.5.1;


/*
    * Baselayer is an interoperability experiment.  ERC20 with PolkaDot swap compatibility.
*/

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    * SafeMath
    
*/

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

/*
    * Swap logic to Baselayer PolkaDot 1:1 swap
    
        Create ERC20 Contract in code below with PolkaDot contract compatibility.
        Baselayer testnet live Q4. 
*/
contract Baselayer is ERC20 {
    using SafeMath for uint256;
    address private deployer;
    string public name = "Baselayer";
    string public symbol = "BASS";
    uint8 public constant decimals = 18;
    uint256 private constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant startingSupply = 1000 * decimalFactor;
    uint256 public burntTokens = 0;
    bool public minted = false;
    bool public unlocked = false;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyOwner() {
        require(deployer == msg.sender, "Caller is not the owner");
        _;
    }

    constructor() public {
        deployer = msg.sender;
    }

    function owner() public view returns (address) {
        return deployer;
    }

    function totalSupply() public view returns (uint256) {
        uint256 currentTokens = startingSupply.sub(burntTokens);
        return currentTokens;
    }
    
    function mint(address _owner) public onlyOwner returns (bool) {
        require(minted != true, "Tokens already minted");
        balances[_owner] = startingSupply;
        emit Transfer(address(0), _owner, startingSupply);
        minted = true;
        return true;
    }
    
    function unlockTokens() public onlyOwner returns (bool) {
        require(unlocked != true, "Tokens already unlocked");
        unlocked = true;
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        balances[account] = balances[account].sub(amount);
        burntTokens = burntTokens.add(amount);
        emit Transfer(account, address(0), amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(unlocked == true, "Tokens not unlocked yet");
        uint256 tokensToBurn = _value.div(100);
        uint256 tokensToSend = _value.sub(tokensToBurn);
        balances[msg.sender] = balances[msg.sender].sub(tokensToSend);
        _burn(msg.sender, tokensToBurn);
        balances[_to] = balances[_to].add(tokensToSend);
        
        emit Transfer(msg.sender, _to, tokensToSend);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(unlocked == true, "Tokens not unlocked yet");
        uint256 tokensToBurn = _value.div(100);
        uint256 tokensToSend = _value.sub(tokensToBurn);
        balances[_from] = balances[_from].sub(tokensToSend);
        balances[_to] = balances[_to].add(tokensToSend);
        _burn(_from, tokensToBurn);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, tokensToSend);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
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