/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
abstract contract Ownable is Context {
    address private _owner;

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20 Airdrop dapp smart contract
 */
contract Airdrop is Ownable {
    using SafeMath for uint;
    IERC20 public token;
    uint256 public lockDuration = 12 days;
    mapping(address => mapping(uint256 => uint256)) public lastClaimedTime;

    constructor() {
            token = IERC20(0x045B5a77Da935B1B79Aa114265dA30B590787587);
        } 

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    /**
    * @dev doAirdrop is the main method for distribution
    * @param _owner address addresses to airdrop
    */
    function doAirdrop(uint256 [] calldata tokenIds, uint256 [] calldata startTimestamps, address _owner) external {
        
        require(_owner == msg.sender, "this is not your NFT owner!");
        require(tokenIds.length == startTimestamps.length, "defferent the length of tokenId and timestamp");

        uint256 amount = 0;
        for(uint256 i = 0; i < tokenIds.length; i++){
            uint256 timeDiff = 0;
            if(lastClaimedTime[msg.sender][tokenIds[i]] != 0){ // the case of not initial claim
                timeDiff = block.timestamp.sub(lastClaimedTime[msg.sender][tokenIds[i]]);
                if(timeDiff >= 1 days){
                    amount += timeDiff.div(1 days) * 7;
                    lastClaimedTime[msg.sender][tokenIds[i]] = block.timestamp;
                }
            } else { // the case of initial claim
                timeDiff = block.timestamp.sub(startTimestamps[i]);
                if(timeDiff > lockDuration){
                    timeDiff = timeDiff.sub(lockDuration);
                    amount += timeDiff.div(1 days) * 7;
                    lastClaimedTime[msg.sender][tokenIds[i]] = block.timestamp;
                }
            }
        }

        require(amount > 0, "not enough amount");
        require(token.balanceOf(address(this)) >= amount, "not enough balance");      
        token.transfer(msg.sender, amount);

    }

    function getAmount(uint256 [] calldata tokenIds, uint256 [] calldata startTimestamps) external view returns(uint256) {

        uint256 amount = 0;

        for(uint256 i = 0; i < tokenIds.length; i++){
            uint256 timeDiff = 0;
            if(lastClaimedTime[msg.sender][tokenIds[i]] != 0){ // the case of not initial claim
                timeDiff = block.timestamp.sub(lastClaimedTime[msg.sender][tokenIds[i]]);
                if(timeDiff >= 1 days)
                    amount += timeDiff.div(1 days) * 7;

            } else { // the case of initial claim
                timeDiff = block.timestamp.sub(startTimestamps[i]);
                if(timeDiff > lockDuration){
                    timeDiff = timeDiff.sub(lockDuration);
                    amount += timeDiff.div(1 days) * 7;
                }
            }
        }

        return amount;
    }

    function getLastClaimedTime(address user, uint256 tokenId) external view returns(uint256) {
        return lastClaimedTime[user][tokenId];
    }


}