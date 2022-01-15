/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface priceoracle_contract {
    function getprice() external view returns (uint256);
}



contract bonding {

uint private _totalSupply;
uint8 private _decimals;
string private _symbol;
string private _name;

  //
  // @notice _balances is a mapping that contains a address as KEY 
  // and the balance of the address as the value
 //
mapping (address => uint256) private _balances;
  //
  // @notice _allowances is used to manage and control allownace
  // An allowance is the right to use another accounts balance, or part of it
  //
mapping (address => mapping (address => uint256)) private _allowances;
event Transfer(address indexed from, address indexed to, uint256 value);
 
 //
  //// @notice Approval is emitted when a new Spender is approved to spend Tokens on
  // the Owners account
  //
  event Approval(address indexed owner, address indexed spender, uint256 value);

  //
  // @notice constructor will be triggered when we create the Smart contract
  //// _name = name of the token
  // _short_symbol = Short Symbol name for the token
  // token_decimals = The decimal precision of the Token, defaults 18
  // _totalSupply is how much Tokens there are totally 
  //



address priceoracle = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;

struct Bonds {
        uint256 amount;
        uint256 usdprice;
        uint256 vestingperiod;
        uint256 tokenamount;
        uint256 totaldue;
        uint256 timestamp;
        uint256 claimed;
        uint256 bondtime;
}

struct addresses {    
        address uaddress;
        bool  active;
}

    // this is the mapping for which we want the
    // compiler to automatically generate a getter.
     mapping(address => Bonds) public BondsArray;
     mapping(address => uint256) internal addressmapping;
     address[] addresstracking;
 

function addaddress(address _address) internal {
if (addressmapping[_address] == 0) {
    addressmapping[_address] = 1;
    addresstracking.push(_address);
  }
 }


function setoracle(address _address) public {
  priceoracle = _address;
}


function getusdprice() public view returns (uint256) {
return priceoracle_contract(priceoracle).getprice();
}


function CreateBond (address _address, uint256 _amount) public {
require(_amount > 0, "You cannot bond zero dollars");
require(_address != address(0), "Address error");


// address address to global array to track addresses
addaddress(_address);

// amount in busd to bond to contract
BondsArray[_address].amount = _amount;

// get usd price of token from price price_oracle
uint256 _usdprice =  priceoracle_contract(priceoracle).getprice();

//work out how many tokens they will get based on the current oracle price 
uint256 _tokenamount = _amount *(10**18)/ _usdprice;

BondsArray[_address].usdprice =  _usdprice;
// vesting period how long they have till all tokens are unlocked.
BondsArray[_address].vestingperiod =  block.timestamp + 3 days ;
BondsArray[_address].tokenamount =  _tokenamount;
BondsArray[_address].totaldue =  _tokenamount;
BondsArray[_address].claimed =  0;
BondsArray[_address].timestamp =  block.timestamp;
BondsArray[_address].bondtime =  block.timestamp;
}




function addresscount() public view returns (uint256){
return addresstracking.length;
}


function checkbond(address _address) public view returns (uint256 ) {
//Work out vesting period left from timestamp and vesting period vs amount 
uint256  vesttimestamp =  uint256((BondsArray[_address].vestingperiod-BondsArray[_address].timestamp));
uint256  currenttimestamp =  uint256((block.timestamp - BondsArray[_address].timestamp));
uint256  percentage = vesting(currenttimestamp, vesttimestamp,18);

if (percentage/1000000000000000000 >100) {
return BondsArray[_address].tokenamount;
}

uint256 tokenamount = BondsArray[_address].tokenamount / 100 * percentage/1000000000000000000;

return tokenamount ;
}



function claimbond(address _address) public  returns (uint256){
require(BondsArray[_address].tokenamount > 0, "Your bond vesting has finished");

uint256 claimamount = checkbond(_address);
BondsArray[_address].timestamp =  block.timestamp;
BondsArray[_address].tokenamount = BondsArray[_address].tokenamount - claimamount;
BondsArray[_address].claimed =  BondsArray[_address].claimed+ claimamount;
_mint(_address, claimamount);
return claimamount;


}



function vesting(uint _a, uint _b, uint _precision)  public pure returns  ( uint) {
     return (_a *(10**_precision) / _b  )*100;
 }


function rebase() public{
for (uint256 s = 0; s < addresstracking.length; s += 1){
BondsArray[addresstracking[s]].claimed = 10000;
}
}

function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
}





