// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interfaces/IERC20.sol";
import "contracts/interfaces/OZT_Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/upgradeability/CustomOwnable.sol";
import "contracts/libraries/UserLibrary.sol";
import "contracts/libraries/InvestmentLibrary.sol";
import "contracts/libraries/TransferHelper.sol";



contract OZV0 is  CustomOwnable, ReentrancyGuard{
  using UserLibrary for UserLibrary.User;
  using InvestmentLibrary for InvestmentLibrary.Slot;
  IERC20 paymentToken;
  OZT_Interface OZT;
  
  
  uint8[] private reservedSlots;
  uint16[] private slotLimit;
  uint16  maxTokenPrice;
  uint32 DaysInSeconds;
  uint32  public currentPublicSlot;
  uint64 public currentId;
  address public rootNode;
  address ozOperations;
  address OZTokenAddress;
  bool internal _initialized;
  

  mapping(address => UserLibrary.User) public users;
  mapping(address =>bool) public tokenIsRegistered;
  mapping(uint32 => InvestmentLibrary.Slot)public investment; 
  mapping(uint=>address) public idToAddress;
  mapping(address=>uint32)public addressToSlot ;

  event Registration(address indexed userAddress, address indexed referrerAddress, uint256 userId, uint256 referrerId,uint time);
  event Slotpurchased(address indexed userAddress, address indexed referrerAddress,uint tokens,uint32 purchaseSlot,uint time);
  event Invest(address indexed userAddress, uint tokens,uint32 purchaseSlot,uint time);

  // 0 - Ecozone slot
  // 1 - Core slot
  // 2 - ArchitectsSlot 
  // 3 - Influencers slot
 
  function initialize(address _root,address ozTokenAddress,address _ozOperations) external {
    require(!_initialized, 'OZV0: INVALID');
    _initialized = true;
    rootNode = _root;
    currentId = 1;
    currentPublicSlot = 890;
    DaysInSeconds = 1; 
    slotLimit = [1,8,80,800];
    reservedSlots = [0,0,0,0];
    OZT = OZT_Interface(ozTokenAddress);
    OZTokenAddress = ozTokenAddress;
    ozOperations = _ozOperations; 
    maxTokenPrice = 3500;
    saveDetailsOfUser(address(0),_root);
  }
  

  modifier onlyOwnerAccess() {
    require(msg.sender == rootNode,"OZV0: Only owner has the access");
    _;
  }


  function register(address _referrer,address user) public onlyOwnerAccess nonReentrant {
    require(!users[user].exists(),"OZV0:User already exists");
    require(users[_referrer].exists(),"OZV0:Referrer does not exists");
    saveDetailsOfUser(_referrer, user);
  }

  function saveDetailsOfUser (address _referrer,address user) private{
    users[user].id = currentId;
    users[user].referrer = _referrer;
    users[user].registrationTime = block.timestamp;
    idToAddress[currentId] = user;
    emit Registration(user,_referrer,currentId,users[_referrer].id,users[user].registrationTime);
    currentId++;
  }

  function addToken(address tokenAddress) public onlyOwnerAccess{
   // Sanity check
    require(!(tokenIsRegistered[tokenAddress]),"OZV0:Token already exists");
    tokenIsRegistered[tokenAddress]= true;
  }
  
  function slotDetails(address user,uint32 slot,uint price) private{
    addressToSlot[user]= slot;
    investment[slot].time = block.timestamp;
    investment[slot].slotPrice = price;
  }
  
  function _currentTokenPrice(uint32 slotNumber) private pure returns(uint price){
    return (8 + (slotNumber-1)*8);
  }

   function currentTokenPrice() public view returns(uint price){
    return _currentTokenPrice(currentPublicSlot);
  }



  function slotReservedByAdmin(address user,uint8 code) public onlyOwnerAccess nonReentrant {
    require((code>=0&&code<=3),"OZV0:Invalid allocation");
    require(users[user].exists(),"OZV0: User not registered");
    require((reservedSlots[code] < slotLimit[code]),"OZV0:Slot already purchased");
    require(isSlotPurchased(user),"OZV0: User can only buy slot once");
    reservedSlots[code]++;
    uint16 slot;
    for(uint8 i;i< code;i++){
      slot += slotLimit[i];
    }
    slot += reservedSlots[code];
    slotDetails(user,slot,_currentTokenPrice(slot));
  }

  function reserveSlot(uint256 value,address tokenAddress) public nonReentrant {
    require(users[msg.sender].exists(),"OZV0: User not registered");
    require((tokenIsRegistered[tokenAddress]),"OZV0:Token is not  registered");
    require(isSlotPurchased(msg.sender),"OZV0: User can only buy slot once");
    paymentToken = IERC20(tokenAddress);
    uint paymentTokenDecimals = 10** paymentToken.decimals();
    require((value >= 100*paymentTokenDecimals && value <=maxTokenPrice*paymentTokenDecimals),"OZV0: Invalid investment");
    TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), value);
    uint ozOperationsamount = value/5;
    uint referralAmount;
    if(value < 300*paymentTokenDecimals){
      referralAmount = value/10;
    } else {
     referralAmount = 30*paymentTokenDecimals;
    }
    paymentToken.transfer(users[msg.sender].referrer,referralAmount);
    paymentToken.transfer(ozOperations,ozOperationsamount-referralAmount);
    uint currentPrice = _currentTokenPrice(currentPublicSlot);
    slotDetails(msg.sender,currentPublicSlot,currentPrice);
    investment[currentPublicSlot].tokens = (value*1000*10**(OZT.decimals()))/(currentPrice*paymentTokenDecimals);
    OZT.mint(address(this),investment[currentPublicSlot].tokens);
    emit Slotpurchased(msg.sender, users[msg.sender].referrer,investment[currentPublicSlot].tokens,currentPublicSlot,block.timestamp);
    currentPublicSlot++;
  }

  function isSlotPurchased(address user)private view returns(bool){
    return addressToSlot[user]== 0;
  }

  function invest(uint256 value,address tokenAddress) public nonReentrant {
    require(value>0,"OZV0: Insufficient investment");
    require(users[msg.sender].exists(),"OZV0: User not registered");
    require(!(isSlotPurchased(msg.sender)),"OZV0: Slot not reserved yet");
    paymentToken = IERC20(tokenAddress);
    uint paymentTokenDecimals = 10** paymentToken.decimals();
    uint oldPrice = investment[addressToSlot[msg.sender]].slotPrice;
    require((((investment[addressToSlot[msg.sender]].tokens*oldPrice*paymentTokenDecimals)/(1000*10**OZT.decimals())) + (value) <= maxTokenPrice*paymentTokenDecimals),"OZV0: Invalid investment");
    TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), value);
    uint _tokens = (value*1000*10**(OZT.decimals()))/(oldPrice*paymentTokenDecimals);
    investment[addressToSlot[msg.sender]].tokens += _tokens ;
    OZT.mint(address(this),_tokens);
    emit Invest(msg.sender, _tokens,addressToSlot[msg.sender],block.timestamp);
  } 

  function burnTokens(uint256 value) public onlyOwnerAccess {
    OZT.burn(value);
  } 

  function calculateDrip (address user) private  view  returns (uint) {
    uint daysOver;
    uint dailyIncome;
    uint drip;
    daysOver = (block.timestamp - (investment[addressToSlot[user]].time))/DaysInSeconds;
    if(daysOver > 365){
      dailyIncome = (investment[addressToSlot[user]].tokens)/(1460);
      if(daysOver<=1825){
        drip = dailyIncome*(daysOver-365);
      }else{
        drip = dailyIncome*(1460);
      }
      return drip;
    }else{
      return 0;
    }
  }

  function dripWithdrawal () public  nonReentrant {
    uint drip = _dripwithdrawal(msg.sender);
    OZT.transfer(msg.sender,drip); 
  }

  function _dripwithdrawal(address user) private returns(uint dripToTransfer) {
    require(!(isSlotPurchased(msg.sender)),"OZV0: Slot not purchased yet");
    uint drip = calculateDrip(user);
    drip = drip-(investment[addressToSlot[user]].totalTokensWithdrawan);
    require(drip > 0 , "OZV0: Drip not generated yet");
    if(drip > OZT.balanceOf(address(this))){
      drip = OZT.balanceOf(address(this));
    }
    investment[addressToSlot[user]].totalTokensWithdrawan += drip; 
    return drip;
  }

  function sellToken (address[]  memory tokenAddresses,uint [] memory numberOfTokens,uint value) public nonReentrant {
    require(users[msg.sender].exists(),"OZV0: User not registered");
    uint totalTokensInDollars;
    if(value==0){
      value = _dripwithdrawal(msg.sender);
    }else{
      require(OZT.balanceOf(msg.sender)>= value,"OZV0: Insufficient tokens");
      TransferHelper.safeTransferFrom(OZTokenAddress, msg.sender, address(this), value);
    }
    uint dollars = (value*_currentTokenPrice(currentPublicSlot)*72)/1000000;
    for(uint i=0;i<=tokenAddresses.length-1;i++){
      paymentToken = IERC20(tokenAddresses[i]);
      require(paymentToken.balanceOf(address(this))>= numberOfTokens[i],"OZV0: Insufficient tokens");
      paymentToken.transfer(msg.sender, numberOfTokens[i]);
      totalTokensInDollars += paymentToken.decimals()* numberOfTokens[i];
    }
    require(dollars == totalTokensInDollars,"OZV0: Invalid input parameters");
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

    //
    //function symbol() external returns (string memory symbols);

    function decimals() external returns (uint  decimal);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
 
interface OZT_Interface {
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

    //
    //function symbol() external returns (string memory symbols);

    function decimals() external returns (uint  decimal);


    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title CustomOwnable
 * @dev This contract has the owner address providing basic authorization control
 */
contract CustomOwnable {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    // Owner of the contract
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner(), "CustomOwnable: FORBIDDEN");
        _;
    }

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "CustomOwnable: FORBIDDEN");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


library UserLibrary {
    struct User {
        uint id;
        uint registrationTime;
        address referrer;
       
    }

    function exists(User storage self) internal view returns (bool) {
        return self.registrationTime > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library InvestmentLibrary {
    
  struct Slot {
    uint time;
    uint slotPrice;
    uint tokens;
    uint totalTokensWithdrawan;
  } 
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

