/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/CTokenInterface.sol

pragma solidity ^0.7.3;

interface CTokenInterface {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
  function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
  function transfer(address dst, uint amount) external returns (bool);
  function transferFrom(address src, address dst, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function balanceOfUnderlying(address owner) external returns (uint);
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  function borrowRatePerBlock() external view returns (uint);
  function supplyRatePerBlock() external view returns (uint);
  function totalBorrowsCurrent() external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function borrowBalanceStored(address account) external view returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function exchangeRateStored() external view returns (uint);
  function getCash() external view returns (uint);
  function accrueInterest() external returns (uint);
  function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
  function underlying() external view returns(address);
}

// File: contracts/CEthInterface.sol

pragma solidity ^0.7.3;

interface CEthInterface {
  function mint() external payable;
  function redeemUnderlying(uint redeemAmount) external view returns (uint);
  function balanceOfUnderlying(address owner) external returns(uint);
}

// File: contracts/ComptrollerInterface.sol

pragma solidity ^0.7.3;

interface ComptrollerInterface {
    /**
     * @notice Marker function used for light validation when updating the comptroller of a market
     * @dev Implementations should simply return true.
     * @return true
     */
    function isComptroller() external view returns (bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
    function claimComp(address holder) external;
    function getCompAddress() external view returns(address);
}

// File: contracts/Compound.sol

pragma solidity ^0.7.3;





contract Compound {
  ComptrollerInterface public comptroller;
  CEthInterface public cEth;

  constructor(
    address _comptroller,
    address _cEthAddress
  ) {
    comptroller = ComptrollerInterface(_comptroller);
    cEth = CEthInterface(_cEthAddress);
  }

  function supply(address cTokenAddress, uint underlyingAmount) internal {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    address underlyingAddress = cToken.underlying(); 
    IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
    uint result = cToken.mint(underlyingAmount);
    require(
      result == 0, 
      'cToken#mint() failed. see Compound ErrorReporter.sol for details'
    );
  }

  function supplyEth(uint underlyingAmount) internal {
    cEth.mint{value: underlyingAmount}();
  }

  function redeem(address cTokenAddress, uint underlyingAmount) internal {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    uint result = cToken.redeemUnderlying(underlyingAmount);
    require(
      result == 0,
      'cToken#redeemUnderlying() failed. see Compound ErrorReporter.sol for more details'
    );
  }

  function redeemEth(uint underlyingAmount) internal {
    uint result = cEth.redeemUnderlying(underlyingAmount);
    require(
      result == 0,
      'cEth#redeemUnderlying() failed. see Compound ErrorReporter.sol for more details'
    );
  }

  function claimComp() internal {
    comptroller.claimComp(address(this));
  }

  function getCompAddress() internal view returns(address) {
    return comptroller.getCompAddress();
  }

  function getUnderlyingAddress(
    address cTokenAddress
  ) 
    internal 
    view 
    returns(address) 
  {
    return CTokenInterface(cTokenAddress).underlying();
  }

  function getcTokenBalance(address cTokenAddress) public view returns(uint){
    return CTokenInterface(cTokenAddress).balanceOf(address(this));
  }

  function getUnderlyingBalance(address cTokenAddress) public returns(uint){
    return CTokenInterface(cTokenAddress).balanceOfUnderlying(address(this));
  }

  function getUnderlyingEthBalance() public returns(uint){
    return cEth.balanceOfUnderlying(address(this));
  }
}

// File: contracts/Wallet.sol

pragma solidity ^0.7.3;



contract Wallet is Compound {
  address public admin;

  constructor(
    address _comptroller, 
    address _cEthAddress
  ) Compound(_comptroller, _cEthAddress) {
    admin = msg.sender;
  }

  function deposit(
    address cTokenAddress, 
    uint underlyingAmount
  ) 
    onlyAdmin()
    external 
  {
    address underlyingAddress = getUnderlyingAddress(cTokenAddress);
    IERC20(underlyingAddress).transferFrom(msg.sender, address(this), underlyingAmount);
    supply(cTokenAddress, underlyingAmount);
  }

  function withdraw(
    address cTokenAddress, 
    uint underlyingAmount,
    address recipient
  ) 
    onlyAdmin()
    external  
  {
    require(
      getUnderlyingBalance(cTokenAddress) >= underlyingAmount, 
      'balance too low'
    );
    claimComp();
    redeem(cTokenAddress, underlyingAmount);

    address underlyingAddress = getUnderlyingAddress(cTokenAddress); 
    IERC20(underlyingAddress).transfer(recipient, underlyingAmount);

    address compAddress = getCompAddress(); 
    IERC20 compToken = IERC20(compAddress);
    uint compAmount = compToken.balanceOf(address(this));
    compToken.transfer(recipient, compAmount);
  }

  function withdrawEth(
    uint underlyingAmount,
    address payable recipient
  ) 
    onlyAdmin()
    external  
  {
    require(
      getUnderlyingEthBalance() >= underlyingAmount, 
      'balance too low'
    );
    claimComp();
    redeemEth(underlyingAmount);

    recipient.transfer(underlyingAmount);

    address compAddress = getCompAddress(); 
    IERC20 compToken = IERC20(compAddress);
    uint compAmount = compToken.balanceOf(address(this));
    compToken.transfer(recipient, compAmount);
  }

  receive() external payable {
    supplyEth(msg.value);
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin');
    _;
  }
}