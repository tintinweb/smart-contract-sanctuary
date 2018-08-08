pragma solidity ^0.4.23;
    /**
    * @title ERC20Basic
    * @dev Simpler version of ERC20 interface
    * @dev see https://github.com/ethereum/EIPs/issues/179
    */
    contract ERC20Basic {
     function totalSupply() public view returns (uint256);
     function balanceOf(address who) public view returns (uint256);
     function transfer(address to, uint256 value) public returns (bool);
     event Transfer(address indexed from, address indexed to, uint256 value);
   }
    /**
    * @title Ownable
    * @dev The Ownable contract has an owner address, and provides basic authorization control
    * functions, this simplifies the implementation of "user permissions".
    */
    contract Ownable {
     address public owner;
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
      constructor() public {
       owner = msg.sender;
     }
     /**
      * @dev Throws if called by any account other than the owner.
      */
      modifier onlyOwner() {
       require(msg.sender == owner);
       _;
     }
     /**
      * @dev Allows the current owner to transfer control of the contract to a newOwner.
      * @param newOwner The address to transfer ownership to.
      */
      function transferOwnership(address newOwner) public onlyOwner {
       require(newOwner != address(0));
       emit OwnershipTransferred(owner, newOwner);
       owner = newOwner;
     }
   }



    /**
    * @title Pausable
    * @dev Base contract which allows children to implement an emergency stop mechanism.
    */
    contract Pausable is Ownable {
     event Pause();
     event Unpause();

     bool public paused = false;


     /**
      * @dev Modifier to make a function callable only when the contract is not paused.
      */
      modifier whenNotPaused() {
       require(!paused);
       _;
     }

     /**
      * @dev Modifier to make a function callable only when the contract is paused.
      */
      modifier whenPaused() {
       require(paused);
       _;
     }

     /**
      * @dev called by the owner to pause, triggers stopped state
      */
      function pause() onlyOwner whenNotPaused public {
       paused = true;
       emit Pause();
     }

     /**
      * @dev called by the owner to unpause, returns to normal state
      */
      function unpause() onlyOwner whenPaused public {
       paused = false;
       emit Unpause();
     }
   }

    /**
    * @title Whitelist
    * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
    * @dev This simplifies the implementation of "user permissions".
    */
    contract Whitelist is Pausable {
     mapping(address => bool) public whitelist;

     event WhitelistedAddressAdded(address addr);
     event WhitelistedAddressRemoved(address addr);
     /**
      * @dev Throws if called by any account that&#39;s not whitelisted.
      */
      modifier onlyWhitelisted() {
       require(whitelist[msg.sender]);
       _;
     }
     /**
      * @dev add an address to the whitelist
      * @param addr address
      * @return true if the address was added to the whitelist, false if the address was already in the whitelist
      */
      function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
       if (!whitelist[addr]) {
         whitelist[addr] = true;
         emit WhitelistedAddressAdded(addr);
         success = true;
       }
     }
     /**
      * @dev add addresses to the whitelist
      * @param addrs addresses
      * @return true if at least one address was added to the whitelist,
      * false if all addresses were already in the whitelist
      */
      function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
       for (uint256 i = 0; i < addrs.length; i++) {
         if (addAddressToWhitelist(addrs[i])) {
           success = true;
         }
       }
     }
     /**
      * @dev remove an address from the whitelist
      * @param addr address
      * @return true if the address was removed from the whitelist,
      * false if the address wasn&#39;t in the whitelist in the first place
      */
      function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
       if (whitelist[addr]) {
         whitelist[addr] = false;
         emit WhitelistedAddressRemoved(addr);
         success = true;
       }
     }
     /**
      * @dev remove addresses from the whitelist
      * @param addrs addresses
      * @return true if at least one address was removed from the whitelist,
      * false if all addresses weren&#39;t in the whitelist in the first place
      */
      function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
       for (uint256 i = 0; i < addrs.length; i++) {
         if (removeAddressFromWhitelist(addrs[i])) {
           success = true;
         }
       }
     }
   }
    /**
    * @title ERC20 interface
    * @dev see https://github.com/ethereum/EIPs/issues/20
    */
    contract ERC20 is ERC20Basic {
     function allowance(address owner, address spender) public view returns (uint256);
     function transferFrom(address from, address to, uint256 value) public returns (bool);
     function approve(address spender, uint256 value) public returns (bool);
     event Approval(address indexed owner, address indexed spender, uint256 value);
   }
    /**
    * @title SafeMath
    * @dev Math operations with safety checks that throw on error
    */
    library SafeMath {
     /**
     * @dev Multiplies two numbers, throws on overflow.
     */
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
         return 0;
       }
       uint256 c = a * b;
       assert(c / a == b);
       return c;
     }
     /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
       // assert(b > 0); // Solidity automatically throws when dividing by 0
       uint256 c = a / b;
       // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
       return c;
     }
     /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       assert(b <= a);
       return a - b;
     }
     /**
     * @dev Adds two numbers, throws on overflow.
     */
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       assert(c >= a);
       return c;
     }
   }
    /**
    * @title Crowdsale
    * @dev Crowdsale is a base contract for managing a token crowdsale,
    * allowing investors to purchase tokens with ether. This contract implements
    * such functionality in its most fundamental form and can be extended to provide additional
    * functionality and/or custom behavior.
    * The external interface represents the basic interface for purchasing tokens, and conform
    * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
    * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
    * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
    * behavior.
    */
    contract Crowdsale is Whitelist{
     using SafeMath for uint256;
     // The token being sold
     MiniMeToken public token;
     // Address where funds are collected
     address public wallet;
     // How many token units a buyer gets per wei
     uint256 public rate = 6120;
     // Amount of tokens sold
     uint256 public tokensSold;
    //Star of the crowdsale
     uint256 startTime;



     /**
      * Event for token purchase logging
      * @param purchaser who paid for the tokens
      * @param beneficiary who got the tokens
      * @param value weis paid for purchase
      * @param amount amount of tokens purchased
      */
      event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

      event buyx(address buyer, address contractAddr, uint256 amount);

      constructor(address _wallet, MiniMeToken _token, uint256 starttime) public{

       require(_wallet != address(0));
       require(_token != address(0));

       wallet = _wallet;
       token = _token;
       startTime = starttime;
     }
     function setCrowdsale(address _wallet, MiniMeToken _token, uint256 starttime) public{


       require(_wallet != address(0));
       require(_token != address(0));

       wallet = _wallet;
       token = _token;
       startTime = starttime;
     }



     // -----------------------------------------
     // Crowdsale external interface
     // -----------------------------------------
     /**
      *  fallback function ***DO NOT OVERRIDE***
      */
      function () external whenNotPaused payable {
        emit buyx(msg.sender, this, _getTokenAmount(msg.value));
        buyTokens(msg.sender);
      }
     /**
      * @dev low level token purchase ***DO NOT OVERRIDE***
      * @param _beneficiary Address performing the token purchase
      */
     function buyTokens(address _beneficiary) public whenNotPaused payable {
      
       if ((tokensSold > 20884500000000000000000000 ) && (tokensSold <= 30791250000000000000000000)) {
         rate = 5967;
       }
       else if ((tokensSold > 30791250000000000000000000) && (tokensSold <= 39270000000000000000000000)) {
        rate = 5865;
       }
       else if ((tokensSold > 39270000000000000000000000) && (tokensSold <= 46856250000000000000000000)) {
        rate = 5610;
       }
       else if ((tokensSold > 46856250000000000000000000) && (tokensSold <= 35700000000000000000000000)) {
        rate = 5355;
       }
       else if (tokensSold > 35700000000000000000000000) {
        rate = 5100;
       }


      uint256 weiAmount = msg.value;
      uint256 tokens = _getTokenAmount(weiAmount);
      tokensSold = tokensSold.add(tokens);
      _processPurchase(_beneficiary, tokens);
      emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
      _updatePurchasingState(_beneficiary, weiAmount);
      _forwardFunds();
      _postValidatePurchase(_beneficiary, weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------



     /**
      * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
      * @param _beneficiary Address performing the token purchase
      * @param _weiAmount Value in wei involved in the purchase
      */
      function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
       require(_beneficiary != address(0));
       require(_weiAmount != 0);
     }
     /**
      * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
      * @param _beneficiary Address performing the token purchase
      * @param _weiAmount Value in wei involved in the purchase
      */
      function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
       // optional override
     }
     /**
      * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
      * @param _beneficiary Address performing the token purchase
      * @param _tokenAmount Number of tokens to be emitted
      */
      function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
       token.transfer(_beneficiary, _tokenAmount);
     }
     /**
      * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
      * @param _beneficiary Address receiving the tokens
      * @param _tokenAmount Number of tokens to be purchased
      */
      function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
       _deliverTokens(_beneficiary, _tokenAmount);
     }
     /**
      * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
      * @param _beneficiary Address receiving the tokens
      * @param _weiAmount Value in wei involved in the purchase
      */
      function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
       // optional override
     }
     /**
      * @dev Override to extend the way in which ether is converted to tokens.
      * @param _weiAmount Value in wei to be converted into tokens
      * @return Number of tokens that can be purchased with the specified _weiAmount
      */
      function _getTokenAmount(uint256 _weiAmount) internal  returns (uint256) {

       return _weiAmount.mul(rate);
     }

     /**
      * @dev Determines how ETH is stored/forwarded on purchases.
      */
      function _forwardFunds() internal {
       wallet.transfer(msg.value);
     }

   }



   contract EmaCrowdSale is Crowdsale {
    uint256 public hardcap;
    uint256 public starttime;
    Crowdsale public csale;
    using SafeMath for uint256; 
    constructor(address wallet, MiniMeToken token, uint256 startTime, uint256 cap) Crowdsale(wallet, token, starttime) public onlyOwner
    {

      hardcap = cap;
      starttime = startTime;
      setCrowdsale(wallet, token, startTime);
    }

function tranferPresaleTokens(address investor, uint256 ammount)public onlyOwner{
    tokensSold = tokensSold.add(ammount); 
    token.transferFrom(this, investor, ammount); 
}

    function setTokenTransferState(bool state) public onlyOwner {
     token.changeController(this);
     token.enableTransfers(state);
   }

   function claim(address claimToken) public onlyOwner {
     token.changeController(this);
     token.claimTokens(claimToken);
   }

   function () external payable onlyWhitelisted whenNotPaused{

    emit buyx(msg.sender, this, _getTokenAmount(msg.value));

    buyTokens(msg.sender);
  }


}






