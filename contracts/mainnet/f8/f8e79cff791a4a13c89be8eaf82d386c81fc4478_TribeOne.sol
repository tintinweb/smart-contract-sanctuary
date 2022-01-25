// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/ITribeOne.sol";
import "./interfaces/IAssetManager.sol";
import "./libraries/Ownable.sol";
import "./libraries/TribeOneHelper.sol";

contract TribeOne is ERC721Holder, ERC1155Holder, ITribeOne, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    enum Status {
        AVOID_ZERO, // just for avoid zero
        LISTED, // after the loan has been created --> the next status will be APPROVED
        APPROVED, // in this status the loan has a lender -- will be set after approveLoan(). loan fund => borrower
        LOANACTIVED, // NFT was brought from opensea by agent and staked in TribeOne - relayNFT()
        LOANPAID, // loan was paid fully but still in TribeOne
        WITHDRAWN, // the final status, the collateral returned to the borrower or to the lender withdrawNFT()
        FAILED, // NFT buying order was failed in partner's platform such as opensea...
        CANCELLED, // only if loan is LISTED - cancelLoan()
        DEFAULTED, // Grace period = 15 days were passed from the last payment schedule
        LIQUIDATION, // NFT was put in marketplace
        POSTLIQUIDATION, /// NFT was sold
        RESTWITHDRAWN, // user get back the rest of money from the money which NFT set is sold in marketplace
        RESTLOCKED, // Rest amount was forcely locked because he did not request to get back with in 2 weeks (GRACE PERIODS)
        REJECTED // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
    }

    struct Asset {
        uint256 amount;
        address currency; // address(0) is ETH native coin
    }

    struct LoanRules {
        uint16 tenor;
        uint16 LTV; // 10000 - 100%
        uint16 interest; // 10000 - 100%
    }

    struct Loan {
        uint256 fundAmount; // the amount which user put in TribeOne to buy NFT
        uint256 paidAmount; // the amount that has been paid back to the lender to date
        uint256 loanStart; // the point when the loan is approved
        uint256 postTime; // the time when NFT set was sold in marketplace and that money was put in TribeOne
        uint256 restAmount; // rest amount after sending loan debt(+interest) and 5% penalty
        address borrower; // the address who receives the loan
        uint8 nrOfPenalty;
        uint8 passedTenors; // the number of tenors which we can consider user passed - paid tenor
        Asset loanAsset;
        Asset collateralAsset;
        Status status; // the loan status
        LoanRules loanRules;
        address[] nftAddressArray; // the adderess of the ERC721
        uint256[] nftTokenIdArray; // the unique identifier of the NFT token that the borrower uses as collateral
        TribeOneHelper.TokenType[] nftTokenTypeArray; // the token types : ERC721 , ERC1155 , ...
    }

    mapping(uint256 => Loan) public loans; // loanId => Loan
    Counters.Counter public loanIds; // loanId is from No.1
    // uint public loanLength;
    uint256 public constant MAX_SLIPPAGE = 500; // 5%
    // uint256 public constant TENOR_UNIT = 4 weeks; // installment should be pay at least in every 4 weeks
    // uint256 public constant GRACE_PERIOD = 14 days; // 2 weeks

    /**
     * @dev It's for only testnet
     */
    uint256 public TENOR_UNIT = 7 minutes;
    uint256 public GRACE_PERIOD = 3 minutes;

    address public salesManager;
    address public assetManager;
    address public feeTo;
    address public immutable feeCurrency; // stable coin such as USDC, late fee $5
    uint256 public lateFee; // we will set it 5 USD for each tenor late
    uint256 public penaltyFee; // we will set it 5% in the future - 1000 = 100%

    event LoanCreated(uint256 indexed loanId, address indexed owner);
    event LoanApproved(uint256 indexed _loanId, address indexed _to, address _fundCurreny, uint256 _fundAmount);
    event LoanCanceled(uint256 indexed _loanId, address _sender);
    event NFTRelayed(uint256 indexed _loanId, address indexed _sender, bool _accepted);
    event InstallmentPaid(uint256 indexed _loanId, address _sender, address _currency, uint256 _amount);
    event NFTWithdrew(uint256 indexed _loanId, address _to);
    event LoanDefaulted(uint256 indexed _loandId);
    event LoanLiquidation(uint256 indexed _loanId, address _salesManager);
    event LoanPostLiquidation(uint256 indexed _loanId, uint256 _soldAmount, uint256 _finalDebt);
    event RestWithdrew(uint256 indexed _loanId, uint256 _amount);
    event SettingsUpdate(address _feeTo, uint256 _lateFee, uint256 _penaltyFee, address _salesManager, address _assetManager);
    event LoanRejected(uint256 _loanId, address _agent);

    constructor(
        address _salesManager,
        address _feeTo,
        address _feeCurrency,
        address _multiSigWallet,
        address _assetManager
    ) {
        require(
            _salesManager != address(0) &&
                _feeTo != address(0) &&
                _feeCurrency != address(0) &&
                _multiSigWallet != address(0) &&
                _assetManager != address(0),
            "TribeOne: ZERO address"
        );
        salesManager = _salesManager;
        assetManager = _assetManager;
        feeTo = _feeTo;
        feeCurrency = _feeCurrency;

        transferOwnership(_multiSigWallet);
    }

    function setPeriods(uint256 _tenorUint, uint256 _gracePeriod) external onlySuperOwner {
        TENOR_UNIT = _tenorUint;
        GRACE_PERIOD = _gracePeriod;
    }

    receive() external payable {}

    function getLoanAsset(uint256 _loanId) external view returns (address _token, uint256 _amount) {
        _token = loans[_loanId].loanAsset.currency;
        _amount = loans[_loanId].loanAsset.amount;
    }

    function getCollateralAsset(uint256 _loanId) external view returns (address _token, uint256 _amount) {
        _token = loans[_loanId].collateralAsset.currency;
        _amount = loans[_loanId].collateralAsset.amount;
    }

    function getLoanRules(uint256 _loanId)
        external
        view
        returns (
            uint16 tenor,
            uint16 LTV,
            uint16 interest
        )
    {
        tenor = loans[_loanId].loanRules.tenor;
        LTV = loans[_loanId].loanRules.LTV;
        interest = loans[_loanId].loanRules.interest;
    }

    function getLoanNFTCount(uint256 _loanId) external view returns (uint256) {
        return loans[_loanId].nftAddressArray.length;
    }

    function getLoanNFTItem(uint256 _loanId, uint256 _nftItemId) external view returns (address _nftAddress, uint256 _tokenId) {
        _nftAddress = loans[_loanId].nftAddressArray[_nftItemId];
        _tokenId = loans[_loanId].nftTokenIdArray[_nftItemId];
    }

    function setSettings(
        address _feeTo,
        uint256 _lateFee,
        uint256 _penaltyFee,
        address _salesManager,
        address _assetManager
    ) external onlySuperOwner {
        require(_feeTo != address(0) && _salesManager != address(0) && _assetManager != address(0), "TribeOne: ZERO address");
        require(_lateFee <= 5 && penaltyFee <= 50, "TribeOne: Exceeded fee limit");
        feeTo = _feeTo;
        lateFee = _lateFee;
        penaltyFee = _penaltyFee;
        salesManager = _salesManager;
        assetManager = _assetManager;
        emit SettingsUpdate(_feeTo, _lateFee, _penaltyFee, _salesManager, assetManager);
    }

    /**
     * @dev _fundAmount shoud be amount in loan currency, and _collateralAmount should be in collateral currency
     */
    function createLoan(
        uint16[] calldata _loanRules, // tenor, LTV, interest, 10000 - 100% to use array - avoid stack too deep
        address[] calldata _currencies, // _loanCurrency, _collateralCurrency, address(0) is native coin
        address[] calldata nftAddressArray,
        uint256[] calldata _amounts, // _fundAmount, _collateralAmount _fundAmount is the amount of _collateral in _loanAsset such as ETH
        uint256[] calldata nftTokenIdArray,
        TribeOneHelper.TokenType[] memory nftTokenTypeArray
    ) external payable {
        require(_loanRules.length == 3 && _amounts.length == 2 && _currencies.length == 2, "TribeOne: Invalid parameter");
        uint16 tenor = _loanRules[0];
        uint16 LTV = _loanRules[1];
        uint16 interest = _loanRules[2];
        require(_loanRules[1] > 0, "TribeOne: LTV should not be ZERO");
        require(_loanRules[0] > 0, "TribeOne: Loan must have at least 1 installment");
        require(nftAddressArray.length > 0, "TribeOne: Loan must have at least 1 NFT");
        address _collateralCurrency = _currencies[1];
        address _loanCurrency = _currencies[0];
        require(IAssetManager(assetManager).isAvailableLoanAsset(_loanCurrency), "TribeOne: Loan asset is not available");
        require(
            IAssetManager(assetManager).isAvailableCollateralAsset(_collateralCurrency),
            "TribeOne: Collateral asset is not available"
        );

        require(
            nftAddressArray.length == nftTokenIdArray.length && nftTokenIdArray.length == nftTokenTypeArray.length,
            "TribeOne: NFT provided informations are missing or incomplete"
        );

        loanIds.increment();
        uint256 loanID = loanIds.current();

        // Transfer Collateral from sender to contract
        uint256 _fundAmount = _amounts[0];
        uint256 _collateralAmount = _amounts[1];

        // Transfer collateral to TribeOne
        if (_collateralCurrency == address(0)) {
            require(msg.value >= _collateralAmount, "TribeOne: Insufficient collateral amount");
            if (msg.value > _collateralAmount) {
                TribeOneHelper.safeTransferETH(msg.sender, msg.value - _collateralAmount);
            }
        } else {
            require(msg.value == 0, "TribeOne: ERC20 collateral");
            TribeOneHelper.safeTransferFrom(_collateralCurrency, _msgSender(), address(this), _collateralAmount);
        }

        loans[loanID].nftAddressArray = nftAddressArray;
        loans[loanID].borrower = _msgSender();
        loans[loanID].loanAsset = Asset({currency: _loanCurrency, amount: 0});
        loans[loanID].collateralAsset = Asset({currency: _collateralCurrency, amount: _collateralAmount});
        loans[loanID].loanRules = LoanRules({tenor: tenor, LTV: LTV, interest: interest});
        loans[loanID].nftTokenIdArray = nftTokenIdArray;
        loans[loanID].fundAmount = _fundAmount;

        loans[loanID].status = Status.LISTED;
        loans[loanID].nftTokenTypeArray = nftTokenTypeArray;

        emit LoanCreated(loanID, msg.sender);
    }

    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external override onlyOwner nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LISTED, "TribeOne: Invalid request");
        require(_agent != address(0), "TribeOne: ZERO address");

        uint256 _fundAmount = _loan.fundAmount;
        uint256 _LTV = _loan.loanRules.LTV;

        uint256 expectedPrice = TribeOneHelper.getExpectedPrice(_fundAmount, _LTV, MAX_SLIPPAGE);
        require(_amount <= expectedPrice, "TribeOne: Invalid amount");
        // Loan should be rejected when requested loan amount is less than fund amount because of some issues such as big fluctuation in marketplace
        if (_amount <= _fundAmount) {
            _loan.status = Status.REJECTED;
            returnColleteral(_loanId);
            emit LoanRejected(_loanId, _agent);
        } else {
            if (!isAdmin(msg.sender)) {
                require(
                    IAssetManager(assetManager).isValidAutomaticLoan(_loan.loanAsset.currency, _amount),
                    "TribeOne: Exceeded loan limit"
                );
            }

            _loan.status = Status.APPROVED;
            address _token = _loan.loanAsset.currency;

            _loan.loanAsset.amount = _amount - _loan.fundAmount;

            if (_token == address(0)) {
                IAssetManager(assetManager).requestETH(_agent, _amount);
            } else {
                IAssetManager(assetManager).requestToken(_agent, _token, _amount);
            }

            emit LoanApproved(_loanId, _agent, _token, _amount);
        }
    }

    /**
     * @dev _loanId: loanId, _accepted: order to Partner is succeeded or not
     * loan will be back to TribeOne if accepted is false
     */
    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable override onlyOwner nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.APPROVED, "TribeOne: Not approved loan");
        require(_agent != address(0), "TribeOne: ZERO address");
        if (_accepted) {
            uint256 len = _loan.nftAddressArray.length;
            for (uint256 ii = 0; ii < len; ii++) {
                TribeOneHelper.safeTransferNFT(
                    _loan.nftAddressArray[ii],
                    _agent,
                    address(this),
                    _loan.nftTokenTypeArray[ii],
                    _loan.nftTokenIdArray[ii]
                );
            }

            _loan.status = Status.LOANACTIVED;
            _loan.loanStart = block.timestamp;
            // user can not get back collateral in this case, we transfer collateral to AssetManager
            address _currency = _loan.collateralAsset.currency;
            uint256 _amount = _loan.collateralAsset.amount;
            // TribeOneHelper.safeTransferAsset(_currency, assetManager, _amount);
            if (_currency == address(0)) {
                IAssetManager(assetManager).collectInstallment{value: _amount}(
                    _currency,
                    _amount,
                    _loan.loanRules.interest,
                    true
                );
            } else {
                IAssetManager(assetManager).collectInstallment(_currency, _amount, _loan.loanRules.interest, true);
            }
        } else {
            _loan.status = Status.FAILED;
            // refund loan
            // in the case when loan currency is ETH, loan amount should be fund back from agent to TribeOne AssetNanager
            address _token = _loan.loanAsset.currency;
            uint256 _amount = _loan.loanAsset.amount + _loan.fundAmount;
            if (_token == address(0)) {
                require(msg.value >= _amount, "TribeOne: Less than loan amount");
                if (msg.value > _amount) {
                    TribeOneHelper.safeTransferETH(_agent, msg.value - _amount);
                }
                IAssetManager(assetManager).collectInstallment{value: _amount}(_token, _amount, _loan.loanRules.interest, true);
            } else {
                TribeOneHelper.safeTransferFrom(_token, _agent, address(this), _amount);
                IAssetManager(assetManager).collectInstallment(_token, _amount, _loan.loanRules.interest, true);
            }

            returnColleteral(_loanId);
        }

        emit NFTRelayed(_loanId, _agent, _accepted);
    }

    function payInstallment(uint256 _loanId, uint256 _amount) external payable nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED || _loan.status == Status.DEFAULTED, "TribeOne: Invalid status");
        uint256 expectedNr = expectedNrOfPayments(_loanId);

        address _loanCurrency = _loan.loanAsset.currency;
        if (_loanCurrency == address(0)) {
            _amount = msg.value;
        }

        uint256 paidAmount = _loan.paidAmount;
        uint256 _totalDebt = totalDebt(_loanId); // loan + interest
        {
            uint256 expectedAmount = (_totalDebt * expectedNr) / _loan.loanRules.tenor;
            require(paidAmount + _amount >= expectedAmount, "TribeOne: Insufficient Amount");
            // out of rule, penalty
            _updatePenalty(_loanId);
        }

        // Transfer asset from msg.sender to AssetManager contract
        uint256 dust;
        if (paidAmount + _amount > _totalDebt) {
            dust = paidAmount + _amount - _totalDebt;
        }
        _amount -= dust;
        // NOTE - don't merge two conditions
        // All user payments will go to AssetManager contract
        if (_loanCurrency == address(0)) {
            if (dust > 0) {
                TribeOneHelper.safeTransferETH(_msgSender(), dust);
            }
            // TribeOneHelper.safeTransferETH(assetManager, _amount);
            IAssetManager(assetManager).collectInstallment{value: _amount}(
                _loanCurrency,
                _amount,
                _loan.loanRules.interest,
                false
            );
        } else {
            TribeOneHelper.safeTransferFrom(_loanCurrency, _msgSender(), address(this), _amount);
            IAssetManager(assetManager).collectInstallment(_loanCurrency, _amount, _loan.loanRules.interest, false);
        }

        _loan.paidAmount += _amount;
        uint256 passedTenors = (_loan.paidAmount * _loan.loanRules.tenor) / _totalDebt;

        if (passedTenors > _loan.passedTenors) {
            _loan.passedTenors = uint8(passedTenors);
        }

        if (_loan.status == Status.DEFAULTED) {
            _loan.status = Status.LOANACTIVED;
        }

        // If user is borrower and loan is paid whole amount and he has no lateFee, give back NFT here directly
        // else borrower should call withdraw manually himself
        // We should check conditions first to avoid transaction failed
        if (paidAmount + _amount == _totalDebt) {
            _loan.status = Status.LOANPAID;
            if (_loan.borrower == _msgSender() && (_loan.nrOfPenalty == 0 || lateFee == 0)) {
                _withdrawNFT(_loanId);
            }
        }

        emit InstallmentPaid(_loanId, msg.sender, _loanCurrency, _amount);
    }

    function withdrawNFT(uint256 _loanId) external nonReentrant {
        _withdrawNFT(_loanId);
    }

    function _withdrawNFT(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANPAID, "TribeOne: Invalid status - you have still debt to pay");
        address _sender = _msgSender();
        require(_sender == _loan.borrower, "TribeOne: Forbidden");
        _loan.status = Status.WITHDRAWN;

        if (_loan.nrOfPenalty > 0 && lateFee > 0) {
            uint256 _totalLateFee = _loan.nrOfPenalty * lateFee * (10**IERC20Metadata(feeCurrency).decimals());
            TribeOneHelper.safeTransferFrom(feeCurrency, _sender, address(feeTo), _totalLateFee);
        }

        uint256 len = _loan.nftAddressArray.length;
        for (uint256 ii = 0; ii < len; ii++) {
            address _nftAddress = _loan.nftAddressArray[ii];
            uint256 _tokenId = _loan.nftTokenIdArray[ii];
            TribeOneHelper.safeTransferNFT(_nftAddress, address(this), _sender, _loan.nftTokenTypeArray[ii], _tokenId);
        }

        emit NFTWithdrew(_loanId, _sender);
    }

    function _updatePenalty(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED || _loan.status == Status.DEFAULTED, "TribeOne: Not actived loan");
        uint256 expectedNr = expectedNrOfPayments(_loanId);
        uint256 passedTenors = _loan.passedTenors;
        if (expectedNr > passedTenors) {
            _loan.nrOfPenalty += uint8(expectedNr - passedTenors);
        }
    }

    /**
     * @dev shows loan + interest
     */
    function totalDebt(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        return (_loan.loanAsset.amount * (10000 + _loan.loanRules.interest)) / 10000;
    }

    /**
     *@dev when user in Tenor 2 (from tenor 1 to tenor 2, we expect at least one time payment)
     */
    function expectedNrOfPayments(uint256 _loanId) private view returns (uint256) {
        uint256 loanStart = loans[_loanId].loanStart;
        uint256 _expected = (block.timestamp - loanStart) / TENOR_UNIT;
        uint256 _tenor = loans[_loanId].loanRules.tenor;
        return _expected > _tenor ? _tenor : _expected;
    }

    function expectedLastPaymentTime(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        return
            _loan.passedTenors >= _loan.loanRules.tenor
                ? _loan.loanStart + TENOR_UNIT * (_loan.loanRules.tenor)
                : _loan.loanStart + TENOR_UNIT * (_loan.passedTenors + 1);
    }

    function setLoanDefaulted(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LOANACTIVED, "TribeOne: Invalid status");
        require(expectedLastPaymentTime(_loanId) < block.timestamp, "TribeOne: Not overdued date yet");

        _loan.status = Status.DEFAULTED;

        emit LoanDefaulted(_loanId);
    }

    function setLoanLiquidation(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.DEFAULTED, "TribeOne: Invalid status");
        require(expectedLastPaymentTime(_loanId) + GRACE_PERIOD < block.timestamp, "TribeOne: Not overdued date yet");
        _loan.status = Status.LIQUIDATION;
        uint256 len = _loan.nftAddressArray.length;

        // Transfering NFTs first
        for (uint256 ii = 0; ii < len; ii++) {
            address _nftAddress = _loan.nftAddressArray[ii];
            uint256 _tokenId = _loan.nftTokenIdArray[ii];
            TribeOneHelper.safeTransferNFT(_nftAddress, address(this), salesManager, _loan.nftTokenTypeArray[ii], _tokenId);
        }

        emit LoanLiquidation(_loanId, salesManager);
    }

    /**
     * @dev after sold NFT set in market place, and give that fund back to TribeOne
     * Only sales manager can do this
     */
    function postLiquidation(uint256 _loanId, uint256 _amount) external payable nonReentrant {
        require(_msgSender() == salesManager, "TribeOne: Forbidden");
        Loan storage _loan = loans[_loanId];
        require(_loan.status == Status.LIQUIDATION, "TribeOne: invalid status");

        // We collect debts to our asset manager address
        address _currency = _loan.loanAsset.currency;
        _amount = _currency == address(0) ? msg.value : _amount;
        uint256 _finalDebt = finalDebtAndPenalty(_loanId);
        _finalDebt = _amount > _finalDebt ? _finalDebt : _amount;
        if (_currency == address(0)) {
            // TribeOneHelper.safeTransferETH(assetManager, _finalDebt);
            IAssetManager(assetManager).collectInstallment{value: _finalDebt}(
                _currency,
                _finalDebt,
                _loan.loanRules.interest,
                false
            );
        } else {
            TribeOneHelper.safeTransferFrom(_currency, _msgSender(), address(this), _amount);
            IAssetManager(assetManager).collectInstallment(_currency, _finalDebt, _loan.loanRules.interest, false);
        }

        _loan.status = Status.POSTLIQUIDATION;
        if (_amount > _finalDebt) {
            _loan.restAmount = _amount - _finalDebt;
        }
        _loan.postTime = block.timestamp;
        emit LoanPostLiquidation(_loanId, _amount, _finalDebt);
    }

    function finalDebtAndPenalty(uint256 _loanId) public view returns (uint256) {
        Loan storage _loan = loans[_loanId];
        uint256 paidAmount = _loan.paidAmount;
        uint256 _totalDebt = totalDebt(_loanId);
        uint256 _penalty = ((_totalDebt - paidAmount) * penaltyFee) / 1000; // 5% penalty of loan amount
        return _totalDebt + _penalty - paidAmount;
    }

    /**
     * @dev User can get back the rest money through this function, but he should pay late fee.
     */
    function getBackFund(uint256 _loanId) external {
        Loan storage _loan = loans[_loanId];
        require(_msgSender() == _loan.borrower, "TribOne: Forbidden");
        require(_loan.status == Status.POSTLIQUIDATION, "TribeOne: Invalid status");
        require(_loan.postTime + GRACE_PERIOD > block.timestamp, "TribeOne: Time over");
        uint256 _restAmount = _loan.restAmount;
        require(_restAmount > 0, "TribeOne: No amount to give back");

        if (lateFee > 0) {
            uint256 _amount = lateFee * (10**IERC20Metadata(feeCurrency).decimals()) * _loan.nrOfPenalty; // tenor late fee
            TribeOneHelper.safeTransferFrom(feeCurrency, _msgSender(), address(feeTo), _amount);
        }

        _loan.status = Status.RESTWITHDRAWN;

        address _currency = _loan.loanAsset.currency;

        if (_currency == address(0)) {
            TribeOneHelper.safeTransferETH(_msgSender(), _restAmount);
        } else {
            TribeOneHelper.safeTransfer(_currency, _msgSender(), _restAmount);
        }

        emit RestWithdrew(_loanId, _restAmount);
    }

    /**
     * @dev if user does not want to get back rest of money due to some reasons, such as gas fee...
     * we will transfer rest money to our fee address (after 14 days notification).
     * For saving gas fee, we will transfer once for the one kind of token.
     */
    function lockRestAmount(uint256[] calldata _loanIds, address _currency) external nonReentrant {
        uint256 len = _loanIds.length;
        uint256 _amount = 0;
        for (uint256 ii = 0; ii < len; ii++) {
            uint256 _loanId = _loanIds[ii];
            Loan storage _loan = loans[_loanId];
            if (
                _loan.loanAsset.currency == _currency &&
                _loan.status == Status.POSTLIQUIDATION &&
                _loan.postTime + GRACE_PERIOD <= block.timestamp
            ) {
                _amount += _loan.restAmount;
                _loan.status = Status.RESTLOCKED;
            }
        }

        TribeOneHelper.safeTransferAsset(_currency, feeTo, _amount);
    }

    function cancelLoan(uint256 _loanId) external nonReentrant {
        Loan storage _loan = loans[_loanId];
        require(_loan.borrower == _msgSender() && _loan.status == Status.LISTED, "TribeOne: Forbidden");
        _loan.status = Status.CANCELLED;
        returnColleteral(_loanId);
        emit LoanCanceled(_loanId, _msgSender());
    }

    /**
     * @dev return back collateral to borrower due to some reasons
     */
    function returnColleteral(uint256 _loanId) private {
        Loan storage _loan = loans[_loanId];
        address _currency = _loan.collateralAsset.currency;
        uint256 _amount = _loan.collateralAsset.amount;
        address _to = _loan.borrower;
        TribeOneHelper.safeTransferAsset(_currency, _to, _amount);
    }

    function setAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, type(uint256).max);
    }

    function revokeAllowanceForAssetManager(address _token) external onlySuperOwner {
        TribeOneHelper.safeApprove(_token, assetManager, 0);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

    constructor () {
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ITribeOne {
    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external;

    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IAssetManager {
    function isAvailableLoanAsset(address _asset) external returns (bool);

    function isAvailableCollateralAsset(address _asset) external returns (bool);

    function isValidAutomaticLoan(address _asset, uint256 _amountIn) external returns (bool);

    function requestETH(address _to, uint256 _amount) external;

    function requestToken(
        address _to,
        address _token,
        uint256 _amount
    ) external;

    function collectInstallment(
        address _currency,
        uint256 _amount,
        uint256 _interest,
        bool _collateral
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev this smart contract is copy of Openzeppelin Ownable.sol, but we introduced superOwner here
 */
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
abstract contract Ownable is Context {
    address private _owner;
    address private _superOwner;
    mapping(address => bool) private admins; // These admins can approve loan manually

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SuperOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed _setter, address indexed _admin);
    event RemoveAdmin(address indexed _setter, address indexed _admin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _superOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function superOwner() external view returns (address) {
        return _superOwner;
    }

    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender() || admins[_msgSender()], "Ownable: caller is neither the owner nor the admin");
        _;
    }

    modifier onlySuperOwner() {
        require(_superOwner == _msgSender(), "Ownable: caller is not the super owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferSuperOwnerShip(address newSuperOwner) public virtual onlySuperOwner {
        require(newSuperOwner != address(0), "Ownable: new super owner is the zero address");
        emit SuperOwnershipTransferred(_superOwner, newSuperOwner);
        _superOwner = newSuperOwner;
    }

    function addAdmin(address _admin) external onlySuperOwner {
        require(!isAdmin(_admin), "Already admin");
        admins[_admin] = true;
        emit AddAdmin(msg.sender, _admin);
    }

    function removeAdmin(address _admin) external onlySuperOwner {
        require(isAdmin(_admin), "This address is not admin");
        admins[_admin] = false;
        emit RemoveAdmin(msg.sender, _admin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TribeOneHelper {
    enum TokenType {
        ERC721,
        ERC1155
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TribeOneHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TribeOneHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TribeOneHelper::safeTransferETH: ETH transfer failed");
    }

    function safeTransferAsset(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) {
            safeTransferETH(to, value);
        } else {
            safeTransfer(token, to, value);
        }
    }

    function safeTransferNFT(
        address _nft,
        address _from,
        address _to,
        TokenType _type,
        uint256 _tokenId
    ) internal {
        if (_type == TokenType.ERC721) {
            IERC721(_nft).safeTransferFrom(_from, _to, _tokenId);
        } else {
            IERC1155(_nft).safeTransferFrom(_from, _to, _tokenId, 1, "0x00");
        }
    }

    /**
     * @dev this function calculates expected price of NFT based on created LTV and fund amount,
     * LTV: 10000 = 100%; _slippage: 10000 = 100%
     */
    function getExpectedPrice(
        uint256 _fundAmount,
        uint256 _LTV,
        uint256 _slippage
    ) internal pure returns (uint256) {
        require(_LTV != 0, "TribeOneHelper: LTV should not be 0");
        return (_fundAmount * (10000 + _slippage)) / _LTV;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}