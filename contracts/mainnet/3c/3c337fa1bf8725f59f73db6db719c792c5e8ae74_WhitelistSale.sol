pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract ERC20Constant {
    function balanceOf( address who ) constant returns (uint value);
}
contract ERC20Stateful {
    function transfer( address to, uint value) returns (bool ok);
}
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract WhitelistSale is Owned {

    ERC20 public manaToken;

    // Amount of MANA received per ETH
    uint256 public manaPerEth;

    // Sales start at this timestamp
    uint256 public initialTimestamp;

    // The sale goes on through 6 days.
    // Each day, users are allowed to buy up to a certain (cummulative) limit of MANA.

    // This mapping stores the addresses for whitelisted users
    mapping(address => bool) public whitelisted;

    // Used to calculate the current limit
    mapping(address => uint256) public bought;

    // The initial values allowed per day are copied from this array
    uint256[6] public limitPerDay;

    // Forwarding address
    address public receiver;

    event LogWithdrawal(uint256 _value);
    event LogBought(uint orderInMana);
    event LogUserAdded(address user);
    event LogUserRemoved(address user);

    function WhitelistSale (
        ERC20 _manaToken,
        uint256 _initialTimestamp,
        address _receiver
    )
        Owned()
    {
        manaToken        = _manaToken;
        initialTimestamp = _initialTimestamp;
        receiver         = _receiver;

        manaPerEth       = 11954;
        limitPerDay[0]   = 3.3 ether;
        limitPerDay[1]   = 10 ether   + limitPerDay[0];
        limitPerDay[2]   = 30 ether   + limitPerDay[1];
        limitPerDay[3]   = 90 ether   + limitPerDay[2];
        limitPerDay[4]   = 450 ether  + limitPerDay[3];
        limitPerDay[5]   = 1500 ether + limitPerDay[4];
    }

    // Withdraw Mana (only owner)
    function withdrawMana(uint256 _value) onlyOwner returns (bool ok) {
        return withdrawToken(manaToken, _value);
    }

    // Withdraw any ERC20 token (just in case)
    function withdrawToken(address _token, uint256 _value) onlyOwner returns (bool ok) {
        return ERC20(_token).transfer(owner,_value);
        LogWithdrawal(_value);
    }

    // Change address where funds are received
    function changeReceiver(address _receiver) onlyOwner {
        require(_receiver != 0);
        receiver = _receiver;
    }

    // Calculate which day into the sale are we.
    function getDay() constant returns (uint256) {
        return SafeMath.sub(block.timestamp, initialTimestamp) / 1 days;
    }

    modifier onlyIfActive {
        require(getDay() >= 0);
        require(getDay() < 6);
        _;
    }

    function buy(address beneficiary) payable onlyIfActive {
        require(beneficiary != 0);
        require(whitelisted[msg.sender]);

        uint day = getDay();
        uint256 allowedForSender = limitPerDay[day] - bought[msg.sender];

        if (msg.value > allowedForSender) revert();

        uint256 balanceInMana = manaToken.balanceOf(address(this));

        uint orderInMana = msg.value * manaPerEth;
        if (orderInMana > balanceInMana) revert();

        bought[msg.sender] = SafeMath.add(bought[msg.sender], msg.value);
        manaToken.transfer(beneficiary, orderInMana);
        receiver.transfer(msg.value);

        LogBought(orderInMana);
    }

    // Add a user to the whitelist
    function addUser(address user) onlyOwner {
        whitelisted[user] = true;
        LogUserAdded(user);
    }

    // Remove an user from the whitelist
    function removeUser(address user) onlyOwner {
        whitelisted[user] = false;
        LogUserRemoved(user);
    }

    // Batch add users
    function addManyUsers(address[] users) onlyOwner {
        require(users.length < 10000);
        for (uint index = 0; index < users.length; index++) {
             whitelisted[users[index]] = true;
             LogUserAdded(users[index]);
        }
    }

    function() payable {
        buy(msg.sender);
    }
}