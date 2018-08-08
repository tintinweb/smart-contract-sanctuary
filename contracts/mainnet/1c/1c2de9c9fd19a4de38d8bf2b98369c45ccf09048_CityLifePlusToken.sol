pragma solidity ^0.4.21;

/** ----------------------------------------------------------------------------
  * &#39;CL+&#39; &#39;CITYLIFE PLUS Token&#39; token contract
  *
  * Symbol      : CL+
  * Name        : CITYLIFE PLUS Token
  * Total supply: 1,000,000,000.000000000000000
  * Decimals    : 18
  *
  *
  *  &#169; 2018 City Life. All rights reserved.
  * ----------------------------------------------------------------------------
  */

/**
  * @title Safe maths
  * @dev Prevent math errors.
  */
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

/**
  * @title ERC20Interface
  * @dev ERC Token Standard #20 Interface
  * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
  */
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

/**
  * @title ApproveAndCallFallBack
  * @dev Contract function to receive approval and execute function in one call
  */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


/**
 * @title Owned
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic ERC20 Interface.
 * @dev https://github.com/ethereum/EIPs/issues/20
 *
 */
contract CityLifePlusToken is ERC20Interface, Pausable {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * @dev Constructor
     */
    function CityLifePlusToken() public {
        symbol = "CL+";
        name = "CITYLIFE PLUS Token";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    /**
      * @dev total number of tokens in existence
      */
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    /**
      * @dev Gets the balance of the specified address.
      * @param tokenOwner The address to query the the balance of.
      * @return An uint256 representing the amount owned by the passed address.
      */
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

    /**
      * @dev transfer token for a specified address
      * @param to The address to transfer to.
      * @param tokens The amount to be transferred.
      */
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param tokens The amount of tokens to be spent.
     */
    function approve(address spender, uint tokens) public returns (bool success) {
        /** To change the approve amount you first have to reduce the addresses&#180;
          *  allowance to zero by calling `approve(_spender,0)` if it is not
          *  already 0 to mitigate the race condition described here:
          *  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
          */
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
       * @dev Increase the amount of tokens that an owner allowed to a spender.
       * @param spender The address which will spend the funds.
       * @param addedValue The amount of tokens to increase the allowance by.
       */
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param tokens uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(to != address(0));
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param tokenOwner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    /**
     * Token owner can approve for `spender` to transferFrom(...) `tokens`
     * from the token owner&#39;s account. The `spender` contract function
     * `receiveApproval(...)` is then executed
     */
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        require(spender != address(0));

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    /**
      * @dev Don&#39;t accept ETH.
      */
    function () public payable {
        revert();
    }

    /**
      * @dev Owner can transfer out any accidentally sent ERC20 tokens
      */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner whenNotPaused returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}