//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHyveVaults.sol";


contract HyveLaunchpad is Ownable {

    IHyveVaults public HyveVaultsContract;

    uint256 public tokenPrice = 0;

    uint256[] public availableTiers;

    mapping(uint256 => address[]) public buyers;

    mapping(uint256 => uint256) public allowedTokensForTier;

    mapping(address => mapping(uint256 => uint256)) public userTierBalance;

    mapping(address => mapping(uint256=> VestedTokens)) public vestedTokens;

    struct VestedTokens{
        uint256 vestingStart;
        uint256 amount;
        uint256 claimedAmount;
    }
    
    modifier checkTierWhitelist(uint256 tier){
        require(HyveVaultsContract.stakedAmounts(msg.sender,tier) > 0, "HYVE_LAUNCHPAD:USER_NOT_WHITELISTED");
        _;
    }

    modifier checkTokenAllowance(uint256 tier){
        uint256 amount = getTokenAmountFromETH(msg.value);        
        require(allowedTokensForTier[tier] >= userTierBalance[msg.sender][tier] + amount,"HYVE_LAUNCHPAD:AMOUNT_TOO_HIGH");
        _;
    }

    constructor(address HyveVaultsAddress){
        HyveVaultsContract = IHyveVaults(HyveVaultsAddress);        
    }


    function buyTokens(uint256 tier) external checkTierWhitelist(tier) checkTokenAllowance(tier) payable{
        
        uint256 amount = getTokenAmountFromETH(msg.value);
        userTierBalance[msg.sender][tier]+=amount;

        
        vestedTokens[msg.sender][tier].amount += 2 * amount / 3;

        if(vestedTokens[msg.sender][tier].vestingStart == 0){
            vestedTokens[msg.sender][tier].vestingStart = block.timestamp;
            buyers[tier].push(msg.sender);
        }

        //YoucloutContract.transfer(msg.sender, amount / 3);
    }    

    // function claim(uint256 tier) external {
    //     require(vestedTokens[msg.sender][tier].amount > 0 , "HYVE_VAULTS:TOKENS_UNAVAILABLE");
    //     require((vestedTokens[msg.sender][tier].vestingStart + 30 days) <= block.timestamp , "HYVE_VAULTS:VESTING_IN_PROGRESS");
        
    //     uint256 availableTokens = getAvailableClaim(tier);
        
    //     require(availableTokens > 0,"HYVE_VAULTS:TOKENS_ALREADY_CLAIMED");

    //     vestedTokens[msg.sender][tier].claimedAmount += availableTokens;

    //     YoucloutContract.transfer(msg.sender, availableTokens);

    // }

    function getAvailableClaim(uint256 tier) public view returns(uint256){

        uint256 claimNo =  ((block.timestamp - vestedTokens[msg.sender][tier].vestingStart) / 30 days);
        uint256 maxClaim=0;
        if(claimNo == 1){
            maxClaim = vestedTokens[msg.sender][tier].amount / 2;
        }else if(claimNo >= 2){
            maxClaim = vestedTokens[msg.sender][tier].amount;
        }

        return maxClaim - vestedTokens[msg.sender][tier].claimedAmount;

    }

    function setTokenPrice(uint256 price) external onlyOwner{
        tokenPrice = price;
    }

    function setAllowedTokensForTier(uint256 tier,uint256 amount) external onlyOwner{
            require(tier>0,"HYVE_VAULTS:TIER_0_NOT_ALLOWED");

        if(allowedTokensForTier[tier] > 0 && amount == 0){
            for(uint i=0;i < availableTiers.length; i++){
                if(availableTiers[i]==tier){
                    availableTiers[i]=availableTiers[availableTiers.length-1];
                    availableTiers[availableTiers.length-1]=0;
                }
            }
        } else if(allowedTokensForTier[tier] == 0 && amount > 0){
            availableTiers.push(tier);
        }

        allowedTokensForTier[tier]=amount;
    }

    function getTokenAmountFromETH(uint256 ethAmount) internal view returns(uint256){
        require(tokenPrice >0, "HYVE_VAULTS:SALE_CLOSED");
        return ((ethAmount * 10**18) / tokenPrice);
    }

    function withdrawETH(uint256 amount) external onlyOwner{
        payable(msg.sender).transfer(amount);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IHyveVaults{

    function tierAmounts(uint256 tier) external returns(uint256);

    function stakeTimes(address holder,uint256 tier) external returns(uint256);

    function stakedAmounts(address holder,uint256 tier) external returns(uint256);      
  
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

