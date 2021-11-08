// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./SigningUtils.sol";
import "./LeverStorage.sol";
import "./interfaces/LeverNFTInterface.sol";

// @title  Main contract for protocol. This contract manages the ability to create
//         NFT-backed peer-to-peer loans.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth, and
//         kittybounties.eth
// @notice There are five steps needed to commence an NFT-backed loan. First,
//         the borrower calls nftContract.approveAll(protocol), approving the protocol
//         contract to move their NFT's on their behalf. Second, the borrower
//         signs an off-chain message for each NFT that they would like to
//         put up for collateral. This prevents borrowers from accidentally
//         lending an NFT that they didn't mean to lend, due to approveAll()
//         approving their entire collection. Third, the lender calls
//         erc20Contract.approve(protocol), allowing protocol to move the lender's
//         ERC20 tokens on their behalf. Fourth, the lender signs an off-chain
//         message, proposing the amount, rate, and duration of a loan for a
//         particular NFT. Fifth, the borrower calls protocol.beginLoan() to
//         accept these terms and enter into the loan. The NFT is stored in the
//         contract, the borrower receives the loan principal in the specified
//         ERC20 currency, and the lender receives an protocol promissory note (in
//         ERC721 form) that represents the rights to either the
//         principal-plus-interest, or the underlying NFT collateral if the
//         borrower does not pay back in time. The lender can freely transfer
//         and trade this ERC721 promissory note as they wish, with the
//         knowledge that transferring the ERC721 promissory note tranfsers the
//         rights to principal-plus-interest and/or collateral, and that they
//         will no longer have a claim on the loan. The ERC721 promissory note
//         itself represents that claim.
// @notice A loan may end in one of two ways. First, a borrower may call
//         protocol.payBackLoan() and pay back the loan plus interest at any time,
//         in which case they receive their NFT back in the same transaction.
//         Second, if the loan's duration has passed and the loan has not been
//         paid back yet, a lender can call protocol.liquidateOverdueLoan(), in
//         which case they receive the underlying NFT collateral and forfeit
//         the rights to the principal-plus-interest, which the borrower now
//         keeps.
contract Lever is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    SigningUtils,
    LeverStorage
{
    /* ****** */
    /* EVENTS */
    /* ****** */

    // @notice This event is fired whenever the admins change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  newAdminFee - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    event AdminFeeUpdated(uint256 newAdminFee);

    // @notice This event is fired whenever the admins change the origination fee
    // @param  newOriginationFee - The new origination fee measured in basis points
    event OriginationFeeUpdated(uint256 newOriginationFee);

    // @notice This event is fired whenever a borrower begins a loan by calling
    //         protocol.beginLoan(), which can only occur after both the lender
    //         and borrower have approved their ERC721 and ERC20 contracts to
    //         use protocol, and when they both have signed off-chain messages that
    //         agree on the terms of the loan.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  loanStartTime - The block.timestamp when the loan first began
    //         (measured in seconds).
    // @param  loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  loanInterestRateInBasisPoints - This is the annual percentage interest rate
    //         (measured in basis points, e.g. hundreths of a percent) for the loan, that
    //         must be repaid pro-rata by the borrower at the conclusion of the
    //         loan or risk seizure of their nft collateral.
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    // @param  loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    event LoanStarted(
        uint256 loanId,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 loanStartTime,
        uint256 loanDuration,
        uint256 loanInterestRateInBasisPoints,
        address nftCollateralContract,
        address loanERC20Denomination,
        address lender,
        address borrower,
        bytes lenderSignature
    );

    // @notice This event is fired whenever a borrower successfully repays
    //         their loan, paying principal-plus-interest-minus-fee to the
    //         lender in loanERC20Denomination, paying fee to owner in
    //         loanERC20Denomination, and receiving their NFT collateral back.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  borrower - The address of the borrower.
    // @param  lender - The address of the lender. The lender can change their
    //         address by transferring the protocol ERC721 token that they
    //         received when the loan began.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  amountPaidToLender The amount of ERC20 that the borrower paid to
    //         the lender, measured in the smalled units of
    //         loanERC20Denomination.
    // @param  totalProtocolFee fees collected from interest payment and loan origination
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    // @param  loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    event LoanRepaid(
        uint256 loanId,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 amountPaidToLender,
        uint256 totalProtocolFee,
        address nftCollateralContract,
        address loanERC20Denomination
    );

    // @notice This event is fired whenever a lender liquidates an outstanding
    //         loan that is owned to them that has exceeded its duration. The
    //         lender receives the underlying NFT collateral, and the borrower
    //         no longer needs to repay the loan principal-plus-interest.
    // @param  loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  loanPrincipalAmount - The original sum of money transferred from
    //         lender to borrower at the beginning of the loan, measured in
    //         loanERC20Denomination's smallest units.
    // @param  nftCollateralId - The ID within the NFTCollateralContract for the
    //         NFT being used as collateral for this loan. The NFT is stored
    //         within this contract during the duration of the loan.
    // @param  loanMaturityDate - The unix time (measured in seconds) that the
    //         loan became due and was eligible for liquidation.
    // @param  loanLiquidationDate - The unix time (measured in seconds) that
    //         liquidation occurred.
    // @param  nftCollateralContract - The ERC721 contract of the NFT collateral
    event LoanLiquidated(
        uint256 loanId,
        uint256 loanPrincipalAmount,
        uint256 nftCollateralId,
        uint256 loanMaturityDate,
        uint256 loanLiquidationDate,
        address nftCollateralContract
    );
    // @notice This event is fired whenever a loan is refinanced
    // @param  oldLoanId - A unique identifier for the loan being refinanced.
    // @param  newLoanId - A unique identifier for the new loan created to pay off the old loan.
    event LoanRefinanced(uint256 oldLoanId, uint256 newLoanId);

    /**
     * @notice Initialize the contract with admin, WETH, and BAYC
     */
    function initialize(address _admin, address _nftAddress)
        public
        initializer
    {
        __Ownable_init();
        transferOwnership(_admin);

        // Configuation
        nftAddress = _nftAddress;
        maximumLoanDuration = 53 weeks;
        maximumNumberOfActiveLoans = 1000;
        adminFeeInBasisPoints = 25;

        // Whitelist mainnet WETH
        erc20CurrencyIsWhitelisted[
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        ] = true;

        // Whitelist mainnet BAYC
        nftContractIsWhitelisted[
            address(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D)
        ] = true;
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice This function can be called by admins to change the whitelist
    //         status (boolean) of an ERC20 currency used as the loan denomination.
    // @param  _erc20Currency - The address of the ERC20 contract whose whitelist
    //         status is to be changed.
    // @param  _setAsWhitelisted - The new status of whether the contract is
    //         whitelisted or not.
    function whitelistERC20Currency(
        address _erc20Currency,
        bool _setAsWhitelisted
    ) external onlyOwner {
        erc20CurrencyIsWhitelisted[_erc20Currency] = _setAsWhitelisted;
    }

    // @notice This function can be called by admins to change the whitelist
    //         status of an NFT contract. This includes both adding an NFT
    //         contract to the whitelist and removing it.
    // @param  _nftContract - The address of the NFT contract whose whitelist
    //         status changed.
    // @param  _setAsWhitelisted - The new status of whether the contract is
    //         whitelisted or not.
    function whitelistNFTContract(address _nftContract, bool _setAsWhitelisted)
        external
        onlyOwner
    {
        nftContractIsWhitelisted[_nftContract] = _setAsWhitelisted;
    }

    // @notice This function can be called by admins to change the
    //         maximumLoanDuration. Note that they can never change
    //         maximumLoanDuration to be greater than UINT32_MAX, since that's
    //         the maximum space alotted for the duration in the loan struct.
    // @param  _newMaximumLoanDuration - The new maximum loan duration, measured
    //         in seconds.
    function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration)
        external
        onlyOwner
    {
        require(
            _newMaximumLoanDuration <= uint256(type(uint32).max),
            "loan duration cannot exceed space alotted in struct"
        );
        maximumLoanDuration = _newMaximumLoanDuration;
    }

    // @notice This function can be called by admins to change the
    //         maximumNumberOfActiveLoans.
    // @param  _newMaximumNumberOfActiveLoans - The new maximum number of
    //         active loans, used to limit the risk that protocol faces while the
    //         project is first getting started.
    function updateMaximumNumberOfActiveLoans(
        uint256 _newMaximumNumberOfActiveLoans
    ) external onlyOwner {
        maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
    }

    // @notice This function can be called by admins to change the percent of
    //         interest rates earned that they charge as a fee. Note that
    //         newAdminFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  _newAdminFeeInBasisPoints - The new admin fee measured in basis points. This
    //         is a percent of the interest paid upon a loan's completion that
    //         go to the contract admins.
    function updateAdminFee(uint256 _newAdminFeeInBasisPoints)
        external
        onlyOwner
    {
        require(
            _newAdminFeeInBasisPoints <= 10000,
            "By definition, basis points cannot exceed 10000"
        );
        adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
        emit AdminFeeUpdated(_newAdminFeeInBasisPoints);
    }

    // @notice This function can be called by admins to change the percent of principal
    //         charged by the contract for originating a loan. Note that
    //         newOriginationFee can never exceed 10,000, since the fee is measured
    //         in basis points.
    // @param  _newOriginationFeeInBasisPoints - The new origination fee measured in basis points. This
    //         is a percent of the principal of the loan taken upon a loan's completion that
    //         go to the contract admins.
    function updateOriginationFee(uint256 _newOriginationFeeInBasisPoints)
        external
        onlyOwner
    {
        require(
            _newOriginationFeeInBasisPoints <= 10000,
            "By definition, basis points cannot exceed 10000"
        );
        originationFeeInBasisPoints = _newOriginationFeeInBasisPoints;
        emit OriginationFeeUpdated(_newOriginationFeeInBasisPoints);
    }

    // @notice This function is called by a borrower when they want to commence
    //         a loan, but can only be called after first: (1) the borrower has
    //         called approve() or approveAll() on the NFT contract for the NFT
    //         that will be used as collateral, (2) the borrower has signed an
    //         off-chain message indicating that they are willing to use this
    //         NFT as collateral, (3) the lender has called approve() on the
    //         ERC20 contract of the principal, and (4) the lender has signed
    //         an off-chain message agreeing to the terms of this loan supplied
    //         in this transaction.
    // @param  _loanPrincipalAmount - The original sum of money transferred
    //         from lender to borrower at the beginning of the loan, measured
    //         in loanERC20Denomination's smallest units.
    // @param  _nftCollateralId - The ID within the NFTCollateralContract for
    //         the NFT being used as collateral for this loan. The NFT is
    //         stored within this contract during the duration of the loan.
    // @param  _loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  _loanInterestRateInBasisPoints - The annual percentage interest rate
    //         (measured in basis points, e.g. hundreths of a percent) for the
    //         loan, that must be repaid pro-rata by the borrower at the
    //         conclusion of the loan or risk seizure of their nft collateral.
    // @param  _lenderNonce - The nonce referred to here is not the same
    //         as an Ethereum account's nonce. We are referring instead to
    //         a nonce that is used by the lenders when they are first signing
    //         off-chain orders. These nonces can be any uint256 value that the user
    //         has not previously used to sign an off-chain order.
    //         Each nonce can be used at most once per user within the protocol,
    //         This serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once. Second,
    //         it allows a user to cancel an off-chain order by calling cancelLoanCommitmentBeforeLoanHasBegun()
    //         which marks the nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _lenderSignatureExpiry - the timestamp when the lender signature expires
    // @param  _nftCollateralContract - The address of the ERC721 contract of
    //         the NFT collateral.
    // @param  _loanERC20Denomination - The address of the ERC20 contract of
    //         the currency being used as principal/interest for this loan.
    // @param  _lender - The address of the lender. The lender can change their
    //         address by transferring the protocol ERC721 token that they
    //         received when the loan began.
    // @param  _acceptAnyNFTInCollection - a boolean that represetns the lender's
    //         intent to take any NFT from the _nftCollateralContract NFT collection
    //         if _acceptAnyNFTInCollection is true, the signed message in the lender signature
    //         must include lenderAcceptNFTTokenId=0 and _acceptAnyNFTInCollection=true
    // @param  _lenderSignature - The ECDSA signature of the lender,
    //         obtained off-chain ahead of time, please refer to SigningUtils.sol::isValidLenderSignature
    //         for the parameters signed
    function beginLoan(
        uint256 _loanPrincipalAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _loanInterestRateInBasisPoints,
        uint256 _lenderNonce,
        uint256 _lenderSignatureExpiry,
        address _nftCollateralContract,
        address _loanERC20Denomination,
        address _lender,
        bool _acceptAnyNFTInCollection,
        bytes memory _lenderSignature
    ) public whenNotPaused nonReentrant {
        require(
            block.timestamp < _lenderSignatureExpiry,
            "lender signature has expired"
        );
        // Save loan details to a struct in memory first, to save on gas if any
        // of the below checks fail, and to avoid the "Stack Too Deep" error by
        // clumping the parameters together into one struct held in memory.
        Loan memory loan = Loan({
            loanId: totalNumLoans, //currentLoanId,
            loanPrincipalAmount: _loanPrincipalAmount,
            nftCollateralId: _nftCollateralId,
            loanStartTime: uint64(block.timestamp), //_loanStartTime
            loanDuration: uint32(_loanDuration),
            loanInterestRateInBasisPoints: uint32(
                _loanInterestRateInBasisPoints
            ),
            loanAdminFeeInBasisPoints: uint32(adminFeeInBasisPoints),
            loanOriginationFeeInBasisPoints: uint32(
                originationFeeInBasisPoints
            ),
            nftCollateralContract: _nftCollateralContract,
            loanERC20Denomination: _loanERC20Denomination
        });
        // Sanity check loan values.
        require(
            uint256(loan.loanDuration) <= maximumLoanDuration,
            "Loan duration exceeds maximum loan duration"
        );
        require(
            uint256(loan.loanDuration) != 0,
            "Loan duration cannot be zero"
        );

        // Check that both the collateral and the principal come from supported
        // contracts.
        require(
            erc20CurrencyIsWhitelisted[loan.loanERC20Denomination],
            "Currency denomination is not whitelisted to be used by this contract"
        );
        require(
            nftContractIsWhitelisted[loan.nftCollateralContract],
            "NFT collateral contract is not whitelisted to be used by this contract"
        );

        // Check loan nonces. These are different from Ethereum account nonces.
        // Here, these are uint256 numbers that should uniquely identify
        // each signature for each user (i.e. each user should only create one
        // off-chain signature for each nonce, with a nonce being any arbitrary
        // uint256 value that they have not used yet for an off-chain signature).
        require(
            !_nonceHasBeenUsedForUser[_lender][_lenderNonce],
            "Lender nonce invalid, lender has either cancelled/begun this loan, or reused this nonce when signing"
        );
        _nonceHasBeenUsedForUser[_lender][_lenderNonce] = true;

        // Check that lender signature is valid.
        require(
            isValidLenderSignature(
                loan.loanPrincipalAmount,
                loan.nftCollateralId,
                loan.loanDuration,
                loan.loanInterestRateInBasisPoints,
                _lenderNonce,
                _lenderSignatureExpiry,
                loan.nftCollateralContract,
                loan.loanERC20Denomination,
                _lender,
                _acceptAnyNFTInCollection,
                _lenderSignature
            ),
            "Lender signature is invalid"
        );
        // Mint two ERC721 tokens; one for the lender and one for the borrower
        LeverNFTInterface(nftAddress).mint(
            _lender,
            msg.sender,
            loan.loanId
        );

        // Add the loan to storage before moving collateral/principal to follow
        // the Checks-Effects-Interactions pattern.
        loanIdToLoan[totalNumLoans] = loan;
        totalNumLoans = totalNumLoans + 1;

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans + 1;
        require(
            totalActiveLoans <= maximumNumberOfActiveLoans,
            "Contract has reached the maximum number of active loans allowed by admins"
        );
        // Transfer collateral from borrower to this contract to be held until
        // loan completion.
        IERC721(loan.nftCollateralContract).transferFrom(
            msg.sender,
            address(this),
            loan.nftCollateralId
        );
        // Transfer principal from lender to borrower.
        IERC20(loan.loanERC20Denomination).transferFrom(
            _lender,
            msg.sender,
            loan.loanPrincipalAmount
        );

        // Emit an event with all relevant details from this transaction.
        emit LoanStarted(
            loan.loanId,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            block.timestamp, //_loanStartTime
            loan.loanDuration,
            loan.loanInterestRateInBasisPoints,
            loan.nftCollateralContract,
            loan.loanERC20Denomination,
            _lender,
            msg.sender,
            _lenderSignature
        );
    }

    // @notice This function is called by a borrower when they want to repay
    //         their loan. It can be called at any time after the loan has
    //         begun. The borrower will pay a pro-rata portion of their
    //         interest if the loan is paid off early. The interest will
    //         continue to accrue after the loan has expired. This function can
    //         continue to be called by the borrower even after the loan has
    //         expired to retrieve their NFT. Note that the lender can call
    //         protocol.liquidateOverdueLoan() at any time after the loan has
    //         expired, so a borrower should avoid paying their loan after the
    //         due date, as they risk their collateral being seized. However,
    //         if a lender has called protocol.liquidateOverdueLoan() before a
    //         borrower could call protocol.payBackLoan(), the borrower will get
    //         to keep the principal-plus-interest.
    // @notice This function is purposefully not pausable in order to prevent
    //         an attack where the contract admin's pause the contract and hold
    //         hostage the NFT's that are still within it.
    // @param _loanId  A unique identifier for this particular loan, sourced
    //        from the continuously increasing parameter totalNumLoans.
    function payBackLoan(uint256 _loanId) external nonReentrant {
        // Sanity check that payBackLoan() and liquidateOverdueLoan() have
        // never been called on this loanId. Depending on how the rest of the
        // code turns out, this check may be unnecessary.
        require(
            !loanRepaidOrLiquidated[_loanId],
            "Loan has already been repaid or liquidated"
        );

        // Fetch loan details from storage, but store them in memory for the
        // sake of saving gas.
        Loan memory loan = loanIdToLoan[_loanId];

        // Mark loan as repaid before doing any external transfers to follow
        // the Checks-Effects-Interactions design pattern.
        loanRepaidOrLiquidated[_loanId] = true;

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans - 1;

        // Delete the loan from storage in order to achieve a substantial gas
        // savings and to lessen the burden of storage on Ethereum nodes, since
        // we will never access this loan's details again, and the details are
        // still available through event data.
        delete loanIdToLoan[_loanId];

        // Calculate amounts to send to lender and admins
        (uint256 payoffAmount, uint256 totalProtocolFee) = settleRepayment(
            LeverNFTInterface(nftAddress).ownerOf(
                loan.loanId * 2 // lenderToken
            ),
            loan.loanERC20Denomination,
            loan.loanPrincipalAmount,
            loan.loanStartTime,
            loan.loanInterestRateInBasisPoints,
            loan.loanOriginationFeeInBasisPoints,
            loan.loanAdminFeeInBasisPoints
        );

        // Transfer collateral from this contract to borrower.
        _transferNftToAddress(
            loan.nftCollateralContract,
            loan.nftCollateralId,
            LeverNFTInterface(nftAddress).ownerOf(
                loan.loanId * 2 + 1 // borrowerToken
            )
        );

        // Destroy the two NFTs representing the loan.
        LeverNFTInterface(nftAddress).burn(loan.loanId);

        // Emit an event with all relevant details from this transaction.
        emit LoanRepaid(
            _loanId,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            payoffAmount,
            totalProtocolFee,
            loan.nftCollateralContract,
            loan.loanERC20Denomination
        );
    }

    // @notice This function is called for settling the ERC20 leg of the loan.
    //         the purpose of this function is to solve the stack-too-deep problem
    //         encountered in the implementation of function refinance.
    // @param  _loanId - A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @param  lender - The lenderNFTHolder that will receive the ERC20 as repayment
    // @param  loanERC20Denomination - The denomination of the loan
    // @param  loanPrincipalAmount - The principal amount of the loan
    // @param  loanStartTime - The start time of the loan
    // @param  loanInterestRateInBasisPoints - The interest rate agreed, in basis points
    // @param  loanOriginationFeeInBasisPoints - The origination fee rate at the time of
    //         loan origination, in basis points
    // @param  loanAdminFeeInBasisPoints - The admin fee rate at the time of
    //         loan origination, in basis points
    function settleRepayment(
        address _lender,
        address _loanERC20Denomination,
        uint256 _loanPrincipalAmount,
        uint256 _loanStartTime,
        uint256 _loanInterestRateInBasisPoints,
        uint256 _loanOriginationFeeInBasisPoints,
        uint256 _loanAdminFeeInBasisPoints
    ) internal returns (uint256 payoffAmount, uint256 totalProtocolFee) {
        uint256 interestDue = _computeInterestDue(
            _loanPrincipalAmount,
            block.timestamp - uint256(_loanStartTime),
            uint256(_loanInterestRateInBasisPoints)
        );

        // Calculate protocol fees
        uint256 adminFee = (interestDue * _loanAdminFeeInBasisPoints) / 10000;

        totalProtocolFee =
            (_loanPrincipalAmount * _loanOriginationFeeInBasisPoints) /
            10000 +
            adminFee;

        // Calculate payOffAmount to be sent to the _lender
        payoffAmount = _loanPrincipalAmount + interestDue - adminFee;

        // Transfer principal-plus-interest-minus-fees from msg.sender to _lender
        // msg.sender is not necessarily the borrowerNFTHolder because anyone can
        // repay on behalf of the borrowerNFTHolder
        IERC20(_loanERC20Denomination).transferFrom(
            msg.sender,
            _lender,
            payoffAmount
        );

        // Transfer fees from borrower to admins
        IERC20(_loanERC20Denomination).transferFrom(
            msg.sender,
            owner(),
            totalProtocolFee
        );
    }

    // @notice This function is called by the borrowerNFTHolder to refinance an active loan
    //         that has not been liquidated or repaid. Essentially it takes a new lending offer
    //         to pay back the old loan, while keeping the collateral locked in the this contract.
    //         NOTE: the principal amount of the new loan can be less than the required repayment amount
    //         of the old loan. In this case, the borrower needs to make up for the difference and
    //         an ERC20 approve transaction is required. If the new loan is more than enough to
    //         repay the old loan then the ERC20 approve transaction is not necessary.
    // @param  _oldLoanId - The unique identifier of the existing active loan that the borrower wants to repay.
    // @param  _loanPrincipalAmount - The principal amount of the new loan
    // @param  _loanDuration - The duration in seconds of the new loan
    // @param  _loanInterestRateInBasisPoints - The interest rate agreed for the new loan, in basis points
    // @param  _lenderNonce - The nonce referred to here is not the same
    //         as an Ethereum account's nonce. We are referring instead to
    //         a nonce that is used by the lenders when they are first signing
    //         off-chain orders. These nonces can be any uint256 value that the user
    //         has not previously used to sign an off-chain order.
    //         Each nonce can be used at most once per user within the protocol,
    //         This serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once. Second,
    //         it allows a user to cancel an off-chain order by calling cancelLoanCommitmentBeforeLoanHasBegun()
    //         which marks the nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _lenderSignatureExpiry - the timestamp when the lender signature expires
    // @param  _lender - The address of the lender. The lender can change their
    //         address by transferring the protocol ERC721 token that they
    //         received when the loan began.
    // @param  _acceptAnyNFTInCollection - a boolean that represetns the lender's
    //         intent to take any NFT from the _nftCollateralContract NFT collection
    //         if _acceptAnyNFTInCollection is true, the signed message in the lender signature
    //         must include lenderAcceptNFTTokenId=0 and _acceptAnyNFTInCollection=true
    // @param  _lenderSignature - The ECDSA signature of the lender,
    //         obtained off-chain ahead of time, please refer to SigningUtils.sol::isValidLenderSignature
    //         for the parameters signed
    function refinance(
        uint256 _oldLoanId,
        uint256 _loanPrincipalAmount,
        uint256 _loanDuration,
        uint256 _loanInterestRateInBasisPoints,
        uint256 _lenderNonce,
        uint256 _lenderSignatureExpiry,
        address _lender,
        bool _acceptAnyNFTInCollection,
        bytes memory _lenderSignature
    ) external whenNotPaused nonReentrant {
        require(
            block.timestamp < _lenderSignatureExpiry,
            "lender signature has expired"
        );
        Loan memory oldLoan = loanIdToLoan[_oldLoanId];
        address oldLoanBorrowerNFTHolder = LeverNFTInterface(
            nftAddress
        ).ownerOf(oldLoan.loanId * 2 + 1); // borrowerToken = loanId * 2 + 1
        require(
            msg.sender == oldLoanBorrowerNFTHolder,
            "only old loan borrower NFT holder can initiate refinance tx"
        );
        require(
            !loanRepaidOrLiquidated[_oldLoanId],
            "Loan has already been repaid or liquidated"
        );
        // Sanity check loan values.
        require(
            _loanDuration <= maximumLoanDuration,
            "Loan duration exceeds maximum loan duration"
        );
        require(_loanDuration != 0, "Loan duration cannot be zero");

        // Check that both the collateral and the principal come from supported
        // contracts.
        require(
            erc20CurrencyIsWhitelisted[oldLoan.loanERC20Denomination],
            "Currency denomination is not whitelisted to be used by this contract"
        );
        require(
            nftContractIsWhitelisted[oldLoan.nftCollateralContract],
            "NFT collateral contract is not whitelisted to be used by this contract"
        );

        require(
            !_nonceHasBeenUsedForUser[_lender][_lenderNonce],
            "Lender nonce invalid, lender has either cancelled/begun this loan, or reused this nonce when signing"
        );
        _nonceHasBeenUsedForUser[_lender][_lenderNonce] = true;

        // Check that lender signature is valid.
        require(
            isValidLenderSignature(
                _loanPrincipalAmount,
                oldLoan.nftCollateralId,
                _loanDuration,
                _loanInterestRateInBasisPoints,
                _lenderNonce,
                _lenderSignatureExpiry,
                oldLoan.nftCollateralContract,
                oldLoan.loanERC20Denomination,
                _lender,
                _acceptAnyNFTInCollection,
                _lenderSignature
            ),
            "Lender signature is invalid"
        );
        Loan memory newLoan = Loan({
            loanId: totalNumLoans, //currentLoanId,
            loanPrincipalAmount: _loanPrincipalAmount,
            nftCollateralId: oldLoan.nftCollateralId,
            loanStartTime: uint64(block.timestamp), //_loanStartTime
            loanDuration: uint32(_loanDuration),
            loanInterestRateInBasisPoints: uint32(
                _loanInterestRateInBasisPoints
            ),
            loanAdminFeeInBasisPoints: uint32(adminFeeInBasisPoints),
            loanOriginationFeeInBasisPoints: uint32(
                originationFeeInBasisPoints
            ),
            nftCollateralContract: oldLoan.nftCollateralContract,
            loanERC20Denomination: oldLoan.loanERC20Denomination
        });
        // Mint two ERC721 tokens; one for the lender and one for the borrower

        LeverNFTInterface(nftAddress).mint(
            _lender,
            msg.sender,
            newLoan.loanId
        );

        // update loan before saving it to storage
        loanIdToLoan[totalNumLoans] = newLoan;
        totalNumLoans = totalNumLoans + 1;
        // Delete the loan from storage in order to achieve a substantial gas
        // savings and to lessen the burden of storage on Ethereum nodes, since
        // we will never access this loan's details again, and the details are
        // still available through event data.
        delete loanIdToLoan[_oldLoanId];

        // Add the loan to storage before moving collateral/principal to follow
        // the Checks-Effects-Interactions pattern.

        // Transfer principal from lender to borrower.
        IERC20(newLoan.loanERC20Denomination).transferFrom(
            _lender,
            oldLoanBorrowerNFTHolder,
            newLoan.loanPrincipalAmount
        );

        // Emit an event with all relevant details from this transaction.
        emit LoanStarted(
            newLoan.loanId,
            newLoan.loanPrincipalAmount,
            newLoan.nftCollateralId,
            block.timestamp, //_loanStartTime
            newLoan.loanDuration,
            newLoan.loanInterestRateInBasisPoints,
            newLoan.nftCollateralContract,
            newLoan.loanERC20Denomination,
            _lender,
            msg.sender,
            _lenderSignature
        );

        // START PAYBACK

        // Mark loan as repaid before doing any external transfers to follow
        // the Checks-Effects-Interactions design pattern.
        address oldLoanLenderNFTHolder = LeverNFTInterface(
            nftAddress
        ).ownerOf(oldLoan.loanId * 2); // lenderToken = loanId * 2
        loanRepaidOrLiquidated[_oldLoanId] = true;

        // Destroy the two NFTs representing the loan.
        LeverNFTInterface(nftAddress).burn(oldLoan.loanId);
        // Calculate amounts to send to lender and admins
        (uint256 payoffAmount, uint256 totalProtocolFee) = settleRepayment(
            oldLoanLenderNFTHolder,
            oldLoan.loanERC20Denomination,
            oldLoan.loanPrincipalAmount,
            oldLoan.loanStartTime,
            oldLoan.loanInterestRateInBasisPoints,
            oldLoan.loanOriginationFeeInBasisPoints,
            oldLoan.loanAdminFeeInBasisPoints
        );

        // Emit an event with all relevant details from this transaction.
        emit LoanRepaid(
            _oldLoanId,
            oldLoan.loanPrincipalAmount,
            oldLoan.nftCollateralId,
            payoffAmount,
            totalProtocolFee,
            oldLoan.nftCollateralContract,
            oldLoan.loanERC20Denomination
        );
        // Emit an event to indicate refinancing.
        emit LoanRefinanced(_oldLoanId, newLoan.loanId);
    }

    // @notice This function is called by a lender once a loan has finished its
    //         duration and the borrower still has not repaid. The lender
    //         can call this function to seize the underlying NFT collateral,
    //         although the lender gives up all rights to the
    //         principal-plus-collateral by doing so.
    // @notice This function is purposefully not pausable in order to prevent
    //         an attack where the contract admin's pause the contract and hold
    //         hostage the NFT's that are still within it.
    // @notice We intentionally allow anybody to call this function, although
    //         only the lender will end up receiving the seized collateral. We
    //         are exploring the possbility of incentivizing users to call this
    //         function by using some of the admin funds.
    // @param _loanId  A unique identifier for this particular loan, sourced
    //        from the continuously increasing parameter totalNumLoans.
    function liquidateOverdueLoan(uint256 _loanId) external nonReentrant {
        // Sanity check that payBackLoan() and liquidateOverdueLoan() have
        // never been called on this loanId. Depending on how the rest of the
        // code turns out, this check may be unnecessary.
        require(
            !loanRepaidOrLiquidated[_loanId],
            "Loan has already been repaid or liquidated"
        );

        // Fetch loan details from storage, but store them in memory for the
        // sake of saving gas.
        Loan memory loan = loanIdToLoan[_loanId];

        // Ensure that the loan is indeed overdue, since we can only liquidate
        // overdue loans.
        uint256 loanMaturityDate = uint256(loan.loanStartTime) +
            uint256(loan.loanDuration);

        require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

        // Fetch the current lender of the promissory note corresponding to
        // this overdue loan.
        address lenderNFTHolder = LeverNFTInterface(nftAddress)
            .ownerOf(loan.loanId * 2); // lenderToken

        // Mark loan as liquidated before doing any external transfers to
        // follow the Checks-Effects-Interactions design pattern.
        loanRepaidOrLiquidated[_loanId] = true;

        // Update number of active loans.
        totalActiveLoans = totalActiveLoans - 1;

        // Delete the loan from storage in order to achieve a substantial gas
        // savings and to lessen the burden of storage on Ethereum nodes, since
        // we will never access this loan's details again, and the details are
        // still available through event data.
        delete loanIdToLoan[_loanId];

        // Transfer collateral from this contract to the lender, since the
        // lender is seizing collateral for an overdue loan.

        _transferNftToAddress(
            loan.nftCollateralContract,
            loan.nftCollateralId,
            lenderNFTHolder
        );

        // Destroy the lender's promissory note for this loan, since by seizing
        // the collateral, the lender has forfeit the rights to the loan
        // principal-plus-interest.
        LeverNFTInterface(nftAddress).burn(loan.loanId);

        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            loan.loanPrincipalAmount,
            loan.nftCollateralId,
            loanMaturityDate,
            block.timestamp,
            loan.nftCollateralContract
        );
    }

    // @notice This function can be called by either a lender or a borrower to
    //         cancel all off-chain orders that they have signed that contain
    //         this nonce. If the off-chain orders were created correctly,
    //         there should only be one off-chain order that contains this
    //         nonce at all.
    // @param  _nonce - The nonce referred to here is not the same as an
    //         Ethereum account's nonce. We are referring instead to nonces
    //         that are used by the lenders when they are
    //         first signing off-chain protocol orders. These nonces can be any
    //         uint256 value that the user has not previously used to sign an
    //         off-chain order. Each nonce can be used at most once per user
    //         within protocol. This serves two purposes. First, it
    //         prevents replay attacks where an attacker would submit a user's
    //         off-chain order more than once. Second, it allows a user to
    //         cancel an off-chain order by calling
    //         protocol.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    function cancelLoanCommitmentBeforeLoanHasBegun(uint256 _nonce) external {
        require(
            !_nonceHasBeenUsedForUser[msg.sender][_nonce],
            "Nonce invalid, user has either cancelled/begun this loan, or reused a nonce when signing"
        );
        _nonceHasBeenUsedForUser[msg.sender][_nonce] = true;
    }

    /* ******************* */
    /* READ-ONLY FUNCTIONS */
    /* ******************* */

    // @notice This function can be used to view the current quantity of the
    //         ERC20 currency used in the specified loan required by the
    //         borrower to repay their loan, measured in the smallest unit of
    //         the ERC20 currency. Note that since interest accrues every
    //         second, once a borrower calls repayLoan(), the amount will have
    //         increased slightly.
    // @param  _loanId  A unique identifier for this particular loan, sourced
    //         from the continuously increasing parameter totalNumLoans.
    // @return The amount of the specified ERC20 currency required to pay back
    //         this loan, measured in the smallest unit of the specified ERC20
    //         currency.
    function getPayoffAmount(uint256 _loanId) public view returns (uint256) {
        Loan storage loan = loanIdToLoan[_loanId];
        uint256 loanDurationSoFarInSeconds = block.timestamp -
            uint256(loan.loanStartTime);

        uint256 interestDue = _computeInterestDue(
            loan.loanPrincipalAmount,
            loanDurationSoFarInSeconds,
            uint256(loan.loanInterestRateInBasisPoints)
        );
        uint256 originationFee = (loan.loanPrincipalAmount *
            loan.loanOriginationFeeInBasisPoints) / 10000;
        return loan.loanPrincipalAmount + interestDue + originationFee;
    }

    // @notice This function can be used to view whether a particular nonce
    //         for a particular user has already been used, either from a
    //         successful loan or a cancelled off-chain order.
    // @param  _user - The address of the user.
    // @param  _nonce - The nonce referred to here is not the same as an
    //         Ethereum account's nonce. We are referring instead to nonces
    //         that are used by the lenders when they are
    //         first signing off-chain protocol orders. These nonces can be any
    //         uint256 value that the user has not previously used to sign an
    //         off-chain order. Each nonce can be used at most once per user
    //         within protocol. This serves two purposes. First, it
    //         prevents replay attacks where an attacker would submit a user's
    //         off-chain order more than once. Second, it allows a user to
    //         cancel an off-chain order by calling
    //         protocol.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @return A bool representing whether or not this nonce has been used for
    //         this user.
    function getWhetherNonceHasBeenUsedForUser(address _user, uint256 _nonce)
        external
        view
        returns (bool)
    {
        return _nonceHasBeenUsedForUser[_user][_nonce];
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    /**
     * @dev _authorizeUpgrade is used by UUPSUpgradeable to determine if it's allowed to upgrade a proxy implementation.
     //     added onlyOwner modifier for access control
     * @param newImplementation The new implementation
     *
     * Ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // @notice A convenience function that calculates the amount of interest
    //         currently due for a given loan.
    // @param  _loanPrincipalAmount - The total quantity of principal first
    //         loaned to the borrower, measured in the smallest units of the
    //         ERC20 currency used for the loan.
    // @param  _loanDurationSoFarInSeconds - The elapsed time (in seconds) that
    //         has occurred so far since the loan began until repayment.
    // @param  _loanInterestRateInBasisPoints - The annual percentage interest rate
    ///        that the borrower and lender agreed to for the duration of the loan
    // @return The quantity of interest due, measured in the smallest units of
    //         the ERC20 currency used to pay this loan.
    function _computeInterestDue(
        uint256 _loanPrincipalAmount,
        uint256 _loanDurationSoFarInSeconds,
        uint256 _loanInterestRateInBasisPoints
    ) internal pure returns (uint256 interestDue) {
        interestDue =
            (((_loanPrincipalAmount * _loanInterestRateInBasisPoints) / 10000) *
                _loanDurationSoFarInSeconds) /
            52 weeks;
    }

    // @notice We call this function when we wish to transfer an NFT from our
    //         contract to another destination.
    // @notice Some nft contracts will not allow you to approve your own
    //         address or do not allow you to call transferFrom() when you are
    //         the sender, (for example, CryptoKitties does not allow you to),
    //         while other nft contracts do not implement transfer() (since it
    //         is not part of the official ERC721 standard but is implemented
    //         in some prominent nft projects such as Cryptokitties).
    //         we assume that the nft contract whitelisted has to conform to EIP721
    // @param  _nftContract - The NFT contract that we are attempting to
    //         transfer an NFT from.
    // @param  _nftId - The ID of the NFT that we are attempting to transfer.
    // @param  _recipient - The destination of the NFT that we are attempting
    //         to transfer.
    // @return A bool value indicating whether the transfer attempt succeeded.
    function _transferNftToAddress(
        address _nftContract,
        uint256 _nftId,
        address _recipient
    ) internal {
        // Try to call transferFrom()
        bool transferFromSucceeded = _attemptTransferFrom(
            _nftContract,
            _nftId,
            _recipient
        );
        require(transferFromSucceeded, "NFT was not successfully transferred");
    }

    // @notice This function attempts to call transferFrom() on the specified
    //         NFT contract, returning whether it succeeded.
    // @notice We only call this function from within _transferNftToAddress(),
    //         which is function attempts to call the various ways that
    //         different NFT contracts have implemented transfer/transferFrom.
    // @param  _nftContract - The NFT contract that we are attempting to
    //         transfer an NFT from.
    // @param  _nftId - The ID of the NFT that we are attempting to transfer.
    // @param  _recipient - The destination of the NFT that we are attempting
    //         to transfer.
    // @return A bool value indicating whether the transfer attempt succeeded.
    function _attemptTransferFrom(
        address _nftContract,
        uint256 _nftId,
        address _recipient
    ) internal returns (bool) {
        // @notice Some NFT contracts will not allow you to approve an NFT that
        //         you own, so we cannot simply call approve() here, we have to
        //         try to call it in a manner that allows the call to fail.
        _nftContract.call(
            abi.encodeWithSelector(
                IERC721(_nftContract).approve.selector,
                address(this),
                _nftId
            )
        );

        // @notice Some NFT contracts will not allow you to call transferFrom()
        //         for an NFT that you own but that is not approved, so we
        //         cannot simply call transferFrom() here, we have to try to
        //         call it in a manner that allows the call to fail.
        (bool success, ) = _nftContract.call(
            abi.encodeWithSelector(
                IERC721(_nftContract).transferFrom.selector,
                address(this),
                _recipient,
                _nftId
            )
        );
        return success;
    }

    /* ***************** */
    /* FALLBACK FUNCTION */
    /* ***************** */

    // @notice By calling 'revert' in the fallback function, we prevent anyone
    //         from accidentally sending funds directly to this contract.
    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @title  Helper contract for NFTfi. This contract manages verifying signatures
//         from off-chain NFTfi orders.
// @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth,
//         and kittybounties.eth
// @notice Cite: I found the following article very insightful while creating
//         this contract:
//         https://dzone.com/articles/signing-and-verifying-ethereum-signatures
// @notice Cite: I also relied on this article somewhat:
//         https://forum.openzeppelin.com/t/sign-it-like-you-mean-it-creating-and-verifying-ethereum-signatures/697
contract SigningUtils {
    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    constructor() {}

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    // @notice OpenZeppelin's ECDSA library is used to call all ECDSA functions
    //         directly on the bytes32 variables themselves.
    using ECDSA for bytes32;

    // @notice This function gets the current chain ID.
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // @notice This function is called in NFTfi.beginLoan() to validate the
    //         lender's signature that the lender provided off-chain to
    //         verify that they did indeed want to agree to this loan according
    //         to these terms.
    // @param  _loanPrincipalAmount - The original sum of money transferred
    //         from lender to borrower at the beginning of the loan, measured
    //         in loanERC20Denomination's smallest units.
    // @param  _nftCollateralId - The ID within the NFTCollateralContract for
    //         the NFT being used as collateral for this loan. The NFT is
    //         stored within this contract during the duration of the loan.
    //         NOTE: if _acceptAnyNFTInCollection is set to true, _nftCollateralId
    //         should be set to zero
    // @param  _loanDuration - The amount of time (measured in seconds) that can
    //         elapse before the lender can liquidate the loan and seize the
    //         underlying collateral NFT.
    // @param  _loanInterestRateInBasisPoints - The interest rate
    //         (measured in basis points, e.g. hundreths of a percent) for the
    //         loan, that must be repaid pro-rata by the borrower at the
    //         conclusion of the loan or risk seizure of their nft collateral.
    // @param  _lenderNonce - The nonce referred to here
    //         is not the same as an Ethereum account's nonce. We are referring
    //         instead to nonces that are used by both the lender and the
    //         borrower when they are first signing off-chain NFTfi orders.
    //         These nonces can be any uint256 value that the user has not
    //         previously used to sign an off-chain order. Each nonce can be
    //         used at most once per user within NFTfi, regardless of whether
    //         they are the lender or the borrower in that situation. This
    //         serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once.
    //         Second, it allows a user to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    // @param  _lenderSignatureExpiry - the timestamp when the lender signature expires
    // @param  _nftCollateralContract - The ERC721 contract of the NFT
    //         collateral
    // @param  _loanERC20Denomination - The ERC20 contract of the currency being
    //         used as principal/interest for this loan.
    // @param  _lender - The address of the lender. The lender can change their
    //         address by transferring the NFTfi ERC721 token that they
    //         received when the loan began.
    // @param  _acceptAnyNFTInCollection - a bool expressing interest in loans of any
    //         NFT within the collection as collateral
    // @param  _lenderSignature - The ECDSA signature of the lender,
    //         obtained off-chain ahead of time, signing the following
    //         combination of parameters: _loanPrincipalAmount,
    //         _nftCollateralId, _loanDuration,
    //         _loanInterestRateInBasisPoints, _lenderNonce,
    //         _nftCollateralContract, _loanERC20Denomination, _lender,
    // @return A bool representing whether verification succeeded, showing that
    //         this signature matched this address and parameters.
    function isValidLenderSignature(
        uint256 _loanPrincipalAmount,
        uint256 _nftCollateralId,
        uint256 _loanDuration,
        uint256 _loanInterestRateInBasisPoints,
        uint256 _lenderNonce,
        uint256 _lenderSignatureExpiry,
        address _nftCollateralContract,
        address _loanERC20Denomination,
        address _lender,
        bool _acceptAnyNFTInCollection,
        bytes memory _lenderSignature
    ) public view returns (bool) {
        if (_lender == address(0)) {
            return false;
        } else {
            uint256 _lenderAcceptNFTTokenId = 0;
            if (!_acceptAnyNFTInCollection) {
                _lenderAcceptNFTTokenId = _nftCollateralId;
            }
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(
                abi.encodePacked(
                    _loanPrincipalAmount,
                    _lenderAcceptNFTTokenId,
                    _loanDuration,
                    _loanInterestRateInBasisPoints,
                    _lenderNonce,
                    _lenderSignatureExpiry,
                    _nftCollateralContract,
                    _loanERC20Denomination,
                    _lender,
                    _acceptAnyNFTInCollection,
                    chainId
                )
            );

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();
            return (messageWithEthSignPrefix.recover(_lenderSignature) ==
                _lender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LeverStorage {
    // @notice The main Loan struct. The struct fits in six 256-bits words due
    //         to Solidity's rules for struct packing.
    struct Loan {
        // A unique identifier for this particular loan, sourced from the
        // continuously increasing parameter totalNumLoans.
        uint256 loanId;
        // The original sum of money transferred from lender to borrower at the
        // beginning of the loan, measured in loanERC20Denomination's smallest
        // units.
        uint256 loanPrincipalAmount;
        // The ID within the NFTCollateralContract for the NFT being used as
        // collateral for this loan. The NFT is stored within this contract
        // during the duration of the loan.
        uint256 nftCollateralId;
        // The block.timestamp when the loan first began (measured in seconds).
        uint64 loanStartTime;
        // The amount of time (measured in seconds) that can elapse before the
        // lender can liquidate the loan and seize the underlying collateral.
        uint32 loanDuration;
        // This is the annual percentage interest rate
        // (measured in basis points, e.g. hundreths of a percent) for the loan,
        // that must be repaid pro-rata by the borrower at the conclusion of
        // the loan or risk seizure of their nft collateral.
        uint32 loanInterestRateInBasisPoints;
        // The percent (measured in basis points) of the interest earned that
        // will be taken as a fee by the contract admins when the loan is
        // repaid. The fee is stored here to prevent an attack where the
        // contract admins could adjust the fee right before a loan is repaid,
        // and take all of the interest earned.
        uint32 loanAdminFeeInBasisPoints;
        // The percent (measured in basis points) of the principal that
        // will be taken as a fee by the contract admins when the loan is
        // repaid.
        uint32 loanOriginationFeeInBasisPoints;
        // The ERC721 contract of the NFT collateral
        address nftCollateralContract;
        // The ERC20 contract of the currency being used as principal/interest
        // for this loan.
        address loanERC20Denomination;
    }

    // @notice The maximum duration of any loan started on this platform,
    //         measured in seconds. This is both a sanity-check for borrowers
    //         and an upper limit on how long admins will have to support v1 of
    //         this contract if they eventually deprecate it, as well as a check
    //         to ensure that the loan duration never exceeds the space alotted
    //         for it in the loan struct.
    uint256 public maximumLoanDuration;

    // @notice The maximum number of active loans allowed on this platform.
    //         This parameter is used to limit the risk that NFTfi faces while
    //         the project is first getting started.
    uint256 public maximumNumberOfActiveLoans;

    // @notice The percentage of interest earned by lenders on this platform
    //         that is taken by the contract admin's as a fee, measured in
    //         basis points (hundreths of a percent).
    uint256 public adminFeeInBasisPoints;
    // @notice The percentage of principal that is taken by the contract
    // admin as a fee for orignating the loan, measured in basis points (hundreths of a percent).
    uint256 public originationFeeInBasisPoints;

    // @notice A continuously increasing counter that simultaneously allows
    //         every loan to have a unique ID and provides a running count of
    //         how many loans have been started by this contract.
    uint256 public totalNumLoans;

    // @notice A counter of the number of currently outstanding loans.
    uint256 public totalActiveLoans;

    // @notice NFT contract that generates borrower/lender token
    address public nftAddress;

    // @notice A mapping from a loan's identifier to the loan's details,
    //         represted by the loan struct. To fetch the lender, call
    //         NFTfi.ownerOf(loanId).
    mapping(uint256 => Loan) public loanIdToLoan;

    // @notice A mapping tracking whether a loan has either been repaid or
    //         liquidated. This prevents an attacker trying to repay or
    //         liquidate the same loan twice.
    mapping(uint256 => bool) public loanRepaidOrLiquidated;
    // @notice A mapping from from an ERC20 currency address to whether that
    //         currency is whitelisted to be used by this contract. Note that
    //         NFTfi only supports loans that use ERC20 currencies that are
    //         whitelisted, all other calls to beginLoan() will fail.
    mapping(address => bool) public erc20CurrencyIsWhitelisted;

    // @notice A mapping from from an NFT contract's address to whether that
    //         contract is whitelisted to be used by this contract. Note that
    //         NFTfi only supports loans that use NFT collateral from contracts
    //         that are whitelisted, all other calls to beginLoan() will fail.
    mapping(address => bool) public nftContractIsWhitelisted;
    // @notice A mapping that takes both a user's address and a loan nonce
    //         that was first used when signing an off-chain order and checks
    //         whether that nonce has previously either been used for a loan,
    //         or has been pre-emptively cancelled. The nonce referred to here
    //         is not the same as an Ethereum account's nonce. We are referring
    //         instead to nonces that are used by both the lender and the
    //         borrower when they are first signing off-chain NFTfi orders.
    //         These nonces can be any uint256 value that the user has not
    //         previously used to sign an off-chain order. Each nonce can be
    //         used at most once per user within NFTfi, regardless of whether
    //         they are the lender or the borrower in that situation. This
    //         serves two purposes. First, it prevents replay attacks where an
    //         attacker would submit a user's off-chain order more than once.
    //         Second, it allows a user to cancel an off-chain order by calling
    //         NFTfi.cancelLoanCommitmentBeforeLoanHasBegun(), which marks the
    //         nonce as used and prevents any future loan from using the user's
    //         off-chain order that contains that nonce.
    mapping(address => mapping(uint256 => bool))
        public _nonceHasBeenUsedForUser;
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface LeverNFTInterface is IERC721 {
    function burn(uint256 loanId) external;

    function mint(
        address lender,
        address borrower,
        uint256 loanId
    ) external returns (uint256, uint256);
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}