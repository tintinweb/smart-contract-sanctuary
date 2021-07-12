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
// File: contracts/ExternalTokenSale.sol

pragma solidity ^0.5;


contract Owned {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    /**
     * @dev Modifier to restrict owner access only.
     */
     
    modifier onlyOwner {
        require(msg.sender == owner,"Invalid Owner");
        _;
    }
    
    /**
     * @dev Transfer ownership to new owner, can only be called by existing owner.
     */
     
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract ERC20 {
  uint256 public totalSupply;
  uint256 public decimals;
  function balanceOf(address who) public view returns (uint);
  function allowance(address owner, address spender) public view returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public returns (bool ok);
}


contract ExternalTokenSale is Owned {

    using SafeMath for uint;
    
    struct TokenArtifact {
        uint256 totalSold;
        uint256 exchangeRate; /* per Token in terms of base token (FTB) */
        ERC20 targetToken;
        uint256 pledgedFeePercent;
        uint256 pledgedFeeDivisor;
    }
    
    /* Seller => Token Address */
    mapping(address => mapping(address => TokenArtifact)) public tokenLedger;
    mapping(address => bool) authorizedCaller;

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
    
    /**
     * @dev Modifier to restrict access to authorized caller.
     */
    modifier onlyAuthCaller(){
        require(authorizedCaller[msg.sender] == true || msg.sender == owner,"Only Authorized and Owner can perform this action");
        _;
    }
    
    /**
     * @dev Modifier to make sure contribution satisfies condition of being non zero and Funding is enabled.
     */
    modifier onlyValidContribution(uint _value){
        require(_value > 0 ,"Value should be greater than zero");
        _;
    }

    /* Events */
    event AuthorizedCaller(address _caller);
    event DeAuthorizedCaller(address _caller);
    
    event PurchaseToken(address indexed _buyerAddress,
                        address indexed _sellerAddress, 
                        address indexed _tokenAddress, 
                        uint256 _amount,
                        uint256 _feeAmount);
    
    event AddTokenArtifact(address indexed _sellerAddress, 
                        address indexed _tokenAddress, 
                        uint256 _amount,
                        uint256 _pledgedFeePercent,
                        uint256 _pledgedFeeDivisor);
                        
    event TransactionConfigUpdated(uint _transactionChargePercent, uint _transactionChargeDivisor);
    event ReferralCommissionConfigUpdated(uint _referralCommissionChargePercent, uint _referralCommissionChargeDivisor);

    
    constructor(address payable _transactionChargeReceiver, address payable _referralChargeReceiver) public {
        
        owner = msg.sender;
        transactionChargeReceiver = _transactionChargeReceiver;
        referralChargeReceiver = _referralChargeReceiver;
    }
    
   
     

    
    /**
     * @dev Can be called to authorize address which can perform operation requiring elevated privileges 
     */
    function authorizeCaller(address _caller) public onlyOwner returns(bool){
        authorizedCaller[_caller] = true;
        emit AuthorizedCaller(_caller);
        return true;
    }
    
    /**
     * @dev Can be called to de-authorize address which can perform operation requiring elevated privileges
     */
    function deAuthorizeCaller(address _caller) public onlyOwner returns(bool){
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
    ) public onlyAuthCaller returns (bool) {
        
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
    
    /**
     * @dev addTokenArtifact function need to be called to add the ERC20 Token artifact
     * by providing ERC20 token contract address, Exchange Rate with respect to base token (FTB)
    */
    
    function addTokenArtifact(
        address _tokenAddress, 
        uint256 _exchangeRate,
        uint256 _pledgedFeePercent,
        uint256 _pledgedFeeDivisor) public returns(bool)
    {
        tokenLedger[msg.sender][_tokenAddress].totalSold =  0 ;
        tokenLedger[msg.sender][_tokenAddress].exchangeRate =  _exchangeRate ;
        tokenLedger[msg.sender][_tokenAddress].targetToken =  ERC20(_tokenAddress) ;
        
        tokenLedger[msg.sender][_tokenAddress].pledgedFeePercent = _pledgedFeePercent;
        tokenLedger[msg.sender][_tokenAddress].pledgedFeeDivisor = _pledgedFeeDivisor;
        
        emit AddTokenArtifact(
            msg.sender, 
            _tokenAddress, 
            _exchangeRate,
            _pledgedFeePercent,
            _pledgedFeeDivisor
        );
        return true;
    }
    

    
    
    function purchaseToken(
        address payable _sellerAddress, 
        address _tokenAddress, 
        bool _isReferredBuyer) public payable returns(bool)
    { 
        
        TokenArtifact memory _activeTokenArtifact = tokenLedger[_sellerAddress][_tokenAddress];
        
        require(_activeTokenArtifact.exchangeRate > 0, "Exchange Rate should greater than zero ");
        
        /* Calculate Conversion in terms of target token decimals */
        uint256 _targetTokenDecimalBase = uint256(_activeTokenArtifact.targetToken.decimals());
        uint256 _finalAmount = 0;
  
       
        
        /* Msg Value  */
        uint256 _depositedAmt = msg.value;
  
        uint256 _baseRecievableAmt = 0;
        uint256 _baseFeeAmt = 0;
        
        uint256 _adminFeeAmt = 0;
        uint256 _referralFeeAmt = 0;
        
   
        // Get Product Pledged Fee
   
        _baseFeeAmt = _activeTokenArtifact.pledgedFeePercent.mul(_depositedAmt).div(_activeTokenArtifact.pledgedFeeDivisor.mul(100));
        _baseRecievableAmt = _depositedAmt.sub(_baseFeeAmt);
        
        
        if (transactionChargeDivisor > 0 && transactionChargePercent > 0) {
            /* Calculate Transaction Fee */
            
            _adminFeeAmt = transactionChargePercent.mul(_baseFeeAmt).div(
                transactionChargeDivisor.mul(100)
            );
         
        }

        if(referralCommissionChargeDivisor > 0 &&
            referralCommissionChargePercent > 0){
            _referralFeeAmt = referralCommissionChargePercent
                .mul(_baseFeeAmt)
                .div(referralCommissionChargeDivisor.mul(100));
            }
        

        /* Debit Referral Commision Fee if set */
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
        _sellerAddress.transfer(_baseRecievableAmt);

        /* Transfer Final target Token from Seller to Buyer */
        _finalAmount = _depositedAmt.mul(10 ** _targetTokenDecimalBase).div(_activeTokenArtifact.exchangeRate);
        
        /* Transfer Calculated token to investor */
        _activeTokenArtifact.targetToken.transferFrom(_sellerAddress,msg.sender,_finalAmount);
        
        /* Update Sold */
        _activeTokenArtifact.totalSold = tokenLedger[msg.sender][_tokenAddress].totalSold.add(_finalAmount);
        
        
        
        emit PurchaseToken(msg.sender, _sellerAddress, _tokenAddress, _finalAmount, _baseFeeAmt);
        return true;   
    }

    
    /**
     * @dev Fallback function configured to accept any ether sent to smart contract
     */
    function () external onlyValidContribution(msg.value) payable {

       revert();
    }


}