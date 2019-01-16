pragma solidity ^0.4.25;

 /*dev ImanuelKevin
 *dev 
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);


    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
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
        Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract KEVINTOKEN is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint;

    string constant public symbol = "KEVIN4";
    string constant public name = "KEVINTOKEN1";

    uint8 constant public decimals = 18;
    uint256 INITIAL_SUPPLY = 3000000000e18;

    uint constant STARTICO = 1542859200;  // 4:00
    uint constant ENDICO = 1542860100;    // 4:20
    uint constant UNLOCKDEV = 1542861300;  // 4:35

    address company = 0x188CA2f0E0f299b803872Ade16483d1e8a6d03ce;
    address team = 0x561Ba772b6EFafF7990e948724857e777762958c;

    address crowdsale = 0x75462d880B050a9d9D247a34B0A248d893E23CE9;
    address bounty = 0xab31b6cafc0a780bb46a0523F1108e7E5a9e8Be0;

    address beneficiary = 0x61477c6eA6521076e4208eAFdBE380b241E3c75D;

    uint constant companyTokens = 400000000e18;
    uint constant teamTokens = 500000000e18;
    uint constant crowdsaleTokens = 2000000000e18;
    uint constant bountyTokens = 50000000e18;


    function KEVINTOKEN() public {

        totalSupply_ = INITIAL_SUPPLY;

        preSale(company, companyTokens);
        preSale(team, teamTokens);
        preSale(crowdsale, crowdsaleTokens);
        preSale(bounty, bountyTokens);


        preSale(0xcA4B4E62E1b1eAa9b8C75Bce29fc896f2890E5E9, 50000000e18);


    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        Transfer(address(0x0), _address, _amount);
    }

    function checkPermissions(address _from) internal constant returns (bool) {

        if (_from == team  && now < UNLOCKDEV) {
            return false;
        }

        if (_from == bounty || _from == company) {
            return true;
        }

        if (now < ENDICO) {
            return false;
        } else {
            return true;
        }
        
        if (_from == crowdsale && now < STARTICO) {
            return false;
        }
        
        if (_from == crowdsale && now > ENDICO) {
            return true;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
    }

    function () public payable {
        require(msg.value >= 1e16);
        beneficiary.transfer(msg.value);
    }
}