contract Controlled is Pausable {
 /// @notice The address of the controller is the only address that can call
 ///  a function with this modifier
 modifier onlyController { require(msg.sender == controller); _; }
 modifier onlyControllerorOwner { require((msg.sender == controller) || (msg.sender == owner)); _; }
 address public controller;
 constructor() public { controller = msg.sender;}
 /// @notice Changes the controller of the contract
 /// @param _newController The new controller of the contract
 function changeController(address _newController) public onlyControllerorOwner {
   controller = _newController;
 }
}
/// @dev The token controller contract must implement these functions
contract TokenController {
 /// @notice Called when `_owner` sends ether to the MiniMe Token contract
 /// @param _owner The address that sent the ether to create tokens
 /// @return True if the ether is accepted, false if it throws
 function proxyPayment(address _owner) public payable returns(bool);
 /// @notice Notifies the controller about a token transfer allowing the
 ///  controller to react if desired
 /// @param _from The origin of the transfer
 /// @param _to The destination of the transfer
 /// @param _amount The amount of the transfer
 /// @return False if the controller does not authorize the transfer
 function onTransfer(address _from, address _to, uint _amount) public returns(bool);
 /// @notice Notifies the controller about an approval allowing the
 ///  controller to react if desired
 /// @param _owner The address that calls `approve()`
 /// @param _spender The spender in the `approve()` call
 /// @param _amount The amount in the `approve()` call
 /// @return False if the controller does not authorize the approval
 function onApprove(address _owner, address _spender, uint _amount) public
 returns(bool);
}
    /*
       Copyright 2016, Jordi Baylina
       This program is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
       This program is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
       You should have received a copy of the GNU General Public License
       along with this program.  If not, see <http://www.gnu.org/licenses/>.
       */
       /// @title MiniMeToken Contract
       /// @author Jordi Baylina
       /// @dev This token contract&#39;s goal is to make it easy for anyone to clone this
       ///  token using the token distribution at a given block, this will allow DAO&#39;s
       ///  and DApps to upgrade their features in a decentralized manner without
       ///  affecting the original token
       /// @dev It is ERC20 compliant, but still needs to under go further testing.
       contract ApproveAndCallFallBack {
         function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
       }
       /// @dev The actual token contract, the default controller is the msg.sender
       ///  that deploys the contract, so usually this token will be deployed by a
       ///  token controller contract, which Giveth will call a "Campaign"
       contract MiniMeToken is Controlled
       {
         using SafeMath for uint256;
         string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
         uint8 public decimals;             //Number of decimals of the smallest unit
         string public symbol;              //An identifier: e.g. REP
         string public version = &#39;V 1.0&#39;; //An arbitrary versioning scheme
         /// @dev `Checkpoint` is the structure that attaches a block number to a
         ///  given value, the block number attached is the one that last changed the
         ///  value
         struct  Checkpoint {
           // `fromBlock` is the block number that the value was generated from
           uint128 fromBlock;
           // `value` is the amount of tokens at a specific block number
           uint128 value;
         }
         // `parentToken` is the Token address that was cloned to produce this token;
         //  it will be 0x0 for a token that was not cloned
         MiniMeToken public parentToken;
         // `parentSnapShotBlock` is the block number from the Parent Token that was
         //  used to determine the initial distribution of the Clone Token
         uint public parentSnapShotBlock;
         // `creationBlock` is the block number that the Clone Token was created
         uint public creationBlock;
         // `balances` is the map that tracks the balance of each address, in this
         //  contract when the balance changes the block number that the change
         //  occurred is also included in the map
         mapping (address => Checkpoint[]) balances;
         // `allowed` tracks any extra transfer rights as in all ERC20 tokens
         mapping (address => mapping (address => uint256)) allowed;
         // Tracks the history of the `totalSupply` of the token
         Checkpoint[] totalSupplyHistory;
         // Flag that determines if the token is transferable or not.
         bool public transfersEnabled;
         // The factory used to create new clone tokens
         MiniMeTokenFactory public tokenFactory;
         ////////////////
         // Constructor
         ////////////////
         /// @notice Constructor to create a MiniMeToken
         /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
         ///  will create the Clone token contracts, the token factory needs to be
         ///  deployed first
         /// @param _parentToken Address of the parent token, set to 0x0 if it is a
         ///  new token
         /// @param _parentSnapShotBlock Block of the parent token that will
         ///  determine the initial distribution of the clone token, set to 0 if it
         ///  is a new token
         /// @param _tokenName Name of the new token
         /// @param _decimalUnits Number of decimals of the new token
         /// @param _tokenSymbol Token Symbol for the new token
         /// @param _transfersEnabled If true, tokens will be able to be transferred
         constructor(
           address _tokenFactory,
           address _parentToken,
           uint _parentSnapShotBlock,
           string _tokenName,
           uint8 _decimalUnits,
           string _tokenSymbol,
           bool _transfersEnabled
           ) public {
           tokenFactory = MiniMeTokenFactory(_tokenFactory);
           name = _tokenName;                                 // Set the name
           decimals = _decimalUnits;                          // Set the decimals
           symbol = _tokenSymbol;                             // Set the symbol
           parentToken = MiniMeToken(_parentToken);
           parentSnapShotBlock = _parentSnapShotBlock;
           transfersEnabled = _transfersEnabled;
           creationBlock = block.number;
         }
         ///////////////////
         // ERC20 Methods
         ///////////////////
         /// @notice Send `_amount` tokens to `_to` from `msg.sender`
         /// @param _to The address of the recipient
         /// @param _amount The amount of tokens to be transferred
         /// @return Whether the transfer was successful or not
         function transfer(address _to, uint256 _amount) public returns (bool success)  {
           require(transfersEnabled);
           doTransfer(msg.sender, _to, _amount);
           return true;
         }
         /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
         ///  is approved by `_from`
         /// @param _from The address holding the tokens being transferred
         /// @param _to The address of the recipient
         /// @param _amount The amount of tokens to be transferred
         /// @return True if the transfer was successful
         function transferFrom(address _from, address _to, uint256 _amount
           ) public  returns (bool success) {
           // The controller of this contract can move tokens around at will,
           //  this is important to recognize! Confirm that you trust the
           //  controller of this contract, which in most situations should be
           //  another open source smart contract or 0x0
           if (msg.sender != controller) {
             require(transfersEnabled);
             // The standard ERC 20 transferFrom functionality
             require(allowed[_from][msg.sender] >= _amount);
             allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
           }
           doTransfer(_from, _to, _amount);
           return true;
         }

         /// @dev This is the actual transfer function in the token contract, it can
         ///  only be called by other functions in this contract.
         /// @param _from The address holding the tokens being transferred
         /// @param _to The address of the recipient
         /// @param _amount The amount of tokens to be transferred
         /// @return True if the transfer was successful
         function doTransfer(address _from, address _to, uint _amount
           ) internal {
          if (_amount == 0) {
            emit Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
            return;
          }

          // Do not allow transfer to 0x0 or the token contract itself
          require((_to != 0) && (_to != address(this)));
          // If the amount being transfered is more than the balance of the
          //  account the transfer throws
          uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
          require(previousBalanceFrom >= _amount);
          //  sending the tokens
          updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
          // Then update the balance array with the new value for the address
          //  receiving the tokens
          uint256 previousBalanceTo = balanceOfAt(_to, block.number);
          require(previousBalanceTo.add(_amount) >= previousBalanceTo); // Check for overflow
          updateValueAtNow(balances[_to], previousBalanceTo.add(_amount));
          // An event to make the transfer easy to find on the blockchain
          emit Transfer(_from, _to, _amount);
        }
        /// @param _owner The address that&#39;s balance is being requested
        /// @return The balance of `_owner` at the current block
        function balanceOf(address _owner) public constant returns (uint256 balance) {
         return balanceOfAt(_owner, block.number);
       }
       /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
       ///  its behalf. This is a modified version of the ERC20 approve function
       ///  to be a little bit safer
       /// @param _spender The address of the account able to transfer the tokens
       /// @param _amount The amount of tokens to be approved for transfer
       /// @return True if the approval was successful
       function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        //  Alerts the token controller of the approve function call
        if (isContract(controller)) {
         require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
       }
       allowed[msg.sender][_spender] = _amount;
       emit Approval(msg.sender, _spender, _amount);
       return true;
     }
     /// @dev This function makes it easy to read the `allowed[]` map
     /// @param _owner The address of the account that owns the token
     /// @param _spender The address of the account able to transfer the tokens
     /// @return Amount of remaining tokens of _owner that _spender is allowed
     ///  to spend
     function allowance(address _owner, address _spender
       ) public constant returns (uint256 remaining) {
       return allowed[_owner][_spender];
     }
     /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     ///  its behalf, and then a function is triggered in the contract that is
     ///  being approved, `_spender`. This allows users to use their tokens to
     ///  interact with contracts in one function call instead of two
     /// @param _spender The address of the contract able to transfer the tokens
     /// @param _amount The amount of tokens to be approved for transfer
     /// @return True if the function call was successful
     function approveAndCall(address _spender, uint256 _amount, bytes _extraData
       ) public returns (bool success) {
       require(approve(_spender, _amount));
       ApproveAndCallFallBack(_spender).receiveApproval(
         msg.sender,
         _amount,
         this,
         _extraData
         );
       return true;
     }
     /// @dev This function makes it easy to get the total number of tokens
     /// @return The total number of tokens
     function totalSupply() public constant returns (uint) {
       return totalSupplyAt(block.number);
     }
     ////////////////
     // Query balance and totalSupply in History
     ////////////////
     /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
     /// @param _owner The address from which the balance will be retrieved
     /// @param _blockNumber The block number when the balance is queried
     /// @return The balance at `_blockNumber`
     function balanceOfAt(address _owner, uint _blockNumber) public constant
     returns (uint) {
       // These next few lines are used when the balance of the token is
       //  requested before a check point was ever created for this token, it
       //  requires that the `parentToken.balanceOfAt` be queried at the
       //  genesis block for that token as this contains initial balance of
       //  this token
       if ((balances[_owner].length == 0)
         || (balances[_owner][0].fromBlock > _blockNumber)) {
         if (address(parentToken) != 0) {
           return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
           } else {
             // Has no parent
             return 0;
           }
           // This will return the expected balance during normal situations
           } else {
             return getValueAt(balances[_owner], _blockNumber);
           }
         }
         /// @notice Total amount of tokens at a specific `_blockNumber`.
         /// @param _blockNumber The block number when the totalSupply is queried
         /// @return The total amount of tokens at `_blockNumber`
         function totalSupplyAt(uint _blockNumber) public constant returns(uint) {
           // These next few lines are used when the totalSupply of the token is
           //  requested before a check point was ever created for this token, it
           //  requires that the `parentToken.totalSupplyAt` be queried at the
           //  genesis block for this token as that contains totalSupply of this
           //  token at this block number.
           if ((totalSupplyHistory.length == 0)
             || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
             if (address(parentToken) != 0) {
               return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
               } else {
                 return 0;
               }
               // This will return the expected totalSupply during normal situations
               } else {
                 return getValueAt(totalSupplyHistory, _blockNumber);
               }
             }
             
             ////////////////
             // Generate and destroy tokens
             ////////////////
             /// @notice Generates `_amount` tokens that are assigned to `_owner`
             /// @param _owner The address that will be assigned the new tokens
             /// @param _amount The quantity of tokens generated
             /// @return True if the tokens are generated correctly
             function generateTokens(address _owner, uint _amount
               ) public onlyControllerorOwner whenNotPaused  returns (bool) {
               uint curTotalSupply = totalSupply();
               require(curTotalSupply.add(_amount) >= curTotalSupply); // Check for overflow
               uint previousBalanceTo = balanceOf(_owner);
               require(previousBalanceTo.add(_amount) >= previousBalanceTo); // Check for overflow
               updateValueAtNow(totalSupplyHistory, curTotalSupply.add(_amount));
               updateValueAtNow(balances[_owner], previousBalanceTo.add(_amount));
               emit Transfer(0, _owner, _amount);
               return true;
             }
             /// @notice Burns `_amount` tokens from `_owner`
             /// @param _owner The address that will lose the tokens
             /// @param _amount The quantity of tokens to burn
             /// @return True if the tokens are burned correctly
             function destroyTokens(address _owner, uint _amount
               ) onlyControllerorOwner public returns (bool) {
               uint curTotalSupply = totalSupply();
               require(curTotalSupply >= _amount);
               uint previousBalanceFrom = balanceOf(_owner);
               require(previousBalanceFrom >= _amount);
               updateValueAtNow(totalSupplyHistory, curTotalSupply.sub(_amount));
               updateValueAtNow(balances[_owner], previousBalanceFrom.sub(_amount));
               emit Transfer(_owner, 0, _amount);
               return true;
             }
             ////////////////
             // Enable tokens transfers
             ////////////////
             /// @notice Enables token holders to transfer their tokens freely if true
             /// @param _transfersEnabled True if transfers are allowed in the clone
             function enableTransfers(bool _transfersEnabled) public onlyControllerorOwner {
               transfersEnabled = _transfersEnabled;
             }
             ////////////////
             // Internal helper functions to query and set a value in a snapshot array
             ////////////////
             /// @dev `getValueAt` retrieves the number of tokens at a given block number
             /// @param checkpoints The history of values being queried
             /// @param _block The block number to retrieve the value at
             /// @return The number of tokens being queried
             function getValueAt(Checkpoint[] storage checkpoints, uint _block
               ) constant internal returns (uint) {
               if (checkpoints.length == 0) return 0;
               // Shortcut for the actual value
               if (_block >= checkpoints[checkpoints.length.sub(1)].fromBlock)
               return checkpoints[checkpoints.length.sub(1)].value;
               if (_block < checkpoints[0].fromBlock) return 0;
               // Binary search of the value in the array
               uint min = 0;
               uint max = checkpoints.length.sub(1);
               while (max > min) {
                 uint mid = (max.add(min).add(1)).div(2);
                 if (checkpoints[mid].fromBlock<=_block) {
                   min = mid;
                   } else {
                     max = mid.sub(1);
                   }
                 }
                 return checkpoints[min].value;
               }
               /// @dev `updateValueAtNow` used to update the `balances` map and the
               ///  `totalSupplyHistory`
               /// @param checkpoints The history of data being updated
               /// @param _value The new number of tokens
               function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
                 ) internal  {
                 if ((checkpoints.length == 0)
                   || (checkpoints[checkpoints.length.sub(1)].fromBlock < block.number)) {
                  Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
                  newCheckPoint.fromBlock =  uint128(block.number);
                  newCheckPoint.value = uint128(_value);
                  } else {
                    Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length.sub(1)];
                    oldCheckPoint.value = uint128(_value);
                  }
                }
                /// @dev Internal function to determine if an address is a contract
                /// @param _addr The address being queried
                /// @return True if `_addr` is a contract
                function isContract(address _addr) constant internal returns(bool) {
                 uint size;
                 if (_addr == 0) return false;
                 assembly {
                   size := extcodesize(_addr)
                 }
                 return size>0;
               }
               /// @dev Helper function to return a min betwen the two uints
               function min(uint a, uint b) pure internal returns (uint) {
                 return a < b ? a : b;
               }
               /// @notice The fallback function: If the contract&#39;s controller has not been
               ///  set to 0, then the `proxyPayment` method is called which relays the
               ///  ether and creates tokens as described in the token controller contract
               function () public payable {
           /*require(isContract(controller));
           require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));*/
           revert();
         }
         //////////
         // Safety Methods
         //////////
         /// @notice This method can be used by the controller to extract mistakenly
         ///  sent tokens to this contract.
         /// @param _token The address of the token contract that you want to recover
         ///  set to 0 in case you want to extract ether.
         function claimTokens(address _token) public onlyControllerorOwner {
           if (_token == 0x0) {
             controller.transfer(address(this).balance);
             return;
           }
           MiniMeToken token = MiniMeToken(_token);
           uint balance = token.balanceOf(this);
           token.transfer(controller, balance);
           emit ClaimedTokens(_token, controller, balance);
         }
         ////////////////
         // Events
         ////////////////
         event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
         event Transfer(address indexed _from, address indexed _to, uint256 _amount);
         event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
         event Approval(
           address indexed _owner,
           address indexed _spender,
           uint256 _amount
           );
       }
       ////////////////
       // MiniMeTokenFactory
       ////////////////
       /// @dev This contract is used to generate clone contracts from a contract.
       ///  In solidity this is the way to create a contract from a contract of the
       ///  same class
       contract MiniMeTokenFactory {
         /// @notice Update the DApp by creating a new token with new functionalities
         ///  the msg.sender becomes the controller of this clone token
         /// @param _parentToken Address of the token being cloned
         /// @param _snapshotBlock Block of the parent token that will
         ///  determine the initial distribution of the clone token
         /// @param _tokenName Name of the new token
         /// @param _decimalUnits Number of decimals of the new token
         /// @param _tokenSymbol Token Symbol for the new token
         /// @param _transfersEnabled If true, tokens will be able to be transferred
         /// @return The address of the new token contract
         function createCloneToken(
           address _parentToken,
           uint _snapshotBlock,
           string _tokenName,
           uint8 _decimalUnits,
           string _tokenSymbol,
           bool _transfersEnabled
           ) public returns (MiniMeToken) {
           MiniMeToken newToken = new MiniMeToken(
             this,
             _parentToken,
             _snapshotBlock,
             _tokenName,
             _decimalUnits,
             _tokenSymbol,
             _transfersEnabled
             );
           newToken.changeController(msg.sender);
           return newToken;
         }
       }

       contract EmaToken is MiniMeToken {
        constructor(address tokenfactory, address parenttoken, uint parentsnapshot, string tokenname, uint8 dec, string tokensymbol, bool transfersenabled)
        MiniMeToken(tokenfactory, parenttoken, parentsnapshot, tokenname, dec, tokensymbol, transfersenabled) public{
        }
      }
      contract Configurator is Ownable {
        EmaToken public token = EmaToken(0xC3EE57Fa8eD253E3F214048879977265967AE745);
        EmaCrowdSale public crowdsale = EmaCrowdSale(0xAd97aF045F815d91621040809F863a5fb070B52d);
        address ownerWallet = 0x3046751e1d843748b4983D7bca58ECF6Ef1e5c77;
        address tokenfactory = 0xB74AA356913316ce49626527AE8543FFf23bB672;
        address fundsWallet = 0x3046751e1d843748b4983D7bca58ECF6Ef1e5c77;
        address incetivesPool = 0x95eac65414a6a650E2c71e3480AeEF0cF76392FA;
        address FoundersAndTeam = 0x88C952c4A8fc156b883318CdA8b4a5279d989391;
        address FuturePartners = 0x5B0333399E0D8F3eF1e5202b4eA4ffDdFD7a0382;
        address Contributors = 0xa02dfB73de485Ebd9d37CbA4583e916F3bA94CeE;
        address BountiesWal = 0xaB662f89A2c6e71BD8c7f754905cAaEC326BcdE7;
        uint256 public crowdSaleStart;


        function deploy() onlyOwner public{
 	    owner = msg.sender; 
	    
	  
	//	crowdsale.transferOwnership(ownerWallet);
	//	token.transferOwnership(ownerWallet);
	//	token.changeController(this);
		token.generateTokens(crowdsale, 255000000000000000000000000); // Generate CrowdSale tokens
		token.generateTokens(incetivesPool, 115000000000000000000000000); //generate Incentives pool tokens
		token.generateTokens(FoundersAndTeam, 85000000000000000000000000); //generate Founders and team tokens
		token.generateTokens(FuturePartners, 40000000000000000000000000); //generate future partners tokens and contributors
		token.generateTokens(BountiesWal, 5000000000000000000000000); //generate contributors tokens
		token.changeController(EmaCrowdSale(crowdsale));
			token.transferOwnership(ownerWallet);
			crowdsale.transferOwnership(ownerWallet);
        }
      }