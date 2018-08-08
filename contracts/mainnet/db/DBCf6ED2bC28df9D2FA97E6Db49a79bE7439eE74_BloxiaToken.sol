pragma solidity 0.4.23;

/**
 * ERC20 compliant interface
 * See: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
**/
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

/**
 * @title SafeMath
 * Math operations with safety checks that throw on error
**/
library SafeMath {

    /**
     * Adds two numbers a and b, throws on overflow.
    **/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }

    /**
     * Subtracts two numbers a and b, throws on overflow (i.e. if b is greater than a).
    **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        return a - b;
    }

    /**
     * Multiplies two numbers, throws on overflow.
    **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);

        return c;
    }

    /**
     * Divide of two numbers (a by b), truncating the quotient.
    **/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0

        return a / b;
    }
}

/**
 * ERC20 compliant token
**/
contract ERC20Token is ERC20Interface {
    using SafeMath for uint256;

    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * Return total number of tokens in existence.
    **/
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Get the balance of the specified address.
     * @param account - The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
    **/
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * Check the amount of tokens that an owner allowed to a spender.
     * @param owner - The address which owns the funds.
     * @param spender - The address which will spend the funds.
     * @return An uint256 specifying the amount of tokens still available for the spender.
    **/
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * Transfer token to a specified address from &#39;msg.sender&#39;.
     * @param recipient - The address to transfer to.
     * @param amount - The amount to be transferred.
     * @return true if transfer is successfull, error otherwise.
    **/
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0) && recipient != address(this));
        require(amount <= balances[msg.sender], "insufficient funds");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * Transfer tokens from one address to another.
     * @param from - The address which you want to send tokens from.
     * @param to - The address which you want to transfer to.
     * @param amount - The amount of tokens to be transferred.
     * @return true if transfer is successfull, error otherwise.
    **/
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0) && to != address(this));
        require(amount <= balances[from] && amount <= allowed[from][msg.sender], "insufficient funds");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);

        emit Transfer(from, to, amount);
        
        return true;
    }

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender - The address which will spend the funds.
     * @param amount - The amount of tokens to be spent.
     * @return true if transfer is successfull, error otherwise.
    **/
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0) && spender != address(this));
        require(amount == 0 || allowed[msg.sender][spender] == 0); // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
}

/**
 * @title Ownable
 * The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
**/
contract Ownable {
    address public owner;

    /**
     * The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
    **/
    constructor() public {
        owner = msg.sender;
    }

    /**
     * Throws if called by any account other than the owner.
    **/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title BurnableToken
 * Implements a token contract in which the owner can burn tokens only from his account.
**/
contract BurnableToken is Ownable, ERC20Token {

    event Burn(address indexed burner, uint256 value);

    /**
     * Owner can burn a specific amount of tokens from his account.
     * @param amount - The amount of token to be burned.
     * @return true if burning is successfull, error otherwise.
    **/
    function burn(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= balances[owner], "amount should be less than available balance");

        balances[owner] = balances[owner].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Burn(owner, amount);
        emit Transfer(owner, address(0), amount);

        return true;
    }
}

/**
 * @title PausableToken
 * Implements a token contract that can be paused and resumed by owner.
**/
contract PausableToken is Ownable, ERC20Token {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * Modifier to make a function callable only when the contract is not paused.
    **/
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * Modifier to make a function callable only when the contract is paused.
    **/
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * Owner can pause the contract (Goes to paused state).
    **/
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * Owner can unpause the contract (Goes to unpaused state).
    **/
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    /**
     * ERC20 specific &#39;transfer&#39; is only allowed, if contract is not in paused state.
    **/
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * ERC20 specific &#39;transferFrom&#39; is only allowed, if contract is not in paused state.
    **/
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    /**
     * ERC20 specific &#39;approve&#39; is only allowed, if contract is not in paused state.
    **/
    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }
}

/**
 * Bloxia Fixed Supply Token Contract
**/
contract BloxiaToken is Ownable, ERC20Token, PausableToken, BurnableToken {

    string public constant name = "Bloxia";
    string public constant symbol = "BLOX";
    uint8 public constant decimals = 18;

    uint256 constant initial_supply = 500000000 * (10 ** uint256(decimals)); // 500 Million

    /**
     * Constructor that gives &#39;msg.sender&#39; all of existing tokens.
    **/
    constructor() public {
        _totalSupply = initial_supply;
        balances[msg.sender] = initial_supply;
        emit Transfer(0x0, msg.sender, initial_supply);
    }
}