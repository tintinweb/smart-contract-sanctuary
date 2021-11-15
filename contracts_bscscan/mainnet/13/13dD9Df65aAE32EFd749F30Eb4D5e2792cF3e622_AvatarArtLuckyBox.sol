// SPDX-License-Identifier: MIT

import "./interfaces/IERC20.sol";
import "./core/Ownable.sol";

pragma solidity ^0.8.0;

contract AvatarArtLuckyBox is Ownable{
    //BNU token
    IERC20 public bnuToken;
    
    //BNU amount is used to buy a ticket
    uint256 public ticketPrice;
    
    //Mapping the account address and their reward quantity
    mapping(address => uint256) public rewards;
    
    //Assign `ticketPrice` and `bnuToken`
    constructor(){
        ticketPrice = 10000000000000000000;     //10 BNU for a ticket
        bnuToken = IERC20(0x4954e0062E0A7668A2FE3df924cD20E6440a7b77);
    }
    
    /**
     * @dev User claims all his reward
     */ 
    function claimReward() public returns(bool){
        uint256 rewardQuantity = rewards[_msgSender()];
        require(rewardQuantity > 0, "No thing to claim");
        
        bnuToken.transfer(_msgSender(), rewardQuantity);
        
        rewards[_msgSender()] -= rewardQuantity;
        return true;
    }
    
    /**
     * @dev Owner add `rewardQuantity` for `account`
     */ 
    function addReward(address account, uint256 rewardQuantity) public onlyOwner returns(bool){
        require(account != address(0), "Zero address");
        require(rewardQuantity > 0, "No thing to add");
        
        rewards[account] += rewardQuantity;
        return true;
    }
    
    /**
     * @dev User use BNU to buy the ticket to join luckybox
     */ 
    function buyTicket() public returns(bool){
        if(ticketPrice > 0)
            bnuToken.transferFrom(_msgSender(), _owner, ticketPrice);
            
        emit TicketBought(_msgSender());
        return true;
    }
    
     /**
     * @dev Set BNU token address
     */ 
    function setBnuToken(address newAddress) public onlyOwner returns(bool){
        require(newAddress != address(0), "Zero address");
        bnuToken = IERC20(newAddress);
        return true;
    }
    
    /**
     * @dev Set ticket price by BNU quantity
     */ 
    function setTicketPrice(uint256 ticketPrice_) public onlyOwner returns(bool){
        ticketPrice = ticketPrice_;
        return true;
    }
    
    /**
     * @dev Withdraw all specific token by `tokenAddress` from contract
     */ 
    function withdrawToken(address tokenAddress) public onlyOwner returns(bool){
        require(tokenAddress != address(0), "Zero address");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_msgSender(), token.balanceOf(address(this)));
        return true;
    }
    
    //Event for broadcast when an user buy ticket
    event TicketBought(address account);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    function _now() internal view returns(uint){
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Ownable is Context {
    
    modifier onlyOwner{
        require(_msgSender() == _owner, "Forbidden");
        _;
    }
    
    address internal _owner;
    address internal _newRequestingOwner;
    
    constructor(){
        _owner = _msgSender();
    }
    
    function getOwner() external virtual view returns(address){
        return _owner;
    }
    
    function requestChangeOwner(address newOwner) external  onlyOwner{
        require(_owner != newOwner, "New owner is current owner");
        _newRequestingOwner = newOwner;
    }
    
    function approveToBeOwner() external{
        require(_newRequestingOwner != address(0), "Zero address");
        require(_msgSender() == _newRequestingOwner, "Forbidden");
        
        address oldOwner = _owner;
        _owner = _newRequestingOwner;
        
        emit OwnerChanged(oldOwner, _owner);
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

