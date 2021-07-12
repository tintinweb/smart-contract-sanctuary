/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// File: contracts/SafeMath.sol

pragma solidity ^0.5;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
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
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: contracts/StandardProductPurchase.sol

pragma solidity ^0.5;


contract Owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Invalid Owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract StandardProductPurchase is Owned {
    using SafeMath for uint256;
    
    // Base Seller Fee;
    uint256 baseFeePercent;
    uint256 baseFeeDivisor;
    
    
    /* Referral Commision Config */
    uint256 referralCommissionChargePercent;
    uint256 referralCommissionChargeDivisor;
    address payable referralChargeReceiver;
    
    // Transaction Config 
    uint256 transactionChargePercent;
    uint256 transactionChargeDivisor;
    address payable transactionChargeReceiver;
    
    
    
    // List of authorizedCaller with escalated permissions
    mapping(address => bool) authorizedCaller;

   
    /* ProductTx */
    struct ProductTx {
        string _txId;
        string _id;
        uint256 _depositedAmt;
        uint256 _receivableAmt;
        uint256 _feeAmt;
        uint256 _paymentMode;
        uint256 _pledgedFeePercent;
        uint256 _pledgedFeeDivisor;
        address payable _ownerAddress;
    }
    
    // Product Info
    struct ProductInfo {
        string _id;
        uint256 _priceInWei;
        address payable _ownerAddress;
        uint256 _pledgedFeePercent;
        uint256 _pledgedFeeDivisor;
        uint256 _paymentMode;
    }

   
    // To Get Product TX Info
    mapping(string => ProductTx) public initiatedProductTx;
    mapping(string => ProductInfo) public initiatedProduct;
    
    // Events 
    event AuthorizedCaller(address _caller);
    event DeAuthorizedCaller(address _caller);
    
    // Product Updates 
    event ProductInfoUpdated(string _id,
        uint256 _priceInWei,
        address payable _ownerAddress,
        uint256 _pledgedFeePercent,
        uint256 _pledgedFeeDivisor,
        uint256 _paymentMode);
    
    // Transaction 

    event ConfigUpdated(
        address payable _transactionChargeReceiver,
        uint256 _transactionChargePercent,
        uint256 _transactionChargeDivisor,
        address payable _referralChargeReceiver,
        uint256 _referralCommissionChargePercent,
        uint256 _referralCommissionChargeDivisor,
        uint256 _baseFeePercent,
        uint256 _baseFeeDivisor
    );
    

    event TransactionCompleted(
        string _txId
    );
    
 

    constructor(address payable _transactionChargeReceiver, address payable _referralChargeReceiver) public {
        owner = msg.sender;
        transactionChargeReceiver = _transactionChargeReceiver;
        referralChargeReceiver = _referralChargeReceiver;
    }

    modifier onlyAuthorized() {
        require(
            authorizedCaller[msg.sender] == true || msg.sender == owner,
            "Only Authorized and Owner can perform this action"
        );
        _;
    }

    function authorizeCaller(address _caller) public onlyOwner returns (bool) {
        authorizedCaller[_caller] = true;
        emit AuthorizedCaller(_caller);
        return true;
    }

    function deAuthorizeCaller(address _caller)
        public
        onlyOwner
        returns (bool)
    {
        authorizedCaller[_caller] = false;
        emit DeAuthorizedCaller(_caller);
        return true;
    }

        

    function getConfig()
        public
        view
        returns (
            address _transactionChargeReceiver,
            uint256 _transactionChargePercent,
            uint256 _transactionChargeDivisor,
            address _referralChargeReceiver,
            uint256 _referralCommissionChargePercent,
            uint256 _referralCommissionChargeDivisor,
            uint256 _baseFeePercent,
            uint256 _baseFeeDivisor
        )
    {
        return (
            transactionChargeReceiver,
            transactionChargePercent,
            transactionChargeDivisor,
            referralChargeReceiver,
            referralCommissionChargePercent,
            referralCommissionChargeDivisor,
            baseFeePercent,
            baseFeeDivisor
        );
    }

    function updateConfig(
        address payable _transactionChargeReceiver,
        uint256 _transactionChargePercent,
        uint256 _transactionChargeDivisor,
        address payable _referralChargeReceiver,
        uint256 _referralCommissionChargePercent,
        uint256 _referralCommissionChargeDivisor,
        uint256 _baseFeePercent,
        uint256 _baseFeeDivisor
    ) public onlyAuthorized returns (bool) {
        
        // Base Fee 
        baseFeePercent = _baseFeePercent;
        baseFeeDivisor = _baseFeeDivisor;
        
        // Transaction 
        transactionChargeReceiver = _transactionChargeReceiver;
        transactionChargePercent = _transactionChargePercent;
        transactionChargeDivisor = _transactionChargeDivisor;
    
        // Referral 
        referralChargeReceiver = _referralChargeReceiver;
        referralCommissionChargePercent = _referralCommissionChargePercent;
        referralCommissionChargeDivisor = _referralCommissionChargeDivisor;
        
        emit ConfigUpdated(
            _transactionChargeReceiver,
            _transactionChargePercent,
            _transactionChargeDivisor,
            _referralChargeReceiver,
            _referralCommissionChargePercent,
            _referralCommissionChargeDivisor,
            _baseFeePercent,
            _baseFeeDivisor
        );

        return true;
    }
    
    

    function updateProductInfo(
        string memory _id,
        uint256 _priceInWei,
        uint256 _pledgedFeePercent,
        uint256 _pledgedFeeDivisor,
        uint256 _paymentMode) public 
        returns (bool)
    {
        /* Check if Product Already exist, if yes then check if updated by same owner*/
        if(initiatedProduct[_id]._ownerAddress != address(0x0))
        {
            require(msg.sender == initiatedProduct[_id]._ownerAddress, "Product can only be updated by owner only");
        }
        
        // To Ensure Pledged Percent are within Permissible limits (Should not exceed 100% and Should not be less than Base fee)
        uint256 _baseCheckInt = 10 ** 18;
        
        uint256 _ceilInt = 0;
        uint256 _ceilPercent = 100; 
        uint256 _ceilDivisor = 1;
        
        
        uint256 _expectedInt = 0;
        uint256 _actualInt = 0;
        
        
        _ceilInt = _ceilPercent.mul(_baseCheckInt).div(_ceilDivisor.mul(100));
        _expectedInt = baseFeePercent.mul(_baseCheckInt).div(baseFeeDivisor.mul(100));
        _actualInt = _pledgedFeePercent.mul(_baseCheckInt).div(_pledgedFeeDivisor.mul(100));
        
        require(_actualInt >= _expectedInt, "Pledged Fee Should be more than base fee ");
        require(_actualInt < _ceilInt, "Pledged Fee Should be less than 100%");
        
        initiatedProduct[_id]._id = _id;
        initiatedProduct[_id]._priceInWei = _priceInWei;
        initiatedProduct[_id]._ownerAddress = msg.sender;
        initiatedProduct[_id]._pledgedFeePercent = _pledgedFeePercent;
        initiatedProduct[_id]._pledgedFeeDivisor = _pledgedFeeDivisor;
        initiatedProduct[_id]._paymentMode = _paymentMode;
        
        emit ProductInfoUpdated( _id,
         _priceInWei,
         msg.sender,
         _pledgedFeePercent,
         _pledgedFeeDivisor,
         _paymentMode);
        
        return true;
    }
    
    
    
    function purchaseProductViaETH(
        string memory _internalTxId,
        string memory _productId,
        bool _isReferredBuyer
    ) public payable returns (bool){
        
        require(initiatedProductTx[_internalTxId]._ownerAddress == address(0x0),"Transaction already processed");
        
        /* Msg Value  */
        uint256 _depositedAmt = msg.value;
  
        uint256 _baseRecievableAmt = 0;
        uint256 _baseFeeAmt = 0;
        
        uint256 _adminFeeAmt = 0;
        uint256 _referralFeeAmt = 0;
        
   
        
        
        initiatedProductTx[_internalTxId]._txId = _internalTxId; 
        initiatedProductTx[_internalTxId]._id = _productId; 
        initiatedProductTx[_internalTxId]._paymentMode = 1; // Via Ether
        initiatedProductTx[_internalTxId]._pledgedFeePercent = initiatedProduct[_productId]._pledgedFeePercent; 
        initiatedProductTx[_internalTxId]._pledgedFeeDivisor = initiatedProduct[_productId]._pledgedFeeDivisor; 
        initiatedProductTx[_internalTxId]._ownerAddress = initiatedProduct[_productId]._ownerAddress; 
        
        
        // Owner Address should not be equal to zero 
        require(initiatedProduct[_productId]._ownerAddress != address(0x0),"Product does not exists");
        
        
        // Amount should be equal to product price , return any extra amount to sender 
        
        require(initiatedProduct[_productId]._priceInWei == _depositedAmt, "Exact Product Price should be provided");
        
        
        // Get Base Receivable and Fee Amount 
        
        // Get Product Pledged Fee
        _baseFeeAmt = initiatedProduct[_productId]._pledgedFeePercent.mul(_depositedAmt).div(initiatedProduct[_productId]._pledgedFeeDivisor.mul(100));
        _baseRecievableAmt = _depositedAmt.sub(_baseFeeAmt);
        
        // Update Base Amounts
        initiatedProductTx[_internalTxId]._depositedAmt = _depositedAmt;
        initiatedProductTx[_internalTxId]._receivableAmt = _baseRecievableAmt;
        initiatedProductTx[_internalTxId]._feeAmt = _baseFeeAmt;
        
        
        
        

        if (transactionChargeDivisor > 0 && transactionChargePercent > 0) {
            /* Calculate Transaction Fee */
            
            _adminFeeAmt = transactionChargePercent.mul(_baseFeeAmt).div(
                transactionChargeDivisor.mul(100)
            );
         
        }

        /* Debit Referral Commision Fee if set */
        if(referralCommissionChargeDivisor > 0 &&
            referralCommissionChargePercent > 0){
            _referralFeeAmt = referralCommissionChargePercent
                .mul(_baseFeeAmt)
                .div(referralCommissionChargeDivisor.mul(100));
            }

        if (
            _isReferredBuyer == false
        ) {
            /* Calculate Referral Commision Fee */            
            _adminFeeAmt = _adminFeeAmt.add(_referralFeeAmt);            
        }

        /* Send Transaction Receiver their share */
        if (_adminFeeAmt > 0) {
            transactionChargeReceiver.transfer(_adminFeeAmt);
        }

        /* Send Referral Receiver their share */
        if (_referralFeeAmt > 0) {
            referralChargeReceiver.transfer(_referralFeeAmt);
        }
        
        
        /* Transfer Leftover amount to product owner */
        initiatedProduct[_productId]._ownerAddress.transfer(_baseRecievableAmt);

      
        emit TransactionCompleted(
            initiatedProductTx[_internalTxId]._txId
        );
        
        return true;
    }

    
}