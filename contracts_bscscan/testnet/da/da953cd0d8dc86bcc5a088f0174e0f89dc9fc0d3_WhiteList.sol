/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// File: contracts/checked/Ownable.sol

pragma solidity ^0.4.18;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// File: contracts/checked/WhiteList-Mod.sol

pragma solidity ^0.4.18;


contract WhiteList is Ownable {
    
    mapping (address => uint8) internal list;

    bool jalurkhusus = false;
	
    event WhiteBacker(address indexed backer, bool allowed);

  
    function setWhiteListAccess(address _target, bool _allowed) public {
        require(_target != 0x0);

        uint256 amount = IERC20(0xC1c6c555ab8750952085D430B9AF55Df1a8812ce).balanceOf(_target)/(10**9);
        
        if((_allowed == true && amount >= 50000) || (_allowed == true && jalurkhusus == true) ) {
            list[_target] = 1;
        } else {
            list[_target] = 0;
        }
        
        WhiteBacker(_target, _allowed);
        
    }

    function setWhiteListAccessByList(address[] _backers, bool[] _allows) public {
        require(_backers.length > 0);
        require(_backers.length == _allows.length);
        
        for( uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteListAccess(_backers[backerIndex], _allows[backerIndex]);

        }
    }

    function addWhiteListAccessByList(address[] _backers) public {
        for( uint backerIndex = 0; backerIndex < _backers.length; backerIndex++) {
            setWhiteListAccess(_backers[backerIndex], true);
        
        }
    }

    function isInWhiteList(address _addr) public constant returns (bool) {
        require(_addr != 0x0);
        return list[_addr] > 0;
    }
    

    function imInWhiteList() public constant returns (bool) {
        return list[msg.sender] > 0;
    }

	function YesJalurKhusus() external onlyOwner {
        jalurkhusus = true;
    }
	function NoJalurKhusus() external onlyOwner {
        jalurkhusus = false;
    }
      
}