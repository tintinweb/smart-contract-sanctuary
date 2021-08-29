/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//-----------------------------------------------------------------------------//
//                             Name : MultiPad                                 //
//                           Symbol : MPAD                                     //
//                     Total Supply : 100,000,000                              //
//                  Company Reserve : 25,000,000                               //
//          Marketing and ecosystem : 20,000,000                               //
//                             Team : 20,000,000                               //
//                        Liquidity : 10,000,000                               //
//                    IDO fundraise : 15,000,000                               //
//       Partners & Early Investors : 10,000,000                               //
//-----------------------------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract MultiPad is IBEP20 {
    
    using SafeMath for uint256;
    
    //variable declaration
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    // Special business use case variables
    mapping (address => bool) _whitelistedAddress;
    mapping (address => uint256) _lockingTimeForSale;
    mapping (address => uint256) _recordSale;
    mapping (address => bool) _addressLocked;
    mapping (address => uint256) _finalSoldAmount;
    mapping (address => mapping(uint256 => bool)) reEntrance;
    mapping (address => uint256) specialAddBal;
    mapping (address => uint256) _contributionBNB;
    mapping (address => mapping(uint256 => uint256)) _claimedByUser;
    
    address[] private _whitelistedUserAddresses;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private saleMinimumAmount;
    uint256 private saleMaximumAmount;
    uint256 private saleId = 0;
    uint256 private tokenPrice;
    uint256 private deploymentTime; 
    uint256 private pricePerToken;
    uint256 private decimalBalancer = 1000000000;
    uint256 private IDOAvailable = 15000000000000000000000000;

    constructor (string memory name, string memory symbol, uint256 totalSupply, address owner) public {
        _name = name;
        _symbol = symbol; 
        _totalSupply = totalSupply*(10**uint256(_decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;

    }


    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @return the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
            _transfer(msg.sender, to, value);
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
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }

     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) external onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount.add(1);
          }
          return true;
      }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
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
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) external onlyOwner{
        _burn(msg.sender, value);
    }
    
    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
    */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() external view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) external onlyOwner returns (bool){
        require(newOwner != address(0), "Owner address cant be zero");
        _owner = newOwner;
        return true;
    }

}