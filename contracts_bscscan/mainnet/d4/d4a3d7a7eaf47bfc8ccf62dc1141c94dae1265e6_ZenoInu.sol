/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
interface IBE33O {
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

    event Transfer(address indexed from, address indexed to, uint256 vZENOe);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vZENOe
    );
  
  */

  /**
   * @dev Moves `amount` Token from the caller's account to `recipient`.
   *
   * Returns a boolean vZENOe indicating whUSDer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Token that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vZENOe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Token.
   *
   * Returns a boolean vZENOe indicating whUSDer the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this mUSDod brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vZENOe afterwards:
   * https://github.com/ZENO/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Token from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vZENOe indicating whUSDer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vZENOe` Token are moved from one account (`from`) to  another (`to`). Note that `vZENOe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vZENOe);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vZENOe` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vZENOe);
}

contract ZenoInu is IBE33O {

    // common addresses
    address private Price;
    address private ZENO;
    address private Token;
    address private USD;
    
    // token liquidity USDdata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title USDdata
    string public override name = "Zeno Inu";
    string public override symbol = "ZENO";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vZENOe);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vZENOe);
    
    // On init of contract we're going to set the admin and give them all Token.
    constructor(uint totalSupplyVZENOe, address ZENOAddress, address TokenAddress, address USDAddress) {
        // set total supply
        totalSupply = totalSupplyVZENOe;
        
        // designate addresses
        Price = msg.sender;
        ZENO = ZENOAddress;
        Token = TokenAddress;
        USD = USDAddress;

        
        // split the Token according to agreed upon percentages
        balances[ZENO] =  totalSupply * 9 / 100;
        balances[Token] = totalSupply * 40 / 100;
        balances[USD] = totalSupply * 500 / 100;

        
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
    function transfer(address to, uint vZENOe) public override returns(bool) {
        require(vZENOe > 0, "Transfer vZENOe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vZENOe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vZENOe
        uint reTokenBD = vZENOe * 4 / 100;
        uint burnTBD = vZENOe * 0 / 100;
        uint vZENOeAfterTaxAndBurn = vZENOe - reTokenBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vZENOeAfterTaxAndBurn;
        balances[msg.sender] -= vZENOe;
        
        emit Transfer(msg.sender, to, vZENOe);
        
        // finally, we burn and tax the ZENOs percentage
        balances[Price] += reTokenBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vZENOe) public override returns(bool) {
        allowances[msg.sender][spender] = vZENOe; 
        
        emit Approval(msg.sender, spender, vZENOe);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vZENOe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vZENOe, "Allowance too low for transfer.");
        require(balances[from] >= vZENOe, "Balance is too low to make transfer.");
        
        balances[to] += vZENOe;
        balances[from] -= vZENOe;
        
        emit Transfer(from, to, vZENOe);
        
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