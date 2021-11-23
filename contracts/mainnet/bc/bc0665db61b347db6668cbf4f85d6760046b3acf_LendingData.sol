// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
interface Geyser{ function totalStakedFor(address addr) external view returns(uint256); }

/**
 * @title Stater Lending Contract
 * @notice Contract that allows users to leverage their NFT assets
 * @author Stater
 */
contract LendingData is ERC721Holder, ERC1155Holder, Ownable {

  // @notice OpenZeppelin's SafeMath library
  using SafeMath for uint256;
  enum TimeScale{ MINUTES, HOURS, DAYS, WEEKS }

  // The address of the Stater NFT collection
  address public nftAddress; //0xcb13DC836C2331C669413352b836F1dA728ce21c

  // The address of the Stater Geyser Contract 
  address[] public geyserAddressArray; //[0xf1007ACC8F0229fCcFA566522FC83172602ab7e3]

  // The address of the Stater Promissory Note Contract
  address public promissoryNoteContractAddress;
  
  uint256[] public staterNftTokenIdArray; //[0, 1]
  
  // 50=50%
  uint32 public discountNft = 50;
  
  // 50=50%
  uint32 public discountGeyser = 50;
  
  // 100 = 1%
  uint32 public lenderFee = 100;
  
  // Incremental value used for loan ids
  uint256 public loanID;

  // Loan to value(ltv). 600=60%
  uint256 public ltv = 600;
  
  uint256 public installmentFrequency = 1;
  TimeScale public installmentTimeScale = TimeScale.WEEKS;
  
  // 20 =20%
  uint256 public interestRate = 20;
  
  // 40=40% out of intersetRate
  uint256 public interestRateToStater = 40;

  enum Status{
      UNINITIALIZED, // will be removed in the future -- not used
      LISTED, // after the loan have been created --> the next status will be APPROVED
      APPROVED, // in this status the loan has a lender -- will be set after approveLoan()
      DEFAULTED, // will be removed in the future -- not used
      LIQUIDATED, // the loan will have this status after all installments have been paid
      CANCELLED, // only if loan is LISTED 
      WITHDRAWN // the final status, the collateral returned to the borrower or to the lender
  }
  enum TokenType{ ERC721, ERC1155 }

  event NewLoan(
    uint256 indexed loanId, 
    address indexed owner, 
    uint256 creationDate, 
    address indexed currency, 
    Status status, 
    address[] nftAddressArray, 
    uint256[] nftTokenIdArray,
    TokenType[] nftTokenTypeArray
  );
  event LoanApproved(
    uint256 indexed loanId, 
    address indexed lender, 
    uint256 approvalDate, 
    uint256 loanPaymentEnd, 
    Status status
  );
  event LoanCancelled(
    uint256 indexed loanId, 
    uint256 cancellationDate, 
    Status status
  );
  event ItemsWithdrawn(
    uint256 indexed loanId, 
    address indexed requester, 
    Status status
  );
  event LoanPayment(
    uint256 indexed loanId, 
    uint256 paymentDate, 
    uint256 installmentAmount, 
    uint256 amountPaidAsInstallmentToLender, 
    uint256 interestPerInstallement, 
    uint256 interestToStaterPerInstallement, 
    Status status
  );

  struct Loan {
    address[] nftAddressArray; // the adderess of the ERC721
    address payable borrower; // the address who receives the loan
    address payable lender; // the address who gives/offers the loan to the borrower
    address currency; // the token that the borrower lends, address(0) for ETH
    Status status; // the loan status
    uint256[] nftTokenIdArray; // the unique identifier of the NFT token that the borrower uses as collateral
    uint256 loanAmount; // the amount, denominated in tokens (see next struct entry), the borrower lends
    uint256 assetsValue; // important for determintng LTV which has to be under 50-60%
    uint256 loanStart; // the point when the loan is approved
    uint256 loanEnd; // the point when the loan is approved to the point when it must be paid back to the lender
    uint256 nrOfInstallments; // the number of installments that the borrower must pay.
    uint256 installmentAmount; // amount expected for each installment
    uint256 amountDue; // loanAmount + interest that needs to be paid back by borrower
    uint256 paidAmount; // the amount that has been paid back to the lender to date
    uint256 defaultingLimit; // the number of installments allowed to be missed without getting defaulted
    uint256 nrOfPayments; // the number of installments paid
    TokenType[] nftTokenTypeArray; // the token types : ERC721 , ERC1155 , ...
  }

  // @notice Mapping for all the loans
  mapping(uint256 => Loan) public loans;

  // @notice Mapping for all the loans that are approved by the owner in order to be used in the promissory note
  mapping(uint256 => address) public promissoryPermissions;

  /**
   * @notice Construct a new lending contract
   * @param _nftAddress The address of the Stater nft collection
   * @param _promissoryNoteContractAddress The address of the Stater Promissory Note contract
   * @param _geyserAddressArray The address of the Stater geyser contract
   * @param _staterNftTokenIdArray Array of the stater nft token IDs
   */
  constructor(address _nftAddress, address _promissoryNoteContractAddress, address[] memory _geyserAddressArray, uint256[] memory _staterNftTokenIdArray) {
    nftAddress = _nftAddress;
    geyserAddressArray = _geyserAddressArray;
    staterNftTokenIdArray = _staterNftTokenIdArray;
    promissoryNoteContractAddress = _promissoryNoteContractAddress;
  }

  // Borrower creates a loan
  /**
   * @notice The borrower creates the loan using the NFT as collateral
   * @param loanAmount The amount of the loan
   * @param nrOfInstallments Loan's number of installments
   * @param currency ETH or custom ERC20
   * @param assetsValue The value of the assets
   * @param nftAddressArray Array of nft addresses in the loan bundle.
   * @param nftTokenIdArray Array of nft token IDs in the loan bundle.
   * @param nftTokenTypeArray The token types : ERC721 , ERC115
   */
  function createLoan(
    uint256 loanAmount,
    uint256 nrOfInstallments,
    address currency,
    uint256 assetsValue, 
    address[] calldata nftAddressArray, 
    uint256[] calldata nftTokenIdArray,
    TokenType[] memory nftTokenTypeArray
  ) external {
    require(nrOfInstallments > 0, "Loan must have at least 1 installment");
    require(loanAmount > 0, "Loan amount must be higher than 0");
    require(nftAddressArray.length > 0, "Loan must have atleast 1 NFT");
    require(nftAddressArray.length == nftTokenIdArray.length && nftTokenIdArray.length == nftTokenTypeArray.length, "NFT provided informations are missing or incomplete");

    // Compute loan to value ratio for current loan application
    require(_percent(loanAmount, assetsValue) <= ltv, "LTV exceeds maximum limit allowed");

    // Computing the defaulting limit
    if ( nrOfInstallments <= 3 )
        loans[loanID].defaultingLimit = 1;
    else if ( nrOfInstallments <= 5 )
        loans[loanID].defaultingLimit = 2;
    else if ( nrOfInstallments >= 6 )
        loans[loanID].defaultingLimit = 3;

    // Set loan fields
    loans[loanID].nftTokenIdArray = nftTokenIdArray;
    loans[loanID].loanAmount = loanAmount;
    loans[loanID].assetsValue = assetsValue;
    loans[loanID].amountDue = loanAmount.mul(interestRate.add(100)).div(100); // interest rate >> 20%
    loans[loanID].nrOfInstallments = nrOfInstallments;
    loans[loanID].installmentAmount = loans[loanID].amountDue.mod(nrOfInstallments) > 0 ? loans[loanID].amountDue.div(nrOfInstallments).add(1) : loans[loanID].amountDue.div(nrOfInstallments);
    loans[loanID].status = Status.LISTED;
    loans[loanID].nftAddressArray = nftAddressArray;
    loans[loanID].borrower = msg.sender;
    loans[loanID].currency = currency;
    loans[loanID].nftTokenTypeArray = nftTokenTypeArray;
 
    // Transfer the items from lender to stater contract
    _transferItems(
        msg.sender, 
        address(this), 
        nftAddressArray, 
        nftTokenIdArray,
        nftTokenTypeArray
    );

    // Fire event
    emit NewLoan(loanID, msg.sender, block.timestamp, currency, Status.LISTED, nftAddressArray, nftTokenIdArray, nftTokenTypeArray);
    ++loanID;
  }

  /**
   * @notice The lender will approve the loan
   * @param loanId The id of the loan 
   */
  function approveLoan(uint256 loanId) external payable {
    require(loans[loanId].lender == address(0), "Someone else payed for this loan before you");
    require(loans[loanId].paidAmount == 0, "This loan is currently not ready for lenders");
    require(loans[loanId].status == Status.LISTED, "This loan is not currently ready for lenders, check later");
    
    uint256 discount = calculateDiscount(msg.sender);
    
    // We check if currency is ETH
    if ( loans[loanId].currency == address(0) )
      require(msg.value >= loans[loanId].loanAmount.add(loans[loanId].loanAmount.div(lenderFee).div(discount)),"Not enough currency");

    // Borrower assigned , status is 1 , first installment ( payment ) completed
    loans[loanId].lender = msg.sender;
    loans[loanId].loanEnd = block.timestamp.add(loans[loanId].nrOfInstallments.mul(generateInstallmentFrequency()));
    loans[loanId].status = Status.APPROVED;
    loans[loanId].loanStart = block.timestamp;

    // We send the tokens here
    _transferTokens(msg.sender,loans[loanId].borrower,loans[loanId].currency,loans[loanId].loanAmount,loans[loanId].loanAmount.div(lenderFee).div(discount));

    emit LoanApproved(
      loanId,
      msg.sender,
      block.timestamp,
      loans[loanId].loanEnd,
      Status.APPROVED
    );
  }

  // Borrower cancels a loan
  function cancelLoan(uint256 loanId) external {
    require(loans[loanId].lender == address(0), "The loan has a lender , it cannot be cancelled");
    require(loans[loanId].borrower == msg.sender, "You're not the borrower of this loan");
    require(loans[loanId].status != Status.CANCELLED, "This loan is already cancelled");
    require(loans[loanId].status == Status.LISTED, "This loan is no longer cancellable");
    
    // We set its validity date as block.timestamp
    loans[loanId].loanEnd = block.timestamp;
    loans[loanId].status = Status.CANCELLED;

    // We send the items back to him
    _transferItems(
      address(this), 
      loans[loanId].borrower, 
      loans[loanId].nftAddressArray, 
      loans[loanId].nftTokenIdArray,
      loans[loanId].nftTokenTypeArray
    );

    emit LoanCancelled(
      loanId,
      block.timestamp,
      Status.CANCELLED
    );
  }
  
  /**
   * @notice Borrower pays installments for the loan
   * @param loanId The id of the loan
   */
  function payLoan(uint256 loanId) external payable {
    require(loans[loanId].borrower == msg.sender, "You're not the borrower of this loan");
    require(loans[loanId].status == Status.APPROVED, "This loan is no longer in the approval phase, check its status");
    require(loans[loanId].loanEnd >= block.timestamp, "Loan validity expired");
    require((msg.value > 0 && loans[loanId].currency == address(0) ) || ( loans[loanId].currency != address(0) && msg.value == 0), "Insert the correct tokens");
    
    uint256 paidByBorrower = msg.value > 0 ? msg.value : loans[loanId].installmentAmount;
    uint256 amountPaidAsInstallmentToLender = paidByBorrower; // >> amount of installment that goes to lender
    uint256 interestPerInstallement = paidByBorrower.mul(interestRate).div(100); // entire interest for installment
    uint256 discount = calculateDiscount(msg.sender);
    uint256 interestToStaterPerInstallement = interestPerInstallement.mul(interestRateToStater).div(100);

    if ( discount != 1 ){
        if ( loans[loanId].currency == address(0) ){
            require(msg.sender.send(interestToStaterPerInstallement.div(discount)), "Discount returnation failed");
            amountPaidAsInstallmentToLender = amountPaidAsInstallmentToLender.sub(interestToStaterPerInstallement.div(discount));
        }
        interestToStaterPerInstallement = interestToStaterPerInstallement.sub(interestToStaterPerInstallement.div(discount));
    }
    amountPaidAsInstallmentToLender = amountPaidAsInstallmentToLender.sub(interestToStaterPerInstallement);

    loans[loanId].paidAmount = loans[loanId].paidAmount.add(paidByBorrower);
    loans[loanId].nrOfPayments = loans[loanId].nrOfPayments.add(paidByBorrower.div(loans[loanId].installmentAmount));

    if (loans[loanId].paidAmount >= loans[loanId].amountDue)
      loans[loanId].status = Status.LIQUIDATED;

    // We transfer the tokens to borrower here
    _transferTokens(msg.sender,loans[loanId].lender,loans[loanId].currency,amountPaidAsInstallmentToLender,interestToStaterPerInstallement);

    emit LoanPayment(
      loanId,
      block.timestamp,
      msg.value,
      amountPaidAsInstallmentToLender,
      interestPerInstallement,
      interestToStaterPerInstallement,
      loans[loanId].status
    );
  }

  /**
   * @notice Borrwoer can withdraw loan items if loan is LIQUIDATED
   * @notice Lender can withdraw loan items if loan is DEFAULTED
   * @param loanId The id of the loan
   */
  function terminateLoan(uint256 loanId) external {
    require(msg.sender == loans[loanId].borrower || msg.sender == loans[loanId].lender, "You can't access this loan");
    require((block.timestamp >= loans[loanId].loanEnd || loans[loanId].paidAmount >= loans[loanId].amountDue) || lackOfPayment(loanId), "Not possible to finish this loan yet");
    require(loans[loanId].status == Status.LIQUIDATED || loans[loanId].status == Status.APPROVED, "Incorrect state of loan");
    require(loans[loanId].status != Status.WITHDRAWN, "Loan NFTs already withdrawn");

    if ( lackOfPayment(loanId) ) {
      loans[loanId].status = Status.WITHDRAWN;
      loans[loanId].loanEnd = block.timestamp;
      // We send the items back to lender
      _transferItems(
        address(this),
        loans[loanId].lender,
        loans[loanId].nftAddressArray,
        loans[loanId].nftTokenIdArray,
        loans[loanId].nftTokenTypeArray
      );
    } else {
      if ( block.timestamp >= loans[loanId].loanEnd && loans[loanId].paidAmount < loans[loanId].amountDue ) {
        loans[loanId].status = Status.WITHDRAWN;
        // We send the items back to lender
        _transferItems(
          address(this),
          loans[loanId].lender,
          loans[loanId].nftAddressArray,
          loans[loanId].nftTokenIdArray,
          loans[loanId].nftTokenTypeArray
        );
      } else if ( loans[loanId].paidAmount >= loans[loanId].amountDue ){
        loans[loanId].status = Status.WITHDRAWN;
        // We send the items back to borrower
        _transferItems(
          address(this),
          loans[loanId].borrower,
          loans[loanId].nftAddressArray,
          loans[loanId].nftTokenIdArray,
          loans[loanId].nftTokenTypeArray
        );
      }
    }
    
    emit ItemsWithdrawn(
      loanId,
      msg.sender,
      loans[loanId].status
    );
  }
  
  /**
   * @notice Used by the Promissory Note contract to change the ownership of the loan when the Promissory Note NFT is sold 
   * @param loanIds The ids of the loans that will be transferred to the new owner
   * @param newOwner The address of the new owner
   */
  function promissoryExchange(uint256[] calldata loanIds, address payable newOwner) external {
      require(msg.sender == promissoryNoteContractAddress, "You're not whitelisted to access this method");
      for (uint256 i = 0; i < loanIds.length; ++i) {
        require(loans[loanIds[i]].lender != address(0), "One of the loans is not approved yet");
        require(promissoryPermissions[loanIds[i]] == msg.sender, "You're not allowed to perform this operation on loan");
        loans[loanIds[i]].lender = newOwner;
      }
  }
  
  /**
   * @notice Used by the Promissory Note contract to approve a list of loans to be used as a Promissory Note NFT
   * @param loanIds The ids of the loans that will be approved
   */
  function setPromissoryPermissions(uint256[] calldata loanIds) external {
      for (uint256 i = 0; i < loanIds.length; ++i) {
          require(loans[loanIds[i]].lender == msg.sender, "You're not the lender of this loan");
          promissoryPermissions[loanIds[i]] = promissoryNoteContractAddress;
      }
  }

  /**
   * @notice Liquidity mining participants or Stater NFT holders will be able to get some discount
   * @param requester The address of the requester
   */
  function calculateDiscount(address requester) public view returns(uint256){
    for (uint i = 0; i < staterNftTokenIdArray.length; ++i)
	    if ( IERC1155(nftAddress).balanceOf(requester,staterNftTokenIdArray[i]) > 0 )
		    return uint256(100).div(discountNft);
	  for (uint256 i = 0; i < geyserAddressArray.length; ++i)
	    if ( Geyser(geyserAddressArray[i]).totalStakedFor(requester) > 0 )
		    return uint256(100).div(discountGeyser);
	  return 1;
  }

  /**
   * @notice This function returns total price (+ fees)
   * @param loanId The id of the loan
   */
  function getLoanApprovalCost(uint256 loanId) external view returns(uint256) {
    return loans[loanId].loanAmount.add(loans[loanId].loanAmount.div(lenderFee).div(calculateDiscount(msg.sender)));
  }
  
  
  /**
   * @notice
   * @param loanId The id of the loan
   */
  function getLoanRemainToPay(uint256 loanId) external view returns(uint256) {
    return loans[loanId].amountDue.sub(loans[loanId].paidAmount);
  }
  
  
  /**
   * @notice
   * @param loanId The id of the loan
   * @param nrOfInstallments The id of the loan
   */
  function getLoanInstallmentCost(
      uint256 loanId,
      uint256 nrOfInstallments
  ) external view returns(
      uint256 overallInstallmentAmount,
      uint256 interestPerInstallement,
      uint256 interestDiscounted,
      uint256 interestToStaterPerInstallement,
      uint256 amountPaidAsInstallmentToLender
  ) {
    require(nrOfInstallments <= loans[loanId].nrOfInstallments, "Number of installments too high");
    uint256 discount = calculateDiscount(msg.sender);
    interestDiscounted = 0;
    
    overallInstallmentAmount = uint256(loans[loanId].installmentAmount.mul(nrOfInstallments));
    interestPerInstallement = uint256(overallInstallmentAmount.mul(interestRate).div(100).div(loans[loanId].nrOfInstallments));
    interestDiscounted = interestPerInstallement.mul(interestRateToStater).div(100).div(discount); // amount of interest saved per installment
    interestToStaterPerInstallement = interestPerInstallement.mul(interestRateToStater).div(100).sub(interestDiscounted);
    amountPaidAsInstallmentToLender = interestPerInstallement.mul(uint256(100).sub(interestRateToStater)).div(100); 
  }
  
  /**
   * @notice This function checks for unpaid installments
   * @param loanId The id of the loan
   */
  function lackOfPayment(uint256 loanId) public view returns(bool) {
    return loans[loanId].status == Status.APPROVED && loans[loanId].loanStart.add(loans[loanId].nrOfPayments.mul(generateInstallmentFrequency())) <= block.timestamp.sub(loans[loanId].defaultingLimit.mul(generateInstallmentFrequency()));
  }

  function generateInstallmentFrequency() public view returns(uint256){
    if (installmentTimeScale == TimeScale.MINUTES) {
      return 1 minutes;  
    } else if (installmentTimeScale == TimeScale.HOURS) {
      return 1 hours;
    } else if (installmentTimeScale == TimeScale.DAYS) {
      return 1 days;
    }
    return 1 weeks;
  }

  /**
   * @notice Setter function for the discounts
   * @param _discountNft Discount value for the Stater NFT holders
   * @param _discountGeyser Discount value for the Stater liquidity mining participants
   * @param _geyserAddressArray List of the Stater Geyser contracts 
   * @param _staterNftTokenIdArray Array of stater nft token IDs.
   * @param _nftAddress List of the Stater NFT collections
   */
  function setDiscounts(uint32 _discountNft, uint32 _discountGeyser, address[] calldata _geyserAddressArray, uint256[] calldata _staterNftTokenIdArray, address _nftAddress) external onlyOwner {
    discountNft = _discountNft;
    discountGeyser = _discountGeyser;
    geyserAddressArray = _geyserAddressArray;
    staterNftTokenIdArray = _staterNftTokenIdArray;
    nftAddress = _nftAddress;
  }
  
  /**
   * @notice Setter function
   * @param _promissoryNoteContractAddress The address of the Stater promissory Note contract
   * @param _ltv Value of Loan to value 
   * @param _installmentFrequency Value of installment frequency
   * @param _installmentTimeScale The timescale of all loans.
   * @param _interestRate Value of interest rate
   * @param _interestRateToStater Value of interest rate to stater
   * @param _lenderFee Value of the lender fee
   */
  function setGlobalVariables(address _promissoryNoteContractAddress, uint256 _ltv, uint256 _installmentFrequency, TimeScale _installmentTimeScale, uint256 _interestRate, uint256 _interestRateToStater, uint32 _lenderFee) external onlyOwner {
    ltv = _ltv;
    installmentFrequency = _installmentFrequency;
    installmentTimeScale = _installmentTimeScale;
    interestRate = _interestRate;
    interestRateToStater = _interestRateToStater;
    lenderFee = _lenderFee;
    promissoryNoteContractAddress = _promissoryNoteContractAddress;
  }
  
  /**
   * @notice Adds a new geyser address to the list
   * @param geyserAddress The new geyser address
   */
  function addGeyserAddress(address geyserAddress) external onlyOwner {
      geyserAddressArray.push(geyserAddress);
  }
  
  /**
   * @notice Adds a new nft to the list
   * @param nftId The id of the new nft
   */
  function addNftTokenId(uint256 nftId) external onlyOwner {
      staterNftTokenIdArray.push(nftId);
  }

  /**
   * @notice Calculates loan to value ration
   * @param numerator Numerator.
   * @param denominator Denominator.
   */
  function _percent(uint256 numerator, uint256 denominator) internal pure returns(uint256) {
    return numerator.mul(10000).div(denominator).add(5).div(10);
  }

  /**
   * @notice Transfer items fron an account to another
   * @param from From account address.
   * @param to To account address.
   * @param nftAddressArray Array of addresses of the nfts to be transfered.
   * @param nftTokenIdArray Array of token IDs of the nfts to be transfered. 
   * @param nftTokenTypeArray Array of token type of the nfts to be transfered.
   */
  function _transferItems(
    address from, 
    address to, 
    address[] memory nftAddressArray, 
    uint256[] memory nftTokenIdArray,
    TokenType[] memory nftTokenTypeArray
  ) internal {
    uint256 length = nftAddressArray.length;
    require(length == nftTokenIdArray.length && nftTokenTypeArray.length == length, "Token infos provided are invalid");
    for(uint256 i = 0; i < length; ++i) 
        if ( nftTokenTypeArray[i] == TokenType.ERC721 )
            IERC721(nftAddressArray[i]).safeTransferFrom(
                from,
                to,
                nftTokenIdArray[i]
            );
        else
            IERC1155(nftAddressArray[i]).safeTransferFrom(
                from,
                to,
                nftTokenIdArray[i],
                1,
                '0x00'
            );
  }
  
  /**
   * @notice Transfer eth or erc20 tokens fron an account to another
   * @param from From account address.
   * @param to To account address.
   * @param currency Address of erc20 token to be transfered, 0x00 for eth.
   * @param qty1 Amount of tokens to be transfered to relevant party account.
   * @param qty2 Amount of tokens to be transfered to this contract's author.
   */
  function _transferTokens(
      address from,
      address payable to,
      address currency,
      uint256 qty1,
      uint256 qty2
  ) internal {
      if ( currency != address(0) ){
          require(IERC20(currency).transferFrom(
              from,
              to, 
              qty1
          ), "Transfer of tokens to receiver failed");
          require(IERC20(currency).transferFrom(
              from,
              owner(), 
              qty2
          ), "Transfer of tokens to Stater failed");
      }else{
          require(to.send(qty1), "Transfer of ETH to receiver failed");
          require(payable(owner()).send(qty2), "Transfer of ETH to Stater failed");
      }
  }

}