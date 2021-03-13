/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity >=0.4.22 ;


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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}




// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


// ----------------------------------------------------------------------------
// Token Interface = ERC20 + symbol + name + decimals + approveAndCall
// ----------------------------------------------------------------------------
contract TokenInterface is ERC20Interface {
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function decimals() public view returns (uint8);
}





/**
 * @title Moon Money
 * @dev Farmable ERC20 token. Earn this token by staking another token over time. 
 */
contract MoonMoney is TokenInterface {
    
    using SafeMath for uint;
    
    string _symbol = "MOON";
    string  _name = "MoonMoney";
    uint8 _decimals = 18;
    uint _totalSupply;
    
    uint mintingDivisor = 10000000000; 
    uint public MinStakingTimeBlocks = 1000000;
    
    //balances and allowance of the farmable token 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Mint(address indexed to, uint tokens);
    
    
    mapping (address => TokenVault) public stakedTokens; 
     
    struct TokenVault {
        uint tokenAmount;
        uint blockTimeDeposited;
    }
    
    address public stakeableToken; 
    
    constructor(address sToken) public
    {
        stakeableToken=sToken;
    }
    
        
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
    
    
    
    //Resets the block number in your vault and pays out yield based on the difference to current blocknum.  
    //This keeps the 'amount staked' the same but brings the block number forward to the current time.
    function _claimYields(address staker) internal returns (uint256 amt){
        
         uint amountStaked = stakedTokens[staker].tokenAmount; 
        
         uint amountEarned = getFarmYieldForStakedAmount(amountStaked);
        
        //mint new tokens
        require( _mintFarmableToken(amountEarned, staker) ); 
         
        
        //update only the block number in the token vault, bring it up to the current block
        stakedTokens[staker] = TokenVault( amountStaked , block.number );
        
        
        return amountEarned; 
        
    }
    
    function _mintFarmableToken(uint amount, address recipient) internal returns (bool)
    {
        balances[recipient] = balances[recipient].add(amount); 
        _totalSupply = _totalSupply.add(amount);
        
        emit Mint(recipient,amount);
        
        return true;
        
    }
      
    
    
     /**
     * @dev Users can stake their tokens, requires preApproval.  Forces a claim of yield.
     */
    function stakeTokens(uint amount) public returns (uint256 amt){
         
        require( amount > 0 );
        
        address from = msg.sender;
        uint blockNum = block.number;
        
        //staking vault must be empty and unsealed
        require(  stakedTokens[from].tokenAmount == 0 );  
        require( vaultIsUnsealed(from) );
        
        //transfer the stakeable tokens into this contract and record that fact in the vault 
        require( ERC20Interface(stakeableToken).transferFrom(from, address(this), amount) ) ; 
        
         
        stakedTokens[from] = TokenVault( amount , blockNum );
        
        //forcibly claim yields here to reset the block number 
        return _claimYields(from);
        
         
    }
    
    
    
    function restakeTokens() public returns (uint256 amt){
      
        address from = msg.sender; 
        uint blockNum = block.number;
         
        require( stakedTokens[from].tokenAmount > 0 );  
        require( vaultIsUnsealed(from) );
        
        
        //reset the timer on the vault, reseal it 
        uint amountStaked = stakedTokens[from].tokenAmount;
        stakedTokens[from] = TokenVault( amountStaked , blockNum );
        
        
        
        return _claimYields(from);
    }
    
    
    
    
    /**
     * @dev Users can unstake their tokens. Forces a claim of yield.
     */
    function unstakeTokens() public returns (uint amount){
    
        
        address from = msg.sender;
       
        
        uint amountRemainingInVault = stakedTokens[from].tokenAmount.sub(amount);
        

        require(amountRemainingInVault > 0);
        
        require( vaultIsUnsealed(from) );
        
        
        //clear out token vault 
        stakedTokens[from] = TokenVault( 0 , 0 );
            
        //transfer the staking tokens out 
        require( ERC20Interface(stakeableToken).transfer(from, amountRemainingInVault) ) ; 
        
        return amountRemainingInVault;
    }
    
    function getVaultBalance(address accountAddress) public view returns (uint amt)
    {
        return stakedTokens[accountAddress].tokenAmount;
    }
    
    function getVaultExpiration(address accountAddress) public view returns (uint amt)
    {
        if(vaultIsUnsealed(accountAddress)){
            return 0;
        }
        
        return stakedTokens[accountAddress].blockTimeDeposited.add(MinStakingTimeBlocks);
    }
    
    function vaultIsUnsealed(address accountAddress) public view returns (bool)
    {
        uint blockNum = block.number;
        
        return ((stakedTokens[accountAddress].blockTimeDeposited == 0) || (stakedTokens[accountAddress].blockTimeDeposited <= (blockNum.sub(MinStakingTimeBlocks))) );
    }
    
    
    function getFarmYieldForStakedAmount( uint256 stakedAmount) public view returns (uint amt)
    {  
        uint amountEarned = stakedAmount.mul(mintingDivisor); 
        
        return amountEarned;
    }
    
   
     
}