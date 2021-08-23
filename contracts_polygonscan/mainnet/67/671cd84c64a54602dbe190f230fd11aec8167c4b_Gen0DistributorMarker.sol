/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT
  pragma solidity 0.8.4;

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
      require(c / a == b, "SafeMath#mul: OVERFLOW");

      return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold

      return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "SafeMath#sub: UNDERFLOW");
      uint256 c = a - b;

      return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath#add: OVERFLOW");

      return c; 
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
      return a % b;
    }

  }

  abstract contract Context {
      function _msgSender() internal view virtual returns (address) {
          return msg.sender;
      }

      function _msgData() internal view virtual returns (bytes calldata) {
          return msg.data;
      }
  }

  /**
   * @dev Contract module which provides a basic access control mechanism, where
   * there is an account (an owner) that can be granted exclusive access to
   * specific functions.
   *
   * This module is used through inheritance. It will make available the modifier
   * `onlyOwner`, which can be applied to your functions to restrict their use to
   * the owner.
   */
  abstract contract Ownable is Context {
      address private _owner;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

      /**
       * @dev Initializes the contract setting the deployer as the initial owner.
       */
      constructor() {
          _setOwner(_msgSender());
      }

      /**
       * @dev Returns the address of the current owner.
       */
      function owner() public view virtual returns (address) {
          return _owner;
      }

      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
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
      function renounceOwnership() public virtual onlyOwner {
          _setOwner(address(0));
      }

      /**
       * @dev Transfers ownership of the contract to a new account (`newOwner`).
       * Can only be called by the current owner.
       */
      function transferOwnership(address newOwner) public virtual onlyOwner {
          require(newOwner != address(0), "Ownable: new owner is the zero address");
          _setOwner(newOwner);
      }

      function _setOwner(address newOwner) private {
          address oldOwner = _owner;
          _owner = newOwner;
          emit OwnershipTransferred(oldOwner, newOwner);
      }
  }

  contract Gen0DistributorMarker is Ownable {
      
      using SafeMath for uint256;
      
      uint256 private claimingFee;
      mapping(address => bool) public claimers;
      event Claimed(address indexed _from);
      
      constructor() 
       {
          claimingFee = 10 * 10 ** 18; //  (Varies by network)
      }
      
        
        function changeClaimingFees(uint256 _claimingFee) onlyOwner public {
            claimingFee = _claimingFee;
        }
      
      function claim() payable public {
            require (msg.value >= claimingFee, "E01");
            require (claimers[msg.sender] == false, "E02");
            claimers[msg.sender] = true;
            emit Claimed(msg.sender);
      }
      
      function getClaimer(address _user) public view returns (bool) {
          return claimers[_user];
      }
      
     function withdrawFees() onlyOwner external {
        require(payable(msg.sender).send(address(this).balance));
    }
  }