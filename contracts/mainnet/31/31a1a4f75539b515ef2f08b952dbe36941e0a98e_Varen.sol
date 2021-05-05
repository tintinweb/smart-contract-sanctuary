/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT

/*
 ____   ____        __        _______      _________   ____  _____ 
|_  _| |_  _|      /  \      |_   __ \    |_   ___  | |_   \|_   _|
  \ \   / /       / /\ \       | |__) |     | |_  \_|   |   \ | |  
   \ \ / /       / ____ \      |  __ /      |  _|  _    | |\ \| |  
    \ ' /      _/ /    \ \_   _| |  \ \_   _| |___/ |  _| |_\   |_ 
     \_/      |____|  |____| |____| |___| |_________| |_____|\____|

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Details {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC677 is IERC20 {
    function transferAndCall(address recipient, uint amount, bytes memory data) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

interface IERC677Receiver {
    function onTokenTransfer(address sender, uint value, bytes memory data) external;
}

/// @notice EIP-20 token name for this token
contract Varen is IERC677, IERC20Details {
    using SafeMath for uint256;
    
    /// @notice EIP-20 token name for this token
    string public constant override name = 'Varen';
    
    /// @notice EIP-20 token symbol for this token
    string public constant override symbol = 'VRN';
    
    /// @notice EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;
    
    /// @notice Total number of tokens in circulation: 88,888
    uint256 public constant override totalSupply = 88888e18;
    
    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) private _allowances;
    
    /// @notice Official record of token balances for each account
    mapping (address => uint256) private _balances;
    
    /// @notice Initial treasury of Varen 
    address private constant TREASURY = 0xE69A81b96FBF5Cb6CAe95d2cE5323Eff2bA0EAE4;
    
    /// @notice Construct Varen token and allocate all tokens to treasury
    constructor() {
        _balances[TREASURY] = totalSupply;
    }
    
    /**
     * @notice Get the number of tokens held by `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `owner`
     * @param owner The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `recipient`
     * @param recipient The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    
    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `recipient` and call the recipient if it is a contract
     * @param recipient The address of the destination account
     * @param amount The number of tokens to transfer
     * @param data The extra data to be passed to the receiving contract.
     * @return Whether or not the transfer succeeded
     */
    function transferAndCall(address recipient, uint amount, bytes memory data) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount, data);
        
        if (_isContract(recipient)) {
          IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        }
        
        return true;
    }
    
    /**
     * @notice Transfer `amount` tokens from `sender` to `recipient`
     * @param sender The address of the source account
     * @param recipient The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "amount exceeds allowance"));
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `msg.sender`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @notice Atomically increase the allowance granted to `spender` by msg.sender. 
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * 
     * @param spender The address of the account for which the allowance has to be increased
     * @param addedValue The number of tokens to increase the allowance by
     * @return Whether or not the allowance was successfully increased
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    /**
     * @notice Atomically decrease the allowance granted to `spender` by msg.sender. 
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * 
     * @param spender The address of the account for which the allowance has to be decreased
     * @param subtractedValue The number of tokens to decrease the allowance by
     * @return Whether or not the allowance was successfully decreased
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] = _balances[sender].sub(amount, "amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 length;
        assembly { length := extcodesize(addr) }
        return length > 0;
    }
}

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}