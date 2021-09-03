//SourceUnit: SmurfToken.sol

/*
 * Smurf is an inviolable and decentralized international payment system.
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.15;

interface ITRC20 {
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

    /**
   * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns(uint256);
    
    /**
   * @dev Returns the amount of tokens owned by `account`.
   */
    function balanceOf(address owner) external view returns(uint256);

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
    function approve(address spender, uint256 value) external returns(bool);
    
   /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */    
    function transfer(address to, uint256 value) external returns(bool);
   
   /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */    
    function transferFrom(address from, address to, uint256 value) external returns(bool);


    function name() external view returns(string memory);
    
    function symbol() external view returns(string memory);
    
    function decimals() external view returns(uint8);
   
   /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */        
    function allowance(address owner, address spender) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.15;

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
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, "SafeMath: MATH_ADD_OVERFLOW");
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
    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, "SafeMath: MATH_SUB_UNDERFLOW");
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
    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: MATH_MUL_OVERFLOW");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.15;

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

   /**
   * @dev Mint `amount` tokens and increasing the total supply.
   */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(address(0), to, value);
    }

   /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);
    }
  
   /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

   /**
   * @dev See {TRC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);
    }

   /**
   * @dev See {TRC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
    function approve(address spender, uint256 value) external returns(bool) {
        _approve(msg.sender, spender, value);

        return true;
    }

   /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
    function transfer(address to, uint256 value) external returns(bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

   /**
   * @dev See {TRC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {TRC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        if(allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }

        _transfer(from, to, value);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.15;

contract Smurf is TRC20 {
    address public owner;
    bool public stopmint;

    modifier onlyOwner() {
        require(msg.sender == owner, "Smurf: ACCESS_DENIED");
        _;
    }

    constructor() public {
        owner = msg.sender;

        name = "Smurf";
        symbol = "SMR";
        decimals = 8;
        _mint(msg.sender, 300000000000000000);
    }

   /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
    function mint(address to, uint256 value) external onlyOwner {
        require(!stopmint, "Smurf: MINT_ALREADY_STOPPED");

        _mint(to, value);
    }

   /**
   * @dev change Owner of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
   
   /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwner() external onlyOwner {
        owner = address(0);
    }

   /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   * 
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
    function burn(uint256 value) external onlyOwner {
        require(balanceOf[msg.sender] >= value, "Smurf: INSUFFICIENT_FUNDS");

        _burn(msg.sender, value);
    }

   /**
   * @dev Stop minting further tokens
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
    function stopMint() external onlyOwner {
        require(!stopmint, "Smurf: MINT_ALREADY_STOPED");

        stopmint = true;
    }
}