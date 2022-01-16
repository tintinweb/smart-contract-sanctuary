/**
 *Submitted for verification at polygonscan.com on 2022-01-16
*/

pragma solidity 0.8.11;
//SPDX-License-Identifier: UNLICENSED

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @title a NFT as collateral lending protocol
/// @author tobou.eth
/// @notice POC of a protocol unlocking medium-sized NFT collections to be used as collateral 
/// for loans in USDC, for NFTHack 2022
contract PoolFi {
  uint256 internal constant RAY = 1e27;

  // config
  uint immutable public START_DATE; // date after which borrowing can start
  uint immutable public EXPIRATION_DATE; // no repay possible after this date
  uint immutable public DEATH_DATE; // suppliers can withdraw their funds after this date
  uint immutable public BORROW_SPR; // interest rate per second for borrowers, in ray
  IERC20 immutable private USDC;
  mapping(IERC721 => uint) public assetPrice;

  struct Loan {
    IERC721 collection;
    uint tokenId;
    uint loanDate;
    uint amount;
    address borrowedBy;
  }

  uint totalSupplied;
  uint totalBorrowed;
  uint totalRepaid;
  uint nbOfLoans;
  mapping(address => uint) suppliedBy;
  mapping(uint => Loan) public loan;

  event Supplied(address indexed supplier, uint amount);
  event Borrowed(address indexed borrower, uint loanId,  uint amount);
  event Repaid(uint indexed loanId, uint amount);
  event Bought(uint indexed loanId, uint price);
  event Withdrew(address indexed supplier, uint amount);

  error SuppliesAreClosed();
  error CollectionNotWhitelisted(IERC721 collection);
  error BorrowsAndRepaysAreClosed();
  error AuctionNotYetStarted();
  error LiquidityNotYetUnlocked();
  error SenderIsNotTheBorrower(address sender);

  constructor(
    uint startDate,
    uint expirationDate,
    uint deathDate,
    IERC20 usdc,
    uint borrowSPR,
    IERC721[] memory collections,
    uint[] memory _assetPrices
  ) {
    require(block.timestamp < startDate && startDate < expirationDate && expirationDate < deathDate);

    START_DATE = startDate;
    EXPIRATION_DATE = expirationDate;
    DEATH_DATE = deathDate;
    USDC = usdc;
    BORROW_SPR = borrowSPR;
    for(uint i; i < collections.length; i++){
      assetPrice[collections[i]] = _assetPrices[i];
    }
  }

  /// @notice supply USDC to the pool before its start date
  /// @dev contract must have `amount` allowed for spending 
  function supply(uint amount) public {
    if (block.timestamp >= START_DATE) revert SuppliesAreClosed();

    USDC.transferFrom(msg.sender, address(this), amount);
    suppliedBy[msg.sender] += amount;
    totalSupplied += amount;

    emit Supplied(msg.sender, amount);
  }

  /// @notice borrow USDC by providing a NFT as collateral
  /// @dev contract must be allowed to spend the asset
  function borrow(IERC721 collection, uint tokenId) public {
    if (assetPrice[collection] == 0) revert CollectionNotWhitelisted(collection);
    if (block.timestamp < START_DATE || block.timestamp >= EXPIRATION_DATE) revert BorrowsAndRepaysAreClosed();

    IERC721(collection).transferFrom(msg.sender, address(this), tokenId);
    uint amount = assetPrice[collection] - calculateInterests(assetPrice[collection], EXPIRATION_DATE - block.timestamp);
    loan[nbOfLoans] = Loan({
      collection: collection,
      tokenId: tokenId,
      loanDate: block.timestamp,
      amount: amount,
      borrowedBy: msg.sender
    });
    USDC.transfer(msg.sender, amount);
    totalBorrowed += amount;

    emit Borrowed(msg.sender, nbOfLoans, amount);
    nbOfLoans++;
  }

  /// @notice repay lended USDC + interests & get back the NFT collateral
  function repay(uint loanId) public {
    if (loan[loanId].borrowedBy != msg.sender) revert SenderIsNotTheBorrower(msg.sender);
    if (block.timestamp >= EXPIRATION_DATE) revert BorrowsAndRepaysAreClosed();

    uint repaid = loan[loanId].amount + calculateInterests(loan[loanId].amount, block.timestamp - loan[loanId].loanDate);
    USDC.transferFrom(msg.sender, address(this), repaid);
    IERC721(loan[loanId].collection).transferFrom(address(this), msg.sender, loan[loanId].tokenId);
    totalRepaid += repaid;

    emit Repaid(loanId, repaid);
  }

  /// @notice buy a NFT of a loan that weren't repaid, price determined by a dutch auction
  function buy(uint loanId) public {
    if (block.timestamp < EXPIRATION_DATE) revert AuctionNotYetStarted();

    uint elapsedTimeSinceAuctionStart = block.timestamp - EXPIRATION_DATE;
    uint auctionDuration = DEATH_DATE - EXPIRATION_DATE;
    // start price is 150% of the predetermined price
    uint startPrice = assetPrice[loan[loanId].collection] * 3 / 2;
    uint priceDiscount = (RAY * startPrice * elapsedTimeSinceAuctionStart / auctionDuration) / RAY;
    uint price = priceDiscount < startPrice ? startPrice - priceDiscount : 0;

    USDC.transferFrom(msg.sender, address(this), price);
    totalRepaid += price;
    IERC721(loan[loanId].collection).transferFrom(address(this), msg.sender, loan[loanId].tokenId);

    emit Bought(loanId, price);
  }

  /// @notice get all USDC gained during the pool lifetime as a supplier
  function withdraw() public {
    if (block.timestamp < DEATH_DATE) revert LiquidityNotYetUnlocked();

    uint amount = suppliedBy[msg.sender] * (totalSupplied + totalRepaid - totalBorrowed) / totalSupplied;
    USDC.transfer(msg.sender, amount);
    suppliedBy[msg.sender] = 0;

    emit Withdrew(msg.sender, amount);
  }

  function calculateInterests(uint amount, uint elapsedTime) private view returns(uint) {
    return elapsedTime * BORROW_SPR * amount / RAY;
  }
}