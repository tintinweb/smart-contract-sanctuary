// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeMath {
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
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/******************************************/
/*      TOKEN INSTANCE STARTS HERE       */
/******************************************/

contract Token {
    
    using SafeMath for uint256;
    
    //variables of the token, EIP20 standard
    string public name = "Exodus Computing Networks";
    string public symbol = "DUS";
    uint256 public decimals = 10; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply = uint256(330000000).mul(uint256(10) ** decimals);
    
    address ZERO_ADDR = address(0x0000000000000000000000000000000000000000);
    address payable public creator; // for destruct contract

    // mapping structure
    mapping (address => uint256) public balanceOf;  //eip20
    mapping (address => mapping (address => uint256)) public allowance; //eip20

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 token);  //eip20
    event Approval(address indexed owner, address indexed spender, uint256 token);   //eip20
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    // constructor (string memory _name, string memory _symbol, uint256 _total, uint256 _decimals) public {
    constructor () public {
        // name = _name;
        // symbol = _symbol;
        // totalSupply = _total.mul(uint256(10) ** _decimals);
        // decimals = _decimals;
        creator = msg.sender;
        balanceOf[creator] = totalSupply;
        emit Transfer(ZERO_ADDR, msg.sender, totalSupply);
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        // prevent 0 and attack!
        require(_value > 0 && _value <= totalSupply, 'Invalid token amount to transfer!');

        require(_to != ZERO_ADDR, 'Cannot send to ZERO address!'); 
        require(_from != _to, "Cannot send token to yourself!");
        require (balanceOf[_from] >= _value, "No enough token to transfer!");   

        // update balance before transfer
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 token) public returns (bool success) {
        return _transfer(msg.sender, to, token);
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 token) public returns (bool success) {
        require(spender != ZERO_ADDR);
        require(balanceOf[msg.sender] >= token, "No enough balance to approve!");
        // prevent state race attack
        require(allowance[msg.sender][spender] == 0 || token == 0, "Invalid allowance state!");
        allowance[msg.sender][spender] = token;
        emit Approval(msg.sender, spender, token);
        return true;
    }
	
    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 token) public returns (bool success) {
        require(allowance[from][msg.sender] >= token, "No enough allowance to transfer!");
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(token);
        _transfer(from, to, token);
        return true;
    }
    
    //destroy this contract
    function destroy() public {
        require(msg.sender == creator, "You're not creator!");
        selfdestruct(creator);
    }

    //Fallback: reverts if Ether is sent to this smart contract by mistake
    fallback() external {
  	    revert();
    }
}