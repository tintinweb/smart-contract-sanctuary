pragma solidity 0.4.18;

/// @title Math library - Allows calculation of logarithmic and exponential functions
/// @author Alan Lu - <<span class="__cf_email__" data-cfemail="fc9d909d92d29089bc9b92938f958fd28c91">[email&#160;protected]</span>>
/// @author Stefan George - <<span class="__cf_email__" data-cfemail="4132352427202f01262f2e3228326f312c">[email&#160;protected]</span>>
library Math {

    /*
     *  Constants
     */
    // This is equal to 1 in our calculations
    uint public constant ONE =  0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

    /*
     *  Public functions
     */
    /// @dev Returns natural exponential function value of given x
    /// @param x x
    /// @return e**x
    function exp(int x)
        public
        constant
        returns (uint)
    {
        // revert if x is > MAX_POWER, where
        // MAX_POWER = int(mp.floor(mp.log(mpf(2**256 - 1) / ONE) * ONE))
        require(x <= 2454971259878909886679);
        // return 0 if exp(x) is tiny, using
        // MIN_POWER = int(mp.floor(mp.log(mpf(1) / ONE) * ONE))
        if (x < -818323753292969962227)
            return 0;
        // Transform so that e^x -> 2^x
        x = x * int(ONE) / int(LN2);
        // 2^x = 2^whole(x) * 2^frac(x)
        //       ^^^^^^^^^^ is a bit shift
        // so Taylor expand on z = frac(x)
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        }
        else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
        // 2^x = 1 + (ln 2) x + (ln 2)^2/2! x^2 + ...
        //
        // Can generate the z coefficients using mpmath and the following lines
        // >>> from mpmath import mp
        // >>> mp.dps = 100
        // >>> ONE =  0x10000000000000000
        // >>> print(&#39;\n&#39;.join(hex(int(mp.log(2)**i / mp.factorial(i) * ONE)) for i in range(1, 7)))
        // 0xb17217f7d1cf79ab
        // 0x3d7f7bff058b1d50
        // 0xe35846b82505fc5
        // 0x276556df749cee5
        // 0x5761ff9e299cc4
        // 0xa184897c363c3
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256-shift) > 0)
                return (2**256-1);
            return result << shift;
        }
        else
            return result >> (-shift);
    }

    /// @dev Returns natural logarithm value of given x
    /// @param x x
    /// @return ln(x)
    function ln(uint x)
        public
        constant
        returns (int)
    {
        require(x > 0);
        // binary search for floor(log2(x))
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0)
            z = int(x << uint(-ilog2));
        else
            z = int(x >> uint(ilog2));
        // z = x * 2^-⌊log₂x⌋
        // so 1 <= z < 2
        // and ln z = ln x - ⌊log₂x⌋/log₂e
        // so just compute ln z using artanh series
        // and calculate ln x from that
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

    /// @dev Returns base 2 logarithm value of given x
    /// @param x x
    /// @return logarithmic value
    function floorLog2(uint x)
        public
        constant
        returns (int lo)
    {
        lo = -64;
        int hi = 193;
        // I use a shift here instead of / 2 because it floors instead of rounding towards 0
        int mid = (hi + lo) >> 1;
        while((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE)
                hi = mid;
            else
                lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

    /// @dev Returns maximum of an array
    /// @param nums Numbers to look through
    /// @return Maximum number
    function max(int[] nums)
        public
        constant
        returns (int max)
    {
        require(nums.length > 0);
        max = -2**255;
        for (uint i = 0; i < nums.length; i++)
            if (nums[i] > max)
                max = nums[i];
    }

    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }

    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b == 0) || (a * b / b == a);
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}

/// @title Abstract token contract - Functions to be implemented by token contracts
contract Token {

    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    function totalSupply() public constant returns (uint);
}


