//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IFixedRateLoanMarket.sol";
import "./interfaces/IQollateralManager.sol";
import "./libraries/Math.sol";
import "./libraries/QConst.sol";
import "./libraries/QTypes.sol";
import "./libraries/QVerifier.sol";
import "./libraries/SafeERC20.sol";
import "./types/ERC20.sol";

contract FixedRateLoanMarket is IFixedRateLoanMarket, ERC20 {

  using SafeERC20 for IERC20;
  
  /// @notice Address of the `QollateralManager`
  address private _qollateralManagerAddress;

  /// @notice Address of the ERC20 token which the loan will be denominated
  address private _principalTokenAddress;
  
  /// @notice UNIX timestamp (in seconds) when the market matures
  uint private _maturity;

  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicate.
  /// account => nonce => bool
  mapping(address => mapping(uint => bool)) private _noncesUsed;

  /// @notice Storage for all borrows by a user
  /// account => principalPlusInterest
  mapping(address => uint) private _accountBorrows;
  
  /// @notice Storage for the current total partial fill for a Quote
  /// signature => filled
  mapping(bytes => uint) private _quoteFill;

  /// @notice Emitted when a borrower repays borrow
  event RepayBorrow(address borrower, uint amount);

  /// @notice Emitted when a borrower repays borrower using qTokens
  event RepayBorrowWithqToken(address borrower, uint amount);
  
  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      address borrower,
                      address lender,
                      uint principal,
                      uint principalPlusInterest);

  /// @notice Emitted when an account cancels their Quote
  event CancelQuote(address account, uint nonce);
  
  constructor(
              address qollateralManagerAddress_,
              address principalTokenAddress_,
              uint maturity_,
              string memory _name,
              string memory _symbol
              ) ERC20(_name, _symbol) {
    _qollateralManagerAddress = qollateralManagerAddress_;
    _principalTokenAddress = principalTokenAddress_;
    _maturity = maturity_;
  }
  
  /** USER INTERFACE **/

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param amount Amount that the borrower wants to execute, in case its not full size
  /// @param lender Account of the lender
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function borrow(                  
                  uint amount,
                  address lender,
                  uint quoteExpiryTime,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external {
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             lender,
                                             1, // side = 1 for lender
                                             quoteExpiryTime,
                                             principal,
                                             principalPlusInterest,
                                             nonce,
                                             signature
                                             );
    _processLoan(amount, quote);
  }

  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param amount Amount that the lender wants to execute, in case its not full size
  /// @param borrower Account of the borrower
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function lend(
                uint amount,
                address borrower,
                uint quoteExpiryTime,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external {
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             borrower,
                                             0, //side = 0 for borrower
                                             quoteExpiryTime,
                                             principal,
                                             principalPlusInterest,
                                             nonce,
                                             signature
                                             );
    _processLoan(amount, quote);
  }

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint){
    
    // Don't allow users to pay more than necessary
    amount = Math.min(amount, _accountBorrows[msg.sender]);

    // Repayment amount must be positive
    require(amount > 0, "zero repay amount");

    // Check borrower has approved contract spend    
    require(_checkApproval(msg.sender, _principalTokenAddress, amount),
            "insufficient allowance");

    // Check borrower has enough balance
    require(_checkBalance(msg.sender, _principalTokenAddress, amount),
            "insufficient balance");

    // Effects: Deduct from the account's total debts
    // Guaranteed not to underflow due to the flooring on amount above
    _accountBorrows[msg.sender] -= amount;

    // Transfer amount from borrower to contract for escrow until maturity
    IERC20 principalToken = IERC20(_principalTokenAddress);
    principalToken.safeTransferFrom(msg.sender, address(this), amount);

    // Emit the event
    emit RepayBorrow(msg.sender, amount);

    return _accountBorrows[msg.sender];
  }

  /// @notice Borrower makes repayment with qTokens. The qTokens will automatically
  /// get burned and the accountBorrows deducted accordingly.
  /// @param amount Amount to pay in qTokens
  /// @return uint Remaining account borrow amount
  function repayBorrowWithqToken(uint amount) external returns(uint){
    return _repayBorrowWithqToken(msg.sender, amount);
  }

  /// @notice By setting the nonce in `_noncesUsed` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external {

    // Set the value to true for the `_noncesUsed` mapping
    _noncesUsed[msg.sender][nonce] = true;

    // Emit the event
    emit CancelQuote(msg.sender, nonce);
  }
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManagerAddress() external view returns(address){
    return _qollateralManagerAddress;
  }

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function principalTokenAddress() external view returns(address){
    return _principalTokenAddress;
  }

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint){
    return _maturity;
  }
  
  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function noncesUsed(address account, uint nonce) external view returns(bool){
    return _noncesUsed[account][nonce];
  }

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint){
    return _accountBorrows[account];
  }

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint){
    return _quoteFill[signature];
  }
    
  /** INTERNAL FUNCTIONS **/

  /// @notice Intermediary function that handles some error handling, partial fills
  /// and managing uniqueness of nonces
  /// @param amount Amount msg.sender wants to execute, in case its not full size
  /// @param quote Quote struct for code simplicity / avoiding 'stack too deep' error
  function _processLoan(uint amount, QTypes.Quote memory quote) internal {

    address signer = QVerifier.getSigner(
                                        quote.marketAddress,
                                        quote.quoter,
                                        quote.side,
                                        quote.quoteExpiryTime,
                                        quote.principal,
                                        quote.principalPlusInterest,
                                        quote.nonce,
                                        quote.signature
                                        );

    // Check if signature is valid
    require(signer == quote.quoter, "invalid signature");
    
    // Check that quote hasn't expired yet
    require(quote.quoteExpiryTime == 0 ||
            quote.quoteExpiryTime > block.timestamp,
            "quote expired");

    // The borrow amount cannot be greater than the remaining Quote size
    amount = Math.min(amount, quote.principal - _quoteFill[quote.signature]);
    require(amount > 0, "quote already filled");

    // Check that the nonce hasn't already been used
    require(!_noncesUsed[quote.quoter][quote.nonce], "invalid nonce");

    // TODO: Still need to check if borrower has sufficient collateral for loan
    
    // For partial fills, get the equivalent `amountPlusInterest` to pay at the end
    uint amountPlusInterest = _scaleAmountWithInterest(
                                                       amount,
                                                       quote.principal,
                                                       quote.principalPlusInterest
                                                       );
    
    // Determine who is the lender and who is the borrower before instantiating loan
    if(quote.side == 1){
      // If quote.side = 1, the quoter is the lender
      _createFixedRateLoan(msg.sender, quote.quoter, amount, amountPlusInterest);
    }else if (quote.side == 0){
      // If quote.side = 0, the quoter is the borrower
      _createFixedRateLoan(quote.quoter, msg.sender, amount, amountPlusInterest);
    }else {
      revert("invalid side"); //should not reach here
    }

    // Update the partial fills for the quote
    _quoteFill[quote.signature] += amount;
    
    // Nonce is used up once the partial fill equals the original principal amount
    if(_quoteFill[quote.signature] == quote.principal){
      _noncesUsed[quote.quoter][quote.nonce] = true;
    }
  }

  /// @notice Mint the future payment tokens to the lender, add the
  /// `principalPlusInterest` amount to the borrower's debts, and transfer the
  /// loan principal from lender to borrower
  /// @param borrower Account of the borrower
  /// @param lender Account of the lender
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  function _createFixedRateLoan(
                                address borrower,
                                address lender,
                                uint principal,
                                uint principalPlusInterest
                                ) internal {

    // Loan amount must be strictly positive
    require(principal > 0, "invalid principal amount");

    // Interest rate needs to be positive
    require(principal < principalPlusInterest, "invalid principalPlusInterest");

    // Cannot borrow from yourself
    require(lender != borrower, "invalid counterparty");

    // Cannot create a loan past its maturity time
    require(block.timestamp < _maturity, "invalid _maturity");

    // Check lender has approved contract spend
    require(_checkApproval(lender, _principalTokenAddress, principal),
            "lender insufficient allowance");

    // Check lender has enough balance
    require(_checkBalance(lender, _principalTokenAddress, principal),
            "lender insufficient balance");

    // The borrow amount of the borrower increases by the full `principalPlusInterest`
    _accountBorrows[borrower] += principalPlusInterest;

    // Net off the borrow amount with any balance of qTokens the borrower may have
    uint repayAmountBorrower = Math.min(_accountBorrows[borrower], balanceOf(borrower));
    if(repayAmountBorrower > 0){
      _repayBorrowWithqToken(borrower, repayAmountBorrower);
    }

    // Lender receives `principalPlusInterest` amount in qTokens
    _mint(lender, principalPlusInterest);

    // Net off the minted amount with any borrow amounts the lender may have
    uint repayAmountLender = Math.min(_accountBorrows[lender], balanceOf(lender));
    if(repayAmountLender > 0){
      _repayBorrowWithqToken(lender, repayAmountLender);
    }
    
    // Record that the lender/borrow have participated in this market
    IQollateralManager qm = IQollateralManager(_qollateralManagerAddress);
    if(!qm.accountMarkets(address(this), lender)){
      qm._addAccountMarket(lender);
    }
    if(!qm.accountMarkets(address(this), borrower)){
      qm._addAccountMarket(borrower);
    }
    
    // Emit the matched borrower and lender and fixed rate loan terms
    emit FixedRateLoan(borrower, lender, principal, principalPlusInterest);
    
    // Transfer the principal from lender to borrower
    IERC20 principalToken = IERC20(_principalTokenAddress);
    principalToken.safeTransferFrom(lender, borrower, principal);
  }

  /// @notice Borrower makes repayment with qTokens. The qTokens will automatically
  /// get burned and the accountBorrows deducted accordingly.
  /// @param account User account
  /// @param amount Amount to pay in qTokens
  /// @return uint Remaining account borrow amount
  function _repayBorrowWithqToken(address account, uint amount) internal returns(uint){
    require(amount <= balanceOf(account), "ERC20: Amount exceeds balance");

    // Don't allow users to pay more than necessary
    amount = Math.min(_accountBorrows[account], amount);

    // Burn the qTokens from the account and subtract the amount for the user's borrows
    _burn(account, amount);
    _accountBorrows[account] -= amount;

    // Emit the repayment event
    emit RepayBorrowWithqToken(account, amount);

    // Return the remaining account borrow amount
    return _accountBorrows[account];
  }

  /// @notice Applies the implied interest on the amount given the starting principal and
  /// ending principalPlusInterest
  /// @param amount Value to apply the implied interest on
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @return uint Amount plus interest
  function _scaleAmountWithInterest(
                                    uint amount,
                                    uint principal,
                                    uint principalPlusInterest
                                    ) internal pure returns(uint){
    uint rate = principalPlusInterest * QConst.MANTISSA_DEFAULT / principal;
    uint amountPlusInterest = amount * rate / QConst.MANTISSA_DEFAULT;
    return amountPlusInterest;
  }
                                    
  /// @notice Verify if the user has enough token balance
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address userAddress,
                         address tokenAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }
  
  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address userAddress,
                          address tokenAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }




  /** ERC20 Implementation **/

  /// @notice Number of decimal places of the qToken should match the number
  /// of decimal places of the underlying token
  /// @return uint8 Number of decimal places
  function decimals() public view override(ERC20, IERC20Metadata) returns(uint8) {
    //TODO possible for ERC20 to not define decimals. Do we need to handle this?
    return IERC20Metadata(_principalTokenAddress).decimals();
  }
  
  /// @notice This hook requires users trying to transfer their qTokens to only
  /// be able to transfer tokens in excess of their current borrows. This is to
  /// protect the protocol from users gaming the collateral management system
  /// by borrowing off of the qToken and then immediately transferring out the
  /// qToken to another address, leaving the borrowing account uncollateralized
  /// @param from Address of the sender
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to send
  function _beforeTokenTransfer(
                                address from,
                                address to,
                                uint256 amount
                                ) internal override {

    // Ignore hook for 0x000... address (e.g. _mint, _burn functions)
    if(from == address(0) || to == address(0)){
      return;
    }

    // Transfers rejected if borrows exceed lends
    require(balanceOf(from) > _accountBorrows[from], "ERC20: account borrows exceeds balance");
    
    // Safe from underflow after previous require statement
    unchecked {
      uint maxTransferrable = balanceOf(from) - _accountBorrows[from];
      require(amount <= maxTransferrable, "ERC20: amount must be in excess of borrows");
    }
      
  }

  /// @notice This hook requires users to automatically repay any borrows their
  /// accounts may still have after receiving the qTokens
  /// @param from Address of the sender
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to send
  function _afterTokenTransfer(
                                address from,
                                address to,
                                uint256 amount
                                ) internal override {
    
    // Ignore hook for 0x000... address (e.g. _mint, _burn functions)
    if(from == address(0) || to == address(0)){
      return;
    }
    
    if(_accountBorrows[to] > 0){
      uint amountOwed = Math.min(_accountBorrows[to], amount);
      _repayBorrowWithqToken(to, amountOwed);
    }    
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IFixedRateLoanMarket is IERC20, IERC20Metadata {

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param amount Amount that the borrower wants to execute, in case its not full size
  /// @param lender Account of the lender
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function borrow(
                  uint amount,
                  address lender,
                  uint quoteExpiryTime,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external;
  
  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param amount Amount that the lender wants to execute, in case its not full size
  /// @param borrower Account of the borrower
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function lend(
                uint amount,
                address borrower,
                uint quoteExpiryTime,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external;

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint);

  /// @notice Borrower makes repayment with qTokens. The qTokens will automatically
  /// get burned and the accountBorrows deducted accordingly.
  /// @param amount Amount to pay in qTokens
  /// @return uint Remaining account borrow amount
  function repayBorrowWithqToken(uint amount) external returns(uint);
  
  /// @notice By setting the nonce in  `noncesUsed` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external;



  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManagerAddress() external view returns(address);
  
  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function principalTokenAddress() external view returns(address);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);
  
  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function noncesUsed(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint);

  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  /* event FixedRateLoan( */
  /*                     address borrower, */
  /*                     address lender, */
  /*                     uint principal, */
  /*                     uint principalPlusInterest); */
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQollateralManager {

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  function depositCollateral(address tokenAddress, uint amount) external;

  /// @notice Get the unweighted value (in USD) for the tokens deposited
  /// for an account
  /// @param tokenAddress Address of ERC20 token
  /// @param account Account to query
  /// @return uint Value of token collateral of account in USD
  function collateralValue(
                           address tokenAddress,
                           address account
                           ) external view returns(uint);

  /// @notice Get the `riskFactor` weighted value (in USD) for the tokens deposited
  /// for an account
  /// @param tokenAddress Address of ERC20 token
  /// @param account Account to query
  /// @return uint Value of token collateral of account in USD
  function collateralValueWeighted(
                                   address tokenAddress,
                                   address account
                                   ) external view returns(uint);
  
  /// @notice get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function totalCollateralValue(address account) external view returns(uint);

  /// @notice get the `riskFactor` weighted value (in USD) of all the collateral
  /// deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function totalCollateralValueWeighted(address account) external view returns(uint);

  /// @notice Get the net value borrowed (i.e. borrows - lends) in USD for a
  /// particular Market
  /// @param marketAddress Address of the `FixedRateLoanMarket` contract
  /// @param account Accoutn to query
  /// @return uint Borrow value of account in USD
  function netBorrowValue(address marketAddress, address account) external view returns(uint);

  /// @notice Get the net value borrowed (i.e. borrows - lends) in USD for all
  /// Markets participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function totalNetBorrowValue(address account) external view returns(uint);
  
  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8);

  /// @notice Get the address of the `Qontroller` contract
  function qontrollerAddress() external view returns(address);
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account  
  /// @return uint Balance in local
  function accountBalances(
                           address tokenAddress,
                           address account
                           ) external view returns(uint);
  
  /// @notice Get iterable list of assets which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableAccountAssets(address account) external view returns(address[] memory);

  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(address[] memory);

  /// @notice Quick lookup of whether an account has nonzero balance in an asset.
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account
  /// @return bool True if user has balance, false otherwise
  function accountAssets(address tokenAddress, address account) external view returns(bool);

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param account User account
  /// @return bool True if participated, false otherwise
  function accountMarkets(address marketAddress, address account) external view returns(bool);

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateLoanMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `totalBorrowValue`. Only the `FixedRateLoanMarket` contract itself may call
  /// this function
  /// @param account User account
  function _addAccountMarket(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QConst {
  
  /// @notice Generic mantissa corresponding to ETH decimals
  uint internal constant MANTISSA_DEFAULT = 1e18;

  /// @notice Mantissa for stablecoins
  uint internal constant MANTISSA_STABLECOIN = 1e6;
  
  /// @notice `riskFactor` has up to 8 decimal places precision
  uint internal constant MANTISSA_RISK_FACTOR = 1e8;

  /// @notice `riskFactor` cannot be below .05
  uint internal constant MIN_RISK_FACTOR = .05e8;

  /// @notice `riskFactor` cannot be above .95
  uint internal constant MAX_RISK_FACTOR = .95e8;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member riskFactor Value from 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    address oracleFeed;
    uint riskFactor;
    uint[] maturities;
  }

  

  
  /// @notice Contains all the fields of a FixedRateLoan agreement
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member maturity Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }

  /// @notice Contains all the fields of a published Quote
  /// @param marketAddress Address of the `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  struct Quote {
    address marketAddress;
    address quoter;
    uint8 side;
    uint quoteExpiryTime;
    uint principal;
    uint principalPlusInterest;
    uint nonce;
    bytes signature;
  }
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QVerifier {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return address signer of the message
  function getSigner(
                     address marketAddress,
                     address quoter,
                     uint8 side,
                     uint quoteExpiryTime,
                     uint principal,
                     uint principalPlusInterest,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         marketAddress,
                                         quoter,
                                         side,
                                         quoteExpiryTime,
                                         principal,
                                         principalPlusInterest,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param marketAddress Address `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @return bytes32 message hash
  function getMessageHash(
                          address marketAddress,
                          address quoter,
                          uint8 side,
                          uint quoteExpiryTime,
                          uint principal,
                          uint principalPlusInterest,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        marketAddress,
                                                        quoter,
                                                        side,
                                                        quoteExpiryTime,
                                                        principal,
                                                        principalPlusInterest,
                                                        nonce
                                                        ));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", unprefixedHash));
  }

  /// @notice Recovers the address of the signer of the `messageHash` from the signature. It should be used to check versus the cleartext address given to verify the message is indeed signed by the owner
  /// @param messageHash Hash of the loan fields
  /// @param signature The candidate signature to recover the signer from
  /// @return address This is the recovered signer of the `messageHash` using the signature
  function _recoverSigner(
                         bytes32 messageHash,
                         bytes memory signature
                         ) private pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the messageHash and signature
    return ecrecover(messageHash, v, r, s);
  }

  
  /// @notice Helper function that splits the signature into r,s,v components
  /// @param signature The candidate signature to recover the signer from
  /// @return r bytes32, s bytes32, v uint8
  function _splitSignature(bytes memory signature) private pure returns(
                                                                      bytes32 r,
                                                                      bytes32 s,
                                                                      uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../libraries/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}