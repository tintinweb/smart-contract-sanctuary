pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract IERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract QPSEToken is IERC20 {

    using SafeMath for uint256;

    // Token properties
    string public name = "Qompass";
    string public symbol = "QPSE";
    uint public decimals = 18;

    uint private constant STAGE_PRE_ICO = 1;
    uint private constant STAGE_MAIN_ICO = 2;

    uint public ico_stage = 0;
    uint public _totalSupply = 33000000e18;

    uint public _icoSupply = 20000000e18; // crowdsale 70%
    uint public _presaleSupply = 8000000e18;
    uint public _mainsaleSupply = 12000000e18;
    uint public _futureSupply = 13000000e18;
                                    
//    uint256 public pre_startTime = 1522904400;  //2018/04/08 00:00:00 UTC + 8
    uint256 public pre_endTime = 1523854800;    //2018/04/16 00:00:00 UTC + 8
	
    uint256 public ico_startTime = 1523854800;  //2018/04/16 00:00:00 UTC + 8
//    uint256 public ico_endTime = 1533074400;    //2018/08/01 00:00:00 UTC + 8

    address eth_addr = 0xE3a08428160C8B7872EcaB35578D3304239a5748;
    address token_addr = 0xDB882cFbA6A483b7e0FdedCF2aa50fA311DD392e;

//    address eth_addr = 0x5A745e3A30CB59980BB86442B6B19c317585cd8e;
//    address token_addr = 0x6f5A6AAfD56AF48673F0DDd32621dC140F16212a;

    // Balances for each account
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping(address => uint256)) allowed;

    // Owner of Token
    address public owner;

    // how many token units a buyer gets per wei
    uint public PRICE = 800;
    uint public pre_PRICE = 960;  //800 + 20% as bonus
    uint public ico_PRICE = 840;  //800 + 5% as bonus

    // amount of raised money in wei
    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // modifier to allow only owner has full control on the function
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // Constructor
    // @notice QPSEToken Contract
    // @return the transaction address
    function QPSEToken() public payable {
        owner = msg.sender;
	    fundRaised = 0;
        balances[token_addr] = _totalSupply; 
    }

    // Payable method
    // @notice Anyone can buy the tokens on tokensale by paying ether
    function () public payable {
        tokensale(msg.sender);
    }

    // @notice tokensale
    // @param recipient The address of the recipient
    // @return the transaction address and send the event as Transfer
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
//        require(now >= pre_startTime);

        if (now < pre_endTime) {
            ico_stage = STAGE_PRE_ICO;
        } else {
            ico_stage = STAGE_MAIN_ICO;
        }

        if ( fundRaised >= _presaleSupply ) {
            ico_stage = STAGE_MAIN_ICO;
        }
	
        uint256 weiAmount = msg.value;
        uint tokens = weiAmount.mul(getPrice());

        require(_icoSupply >= tokens);

        balances[token_addr] = balances[token_addr].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _icoSupply = _icoSupply.sub(tokens);
        fundRaised = fundRaised.add(tokens);

        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
        if ( tokens == 0 ) {
            recipient.transfer(msg.value);
        } else {
            eth_addr.transfer(msg.value);    
        }
    }

    // @return total tokens supplied
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    // What is the balance of a particular account?
    // @param who The address of the particular account
    // @return the balanace the particular account
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

    // Token distribution
    function sendTokenToMultiAddr(address[] _toAddresses, uint256[] _amounts) public {
	/* Ensures _toAddresses array is less than or equal to 255 */
        require(_toAddresses.length <= 255);
        /* Ensures _toAddress and _amounts have the same number of entries. */
        require(_toAddresses.length == _amounts.length);

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

    // @notice send `value` token to `to` from `msg.sender`
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transfer(address to, uint256 value) public returns (bool success) {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    // @notice send `value` token to `to` from `from`
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    // Allow spender to withdraw from your account, multiple times, up to the value amount.
    // If this function is called again it overwrites the current allowance with value.
    // @param spender The address of the sender
    // @param value The amount to be approved
    // @return the transaction address and send the event as Approval
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (
            balances[msg.sender] >= _value && _value > 0
        );
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // Check the allowed value for the spender to withdraw from owner
    // @param owner The address of the owner
    // @param spender The address of the spender
    // @return the amount which spender is still allowed to withdraw from owner
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }

    // Get current price of a Token
    // @return the price or token value for a ether
    function getPrice() public view returns (uint result) {
        if ( ico_stage == STAGE_PRE_ICO ) {
    	    return pre_PRICE;
    	} if ( ico_stage == STAGE_MAIN_ICO ) {
    	    return ico_PRICE;
    	}
    }
}