/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
contract star{
    
    using SafeMath for uint256;
    
    string  public name = "Star";
    string  public symbol = "*";
    uint256 public decimals=0;
    uint256 public currentSeason=1;
    uint256 public totalSupply;
    address public ownerAddress;
    address public gameContractAddress;
    address public marketAddress;
    
    mapping(address =>mapping(uint256=> uint256)) public balances;
    
    mapping(address =>mapping(uint256=>mapping(address => uint256))) public allowance;
    
    event Transfer(address indexed _from,address indexed _to,uint256 _value);

    event Approval(address indexed _owner,address indexed _spender,uint256 _value);

    constructor (uint256 _initialSupply) public {
        
        ownerAddress=msg.sender;
        balances[msg.sender][currentSeason] = _initialSupply;
        totalSupply=_initialSupply;
        emit Transfer(address(0),msg.sender,_initialSupply);
    
    }
    
    function setGameContractAddress(address contractAddress) public payable {
        require(msg.sender == ownerAddress);
        gameContractAddress = contractAddress;
    }

    function setMarketAddress(address _address) public payable {
        require(msg.sender == ownerAddress);
        marketAddress = _address;
    }
    
    function Seller_Approve_Market(address from , address spender ,uint256 _value) public payable {
    
        require(msg.sender == marketAddress);
        allowance[from][currentSeason][spender] += _value;
        emit Approval(from,spender,_value);
    
    }
    
    function transfer(address _to, uint256 _value) public payable returns (bool success) {
    
        require(_value>0);
        require(balances[msg.sender][currentSeason]>=_value);
        balances[msg.sender][currentSeason] = balances[msg.sender][currentSeason].sub(_value);     
        balances[_to][currentSeason] =balances[_to][currentSeason].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
    
        allowance[msg.sender][currentSeason][_spender] += _value;                                 ///////////if he already approved then it get overrideen =>(Sir 
        emit Approval(msg.sender,_spender, _value);
        return true;
    
    }
    
    function balanceOf(address request) public view returns (uint256){
    
        return balances[request][currentSeason];
    
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
        
        require (_value>0);
        require(_value <= allowance[_from][currentSeason][msg.sender]);  //checking that whether sender is approved or not...
        balances[_from][currentSeason]= balances[_from][currentSeason].sub(_value);
        balances[_to][currentSeason] = balances[_to][currentSeason].add(_value);
        allowance[_from][currentSeason][msg.sender]=allowance[_from][currentSeason][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    
    }
    function changeowner(address _newaddress) public  returns(bool success){
    
        require(msg.sender==ownerAddress);
        balances[_newaddress][currentSeason]=balances[ownerAddress][currentSeason];
        balances[ownerAddress][currentSeason]=0;
        ownerAddress=_newaddress;
        return true;
    
    }
    
    function IncreaseSupply(uint256 _newSupply) public payable onlyOwner {
       
        balances[ownerAddress][currentSeason]=balances[ownerAddress][currentSeason].add(_newSupply);  
        totalSupply+=_newSupply;
    
    }
    
    function DecreaseSupply(uint _reduceSupply) public payable onlyOwner{
       
        require(_reduceSupply<=balances[ownerAddress][currentSeason]);
        balances[ownerAddress][currentSeason]=balances[ownerAddress][currentSeason].sub(_reduceSupply);
        totalSupply-=_reduceSupply;
    
    }
    
    function changeSeason()public payable onlyOwner{
        
        currentSeason+=1;
        balances[ownerAddress][currentSeason] =balances[ownerAddress][currentSeason].add(balances[ownerAddress][currentSeason.sub(1)]);
        approve(gameContractAddress , balances[ownerAddress][currentSeason]);
        
    }

    function returnSeason() public view returns(uint256){
        
        return currentSeason;

    }

    modifier onlyOwner () {
 
        require(msg.sender == ownerAddress);
        _;

    }
}




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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