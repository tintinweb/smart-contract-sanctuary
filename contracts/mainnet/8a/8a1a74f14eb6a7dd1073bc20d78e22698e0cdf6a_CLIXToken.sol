pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) { return 0; }
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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    
    function transfer(
        address to, 
        uint256 value
    ) 
        public 
        returns (bool);
    
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) 
        public view returns (uint256);
        
    function transferFrom(address from, address to, uint256 value) 
        public returns (bool);
        
    function approve(address spender, uint256 value) 
        public returns (bool);
        
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value
    );
}


contract TokenRecipient {
    function receiveApproval(
        address from, 
        uint256 tokens, 
        address token, 
        bytes data
    )
        public;
}


contract CLIXToken is ERC20, Ownable, Pausable {
    
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public blacklisted;
    mapping (address => bool) public hasReceived;

    string public name = "CLIXToken";
    string public symbol = "CLIX";
    
    uint public decimals = 18;
    uint256 private totalSupply_ = 200000000e18;
    uint256 private totalReserved = (totalSupply_.div(100)).mul(10);
    uint256 private totalBounties = (totalSupply_.div(100)).mul(5);
    uint256 public totalDistributed = totalReserved.add(totalBounties);
    uint256 public totalRemaining = totalSupply_.sub(totalDistributed);
    uint256 public tokenRate;
    
    bool public distributionFinished;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
    
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
    
    event Distribution(
        address indexed to, 
        uint256 amount
    );
    
    modifier distributionAllowed() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyWhitelist() {
        require(whitelist[msg.sender]);
        _;
    }
    
    modifier notBlacklisted() {
        require(!blacklisted[msg.sender]);
        _;
    }
    
    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    constructor(uint256 _tokenRate) public {
        tokenRate = _tokenRate;
        balances[msg.sender] = totalDistributed;
    }
    
    function() external payable { getClixToken(); }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
	    return balances[_owner];
    }
    
    function setTokenRate(uint256 _tokenRate) public onlyOwner {
        tokenRate = _tokenRate;
    }
    
    function enableWhitelist(address[] addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function disableWhitelist(address[] addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }
    
    function enableBlacklist(address[] addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            blacklisted[addresses[i]] = true;
        }
    }
    
    function disableBlacklist(address[] addresses) public onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            blacklisted[addresses[i]] = false;
        }
    }
    
    function distributeToken(
        address _to, 
        uint256 _amount
    ) 
        private 
        distributionAllowed 
        whenNotPaused 
        returns (bool)
    {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Distribution(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
        
        if (totalDistributed >= totalSupply_) {
            distributionFinished = true;
        }
    }
    
    function getClixToken() 
        public 
        payable 
        distributionAllowed 
        onlyWhitelist 
        whenNotPaused 
    {
        require(tokenRate <= totalRemaining);
        
        /* Buyer has previously received their free tokens so this time we 
        calculate how many tokens to send based on the amount of eth sent to the 
        contract */
        if (hasReceived[msg.sender]) {
            uint256 ethInWei = msg.value;
            uint256 weiNumber = 1000000000000000000;
            uint256 divider = weiNumber.div(tokenRate.div(weiNumber));
            uint256 tokenReceived = (ethInWei.div(divider)).mul(weiNumber);
            distributeToken(msg.sender, tokenReceived);
        } else {
            // First time buyer gets free tokens (tokenRate)
            distributeToken(msg.sender, tokenRate);
        }

        if (!hasReceived[msg.sender] && tokenRate > 0) {
            hasReceived[msg.sender] = true;
        }

        if (totalDistributed >= totalSupply_) {
            distributionFinished = true;
        }
    }
    
    function transfer(
        address _to, 
        uint256 _amount
    ) 
        public 
        onlyPayloadSize(2 * 32) 
        whenNotPaused 
        notBlacklisted 
        returns (bool success) 
    {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _amount
    )
        public 
        onlyPayloadSize(3 * 32) 
        whenNotPaused 
        notBlacklisted 
        returns (bool success) 
    {
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(
        address _spender, 
        uint256 _value
    ) 
        public 
        whenNotPaused 
        returns (bool success) 
    {
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(
        address _owner, 
        address _spender
    ) 
        public 
        view 
        whenNotPaused 
        returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function withdraw() public onlyOwner {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawTokens(
        address tokenAddress, 
        uint256 tokens
    ) 
        public
        onlyOwner 
        returns (bool success)
    {
        return ERC20Basic(tokenAddress).transfer(owner, tokens);
    }
    
    function approveAndCall(
        address _spender, 
        uint256 _value, 
        bytes _extraData
    ) 
        public 
        whenNotPaused 
    {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(
            msg.sender, 
            _value, 
            address(this), 
            _extraData
        );
    }

}