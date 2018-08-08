pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/// @title Contract class
/// @author Infinigon Group
/// @notice Contract class defines the name of the contract
contract Contract {
    bytes32 public Name;

    /// @notice Initializes contract with contract name
    /// @param _contractName The name to be given to the contract
    constructor(bytes32 _contractName) public {
        Name = _contractName;
    }

    function() public payable { }
}

// ----------------------------------------------------------------------------
// ERC20 Default Token
// ----------------------------------------------------------------------------
contract DeaultERC20 is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "DFLT";
        name = "Default";
        decimals = 18;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ---------------------------------------------------------allowance---------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}

// ----------------------------------------------------------------------------
// IGCoin
// ----------------------------------------------------------------------------
contract IGCoin is DeaultERC20 {
    using SafeMath for uint;

    address public reserveAddress; // wei
    uint256 public ask;
    uint256 public bid;
    uint16 public constant reserveRate = 10;
    bool public initialSaleComplete;
    uint256 constant private ICOAmount = 2e6*1e18; // in aToken
    uint256 constant private ICOask = 1*1e18; // in wei per Token
    uint256 constant private ICObid = 0; // in wei per Token
    uint256 constant private InitialSupply = 1e6 * 1e18; // Number of tokens (aToken) minted when contract created
    uint256 public debugVal;
    uint256 public debugVal2;
    uint256 public debugVal3;
    uint256 public debugVal4;
    uint256 constant private R = 12500000;  // matlab R=1.00000008, this R=1/(1.00000008-1)
    uint256 constant private P = 50; // precision
    uint256 constant private lnR = 12500001; // 1/ln(R)   (matlab R)
    uint256 constant private S = 1e8; // s.t. S*R = integer
    uint256 constant private RS = 8; // 1.00000008*S-S=8
    uint256 constant private lnS = 18; // ln(S) = 18
    
    /* Constants to support ln() */
    uint256 private constant ONE = 1;
    uint32 private constant MAX_WETokenHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;
    uint256 private constant FIXED_3 = 0x07fffffffffffffffffffffffffffffff;
    uint256 private constant LN2_MANTISSA = 0x2c5c85fdf473de6af278ece600fcbda;
    uint8   private constant LN2_EXPONENT = 122;

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen); 

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "IG17";
        name = "theTestToken001";
        decimals = 18;
        initialSaleComplete = false;
        _totalSupply = InitialSupply;  // Keep track of all IG Coins created, ever
        balances[owner] = _totalSupply;  // Give the creator all initial IG coins
        emit Transfer(address(0), owner, _totalSupply);

        reserveAddress = new Contract("Reserve");  // Create contract to hold reserve
        quoteAsk();
        quoteBid();        
    }

    /// @notice Deposits &#39;_value&#39; in wei to the reserve address
    /// @param _value The number of wei to be transferred to the 
    /// reserve address
    function deposit(uint256 _value) private {
        reserveAddress.transfer(_value);
        balances[reserveAddress] += _value;
    }
  
    /// @notice Withdraws &#39;_value&#39; in wei from the reserve address
    /// @param _value The number of wei to be transferred from the 
    /// reserve address    
    function withdraw(uint256 _value) private pure {
        // TODO
         _value = _value;
    }
    
    /// @notice Transfers &#39;_value&#39; in wei to the &#39;_to&#39; address
    /// @param _to The recipient address
    /// @param _value The amount of wei to transfer
    function transfer(address _to, uint256 _value) public returns (bool success) {
        /* Check if sender has balance and for overflows */
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        
        /* Check if amount is nonzero */
        require(_value > 0);

        /* Add and subtract new balances */
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    
        /* Notify anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending 
    /// & receiving tokens
    /// @param _target Address to be frozen
    /// @param _freeze either to freeze it or not
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }    
 
    /// @notice Calculates the ask price in wei per aToken based on the 
    /// current reserve amount
    /// @return Price of aToken in wei
    function quoteAsk() public returns (uint256) {
        if(initialSaleComplete)
        {
            ask = fracExp(1e18, R, (_totalSupply/1e18)+1, P);
        }
        else
        {
            ask = ICOask;
        }

        return ask;
    }
    
    /// @notice Calculates the bid price in wei per aToken based on the 
    /// current reserve amount
    /// @return Price of aToken in wei    
    function quoteBid() public returns (uint256) {
        if(initialSaleComplete)
        {
            bid = fracExp(1e18, R, (_totalSupply/1e18)-1, P);
        }
        else
        {
            bid = ICObid;
        }

        return bid;
    }

    /// @notice Buys aToken in exchnage for wei at the current ask price
    /// @return refunds remainder of wei from purchase   
    function buy() public payable returns (uint256 amount){
        uint256 refund = 0;
        debugVal = 0;
        
        if(initialSaleComplete)
        {
            uint256 units_to_buy = 0;

            uint256 etherRemaining = msg.value;             // (wei)
            uint256 etherToReserve = 0;                     // (wei)

            debugVal = fracExp(S, R, (_totalSupply/1e18),P);
            debugVal2 = RS*msg.value;
            debugVal3 = RS*msg.value/1e18 + fracExp(S, R, (_totalSupply/1e18),P);
            debugVal4 = (ln(debugVal3,1)-lnS);//*lnR-1;
            units_to_buy = debugVal4;


            reserveAddress.transfer(etherToReserve);        // send the ask amount to the reserve
            mintToken(msg.sender, amount);                  // Mint the coin
            refund = etherRemaining;
            msg.sender.transfer(refund);                    // Issue refund            
        }
        else
        {
            // TODO don&#39;t sell more than the ICO amount if one transaction is huge
            ask = ICOask;                                   // ICO sale price (wei/Token)
            amount = 1e18*msg.value / ask;                  // calculates the amount of aToken (1e18*wei/(wei/Token))
            refund = msg.value - (amount*ask/1e18);         // calculate refund (wei)

            // TODO test for overflow attack
            reserveAddress.transfer(msg.value - refund);    // send the full amount of the sale to reserve
            msg.sender.transfer(refund);                    // Issue refund
            balances[reserveAddress] += msg.value-refund;  // All other addresses hold Token Coin, reserveAddress represents ether
            mintToken(msg.sender, amount);                  // Mint the coin (aToken)

            if(_totalSupply >= ICOAmount)
            {
                initialSaleComplete = true;
            }             
        }
        
        
        return amount;                                    // ends function and returns
    }

    /// @notice Sells aToken in exchnage for wei at the current bid 
    /// price, reduces resreve
    /// @return Proceeds of wei from sale of aToken
    function sell(uint amount) public returns (uint revenue){
        require(initialSaleComplete);
        require(balances[msg.sender] >= bid);            // checks if the sender has enough to sell
        balances[reserveAddress] += amount;                        // adds the amount to owner&#39;s balance
        balances[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        revenue = amount * bid;
        require(msg.sender.send(revenue));                // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, reserveAddress, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }    
    
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) public {
        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }    
    

    /// @notice Compute &#39;_k * (1+1/_q) ^ _n&#39;, with precision &#39;_p&#39;
    /// @dev The higher the precision, the higher the gas cost. It should be
    /// something around the log of &#39;n&#39;. When &#39;p == n&#39;, the
    /// precision is absolute (sans possible integer overflows).
    /// Much smaller values are sufficient to get a great approximation.
    /// @param _k input param k
    /// @param _q input param q
    /// @param _n input param n
    /// @param _p input param p
    /// @return &#39;_k * (1+1/_q) ^ _n&#39;   
    function fracExp(uint256 _k, uint256 _q, uint256 _n, uint256 _p) public pure returns (uint256) {
      uint256 s = 0;
      uint256 N = 1;
      uint256 B = 1;
      for (uint256 i = 0; i < _p; ++i){
        s += _k * N / B / (_q**i);
        N  = N * (_n-i);
        B  = B * (i+1);
      }
      return s;
    }
    
    /// @notice Compute the natural logarithm
    /// @dev This functions assumes that the numerator is larger than or equal 
    /// to the denominator, because the output would be negative otherwise.
    /// @param _numerator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    /// @param _denominator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
    /// @return is a value between 0 and floor(ln(2 ^ (256 - MAX_PRECISION) - 1) * 2 ^ MAX_PRECISION)
    function ln(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
        assert(_numerator <= MAX_NUM);

        uint256 res = 0;
        uint256 x = _numerator * FIXED_1 / _denominator;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }
        
        return ((res * LN2_MANTISSA) >> LN2_EXPONENT) / FIXED_3;
    }

    /// @notice Compute the largest integer smaller than or equal to 
    /// the binary logarithm of the input
    /// @param _n Operand of the function
    /// @return Floor(Log2(_n))
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }    
  
}