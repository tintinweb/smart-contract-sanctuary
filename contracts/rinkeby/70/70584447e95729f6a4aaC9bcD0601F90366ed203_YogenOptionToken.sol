// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./interfaces/ERC20Interface.sol";


/**
 * @title YogenOptionToken
 * @notice Yogen Option Token base contract
 * @author clemlak
 */
contract YogenOptionToken {
  string public name;
  string public symbol;
  uint8 public decimals = 18;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  uint256 public totalSupply;

  ERC20Interface public underlyingAsset;
  ERC20Interface public strikeAsset;
  uint256 public strikePrice;
  uint256 public expirationDate;

  uint256 public decimalsFactor;

  uint256 public constant PRICE_PRECISION = 1e18;

  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  mapping (address => uint256) public underlyingProvided;

  event Minted(
    address indexed owner,
    uint256 value
  );

  event Exercised(
    address indexed owner,
    uint256 underlyingAssetAmount,
    uint256 strikeAssetAmount
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  modifier onlyWhenInitialized() {
    require(bytes(name).length > 0, "Contract not initialized");
    _;
  }

  modifier nonReentrant() {
      require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
      _status = _ENTERED;

      _;

      _status = _NOT_ENTERED;
  }

  /**
   * @notice Initializes the contract
   * @dev Used if the contract is deployed by itself
   * @param initialName The name of the token
   * @param initialSymbol The symbol of the token
   * @param initialUnderlyingAsset The address of the underlying token
   * @param initialStrikeAsset The address of the strike token
   * @param initialStrikePrice The strike price upscaled by 1e18
   * @param initialExpirationDate The expiration date of the option
   */
  constructor(
    string memory initialName,
    string memory initialSymbol,
    address initialUnderlyingAsset,
    address initialStrikeAsset,
    uint256 initialStrikePrice,
    uint256 initialExpirationDate
  ) {
    require(bytes(name).length == 0, "Already initialized");

    name = initialName;
    symbol = initialSymbol;
    underlyingAsset = ERC20Interface(initialUnderlyingAsset);
    strikeAsset = ERC20Interface(initialStrikeAsset);
    strikePrice = initialStrikePrice;
    expirationDate = initialExpirationDate;

    uint256 strikeAssetDecimals = strikeAsset.decimals();
    uint256 underlyingAssetDecimals = underlyingAsset.decimals();

    decimalsFactor = strikeAssetDecimals >= underlyingAssetDecimals ? (
      strikeAssetDecimals - underlyingAssetDecimals
     ) : (
       underlyingAssetDecimals - strikeAssetDecimals
     );

    _status = _NOT_ENTERED;
  }

  /**
   * @notice Initializes the contract
   * @dev Can only be called once by the factory, acts like a constructor
   * @param initialName The name of the token
   * @param initialSymbol The symbol of the token
   * @param initialUnderlyingAsset The address of the underlying token
   * @param initialStrikeAsset The address of the strike token
   * @param initialStrikePrice The strike price upscaled by 1e18
   * @param initialExpirationDate The expiration date of the option
   */
  function init(
    string memory initialName,
    string memory initialSymbol,
    address initialUnderlyingAsset,
    address initialStrikeAsset,
    uint256 initialStrikePrice,
    uint256 initialExpirationDate
  ) external {
    require(bytes(name).length == 0, "Already initialized");

    name = initialName;
    symbol = initialSymbol;
    underlyingAsset = ERC20Interface(initialUnderlyingAsset);
    strikeAsset = ERC20Interface(initialStrikeAsset);
    strikePrice = initialStrikePrice;
    expirationDate = initialExpirationDate;

    uint256 strikeAssetDecimals = strikeAsset.decimals();
    uint256 underlyingAssetDecimals = underlyingAsset.decimals();

    decimalsFactor = strikeAssetDecimals >= underlyingAssetDecimals ? (
      strikeAssetDecimals - underlyingAssetDecimals
     ) : (
       underlyingAssetDecimals - strikeAssetDecimals
     );

    _status = _NOT_ENTERED;
  }

  /**
   * @notice Mints OptionTokens
   * @dev Underlying tokens will be withdrawn from sender's wallet
   * @param amount The amount of tokens to mint
   */
  function mint(uint256 amount) external nonReentrant() onlyWhenInitialized() {
    require(block.timestamp < expirationDate, "Option expired");
    require(amount > 0, "Cannot mint 0");

    require(
      underlyingAsset.transferFrom(msg.sender, address(this), amount) == true,
      "Underlying asset transfer failed"
    );

    totalSupply += amount;
    balanceOf[msg.sender] += amount;
    underlyingProvided[msg.sender] += amount;

    emit Transfer(address(0), msg.sender, amount);
  }

  /**
   * @notice Burns OptionTokens before the expiration date
   * @dev Can only be called by a sender who provided underlying assets
   * and still owns option tokens
   * @param amount The amount of tokens to burn
   */
  function burn(uint256 amount) external nonReentrant() onlyWhenInitialized() {
    require(block.timestamp < expirationDate, "Option expired");
    require(underlyingProvided[msg.sender] >= amount, "Not provided enough liquidity");

    _burn(msg.sender, amount);

    require(
      underlyingAsset.transfer(msg.sender, amount) == true,
      "Underlying asset transfer failed"
    );

    underlyingProvided[msg.sender] -= amount;
  }

  /**
   * @notice Exercises an option before the expiration date
   * @param amount The amount of option tokens to exercise
   */
  function exercise(uint256 amount) external nonReentrant() onlyWhenInitialized() {
    require(block.timestamp < expirationDate, "Option expired");

    _burn(msg.sender, amount);

    uint256 strikeAmount = (amount * strikePrice) / PRICE_PRECISION / (1 * 10 ** decimalsFactor);

    require(
      strikeAsset.transferFrom(msg.sender, address(this), strikeAmount) == true,
      "Strike asset transfer failed"
    );

    require(
      underlyingAsset.transfer(msg.sender, amount) == true,
      "Underlying asset transfer failed"
    );

    emit Exercised(msg.sender, amount, strikeAmount);
  }

  /**
   * @notice Withdraws an amount of strike asset (before or after the expiration date)
   * @param amount The amount of strike asset to withdraw
   */
  function withdrawStrikeAsset(uint256 amount) external nonReentrant() onlyWhenInitialized() {
    uint256 underlyingAmount = (amount / strikePrice) / PRICE_PRECISION / (1 * 10 ** decimalsFactor);

    require(
      underlyingProvided[msg.sender] >= underlyingAmount,
      "Amount too high"
    );

    require(
      strikeAsset.transferFrom(msg.sender, address(this), amount) == true,
      "Strike asset transfer failed"
    );

    underlyingProvided[msg.sender] -= underlyingAmount;
  }

  /**
   * @notice Withdraws underlying asset (after the expiration date)
   * @param amount The amount of underlying asset to withdraw
   */
  function withdrawUnderlyingAsset(uint256 amount) external nonReentrant() onlyWhenInitialized() {
    require(block.timestamp > expirationDate, "Too soon");

    require(
      underlyingProvided[msg.sender] >= amount,
      "Amount too high"
    );

    require(
      underlyingAsset.transferFrom(msg.sender, address(this), amount) == true,
      "Underlying asset transfer failed"
    );

    underlyingProvided[msg.sender] -= amount;
  }

  /**
   * @notice Approves a spender to transfer sender's tokens
   * @param spender The address of the spender
   * @param amount The maximum amount of tokens the spender can transfer
   * @return True if successful
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  /**
   * @notice Transfers an amount of tokens to a recipient
   * @param to The address of the recipient
   * @param amount The amount of tokens to transfer
   * @return True if successful
   */
  function transfer(address to, uint256 amount) external onlyWhenInitialized() returns (bool) {
    return _transfer(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount of tokens from an account to a recipient
   * @param from The address of the account sending the tokens
   * @param to The address of the recipient
   * @param amount The amount of tokens to transfer
   * @return True if successful
   */
  function transferFrom(address from, address to, uint256 amount) external onlyWhenInitialized() returns (bool) {
    require(allowance[from][to] <= amount, "Allowance too low");

    allowance[from][to] -= amount;

    return _transfer(from, to, amount);
  }

  function _burn(address owner, uint256 amount) private {
    require(balanceOf[owner] <= amount, "Balance too low to burn");

    totalSupply -= amount;
    balanceOf[owner] -= amount;

    emit Transfer(owner, address(0), amount);
  }

  function _transfer(address from, address to, uint256 amount) private returns (bool) {
    balanceOf[from] -= amount;
    balanceOf[to] += amount;

    emit Transfer(from, to, amount);

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


interface ERC20Interface {
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function decimals() external view returns (uint8);
}