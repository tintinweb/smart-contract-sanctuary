/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

//-----------------------------------------------------------------------------//
//                             Name : MPadLaunchPad                            //
//                     Swap tokens to claim launch tokens                      //
//                        Distribution Contract                                //
//-----------------------------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IMainToken{
    function transfer(address, uint256) public pure  returns (bool);
    function transferFrom(address, address, uint256) public pure  returns (bool);
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

contract MultiPadLaunchApp is IBEP20 {
    
    using SafeMath for uint256;
    
    IMainToken iMainToken;
    
    //variable declaration
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private IDOAvailable;
    address private tokenContractAddress;
    bool whitelistFlag = true;
    address private IDOAddress;
    
    constructor (string memory name, string memory symbol, uint256 totalSupply, address owner, uint256 _totalDummySupply) public {
        _name = name;
        _symbol = symbol; 
        _totalSupply = totalSupply*(10**uint256(_decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
        _transfer(_owner,address(this),_totalDummySupply*(10**uint256(_decimals)));
    }

    function setTokenAddress(address _ITokenContract) onlyOwner external returns(bool){
        tokenContractAddress = _ITokenContract;
        iMainToken = IMainToken(_ITokenContract);
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
    function totalSupply() external  view returns (uint256) {
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
    function balanceOf(address owner) public  view returns (uint256) {
        return _balances[owner];
    }



    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

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
    
    
     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               iMainToken.transfer(_addresses[i],_amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }

}