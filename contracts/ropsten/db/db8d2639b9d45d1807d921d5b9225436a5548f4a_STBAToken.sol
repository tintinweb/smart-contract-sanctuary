// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)
import "./SafeMath.sol";
import "./Utils.sol";

pragma solidity ^ 0.8 .0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns(bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns(bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract TokenERC20 is IERC20, Owned {
    using SafeMath
    for uint;
    using Utils for string;

    string public ISIN;
    string public WKN;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint totalTokenSupply;

    mapping(address => uint) balances;
    
    mapping(address => bool) blacklist;
    
    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => uint) timelocks;
    uint timelockLimit = 1 minutes;
    

    constructor() {}
    
    function init(string memory _symbol, string memory _name, 
                string memory _ISIN, string memory _WKN, uint8 _decimals, uint _totalSupply) internal {
        ISIN = checkValidityISIN(_ISIN.checkLength(12));
        WKN = checkValidityWKN(_WKN.checkLength(6));
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalTokenSupply = _totalSupply * (10 ** decimals);
        balances[owner] = totalTokenSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function checkValidityISIN(string memory _ISIN) pure internal returns(string memory) {
        require(_ISIN.checkAlphanumeric(), "ERC20: ISIN not alphanumeric");

         /*
        bytes memory buffer = bytes(_ctx);
        
        uint256 finalnumber = 1;
        uint iteratorEx = 0;
        uint finNumSize = 0;
        bytes1 b;
            uint8 c1;
        for(uint i; i < _ctx.length();i++){
            b = buffer[_ctx.length()-i-1];
            if(b < 0x41) {
                c1 = uint8(b);
                finalnumber = c1 * 10 + finalnumber;
                finNumSize++;
            } else {
                c1 = uint8(b) - uint8(0x41-10);
                finalnumber += c1 * 100 ** iteratorEx++;
                finNumSize+=2;
            }
        }
        
        return _ctx.length();
        */
        return _ISIN;
    }
    
    function checkValidityWKN(string memory _WKN) pure internal returns(string memory) {
        require(_WKN.checkAlphanumeric(), "ERC20: WKN not alphanumeric");
        return _WKN;
    }

    function totalSupply() public view override returns(uint) {
        return totalTokenSupply.sub(balances[address(0)]);
    }

    function getBalance() public view returns(uint) {
        return balanceOf(msg.sender);
    }

    function balanceOf(address tokenOwner) public view override returns(uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens)public override timelockCheck blacklistCheck returns(bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override timelockCheck blacklistCheck returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns(bool success) {

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view override returns(uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function mint(uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: mint to the zero address");
        totalTokenSupply = totalTokenSupply.add(amount);
        balances[msg.sender] = totalTokenSupply.add(amount);
    }
    
   function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(balances[account] <= amount, "ERC20: burn amount exceeds balance");
        totalTokenSupply = totalTokenSupply.sub(amount);
    }

    modifier timelockCheck() {
        if((timelocks[msg.sender] != 0) && (msg.sender != owner)) {
            require(timelocks[msg.sender] + timelockLimit > block.timestamp);
        }
        _;
    }
    
    modifier blacklistCheck() {
        require(!blacklist[msg.sender]);
        _;
    }
    
    function setTimelockLimit(uint _timelockLimit) public onlyOwner {
        require(_timelockLimit > 0, "ERC20: Timelock invalid!");
        timelockLimit = _timelockLimit;
    }
    
    function setBlacklist(address _address, bool _state) public onlyOwner {
        blacklist[_address] = _state;
    }

}


contract STBAToken is TokenERC20 {
    /* constructor(string memory _symbol, string memory _name, string memory _ISIN, string memory _WKN, uint8 _decimals, uint _totalSupply) { 
       
        init(_symbol, 
            _name, 
            _ISIN0000,
            _WKN,
            _decimals, 
            _totalSupply);
        */
    constructor() {
            init("STBAT", 
            "Security Token BAT", 
            "DE8329285235",
            "WKN755",
            9, 
            1000);
    }
    
}