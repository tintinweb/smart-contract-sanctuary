/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// &#39;Chatl&#39; &#39;CHAL&#39; token contract
// ----------------------------------------------------------------------------

// implement safemath as a library
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  
}

contract ChatlToken {

    using SafeMath for uint256;

    address     public      owner;
    string      public      name;
    string      public      symbol;
    uint256     public      totalSupply;
    uint8       public      decimals;
    bool        public      globalTransferLock;

    mapping (address => bool)                           public      accountLock;
    mapping (address => uint256)                        public      balances;
    mapping (address => mapping(address => uint256))    public      allowed;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event GlobalTransfersLocked(bool indexed _transfersFrozenGlobally);
    event GlobalTransfersUnlocked(bool indexed _transfersThawedGlobally);
    event AccountTransfersFrozen(address indexed _eszHolder, bool indexed _accountTransfersFrozen);
    event AccountTransfersThawed(address indexed _eszHolder, bool indexed _accountTransfersThawed);

    /**
        @dev Checks to ensure that msg.sender is the owner
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
        @dev Checks to ensure that global transfers are not locked
    */
    modifier transfersUnlocked() {
        require(!globalTransferLock);
        _;
    }

    /**CONSTRUCTOR*/
    function ChatlToken() public{
        owner = msg.sender;
        totalSupply = 100000000000000000000000000;
        balances[msg.sender] = totalSupply;
        name = "Chatl";
        symbol = "CHAL";
        decimals = 18;
        globalTransferLock = false;
    } 

    /**
        @dev Freezes transfers globally
    */
    function freezeGlobalTansfers()
        public
        onlyOwner
        returns (bool)
    {
        globalTransferLock = true;
        emit GlobalTransfersLocked(true);
        return true;
    }

    /**
        @dev Thaws transfers globally
    */
    function thawGlobalTransfers()
        public
        onlyOwner
        returns (bool)
    {
        globalTransferLock = false;
        emit GlobalTransfersUnlocked(true);
    }

    /**
        @dev Freezes a particular account, preventing them from making transfers
    */
    function freezeAccountTransfers(
        address _eszHolder
    )
        public
        onlyOwner
        returns (bool)
    {
        accountLock[_eszHolder] = true;
        emit AccountTransfersFrozen(_eszHolder, true);
        return true;
    }

    /**
        @dev Thaws a particular account, allowing them to make transfers again
    */
    function thawAccountTransfers(
        address _eszHolder
    )
        public
        onlyOwner
        returns (bool)
    {
        accountLock[_eszHolder] = false;
        emit AccountTransfersThawed(_eszHolder, true);
        return true;
    }

    /**
        @dev Used to transfers tokens
    */
    function transfer(
        address _recipient,
        uint256 _amount
    )
        public
        returns (bool)
    {
        require(accountLock[msg.sender] == false);
        require(transferCheck(msg.sender, _recipient, _amount));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
        @dev Used to transfers tokens to someone on behalf of the owner account. Must be approved
    */
    function transferFrom(
        address _owner,
        address _recipient,
        uint256 _amount
    )
        public
        returns (bool)
    {
        require(accountLock[_owner] == false);
        require(allowed[_owner][msg.sender] >= _amount);
        require(transferCheck(_owner, _recipient, _amount));
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_owner, _recipient, _amount);
        return true;
    }

    /**
        @dev Used to approve another account to spend on your behalf
    */
    function approve(
        address _spender,
        uint256 _amount
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /** INTERNALS */

    /**
        @dev Does a sanity check of the parameters in a transfer, makes sure transfers are allowed
    */
    function transferCheck(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
        view
        transfersUnlocked
        returns (bool)
    {
        require(_amount > 0);
        require(balances[_sender] >= _amount);
        require(balances[_sender].sub(_amount) >= 0);
        require(balances[_recipient].add(_amount) > balances[_recipient]);
        return true;
    }

    /** GETTERS */
    
    /**
        @dev Retrieves total supply
    */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply;
    }

    /**
        @dev Retrieves the balance of an ESZ holder
    */
    function balanceOf(
        address _eszHolder
    )
        public
        view
        returns (uint256)
    {
        return balances[_eszHolder];
    }

    /**
        @dev Retrieves the balance of spender for owner
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    
}