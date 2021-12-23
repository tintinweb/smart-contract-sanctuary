/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the BSC standard as defined in the EIP.
 */
interface IBSC {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

// Adding-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract DMGAirdop is Ownable, ReentrancyGuard {
  struct Claimer {
    address referer;
    uint256 tier1;
    uint256 tier2;
    uint256 tier3;
    uint256 totalRef;
    uint256 claimed;
  }

  IBSC public claimToken;

  address public support;

  uint[] public rewards;
  uint256 public totalclaimers;
  uint256 public _claimTokenRegister = 1000 * 1e18;
  uint256 public _claimTokenTier1 = 500 * 1e18;
  uint256 public _claimTokenTier2 = 300 * 1e18;
  uint256 public _claimTokenTier3 = 100 * 1e18;
  uint256 public totalrewards;
  uint256 public bonusMultiple = 75;

  mapping (address => Claimer) public claimers;
  event Claim(address user, address referer);
  event Reward(address user, uint256 amount);

  constructor(address _claimToken) public {
    rewards.push(_claimTokenTier1);
    rewards.push(_claimTokenTier2);
    rewards.push(_claimTokenTier3);
    support = msg.sender;
    claimToken = IBSC(_claimToken);
  }

  function claim(address referer) external nonReentrant {
    if (claimers[msg.sender].claimed == 0) {
      claimers[msg.sender].claimed = _claimTokenRegister;

      totalclaimers++;
      
      if (claimers[referer].claimed != 0 && referer != msg.sender) {
        address rec = referer;
        claimers[msg.sender].referer = referer;

        for (uint256 i = 0; i < rewards.length; i++) {
          if (claimers[rec].claimed == 0) {
            break;
          }

          if (i == 0) {
            claimers[rec].tier1++;
          }

          if (i == 1) {
            claimers[rec].tier2++;
          }

          if (i == 2) {
            claimers[rec].tier3++;
          }

          if (i == 3) {
            claimers[rec].tier3++;
          }

          rec = claimers[rec].referer;
        }

        rewardReferers(referer);
      }

      require(IBSC(claimToken).transfer(msg.sender, _claimTokenRegister*bonusMultiple), 'Claim token is failed');
      emit Claim(msg.sender, referer);
    }
  }
   // Recover lost bnb and send it to the contract owner
    function recoverLostBNB() public onlyOwner {
         address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }
    // Ensure requested tokens aren't users RUSH tokens
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
         require(_token != address(this), "Cannot recover RUSH tokens");
         IBSC(_token).transfer(msg.sender, amount);
    }

  function rewardReferers(address referer) internal {
    address rec = referer;

    for (uint256 i = 0; i < rewards.length; i++) {
      if (claimers[rec].claimed == 0) {
        break;
      }

      uint256 a = rewards[i]*bonusMultiple;

      claimers[rec].totalRef += a;
      totalrewards += a;

      require(IBSC(claimToken).transfer(rec, a), 'Claim reward token is failed');
      emit Reward(rec, a);

      rec = claimers[rec].referer;
    }
  }

  function balanceOf(address user) public view returns (uint256) {
    return claimers[user].claimed;
  }

  function availabe() public view returns (uint256) {
    return IBSC(claimToken).balanceOf(address(this));
  }
}