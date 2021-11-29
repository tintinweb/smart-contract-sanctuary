// SPDX-License-Identifier: MIT
// pragma solidity ^0.5.0;
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthCoupon is ReentrancyGuard {

    /// @title EthCoupon
    /// @author Justin Chan

    /**
    / @notice EthCoupon is a smart contract that allow people to hand out free Ethereum to other Ethereum users that only can be spend in specific Ethereum addresses 
    like how shopping coupons work. Shopping coupon works by  giving people coupons that allow them to spend a specific amount of money for free at only 
    the outlets at specific stores only. Thus, this smart contract is bringing the concept of shopping coupons to 
    the Ethereum blockchain whereby account holders can redeem free Ethereum to give to addresses that are specified by the coupon author.
    
    For example: If the account gives out 5 Ethereum that only can be given to address 0x71C7656EC7ab88b098defB751B7401B5f6d8976F, 
    the person who redeems the free Ethereum cannot give it to address 0x81C7656EC7ab88b098defB751B7401B5f6d8976F 
    but instead only can give to account 0x71C7656EC7ab88b098defB751B7401B5f6d8976F. 
    Account holders that have the free Ethereum can top up the redeemed amount by adding more funds from their existing Ethereum balance. 
    Through this system, it is hoped that third party organisations and account holders can hold promotions to encourage adoption of early stage DAPPS(decentralised applications) 
    whether financial in nature or not by giving out free Ethereum for people to spend at the specific DAPPS that the organisation or account holder is currently sponsoring.
    
    Currently, the bottleneck of DAPPS adoption is the lack of financial rebates for early adopters to try out the DAPP before it becomes popular 
    unlike in the real world where financial rebates and discount are given to people to encourage purchase of items. 
    For example: I can lock up 1000 Ethereum to allow people to spend 0.05 Ethereum each at the at ethereum address 0x81C7656EC7ab88b098defB751B7401B5f6d8976F. 
    Thus, I provide opportunity for 20000 people for spend free 0.05 Ethereum each at Ethereum address 0x81C7656EC7ab88b098defB751B7401B5f6d8976F. 
    Besides redeem amount, the valid date range, minimum transaction amount and maximum transaction amount of the transaction can be made by the promotion organisers.  
    When the promotional fund balance is low, the promotion sponsor can top up more funds for the promotion using the smart contract.
    
    Stakeholders in the system

    1. Sponsor(Account holder that initiates the promotion and sponsors the event)
    2. Account holder(Redeems promotional amount and spends the free Ethereum at the selected address)

    Use cases:

    1. Mint coupon(Sponsor)
    2. Collect leftover Ether(Sponsor)
    3. Top up Promotion fund(Sponsor)
    4. Redeem coupon(User)
    5. Execute transaction(User)
    6. Check promotion balance(Sponsor)
    7. Check coupon details(public)
    8. Check coupon balance(User)

    // Assumptions:

    1. Sponsor cannot change the details of the promotion after it is created.
    2. At present, only ether sending to another account is supported. No smart contract specific function calls are supported but it will be a future function.
    */

    // Data Storage Layout
    
    // Struct to hold promotion details of a promotion code
    
    struct promotion{
        address sponsorAddress;
        uint256 totalEth;
        uint256 amtPerAddress;
        address targetAddress;
        uint256 startDate;
        uint256 endDate;
        uint256 minRedeemAmt;
        uint256 maxRedeemAmt;
    }
    
    // Map of hash of promotion code to the promotion details struct
   mapping(bytes32=>promotion) private PromotionDetails;
   
    // Struct to hold coupon details of each user for a promotion code
    struct couponDetails{
        bytes32 promotionCode;
        address userAddress;
        uint256 existingBalance;
    }
    
    // Map of coupon details to hash of user account and promotion code
    mapping(bytes32=>couponDetails) private CouponList;
    
    // Map of promotion code to unspent balance. When the coupon holder spents the coupon amount, the balance is deducted from the mapping
    mapping(bytes32=>uint256) private UnspentBalance;
    
    // Total funds remaining in the contract
    uint256 private totalFunds;
    
    // List of events
    event Promotion(bytes32 indexed couponHash,address indexed sponsorAddress,address indexed targetAddress,string couponCode,uint256 totalEth,uint256 amtPerAddress,uint256 startDate,uint256 endDate,uint256 minRedeemAmt,uint256 maxRedeemAmt,uint256 dateCreated);
    
    event TopUp(string indexed couponHash, uint256 amount, uint256 date);
    
    event Redeem(bytes32 indexed couponHash, address indexed user, bytes32 RedeemID,uint256 date);

    event Transaction(bytes32 indexed RedeemID, uint256 couponAmt, uint256 walletAmt);

    event CollectLeftOver(bytes32 indexed couponHash, uint256 amount, uint256 date);
    
    // List of modifiers
    
    // Check if a promotion is currently valid
    modifier IsValidDate(string memory promotionCode){
        promotion storage promo = PromotionDetails[keccak256(abi.encodePacked(promotionCode))];
        require((promo.startDate <= block.timestamp) && (promo.endDate >= block.timestamp), "Promotion is not currently valid");
        _;
    }
    
    // Check if caller address is the sponsor address of the promotion couponCode
    modifier IsSponsorAddress(string memory promotionCode){
        promotion storage promo = PromotionDetails[keccak256(abi.encodePacked(promotionCode))];
        require(msg.sender == promo.sponsorAddress, "Caller Address is not the sponsor address of the promotion code");
        _;
    }
    
    // Check if caller address has redeemed the promotion code
    modifier IsValidHolder(string memory promotionCode){
        couponDetails storage coupon = CouponList[keccak256(abi.encodePacked(promotionCode,msg.sender))];
        require(coupon.userAddress == msg.sender, "Caller Address has not redeemed the promotion code");
        _;
    }
    
   constructor() {
   }
   
   /// @notice The mint function creates a new promotion code that accepts parameter name, total Eth per address, target address, start date, end date, minimum redeem amount and maximum redeem amount
   /// @dev The promotion code must not be used by any promotion before
   function mint(string memory promoCode, uint256 totalPerAddress, address targetAddress, uint256 startDate, uint256 endDate, uint256 minRedeemAmt, uint256 maxRedeemAmt) public payable{
       
       bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
       // Check if redeem code exists
       require(PromotionDetails[hashPromo].sponsorAddress == address(0x0),"Promotion code already exists");
       // Check if start date is earlier than end date
       require(startDate < endDate,"Start date must be earlier than end date");
       // Check if totalEth is greather than 0
       require(msg.value > 0,"Total Eth must be greater than 0");
       // Check if Eth per address is greather than 0
       require(totalPerAddress > 0,"Eth per address must be greater than 0");
       // Check if Eth per address is lesser than or equal to total Eth
       require(totalPerAddress <= msg.value,"Eth per address must be lesser than or equal to total Eth amount");
        // Check if sponsor address is similar to target adaddress
       require(targetAddress != msg.sender,"Sponsor address cannot be the same as target address");
       // Check if start date is present
       require(startDate > 0,"Start date is not present");
       // Check if end date is present
       require(endDate > 0,"End date is not present");
       // Check if minimum redeem amount is present
       require(minRedeemAmt > 0,"Minimum redeem amount is not present");
       // Check if maximum redeem amount is present
       require(maxRedeemAmt > 0,"Maximum redeem amount is not present");
       // Check if minimum redeem amount is lesser than the maximum redeem amount
       require(maxRedeemAmt > minRedeemAmt,"Minimum redeem amount must be greather than maximum redeem amount");
       
       // Create new promotion
       PromotionDetails[hashPromo].sponsorAddress = msg.sender;
       PromotionDetails[hashPromo].totalEth = msg.value;
       PromotionDetails[hashPromo].amtPerAddress = totalPerAddress;
       PromotionDetails[hashPromo].targetAddress = targetAddress;
       PromotionDetails[hashPromo].startDate = startDate;
       PromotionDetails[hashPromo].endDate = endDate;
       PromotionDetails[hashPromo].minRedeemAmt = minRedeemAmt;
       PromotionDetails[hashPromo].maxRedeemAmt = maxRedeemAmt;
       UnspentBalance[hashPromo] = msg.value;
       totalFunds = totalFunds + msg.value;
       emit Promotion(hashPromo,msg.sender,targetAddress,promoCode,msg.value,totalPerAddress,startDate,endDate,minRedeemAmt,maxRedeemAmt,block.timestamp);
   }  
   
   /// @notice The collectLeftoverEther function enables the promotion sponsor to collect unspent Ether after the promotion ends.
   /// @dev Only the promotion sponsor can call this function
   function collectLeftoverEther(string memory promoCode) public IsSponsorAddress(promoCode) nonReentrant{
       bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
       // Check if promotion date is expired already
       require(block.timestamp > PromotionDetails[hashPromo].endDate,"To collect leftover Ether, the promotion must expire first");
       // Return leftover ether to the sponsor
       address payable sponsor = payable(PromotionDetails[hashPromo].sponsorAddress);
       uint256 returnAmt = UnspentBalance[hashPromo];
       // Reset all values first to avoid re-entrancy attacks
       UnspentBalance[hashPromo] = 0;
       totalFunds = totalFunds - returnAmt;
       PromotionDetails[hashPromo].totalEth = 0;
       (bool sent,) = sponsor.call{value:returnAmt}("");
       require(sent, "Failed to send Ether");
       emit CollectLeftOver(hashPromo, returnAmt, block.timestamp);
   }
   
   /// @notice The topUp function enables the promotion sponsor to top up the promotion amount for a promotion code as long as the promotion is valid.
   /// @dev Only the promotion sponsor can call this function
   function topUp(string memory promoCode) public payable IsSponsorAddress(promoCode) IsValidDate(promoCode){
       require(msg.value > 0,"Top up value must be greater than 0");
       bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
       PromotionDetails[hashPromo].totalEth = PromotionDetails[hashPromo].totalEth + msg.value;
       UnspentBalance[hashPromo] = UnspentBalance[hashPromo] + msg.value;
       totalFunds = totalFunds + msg.value;
       emit TopUp(promoCode, msg.value, block.timestamp);
   }
   
   /// @notice The checkPromotionalBalance function enables the promotion sponsor to check the leftOver and unspentEther of the promotion.
   /// @dev Only the promotion sponsor can call this function
   function checkPromotionalBalance(string memory promoCode) public view IsSponsorAddress(promoCode) returns(uint256 leftOver,uint256 unspentEther) {
      bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
      leftOver = PromotionDetails[hashPromo].totalEth;
      unspentEther = UnspentBalance[hashPromo];
   }
   
   /// @notice The redeem function enables an account holder to redeem a promotion coupon based on the promotion code as long as the promotion is valid.
   /// @dev Sponsor and target address cannot call the redeem function to redeem the promotion code that is assigned.
   function redeem(string memory promoCode) public IsValidDate(promoCode){
       bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
        // sponsor cannot redeem coupon
       require(PromotionDetails[hashPromo].sponsorAddress != msg.sender,"Sponsor cannot redeem coupon");
       // target address cannot redeem coupon
       require(PromotionDetails[hashPromo].targetAddress != msg.sender,"Target address cannot redeem coupon");
        // Check if the coupon has enough to allocated the amount to coupon
       require(PromotionDetails[hashPromo].totalEth >= PromotionDetails[hashPromo].amtPerAddress, "Promotion balance insufficient to allocate to coupon");
       // Check if the user has redemeed the promotion code yet
       bytes32 promoUser = keccak256(abi.encodePacked(promoCode,msg.sender));
       require(CouponList[promoUser].userAddress != msg.sender,"User has redemeed the promotion code already");
       // Create new couponDetails object and allocate eth from the promotion's struct totalEth. The promotion's struct new totalEth is totalEth - amtPerAddress
       CouponList[promoUser].promotionCode = keccak256(abi.encodePacked(promoCode));
       CouponList[promoUser].userAddress = msg.sender;
       CouponList[promoUser].existingBalance = PromotionDetails[hashPromo].amtPerAddress;
       // update promotion new Eth balance after allocating it to the coupon redeemer.
       PromotionDetails[hashPromo].totalEth = PromotionDetails[hashPromo].totalEth - PromotionDetails[hashPromo].amtPerAddress;
       emit Redeem(hashPromo, msg.sender, promoUser,block.timestamp);
       
   }
   
   /// @notice The transaction function enables an account holder to spend a coupon's value for a redeemed coupon
   /// @dev Only the coupon holder can call this function
   function transaction(string memory promoCode,uint256 couponAmt) public payable IsValidDate(promoCode) IsValidHolder(promoCode) nonReentrant{
      bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
       // check if amount from wallet is a non negative number
      require(msg.value >= 0,"Amount sent must be a non negative number");
      // check if amount from coupon is greater than 0
      require(couponAmt > 0,"Coupon transaction amount must be greater than 0");
      bytes32 promoUser = keccak256(abi.encodePacked(promoCode,msg.sender));
      // check if coupon transaction amount is greater than or equal to the coupon's balance
      require(CouponList[promoUser].existingBalance >= couponAmt, "Coupon amount is greater than the balance");
      // check if coupon transaction amount is less than the minRedeemAmt
      require(PromotionDetails[hashPromo].minRedeemAmt <= couponAmt, "Coupon transaction amount is lesser than the minimum amount");
      // check if coupon transaction amount is greater than the maxRedeemAmt
      require(PromotionDetails[hashPromo].maxRedeemAmt >= couponAmt, "Coupon transaction amount is greater than the maximum amount");
      // update couponDetails struct's balance, UnspentBalance balance and totalFunds first to avoid re-entrancy attacks
      // These balances are updated by deducting the coupon amount from them
      CouponList[promoUser].existingBalance = CouponList[promoUser].existingBalance - couponAmt;
      UnspentBalance[hashPromo] = UnspentBalance[hashPromo] - couponAmt;
      totalFunds = totalFunds - couponAmt;
      // the amount sent to the recipient is couponAmt + wallet amount 
      address payable recipient = payable(PromotionDetails[hashPromo].targetAddress);
      (bool sent,) = recipient.call{value:couponAmt + msg.value}("");
      require(sent, "Failed to send Ether");
      emit Transaction(hashPromo, couponAmt, msg.value);
   }
   
    /// @notice The checkCouponBalance function enables an account holder to check a coupon's balance
   /// @dev Only the coupon holder can call this function
   function checkCouponBalance(string memory promoCode) public view IsValidHolder(promoCode) returns(uint256 amt) {
        bytes32 promoUser = keccak256(abi.encodePacked(promoCode,msg.sender));
        amt = CouponList[promoUser].existingBalance;
   }
   
   /// @notice The checkPromotionDetails function enables anyone to check the promotion details of a promotion
   function checkPromotionDetails(string memory promoCode) public view returns(uint256 totalPerAddress, bool isPromoValid , address targetAddress, uint256 startDate, uint256 endDate, uint256 minRedeemAmt, uint256 maxRedeemAmt){
       bytes32 hashPromo = keccak256(abi.encodePacked(promoCode));
       totalPerAddress = PromotionDetails[hashPromo].amtPerAddress;
       targetAddress = PromotionDetails[hashPromo].targetAddress;
       startDate = PromotionDetails[hashPromo].startDate;
       endDate = PromotionDetails[hashPromo].endDate;
       minRedeemAmt = PromotionDetails[hashPromo].minRedeemAmt;
       maxRedeemAmt = PromotionDetails[hashPromo].maxRedeemAmt;
       // returns promotion status by checking if there is still redemmable eth in the coupon
       if(PromotionDetails[hashPromo].totalEth >= totalPerAddress){
           isPromoValid = true;
       }
       else{
           isPromoValid = false;
       }
   }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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