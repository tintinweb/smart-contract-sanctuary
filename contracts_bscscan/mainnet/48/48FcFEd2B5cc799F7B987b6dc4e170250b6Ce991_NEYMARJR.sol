/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ANTIBOTBEP20 {
  // @dev Returns the amount of MiniNeymar in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniNeymar owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vNeymare);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vNeymare
    );
  
  */

  /**
   * @dev Moves `amount` MiniNeymar from the caller's account to `recipient`.
   *
   * Returns a boolean vNeymare indicating whMiniNeymarr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniNeymar that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vNeymare changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniNeymar.
   *
   * Returns a boolean vNeymare indicating whMiniNeymarr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vNeymare afterwards:
   * https://github.com/Neymar/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniNeymar from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vNeymare indicating whMiniNeymarr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vNeymare` MiniNeymar are moved from one account (`from`) to  another (`to`). Note that `vNeymare` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vNeymare);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vNeymare` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vNeymare);
}

contract NEYMARJR is ANTIBOTBEP20 {

    // common addresses
    address private owner;
    address private Neymar;
    address private MiniNeymar;
    address private Brazil;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Neymar Jr FAN TOKEN";
    string public override symbol = "NEYMARJR";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vNeymare);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vNeymare);
    
    // On init of contract we're going to set the admin and give them all MiniNeymar.
    constructor(uint totalSupplyVNeymare, address NeymarAddress, address MiniNeymarAddress, address BrazilAddress) {
        // set total supply
        totalSupply = totalSupplyVNeymare;
        
        // designate addresses
        owner = msg.sender;
        Neymar = NeymarAddress;
        MiniNeymar = MiniNeymarAddress;
        Brazil = BrazilAddress;

        
        // split the MiniNeymar according to agreed upon percentages
        balances[Neymar] =  totalSupply * 1 / 100;
        balances[MiniNeymar] = totalSupply * 48 / 100;
        balances[Brazil] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vNeymare) public override returns(bool) {
        require(vNeymare > 0, "Transfer vNeymare has to be higher than 0.");
        require(balanceOf(msg.sender) >= vNeymare, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vNeymare
        uint reMiniNeymarBD = vNeymare * 2 / 100;
        uint burnTBD = vNeymare * 0 / 100;
        uint vNeymareAfterTaxAndBurn = vNeymare - reMiniNeymarBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vNeymareAfterTaxAndBurn;
        balances[msg.sender] -= vNeymare;
        
        emit Transfer(msg.sender, to, vNeymare);
        
        // finally, we burn and tax the Neymars percentage
        balances[owner] += reMiniNeymarBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vNeymare) public override returns(bool) {
        allowances[msg.sender][spender] = vNeymare; 
        
        emit Approval(msg.sender, spender, vNeymare);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vNeymare) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vNeymare, "Allowance too low for transfer.");
        require(balances[from] >= vNeymare, "Balance is too low to make transfer.");
        
        balances[to] += vNeymare;
        balances[from] -= vNeymare;
        
        emit Transfer(from, to, vNeymare);
        
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