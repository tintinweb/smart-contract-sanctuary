/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// Part: OpenZeppelin/[email protected]/IERC20

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
    
    
    function aSellFeeSharehold( address _toAddress, uint256 _amount, uint8 _envelopeNumber ) external returns( bool );
    
    function agetShareHoldOf( address _UserAddress, uint8 _envelopeNumber ) view external returns( uint256, uint8 );
    
    function agetProperty( bytes32 _PropertyID) view external returns ( bool, address, address, address, uint256, uint256, bytes32, uint256, uint256, uint256, uint256, uint8, bool );

    function agetUserCard( address _UserAddress) view external returns ( bool, bool, address, address, address, address, uint8 );
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

// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.4;
/*
* Equitable Builds Inc presents..
* ====================================*
*        _____ ___ _______ ______     *
*       |  _  |  ||  |  __|   __|     *
*       |     |  |  |  __|   |__      *
*       |__|__|_____|____|_____|      *
*                                     *
*        _____ __________ ______      *
*       |     |   | | | ||   __|      *
*       |  |  |     | | ||__   |      *
*       |_____|_|___|___||_____|      *
*                                     *
*        _____ ____________ ___       *
*       |     |  |  |   | ||  |       *
*       |  |  |  |  |     ||  |       *
*       |_____|_|_|_|_|___||__|       *
*                                     *
* ====================================*
*/
contract AVEC{
     /*=================================   
     =            ERC20           =    
     =================================*/
    string public name = "The Wealth Architect";
    string public symbol = "AVEC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    IERC20 public wai = IERC20(0xa2e5833D7d6CA149475005eB1f2DDccB61C04e95);
    function allowance(address tokenOwner, address spender)
        public
        view returns (uint remaining) {
            remaining = GUsers[tokenOwner]._allowed[spender];
    }
    function balanceOf(address _UserAddress)
        view
        public
        returns(uint256 balance)
    {
        balance = GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_];
    }
    function transfer(address to, uint amount) public returns(bool success){
        success = transferFrom(msg.sender, to, amount);
    }
    function transferFrom(
        address from, 
        address to, 
        uint256 tokens)
        public
        returns(bool success)
    {
        require(balanceOf(from) >= (tokens + (tokens / 50)) && from != to);
        if (from != msg.sender && allowance(from, msg.sender) >= 1) {
            require(GUsers[from]._allowed[msg.sender] >= (tokens + (tokens / 50)));
            GUsers[from]._allowed[msg.sender] -= (tokens + (tokens / 50));
            if(GUsers[msg.sender].transferType_ == 1){
                    requireUserPrivilegeLevel(1, msg.sender);
                    requireUserPrivilegeLevel(1, to);
            }
        }
        updateValueI(from, GUsers[from].transferingPropertyid_);
        updateValueI(to, GUsers[from].transferingPropertyid_);
        // setup
        updateEquityRents(tokens);
        GUsers[to].PropertyAvecBalance[GUsers[from].transferingPropertyid_] += tokens;
        GUsers[from].amountCirculated_ += (tokens + (tokens / 50));
        GUsers[from].PropertyAvecBalance[GUsers[from].transferingPropertyid_] -= (tokens + (tokens / 50));
        GUsers[msg.sender].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
        emit Transfer(from, to, (tokens + (tokens / 50)));
        success = true;
    }
    function approve(
        address spender, 
        uint256 value)
        public
        returns (bool success) {
            requireUserPrivilegeLevel(0, msg.sender);
            if(spender != address(0)){
                GUsers[msg.sender]._allowed[spender]
                = value;
                emit Approval(msg.sender, spender, value);
                success = true;
            } else {
                success = false;
            }
    }
    /*=================================
    =            Structs            =
    =================================*/
    struct PropertyEscrow {
        bool escrowCompleted;
        uint8 escrowAgreementNumber;
        address payable recipientOfFunds;
        bytes32 PropertyID;
        bytes32 recipientName;
        uint256 milestonePriceOfEscrowInETH;
        uint256 tokensAvailableTotal;
        uint256 tokensAvailableCurrent;
        uint256 totalETHReceived;
        uint256 ethPerToken;
        uint256 propertyIncrease;
        mapping(address => uint256) AgreementAmountDueInTokens;
    }
    struct TotalHolds {
        mapping(uint8 => uint48) feeHoldsTotalByEnvelope;
    }
    struct FeeWallet {
        address  whoaaddress;
        address  whoamaintenanceaddress;
        address  whoarewardsaddress;
        address  cevaaddress;
        address  credibleyouaddress;
        address  techaddress;
        address  existholdingsaddress;
        address  existcryptoaddress;
        bytes32  feeWalletSecretID;
    }
    struct Property {
        bool Set;
        bool firstEscrowSet;
        uint8 currentEscrowAgreementNumber;
        uint8[] escrowAgreementNumber;
        address Owner;
        address FounderDeveloper;
        address Ceva;
        address holdOne;
        address holdTwo;
        address holdThree;
        bytes32 PropertyID;
        uint256 Value;
        uint256 lastMintingPrice_;
        uint256 NumberOfTokensToEscrow;
        uint256 propertyGlobalBalance_;
        uint256 propertyPriceUpdateCountAsset_;
        mapping(address => uint256) propertyLastKnownValue_;
    }
    struct User {
        bool Set;
        uint8 transferType_;
        uint8 UserPrivilegeLevel;
        address UserAddress;
        address Ceva;
        address FounderDeveloperTwo;
        address FounderDeveloperOne;
        bytes32 workingPropertyid_;
        bytes32 transferingPropertyid_;
        bytes32 workingMintRequestid_;
        bytes32 workingBurnRequestid_;
        bytes32[] Properties;
        uint256 amountCirculated_;
        uint256 mintingDepositsOf_;
        mapping(uint8 => uint256) FeesTotalWithdrawnByEnvelope_;
        mapping(uint8 => uint256) FeesPreviousWithdrawnByEnvelope_;
        mapping(uint8 => uint256) FeeShareholdByEnvelope_;
        mapping(bytes32 => bool) burnrequestwhitelist_;
        mapping(bytes32 => uint8) lastknownPropertyEscrowAgreementNumber;
        mapping(bytes32 => uint256) PropertyAvecBalance;
        mapping(bytes32 => uint256) propertyvalueOld_;
        mapping(address => mapping(bytes32 => uint256)) propertyPriceUpdateCountMember_;
        mapping(address => uint256) _allowed;
    }
    /*==============================
    =            EVENTS            =
    ==============================*/
    event AVECtoONUS(
        address indexed MemberAddress,
        uint256 tokensConverted,
        bytes32 indexed PropertyID
    );
    event ONUStoAVEC(
        address indexed MemberAddress,
        uint256 tokensConverted,
        bytes32 indexed PropertyID
    );
    event OnWithdraw(
        address indexed MemberAddress,
        uint256 tokensWithdrawn,
        uint8 indexed envelopeNumber
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Burn(
        address indexed from,
        uint256 tokens,
        uint256 propertyValue
    );
    event Approval(
        address indexed _UserAddress,
        address indexed _spender,
        uint256 _Lvalue
    );
    event PropertyValuation(
        address indexed from,
        bytes32 indexed _propertyUniqueID,
        uint256 propertyValue
    );
    event ContributionMade(
        address indexed contributor, 
        uint256 amount, 
        bytes32 indexed PropertyID, 
        uint8 indexed escrowNumber, 
        bool fundingComplete
    );  
    event UserSet(
        address indexed User
    );
    event LicensePurchase(
        address indexed User,
        address indexed CEVA,
        address indexed FDone,
        address FDTwo
    );
    event AVECMinted(
        address indexed CEVA,
        address indexed FD,
        address indexed USER,
        uint256 Amount,
        uint256 AmountEscrowed
    );
    event EscrowCreated(
        address indexed CEVA,
        address indexed Recipient,
        bytes32 REcipientName,
        uint256 MilestoneETH,
        uint256 TokensAVAILABLE,
        bytes32 indexed PropertyID,
        uint8 EscrowAgreementNumber
    );
    event PropertySet(
        bool Set,
        bytes32 indexed PropertyID,
        address indexed CEVA,
        address FDOne,
        address OWNER,
        uint256 indexed Value
    );
    event AVECWithdrawnFromEscrow(
        address indexed User,
        uint256 amount,
        bytes32 indexed PropertyID
    );
    event FeeShareholdSOLD(
        address indexed Seller,
        address indexed Buyer,
        uint256 amount
    );
    event ValueUpdate(
        address indexed User,
        bytes32 indexed PropertyID,
        uint256 Before,
        uint256 indexed After
    );
    /*=================================
    =            Mapping              =
    =================================*/
    mapping(bytes32 => Property) Properties;
    mapping(bytes32 => FeeWallet) private GFeeWallets;
    mapping(bytes32 => mapping(uint8 => PropertyEscrow)) private GEscrowAgreements;
    mapping(address => User) GUsers;
    mapping(address => uint256) amountDueInTokens;
    mapping(address => TotalHolds) private LatestTotalHolds;
    /*=================================
    =            bytes32              =
    =================================*/
    bytes32 private GfeeWalletSecretID_;
    bytes32[] private GListFeeWalletSecretIDs;
    /*=================================
    =            address              =
    =================================*/
   /*================================
    =            uint               =
    ================================*/
    uint256 ETHERESCROWED;
    uint256 ETHERTOTALRECEIVED;
    uint256 ETHERTOTALWITHDRAWN;
    /*================================
    =            bool               =
    ================================*/
    bool internal adminset_ = false;
    /*=================================
    =        admin  functions         =
    =================================*/
    function setFeeWalletSecret(bytes32 secret) public{
        requireUserPrivilegeLevel(4, msg.sender);
        GfeeWalletSecretID_ = secret;
    }
    function asetFeeWallet(
        bytes32 _LfeeWalletSecretID,
        address _whoaaddress,
        address _whoamaintenanceaddress,
        address _whoarewardsaddress,
        address _cevaaddress,
        address _credibleyouaddress,
        address _techaddress,
        address _existholdingsaddress,
        address _existcryptoaddress) public returns(bool success){
            requireUserPrivilegeLevel(4, msg.sender);
            AVEC.FeeWallet storage feeWallet = GFeeWallets[_LfeeWalletSecretID];
                if(_whoaaddress == address(0x0)  || _whoamaintenanceaddress == address(0x0) || _whoarewardsaddress == address(0x0) || _cevaaddress == address(0x0) 
                || _credibleyouaddress == address(0x0) || _techaddress == address(0x0) || _existholdingsaddress == address(0x0) || _existcryptoaddress == address(0x0)) {
                    success = false;
                } else {
                    feeWallet.feeWalletSecretID = _LfeeWalletSecretID;
                    feeWallet.whoaaddress = _whoaaddress;
                    feeWallet.whoamaintenanceaddress = _whoamaintenanceaddress;
                    feeWallet.whoarewardsaddress = _whoarewardsaddress;
                    feeWallet.cevaaddress = _cevaaddress;
                    feeWallet.credibleyouaddress = _credibleyouaddress;
                    feeWallet.techaddress = _techaddress;
                    feeWallet.existholdingsaddress = _existholdingsaddress;
                    feeWallet.existcryptoaddress = _existcryptoaddress;
                    Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Owner = _whoaaddress;
                    success = true;
                }
    }
    function agetFeeWallet(bytes32 thefeeWalletSecretID) view public returns (
        bytes32 _feeWalletSecretID,
        address _whoaaddress,
        address _whoamaintenanceaddress,
        address _whoarewardsaddress,
        address _cevaaddress,
        address _credibleyouaddress,
        address _techaddress,
        address _existholdingsaddress,
        address _existcryptoaddress) {
            requireUserPrivilegeLevel(4, msg.sender);
            _feeWalletSecretID = GFeeWallets[thefeeWalletSecretID].feeWalletSecretID;
            _whoaaddress = GFeeWallets[thefeeWalletSecretID].whoaaddress;
            _whoamaintenanceaddress = GFeeWallets[thefeeWalletSecretID].whoamaintenanceaddress;
            _whoarewardsaddress = GFeeWallets[thefeeWalletSecretID].whoarewardsaddress;
            _cevaaddress = GFeeWallets[thefeeWalletSecretID].cevaaddress;
            _credibleyouaddress = GFeeWallets[thefeeWalletSecretID].credibleyouaddress;
            _techaddress = GFeeWallets[thefeeWalletSecretID].techaddress;
            _existholdingsaddress = GFeeWallets[thefeeWalletSecretID].existholdingsaddress;
            _existcryptoaddress = GFeeWallets[thefeeWalletSecretID].existcryptoaddress;
    }
    function withdrawEther(uint256 amount)
        public
        returns(bool success){
            requireUserPrivilegeLevel(4, msg.sender);
            uint256 etherAvailableAboveEscrow = (ETHERTOTALRECEIVED - ETHERESCROWED);
            uint256 etherAvailableAboveWithdrawn = (etherAvailableAboveEscrow - ETHERTOTALWITHDRAWN);
            if(address(this).balance > 0
            && ETHERTOTALRECEIVED > ETHERESCROWED
            && etherAvailableAboveEscrow  > ETHERTOTALWITHDRAWN
            && etherAvailableAboveWithdrawn > 0){
                (success, ) = msg.sender.call{value: amount}("");
                if (success != true){
                } else {
                   ETHERTOTALWITHDRAWN += amount;
                }
            } else {
                success = false;
            }
    }
    function depositONUS() public returns(bool success){
        if(GUsers[msg.sender].Set != true){
            setGuest();
        }
        uint256 allowed = wai.allowance(msg.sender, address(this));
        uint256 amount = wai.balanceOf(msg.sender);
        if(allowed >= amount && amount > 0){
            success = wai.transferFrom(msg.sender, address(this), amount);
            GUsers[msg.sender].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += amount;
        }
    }
    function depositShares() public returns(bool success){
        uint256 sharesDeposited;
        for(uint8 i; i <= 13; i++){
            (uint256 amount, ) = wai.agetShareHoldOf(msg.sender, i);
            if(amount > 0){    
                sharesDeposited += amount;
                wai.aSellFeeSharehold(address(this), amount, i);
                GUsers[msg.sender].FeeShareholdByEnvelope_[i] += amount;
            }
        }
        if(GUsers[msg.sender].Set != true){ 
            (,,, address Ceva , address FounderDeveloperTwo , address FounderDeveloperOne , uint8 UserPrivilegeLevel) = wai.agetUserCard(msg.sender);
            GUsers[msg.sender].Set = true;
            GUsers[msg.sender].Ceva = Ceva;
            GUsers[msg.sender].FounderDeveloperTwo = FounderDeveloperTwo;
            GUsers[msg.sender].FounderDeveloperOne = FounderDeveloperOne;
            GUsers[msg.sender].UserPrivilegeLevel = UserPrivilegeLevel;
        }
        if(sharesDeposited > 0){
            success = true;
        } else {
            success = false;
        }
    }
    /*=================================
    =        CEVA  functions         =
    =================================*/
    function setProperyValue(
        uint256 _propertyValue)
        public
        returns(bool success)
    {
        requireUserPrivilegeLevel(3, msg.sender);
        if(Properties[GUsers[msg.sender].workingPropertyid_].Set = true
        && _propertyValue >= 0
        && GUsers[msg.sender].workingPropertyid_ != 0x676c6f62616c0000000000000000000000000000000000000000000000000000){
            if(Properties[GUsers[msg.sender].workingPropertyid_].Owner != msg.sender){
                GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_] = Properties[GUsers[msg.sender].workingPropertyid_].Value;
                if(Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyPriceUpdateCountAsset_ == 0){
                    Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value = _propertyValue;
                } else if(Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ >= 1e18){
                    Properties[GUsers[msg.sender].workingPropertyid_].Value = _propertyValue;
                    Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ = (((( Properties[GUsers[msg.sender].workingPropertyid_].Value * 1e18) / 100) * 1000000) / ((((GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_] * 1e18) / 100) * 1000000) / Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_));
                    Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value = ((Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value + ((Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ * 100) / 1e18)) - ((Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_  * 100) / 1e18));
                }
                Properties[GUsers[msg.sender].workingPropertyid_].lastMintingPrice_ = _propertyValue;
                Properties[GUsers[msg.sender].workingPropertyid_].Value = _propertyValue;
                Properties[GUsers[msg.sender].workingPropertyid_].Value = ((Properties[GUsers[msg.sender].workingPropertyid_].Value + _propertyValue) - GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_]);
                Properties[GUsers[msg.sender].workingPropertyid_].propertyPriceUpdateCountAsset_++;
                Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyPriceUpdateCountAsset_++;
                if(Properties[GUsers[msg.sender].workingPropertyid_].propertyPriceUpdateCountAsset_ >= 1){
                    totalSupply = ((totalSupply + ((Properties[GUsers[msg.sender].workingPropertyid_].Value * 1e18) / 100)) - ((GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_] * 1e18) / 100));
                }
                emit PropertyValuation(msg.sender, GUsers[msg.sender].workingPropertyid_, Properties[GUsers[msg.sender].workingPropertyid_].Value);
                success = true;
            } else {
                success = false;
            }
        }
    }
    function setProperty(
        bool _Set,
        address _FounderDeveloper,
        address _Owner,
        address _holdOne,
        address _holdTwo,
        address _holdThree,
        uint256 _Value,
        uint256 _NumberOfTokensToEscrow,
        bytes32 _PropertyID
        ) public {
            requireUserPrivilegeLevel(3, msg.sender);
            AVEC.Property storage property = Properties[_PropertyID];
            property.Set = _Set;
            property.Ceva = msg.sender;
            property.FounderDeveloper = _FounderDeveloper;
            property.Owner = _Owner;
            property.holdOne = _holdOne;
            property.holdTwo = _holdTwo;
            property.holdThree = _holdThree;
            property.Value = _Value;
            property.NumberOfTokensToEscrow = _NumberOfTokensToEscrow;
            property.PropertyID = _PropertyID;
            GUsers[_FounderDeveloper].workingMintRequestid_ = _PropertyID;
            GUsers[_FounderDeveloper].workingPropertyid_ = _PropertyID;
            GUsers[_FounderDeveloper].workingBurnRequestid_ = _PropertyID;
            GUsers[_Owner].burnrequestwhitelist_[_PropertyID] = _Set;
            GUsers[msg.sender].workingPropertyid_ = _PropertyID;
            setProperyValue(_Value);
            emit PropertySet(_Set, _PropertyID, GUsers[_Owner].Ceva, _FounderDeveloper, _Owner, _Value);
    }
    function createEscrow(
        bytes32 _PropertyID, 
        address payable _recipientOfFunds, 
        bytes32 _recipientName, 
        uint8 _escrowAgreementNumber,
        bool _override,
        bool _escrowCompleted,
        uint256 _milestonePriceOfEscrowInETH, 
        uint256 _tokensAvailableTotal,
        uint256 _propertyIncrease
        )
        public {
            requireUserPrivilegeLevel(3, msg.sender);
            uint8 _localEscrowAgreementNumber;
            if(Properties[_PropertyID].firstEscrowSet != true){
                _localEscrowAgreementNumber = 0;
                Properties[_PropertyID].currentEscrowAgreementNumber = 0;
                Properties[_PropertyID].firstEscrowSet = true;
            } else {
                _localEscrowAgreementNumber = uint8(Properties[_PropertyID].currentEscrowAgreementNumber++); 
            }
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].PropertyID = _PropertyID;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].recipientOfFunds = _recipientOfFunds;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].recipientName = _recipientName;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].milestonePriceOfEscrowInETH = _milestonePriceOfEscrowInETH;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].tokensAvailableTotal = _tokensAvailableTotal;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].tokensAvailableCurrent = _tokensAvailableTotal;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].ethPerToken = (_milestonePriceOfEscrowInETH / _tokensAvailableTotal);
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].escrowCompleted = _escrowCompleted;
            GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].propertyIncrease = _propertyIncrease;
            ETHERESCROWED += GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].milestonePriceOfEscrowInETH;
            if(_override == true){
               GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].escrowAgreementNumber = _escrowAgreementNumber; 
            } else {
                GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].escrowAgreementNumber = _localEscrowAgreementNumber;
            }
            Properties[_PropertyID].escrowAgreementNumber.push(GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].escrowAgreementNumber);
            bytes32 prop = _PropertyID;
            emit EscrowCreated(msg.sender, _recipientOfFunds,  _recipientName, _milestonePriceOfEscrowInETH, _tokensAvailableTotal, prop, _localEscrowAgreementNumber);
    }
    function setWPID(
        bytes32 _PropertyID)
        public{
            requireUserPrivilegeLevel(3, msg.sender);
            GUsers[msg.sender].workingPropertyid_ = _PropertyID;
        }
    function burnProperty(
        uint256 _propertyValue, 
        address _clearFrom)
            public
            returns(bool success)
        {
            requireUserPrivilegeLevel(3, msg.sender);
            uint256 _amountOfTokens = ((_propertyValue * 1e18) / 100);
            uint256 _difference = (_amountOfTokens - GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_]);
            if(GUsers[msg.sender].workingPropertyid_ != 0x676c6f62616c0000000000000000000000000000000000000000000000000000
            && GUsers[_clearFrom].burnrequestwhitelist_[GUsers[msg.sender].transferingPropertyid_] == true
            && Properties[GUsers[msg.sender].workingPropertyid_].Set == true
            && _difference <= GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
            && _amountOfTokens >= 0){
                //Burn Tokens
                totalSupply -= _amountOfTokens;
                // take tokens out of stockpile
                //Exchange tokens
                Properties[GUsers[msg.sender].workingPropertyid_].Value = 0;
                Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value -= ((Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ * 100) / 1e18);
                GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] -= (_amountOfTokens - GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_]);
                GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_] = 0;
                // returns bool true
                emit Burn(msg.sender, _amountOfTokens, _propertyValue);
                success = true;
            } else {
                success = false;
            }
    }
    /*=================================
    =   FounderDev only function     =
    =================================*/
    function mintAVEC(
        uint256 _founderDeveloperFee)
            public
            returns(bool success)
        {
            address _toAddress = Properties[GUsers[msg.sender].workingPropertyid_].Owner;
            address _holdOne = Properties[GUsers[msg.sender].workingPropertyid_].holdOne;
            address _holdTwo = Properties[GUsers[msg.sender].workingPropertyid_].holdTwo;
            address _holdThree = Properties[GUsers[msg.sender].workingPropertyid_].holdThree;
            uint256 _propertyValue = Properties[GUsers[msg.sender].workingPropertyid_].Value;
            uint256 _numberOfSingleTokensToEscrow = Properties[GUsers[msg.sender].workingPropertyid_].NumberOfTokensToEscrow;
            address _commissionFounderDeveloper = GUsers[_toAddress].FounderDeveloperOne;
            bytes32 _propertyUniqueID = GUsers[msg.sender].workingPropertyid_;
            bytes32 _mintingRequestUniqueid = GUsers[msg.sender].workingMintRequestid_;
            uint256 _amountOfTokens
            = ((_propertyValue * 1e18) / 100);
            if(_propertyValue == Properties[_propertyUniqueID].Value 
            && GUsers[_toAddress].UserPrivilegeLevel >= 1
            && GUsers[msg.sender].UserPrivilegeLevel >= 2
            && _founderDeveloperFee >= 20001
            && _founderDeveloperFee <= 100000
            && msg.sender != _toAddress
            && _propertyUniqueID == GUsers[msg.sender].workingPropertyid_
            && _mintingRequestUniqueid == GUsers[msg.sender].workingMintRequestid_){
                updt(_amountOfTokens);
                GUsers[_commissionFounderDeveloper].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += ((_amountOfTokens * 1000) / _founderDeveloperFee);
                creditFeeSharehold(_amountOfTokens, _toAddress, _holdOne, _holdTwo, _holdThree);
                uint256 _techFee = ((_amountOfTokens * 100) / 25000);
                GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += _techFee;
                Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value += ((_amountOfTokens * 100000000000) / 1111234581620);
                uint256 _founderDeveloperFeeStacked = _founderDeveloperFee;
                uint256 _amountOfTokensStacked = _amountOfTokens;
                uint256 _escrowTokensStacked = _numberOfSingleTokensToEscrow *1e18;
                address _toAddressStacked = _toAddress;
                success = true;
                uint256 _whoaFees = ((_amountOfTokens * 100000000000000) / 2500000000000625);
                uint256 _fee = ((_amountOfTokens * (1000 * 100000)) / (_founderDeveloperFeeStacked * 100000));
                GUsers[_toAddressStacked].mintingDepositsOf_ += (((_amountOfTokensStacked - _whoaFees) - _fee) - _escrowTokensStacked);
                GUsers[_toAddressStacked].PropertyAvecBalance[_propertyUniqueID] += (((_amountOfTokensStacked - _whoaFees) - _fee) - _escrowTokensStacked);
                Properties[_propertyUniqueID].propertyGlobalBalance_ += (_whoaFees + _fee);
                GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += (_whoaFees - _techFee);
                updateValueI(_toAddressStacked, _propertyUniqueID);
                updateValueI(GUsers[_toAddressStacked].FounderDeveloperOne, _propertyUniqueID);
                updateValueI(GUsers[_toAddressStacked].FounderDeveloperTwo, _propertyUniqueID);
                GUsers[_toAddressStacked].Properties.push(_propertyUniqueID);
                emit AVECMinted(GUsers[_toAddressStacked].Ceva, _commissionFounderDeveloper,  _toAddressStacked, _amountOfTokens, _escrowTokensStacked);
            } else {
                success = false;
            }
    }
    /*=================================
    =   Member only function         =
    =================================*/
    /**
     * Convert AVEC into ONUS
     */
    function Convert(
        uint8 oneAVECtwoONUS, 
        uint256 tokens, 
        bytes32 _PropertyID)
        public
        returns(bool success)
    {
        if( oneAVECtwoONUS == 1){
            requireUserPrivilegeLevel(1, msg.sender);
            bytes32 _propertyUniqueID = _PropertyID;
            uint256 _propertyBalanceLedger = GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID];
            uint256 _Lvalue = tokens;
            updateValueI(msg.sender, _propertyUniqueID);
            if(_propertyBalanceLedger >= _Lvalue
            && GUsers[msg.sender].UserPrivilegeLevel == 1
            && tokens > 0){
                uint256 LcValue;
                LcValue = ((Properties[_propertyUniqueID].Value * 1e18) / 100);
                GUsers[msg.sender].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += tokens;
                GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID] -= tokens;
                Properties[_propertyUniqueID].propertyGlobalBalance_ += tokens;
                Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyLastKnownValue_[msg.sender] = Properties[_propertyUniqueID].Value;
                emit AVECtoONUS(msg.sender, _Lvalue, _PropertyID);
                success = true;
            } else {
                success = false;
            }
        } else if(oneAVECtwoONUS == 2){
            requireUserPrivilegeLevel(1, msg.sender);
            bytes32 _propertyUniqueID = _PropertyID;
            uint256 _propertyBalanceLedger = (((Properties[_propertyUniqueID].Value * 1e18) / 100) - Properties[_propertyUniqueID].propertyGlobalBalance_);
            uint256 _Lvalue = tokens;
            updateValueI(msg.sender, _propertyUniqueID);
            if(_propertyBalanceLedger >= _Lvalue
            && GUsers[msg.sender].UserPrivilegeLevel == 1
            && tokens > 0){
                //Exchange tokens
                GUsers[msg.sender].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] -= tokens;
                GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID] += tokens;
                Properties[_propertyUniqueID].propertyGlobalBalance_ -= tokens;
                Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyLastKnownValue_[msg.sender] = Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value;
                emit ONUStoAVEC(msg.sender, _Lvalue, _propertyUniqueID);
                success = true;
            } else {
                success = false;
            }
        }
    }
    function buyFD()
        public
        returns(bool success)
    {
        uint256 _licenseprice = (1000 * 1e18); 
        address _UserAddress = msg.sender;
        if(balanceOf(msg.sender) > _licenseprice){
        address _founderDeveloperOne = GUsers[msg.sender].FounderDeveloperOne;
        address _founderDeveloperTwo = GUsers[msg.sender].FounderDeveloperTwo;
        address _ceva = GUsers[msg.sender].Ceva;
        requireUserPrivilegeLevel(1, msg.sender);
            uint256 _commission = (_licenseprice / 5);
            GUsers[_ceva].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += _commission;
            GUsers[_founderDeveloperOne].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] +=  _commission;
            _commission = (_licenseprice / 10);
            GUsers[_founderDeveloperTwo].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] +=  _commission; 
            GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_] = (GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_] - _licenseprice);
            GUsers[_UserAddress].UserPrivilegeLevel = 2;
            emit LicensePurchase(msg.sender, _ceva, _founderDeveloperOne, _founderDeveloperTwo);
            success = true;
        } else {
            success = false;
        }
    }
    /**
     * withdraw an envelope hold shareholders specific envelope dividends based on the chosen number
     * 1 = Taxes Envelope
     * 2 = Insurance Envelope
     * 3 = Maintenance Envelope
     * 4 = Wealth Architect Equity Coin Operator Envelope
     * 5 = Hold One Envelope
     * 6 = Hold Two Envelope
     * 7 = Hold Three Envelope
     * 8 = Rewards Envelope(OMNI)
     * 9 = Tech Envelope
     * 10 = Exist Holdings Envelope
     * 11 = Exist Crypto Envelope
     * 12 = WHOA Envelope
     * 13 = Credible You Envelope
     */
    function withdrawDividends(
        uint8 _envelopeNumber)
            public
        {
            requireUserPrivilegeLevel(1, msg.sender);
            // setup data
            address _UserAddress = msg.sender;
            uint256 _dividends;
            if(_envelopeNumber > 0 
            && _envelopeNumber <= 13
            && _envelopeNumber != 8){
                _dividends = getUserDividends(msg.sender, _envelopeNumber);
                GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber] +=  _dividends;
            } else if(_envelopeNumber == 8){
                _dividends = getUserDividends(msg.sender, _envelopeNumber);
                GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber] +=  _dividends;
                GUsers[_UserAddress].PropertyAvecBalance[0x4f4d4e4900000000000000000000000000000000000000000000000000000000] +=  _dividends;
            }
            // update dividend tracker
            if(_envelopeNumber != 8){
                GUsers[_UserAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] +=  _dividends;
            }
            // fire event
            emit OnWithdraw(_UserAddress, _dividends, _envelopeNumber);
    }
    /*=================================
    = UserPrivilegeLevel/set function =
    =================================*/
    function setGuest() public returns(bool success){
        if(GUsers[msg.sender].UserPrivilegeLevel > 1 && GUsers[msg.sender].UserPrivilegeLevel < 4) {
            success = false;
        } else {
            AVEC.User storage LTwouser = GUsers[msg.sender];
            LTwouser.Set = true;
            LTwouser.UserAddress = msg.sender;
            LTwouser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
            emit UserSet(msg.sender);
            success = true;
        }
    }
    function setUser(
        address _modifyUser,
        address _FounderDeveloperOne,
        uint8 _UserPrivilegeLevel) public returns(bool success){
            AVEC.User storage Luser = GUsers[_modifyUser];
                if(_UserPrivilegeLevel <= GUsers[msg.sender].UserPrivilegeLevel
                    && GUsers[msg.sender].UserPrivilegeLevel == 4
                    && _FounderDeveloperOne != address(0x0)
                    && _modifyUser != address(0x0)
                    && _modifyUser != msg.sender){
                        success = true;
                        if(GUsers[_modifyUser].Set == true){
                            GUsers[_modifyUser].FounderDeveloperOne = _FounderDeveloperOne;
                            GUsers[_modifyUser].FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                            GUsers[_modifyUser].Ceva = GUsers[GUsers[_modifyUser].FounderDeveloperTwo].FounderDeveloperOne;
                            GUsers[_modifyUser].UserPrivilegeLevel = _UserPrivilegeLevel;
                            GUsers[_modifyUser].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                        } else {
                        Luser.UserAddress = _modifyUser;
                        Luser.Set = true;
                        Luser.FounderDeveloperOne = _FounderDeveloperOne;
                        Luser.FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                        Luser.Ceva = GUsers[Luser.FounderDeveloperTwo].FounderDeveloperOne;
                        Luser.UserPrivilegeLevel = _UserPrivilegeLevel;
                        Luser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                        }
                } else if(_UserPrivilegeLevel < GUsers[msg.sender].UserPrivilegeLevel
                    && GUsers[msg.sender].UserPrivilegeLevel <= 3
                    && GUsers[msg.sender].UserPrivilegeLevel >= 2
                    && _FounderDeveloperOne != address(0x0)
                    && _modifyUser != address(0x0)
                    && _modifyUser != msg.sender){
                        success = true;
                        if(GUsers[_modifyUser].Set == true){
                            GUsers[_modifyUser].FounderDeveloperOne = _FounderDeveloperOne;
                            GUsers[_modifyUser].FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                            GUsers[_modifyUser].Ceva = GUsers[GUsers[_modifyUser].FounderDeveloperTwo].FounderDeveloperOne;
                            GUsers[_modifyUser].UserPrivilegeLevel = _UserPrivilegeLevel;
                            GUsers[_modifyUser].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                        } else {
                        Luser.UserAddress = _modifyUser;
                        Luser.Set = true;
                        Luser.FounderDeveloperOne = _FounderDeveloperOne;
                        Luser.FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                        Luser.Ceva = GUsers[Luser.FounderDeveloperTwo].FounderDeveloperOne;
                        Luser.UserPrivilegeLevel = _UserPrivilegeLevel;
                        Luser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                        }
                } else {
                    success = false;
                }
            emit UserSet(_modifyUser);
    }
    function requireUserPrivilegeLevel(uint8 _UserPrivilegeLevel, address _UserAddress)
        view
        internal
        returns(bool success)
    {
        if(_UserPrivilegeLevel <= GUsers[_UserAddress].UserPrivilegeLevel){
            success = false;
        } else {
            success = false;
        }
    }
    /*=================================
    =       public view function      =
    =================================*/
    function getProp(
        bytes32 _PropertyID) 
        view
        public
        returns (
        address _Owner,
        uint256 _Value,
        uint256 _NumberOfTokensToEscrow,
        uint256 _propertyPriceUpdateCountAsset_,
        uint256 _propertyGlobalBalance_,
        uint256 _escrowAgreementNumber,
        uint8 _currentEscrowAgreementNumber,
        bool _firstEscrowSet) {
            _Owner = Properties[_PropertyID].Owner;
            _Value = Properties[_PropertyID].Value;
            _NumberOfTokensToEscrow = Properties[_PropertyID].NumberOfTokensToEscrow;
            _propertyPriceUpdateCountAsset_ = Properties[_PropertyID].propertyPriceUpdateCountAsset_;
            _propertyGlobalBalance_ = Properties[_PropertyID].propertyGlobalBalance_;
            _escrowAgreementNumber = uint256(Properties[_PropertyID].escrowAgreementNumber.length);
            _currentEscrowAgreementNumber = Properties[_PropertyID].currentEscrowAgreementNumber;
            _firstEscrowSet = Properties[_PropertyID].firstEscrowSet;
    }
    function getUser(
        address _UserAddress) 
        view 
        public 
        returns (
            bool success,
            bool set,
            address userAddress, 
            address fdOne, 
            address fdTwo, 
            address ceva, 
            uint8 privilegeLevel) {
                address _UserAddressStacked = _UserAddress;
                if(GUsers[_UserAddressStacked].Set == true){
                    success = true;
                    set = GUsers[_UserAddressStacked].Set;
                    userAddress = GUsers[_UserAddressStacked].UserAddress;
                    fdOne = GUsers[_UserAddressStacked].Ceva;
                    fdTwo = GUsers[_UserAddressStacked].FounderDeveloperTwo;
                    ceva = GUsers[_UserAddressStacked].FounderDeveloperOne;
                    privilegeLevel = GUsers[_UserAddressStacked].UserPrivilegeLevel;
                } else {
                    success = false;
                }
    }
    function getUserProperty(
        address _UserAddress) 
        view 
        public 
        returns (
            bool success,
            bytes32 _workingPropertyid, 
            bytes32 _transferingPropertyid, 
            uint256 _PropertyAvecBalanc, 
            uint256 _mintingDepositsOf,
            uint256 _amountCirculated, 
            bool _burnrequestwhitelist, 
            uint256 _propertyvalueOld, 
            uint8 _transferType) {
                address _UserAddressStacked = _UserAddress;
                if(GUsers[_UserAddressStacked].Set == true){
                    success = true;
                    _workingPropertyid = GUsers[_UserAddressStacked].workingPropertyid_;
                    _transferingPropertyid = GUsers[_UserAddressStacked].transferingPropertyid_;
                    _PropertyAvecBalanc = GUsers[_UserAddressStacked].PropertyAvecBalance[GUsers[_UserAddressStacked].transferingPropertyid_];
                    _mintingDepositsOf = GUsers[_UserAddressStacked].mintingDepositsOf_;
                    _amountCirculated = GUsers[_UserAddressStacked].amountCirculated_;
                    _burnrequestwhitelist = GUsers[_UserAddressStacked].burnrequestwhitelist_[GUsers[_UserAddressStacked].transferingPropertyid_];
                    _propertyvalueOld = GUsers[_UserAddressStacked].propertyvalueOld_[GUsers[_UserAddressStacked].transferingPropertyid_];
                    _transferType = GUsers[_UserAddressStacked].transferType_;
                } else {
                    success = false;
                }
    }
    function getUserAvecBalance(
        address UserAddress, 
        bytes32 _PropertyID) 
        view
        public
        returns (
            bool success,
            address _UserAddress,
            uint256 _PropertyAvecBalance) {
          success = true;
          _UserAddress = GUsers[UserAddress].UserAddress;
          _PropertyAvecBalance = GUsers[UserAddress].PropertyAvecBalance[_PropertyID];
    }
    function getUserDividends(
        address _UserAddress, 
        uint8 _envelopeNumber)
        view
        public
        returns(uint256 dividends)
    {
      if(GUsers[_UserAddress].amountCirculated_ >= 1 && GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber] >= 1){ 
          dividends = ((((((LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14] / 2) / 8) / LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1]) * GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]) - (GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber] + GUsers[_UserAddress].FeesPreviousWithdrawnByEnvelope_[_envelopeNumber])) / ((GUsers[_UserAddress].mintingDepositsOf_ + 1) / (GUsers[_UserAddress].amountCirculated_ + 1)));
      } else {
          dividends = 0;
      }
    }
    function getUserShareHold(
        address _UserAddress, 
        uint8 _envelopeNumber)
        view
        public
        returns(uint256 sharehold, bool success)
    {
        if(_envelopeNumber >= 1
        && _envelopeNumber <= 13){
            sharehold = GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]; 
            success = true;
        } else {
            sharehold = 0; 
            success = false;
        }
    }
    function getEscrow(
        bytes32 _PropertyId) 
        view
        public
        returns (
            address _recipientOfFunds,
            bytes32 _recipientName,
            uint8 _escrowAgreementNumber,
            uint256 _milestonePriceOfEscrowInETH,
            uint256 _tokensAvailableTotal,
            uint256 _tokensAvailableCurrent,
            uint256 _ethPerToken,
            uint256 _propertyIncrease,
            uint256 _AgreementAmountDueInTokens) {
                _recipientOfFunds = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].recipientOfFunds;
                _recipientName = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].recipientName;
                _escrowAgreementNumber = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].escrowAgreementNumber;
                _milestonePriceOfEscrowInETH = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH;
                _tokensAvailableTotal = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].tokensAvailableTotal;
                _tokensAvailableCurrent = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].tokensAvailableCurrent;
                _ethPerToken = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].ethPerToken;
                _propertyIncrease = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].propertyIncrease;
                _AgreementAmountDueInTokens = GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].AgreementAmountDueInTokens[msg.sender];
    }
    function getBalance() 
        public 
        view 
        returns (uint balance) {
            balance = address(this).balance;
        }
    /*==============================
    =        public function       =
    ==============================*/
    constructor()
    {
    }
    function setAdmin()
        public
        returns(bool success)
    {
        if(adminset_ == false){
            GUsers[msg.sender].Set = true;
            GUsers[msg.sender].UserAddress = msg.sender;
            GUsers[msg.sender].UserPrivilegeLevel = 4;
            GUsers[msg.sender].FounderDeveloperOne = msg.sender;
            GUsers[msg.sender].FounderDeveloperTwo = msg.sender;
            GUsers[msg.sender].Ceva = msg.sender;
            adminset_ = true; 
            success = true;
        } else { success = false; }
    }
    function sellSharehold(
        address _toAddress, 
        uint256 _amount, 
        uint8 _envelopeNumber)
        public
        returns(bool success)
    {
        requireUserPrivilegeLevel(0, msg.sender);
        requireUserPrivilegeLevel(0, _toAddress);
        if(_amount > 0
        && _envelopeNumber == 1){
        // setup
            address _UserAddress = msg.sender;
            if(_amount <= GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]
            && _amount >= 0
            && _toAddress != _UserAddress){
                GUsers[_toAddress].FeesPreviousWithdrawnByEnvelope_[_envelopeNumber] += ((GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber] / GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]) * _amount);
                GUsers[_toAddress].FeeShareholdByEnvelope_[_envelopeNumber] += _amount;
                GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber] -= _amount;
            }
        } else {
            success = false;
        }
          GUsers[_toAddress].mintingDepositsOf_ += (_amount * 1e18);
          GUsers[_toAddress].amountCirculated_ += (_amount * 1e18);
          
          emit FeeShareholdSOLD(msg.sender, _toAddress, _amount);
          success = true;
    }
    function updateValue(
        address _holderAddress, 
        bytes32 _propertyUniqueId)
        public
        returns(bool success)
    {
        requireUserPrivilegeLevel(0, msg.sender);
        if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ != GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
        && GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId] > 0
        && Properties[_propertyUniqueId].Set == true
        && Properties[_propertyUniqueId].Value > 0){
            updateValueI(_holderAddress,_propertyUniqueId);
            success = true;
        } else {
            success = false;
        }
    }
    /**
     * Select a specific property unique id to swap its AVEC when calling the transfer function.
     * 0x676c6f62616c0000000000000000000000000000000000000000000000000000
     * ONUS ^
     * 0x4f4d4e4900000000000000000000000000000000000000000000000000000000
     * OMNI ^
     */
    function setToken(
        bytes32 _propertyUniqueID, 
        uint8 _tokenType)
            public
            returns(bytes32 _tranferingPropertyID, uint8 tokenType)
        {
            if(_tokenType <= 3 
            && _tokenType >= 1
            && GUsers[msg.sender].UserPrivilegeLevel >= 1){
                updateValueI(msg.sender, _propertyUniqueID);
              if(_tokenType == 1){
                  GUsers[msg.sender].transferingPropertyid_ = _propertyUniqueID;
                  GUsers[msg.sender].transferType_ = 1;
              } else if(_tokenType == 2){
                  GUsers[msg.sender].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                  GUsers[msg.sender].transferType_ = 2;
              } else if(_tokenType == 3){
                  GUsers[msg.sender].transferingPropertyid_ = 0x4f4d4e4900000000000000000000000000000000000000000000000000000000;
                  GUsers[msg.sender].transferType_ = 3;
              }
              _tranferingPropertyID = GUsers[msg.sender].transferingPropertyid_;
              tokenType = _tokenType;
            }
    }
    function withdrawEscrow(
        bytes32 _PropertyID) 
        public{
            uint256 tokens = GEscrowAgreements[_PropertyID][GUsers[msg.sender].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[msg.sender];
            address _userAddress = msg.sender;
            if(GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress] >= 1e18 
            && GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].escrowCompleted == true
            && GUsers[msg.sender].UserPrivilegeLevel >= 0){
                if(GUsers[_userAddress].UserPrivilegeLevel == 0){
                    GUsers[_userAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                    Properties[_PropertyID].propertyGlobalBalance_ += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                    GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress] -= GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                    emit AVECWithdrawnFromEscrow(msg.sender, tokens, _PropertyID);
                } else if(GUsers[_userAddress].UserPrivilegeLevel >= 1)
                    GUsers[_userAddress].PropertyAvecBalance[_PropertyID] += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                    GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress] -= GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                    emit AVECWithdrawnFromEscrow(msg.sender, tokens, _PropertyID);
            } else {
            }
            updateValueI(msg.sender, _PropertyID);
    }
    /*==============================
    =        payable function     =
    ==============================*/
    function contributeEscrow(
        bytes32 _PropertyID)
        public
        payable
        returns(bytes memory tf){
            if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == true){
                revert();
            } else {
            address _userAddress = msg.sender;
            uint256 _value;
            uint256 _amountOfAVEC = (msg.value / GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken);
            bytes32 stacked = _PropertyID;      
            if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == false
                && GUsers[msg.sender].UserPrivilegeLevel >= 0
                && GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived 
                >= GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH){
                    GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent = 0;
                    (, tf) = GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].recipientOfFunds.call
                    {value: GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH}("");
                    GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted = true;
            if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].propertyIncrease > 0 
                && GUsers[msg.sender].UserPrivilegeLevel >= 3 
                && GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == true
                ){
                    bytes32 wpIDTemp = GUsers[msg.sender].workingPropertyid_;
                    GUsers[msg.sender].workingPropertyid_ = _PropertyID;
                    setProperyValue((Properties[stacked].Value + GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].propertyIncrease));
                    GUsers[msg.sender].workingPropertyid_ = wpIDTemp;
                    GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].propertyIncrease = 0;
            }
                emit ContributionMade(_userAddress, msg.value, stacked, Properties[stacked].currentEscrowAgreementNumber, GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].escrowCompleted);
            } else {
            if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent <= _amountOfAVEC){
                _value = (GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH - 
                GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived);
                _amountOfAVEC = GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent;
                if(msg.value > (_value + GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken) || 
                msg.value < GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken){
                    revert();
                }   
            }
            GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent -= _amountOfAVEC;
            _value = (GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken * _amountOfAVEC);
            withdrawEscrow(_PropertyID);
            GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID] = Properties[_PropertyID].currentEscrowAgreementNumber;
            address(this).call{value: _value};
            updateValueI(msg.sender, _PropertyID);
            GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived += _value;
            ETHERTOTALRECEIVED += _value;
            amountDueInTokens[_userAddress] += (_amountOfAVEC * 1e18);
            GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].AgreementAmountDueInTokens[_userAddress] = (_amountOfAVEC * 1e18);
            emit ContributionMade(_userAddress, _value, stacked, Properties[stacked].currentEscrowAgreementNumber, GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].escrowCompleted);
            }
            }
        }
    /*==============================
    =        internal function     =
    ==============================*/
    function updateValueI(
        address _holderAddress, 
        bytes32 _propertyUniqueId)
        internal
    {
        uint256 _propertyBalanceLedger = GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId];
        //if holding burned value
        if(_propertyBalanceLedger >= 1 
        && Properties[_propertyUniqueId].Value == 0 
        && _propertyUniqueId != 0x676c6f62616c0000000000000000000000000000000000000000000000000000){
           GUsers[_holderAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] = GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]; 
           GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId] -= GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId];
           emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
        } else {
        if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ > GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
        && GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] == 0) {
            Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress] = Properties[_propertyUniqueId].Value;
            GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] = Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_;
            emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
        } else if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ > GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]){
            uint256 _divideby = ((((Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress] * 1e18) / 100) * 1000000) / _propertyBalanceLedger);
            uint256 _propertyValue = (((Properties[_propertyUniqueId].Value * 1e18) / 100) * 1000000);
            uint256 _LCalculate = (_propertyValue / _divideby);
            GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId] = _LCalculate;
            GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] = Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_;
            Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress] = Properties[_propertyUniqueId].Value;
            emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
        }}
    }
    function updt(uint256 _amountOfTokens)
            internal
            returns(bool success)
        {
            uint48 _tokenCount = uint48((_amountOfTokens / 1e18));
            totalSupply += _amountOfTokens;
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[2] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[2]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[3] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[3]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[4] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[4]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[5] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[5]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[6] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[6]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[7] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[7]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[8] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[8]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[9] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[9]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[10] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[10]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[11] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[11]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[12] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[12]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[13] = uint48(_tokenCount + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[13]);
            LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[15] = uint48((_tokenCount * 13) + LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[15]);
            success = true;
    }
    function updateEquityRents(uint256 _amountOfTokens)
            internal
            returns(bool success)
        {
            if(_amountOfTokens > 0){
                LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14] = uint48(LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14] + _amountOfTokens / 50);
                success = true;
            } else {
                success = false;
            }
    }
    function creditFeeSharehold(uint256 _amountOfTokens, address _UserAddress, address _toAddress, address _toAddresstwo, address _toAddressthree)
            internal
            returns(bool success)
        {
            _amountOfTokens /= 1e18;
            GUsers[_UserAddress].FeeShareholdByEnvelope_[1] += _amountOfTokens;
            GUsers[_UserAddress].FeeShareholdByEnvelope_[2] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].whoamaintenanceaddress].FeeShareholdByEnvelope_[3] += _amountOfTokens;
            GUsers[_UserAddress].FeeShareholdByEnvelope_[4] += _amountOfTokens;
            GUsers[_toAddress].FeeShareholdByEnvelope_[5] += _amountOfTokens;
            GUsers[_toAddresstwo].FeeShareholdByEnvelope_[6] += _amountOfTokens;
            GUsers[_toAddressthree].FeeShareholdByEnvelope_[7] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].whoarewardsaddress].FeeShareholdByEnvelope_[8] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].FeeShareholdByEnvelope_[9] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].existholdingsaddress].FeeShareholdByEnvelope_[10] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].existcryptoaddress].FeeShareholdByEnvelope_[11] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].FeeShareholdByEnvelope_[12] += _amountOfTokens;
            GUsers[GFeeWallets[GfeeWalletSecretID_].credibleyouaddress].FeeShareholdByEnvelope_[13] += _amountOfTokens;
            success = true;
        }
}