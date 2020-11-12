pragma solidity >=0.5.22 <0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
    
    contract ERC20 {
        
    // Balances
    mapping(address => uint) tokenBalances;
    // Allowances
    mapping(address => mapping(address => uint)) tokenAllowances;
    // The owner of this token
    address public owner;
    // Optional ERC-20 Functions
    string public constant name = "Worth";
    string public constant symbol = "WTH";
    uint256 public constant decimals = 8;

    // Constructor. Called ONCE when the contract is deployed.
    constructor() public {
        owner = msg.sender;
        currentSupply = 0;
    }

    // Implement a minting function here -OR- generate a fixed
    // supply in the constructor


    uint currentSupply;

    // Required ERC-20 Functions
    /** Returns the current total supply of tokens available. The easisest
        way to implement this function is to keep track of the total supply
        in a storage variable and to return it when this functino is called. */
    function totalSupply() public view returns (uint) {
        return currentSupply;
    }

    /** Return the balance of a given token owner. */
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return tokenBalances[tokenOwner];
    }

    /** Return the tokens that spender is still allowed to return from tokenOwner. */
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return tokenAllowances[tokenOwner][spender];
    }

    /** Transfer tokens from sender's account to the to account.
        Zero-value transfers MUST be treated as normal transfers.
        This function should throw an error (use require(condition, message)) if
        the account has insufficient tokens.
        A successful transfer should emit the Transfer() event.
     */
    function transfer(address to, uint tokens) public returns (bool success) {
        uint tokenBalance = tokenBalances[msg.sender];
        require(tokenBalance > tokens, "You do not have enough tokens");
        tokenBalances[msg.sender] -= tokens;
        tokenBalances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /** Approve spender to spend tokens from caller's account.
        If this function is called multiple times, the previous allowance
        is replaced.
        Successful execution of this function should emit the Approval() event.
     */
    function approve(address spender, uint tokens) public returns (bool success) {
        tokenAllowances[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function mint(address to, uint tokens) public returns (bool success) {
        require(msg.sender == owner, "You must be the token owner to call this function");
        tokenBalances[to] += tokens;
        currentSupply += tokens;
        return true;
    }

    /** Transfer tokens from one account to another account.
        Zero-value transfers MUST be treated as normal transfers.
        This function should throw an error (use require(condition, message)) if
        the from account has insufficient tokens or there is insufficient allowance
        for the caller account.
        A successful transfer should emit the Transfer() event.
     */
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokenAllowances[from][msg.sender] > tokens, "Not enough token allowance to transfer!");
        require(tokenBalances[from] > tokens, "Account does not have enough tokens");
        tokenBalances[from] -= tokens;
        tokenBalances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    /** This event is emitted when tokens are transferred from one account to another. */
    event Transfer(address indexed from, address indexed to, uint tokens);

    /** This event is emitted when tokens are approved for transfer from one account to another.. */
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}