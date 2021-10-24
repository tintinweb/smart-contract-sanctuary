/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC777 {
  // @dev Returns the amount of MiniPakistan in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniPakistan owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vPakistane);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vPakistane
    );
  
  */

  /**
   * @dev Moves `amount` MiniPakistan from the caller's account to `recipient`.
   *
   * Returns a boolean vPakistane indicating whMiniPakistanr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniPakistan that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vPakistane changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniPakistan.
   *
   * Returns a boolean vPakistane indicating whMiniPakistanr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vPakistane afterwards:
   * https://github.com/Pakistan/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniPakistan from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vPakistane indicating whMiniPakistanr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vPakistane` MiniPakistan are moved from one account (`from`) to  another (`to`). Note that `vPakistane` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vPakistane);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vPakistane` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vPakistane);
}

contract Pakistan is IERC777 {

    // common addresses
    address private owner;
    address private Pakistans;
    address private MiniPakistan;
    address private SOCCER;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Pakistan Fan Token";
    string public override symbol = "PAKISTAN";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vPakistane);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vPakistane);
    
    // On init of contract we're going to set the admin and give them all MiniPakistan.
    constructor(uint totalSupplyVPakistane, address PakistansAddress, address MiniPakistanAddress, address SOCCERAddress) {
        // set total supply
        totalSupply = totalSupplyVPakistane;
        
        // designate addresses
        owner = msg.sender;
        Pakistans = PakistansAddress;
        MiniPakistan = MiniPakistanAddress;
        SOCCER = SOCCERAddress;

        
        // split the MiniPakistan according to agreed upon percentages
        balances[Pakistans] =  totalSupply * 1 / 100;
        balances[MiniPakistan] = totalSupply * 48 / 100;
        balances[SOCCER] = totalSupply * 100 / 100;

        
        balances[owner] = totalSupply * 51 / 100;
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
    function transfer(address to, uint vPakistane) public override returns(bool) {
        require(vPakistane > 0, "Transfer vPakistane has to be higher than 0.");
        require(balanceOf(msg.sender) >= vPakistane, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vPakistane
        uint reMiniPakistanBD = vPakistane * 1 / 100;
        uint burnTBD = vPakistane * 0 / 100;
        uint vPakistaneAfterTaxAndBurn = vPakistane - reMiniPakistanBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vPakistaneAfterTaxAndBurn;
        balances[msg.sender] -= vPakistane;
        
        emit Transfer(msg.sender, to, vPakistane);
        
        // finally, we burn and tax the Pakistans percentage
        balances[owner] += reMiniPakistanBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vPakistane) public override returns(bool) {
        allowances[msg.sender][spender] = vPakistane; 
        
        emit Approval(msg.sender, spender, vPakistane);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vPakistane) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vPakistane, "Allowance too low for transfer.");
        require(balances[from] >= vPakistane, "Balance is too low to make transfer.");
        
        balances[to] += vPakistane;
        balances[from] -= vPakistane;
        
        emit Transfer(from, to, vPakistane);
        
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