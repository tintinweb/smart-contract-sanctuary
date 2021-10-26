/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

//-----------------------------------------------------------------------------//
//                             Name : MPadLaunchPad                            //
//                     Swap tokens to claim launch tokens                      //
//                        Distribution Contract                                //
//-----------------------------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IMainToken{
    function transfer(address, uint256) public pure returns (bool);
 }
 
contract IBUSD{
    function transferFrom(address, address, uint256) public pure returns (bool);
    function transfer(address, uint256) public pure returns (bool);
 }
 
 
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract MultiPadLaunchApp is IBEP20{
    
    using SafeMath for uint256;
    
    IMainToken iMainToken;
    IBUSD iBUSD;
    
    //variable declaration
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    // Special business use case variables
    mapping (address => bool) _whitelistedAddress;
    mapping (address => uint256) _lockingTimeForSale;
    mapping (address => uint256) _recordSale;
    mapping (address => bool) _addressLocked;
    mapping (address => uint256) _finalSoldAmount;
    mapping (address => mapping(uint256 => bool)) reEntrance;
    mapping (address => uint256) specialAddBal;
    mapping (address => uint256) _contributionBNB;
    mapping (address => mapping(uint256 => uint256)) _claimedByUser;
    mapping (address =>mapping(uint256 => uint256))_thisSaleContribution;
    mapping (address => uint) _multiplier;
    
    address[] private _whitelistedUserAddresses;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private saleMinimumAmount;
    uint256 private saleMaximumAmount;
    uint256 private saleId = 0;
    uint256 private tokenPrice;
    uint256 private deploymentTime; 
    uint256 private pricePerToken;
    uint256 private hardCap;
    uint256 private decimalBalancer = 1000000000;
    uint256 private IDOAvailable;
    address private tokenContractAddress;
    bool whitelistFlag = true;
    address private IDOAddress;
    string private _baseName;
    uint256 private _claimTime1;
    address public _BUSDAddress;
    uint256 public BUSDPrice;
    
    constructor (string memory name, string memory symbol, uint256 totalSupply, address owner, uint256 _totalDummySupply) public {
        _name = name;
        _symbol = symbol; 
        _totalSupply = totalSupply*(10**uint256(_decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
         deploymentTime =  block.timestamp;
        _transfer(_owner,address(this),_totalDummySupply*(10**uint256(_decimals)));
    }

    function setTokenAddress(address _ITokenContract) onlyOwner external returns(bool){
        tokenContractAddress = _ITokenContract;
        iMainToken = IMainToken(_ITokenContract);
    }
    
    function setBUSDAddress(address _iBUSDAdd) onlyOwner external returns(bool){
        _BUSDAddress = _iBUSDAdd;
        iBUSD = IBUSD(_iBUSDAdd);
    }
    
    function setBUSDprice(uint256 _BUSDPrice) onlyOwner external returns(bool){
        BUSDPrice = _BUSDPrice;
    }
    
    
    

    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @return the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @return the name of the token.
     */
    function setBaseName(string baseName) external onlyOwner returns (bool) {
         _baseName = baseName;
         return true;
    }
    
    /**
     * @return the name of the token.
     */
    function baseName() external view returns (string memory) {
        return _baseName;
    }
    /**
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() external  view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public  view returns (uint256) {
        return _balances[owner];
    }



    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    
    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
    */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() external view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) external onlyOwner returns (bool){
        require(newOwner != address(0), "Owner address cant be zero");
        _owner = newOwner;
        return true;
    }

    /* ----------------------------------------------------------------------------
     *  Functions for Additional Business Logic For Owner Functions
     * ----------------------------------------------------------------------------
     */
     
     /**
     * @dev Whitelist Addresses for further transactions
     * @param _userAddresses  Array of user addresses
     */
     function whitelistUserAdress(address[]  _userAddresses, uint[] _multiplierAmount) external onlyOwner returns(bool){
         uint256 count = _userAddresses.length;
         require(count < 201, "Array Overflow");    //Max 200 enteries at a time
          for (uint256 i = 0; i < count; i++){
               _whitelistedUserAddresses.push(_userAddresses[i]);
               _whitelistedAddress[_userAddresses[i]] = true;
               _multiplier[_userAddresses[i]] = _multiplierAmount[i];
          }
         return true;
     }
     
     //Get the multiplier details
     function getMultiplierbyAddress(address _userAddress) external view returns(uint256){
      return _multiplier[_userAddress];
     }
     
     /**
     * @dev get the list of whitelisted addresses
     */
     function getWhitelistUserAdress() external view returns(address[] memory){
         return _whitelistedUserAddresses;
     }
     
     /**
     * @dev Set sale parameters for users to buy new tokens
     * @param _startTime Start time of the sale
     * @param _endTime End time of the sale
     * @param _minimumAmount Minimum accepted amount
     * @param _maximumAmount Maximum accepted amount
     */
     function setSaleParameter(
         uint256 _startTime,
         uint256 _endTime,
         uint256 _minimumAmount,
         uint256 _maximumAmount,
         bool _whitelistFlag
         ) external onlyOwner returns(bool){
          require(_startTime > 0 && _endTime > 0  && _minimumAmount > 0  && _maximumAmount > 0, "Invalid Values");
          saleStartTime = _startTime;
          saleEndTime = _endTime;
          saleMinimumAmount = _minimumAmount;
          saleMaximumAmount = _maximumAmount;
          saleId = saleId.add(1);
          whitelistFlag = _whitelistFlag;
         return true;
     }
     
     /**
     * @dev Get Sale Details Description
     */
     function getSaleParameter(address _userAddress) external view returns(
         uint256 _startTime,
         uint256 _endTime,
         uint256 _minimumAmount,
         uint256 _maximumAmount,
         uint256 _saleId,
         bool _whitelistFlag
         ){
            if(whitelistFlag == true && _whitelistedAddress[_userAddress] == true){    
            _maximumAmount = saleMaximumAmount.mul(_multiplier[_userAddress]);
           }
           else{
            _maximumAmount = saleMaximumAmount;
           }
          _startTime  =  saleStartTime;
          _endTime = saleEndTime;
          _minimumAmount = saleMinimumAmount;
          
          _saleId = saleId;
          _whitelistFlag = whitelistFlag;
     }
     
     /**
     * @dev Owner can set token price
     * @param _tokenPrice price of 1 Token
     */
     function setTokenPrice(
         uint256 _tokenPrice
         ) external onlyOwner returns(bool){
          tokenPrice = _tokenPrice;
         return true;
     }
     
     /**
     * @dev Get token price
     */
     function getTokenPrice() external view returns(uint256){
          return tokenPrice;
     }
     
     
    /* ----------------------------------------------------------------------------
     *  Functions for Additional Business Logic For Users 
     * ----------------------------------------------------------------------------
     */    
     
    modifier checkSaleValidations(address _userAddress, uint256 _value){
     if(whitelistFlag == true){    
     require(_whitelistedAddress[_userAddress] == true, "Address not Whitelisted" );
     require(_value <= saleMaximumAmount.mul(_multiplier[_userAddress]), "Total amount should be less than maximum limit");
     require(_thisSaleContribution[_userAddress][saleId].add(_value) <= saleMaximumAmount.mul(_multiplier[_userAddress]), "Total amount should be less than maximum limit");
     }
     else{
         require(_thisSaleContribution[_userAddress][saleId].add(_value) <= saleMaximumAmount, "Total amount should be less than maximum limit");
     }
     require(saleStartTime < block.timestamp , "Sale not started");
     require(saleEndTime > block.timestamp, "Sale Ended");
     require(_finalSoldAmount[_userAddress].add(_value) >= saleMinimumAmount, "Total amount should be more than minimum limit");
     require(_value <= IDOAvailable, "Hard Cap Reached");
        _;
    }
    
    //Check the expected amount per bnb 
    function checkTokensExpected(uint256 _value) view external returns(uint256){
        return _value.mul(tokenPrice).div(decimalBalancer);
    }
    
    /*
     * @dev Get Purchaseable amount
     */
      function getPurchaseableTokens() external view returns(uint256){
         return hardCap;
     }
     
    
    /*
     * @dev Buy New tokens from the sale
     */
     function buyTokens(uint256 _NumberOfNFT) external checkSaleValidations(msg.sender, _NumberOfNFT.mul(1000000000000000000)) returns(bool){
         iBUSD.transferFrom(msg.sender,address(this),_NumberOfNFT.mul(BUSDPrice).mul(1000000000000000000));
         _trasferInLockingState(msg.sender, _NumberOfNFT);
         return true;
     }
     
     /*
      * @dev Internal function to achieve 
      */
     function _trasferInLockingState(
         address _userAddress,
         uint256 _amountTransfer
         ) internal returns(bool){
        _lockingTimeForSale[_userAddress] = block.timestamp;
        uint256 calculateTokens = _amountTransfer.mul(1000000000000000000);
        uint256 earnedTokens = _recordSale[_userAddress].add(calculateTokens);
        _transfer(address(this),msg.sender,calculateTokens);
        _recordSale[_userAddress] = earnedTokens;
        _finalSoldAmount[_userAddress] = earnedTokens;
        _contributionBNB[_userAddress] = _contributionBNB[_userAddress].add(_amountTransfer.mul(BUSDPrice).mul(1000000000000000000));
        _thisSaleContribution[_userAddress][saleId] = _thisSaleContribution[_userAddress][saleId].add(_amountTransfer);
        IDOAvailable = IDOAvailable.sub(calculateTokens);
         return true;
     }
     
     /*
     * @dev Owner can set hard cap for IDO 
     */
     function setIDOavailable(uint256 _IDOHardCap) external onlyOwner returns(bool){
         require(_IDOHardCap <= balanceOf(address(this)) && _IDOHardCap > 0, "Value should not be more than IDO balance and greater than 0" );
         hardCap = _IDOHardCap;
         IDOAvailable = _IDOHardCap;
         return true;
     }
     
    /*
     * @dev Claim Purchased token by lock number 
     */
    function claimPurchasedTokens(uint256 _lockNumber) external validateClaim(msg.sender,_lockNumber) returns (bool){
    }
    
    //validate claim tokens
    modifier validateClaim(address _userAddress, uint256 _lockNumber)
    {
        require(_recordSale[_userAddress] > 0, "Not sufficient purchase Balance");
        require(_lockNumber == 1 || _lockNumber == 2, "Invalid Lock Number");
        if(_lockNumber == 1){   //Users will be able to withdraw tokens only after 1.5 hours of end time
            require(block.timestamp > saleEndTime + _claimTime1 && reEntrance[_userAddress][_lockNumber] != true, "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 2){    // 1 month
            require(block.timestamp > saleEndTime + _claimTime1 +  2629743  && reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 3){    // 1 month
            require(block.timestamp > saleEndTime + _claimTime1 +  2629743  && reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 4){    // 1 month
            require(block.timestamp > saleEndTime + _claimTime1 +  2629743  && reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 5){    // 1 month
            require(block.timestamp > saleEndTime + _claimTime1 +  2629743  && reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        _;
    }
    
    /*
     * @dev Check if the user address is whitelisted or not
     */ 
    function checkWhitelistedAddress(address _userAddress) view external returns(bool){
        require(_userAddress != address(0), "addresses should not be 0");
        return _whitelistedAddress[_userAddress];
    }
    
    /*
     * @dev Check all locking addresses
     */
    modifier checkLockedAddresses(address _lockedAddresses){
           require(_addressLocked[_lockedAddresses] != true, "Locking Address");
       _;
    }
    
    /*
     * @dev Admin can withdraw the bnb  
     */
    function withdrawCurrency(uint256 _amount) external onlyOwner returns(bool){
        msg.sender.transfer(_amount);
        return true;
    }
    
    /*
     * @dev Get user tokens by address 
     */
    function getUserTokensByAdd(address _userAddress) external view returns(uint256 _div1, uint256 _div2, uint256 _div3, uint256 _div4, uint256 _div5){
        uint256 division = _finalSoldAmount[_userAddress].div(2);
        _div1 = division;
        _div2 = division;
        _div3 = 0;
        _div4 = 0;
        _div5 = 0;
        if(reEntrance[_userAddress][1] == true){
            _div1 = 0;
        }
        if(reEntrance[_userAddress][2] == true){
            _div2 = 0;
        }
        if(reEntrance[_userAddress][3] == true){
            _div3 = 0;
        }
        if(reEntrance[_userAddress][4] == true){
            _div4 = 0;
        }
        if(reEntrance[_userAddress][5] == true){
            _div5 = 0;
        }
        return(_div1,_div2,_div3,_div4,_div5);
    }
    
    /*
     * @dev Get contract BNb balance to display
     */ 
    function checkContractBNBBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    //get sold status
    function getSoldStatus() external view returns(uint256 _totalAvailable, uint256 _currentAvailable){
       _totalAvailable = hardCap;
       _currentAvailable = IDOAvailable;
    }
    
    function getAmountPurchased(address _userAddress) external view returns(uint256 _contribution, uint256 _allocation){
       _contribution =  _contributionBNB[_userAddress];
        _allocation = _finalSoldAmount[_userAddress];
    }
    
    //check contract block.timestamp time 
    function checkContractTime() external view returns(uint256){
        return block.timestamp;
    }
    
    function getClaimDates() view external returns(uint256 _d1, uint256 _d2, uint256 _d3, uint256 _d4, uint256 _d5){
        _d1 = saleEndTime + _claimTime1;  
        _d2 = saleEndTime + _claimTime1 +  2629743;
        _d3 = 0;
        _d4 = 0;
        _d5 = 0;
        return(_d1, _d2, _d3, _d4,_d5);
    }
    
    /*
     * @dev Get claimed tokens by user address
     */
    function getClaimedTokensHistory(address _userAddress) view external returns(uint256 r1,uint256 r2, uint256 r3, uint256 r4, uint256 r5){
        r1 = _claimedByUser[_userAddress][1];
        r2 = _claimedByUser[_userAddress][2];
        r3 = 0;
        r4 = 0;
        r5 = 0;
        return(r1, r2, r3, r4, r5);
    }
    
    /*
     * @dev Set bnb price to display per token
     */
    function setViewPricePerToken(uint256 _price) external onlyOwner returns(bool){
        pricePerToken = _price;
        return true;
    }
    
    /*
     * @dev Get BNB price per token to display 
     */
    function getViewPricePerToken() view external returns(uint256){
        return pricePerToken;
    }
    

    function setclaimTime1(uint256 claimTime1) external onlyOwner returns(bool){
        _claimTime1 = claimTime1;
        return true;
    }
    

    function getclaimTime1() view external returns(uint256){
        return _claimTime1;
    }
    
    function withdrawPeningTokens(uint256 _amount) external onlyOwner returns(bool){
       iBUSD.transfer(msg.sender, _amount);
       return true;
         
    }
    
    function getBUSDAddress() public view returns(address){
        return _BUSDAddress;
    }

}