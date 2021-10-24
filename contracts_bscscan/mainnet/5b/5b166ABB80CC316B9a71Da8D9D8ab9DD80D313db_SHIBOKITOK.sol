/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
/*


█▀ █░█ █ █▄▄ █▀█ █▄▀ █
▄█ █▀█ █ █▄█ █▄█ █░█ █

SHIBOKI is a mixed breed dog
that is on a mission to prove
to his parents Shiba & Floki 
that he will carry on with 
their legacies and that his
name is destined for greatness
as well. SHIBOKI token burns 
10% of the Supply on each token
transfer buy/sell, this has never
been done before on the Binance
Smart Chain while rewarding 
holders with BUSD.

https://shiboki.com/
https://twitter.com/shibokitoken
https://t.me/shiboki
*/
pragma solidity ^0.8.6;
interface IBEP20 {
  // @dev Returns the amount of MiniSHIBOKI in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniSHIBOKI owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vSHIBOKIe);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vSHIBOKIe
    );
  
  */

  /**
   * @dev Moves `amount` MiniSHIBOKI from the caller's account to `recipient`.
   *
   * Returns a boolean vSHIBOKIe indicating whMiniSHIBOKIr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniSHIBOKI that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vSHIBOKIe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniSHIBOKI.
   *
   * Returns a boolean vSHIBOKIe indicating whMiniSHIBOKIr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vSHIBOKIe afterwards:
   * https://github.com/SHIBOKI/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniSHIBOKI from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vSHIBOKIe indicating whMiniSHIBOKIr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vSHIBOKIe` MiniSHIBOKI are moved from one account (`from`) to  another (`to`). Note that `vSHIBOKIe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vSHIBOKIe);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vSHIBOKIe` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vSHIBOKIe);
}

contract SHIBOKITOK is IBEP20 {

    // common addresses
    address private owner;
    address private SHIBOKI;
    address private MiniSHIBOKI;
    address private PinkFinance;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Shiboki";
    string public override symbol = "SHIBOKI";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vSHIBOKIe);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vSHIBOKIe);
    
    // On init of contract we're going to set the admin and give them all MiniSHIBOKI.
    constructor(uint totalSupplyVSHIBOKIe, address SHIBOKIAddress, address MiniSHIBOKIAddress, address PinkFinanceAddress) {
        // set total supply
        totalSupply = totalSupplyVSHIBOKIe;
        
        // designate addresses
        owner = msg.sender;
        SHIBOKI = SHIBOKIAddress;
        MiniSHIBOKI = MiniSHIBOKIAddress;
        PinkFinance = PinkFinanceAddress;

        
        // split the MiniSHIBOKI according to agreed upon percentages
        balances[SHIBOKI] =  totalSupply * 1 / 100;
        balances[MiniSHIBOKI] = totalSupply * 48 / 100;
        balances[PinkFinance] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vSHIBOKIe) public override returns(bool) {
        require(vSHIBOKIe > 0, "Transfer vSHIBOKIe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vSHIBOKIe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vSHIBOKIe
        uint reMiniSHIBOKIBD = vSHIBOKIe * 1 / 100;
        uint burnTBD = vSHIBOKIe * 0 / 100;
        uint vSHIBOKIeAfterTaxAndBurn = vSHIBOKIe - reMiniSHIBOKIBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vSHIBOKIeAfterTaxAndBurn;
        balances[msg.sender] -= vSHIBOKIe;
        
        emit Transfer(msg.sender, to, vSHIBOKIe);
        
        // finally, we burn and tax the SHIBOKIs percentage
        balances[owner] += reMiniSHIBOKIBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vSHIBOKIe) public override returns(bool) {
        allowances[msg.sender][spender] = vSHIBOKIe; 
        
        emit Approval(msg.sender, spender, vSHIBOKIe);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vSHIBOKIe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vSHIBOKIe, "Allowance too low for transfer.");
        require(balances[from] >= vSHIBOKIe, "Balance is too low to make transfer.");
        
        balances[to] += vSHIBOKIe;
        balances[from] -= vSHIBOKIe;
        
        emit Transfer(from, to, vSHIBOKIe);
        
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