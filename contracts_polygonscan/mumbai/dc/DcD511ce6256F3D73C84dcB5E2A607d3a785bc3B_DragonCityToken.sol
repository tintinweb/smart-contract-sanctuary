/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

/**
 *Submitted for verification at Etherscan.io on 2018-11-02
*/

pragma solidity ^0.4.21;

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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
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

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

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

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract DragonCityToken is PausableToken {
    using SafeMath for uint256;
    struct VaultInfo {
        uint256 amount;
        uint256 acquiredTime;
    }
    string public name = "Dragon City Token";
    string public symbol = "DCT";
    uint256 public decimals = 0;
    uint256 public constant Factor = 1000;
    uint256 public constant INITIAL_SUPPLY = 6485 * Factor;//
    mapping(address => VaultInfo) public vaults;
    uint256 public circulatingSupply = 0;
    uint256 public tokensInVaults;
    bool public activated_;

    event Acquired(address indexed to, uint256 amount);
    event Activated(address indexed who);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
    }

    modifier isActivated() {
        require(activated_ == true, "its not ready yet.");
        _;
    }

    modifier lessThanTotalSupply(uint256[] _amountOfLands) {
        uint256 totalAmount = 0;
        for (uint256 i; i < _amountOfLands.length; i++) {
            uint256 amount = _amountOfLands[i].mul(Factor);
            totalAmount = totalAmount.add(amount);
        }
        require(totalAmount.add(tokensInVaults) <= totalSupply_, 'can not exceed total supply.');
        _;
    }

    function setVault(address[] holders, uint256[] amountOfLands) public onlyOwner lessThanTotalSupply(amountOfLands) {
        uint256 len = holders.length;
        require(len == amountOfLands.length);
        for(uint256 i=0; i<len; i++){
            uint256 _amount = amountOfLands[i].mul(Factor);
            tokensInVaults = tokensInVaults.sub(vaults[holders[i]].amount);
            vaults[holders[i]].amount = _amount;
            tokensInVaults = tokensInVaults.add(_amount);
        }
    }

    function claimToken() public isActivated(){
        uint256 tokenAmount = vaults[msg.sender].amount;
        require(tokenAmount > 0);

        vaults[msg.sender].amount = 0;
        vaults[msg.sender].acquiredTime = block.timestamp;

        balances[msg.sender] = tokenAmount;
        circulatingSupply = circulatingSupply.add(tokenAmount);

        emit Transfer(address(0), msg.sender, tokenAmount);
        emit Acquired(msg.sender, tokenAmount);
    }

    function activate() public onlyOwner(){
        require(activated_ == false, "Already activated");
        activated_ = true;
        emit Activated(msg.sender);
    }

}