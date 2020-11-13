pragma solidity 0.5.16;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
}

contract ThreeFMutual {

    struct Player {
        uint256 id;             // agent id
        bytes32 name;           // agent name
        uint256 ref;            // referral vault
        bool isAgent;           // referral activated
        bool claimed;           // insurance claimed
        uint256 eth;            // eth player has paid
        uint256 shares;         // shares
        uint256 units;          // uints of insurance
        uint256 plyrLastSeen;   // last day player played
        uint256 mask;           // player mask
        uint256 level;          // agent level
        uint256 accumulatedRef; // accumulated referral income
    }

    mapping(address => mapping(uint256 => uint256)) public unitToExpirePlayer;
    mapping(uint256 => uint256) public unitToExpire; // unit of insurance due at day x

    uint256 public issuedInsurance; // all issued insurance
    uint256 public ethOfShare;      // virtual eth pointer
    uint256 public shares;          // total share
    uint256 public pool;            // eth gonna pay to beneficiary
    uint256 public today;           // today's date
    uint256 public _now;            // current time
    uint256 public mask;            // global mask
    uint256 public agents;          // number of agent

    // player data
    mapping(address => Player) public player;       // player data
    mapping(uint256 => address) public agentxID_;   // return agent address by id
    mapping(bytes32 => address) public agentxName_; // return agent address by name

}

contract TFToken is ERC20Mintable {
    string public constant name = "ThirdFloorToken";
    string public constant symbol = "TFT";
    uint8 public constant decimals = 18;

    ThreeFMutual public constant Mutual = ThreeFMutual(0x66be1bc6C6aF47900BBD4F3711801bE6C2c6CB32);

    mapping(address => uint256) public claimedAmount;

    function claim(address receiver) external {
        uint256 balance;
        (,,,,,balance,,,,,,) = Mutual.player(receiver);
        require(balance > claimedAmount[receiver]);
        _mint(receiver, balance.sub(claimedAmount[receiver]));
        claimedAmount[receiver] = balance;
    }

}