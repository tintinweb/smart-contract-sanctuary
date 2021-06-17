// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./CappedTimedCrowdsale.sol";
import "./RefundPostdevCrowdsale.sol";


/**
**  ICO Contract for the LBC crowdsale
*/
contract HLBICO is CappedTimedCrowdsale, RefundablePostDeliveryCrowdsale {
    using SafeMath for uint256;

    /*
    ** Global State
    */
    bool public initialized; // default : false

    /*
    ** Addresses
    */
    address public _deployingAddress; // should remain the same as deployer's address
    address public _whitelistingAddress; // should be oracle
    address public _reserveAddress; // should be deployer then humble reserve

    /*
    ** Events
    */
    event InitializedContract(address indexed changerAddress, address indexed whitelistingAddress);
    event ChangedWhitelisterAddress(address indexed whitelisterAddress, address indexed changerAddress);
    event ChangedReserveAddress(address indexed reserveAddress, address indexed changerAddress);
    event ChangedDeployerAddress(address indexed deployerAddress, address indexed changerAddress);
    event BlacklistedAdded(address indexed account);
    event BlacklistedRemoved(address indexed account);
    event UpdatedCaps(uint256 newGoal, uint256 newCap, uint256 newTranche, uint256 newMaxInvest, uint256 newRate, uint256 newRateCoef);

    /*
    ** Attrs
    */
    uint256 private _currentRate;
    uint256 private _rateCoef;
    mapping(address => bool) private _blacklistedAddrs;
    mapping(address => uint256) private _investmentAddrs;
    uint256 private _weiMaxInvest;
    uint256 private _etherTranche;
    uint256 private _currentWeiTranche; // Holds the current invested value for a tranche
    uint256 private _deliverToReserve;
    uint256 private _minimumInvest;

    /*
    * initialRateReceived : Number of token units a buyer gets per wei for the first investment slice. Should be 5000 (diving by 1000 for 3 decimals).
    * walletReceived : Wallet that will get the invested eth at the end of the crowdsale
    * tokenReceived : Address of the LBC token being sold
    * openingTimeReceived : Starting date of the ICO
    * closingtimeReceived : Ending date of the ICO
    * capReceived : Max amount of wei to be contributed
    * goalReceived : Funding goal
    * etherMaxInvestReceived : Maximum ether that can be invested
    */
    constructor(uint256 initialRateReceived,
        uint256 rateCoefficientReceived,
        address payable walletReceived,
        LBCToken tokenReceived,
        uint256 openingTimeReceived,
        uint256 closingTimeReceived,
        uint256 capReceived,
        uint256 goalReceived)
        CrowdsaleMint(initialRateReceived, walletReceived, tokenReceived)
        TimedCrowdsale(openingTimeReceived, closingTimeReceived)
        CappedTimedCrowdsale(capReceived)
        RefundableCrowdsale(goalReceived) {
        _deployingAddress = msg.sender;
        _etherTranche = 250000000000000000000; // 300000€; For eth = 1200 €
        _weiMaxInvest = 8340000000000000000; // 10008€; for eth = 1200 €
        _currentRate = initialRateReceived;
        _rateCoef = rateCoefficientReceived;
        _currentWeiTranche = 0;
        _deliverToReserve = 0;
        _minimumInvest = 1000000000000000; // 1.20€; for eth = 1200€
    }

    /*
    ** Initializes the contract address and affects addresses to their roles.
    */
    function init(
        address whitelistingAddress,
        address reserveAddress
    )
    public
    isNotInitialized
    onlyDeployingAddress
    {
        require(whitelistingAddress != address(0), "HLBICO: whitelistingAddress cannot be 0x");
        require(reserveAddress != address(0), "HLBICO: reserveAddress cannot be 0x");

        _whitelistingAddress = whitelistingAddress;
        _reserveAddress = reserveAddress;
        initialized = true;

        emit InitializedContract(_msgSender(), whitelistingAddress);
    }

    /**
     * @dev Returns the rate of tokens per wei at the present time and computes rate depending on tranche.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens a buyer gets per wei for a given tranche
     */
    function _getCustomAmount(uint256 weiAmount) internal returns (uint256) {
        if (!isOpen()) {
            return 0;
        }

        uint256 calculatedAmount = 0;

        _currentWeiTranche = _currentWeiTranche.add(weiAmount);

        if (_currentWeiTranche > _etherTranche) {
            _currentWeiTranche = _currentWeiTranche.sub(_etherTranche);

            //If we updated the tranche manually to a smaller one
            uint256 manualSkew = weiAmount.sub(_currentWeiTranche);

            if (manualSkew >= 0) {
                calculatedAmount = calculatedAmount.add(weiAmount.sub(_currentWeiTranche).mul(rate()));
                _currentRate -= _rateCoef; // coefficient for 35 tokens reduction for each tranche
                calculatedAmount = calculatedAmount.add(_currentWeiTranche.mul(rate()));
            }
            //If there is a skew between invested wei and calculated wei for a tranche
            else {
                _currentRate -= _rateCoef; // coefficient for 35 tokens reduction for each tranche
                calculatedAmount = calculatedAmount.add(weiAmount.mul(rate()));
            }
        }
        else
            calculatedAmount = calculatedAmount.add(weiAmount.mul(rate()));

        uint256 participationAmount = calculatedAmount.mul(5).div(100);

        calculatedAmount = calculatedAmount.sub(participationAmount);
        _deliverToReserve = _deliverToReserve.add(participationAmount);

        return calculatedAmount;
    }

    /*
    ** Adjusts all parameters influenced by Ether value based on a percentage coefficient
    ** coef is based on 4 digits for decimal representation with 1 precision
    ** i.e : 934 -> 93.4%; 1278 -> 127.8%
    */
    function adjustEtherValue(uint256 coef)
    public
    onlyDeployingAddress {
        require(coef > 0 && coef < 10000, "HLBICO: coef isn't within range of authorized values");

        uint256 baseCoef = 1000;

        changeGoal(goal().mul(coef).div(1000));
        changeCap(cap().mul(coef).div(1000));
        _etherTranche = _etherTranche.mul(coef).div(1000);
        _weiMaxInvest = _weiMaxInvest.mul(coef).div(1000);
        
        if (coef > 1000) {
            coef = coef.sub(1000);
            _currentRate = _currentRate.sub(_currentRate.mul(coef).div(1000));
            _rateCoef = _rateCoef.sub(_rateCoef.mul(coef).div(1000));
        } else {
            coef = baseCoef.sub(coef);
            _currentRate = _currentRate.add(_currentRate.mul(coef).div(1000));
            _rateCoef = _rateCoef.add(_rateCoef.mul(coef).div(1000));
        }

        emit UpdatedCaps(goal(), cap(), _etherTranche, _weiMaxInvest, _currentRate, _rateCoef);
    }

    function rate() public view override returns (uint256) {
       return _currentRate;
    }

    function getNextRate() public view returns (uint256) {
        return _currentRate.sub(_rateCoef);
    }

    /*
    ** Changes the address of the token contract. Must only be callable by deployer
    */
    function changeToken(LBCToken newToken)
    public
    onlyDeployingAddress
    {
        _changeToken(newToken);
    }

    /*
    ** Changes the address with whitelisting role and can only be called by deployer
    */
    function changeWhitelister(address newWhitelisterAddress)
    public
    onlyDeployingAddress
    {
        _whitelistingAddress = newWhitelisterAddress;
        emit ChangedWhitelisterAddress(newWhitelisterAddress, _msgSender());
    }
    
    /*
    ** Changes the address with deployer role and can only be called by deployer
    */
    function changeDeployer(address newDeployerAddress)
    public
    onlyDeployingAddress
    {
        _deployingAddress = newDeployerAddress;
        emit ChangedDeployerAddress(_deployingAddress, _msgSender());
    }

    /*
    ** Changes the address with pause role and can only be called by deployer
    */
    function changeReserveAddress(address newReserveAddress)
    public
    onlyDeployingAddress
    {
        _reserveAddress = newReserveAddress;
        emit ChangedReserveAddress(newReserveAddress, _msgSender());
    }

    /**
     * @dev Escrow finalization task, called when finalize() is called.
     */
    function _finalization() override virtual internal {
        // Mints the 5% participation and sends it to humblereserve
        if (goalReached()) {
            _deliverTokens(_reserveAddress, _deliverToReserve);
        }

        super._finalization();
    }

    /*
    ** Checks if an adress has been blacklisted before letting them withdraw their funds
    */
    function withdrawTokens(address beneficiary) override virtual public {
        require(!isBlacklisted(beneficiary), "HLBICO: account is blacklisted");

        super.withdrawTokens(beneficiary);
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 weiAmount) internal override returns (uint256) {
       return _getCustomAmount(weiAmount);
    }

    function _forwardFunds() internal override(CrowdsaleMint, RefundablePostDeliveryCrowdsale) {
        RefundablePostDeliveryCrowdsale._forwardFunds();
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override(TimedCrowdsale, CappedTimedCrowdsale) view {
        require(weiAmount >= _minimumInvest, "HLBICO: Investment must be greater than or equal to 0.001 eth");
        _dontExceedAmount(beneficiary, weiAmount);
        CappedTimedCrowdsale._preValidatePurchase(beneficiary, weiAmount);
    }

    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal override {
        require(beneficiary != address(0), "HLBICO: _postValidatePurchase benificiary is the zero address");

        _investmentAddrs[beneficiary] = _investmentAddrs[beneficiary].add(weiAmount);        
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal override(CrowdsaleMint, RefundablePostDeliveryCrowdsale) {
        RefundablePostDeliveryCrowdsale._processPurchase(beneficiary, tokenAmount);
    }

    function hasClosed() public view override(TimedCrowdsale, CappedTimedCrowdsale) returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return CappedTimedCrowdsale.hasClosed();
    }

    function etherTranche() public view returns (uint256) {
        return _etherTranche;
    }

    function maxInvest() public view returns (uint256) {
        return _weiMaxInvest;
    }

    function addBlacklisted(address account) public onlyWhitelistingAddress {
        _addBlacklisted(account);
    }

    function removeBlacklisted(address account) public onlyWhitelistingAddress {
        _removeBlacklisted(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        require(account != address(0), "HLBICO: account is zero address");
        return _blacklistedAddrs[account];
    }

    function _addBlacklisted(address account) internal {
        require(!isBlacklisted(account), "HLBICO: account already blacklisted");
        _blacklistedAddrs[account] = true;
        emit BlacklistedAdded(account);
    }

    function _removeBlacklisted(address account) internal {
        require(isBlacklisted(account), "HLBICO: account is not blacklisted");
        _blacklistedAddrs[account] = true;
        emit BlacklistedRemoved(account);
    }

    function _dontExceedAmount(address beneficiary, uint256 weiAmount) internal view {
        require(_investmentAddrs[beneficiary].add(weiAmount) <= _weiMaxInvest,
          "HLBICO: Cannot invest more than KYC limit.");
    }

    modifier onlyWhitelistingAddress() {
        require(_msgSender() == _whitelistingAddress, "HLBICO: caller does not have the Whitelisted role");
        _;
    }

    /*
    ** Checks if the contract hasn't already been initialized
    */
    modifier isNotInitialized() {
        require(initialized == false, "HLBICO: contract is already initialized.");
        _;
    }

    /*
    ** Checks if the sender is the minter controller address
    */
    modifier onlyDeployingAddress() {
        require(msg.sender == _deployingAddress, "HLBICO: only the deploying address can call this method.");
        _;
    }

}