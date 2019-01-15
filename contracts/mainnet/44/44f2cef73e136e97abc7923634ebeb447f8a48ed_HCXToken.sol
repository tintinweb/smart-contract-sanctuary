pragma solidity ^0.4.25;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
// ----------------------------------------------------------------------------
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is ERC20Interface {

    using SafeMath for uint256;

    string  private tokenName;
    string  private tokenSymbol;
    uint8   private tokenDecimals;
    uint256 internal tokenTotalSupply;
    uint256 public publicReservedToken;
    uint256 public tokenConversionFactor = 10**4;
    mapping(address => uint256) internal balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) internal allowed;


    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage/*,address[] boardReserved,uint256[] boardReservedPersentage*/) public {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        tokenTotalSupply = _totalSupply;

        // The initial Public Reserved balance of tokens is assigned to the given token holder address.
        // from total supple 90% tokens assign to public reserved  holder
        publicReservedToken = _totalSupply.mul(_publicReservedPersentage).div(tokenConversionFactor);
        balances[_publicReserved] = publicReservedToken;

        //10 persentage token available for board members
        //uint256 boardReservedToken = _totalSupply.sub(publicReservedToken);

        // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
        emit Transfer(0x0, _publicReserved, publicReservedToken);

		/*
        // The initial Board Reserved balance of tokens is assigned to the given token holder address.
        uint256 persentageSum = 0;
        for(uint i=0; i<boardReserved.length; i++){
            //
            persentageSum = persentageSum.add(boardReservedPersentage[i]);
            require(persentageSum <= 10000);
            //assigning board members persentage tokens to particular board member address.
            uint256 token = boardReservedToken.mul(boardReservedPersentage[i]).div(tokenConversionFactor);
            balances[boardReserved[i]] = token;
            Transfer(0x0, boardReserved[i], token);
        }
		*/

    }


    function name() public view returns (string) {
        return tokenName;
    }


    function symbol() public view returns (string) {
        return tokenSymbol;
    }


    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }


    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    // Get the token balance for account `tokenOwner`
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 fromBalance = balances[msg.sender];
        if (fromBalance < _value) return false;
        if (_value > 0 && msg.sender != _to) {
          balances[msg.sender] = fromBalance.sub(_value);
          balances[_to] = balances[_to].add(_value);
        }
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // Send `tokens` amount of tokens from address `from` to address `to`
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        uint256 spenderAllowance = allowed [_from][msg.sender];
        if (spenderAllowance < _value) return false;
        uint256 fromBalance = balances [_from];
        if (fromBalance < _value) return false;
    
        allowed [_from][msg.sender] = spenderAllowance.sub(_value);
    
        if (_value > 0 && _from != _to) {
          balances [_from] = fromBalance.sub(_value);
          balances [_to] = balances[_to].add(_value);
        }

        emit Transfer(_from, _to, _value);

        return true;
    }

    // Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}

contract Owned {

    address public owner;
    address public proposedOwner = address(0);

    event OwnershipTransferInitiated(address indexed _proposedOwner);
    event OwnershipTransferCompleted(address indexed _newOwner);
    event OwnershipTransferCanceled();


    constructor() public
    {
        owner = msg.sender;
    }


    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }


    function isOwner(address _address) public view returns (bool) {
        return (_address == owner);
    }


    function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
        require(_proposedOwner != address(0));
        require(_proposedOwner != address(this));
        require(_proposedOwner != owner);

        proposedOwner = _proposedOwner;

        emit OwnershipTransferInitiated(proposedOwner);

        return true;
    }


    function cancelOwnershipTransfer() public onlyOwner returns (bool) {
        //if proposedOwner address already address(0) then it will return true.
        if (proposedOwner == address(0)) {
            return true;
        }
        //if not then first it will do address(0) then it will return true.
        proposedOwner = address(0);

        emit OwnershipTransferCanceled();

        return true;
    }


    function completeOwnershipTransfer() public returns (bool) {

        require(msg.sender == proposedOwner);

        owner = msg.sender;
        proposedOwner = address(0);

        emit OwnershipTransferCompleted(owner);

        return true;
    }
}

contract FinalizableToken is ERC20Token, Owned {

    using SafeMath for uint256;


    /**
         * @dev Call publicReservedAddress - library function exposed for testing.
    */
    address public publicReservedAddress;


    event Burn(address indexed burner,uint256 value);

    // The constructor will assign the initial token supply to the owner (msg.sender).
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply,address _publicReserved,uint256 _publicReservedPersentage) public
    ERC20Token(_name, _symbol, _decimals, _totalSupply, _publicReserved, _publicReservedPersentage)
    Owned(){
        publicReservedAddress = _publicReserved;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        return super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        return super.transferFrom(_from, _to, _value);
    }



    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
     //get current time
    function currentTime() public constant returns (uint256) {
        return now;
    }

}

contract HCXTokenConfig {

    string  public constant TOKEN_SYMBOL      = "HCX";
    string  public constant TOKEN_NAME        = "HOLIDAY CAPITAL Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;

    address public constant PUBLIC_RESERVED = 0x6E22277b9A32a88cba52d5108ca7E836d994859f;
    uint256 public constant PUBLIC_RESERVED_PERSENTAGE = 10000;

}

// Holiday Capital issues vouchers in the form of blockchain tokens to spend in all of its apartments around the world.
contract HCXToken is FinalizableToken, HCXTokenConfig {

    using SafeMath for uint256;
    event TokensReclaimed(uint256 _amount);

    constructor() public
    FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY, PUBLIC_RESERVED, PUBLIC_RESERVED_PERSENTAGE)
    {

    }


    // Allows the owner to reclaim tokens that have been sent to the token address itself.
    function reclaimTokens() public onlyOwner returns (bool) {

        address account = address(this);
        uint256 amount  = balanceOf(account);

        if (amount == 0) {
            return false;
        }

        balances[account] = balances[account].sub(amount);
        balances[owner] = balances[owner].add(amount);

        emit Transfer(account, owner, amount);

        emit TokensReclaimed(amount);

        return true;
    }
}