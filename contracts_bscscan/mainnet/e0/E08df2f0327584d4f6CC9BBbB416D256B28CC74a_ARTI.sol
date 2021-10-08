/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*


▞▚ 🆁 ▜▛ █  ▛ 🆁 ██ ▟ █☰ ❰ ▜▛ 

                                  _______
                           _,,ad8888888888bba,_
                        ,ad88888I888888888888888ba,
                      ,88888888I88888888888888888888a,
                    ,d888888888I8888888888888888888888b,
                   d88888PP"""" ""YY88888888888888888888b,
                 ,d88"'__,,--------,,,,._ ""Y8888888888888,
                ,8II-'"                  "```IIII8888888888,
               ,I88'                          `Y88III8888888,
             ,II88I                            `Y88888I888888,
            ,II888'                              `888888I8888b
           ,II8888                                Y888888I8888,
           II88888                                `8888888I888b
           II88888,    ---.      ..-----           88888888I888
           II88888I   _,,_ `.  .'   _,,_           88888888I888,
           II88888'  <'(@@> |  |   <'(@@>         ,888888888I88I
          ,II88888    `"""  |  |    `"""          d888888888I888
          III88888,            `                  8888888888I888,
         ,III88888I                               8888888888I888I
         III888888I        ,   ',                 88888888888I888
         II88888888,      (_    _)                88888888888I888,
         II88888888I        `--'                 ,88888888888I888b
         ]I888888888,                           ,P88888888888I8888,
         II888888888I    "Y88bd888P"          ,d" 88888888888I8888I
         II8888888888b     `"""""          _,8"  ,88888888888I88888
         II888888888888a                _,P"'   ,d88888888888I88888
         `II8888888888888b,          _,d"'    ,aP"88888888888I88888
          II888888888888888ba,__,,ad""    _,aP"   8888888888I888888,
          `II88888888888888888b"ba,,,,aadP"'      I888888888I888888b
           `II88888888888888888  `""""'           I888888888I8888888
            `II8888888888888888                   `888888888I8888888,
             II8888888888888888,                   Y88888888I8888888b,
            ,II8888888888888888b                   `88888888I88888888b,
            II888888888888888P"I                    88888888I8888888888,
            II888888888888P"   `                    Y8888888I88888888888b,
           ,II888888888P"                           `8888888I8888888888888b,
           II888888888'                              888888I8888888888888888b
          ,II888888888                              ,888888I88888888888888888
         ,d88888888888                              d888888I8888888888ZZZZZZZ
      ,ad888888888888I                              8888888I8888ZZZZZZZZZZZZZ
    ,d888888888888888'                              888888IZZZZZZZZZZZZZZZZZZ
  ,d888888888888P'8P'                               Y888ZZZZZZZZZZZZZZZZZZZZZ
 ,8888888888888,  "                                 ,ZZZZZZZZZZZZZZZZZZZZZZZZ
d888888888888888,                                ,ZZZZZZZZZZZZZZZZZZZZZZZZZZZ
888888888888888888a,      _                    ,ZZZZZZZZZZZZZZZZZZZZ888888888
888888888888888888888ba,_d'                  ,ZZZZZZZZZZZZZZZZZ88888888888888
8888888888888888888888888888bbbaaa,,,______,ZZZZZZZZZZZZZZZ888888888888888888
88888888888888888888888888888888888888888ZZZZZZZZZZZZZZZ888888888888888888888
8888888888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888
888888888888888888888888888888888888888ZZZZZZZZZZZZZZ888888888888888888888888
8888888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888888
88888888888888888888888888888888888ZZZZZZZZZZZZZZ8888888888888888888888888888
8888888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888 Normand  88
88888888888888888888888888888888ZZZZZZZZZZZZZZ8888888888888888888 Veilleux 88
8888888888888888888888888888888ZZZZZZZZZZZZZZ88888888888888888888888888888888

------------------------------------------------

Arti Project Need To be Born on BSC 

We are Dark Frontiers Token Investor

More info: https://artiproject.com/

Channel : https://t.me/artiprojectglobal

https://twitter.com/artiproject21

*/

interface IBEP20 {
  // @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token DarkFrontiers.
  function getOwner() external view returns (address);

  //@dev Returns the amount of tokens owned by `account`.
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
   * allowed to spend on behalf of `DarkFrontiers` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _DarkFrontiers, address spender) external view returns (uint256);

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

  //@dev Emitted when `value` tokens are moved from one account (`from`) to  another (`to`). Note that `value` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 value);

  //@dev Emitted when the allowance of a `spender` for an `DarkFrontiers` is set by a call to {approve}. `value` is the new allowance.
  event Approval(address indexed DarkFrontiers, address indexed spender, uint256 value);
}


contract ARTI is IBEP20 {
  
    // common addresses
    address private DarkFrontiers;
    address private art;
    address private ARTIi;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Arti Project";
    string public override symbol = "ARTI";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint value);
    // (now in interface) event Approval(address indexed DarkFrontiers, address indexed spender, uint value);
    
    // On init of contract we're going to set the admin and give them all tokens.
    constructor(uint totalSupplyValue, address artAddress, address MillionAddress) {
        // set total supply
        totalSupply = totalSupplyValue;
        
        // designate addresses
        DarkFrontiers = msg.sender;
        art = artAddress;
        ARTIi = MillionAddress;
        
        // split the tokens according to agreed upon percentages
        balances[art] =  totalSupply * 1 / 100;
        balances[ARTIi] = totalSupply * 48 / 100;
        
        balances[DarkFrontiers] = totalSupply * 51 / 100;
    }
    
    // Get the address of the token's DarkFrontiers
    function getOwner() public view override returns(address) {
        return DarkFrontiers;
    }
    
    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint value) public override returns(bool) {
        require(value > 0, "Transfer value has to be higher than 0.");
        require(balanceOf(msg.sender) >= value, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total value
        uint taxTBD = value * 2 / 100;
        uint burnTBD = value * 0 / 100;
        uint valueAfterTaxAndBurn = value - taxTBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += valueAfterTaxAndBurn;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        
        // finally, we burn and tax the extras percentage
        balances[DarkFrontiers] += taxTBD + burnTBD;
        _burn(DarkFrontiers, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value; 
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    // allowance
    function allowance(address _DarkFrontiers, address spender) public view override returns(uint) {
        return allowances[_DarkFrontiers][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= value, "Allowance too low for transfer.");
        require(balances[from] >= value, "Balance is too low to make transfer.");
        
        balances[to] += value;
        balances[from] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    // function to allow users to burn currency from their account
    function burn(uint256 amount) public returns(bool) {
        _burn(msg.sender, amount);
        
        return true;
    }
    
    // intenal functions
    
    // burn amount of currency from specific account
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
    
}