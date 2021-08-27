/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: Bridge.sol


interface TokenInterface is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface MinterInterface {
    function mint(address to, uint256 amount) external;
}

contract Bridge {

  address public owner;
  address private minter = 0xE4dEc5FB434272A8c4c031bB70E798ed44D28013; //TODO set actual
  address private pauser = 0xE4dEc5FB434272A8c4c031bB70E798ed44D28013; //TODO set actual
  
  address constant public token = 0xA48cd655cF2dbd04BBa7ac3DFD9A834cb4a30507; //TODO set actual
  address constant private ethMinter = 0xb739F63006c83d39e20d3b3B9c5907e020F9a1aE; //TODO set actual
  uint256 constant private currentNetworkId = 2; //TODO set actual
  
  uint256 public minAmount = 1000 ether;
  uint256 public maxAmount = 100000 ether;
  uint256 public feePercantage = 100; // 1%
  
  uint256 public maxFeeAmount = 1500 ether;
  uint256 public fixFeeAmount = 0;
  
  uint256 public nextStartDayLimitTime;
  uint256 public dayLimit = 1000000 ether; //TODO set actual
  uint256 public usedDayLimit;
  uint256 private SECONDS_IN_DAY = 1800; //TODO set 86400
  
  bool public paused = false;
  uint256 public migrationBalance;
  bool public checkMigrationBalance;

  struct Network {
      string name;
      address token;
  }

  // networkId => user => nonce
  mapping(uint256 => mapping(address => uint256)) public networkUserNonce;
  // networkId => user => nonce => isProcessed 
  mapping(uint256 => mapping(address => mapping(uint256 => bool))) public processedToNonces;
  mapping(uint256 => mapping(address => mapping(uint256 => bool))) public processedFromNonces;
  mapping(uint256 => Network) public networks;

  enum Action { Burn, Mint }
  
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can perfrom this action");
    _;
  }
  
  modifier whenNotPaused() {
    require(!paused, "Contract is paused");
    _;
  }

  event Migrate(
    address indexed from,
    address to,
    uint256 amount,
    uint256 fee,
    uint256 date,
    uint256 indexed fromNetworkId,
    uint256 toNetworkId,
    uint256 nonce,
    Action indexed action,
    uint256 extraFee
  );

  constructor() {
    owner = msg.sender;
    checkMigrationBalance = true; //TODO set actual
    
    nextStartDayLimitTime = block.timestamp + SECONDS_IN_DAY; //TODO set acual

    Network storage ethereum = networks[1];
    ethereum.name = 'ethereum';
    ethereum.token = 0xc52FD807131e8cb3bc5FD278db6a18768aebf233; //TODO set actual
    

    Network storage binance = networks[2];
    binance.name = 'binance';
    binance.token = 0xA48cd655cF2dbd04BBa7ac3DFD9A834cb4a30507; //TODO set actual
    
    Network storage polygon = networks[3];
    polygon.name = 'polygon';
    polygon.token = 0xBDEdd94EE87c54760a795be5cE858e853EF59aE7; //TODO set actual
  }
  
  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }
  
  function setPauser(address _pauser) external onlyOwner {
    pauser = _pauser;
  }

  function setNetwork(uint256 networkId, string memory name, address netToken) external onlyOwner {
    Network storage net = networks[networkId];
    net.name = name;
    net.token = netToken;
  }
  
  function setMinAmount(uint256 amount) external onlyOwner {
    minAmount = amount;
  }
  
  function setMaxAmount(uint256 amount) external onlyOwner {
    maxAmount = amount;
  }
  
  function setCheckMigrationBalance(bool check) external onlyOwner {
    checkMigrationBalance = check;
  }
  
  // must be in bases point ( 1,5% = 150 bp)
  function setFeePercantage(uint256 fee) external onlyOwner {
    feePercantage = fee;
  }
  
  function getTokens(address to, address tokenAddress) external onlyOwner {
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    if (balance > 0) {
      IERC20(tokenAddress).transfer(to, balance);
    }
  }
  
  function getCurrency(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Not enough funds');
        address to = owner;
        payable(to).transfer(amount);
  }
  
  function setNextStartDayLimitTime(uint256 time) external onlyOwner {
    nextStartDayLimitTime = time;
  }
  
  function setDayLimit(uint256 limit) external onlyOwner {
    dayLimit = limit;
  }
  
  function setMigrationBalance(uint256 balance) external onlyOwner {
    migrationBalance = balance;
  }
  
  function setMaxFeeAmount(uint256 amount) external onlyOwner {
    maxFeeAmount = amount;
  }
  
  function setFixFeeAmount(uint256 amount) external onlyOwner {
    fixFeeAmount = amount;
  }
  
  function pause(bool _paused) external {
    require(msg.sender == owner || msg.sender == pauser, "Only owner or pauser can perfrom this action");
    paused = _paused;
  }

  function burn(address to, uint256 amount, uint256 toNetworkId, uint256 extraFee) external whenNotPaused {
    require(currentNetworkId != toNetworkId, 'Wrong distination network');
    require(networks[toNetworkId].token != address(0), 'Network is not initialized');
    uint256 nonce = networkUserNonce[toNetworkId][msg.sender]; //TODO nonce as argument
    require(processedToNonces[toNetworkId][msg.sender][nonce] == false, 'Transfer already processed');
    require(TokenInterface(token).allowance(msg.sender, address(this)) >= amount, "Token allowance too small");
    require(amount >= minAmount, "Amount is too small");
    if (maxAmount > 0) {
        require(amount <= maxAmount, "Amount is too large");
    }
    
    processedToNonces[toNetworkId][msg.sender][nonce] = true;
    TokenInterface(token).transferFrom(msg.sender, address(this), amount);
    TokenInterface(token).burn(amount);

    networkUserNonce[toNetworkId][msg.sender]++;
    migrationBalance += amount;
    
    if (nextStartDayLimitTime < block.timestamp) {
        usedDayLimit = 0;
        updateNextStartDayLimitTime();
    }

    emit Migrate(msg.sender, to, amount, 0, block.timestamp, currentNetworkId, toNetworkId, nonce, Action.Burn, extraFee);
  }

  function mint(address from, address to, uint256 amount, uint256 fromNetworkId, uint256 nonce, uint256 extraFee) external whenNotPaused {
    require(minter == msg.sender, "Caller is not the minter");
    if (maxAmount > 0) {
        require(amount <= maxAmount, "Amount is too large");
    }
    require(processedFromNonces[fromNetworkId][from][nonce] == false, 'Transfer already processed');
    if (checkMigrationBalance) {
        require(amount <= migrationBalance, "Amount is not acceptable");
        migrationBalance -= amount;
    }
    checkDayLimit(amount);
    
    processedFromNonces[fromNetworkId][from][nonce] = true;
    
    uint256 amountToMint = amount;
    uint256 fee = calculateFee(amount, extraFee);
    if (fee > 0) {
        _mint(address(this), fee);
        amountToMint = amountToMint - fee;
    }
    
    _mint(to, amountToMint);
    
    emit Migrate(from, to, amountToMint, fee, block.timestamp, fromNetworkId, currentNetworkId, nonce, Action.Mint, extraFee);
  }
  
  function calculateFee(uint256 amount, uint256 extraFee) public view returns (uint256) {
    uint256 fee = 0;
    if (fixFeeAmount > 0) {
        fee = fixFeeAmount;
    } else {
        if (feePercantage > 0) {
            fee = amount * feePercantage / 10**4;
            if (fee > maxFeeAmount && maxFeeAmount > 0) {
                fee = maxFeeAmount;
            }
        }
    }
    return fee + extraFee;
  }
  
  function checkDayLimit(uint256 amount) internal {
    if (block.timestamp < nextStartDayLimitTime) {
        usedDayLimit += amount;
        require(usedDayLimit <= dayLimit, "Exceedeed daily limit");
    } else {
        usedDayLimit = amount;
        require(usedDayLimit <= dayLimit, "Exceedeed daily limit");
        
        updateNextStartDayLimitTime();
    }
  }
  
  function updateNextStartDayLimitTime() internal {
    uint256 diffDays = (block.timestamp - nextStartDayLimitTime) / SECONDS_IN_DAY;
    //if there were no transactions for more then one day
    if (diffDays > 0) {
        nextStartDayLimitTime += SECONDS_IN_DAY * (diffDays + 1);
    } else {
        nextStartDayLimitTime += SECONDS_IN_DAY;
    }
  }
  
  function getUsedDayLimit() public view returns (uint256) {
    if (block.timestamp < nextStartDayLimitTime) {
        return usedDayLimit;
    } else {
        return 0;
    }
  }
  
  function _mint(address to, uint256 amount) internal {
    if (currentNetworkId == 1) {
        MinterInterface(ethMinter).mint(to, amount);
    } else {
        TokenInterface(token).mint(to, amount);
    }
  }
}