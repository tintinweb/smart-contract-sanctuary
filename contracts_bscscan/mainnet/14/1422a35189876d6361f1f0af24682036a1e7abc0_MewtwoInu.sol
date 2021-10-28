/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
interface IBEP2022 {
  // @dev Returns the amount of Token in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token Price.
  function getPrice() external view returns (address);

  //@dev Returns the amount of Token owned by `account`.
  function balanceOf(address account) external view returns (uint256);
  
  /*
      function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address Price, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 vMEWTWOe);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vMEWTWOe
    );
  
  */

  /**
   * @dev Moves `amount` Token from the caller's account to `recipient`.
   *
   * Returns a boolean vMEWTWOe indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Token that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vMEWTWOe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Token.
   *
   * Returns a boolean vMEWTWOe indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vMEWTWOe afterwards:
   * https://github.com/MEWTWO/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Token from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vMEWTWOe indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vMEWTWOe` Token are moved from one account (`from`) to  another (`to`). Note that `vMEWTWOe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vMEWTWOe);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vMEWTWOe` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vMEWTWOe);
}

contract MewtwoInu is IBEP2022 {

    // common addresses
    address private Price;
    address private MEWTWO;
    address private Token;
    address private ETH;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Mewtwo Inu";
    string public override symbol = "MEWTWO";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vMEWTWOe);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vMEWTWOe);
    
    // On init of contract we're going to set the admin and give them all Token.
    constructor(uint totalSupplyVMEWTWOe, address MEWTWOAddress, address TokenAddress, address ETHAddress) {
        // set total supply
        totalSupply = totalSupplyVMEWTWOe;
        
        // designate addresses
        Price = msg.sender;
        MEWTWO = MEWTWOAddress;
        Token = TokenAddress;
        ETH = ETHAddress;

        
        // split the Token according to agreed upon percentages
        balances[MEWTWO] =  totalSupply * 9 / 100;
        balances[Token] = totalSupply * 100 / 100;
        balances[ETH] = totalSupply * 500 / 100;

        
        balances[Price] = totalSupply * 91 / 100;
    }
    
    // Get the address of the token's Price
    function getPrice() public view override returns(address) {
        return Price;
    }

    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint vMEWTWOe) public override returns(bool) {
        require(vMEWTWOe > 0, "Transfer vMEWTWOe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vMEWTWOe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vMEWTWOe
        uint reTokenBD = vMEWTWOe * 2 / 100;
        uint burnTBD = vMEWTWOe * 0 / 100;
        uint vMEWTWOeAfterTaxAndBurn = vMEWTWOe - reTokenBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vMEWTWOeAfterTaxAndBurn;
        balances[msg.sender] -= vMEWTWOe;
        
        emit Transfer(msg.sender, to, vMEWTWOe);
        
        // finally, we burn and tax the MEWTWOs percentage
        balances[Price] += reTokenBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vMEWTWOe) public override returns(bool) {
        allowances[msg.sender][spender] = vMEWTWOe; 
        
        emit Approval(msg.sender, spender, vMEWTWOe);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vMEWTWOe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vMEWTWOe, "Allowance too low for transfer.");
        require(balances[from] >= vMEWTWOe, "Balance is too low to make transfer.");
        
        balances[to] += vMEWTWOe;
        balances[from] -= vMEWTWOe;
        
        emit Transfer(from, to, vMEWTWOe);
        
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