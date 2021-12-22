/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

/** 
 *  SourceUnit: /Users/yashgupta/Projects/geddit/smart-contract/contracts/GedditTokenSale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity 0.8.7;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

     function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}




/** 
 *  SourceUnit: /Users/yashgupta/Projects/geddit/smart-contract/contracts/GedditTokenSale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.7;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
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
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

   
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
 *  SourceUnit: /Users/yashgupta/Projects/geddit/smart-contract/contracts/GedditTokenSale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity 0.8.7;

////import "../utils/Context.sol";

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


/** 
 *  SourceUnit: /Users/yashgupta/Projects/geddit/smart-contract/contracts/GedditTokenSale.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.7;

////import "./@openzeppelin/contracts/utils/Context.sol";
////import "./@openzeppelin/contracts/access/Ownable.sol";
////import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GedditTokenSale is Context, Ownable {
    
    event UnLock(address indexed account, uint256 value);

    IERC20 private _token;
    
    address[] private investors;
    uint256[] private investedAmountsBatch;

    // Release time for Batch1, after 6 months(4380 hours) of deployment
    uint256 public timeToReleaseBatch1 = block.timestamp + 4380 hours;
    
    // Release time for Batch2, after 6 months(4380 hours) of Batch 1 
    uint256 public timeToReleaseBatch2 = timeToReleaseBatch1 + 4380 hours;

    // Release time for Batch3, after 6 months(4380 hours) of Batch 2
    uint256 public timeToReleaseBatch3 = timeToReleaseBatch2 + 4380 hours;
    
    // Release time for Batch4, after 6 months(4380 hours) of Batch 3 
    uint256 public timeToReleaseBatch4 = timeToReleaseBatch3 + 4380 hours;

    
    /**
     * @dev Sets the values for gedditToken, investor's accounts and their respective tokens
     * 
     * Batch tokens values array, 
     * we will transfer the 25% of the total investment by the investor, so dividing it by 4.
     * Adding investments details
     */
    constructor(IERC20 gedditToken, address[] memory accounts, uint256[] memory batch) {
        //require(accounts.length == batch.length, "batch Array length is not matching with accounts");
        _token = gedditToken;
        addInvestments(accounts, batch);
    }

    /**
     * @dev use to set investments in contract to distribute later
     * @return boolean
     */
    function addInvestments(address[] memory accounts, uint256[] memory batch) private returns (bool) {
        require(accounts.length == batch.length, "batch Array length is not matching with accounts");
        investors = accounts;
        for (uint256 i = 0; i < batch.length; i++) {
            investedAmountsBatch.push( (batch[i] / 4) * 10 ** 18 ); // 
        }
        return true;
    }
    
    /**
     * @dev use to get the token contract
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @dev use to get the investors list
     * @return investors list
     */
    function getAllInvestors() public view returns( address[] memory ){
        return investors;
    }

    /**
     * @dev use to get the investedAmountsBatch list
     * @return investedAmountsBatch list
     */
    function getBatch() public view returns( uint256[] memory ){
        return investedAmountsBatch;
    }
    
     /**
     * @dev use to get the Investor's Invested tokens
     * @return investedAmountsBatch list
     */
    function getInvestedTokens(address investor) external view returns(uint256){
        require(investor != address(0), "Invalid Investor's address");
        for (uint256 i = 0; i < investors.length; i++) {
            if (investors[i] == investor) {
                return investedAmountsBatch[i] * 4;
            }    
        }
        return 0;
    }

    // function releaseBatch1() public returns(bool){
    //     require(block.timestamp >= timeToReleaseBatch1, "Its going to take some more time to unlock investers batch1 tokens");
    //     return true;
    // }

    // function releaseBatch2() public returns(bool){
    //     require(block.timestamp >= timeToReleaseBatch2, "Its going to take some more time to unlock investers batch2 tokens");
    //     return true;
    // }

    // function releaseBatch3() public returns(bool){
    //     require(block.timestamp >= timeToReleaseBatch3, "Its going to take some more time to unlock investers batch3 tokens");
    //     return true;
    // }

    // function releaseBatch4() public returns(bool){
    //     require(block.timestamp >= timeToReleaseBatch4, "Its going to take some more time to unlock investers batch4 tokens");
    //     return true;
    // }


}