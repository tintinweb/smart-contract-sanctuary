/**
This is the source of a special time-locked token for the FTV Coin Deluxe.
If you hold a balance of the token and you wan to convert it to the FTV token, wait until the lockup period is over
 and then transfer any amount to yourself.
 it will convert the token to the real FTV Token at 0xf91254fe7e6e9f5986a0b41da45a8a2549f1871b
**/
pragma solidity ^0.4.11;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FtvTimelockFactory is BasicToken {

    ERC20 public token;
    address public tokenAssignmentControl;

    constructor (ERC20 _token, address _tokenAssignmentControl) {
        token = _token;
        tokenAssignmentControl = _tokenAssignmentControl;
    }
    string public constant name = "Your Timelocked FTV Deluxe Tokens";

    string public constant symbol = "TLFTV";

    uint8 public constant decimals = 18;

    mapping(address => uint256) public releaseTimes;


    function assignBalance(address _holder, uint256 _releaseTime, uint256 _amount) public {
        require(_amount > 0);
        require(msg.sender == tokenAssignmentControl);
        //only allowed if not already assigned
        require(releaseTimes[_holder] == 0);
        totalSupply += _amount;
        require(totalSupply <= token.balanceOf(this));
        releaseTimes[_holder] = _releaseTime;
        balances[_holder] = balances[_holder].add(_amount);
        emit Transfer(0x0, _holder, _amount);
    }

    function transfer(address _holder, uint256) public returns (bool) {
        //this transfer function ignores value, it will just trigger release
        require(_holder == msg.sender, "you can only send to self to unlock the tokens to the real FTV coin");
        release(msg.sender);
        return true;
    }

    /**
        * @notice Transfers tokens held by timelock to beneficiary. can be called any time after releaseTime
        */
    function release(address _holder) public {
        require(releaseTimes[_holder] < now, "release time is not met yet");
        uint256 amount = balanceOf(_holder);
        totalSupply -= amount;
        token.transfer(_holder, amount);
        emit Transfer(_holder, 0x0, amount);
    }

}