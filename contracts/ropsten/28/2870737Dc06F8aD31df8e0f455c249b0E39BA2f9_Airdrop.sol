pragma solidity ^0.4.24;

//import &quot;./AbstractESS.sol&quot;;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

    constructor() internal {
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


contract AbstractESS {
    
    function transfer(address _to, uint256 _value) public returns (bool);
    
}


contract AirESS is AbstractESS {
    
    
    using SafeMath for uint256;


    mapping (address => uint256) public balances;


    mapping (address => mapping (address => uint256)) internal allowed;



    // Public variables for the ESSENTIA ERC20 ESS token contract
    string public constant standard = &quot;ESSENTIA erc20 and Genesis&quot;;
    uint256 public constant decimals = 18;   // hardcoded to be a constant
    string public name = &quot;ESSENTIA&quot;;
    string public symbol = &quot;ESS&quot;;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);



    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
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
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);


        balances[_to] = balances[_to].add(_value);


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


contract Airdrop is Ownable{
    
    //send token for airdrop addresses
    function airdrop(address[] _address) external onlyOwner {
        
        AbstractESS my_ess = AbstractESS(0xfc05987bd2be489ACCF0f509E44B0145d68240f7);
        
        for (uint i = 0; i < _address.length; i++) {
            //_address[i] = true;
            //token.mint(_address[i], 25);
            
            
            my_ess.transfer(_address[i], 25);
        }
    }
    
}