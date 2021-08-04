/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//-----------------------------------------------------------------------------//
//                             Name : MultiPad                                 //
//                           Symbol : MPAD                                     //
//                     Total Supply : 100,000,000                              //
//                  Company Reserve : 25,000,000                               //
//          Marketing and ecosystem : 20,000,000                               //
//                             Team : 20,000,000                               //
//                        Liquidity : 10,000,000                               //
//                    IDO fundraise : 15,000,000                               //
//       Partners & Early Investors : 10,000,000                               //
//-----------------------------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract MultiPad is IBEP20 {
    
    using SafeMath for uint256;
    
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
    
    address[] private _whitelistedUserAddresses;
    uint256 private saleStartTime;
    uint256 private saleEndTime;
    uint256 private saleMinimumAmount;
    uint256 private saleMaximumAmount;
    uint256 private saleId = 0;
    uint256 private tokenPrice;
    uint256 private deploymentTime; 
    uint256 private pricePerToken;
    uint256 private decimalBalancer = 1000000000;
    uint256 private IDOAvailable = 15000000000000000000000000;

    bool whitelistFlag = true;
    address private Reserve = 0x2244296A5EcAfF57d4AEE3A99b2Ae4D55c38bB4a;
    address private Marketing = 0x3DDD53726be86265107369c42e01B1529DDd5E40;
    address private Team1 = 0xD2265169Fa9Bbd0f5A2f4b7AddBcF41E20b496fd;
    address private Team2 = 0x42b0E9714561991940EeCa7eEEA7D5f6d04037C4;
    address private Liquidity = 0xC818c2dAF237C6e7E7B125b657F38644f7389fd2;
    address private IDO = 0x62e3ebBc8B75803f1487a5b1e27686e3E04D9790;
    address private Partners = 0x4bdF39b9FF0d982D73E7f2b652d149D4Bf2ae978;
    

    
    

    constructor (string memory name, string memory symbol, uint256 totalSupply, address owner) public {
        _name = name;
        _symbol = symbol; 
        _totalSupply = totalSupply*(10**uint256(_decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
        _addressLocked[Reserve] = true;
        _addressLocked[Marketing] = true;
        _addressLocked[Team1] = true;
        _addressLocked[Liquidity] = true;
        _addressLocked[Partners] = true;
         deploymentTime =  block.timestamp;
         initiateValues();
    }
    
    function initiateValues() internal {
        specialAddBal[Reserve] = 25000000*(10**uint256(_decimals));
        specialAddBal[Marketing] = 20000000*(10**uint256(_decimals));
        specialAddBal[Team1] = 18000000*(10**uint256(_decimals));
        specialAddBal[Team2] = 2000000*(10**uint256(_decimals));
        specialAddBal[Liquidity] = 10000000*(10**uint256(_decimals));
        specialAddBal[IDO] = 15000000*(10**uint256(_decimals));
        specialAddBal[Partners] = 10000000*(10**uint256(_decimals));
        _transfer(_owner,Reserve,specialAddBal[Reserve]);
        _transfer(_owner,Marketing,specialAddBal[Marketing]);
        _transfer(_owner,Team1,specialAddBal[Team1]); 
        _transfer(_owner,Team2,specialAddBal[Team2]);
        _transfer(_owner,Liquidity,specialAddBal[Liquidity]);       
        _transfer(_owner,IDO,specialAddBal[IDO]);
        _transfer(_owner,Partners,specialAddBal[Partners]);
    }


    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override checkLockedAddresses(msg.sender) returns (bool) {
            _transfer(msg.sender, to, value);
            return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override checkLockedAddresses(from) returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }

     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }

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

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
    
    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
    */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() public view returns (address) {
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
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
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
     function whitelistUserAdress(address[] calldata _userAddresses) external onlyOwner returns(bool){
         uint256 count = _userAddresses.length;
          for (uint256 i = 0; i < count; i++){
               _whitelistedUserAddresses.push(_userAddresses[i]);
               _whitelistedAddress[_userAddresses[i]] = true;
          }
         return true;
     }
     
     /**
     * @dev get the list of whitelisted addresses
     */
     function getWhitelistUserAdress() public view returns(address[] memory){
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
          saleStartTime = _startTime;
          saleEndTime = _endTime;
          saleMinimumAmount = _minimumAmount;
          saleMaximumAmount = _maximumAmount;
          saleId = saleId + 1;
          whitelistFlag = _whitelistFlag;
         return true;
     }
     
     /**
     * @dev Get Sale Details Description
     */
     function getSaleParameter() external view returns(
         uint256 _startTime,
         uint256 _endTime,
         uint256 _minimumAmount,
         uint256 _maximumAmount,
         uint256 _saleId,
         bool _whitelistFlag
         ){
          _startTime  =  saleStartTime;
          _endTime = saleEndTime;
          _minimumAmount = saleMinimumAmount;
          _maximumAmount = saleMaximumAmount;
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
     }
     require(saleStartTime < block.timestamp , "Sale not started");
     require(saleEndTime > block.timestamp, "Sale Ended");
     require(_contributionBNB[_userAddress] + _value >= saleMinimumAmount, "Total amount should be more than minimum limit");
     require(_contributionBNB[_userAddress] + _value <= saleMaximumAmount, "Total amount should be less than maximum limit");
     require(_value <= IDOAvailable, "Hard Cap Reached");
        _;
    }
    
    //Check the expected amount per bnb 
    function checkTokensExpected(uint256 _value) view public returns(uint256){
        return _value.mul(tokenPrice).div(decimalBalancer);
    }
    
    /*
     * @dev Get Purchaseable amount
     */
      function getPurchaseableTokens() external view returns(uint256){
         return IDOAvailable;
     }
    
    /*
     * @dev Buy New tokens from the sale
     */
     function buyTokens() payable external checkSaleValidations(msg.sender, msg.value) returns(bool){
         _trasferInLockingState(msg.sender, msg.value);
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
        uint256 earnedTokens = _recordSale[_userAddress].add((_amountTransfer.mul(tokenPrice)).div(decimalBalancer));
        _recordSale[_userAddress] = earnedTokens;
        _finalSoldAmount[_userAddress] = earnedTokens;
        _contributionBNB[_userAddress] = _contributionBNB[_userAddress] + msg.value;
        IDOAvailable = IDOAvailable.sub(earnedTokens);
         return true;
     }
     
     /*
     * @dev Owner can set hard cap for IDO 
     */
     function setIDOavailable(uint256 _IDOHardCap) external onlyOwner returns(bool){
         IDOAvailable = _IDOHardCap;
         return true;
     }
     
    /*
     * @dev Claim Purchased token by lock number 
     */
    function claimPurchasedTokens(uint256 _lockNumber) external validateClaim(msg.sender,_lockNumber) returns (bool){
        _transfer(IDO,msg.sender,_finalSoldAmount[msg.sender].div(4));
        _recordSale[msg.sender] = _recordSale[msg.sender].sub(_finalSoldAmount[msg.sender].div(4));
        reEntrance[msg.sender][_lockNumber] = true;
        _claimedByUser[msg.sender][_lockNumber] = _finalSoldAmount[msg.sender].div(4);
    }
    
    //validate claim tokens
    modifier validateClaim(address _userAddress, uint256 _lockNumber)
    {
        require(_recordSale[_userAddress] > 0, "Not sufficient purchase Balance");
        require(_lockNumber == 1 || _lockNumber == 2 || _lockNumber == 3 || _lockNumber == 4 || _lockNumber == 5, "Invalid Lock Number");
        if(_lockNumber == 1){
            require(block.timestamp > saleEndTime + 300 && reEntrance[_userAddress][_lockNumber] != true, "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 2){
            require(block.timestamp > saleEndTime + 600  && reEntrance[_userAddress][_lockNumber] != true , "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 3){
            require(block.timestamp > saleEndTime  + 900 && reEntrance[_userAddress][_lockNumber] != true ,  "Insufficient Unlocked Tokens");
        }
        if(_lockNumber == 4){
            require(block.timestamp > saleEndTime + 1200 &&  reEntrance[_userAddress][_lockNumber] != true,  "Insufficient Unlocked Tokens");
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
     * @dev withdraw special locked tokens for internal team 
     */
    function withdrawSpecialLocked(address _toAddress, uint256 _amount) checkLockingRoles(msg.sender, _amount) external returns(bool){
       _transfer(msg.sender, _toAddress, _amount);
        specialAddBal[msg.sender].sub(_amount);
    }
    
    /*
     * @dev Admin can withdraw the bnb  
     */
    function withdrawBNB(uint256 _amount) external onlyOwner returns(bool){
        msg.sender.transfer(_amount);
        return true;
    }
    
    /*
     * @dev Get user tokens by address 
     */
    function getUserTokensBy(address _userAddress) public view returns(uint256 _div1, uint256 _div2, uint256 _div3, uint256 _div4){
        uint256 division = _finalSoldAmount[_userAddress].div(4);
        _div1 = division;
        _div2 = division;
        _div3 = division;
        _div4 = division;
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
        return(_div1,_div2,_div3,_div4);
    }
    
    /*
     * @dev Get contract BNb balance to display
     */ 
    function checkContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    //get sold status
    function getSoldStatus() public view returns(uint256 _totalAvailable, uint256 _currentAvailable){
       _totalAvailable = 15000000000000000000000000;
       _currentAvailable = IDOAvailable;
    }
    
    function getAmountPurchased(address _userAddress) public view returns(uint256 _contribution, uint256 _allocation){
       _contribution =  _contributionBNB[_userAddress];
        _allocation = _finalSoldAmount[_userAddress];
    }
    
    //check contract block.timestamp time 
    function checkContractTime() public view returns(uint256){
        return block.timestamp;
    }
    
    //Get the dates for unlock for buyers
    function getClaimDates() view public returns(uint256 _d1, uint256 _d2, uint256 _d3, uint256 _d4){
        _d1 = saleEndTime + 600;   // After 3 hours of end sale
        _d2 = saleEndTime + 1200;
        _d3 = saleEndTime + 2400;
        _d4 = saleEndTime + 3600;
        return(_d1, _d2, _d3, _d4);
    }
    
    /*
     * @dev Get claimed tokens by user address
     */
    function getClaimedTokensHistory(address _userAddress) view public returns(uint256 r1,uint256 r2, uint256 r3,uint256 r4){
        r1 = _claimedByUser[_userAddress][1];
        r2 = _claimedByUser[_userAddress][2];
        r3 = _claimedByUser[_userAddress][3];
        r4 = _claimedByUser[_userAddress][4];
        return(r1, r2, r3, r4);
    }
    
    /*
     * @dev Set bnb price to display per token
     */
    function setBnbPricePerToken(uint256 _price) external onlyOwner returns(bool){
        pricePerToken = _price;
        return true;
    }
    
    /*
     * @dev Get BNB price per token to display 
     */
    function getBnbPricePerToken() view public returns(uint256){
        return pricePerToken;
    }
   
    // to check locked tokens for marketing address, Reserve, Partners, Liquidity and Team  
    modifier checkLockingRoles(address _add, uint256 _amountRequested){
        require(_add == Team1 || _add == Team2 || _add == Partners || _add == Liquidity , "Only for Special Addresses");
        require(_amountRequested != 0, "amount should be greater than 0");
       if(_add == Reserve){
           require(block.timestamp > deploymentTime+3600, "Tokens are locked for 1 years from TGE");
         }
       if(_add == Marketing){
           if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 1800){                                               // First month from the deployment & 10%
              require(specialAddBal[_add].sub(_amountRequested) >= 18000000000000000000, "Amount exceded lock 1");
           }
           if(block.timestamp > deploymentTime + 1800 && block.timestamp < deploymentTime + 3600){                                        // Second month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 16000000000000000000, "Amount exceded lock 2");
           }
           if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 4800){                                        // Third month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 14000000000000000000, "Amount exceded lock 3");
           }
           if(block.timestamp > deploymentTime + 4800 && block.timestamp < deploymentTime + 6000){                                        // Fourth month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 12000000000000000000, "Amount exceded lock 4");
           }
           if(block.timestamp > deploymentTime + 6000 && block.timestamp < deploymentTime + 7200){                                       // Fifth month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 10000000000000000000, "Amount exceded lock 5");
           }
           if(block.timestamp > deploymentTime + 7200 && block.timestamp < deploymentTime + 8400){                                       // Sixth month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 8000000000000000000, "Amount exceded lock 6");
           }
           if(block.timestamp > deploymentTime + 8400 && block.timestamp < deploymentTime + 9600){                                       // Seventh month from the deployment & 10% 
               require(specialAddBal[_add].sub(_amountRequested) >= 6000000000000000000, "Amount exceded lock 7");
           }
           if(block.timestamp > deploymentTime + 9600 && block.timestamp < deploymentTime + 10800){                                       // Eighth month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 4000000000000000000, "Amount exceded lock 8");
           }
           if(block.timestamp > deploymentTime + 10800 && block.timestamp < deploymentTime + 12000){                                     // Ninth month from the deployment & 10%
               require(specialAddBal[_add].sub(_amountRequested) >= 2000000000000000000, "Amount exceded lock 9");
           }
         }
       if(_add == Team1){
           if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 4500){                                        // Sixth to Seventh Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1620000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 4500 && block.timestamp < deploymentTime + 5400){                                        // Seventh to Eighth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1440000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 5400 && block.timestamp < deploymentTime + 6300){                                        // Eighth to Ninth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1260000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 6300 && block.timestamp < deploymentTime + 7200){                                        // Ninth to Tenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1080000000000000000000000, "Amount exceded lock 4");
           }
            if(block.timestamp > deploymentTime + 7200 && block.timestamp < deploymentTime + 8100){                                        // Tenth to Eleventh Month
               require(specialAddBal[_add].sub(_amountRequested) >= 900000000000000000000000, "Amount exceded lock 5");
           }
            if(block.timestamp > deploymentTime + 8100 && block.timestamp < deploymentTime + 9000){                                        // Eleventh to Twelveth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 720000000000000000000000, "Amount exceded lock 6");
           }
            if(block.timestamp > deploymentTime + 9000 && block.timestamp < deploymentTime + 9900){                                        // Twelveth to Thirteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 540000000000000000000000, "Amount exceded lock 7");
           }
            if(block.timestamp > deploymentTime + 9900 && block.timestamp < deploymentTime + 10800){                                        // Thirteenth to Fourteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 360000000000000000000000, "Amount exceded lock 8");
           }
            if(block.timestamp > deploymentTime + 10800 && block.timestamp < deploymentTime + 11700){                                        // Fourteenth to Fifteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 180000000000000000000000, "Amount exceded lock 9");
           }
         }
          if(_add == Team2){   
           if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 4500){                                          // Sixth to Seventh Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1800000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 4500 && block.timestamp < deploymentTime + 5400){                                         // Seventh to Eighth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1600000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 5400 && block.timestamp < deploymentTime + 6300){                                        // Eighth to Ninth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1400000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 6300 && block.timestamp < deploymentTime + 7200){                                        // Ninth to Tenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1200000000000000000000000, "Amount exceded lock 4");
           }
            if(block.timestamp > deploymentTime + 7200 && block.timestamp < deploymentTime + 8100){                                        // Tenth to Eleventh Month
               require(specialAddBal[_add].sub(_amountRequested) >= 1000000000000000000000000, "Amount exceded lock 5");
           }
            if(block.timestamp > deploymentTime + 8100 && block.timestamp < deploymentTime + 9000){                                        // Eleventh to Twelveth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 800000000000000000000000, "Amount exceded lock 6");
           }
            if(block.timestamp > deploymentTime + 9000 && block.timestamp < deploymentTime + 9900){                                        // Twelveth to Thirteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 600000000000000000000000, "Amount exceded lock 7");
           }
            if(block.timestamp > deploymentTime + 9900 && block.timestamp < deploymentTime + 10800){                                        // Thirteenth to Fourteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 400000000000000000000000, "Amount exceded lock 8");
           }
            if(block.timestamp > deploymentTime + 10800 && block.timestamp < deploymentTime + 11700){                                        // Fourteenth to Fifteenth Month
               require(specialAddBal[_add].sub(_amountRequested) >= 200000000000000000000000, "Amount exceded lock 9");
           }
         }
         if(_add == Partners){ 
            if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 1200){                                                  //One to Four week
               require(specialAddBal[_add].sub(_amountRequested) >= 8000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 1200 && block.timestamp < deploymentTime + 2400){                                           //Four to Six week
               require(specialAddBal[_add].sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 2400 && block.timestamp < deploymentTime + 3600){                                           //Six to Eighth week
               require(specialAddBal[_add].sub(_amountRequested) >= 4000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 4800){                                           //Eighth to Tenth week
               require(specialAddBal[_add].sub(_amountRequested) >= 2000000000000000000000000, "Amount exceded lock 4");
           }
         }
         if(_add == Liquidity){
             if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 1800){                                                   //One to Two Month
               require(specialAddBal[_add].sub(_amountRequested) >= 8000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 1800 && block.timestamp < deploymentTime + 3600){                                            //Two to Three week
               require(specialAddBal[_add].sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 5400){                                            //Three to Four week
               require(specialAddBal[_add].sub(_amountRequested) >= 4000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 5400 && block.timestamp < deploymentTime + 7200){                                            //Four to Fifth week
               require(specialAddBal[_add].sub(_amountRequested) >= 2000000000000000000000000, "Amount exceded lock 4");
           }
         }
        _;
     }
}