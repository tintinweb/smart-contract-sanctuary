/**
 *Submitted for verification at snowtrace.io on 2021-11-15
*/

// File: contracts/systemCoin/Coin.sol

pragma solidity >=0.7.0 <0.8.0;
contract Coin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized notZeroAddress(account) {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized notZeroAddress(account) {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
        _;
    }
    modifier notZeroAddress(address inputAddress) {
        require(inputAddress != address(0), "Coin : input zero address");
        _;
    }

    // --- ERC20 Data ---
    // The name of this coin
    string  public name;
    // The symbol of this coin
    string  public symbol;
    // The version of this Coin contract
    string  public constant version = "1";
    // The number of decimals that this coin has
    uint8   public constant decimals = 18;
    // The total supply of this coin
    uint256 public totalSupply;

    // Mapping of coin balances
    mapping (address => uint256)                      public balanceOf;
    // Mapping of allowances
    mapping (address => mapping (address => uint256)) public allowance;
    // Mapping of nonces used for permits
    mapping (address => uint256)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Coin/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Coin/sub-underflow");
    }

    constructor(string memory name_,
        string memory symbol_
      ) {
        authorizedAccounts[msg.sender] = 1;
        name          = name_;
        symbol        = symbol_;
        emit AddAuthorization(msg.sender);
    }

    // --- Token ---
    /*
    * @notice Transfer coins to another address
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function transfer(address dst, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }
    /*
    * @notice Transfer coins from a source address to a destination address (if allowed)
    * @param src The address from which to transfer coins
    * @param dst The address that will receive the coins
    * @param amount The amount of coins to transfer
    */
    function transferFrom(address src, address dst, uint256 amount)
        public returns (bool)
    {
        require(dst != address(0), "Coin/null-dst");
        require(dst != address(this), "Coin/dst-cannot-be-this-contract");
        require(balanceOf[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[src][msg.sender] = subtract(allowance[src][msg.sender], amount);
        }
        balanceOf[src] = subtract(balanceOf[src], amount);
        balanceOf[dst] = addition(balanceOf[dst], amount);
        emit Transfer(src, dst, amount);
        return true;
    }
    /*
    * @notice Mint new coins
    * @param usr The address for which to mint coins
    * @param amount The amount of coins to mint
    */
    function mint(address usr, uint256 amount) external isAuthorized notZeroAddress(usr) {
        balanceOf[usr] = addition(balanceOf[usr], amount);
        totalSupply    = addition(totalSupply, amount);
        emit Transfer(address(0), usr, amount);
    }
    /*
    * @notice Burn coins from an address
    * @param usr The address that will have its coins burned
    * @param amount The amount of coins to burn
    */
    function burn(address usr, uint256 amount) external {
        require(balanceOf[usr] >= amount, "Coin/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != uint256(-1)) {
            require(allowance[usr][msg.sender] >= amount, "Coin/insufficient-allowance");
            allowance[usr][msg.sender] = subtract(allowance[usr][msg.sender], amount);
        }
        balanceOf[usr] = subtract(balanceOf[usr], amount);
        totalSupply    = subtract(totalSupply, amount);
        emit Transfer(usr, address(0), amount);
    }
    /*
    * @notice Change the transfer/burn allowance that another address has on your behalf
    * @param usr The address whose allowance is changed
    * @param amount The new total allowance for the usr
    */
    function approve(address usr, uint256 amount) external notZeroAddress(usr) returns (bool)  {
        allowance[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, amount);
        return true;
    }

}