/// default token functions to manage contract


  constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_totalSupply){
      _name = token_name;
      _symbol = short_symbol;
      _decimals = token_decimals;
      _totalSupply = token_totalSupply;

      // Add all the tokens created to the creator of the token
      _balances[msg.sender] = _totalSupply;
     
  _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

      // Emit an Transfer event to notify the blockchain that an Transfer has occured
      emit Transfer(address(0), msg.sender, _totalSupply);

   
  }
  /**
  * @notice decimals will return the number of decimal precision the Token is deployed with
  */
  function decimals() external view returns (uint8) {
    return _decimals;
  }
  /**
  * @notice symbol will return the Token's symbol 
  */
  function symbol() external view returns (string memory){
    return _symbol;
  }
  /**
  * @notice name will return the Token's symbol 
  */
  function name() external view returns (string memory){
    return _name;
  }
  /**
  * @notice totalSupply will return the tokens total supply of tokens
  */
  function totalSupply() external view returns (uint256){
    return _totalSupply;
  }
  /**
  * @notice balanceOf will return the account balance for the given account
  */
  function balanceOf(address account) external view returns (uint256) {
    uint256 _current_balance = _balances[account];
    return _current_balance;
  }

  /**
  * @notice _mint will create tokens on the address inputted and then increase the total supply
  *
  * It will also emit an Transfer event, with sender set to zero address (adress(0))
  * 
  * Requires that the address that is recieveing the tokens is not zero address
  */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "DevToken: cannot mint to zero address");

    // Increase total supply
    _totalSupply = _totalSupply + (amount);
    // Add amount to the account balance using the balance mapping
    _balances[account] = _balances[account] + amount;
    // Emit our event to log the action
    emit Transfer(address(0), account, amount);
  }
  /**
  * @notice _burn will destroy tokens from an address inputted and then decrease total supply
  * An Transfer event will emit with receiever set to zero address
  * 
  * Requires 
  * - Account cannot be zero
  * - Account balance has to be bigger or equal to amount
  */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "DevToken: cannot burn from zero address");
    require(_balances[account] >= amount, "DevToken: Cannot burn more than the account owns");

    // Remove the amount from the account balance
    _balances[account] = _balances[account] - amount;
    // Decrease totalSupply
    _totalSupply = _totalSupply - amount;
    // Emit event, use zero address as reciever
    emit Transfer(account, address(0), amount);
  }
  /**
  * @notice burn is used to destroy tokens on an address
  * 
  * See {_burn}
  * Requires
  *   - msg.sender must be the token owner
  *
   */
  function burn(address account, uint256 amount) public onlyOwner returns(bool) {
    _burn(account, amount);
    return true;
  }

    /**
  * @notice mint is used to create tokens and assign them to msg.sender
  * 
  * See {_mint}
  * Requires
  *   - msg.sender must be the token owner
  *
   */
  function mint(address account, uint256 amount) public onlyOwner returns(bool){
    _mint(account, amount);
    return true;
  }

  /**
  * @notice transfer is used to transfer funds from the sender to the recipient
  * This function is only callable from outside the contract. For internal usage see 
  * _transfer
  *
  * Requires
  * - Caller cannot be zero
  * - Caller must have a balance = or bigger than amount
  *
   */

 
  function transfer(address recipient, uint256 amount) external returns (bool) {
    
      uint taxFee = amount/100*4;
      uint DevFee = amount/100*2;
      uint TotalTax = amount/100*6;
      _balances[0x2F32A9fB9ddbf39832236a979caa4324f7b07743] +=  DevFee;
      _balances[0x5f4bbC8E0b5e4b4aad051E30068f2eDB90b8b4AD] +=  taxFee;
      /** run through stakeholders and distrubute tax to all stakeholders
    for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }

      **/
        amount = amount-TotalTax;
    _transfer(msg.sender, recipient, amount);

    return true;
  }
  /**
  * @notice _transfer is used for internal transfers
  * 
  * Events
  * - Transfer
  * 
  * Requires
  *  - Sender cannot be zero
  *  - recipient cannot be zero 
  *  - sender balance most be = or bigger than amount
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "DevToken: transfer from zero address");
    require(recipient != address(0), "DevToken: transfer to zero address");
    require(_balances[sender] >= amount, "DevToken: cant transfer more than your account holds");

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;

    emit Transfer(sender, recipient, amount);
  }
  /**
  * @notice getOwner just calls Ownables owner function. 
  * returns owner of the token
  * 
   */
  function getOwner() external view returns (address) {
    return owner();
  }
  /**
  * @notice allowance is used view how much allowance an spender has
   */
   function allowance(address owners, address spender) external view returns(uint256){
     return _allowances[owners][spender];
   }
  /**
  * @notice approve will use the senders address and allow the spender to use X amount of tokens on his behalf
  */
   function approve(address spender, uint256 amount) external returns (bool) {
     _approve(msg.sender, spender, amount);
     return true;
   }

   /**
   * @notice _approve is used to add a new Spender to a Owners account
   * 
   * Events
   *   - {Approval}
   * 
   * Requires
   *   - owner and spender cannot be zero address
    */
    function _approve(address owners, address spender, uint256 amount) internal {
      require(owners != address(0), "DevToken: approve cannot be done from zero address");
      require(spender != address(0), "DevToken: approve cannot be to zero address");
      // Set the allowance of the spender address at the Owner mapping over accounts to the amount
      _allowances[owners][spender] = amount;

      emit Approval(owners,spender,amount);
    }
    /**
    * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
    * Spender address should be the token holder
    *
    * Requires
    *   - The caller must have a allowance = or bigger than the amount spending
     */
    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool){
      // Make sure spender is allowed the amount 
      require(_allowances[spender][msg.sender] >= amount, "DevToken: You cannot spend that much on this account");
      // Transfer first
      _transfer(spender, recipient, amount);
      // Reduce current allowance so a user cannot respend
      _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
      return true;
    }
    /**
    * @notice increaseAllowance
    * Adds allowance to a account from the function caller address
    */
    function increaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]+amount);
      return true;
    }
  /**
  * @notice decreaseAllowance
  * Decrease the allowance on the account inputted from the caller address
   */
    function deaseAllowance(address spender, uint256 amount) public returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender]-amount);
      return true;
    }

 


  
    // _owner is the owner of the Token
    address public _owner;

    /**
    * Event OwnershipTransferred is used to log that a ownership change of the token has occured
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * Modifier
    * We create our own function modifier called onlyOwner, it will Require the current owner to be 
    * the same as msg.sender
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }


  
    /**
    * @notice owner() returns the currently assigned owner of the Token
    * 
     */
    function owner() public view returns(address) {
        return _owner;

    }
    /**
    * @notice renounceOwnership will set the owner to zero address
    * This will make the contract owner less, It will make ALL functions with
    * onlyOwner no longer callable.
    * There is no way of restoring the owner
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @notice transferOwnership will assign the {newOwner} as owner
    *
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
    * @notice _transferOwnership will assign the {newOwner} as owner
    *
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


 function approveSpendToken(uint _amount) public returns(bool){
   IERC20 busd = IERC20(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
            return busd.approve(address(this), _amount); // We give permission to this contract to spend the sender tokens
            //emit Approval(msg.sender, address(this), _amount);
}

 function BondBUSD (uint256 _amount) external payable {
 IERC20 busd = IERC20(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
            address from = msg.sender;
            address to = address(this);
            CreateBond(msg.sender,_amount);
            busd.transferFrom(from, to, _amount);
 }




function _safeTransferFrom(IERC20 token, address sender, address recipient, uint amount) private {bool sent = token.transferFrom(sender, recipient, amount);
            require(sent, "Token transfer failed");
            
}



function ReleaseFunds(address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 busd = IERC20(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7));
        // transfers USDT that belong to your contract to the specified address
        busd.transferFrom(address(this), _to, _amount);
}

////

}


interface IERC20 {
   function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}