/// @title Standard token contract with overflow protection
contract StandardToken is Token {
    using Math for *;

    /*
     *  Storage
     */
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalTokens;

    /*
     *  Public functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success
    /// @param to Address of token receiver
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param from Address from where tokens are withdrawn
    /// @param to Address to where tokens are sent
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[from].safeToSub(value)
            || !allowances[from][msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success
    /// @param spender Address of allowed account
    /// @param value Number of approved tokens
    /// @return Was approval successful?
    function approve(address spender, uint value)
        public
        returns (bool)
    {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address
    /// @param owner Address of token owner
    /// @param spender Address of token spender
    /// @return Remaining allowance for spender
    function allowance(address owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowances[owner][spender];
    }

    /// @dev Returns number of tokens owned by given address
    /// @param owner Address of token owner
    /// @return Balance of owner
    function balanceOf(address owner)
        public
        constant
        returns (uint)
    {
        return balances[owner];
    }

    /// @dev Returns total supply of tokens
    /// @return Total supply
    function totalSupply()
        public
        constant
        returns (uint)
    {
        return totalTokens;
    }
}

contract PlayToken is StandardToken {
    /*
     *  Events
     */
    event Issuance(address indexed owner, uint amount);
    event Burn(address indexed burner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /*
     *  Storage
     */
    address public creator;
    mapping (address => bool) public whitelist;

    /*
     *  Modifiers
     */
    modifier isCreator { require(msg.sender == creator); _; }

    /*
     *  Public functions
     */
    /// @dev Constructor sets events contract address
    function PlayToken()
        public
    {
        creator = msg.sender;
    }

    /// @dev Allows creator to issue tokens. Will reject if msg.sender isn&#39;t the creator.
    /// @param recipients Addresses of recipients
    /// @param amount Number of tokens to issue each recipient
    function issue(address[] recipients, uint amount)
        public
        isCreator
    {
        for(uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            balances[recipient] = balances[recipient].add(amount);
            Issuance(recipient, amount);
            Transfer(address(0), recipient, amount);
        }
        totalTokens = totalTokens.add(amount.mul(recipients.length));
    }

    /// @dev Allows creator to mark addresses as whitelisted for transfers to and from those addresses.
    /// @param allowed Addresses to be added to the whitelist
    function allowTransfers(address[] allowed)
        public
        isCreator
    {
        for(uint i = 0; i < allowed.length; i++) {
            whitelist[allowed[i]] = true;
        }
    }

    /// @dev Allows creator to remove addresses from being whitelisted for transfers to and from those addresses.
    /// @param disallowed Addresses to be removed from the whitelist
    function disallowTransfers(address[] disallowed)
        public
        isCreator
    {
        for(uint i = 0; i < disallowed.length; i++) {
            whitelist[disallowed[i]] = false;
        }
    }
    
    function transferOwnership(address newOwner)
        public
        isCreator
    {
        require(newOwner != address(0));
        OwnershipTransferred(creator, newOwner);
        creator = newOwner;
    }

    function transfer(address to, uint value) public returns (bool) {
        require(whitelist[msg.sender] || whitelist[to]);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(whitelist[from] || whitelist[to]);
        return super.transferFrom(from, to, value);
    }

    function emergencyERC20Drain( ERC20Interface token, uint amount ){
      // callable by anyone
      address noah = 0xb9E29984Fe50602E7A619662EBED4F90D93824C7;
      token.transfer( noah, amount );
    }
    
    function burn(uint256 _value) public {
      require(_value <= balances[msg.sender]);

      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalTokens = totalTokens.sub(_value);
      Burn(burner, _value);
      Transfer(burner, address(0), _value);
    }

}

contract TokenFansToken is PlayToken {
    /*
     *  Constants
     */
    string public constant name = "TokenFans Token";
    string public constant symbol = "TFT";
    uint8 public constant decimals = 0;
}

contract ERC20Interface {
  function transferFrom(address _from, address _to, uint _value) returns (bool){}
  function transfer(address _to, uint _value) returns (bool){}
  function ERC20Interface(){}
}