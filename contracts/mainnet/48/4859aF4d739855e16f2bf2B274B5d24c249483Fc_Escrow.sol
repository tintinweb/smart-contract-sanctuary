// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is Ownable{
    address public constant charity = 0xb5bc62c665c13590188477dfD83F33631C1Da0ba;
    IERC20 public immutable shelterToken;

    uint public timeLockBuffer;
    uint public timeLock;
    uint private boutiesIndex = 0;

    struct bounty{
        uint amount;
        uint timestamp;
        address sponsor;
    }

    bounty[] bounties;

    constructor(address _shelter){
        shelterToken = IERC20(_shelter);
    }

    event NewBounty(uint);

    /// @dev create a new charity bounty
    function newBounty(uint _amount)external{
        require(_amount != 0, "cannot set a bounty of 0");
        shelterToken.transferFrom(msg.sender, address(this), _amount);

        bounties.push(
            bounty({
                amount: _amount,
                timestamp: block.timestamp,
                sponsor: msg.sender
            })
        );
        emit NewBounty(bounties.length - 1);
    }

    /// @dev closeBounty callable by a bounty's creator
    function closeBounty(uint _i, address _recipient)external{
        require(bounties[_i].amount != 0, "there is no bounty");
        require(bounties[_i].sponsor == msg.sender, "Must be the sponsor to close");
        uint temp = bounties[_i].amount;
        bounties[_i].amount = 0;
        shelterToken.transfer(_recipient, temp);
    }

    /// @dev owner to change the timelock expiration date on bounties
    function changeTimeLock(uint _timeLock) external onlyOwner{
        //If you are decreasing timelock, then update the buffer
        //Must wait to liquidate until people who are instantly eligible for liquidation becaues of a time lock change
        //have waited long enough to be eligible for a liquidation based on the old time lock.
        if(_timeLock < timeLock){
            timeLockBuffer = block.timestamp + timeLock;
        }
        timeLock = _timeLock;
    }

    /// @dev liquidate all the bounties that are expired
    function liquidate()external{
        require(block.timestamp > timeLockBuffer, "There is a buffer in place due to a recent decrease in the time lock period. You must wait to liquidate");
        uint liquidations = 0;
        //Starting from the oldest non-liquidated bounty loop
        for(uint i = boutiesIndex; i < bounties.length; i++){
            //If bounty expired
            if(block.timestamp + timeLock > bounties[i].timestamp){
                //if outstanding balance still
                if(bounties[i].amount > 0){
                    uint temp = bounties[i].amount;
                    bounties[i].amount = 0;
                    liquidations += temp;
                }
            //Once we get to a non-expired bounty
            }else{
                //update the bounties index and break
                boutiesIndex = i;
                break;
            }
        }
        //send liquidated balance to charity
        shelterToken.transfer(charity, liquidations);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}