pragma solidity ^0.4.18;


/**
 * @title ERC20 Token Interface
 */
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title ERC677 transferAndCall token interface
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and
 *      discussion.
 */
contract ERC677 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);

    function transferAndCall(address _to, uint _value, bytes _data) public returns (bool success);
}

/**
 * @title Receiver interface for ERC677 transferAndCall
 * @dev See https://github.com/ethereum/EIPs/issues/677 for specification and
 *      discussion.
 */
contract ERC677Receiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}


/**
 * @title VALID Token
 * @dev ERC20 compatible smart contract for the VALID token. Closely follows
 *      ConsenSys StandardToken.
 */
contract ValidToken is ERC677, ERC20 {
    // token metadata
    string public constant name = "VALID";
    string public constant symbol = "VLD";
    uint8 public constant decimals = 18;

    // total supply and maximum amount of tokens
    uint256 public constant maxSupply = 10**9 * 10**uint256(decimals);
    // note: this equals 10**27, which is smaller than uint256 max value (~10**77)

    // token accounting
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // token lockups
    mapping(address => uint256) lockups;
    event TokensLocked(address indexed _holder, uint256 _timeout);

    // ownership
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // minting
    bool public mintingDone = false;
    modifier mintingFinished() {
        require(mintingDone == true);
        _;
    }
    modifier mintingInProgress() {
        require(mintingDone == false);
        _;
    }

    // constructor
    function ValidToken() public {
        owner = msg.sender;
    }

    /**
     * @dev Allows the current owner to transfer the ownership.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // minting functionality

    function mint(address[] _recipients, uint256[] _amounts) public mintingInProgress onlyOwner {
        require(_recipients.length == _amounts.length);
        require(_recipients.length < 255);

        for (uint8 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];

            // enforce maximum token supply
            require(totalSupply + amount >= totalSupply);
            require(totalSupply + amount <= maxSupply);

            balances[recipient] += amount;
            totalSupply += amount;

            Transfer(0, recipient, amount);
        }
    }

    function lockTokens(address[] _holders, uint256[] _timeouts) public mintingInProgress onlyOwner {
        require(_holders.length == _timeouts.length);
        require(_holders.length < 255);

        for (uint8 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
            uint256 timeout = _timeouts[i];

            // make sure lockup period can not be overwritten
            require(lockups[holder] == 0);

            lockups[holder] = timeout;
            TokensLocked(holder, timeout);
        }
    }

    function finishMinting() public mintingInProgress onlyOwner {
        // check hard cap again
        assert(totalSupply <= maxSupply);

        mintingDone = true;
    }

    // ERC20 functionality

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public mintingFinished returns (bool) {
        // prevent some common errors
        require(_to != address(0x0));
        require(_to != address(this));

        // check lockups
        if (lockups[msg.sender] != 0) {
            require(now >= lockups[msg.sender]);
        }

        // check balance
        require(balances[msg.sender] >= _value);
        assert(balances[_to] + _value >= balances[_to]); // receiver balance overflow check

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public mintingFinished returns (bool) {
        // prevent some common errors
        require(_to != address(0x0));
        require(_to != address(this));

        // check lockups
        if (lockups[_from] != 0) {
            require(now >= lockups[_from]);
        }

        // check balance and allowance
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value);
        require(allowance >= _value);
        assert(balances[_to] + _value >= balances[_to]); // receiver balance overflow check

        allowed[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;

        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // no check for zero allowance, see NOTES.md

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // ERC677 functionality

    function transferAndCall(address _to, uint _value, bytes _data) public mintingFinished returns (bool) {
        require(transfer(_to, _value));

        Transfer(msg.sender, _to, _value, _data);

        // call receiver
        if (isContract(_to)) {
            ERC677Receiver receiver = ERC677Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        return true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint len;
        assembly {
            len := extcodesize(_addr)
        }
        return len > 0;
    }
}