/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

//SPDX-License-Identifier: MIT

/**
              @@@                                @@@)                    
              @@@@                              @@@@)                    
              @@@@@)                           @@@@@)                    
              @@@@@@@                        @@@@@@@)                    
              @@@@@@@@)                     @@@@@@@@)                    
               @@@@@@@@@)                  @@@@@@@@)                     
                 @@@@@@@@@              (@@@@@@@@@                       
                (@@@@@@@@@@@          (@@@@@@@@@@                       
                 (@@@@@@@@@@@)        @@@@@@@@@@@                       
                  (@@@@@@@@@@@@)     (@@@@@@@@@@)                        
                    @@@@@@@@@@@@     (@@@@@@@@)                          
                       @@@@@@@@@@   @@@@@@@                             
                          @@@@@@@@@@@@@@@@                               
                          @@@@@@@@@@@@@@)                                
                            @@@@@@@@@@)                                  
                              (@@@@)   

                           VETTA.FINANCE
*/

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context{
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata)
    {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 public _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address)
    {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner()
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Token is Context, Ownable{
    mapping (address => uint256) public balance;
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => bool) private isFrozen;
    uint256 public totalSupply = 10000000 * 10 ** 9;
    string public name = "Vetta Coin";
    string public symbol = "VETTA";
    uint256 public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balance[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }
    
    function balanceOf(address owner) public view returns(uint256) {
        return balance[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(_msgSender()) >= value, 'Balance is too low');
        require(isFrozen[_msgSender()] != true, "Account is frozen");
        balance[to] += value;
        balance[_msgSender()] -= value;
        emit Transfer(_msgSender(), to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, "Balance is too low.");
        require(allowance[from][_msgSender()] >= value, "Allowance is too low");
        require(isFrozen[_msgSender()] != true, "Account is frozen");
        balance[to] += value;
        balance[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[_msgSender()][spender] = value;
        emit Approval(_msgSender(), spender, value);
        return true;   
    }

    function isFrozenAccount(address account) public view returns(bool) {
        return isFrozen[account];
    }

    function includeInFrozen(address account) public onlyOwner {
        isFrozen[account] = true;
    }

    function excludeFromFrozen(address account) public onlyOwner {
        isFrozen[account] = false;
    }
}