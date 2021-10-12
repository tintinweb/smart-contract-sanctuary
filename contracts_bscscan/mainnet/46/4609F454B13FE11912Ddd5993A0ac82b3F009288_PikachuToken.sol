/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
}

contract PikachuToken {
    using SafeMath for uint256;

    string public symbol = "PKC";
    string public name = "PikachuSwap";

    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000000 * 10**18; // 1 Billion
    uint256 public totalBurn;
    
    uint256 public _COMBUSTION_FEE_;
    address payable public _OWNER_;
    bool public _PAUSE_TRADE_;
    mapping(address => bool) public _ALLOWDED_WHITE_;
    

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // ============ Events ============

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ============ Functions ============

    constructor(string memory _name, string memory _symbol, uint256 _fee) public {
        balances[msg.sender] = totalSupply;
        _COMBUSTION_FEE_ = _fee;
        _ALLOWDED_WHITE_[msg.sender] = true;
        _OWNER_ = msg.sender;
        name = _name;
        symbol = _symbol;
    }
    
    function addAllowded(address addr, bool checker) public {
        require(msg.sender == _OWNER_, "Invaild");
        _ALLOWDED_WHITE_[addr] = checker;
    }
    
    function updateFee(uint256 _new_fee) public {
        require(msg.sender == _OWNER_, "Invaild");
        require(_new_fee < 5000, "0<=fee<5000");
        _COMBUSTION_FEE_ = _new_fee;
    }
    
    function pauseTrade(bool is_pause) public {
        require(msg.sender == _OWNER_, "Invaild");
        _PAUSE_TRADE_ = is_pause;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(!_PAUSE_TRADE_, "Pause Transfer");
        uint256 amountWithFee = amount;
        if(!_ALLOWDED_WHITE_[from] && _COMBUSTION_FEE_ != 0) {
            uint256 fee = amount.mul(_COMBUSTION_FEE_) / 10000;
            balances[address(0)] = balances[address(0)].add(fee);
            emit Transfer(from, address(0), fee);
            amountWithFee = amount.sub(fee);
            totalBurn = totalBurn.add(fee);
        }
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amountWithFee);
        emit Transfer(from, to, amountWithFee);
    }

    /**
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "BALANCE_NOT_ENOUGH");
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return balance An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balances[from], "BALANCE_NOT_ENOUGH");
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        _transfer(from, to, amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function migrate(address token) public {
        require(msg.sender == _OWNER_, "Invalid");
        if(token == address(0)) {
            _OWNER_.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(_OWNER_, IERC20(token).balanceOf(address(this)));
        }
    }
}