/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

//-----------------------------------------------------------------------------//
//                             Name : Operon Origins                           //
//                           Symbol : ORO                                      //
//                     Total Supply : 100,000,000                              //
//                        Liquidity : 10,000,000                               //
//                        Marketing : 23,500,000                               //
//                          Reserve : 17,000,000                               //
//                             Team : 15,000,000                               //
//                         Partners : 5,000,000                                //
//                        SeedRound : 7,500,000                                //
//                             Priv : 16,000,000                               //
//                           Public : 4,000,000                                //
//			                    KOL : 2,000,000                                //
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


 
abstract contract IBUSD{
    function transferFrom(address, address, uint256) public virtual returns(bool);
    function transfer(address, uint256) public pure virtual returns(bool);
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract LGEWhitelisted is Context {
    struct WhitelistRound {
        uint256 duration;
        uint256 amountMax;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }

    WhitelistRound[] public _lgeWhitelistRounds;

    uint256 public _lgeTimestamp;
    address public _lgePairAddress;

    address public _whitelister;

    event WhitelisterTransferred(address indexed previousWhitelister, address indexed newWhitelister);

    constructor() public {
        _whitelister = _msgSender();
    }

    modifier onlyWhitelister() {
        require(_whitelister == _msgSender(), "Caller is not the whitelister");
        _;
    }

    function renounceWhitelister() external onlyWhitelister {
        emit WhitelisterTransferred(_whitelister, address(0));
        _whitelister = address(0);
    }

    function transferWhitelister(address newWhitelister) external onlyWhitelister {
        _transferWhitelister(newWhitelister);
    }

    function _transferWhitelister(address newWhitelister) internal {
        require(newWhitelister != address(0), "New whitelister is the zero address");
        emit WhitelisterTransferred(_whitelister, newWhitelister);
        _whitelister = newWhitelister;
    }

    /*
     * createLGEWhitelist - Call this after initial Token Generation Event (TGE)
     *
     * pairAddress - address generated from createPair() event on DEX
     * durations - array of durations (seconds) for each whitelist rounds
     * amountsMax - array of max amounts (TOKEN decimals) for each whitelist round
     *
     */

    function createLGEWhitelist(
        address pairAddress,
        uint256[] calldata durations,
        uint256[] calldata amountsMax
    ) external onlyWhitelister() {
        require(durations.length == amountsMax.length, "Invalid whitelist(s)");

        _lgePairAddress = pairAddress;

        if (durations.length > 0) {
            delete _lgeWhitelistRounds;

            for (uint256 i = 0; i < durations.length; i++) {
                WhitelistRound storage whitelistRound = _lgeWhitelistRounds.push();
                whitelistRound.duration = durations[i];
                whitelistRound.amountMax = amountsMax[i];
            }
        }
    }

    /*
     * modifyLGEWhitelistAddresses - Define what addresses are included/excluded from a whitelist round
     *
     * index - 0-based index of round to modify whitelist
     * duration - period in seconds from LGE event or previous whitelist round
     * amountMax - max amount (TOKEN decimals) for each whitelist round
     *
     */

    function modifyLGEWhitelist(
        uint256 index,
        uint256 duration,
        uint256 amountMax,
        address[] calldata addresses,
        bool enabled
    ) external onlyWhitelister() {
        require(index < _lgeWhitelistRounds.length, "Invalid index");
        require(amountMax > 0, "Invalid amountMax");

        if (duration != _lgeWhitelistRounds[index].duration) _lgeWhitelistRounds[index].duration = duration;

        if (amountMax != _lgeWhitelistRounds[index].amountMax) _lgeWhitelistRounds[index].amountMax = amountMax;

        for (uint256 i = 0; i < addresses.length; i++) {
            _lgeWhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }

    /*
     *  getLGEWhitelistRound
     *
     *  returns:
     *
     *  1. whitelist round number ( 0 = no active round now )
     *  2. duration, in seconds, current whitelist round is active for
     *  3. timestamp current whitelist round closes at
     *  4. maximum amount a whitelister can purchase in this round
     *  5. is caller whitelisted
     *  6. how much caller has purchased in current whitelist round
     *
     */

    function getLGEWhitelistRound()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        if (_lgeTimestamp > 0) {
            uint256 wlCloseTimestampLast = _lgeTimestamp;

            for (uint256 i = 0; i < _lgeWhitelistRounds.length; i++) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[i];

                wlCloseTimestampLast = wlCloseTimestampLast + wlRound.duration;
                if (block.timestamp <= wlCloseTimestampLast)
                    return (
                        i + 1,
                        wlRound.duration,
                        wlCloseTimestampLast,
                        wlRound.amountMax,
                        wlRound.addresses[_msgSender()],
                        wlRound.purchased[_msgSender()]
                    );
            }
        }

        return (0, 0, 0, 0, false, 0);
    }

    /*
     * _applyLGEWhitelist - internal function to be called initially before any transfers
     *
     */

    function _applyLGEWhitelist(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (_lgePairAddress == address(0) || _lgeWhitelistRounds.length == 0) return;

        if (_lgeTimestamp == 0 && sender != _lgePairAddress && recipient == _lgePairAddress && amount > 0)
            _lgeTimestamp = block.timestamp;

        if (sender == _lgePairAddress && recipient != _lgePairAddress) {
            //buying

            (uint256 wlRoundNumber, , , , , ) = getLGEWhitelistRound();

            if (wlRoundNumber > 0) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[wlRoundNumber - 1];

                require(wlRound.addresses[recipient], "LGE - Buyer is not whitelisted");

                uint256 amountRemaining = 0;

                if (wlRound.purchased[recipient] < wlRound.amountMax)
                    amountRemaining = wlRound.amountMax - wlRound.purchased[recipient];

                require(amount <= amountRemaining, "LGE - Amount exceeds whitelist maximum");
                wlRound.purchased[recipient] = wlRound.purchased[recipient] + amount;
            }
        }
    }
}

