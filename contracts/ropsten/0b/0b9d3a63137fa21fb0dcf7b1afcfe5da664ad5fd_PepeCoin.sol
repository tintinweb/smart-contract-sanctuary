/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity 0.6.6;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        assert(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

abstract contract SafeMath {
     /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

contract PepeCoin is Owned, SafeMath {
    string  public Name = "PepeCoin";
    string  public Symbol = "PEPE";
    uint8 public Decimal = 18;
    uint256 public TotalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public Allowance;

    constructor (uint256 InitialSupply) public {
        balanceOf[owner] = InitialSupply;
        TotalSupply = InitialSupply;
    }

    function transfer(address to, uint coins) public returns (bool success) {
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], coins);
        balanceOf[to] = add(balanceOf[to], coins);
        emit Transfer(msg.sender, to, coins);
        return true;
    }

    function approve(address spender, uint coins) public returns (bool success) {
        Allowance[msg.sender][spender] = coins;
        emit Approval(msg.sender, spender, coins);
        return true;
    }

    function transferFrom(address from, address to, uint coins) public returns (bool success) {
        balanceOf[from] = sub(balanceOf[from], coins);
        Allowance[from][msg.sender] = sub(Allowance[from][msg.sender], coins);
        balanceOf[to] = add(balanceOf[to], coins);
        emit Transfer(from, to, coins);
        return true;
    }
    
        function mint(address account, uint256 coins) external onlyOwner {
        require(account != address(0));

        TotalSupply = add(TotalSupply, coins);
        balanceOf[account] = add(balanceOf[account], coins);
        emit Transfer(address(0), account, coins);
    }   
    
        function burn(address account, uint256 coins) external onlyOwner {
        require(account != address(0));

        TotalSupply = sub(TotalSupply, coins);
        balanceOf[account] = sub(balanceOf[account], coins);
        emit Transfer(account, address(0), coins);
    }
}