contract OperonOrigins is IBEP20, LGEWhitelisted  {
    
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
    mapping (address => uint256) _contributionBUSD;
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
    address public _BUSDAddress;
    uint256 public BUSDPrice;
    bool whitelistFlag = true;
    address private Reserve = 0xc6BBb38478861ff1eA4A729e79DAffa20ad5A18E;
    address private Marketing = 0x7cF44E816070f4E3471F770dF5E4Bde8efB9a0B4;
    address private Team = 0xa67A04b3a6fBF6771c301CcE85b52BbA9e4F504B;
    address private Liquidity = 0x5ecc23447d6669B0139DAbE6E515B9830e0A058B;
    address private Partners = 0x675f640a5c00C875059AF359004F2EA11bA60fC2;
    address private SeedRound = 0x9826DDE3c8529930B92D1068C5d2991f6D648908;
    address private Priv = 0x0AfbBA0CF312Bdee57689ffFfF177cd041B8dB93;
    address private Public = 0x218f8E5f83964e24b1a139482fb080dE820b05F7;
    address private KOL = 0x20c4A785B387bf01456e326dEb11721950fE5a56;
    
    constructor () public {
        _name = "Operon Origins";
        _symbol = "ORO";
        _owner = msg.sender;
        _totalSupply = 100000000*(10**uint256(_decimals));
        _balances[_owner] = _totalSupply;
        _addressLocked[Reserve] = true;
        _addressLocked[Marketing] = true;
        _addressLocked[Team] = true;
        _addressLocked[Liquidity] = true;
         deploymentTime =  block.timestamp;
         initiateValues();
    }
    
    function initiateValues() internal {
        specialAddBal[Reserve] = 17000000*(10**uint256(_decimals));
        specialAddBal[Marketing] = 23500000*(10**uint256(_decimals));
        specialAddBal[Team] = 15000000*(10**uint256(_decimals));
        specialAddBal[Liquidity] = 10000000*(10**uint256(_decimals));
        specialAddBal[Partners] = 5000000*(10**uint256(_decimals));
        specialAddBal[SeedRound] = 7500000*(10**uint256(_decimals));
        specialAddBal[Priv] = 16000000 *(10**uint256(_decimals));
        specialAddBal[Public] = 4000000 *(10**uint256(_decimals));
        specialAddBal[KOL] = 2000000 *(10**uint256(_decimals));

        _transfer(_owner,Reserve,specialAddBal[Reserve]);
        _transfer(_owner,Marketing,specialAddBal[Marketing]);
        _transfer(_owner,Team,specialAddBal[Team]); 
        _transfer(_owner,Liquidity,specialAddBal[Liquidity]);  
        _transfer(_owner,Partners,specialAddBal[Partners]);  
        _transfer(_owner,SeedRound,specialAddBal[SeedRound]);  
        _transfer(_owner,Priv,specialAddBal[Priv]);
        _transfer(_owner,Public,specialAddBal[Public]);
        _transfer(_owner,KOL,specialAddBal[KOL]);
        
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
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() external override view returns (uint256) {
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
    function balanceOf(address owner) public  override view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowed[owner][spender];
    }

    /* ----------------------------------------------------------------------------
     * Transfer, allow and burn functions
     * ----------------------------------------------------------------------------
     */

    //check if special address or not
    modifier checkLockedAddresses(address _lockedAddresses){
           require(_addressLocked[_lockedAddresses] != true, "Locking Address");
       _;
    }

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public  override checkLockedAddresses(msg.sender) returns (bool) {
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
      function airdropByOwner(address[]  calldata _addresses, uint256[]  calldata _amount) external onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          uint256 airdropcount = 0;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount.add(1);
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
        _applyLGEWhitelist(from, to, value);
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
    function approve(address spender, uint256 value) external  override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
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
    function burn(uint256 value) external onlyOwner{
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

    //Set TGE Time
    function setTGE(uint256 _deploymentTime) external onlyOwner returns(bool){
        deploymentTime = _deploymentTime;
        return true;
    }

    /*
     * @dev withdraw special locked tokens for internal team 
     */
    function withdrawSpecialLocked(address _toAddress, uint256 _amount) checkLockingRoles(msg.sender, _amount) external returns(bool){
       _transfer(msg.sender, _toAddress, _amount);
        specialAddBal[msg.sender] = specialAddBal[msg.sender].sub(_amount);
    }
    
    /*
     * @dev Admin can withdraw the bnb  
     */
    function withdrawCurrency(uint256 _amount) external onlyOwner returns(bool){
        msg.sender.transfer(_amount);
        return true;
    }
    
    //check contract block.timestamp time 
    function checkContractTime() external view returns(uint256){
        return block.timestamp;
    }
    
    // to check locked tokens for marketing address, Reserve, Liquidity and Team  
    modifier checkLockingRoles(address _add, uint256 _amountRequested){
        require(_add == Reserve || _add == Marketing || _add == Team || _add == Liquidity , "Only for Special Addresses");
        require(_amountRequested != 0, "amount should be greater than 0");
       if(_add == Reserve){
           require(block.timestamp > deploymentTime+47335374, "Tokens are locked for 18 months from TGE");
         }
       if(_add == Marketing){
           if(block.timestamp > deploymentTime + 3600 && block.timestamp < deploymentTime + 2629743){                                            // First month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 22325000000000000000000000, "Amount exceded lock 1");
           }
           if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 5259486){                                         // Second month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 21150000000000000000000000, "Amount exceded lock 2");
           }
           if(block.timestamp > deploymentTime + 5259486 && block.timestamp < deploymentTime + 7889229){                                         // Third month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 19975000000000000000000000, "Amount exceded lock 3");
           }
           if(block.timestamp > deploymentTime + 7889229 && block.timestamp < deploymentTime + 10518972){                                        // Fourth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 18800000000000000000000000, "Amount exceded lock 4");
           }
           if(block.timestamp > deploymentTime + 10518972 && block.timestamp < deploymentTime + 13148715){                                       // Fifth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 17625000000000000000000000, "Amount exceded lock 5");
           }
           if(block.timestamp > deploymentTime + 13148715 && block.timestamp < deploymentTime + 15778458){                                       // Sixth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 16450000000000000000000000, "Amount exceded lock 6");
           }
           if(block.timestamp > deploymentTime + 15778458 && block.timestamp < deploymentTime + 18408201){                                       // Seventh month from the deployment & 5% 
               require(specialAddBal[_add].sub(_amountRequested) >= 15275000000000000000000000, "Amount exceded lock 7");
           }
           if(block.timestamp > deploymentTime + 18408201 && block.timestamp < deploymentTime + 21037944){                                       // Eighth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 14100000000000000000000000, "Amount exceded lock 8");
           }
           if(block.timestamp > deploymentTime + 21037944 && block.timestamp < deploymentTime + 23667687){                                       // Ninth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 12925000000000000000000000, "Amount exceded lock 9");
           }
           if(block.timestamp > deploymentTime + 23667687 && block.timestamp < deploymentTime + 26297430){                                       // Tenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 11750000000000000000000000, "Amount exceded lock 10");
           }
           if(block.timestamp > deploymentTime + 26297430 && block.timestamp < deploymentTime + 28927173){                                        // Evenenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 10575000000000000000000000, "Amount exceded lock 11");
           }
           if(block.timestamp > deploymentTime + 28927173 && block.timestamp < deploymentTime + 31556916){                                        // Twelveth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 9400000000000000000000000, "Amount exceded lock 12");
           }
           if(block.timestamp > deploymentTime + 31556916 && block.timestamp < deploymentTime + 34186659){                                        // Thirteen month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 8225000000000000000000000, "Amount exceded lock 13");
           }
           if(block.timestamp > deploymentTime + 34186659 && block.timestamp < deploymentTime + 36816402){                                       // Fourteen month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 7050000000000000000000000, "Amount exceded lock 14");
           }
           if(block.timestamp > deploymentTime + 36816402 && block.timestamp < deploymentTime + 39446145){                                       // Fifteenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 5875000000000000000000000, "Amount exceded lock 15");
           }
           if(block.timestamp > deploymentTime + 39446145 && block.timestamp < deploymentTime + 42075888){                                       // Sixteenth month from the deployment & 5% 
               require(specialAddBal[_add].sub(_amountRequested) >= 4700000000000000000000000, "Amount exceded lock 16");
           }
           if(block.timestamp > deploymentTime + 42075888 && block.timestamp < deploymentTime + 44705631){                                       // Seventeenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 3525000000000000000000000, "Amount exceded lock 17");
           }
           if(block.timestamp > deploymentTime + 44705631 && block.timestamp < deploymentTime + 47335374){                                       // Eighteenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 2350000000000000000000000, "Amount exceded lock 18");
           }
           if(block.timestamp > deploymentTime + 47335374 && block.timestamp < deploymentTime + 49965117){                                       // Nineteenth month from the deployment & 5%
               require(specialAddBal[_add].sub(_amountRequested) >= 1175000000000000000000000, "Amount exceded lock 19");
           }
           if(block.timestamp > deploymentTime + 49965117){                      
               require(specialAddBal[_add].sub(_amountRequested) >= 0, "Amount exceded lock 20");
           }
           else{
               require(block.timestamp > deploymentTime + 3600,"Unlock time not reached");
           }
         }
       if(_add == Team){
           if(block.timestamp > deploymentTime + 31556916 && block.timestamp < deploymentTime + 34186659){                                      
               require(specialAddBal[_add].sub(_amountRequested) >= 12000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 34186659 && block.timestamp < deploymentTime + 36816402){                                     
               require(specialAddBal[_add].sub(_amountRequested) >= 9000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 36816402 && block.timestamp < deploymentTime + 39446145){                                    
               require(specialAddBal[_add].sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 39446145 && block.timestamp < deploymentTime + 42075888){                                       
               require(specialAddBal[_add].sub(_amountRequested) >= 3000000000000000000000000, "Amount exceded lock 4");
           }
           if(block.timestamp > deploymentTime + 42075888){                                       
               require(specialAddBal[_add].sub(_amountRequested) >= 0, "Amount exceded lock 4");
           }
           else{
               require(block.timestamp > deploymentTime + 31556916,"Unlock time not reached");
           }
         }

         if(_add == Liquidity){
             if(block.timestamp > deploymentTime && block.timestamp < deploymentTime + 2629743){                                                    
               require(specialAddBal[_add].sub(_amountRequested) >= 9000000000000000000000000, "Amount exceded lock 1");
           }
            if(block.timestamp > deploymentTime + 2629743 && block.timestamp < deploymentTime + 5259486){                                        
               require(specialAddBal[_add].sub(_amountRequested) >= 8000000000000000000000000, "Amount exceded lock 2");
           }
            if(block.timestamp > deploymentTime + 5259486 && block.timestamp < deploymentTime + 7889229){                                         
               require(specialAddBal[_add].sub(_amountRequested) >= 7000000000000000000000000, "Amount exceded lock 3");
           }
            if(block.timestamp > deploymentTime + 7889229 && block.timestamp < deploymentTime + 10518972){                                          
               require(specialAddBal[_add].sub(_amountRequested) >= 6000000000000000000000000, "Amount exceded lock 4");
           }
            if(block.timestamp > deploymentTime + 10518972 && block.timestamp < deploymentTime + 13148715){                                           
               require(specialAddBal[_add].sub(_amountRequested) >= 5000000000000000000000000, "Amount exceded lock 5");
           }
            if(block.timestamp > deploymentTime + 13148715 && block.timestamp < deploymentTime + 15778458){                                            
               require(specialAddBal[_add].sub(_amountRequested) >= 4000000000000000000000000, "Amount exceded lock 6");
           }
            if(block.timestamp > deploymentTime + 15778458 && block.timestamp < deploymentTime + 18408201){                                            
               require(specialAddBal[_add].sub(_amountRequested) >= 3000000000000000000000000, "Amount exceded lock 7");
           }
           if(block.timestamp > deploymentTime + 18408201 && block.timestamp < deploymentTime + 21037944){                                            
               require(specialAddBal[_add].sub(_amountRequested) >= 2000000000000000000000000, "Amount exceded lock 8");
           }
           if(block.timestamp > deploymentTime + 21037944 && block.timestamp < deploymentTime + 23667687){                                            
               require(specialAddBal[_add].sub(_amountRequested) >= 1000000000000000000000000, "Amount exceded lock 9");
           }
         }
        _;
     }
     
    function withdrawPeningTokens(uint256 _amount, uint256 _contractAdd) external onlyOwner returns(bool){
       IBUSD iBUSD;
       iBUSD = IBUSD(_contractAdd);
       iBUSD.transfer(msg.sender, _amount);
       return true;
         
    }
}