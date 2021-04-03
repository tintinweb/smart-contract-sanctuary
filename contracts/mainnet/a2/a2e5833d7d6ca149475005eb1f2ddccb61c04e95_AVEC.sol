/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity^0.6.0;
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
      string public name = "TheWealthArchitect";
      string public symbol = "AVEC";
      uint8 public decimals = 18;
      uint256 public totalSupply;
      function allowance(address tokenOwner, address spender)
          public
          view returns (uint remaining) {
              return GUsers[tokenOwner]._allowed[spender];
      }
      function balanceOf(address _UserAddress)
          view
          public
          returns(uint256)
      {
          return GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_];
      }
      function transfer(
          address _toAddress, 
          uint256 _amountOfTokens)
          public
          returns(bool)
      {
          if(GUsers[msg.sender].Set != true){
                  asetMyUser();
          }
          if(GUsers[msg.sender].transferType_ == 1){
                  requireUserPrivilegeLevel(1, msg.sender);
                  requireUserPrivilegeLevel(1, _toAddress);
          } else {
          uint256 _fee = divi(_amountOfTokens, 50);
          uint256 _compare = addi(_amountOfTokens, _fee);
          if(_compare < GUsers[msg.sender].PropertyAvecBalance[GUsers[msg.sender].transferingPropertyid_]
          && GUsers[_toAddress].UserPrivilegeLevel >= 0){
              updateRollingPropertyValueMember(msg.sender, GUsers[msg.sender].transferingPropertyid_);
              updateRollingPropertyValueMember(_toAddress, GUsers[msg.sender].transferingPropertyid_);
              GUsers[msg.sender].PropertyAvecBalance[GUsers[msg.sender].transferingPropertyid_]
              -= _compare;
               GUsers[msg.sender].amountCirculated_
              += _compare;
              GUsers[msg.sender].TokenBalanceLedgersTotal
              -= _compare;
              GUsers[_toAddress].TokenBalanceLedgersTotal
              += _amountOfTokens;
              GUsers[_toAddress].PropertyAvecBalance[GUsers[msg.sender].transferingPropertyid_]
              += _amountOfTokens;
              updateEquityRents(_amountOfTokens);
              GUsers[msg.sender].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
              emit Transfer(msg.sender, _toAddress, _compare);
              return true;
          } else {
              revert();
          }
      }  } 
      function transferFrom(
          address from, 
          address to, 
          uint256 tokens)
          public
          returns(bool)
      {
          if(GUsers[msg.sender].Set != true){
                  asetMyUser();
              }
          if(GUsers[msg.sender].transferType_ == 1){
                  requireUserPrivilegeLevel(1, msg.sender);
                  requireUserPrivilegeLevel(1, to);
          }
          bytes32 _propertyUniqueID
          = GUsers[from].transferingPropertyid_;
          uint256 _propertyBalanceLedger
          = GUsers[from].PropertyAvecBalance[_propertyUniqueID];
          uint256 _Lvalue
          = addi(tokens, divi(tokens, 50));
          if(_propertyBalanceLedger >= _Lvalue
          && GUsers[to].UserPrivilegeLevel >= 0
          && tokens > 0
          &&from != to
          && _Lvalue <= GUsers[from]._allowed[msg.sender]
          && msg.sender != from){
              updateRollingPropertyValueMember(from, _propertyUniqueID);
              updateRollingPropertyValueMember(to, _propertyUniqueID);
              // setup
              updateEquityRents(tokens);
              GUsers[to].TokenBalanceLedgersTotal
              += tokens;
              GUsers[from].TokenBalanceLedgersTotal
              -= _Lvalue;
              //Reduce Approval Amount
              GUsers[from]._allowed[msg.sender]
              -= tokens;
              GUsers[from].amountCirculated_
              += _Lvalue;
              GUsers[from].PropertyAvecBalance[_propertyUniqueID]
              -= _Lvalue;
              GUsers[to].PropertyAvecBalance[_propertyUniqueID]
              += tokens;
              GUsers[msg.sender].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
              emit Transfer(from, to, _Lvalue);
              return true;
          } else {
              revert();
          }
      }
      function approve(
          address spender, 
          uint256 value)
          public
          returns (bool) {
              requireUserPrivilegeLevel(0, msg.sender);
              if(spender != address(0)){
                  GUsers[msg.sender]._allowed[spender]
                  = value;
                  emit Approval(msg.sender, spender, value);
                  return true;
              } else {
                  revert();
              }
      }
      /*=================================
      =            Structs            =
      =================================*/
      
      struct PropertyEscrow {
          bytes32 PropertyID;
          address payable recipientOfFunds;
          bytes32 recipientName;
          uint8 escrowAgreementNumber;
          bool escrowCompleted;
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
          bytes32  feeWalletSecretID;
          address  whoaaddress;
          address  whoamaintenanceaddress;
          address  whoarewardsaddress;
          address  cevaaddress;
          address  credibleyouaddress;
          address  techaddress;
          address  existholdingsaddress;
          address  existcryptoaddress;
      }
      struct Property {
          bool Set;
          address Ceva;
          address FounderDeveloper;
          address Owner;
          address holdOne;
          address holdTwo;
          address holdThree;
          uint256 Value;
          uint256 NumberOfTokensToEscrow;
          bytes32 PropertyID;
          uint256 propertyGlobalBalance_;
          uint256 propertyPriceUpdateCountAsset_;
          uint256 lastMintingPrice_;
          mapping(address => uint256) propertyLastKnownValue_;
          uint8[] escrowAgreementNumber;
          uint8 currentEscrowAgreementNumber;
          bool firstEscrowSet;
      }
      struct User {
          bool Set;
          address UserAddress;
          address Ceva;
          address FounderDeveloperTwo;
          address FounderDeveloperOne;
          uint8 UserPrivilegeLevel;
          bytes32 workingPropertyid_;
          bytes32 transferingPropertyid_;
          bytes32 workingMintRequestid_;
          bytes32 workingBurnRequestid_;
          bool approvedByCevaForFD_;
          uint256 TokenBalanceLedgersTotal;
          bytes32[] Properties;
          mapping(bytes32 => uint256) PropertyAvecBalance;
          mapping(address => mapping(bytes32 => uint256)) propertyPriceUpdateCountMember_;
          uint256 mintingDepositsOf_;
          uint256 amountCirculated_;
          mapping(address => uint256) _allowed;
          mapping(bytes32 => bool) burnrequestwhitelist_;
          mapping(bytes32 => uint256) propertyvalueOld_;
          mapping(uint8 => uint256) FeesTotalWithdrawnByEnvelope_;
          mapping(uint8 => uint256) FeesPreviousWithdrawnByEnvelope_;
          mapping(uint8 => uint256) FeeShareholdByEnvelope_;
          mapping(bytes32 => uint8) lastknownPropertyEscrowAgreementNumber;
          uint8 transferType_;
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
      mapping(address => TotalHolds) private LatestTotalHolds;
      mapping(bytes32 => FeeWallet) private GFeeWallets;
      mapping(bytes32 => Property) Properties;
      mapping(address => User) GUsers;
      mapping(address => uint256) amountDueInTokens;
      mapping(bytes32 => mapping(uint8 => PropertyEscrow)) private GEscrowAgreements;
      /*=================================
      =            bytes32              =
      =================================*/
      bytes32 private GfeeWalletSecretID_;
      bytes32[] private GListFeeWalletSecretIDs;
      bytes32[] propertyIDs;
      /*=================================
      =            address              =
      =================================*/
      address[] userAccounts;
     /*================================
      =            uint               =
      ================================*/
      uint256 ETHERTOTALRECEIVED;
      uint256 ETHERESCROWED;
      uint256 ETHERTOTALWITHDRAWN;
      /*================================
      =            bool               =
      ================================*/
      bool internal adminset_ = false;
       /*=================================
      =          pure function          =
      =================================*/
      function agetbytes32ToString(bytes32 _bytes32)
          public
          pure
          returns (string memory) {
              uint8 i = 0;
              while(i < 32 && _bytes32[i] != 0) {
                  i++;
              }
              bytes memory bytesArray = new bytes(i);
              for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
                  bytesArray[i] = _bytes32[i];
              }
              return string(bytesArray);
      }
      function agetstringToBytes32(string memory source)
          pure
          public
          returns (bytes32 result) {
          bytes memory tempEmptyStringTest = bytes(source);
          if (tempEmptyStringTest.length == 0) {
              return 0x0;
          }
          assembly {
              result := mload(add(source, 32))
          }
      }
      function mult(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
      }
      function divi(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
      }
      function subt(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
      function addi(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
      }
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
          address _existcryptoaddress) public {
              requireUserPrivilegeLevel(4, msg.sender);
              AVEC.FeeWallet storage feeWallet = GFeeWallets[_LfeeWalletSecretID];
                  if(_whoaaddress == address(0x0)  || _whoamaintenanceaddress == address(0x0) || _whoarewardsaddress == address(0x0) || _cevaaddress == address(0x0) 
                  || _credibleyouaddress == address(0x0) || _techaddress == address(0x0) || _existholdingsaddress == address(0x0) || _existcryptoaddress == address(0x0)) {
                      revert();
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
                      Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Owner 
                      = _whoaaddress;
                  }
      }
      function agetFeeWallet(bytes32 _LfeeWalletSecretID) view public returns (
          bytes32,
          address,
          address,
          address,
          address,
          address,
          address,
          address,
          address) {
              requireUserPrivilegeLevel(4, msg.sender);
              bytes32 thefeeWalletSecretID = _LfeeWalletSecretID;
              return (
                  GFeeWallets[thefeeWalletSecretID].feeWalletSecretID,
                  GFeeWallets[thefeeWalletSecretID].whoaaddress,
                  GFeeWallets[thefeeWalletSecretID].whoamaintenanceaddress,
                  GFeeWallets[thefeeWalletSecretID].whoarewardsaddress,
                  GFeeWallets[thefeeWalletSecretID].cevaaddress,
                  GFeeWallets[thefeeWalletSecretID].credibleyouaddress,
                  GFeeWallets[thefeeWalletSecretID].techaddress,
                  GFeeWallets[thefeeWalletSecretID].existholdingsaddress,
                  GFeeWallets[thefeeWalletSecretID].existcryptoaddress
              );
      }
      function withdrawEther(uint256 amount)
          public
          returns(bytes memory){
              requireUserPrivilegeLevel(4, msg.sender);
              uint256 etherAvailableAboveEscrow = subt(ETHERTOTALRECEIVED, ETHERESCROWED);
              uint256 etherAvailableAboveWithdrawn = subt(etherAvailableAboveEscrow, ETHERTOTALWITHDRAWN);
              if(address(this).balance > 0
              && ETHERTOTALRECEIVED > ETHERESCROWED
              && etherAvailableAboveEscrow  > ETHERTOTALWITHDRAWN
              && etherAvailableAboveWithdrawn > 0){
                   (bool success, bytes memory tf) = msg.sender.call{value: amount}("");
                   if (success != true){
                      revert();
                   }
                   ETHERTOTALWITHDRAWN += amount;
                   return (tf);
              } else {
                  revert();
              }
      }
      /*=================================
      =        CEVA  functions         =
      =================================*/
      function approveMemberForFD(bool _approve, address _UserAddress)
          public{
          requireUserPrivilegeLevel(3, msg.sender);
          GUsers[_UserAddress].approvedByCevaForFD_ = _approve;
      }
      function adjustPropertyValue(
          uint256 _propertyValue)
          public
          returns(uint256, uint8)
      {
          requireUserPrivilegeLevel(3, msg.sender);
          if(Properties[GUsers[msg.sender].workingPropertyid_].Set = true
          && _propertyValue >= 0
          && GUsers[msg.sender].workingPropertyid_ != 0x676c6f62616c0000000000000000000000000000000000000000000000000000){
              if(Properties[GUsers[msg.sender].workingPropertyid_].Owner != msg.sender){
                  GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_]
                  = Properties[GUsers[msg.sender].workingPropertyid_].Value;
                  if(Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyPriceUpdateCountAsset_ == 0){
                      Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value
                      = _propertyValue;
                  } else if(Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ >= 1e18){
                      Properties[GUsers[msg.sender].workingPropertyid_].Value
                      = _propertyValue;
                      uint256 _LCalculate
                      = divi(mult(divi(mult(GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_], 1e18), 100), 1000000), Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_);
                      uint256 _SecondCalculate
                      = divi(mult(divi(mult( Properties[GUsers[msg.sender].workingPropertyid_].Value, 1e18), 100), 1000000), _LCalculate);
                      uint256 _propertyGlobalBalanceOld
                      = Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_ ;
                      Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_
                      = _SecondCalculate;
                      Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value
                      = subt(addi(Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value, divi(mult(Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_, 100), 1e18))
                      , divi(mult(_propertyGlobalBalanceOld, 100), 1e18));
                  }
                  Properties[GUsers[msg.sender].workingPropertyid_].lastMintingPrice_
                  = _propertyValue;
                  Properties[GUsers[msg.sender].workingPropertyid_].Value
                  = _propertyValue;
                  uint256 _pValue
                  = Properties[GUsers[msg.sender].workingPropertyid_].Value;
                  uint256 _pValueOld
                  = GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_];
                  Properties[GUsers[msg.sender].workingPropertyid_].Value
                  = subt(addi(_pValue, _propertyValue), _pValueOld);
                  Properties[GUsers[msg.sender].workingPropertyid_].propertyPriceUpdateCountAsset_
                  += 1;
                  Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyPriceUpdateCountAsset_
                  += 1;
                  if(Properties[GUsers[msg.sender].workingPropertyid_].propertyPriceUpdateCountAsset_ >= 1){
                      totalSupply
                      = subt(addi(totalSupply, divi(mult(Properties[GUsers[msg.sender].workingPropertyid_].Value, 1e18), 100)), divi(mult(GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].propertyvalueOld_[GUsers[msg.sender].workingPropertyid_], 1e18), 100));
                  }
                  emit PropertyValuation(msg.sender, GUsers[msg.sender].workingPropertyid_, Properties[GUsers[msg.sender].workingPropertyid_].Value);
              } else {
                  revert();
              }
          }
      }
      function asetProperty(
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
              if(Properties[_PropertyID].Set == true){
                  Properties[_PropertyID].Set = _Set;
                  Properties[_PropertyID].Ceva = msg.sender;
                  Properties[_PropertyID].FounderDeveloper = _FounderDeveloper;
                  Properties[_PropertyID].Owner = _Owner;
                  Properties[_PropertyID].holdOne = _holdOne;
                  Properties[_PropertyID].holdTwo = _holdTwo;
                  Properties[_PropertyID].holdThree = _holdThree;
                  Properties[_PropertyID].Value = _Value;
                  Properties[_PropertyID].NumberOfTokensToEscrow = _NumberOfTokensToEscrow;
              } else {
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
              GUsers[_FounderDeveloper].workingMintRequestid_
              = _PropertyID;
              GUsers[_FounderDeveloper].workingPropertyid_
              = _PropertyID;
              GUsers[_FounderDeveloper].workingBurnRequestid_ = _PropertyID;
              GUsers[_Owner].burnrequestwhitelist_[_PropertyID]
              = _Set;
              propertyIDs.push(_PropertyID);
              bytes32 wpIDTemp = GUsers[msg.sender].workingPropertyid_;
              GUsers[msg.sender].workingPropertyid_ = _PropertyID;
              adjustPropertyValue(_Value);
              GUsers[msg.sender].workingPropertyid_ = wpIDTemp;
              emit PropertySet(_Set, _PropertyID, GUsers[_Owner].Ceva, _FounderDeveloper, _Owner, _Value);
          }
      }
      function createEscrowForProperty(
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
                  _localEscrowAgreementNumber = uint8(Properties[_PropertyID].currentEscrowAgreementNumber + 1); 
              }
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].PropertyID = _PropertyID;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].recipientOfFunds = _recipientOfFunds;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].recipientName = _recipientName;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].milestonePriceOfEscrowInETH = _milestonePriceOfEscrowInETH;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].tokensAvailableTotal = _tokensAvailableTotal;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].tokensAvailableCurrent = _tokensAvailableTotal;
              GEscrowAgreements[_PropertyID][_localEscrowAgreementNumber].ethPerToken = divi(_milestonePriceOfEscrowInETH, _tokensAvailableTotal);
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
      function aCEVASetWorkingPropertyID(
          bytes32 _PropertyID)
          public{
              requireUserPrivilegeLevel(3, msg.sender);
              GUsers[msg.sender].workingPropertyid_ = _PropertyID;
          }
      function aBurnProperty(
          uint256 _propertyValue, 
          address _clearFrom)
              public
              returns(bool)
          {
              requireUserPrivilegeLevel(3, msg.sender);
              uint256 _amountOfTokens = divi(mult(_propertyValue, 1e18), 100);
              uint256 _difference = subt(_amountOfTokens, GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_]);
              if(GUsers[msg.sender].workingPropertyid_ != 0x676c6f62616c0000000000000000000000000000000000000000000000000000
              && GUsers[_clearFrom].burnrequestwhitelist_[GUsers[msg.sender].transferingPropertyid_] == true
              && Properties[GUsers[msg.sender].workingPropertyid_].Set == true
              && _difference <= GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
              && _amountOfTokens >= 0){
                  //Burn Tokens
                  totalSupply
                  -= _amountOfTokens;
                  // take tokens out of stockpile
                  //Exchange tokens
                  Properties[GUsers[msg.sender].workingPropertyid_].Value
                  = 0;
                  Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value
                  -= divi(mult(Properties[GUsers[msg.sender].workingPropertyid_].propertyGlobalBalance_, 100), 1e18);
                  GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].TokenBalanceLedgersTotal
                  -= GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_];
                  GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  -= subt(_amountOfTokens, GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_]);
                  GUsers[Properties[GUsers[msg.sender].workingPropertyid_].Owner].PropertyAvecBalance[GUsers[msg.sender].workingPropertyid_]
                  = 0;
                  // returns bool true
                  emit Burn(msg.sender, _amountOfTokens, _propertyValue);
                  return true;
              } else {
                  revert();
              }
      }
      /*=================================
      =   FounderDev only function     =
      =================================*/
      function afounderDeveloperMintAVEC(
          uint256 _founderDeveloperFee)
              public
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
              = divi(mult(_propertyValue, 1e18), 100);
              if(_propertyValue == Properties[_propertyUniqueID].Value 
              && GUsers[_toAddress].UserPrivilegeLevel >= 1
              && GUsers[msg.sender].UserPrivilegeLevel >= 2
              && _founderDeveloperFee >= 20001
              && _founderDeveloperFee <= 100000
              && msg.sender != _toAddress
              && _propertyUniqueID == GUsers[msg.sender].workingPropertyid_
              && _mintingRequestUniqueid == GUsers[msg.sender].workingMintRequestid_){
                  updateHoldsandSupply(_amountOfTokens);
                  GUsers[_commissionFounderDeveloper].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  += divi(mult(_amountOfTokens, 1000), _founderDeveloperFee);
                  GUsers[_commissionFounderDeveloper].TokenBalanceLedgersTotal
                  = addi(GUsers[_commissionFounderDeveloper].TokenBalanceLedgersTotal, divi(mult(_amountOfTokens, 1000), _founderDeveloperFee));
                  creditFeeSharehold(_amountOfTokens, _toAddress, _holdOne, _holdTwo, _holdThree);
                  uint256 _techFee
                  = divi(mult(_amountOfTokens, 100), 25000);
                  GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  += _techFee;
                  Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value
                  += divi(mult(_amountOfTokens, 100000000000), 1111234581620);
                  GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].TokenBalanceLedgersTotal
                  = addi(GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].TokenBalanceLedgersTotal, _techFee);
                  uint256 _founderDeveloperFeeStacked = _founderDeveloperFee;
                  uint256 _amountOfTokensStacked = _amountOfTokens;
                  uint256 _escrowTokensStacked = _numberOfSingleTokensToEscrow *1e18;
                  address _toAddressStacked = _toAddress;
                  uint256 _whoaFees
                  = divi(mult(_amountOfTokens, 100000000000000), 2500000000000625);
                  uint256 _fee
                  = divi(mult(_amountOfTokens, mult(1000, 100000)), mult(_founderDeveloperFeeStacked, 100000));
                  GUsers[_toAddressStacked].TokenBalanceLedgersTotal
                  = addi(GUsers[_toAddressStacked].TokenBalanceLedgersTotal, subt(subt(subt(_amountOfTokensStacked, _whoaFees), _fee), _escrowTokensStacked));
                  GUsers[_toAddressStacked].mintingDepositsOf_
                  += subt(subt(subt(_amountOfTokensStacked, _whoaFees), _fee), _escrowTokensStacked);
                  GUsers[_toAddressStacked].PropertyAvecBalance[_propertyUniqueID]
                  += subt(subt(subt(_amountOfTokensStacked, _whoaFees), _fee), _escrowTokensStacked);
                  Properties[_propertyUniqueID].propertyGlobalBalance_
                  += addi(_whoaFees, _fee);
                  GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  += subt(_whoaFees, _techFee);
                  GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].TokenBalanceLedgersTotal
                  += subt(_whoaFees, _techFee);
                  updateRollingPropertyValueMember(_toAddressStacked, _propertyUniqueID);
                  updateRollingPropertyValueMember(GUsers[_toAddressStacked].FounderDeveloperOne, _propertyUniqueID);
                  updateRollingPropertyValueMember(GUsers[_toAddressStacked].FounderDeveloperTwo, _propertyUniqueID);
                  GUsers[_toAddressStacked].Properties.push(_propertyUniqueID);
                  emit AVECMinted(GUsers[_toAddressStacked].Ceva, _commissionFounderDeveloper,  _toAddressStacked, _amountOfTokens, _escrowTokensStacked);
              } else {
                  revert();
              }
      }
      /*=================================
      =   Member only function         =
      =================================*/
      /**
       * Convert AVEC into ONUS
       */
      function amemberConvert(
          uint8 oneAVECtwoONUS, 
          uint256 tokens, 
          bytes32 _PropertyID)
          public
      {
          if( oneAVECtwoONUS == 1){
              requireUserPrivilegeLevel(1, msg.sender);
              bytes32 _propertyUniqueID
              = _PropertyID;
              uint256 _propertyBalanceLedger
              = GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID];
              uint256 _Lvalue
              = tokens;
              updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
              if(_propertyBalanceLedger >= _Lvalue
              && GUsers[msg.sender].UserPrivilegeLevel == 1
              && tokens > 0){
                  uint256 LcValue;
                  LcValue = divi(mult(Properties[_propertyUniqueID].Value, 1e18), 100);
                  GUsers[msg.sender].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  += tokens;
                  GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID]
                  -= tokens;
                  Properties[_propertyUniqueID].propertyGlobalBalance_
                  += tokens;
                  Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyLastKnownValue_[msg.sender]
                  = Properties[_propertyUniqueID].Value;
                  emit AVECtoONUS(msg.sender, _Lvalue, _PropertyID);
              } else {
                  revert();
              }
          } else if(oneAVECtwoONUS == 2){
              requireUserPrivilegeLevel(1, msg.sender);
              bytes32 _propertyUniqueID
              = _PropertyID;
              uint256 _propertyBalanceLedger
              = subt(divi(mult(Properties[_propertyUniqueID].Value, 1e18), 100), Properties[_propertyUniqueID].propertyGlobalBalance_);
              uint256 _Lvalue
              = tokens;
              updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
              if(_propertyBalanceLedger >= _Lvalue
              && GUsers[msg.sender].UserPrivilegeLevel == 1
              && tokens > 0){
                  //Exchange tokens
                  GUsers[msg.sender].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  -= tokens;
                  GUsers[msg.sender].PropertyAvecBalance[_propertyUniqueID]
                  += tokens;
                  Properties[_propertyUniqueID].propertyGlobalBalance_
                  -= tokens;
                  Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].propertyLastKnownValue_[msg.sender]
                  = Properties[0x676c6f62616c0000000000000000000000000000000000000000000000000000].Value;
                  emit ONUStoAVEC(msg.sender, _Lvalue, _propertyUniqueID);
              } else {
                  revert();
              }
          }
      }
      function amemberBuyFounderDeveloperLicense()
          public
          returns(bool)
      {
          address _founderDeveloperOne = GUsers[msg.sender].FounderDeveloperOne;
          address _founderDeveloperTwo = GUsers[msg.sender].FounderDeveloperTwo;
          address _ceva = GUsers[msg.sender].Ceva;
          requireUserPrivilegeLevel(1, msg.sender);
          uint256 _licenseprice
          = mult(1000, 1e18); 
          address _UserAddress
          = msg.sender;
          if(GUsers[_UserAddress].TokenBalanceLedgersTotal > _licenseprice && GUsers[_UserAddress].approvedByCevaForFD_ == true){
              uint256 _commission = divi(_licenseprice, 5);
              GUsers[_ceva].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
              += _commission;
              GUsers[_UserAddress].TokenBalanceLedgersTotal 
              += _commission;
              GUsers[_founderDeveloperOne].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
              +=  _commission;
              GUsers[_founderDeveloperOne].TokenBalanceLedgersTotal
              += _commission;
              _commission = divi(_licenseprice, 10);
              GUsers[_founderDeveloperTwo].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
              +=  _commission; 
              GUsers[_founderDeveloperTwo].TokenBalanceLedgersTotal 
              += _commission;
              GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_]
              = subt(GUsers[_UserAddress].PropertyAvecBalance[GUsers[_UserAddress].transferingPropertyid_], _licenseprice);
              GUsers[_UserAddress].TokenBalanceLedgersTotal
              = subt(GUsers[_UserAddress].TokenBalanceLedgersTotal, _licenseprice);
              GUsers[_UserAddress].UserPrivilegeLevel 
              = 2;
              emit LicensePurchase(msg.sender, _ceva, _founderDeveloperOne, _founderDeveloperTwo);
              return true;
          } else {
              revert();
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
      function amemberWithdrawDividends(
          uint8 _envelopeNumber)
              public
          {
              requireUserPrivilegeLevel(1, msg.sender);
              // setup data
              address _UserAddress
              = msg.sender;
              uint256 _dividends;
              if(_envelopeNumber > 0 
              && _envelopeNumber < 13
              && _envelopeNumber != 8){
                  _dividends
                  = agetDividendsOf(msg.sender, _envelopeNumber);
                  GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber]
                  +=  _dividends;
              } else if(_envelopeNumber == 8){
                  _dividends
                  = agetDividendsOf(msg.sender, _envelopeNumber);
                  GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber]
                  +=  _dividends;
                  GUsers[_UserAddress].PropertyAvecBalance[0x4f4d4e4900000000000000000000000000000000000000000000000000000000]
                  +=  _dividends;
                  GUsers[_UserAddress].TokenBalanceLedgersTotal 
                  = GUsers[_UserAddress].TokenBalanceLedgersTotal +_dividends;
              }
              // update dividend tracker
              if(_envelopeNumber != 8){
                  GUsers[_UserAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                  +=  _dividends;
              }
              GUsers[_UserAddress].TokenBalanceLedgersTotal
              += _dividends;
              // fire event
              emit OnWithdraw(_UserAddress, _dividends, _envelopeNumber);
      }
      /*=================================
      = UserPrivilegeLevel/set function =
      =================================*/
      function asetMyUser() public{
              if(GUsers[msg.sender].Set != true) {
                  AVEC.User storage LTwouser = GUsers[msg.sender];
                      LTwouser.UserAddress = msg.sender;
                      LTwouser.UserPrivilegeLevel = 0;
                      LTwouser.Set = true;
                      LTwouser.Ceva = address(0x0);
                      LTwouser.FounderDeveloperOne = address(0x0);
                      LTwouser.FounderDeveloperTwo = address(0x0);
                      LTwouser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                      userAccounts.push(msg.sender);
                      emit UserSet(msg.sender);
              } else {
                  revert();
              }
      }
      function asetUser(
          address _UserAddress,
          address _Ceva,
          address _FounderDeveloperOne,
          uint8 _UserPrivilegeLevel) public {
              AVEC.User storage Luser = GUsers[_UserAddress];
              if(GUsers[_UserAddress].Set != true){
                  if(_UserPrivilegeLevel <= GUsers[msg.sender].UserPrivilegeLevel
                      && GUsers[msg.sender].UserPrivilegeLevel >= 4
                      && _FounderDeveloperOne != address(0x0)
                      && _Ceva != address(0x0)
                      && _UserAddress != address(0x0)
                      && _UserAddress != msg.sender
                      && _UserPrivilegeLevel < 5){
                          if(GUsers[_UserAddress].Set == true){
                              GUsers[_UserAddress].Ceva = _Ceva;
                              GUsers[_UserAddress].FounderDeveloperOne = _FounderDeveloperOne;
                              GUsers[_UserAddress].FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                              GUsers[_UserAddress].UserPrivilegeLevel = _UserPrivilegeLevel;
                              GUsers[_UserAddress].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                          } else {
                          Luser.UserAddress = _UserAddress;
                          Luser.Set = true;
                          Luser.Ceva = _Ceva;
                          Luser.FounderDeveloperOne = _FounderDeveloperOne;
                          Luser.FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                          Luser.UserPrivilegeLevel = _UserPrivilegeLevel;
                          Luser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                          userAccounts.push(msg.sender);
                          }
                  } else if(GUsers[msg.sender].UserPrivilegeLevel >= subt(_UserPrivilegeLevel, 1)
                      && _UserPrivilegeLevel <= 3
                      && _UserPrivilegeLevel >= 2
                      && _FounderDeveloperOne != address(0x0)
                      && _Ceva != address(0x0)
                      && _UserAddress != address(0x0)
                      && _UserAddress != msg.sender){
                          if(GUsers[_UserAddress].Set == true){
                              GUsers[_UserAddress].Ceva = _Ceva;
                              GUsers[_UserAddress].FounderDeveloperOne = _FounderDeveloperOne;
                              GUsers[_UserAddress].FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                              GUsers[_UserAddress].UserPrivilegeLevel = _UserPrivilegeLevel;
                              GUsers[_UserAddress].transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                          } else {
                          Luser.UserAddress = _UserAddress;
                          Luser.Set = true;
                          Luser.Ceva = _Ceva;
                          Luser.FounderDeveloperOne = _FounderDeveloperOne;
                          Luser.FounderDeveloperTwo = GUsers[_FounderDeveloperOne].FounderDeveloperOne;
                          Luser.UserPrivilegeLevel = _UserPrivilegeLevel;
                          Luser.transferingPropertyid_ = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                          userAccounts.push(msg.sender);
                          }
                  } 
              }
              emit UserSet(_UserAddress);
      }
      function requireUserPrivilegeLevel(uint8 _UserPrivilegeLevel, address _UserAddress)
          view
          internal
      {
          if(_UserPrivilegeLevel <= GUsers[_UserAddress].UserPrivilegeLevel){
          } else {
              revert();
          }
      }
      /*=================================
      =       public view function      =
      =================================*/
      function agetProperty(
          bytes32 _PropertyID) 
          view
          public
          returns (
          bool,
          address,
          address,
          address,
          uint256,
          uint256,
          bytes32,
          uint256,
          uint256,
          uint256,
          uint256,
          uint8,
          bool) {
              bytes32 _PropertyIDStacked = _PropertyID;
              return (
                  Properties[_PropertyIDStacked].Set,
                  Properties[_PropertyIDStacked].Ceva,
                  Properties[_PropertyIDStacked].FounderDeveloper,
                  Properties[_PropertyIDStacked].Owner,
                  Properties[_PropertyIDStacked].Value,
                  Properties[_PropertyIDStacked].NumberOfTokensToEscrow,
                  Properties[_PropertyIDStacked].PropertyID,
                  Properties[_PropertyIDStacked].propertyPriceUpdateCountAsset_,
                  Properties[_PropertyIDStacked].propertyGlobalBalance_,
                  Properties[_PropertyIDStacked].lastMintingPrice_,
                  uint256(Properties[_PropertyIDStacked].escrowAgreementNumber.length),
                  Properties[_PropertyIDStacked].currentEscrowAgreementNumber,
                  Properties[_PropertyIDStacked].firstEscrowSet
              );
      }
      function agetPropertiesCount() 
          view
          public
          returns (uint) {
        return propertyIDs.length;
      }
      function agetUserCard(
          address _UserAddress) 
          view 
          public 
          returns (
              bool, 
              bool, 
              address, 
              address, 
              address, 
              address, 
              uint8) {
                  address _UserAddressStacked = _UserAddress;
                  if(GUsers[_UserAddressStacked].Set == true){
                      return(
                          GUsers[_UserAddressStacked].Set,
                          GUsers[_UserAddressStacked].approvedByCevaForFD_,
                          GUsers[_UserAddressStacked].UserAddress,
                          GUsers[_UserAddressStacked].Ceva,
                          GUsers[_UserAddressStacked].FounderDeveloperTwo,
                          GUsers[_UserAddressStacked].FounderDeveloperOne,
                          GUsers[_UserAddressStacked].UserPrivilegeLevel
                          );
                  } else {
                      revert();
                  }
      }
      function agetUserPropertyCard(
          address _UserAddress) 
          view 
          public 
          returns (
              bytes32, 
              bytes32, 
              uint256, 
              uint256, 
              uint256,
              uint256, 
              uint256, 
              bool, 
              uint256, 
              uint8, 
              uint8) {
                  address _UserAddressStacked = _UserAddress;
                  if(GUsers[_UserAddressStacked].Set == true){
                      return(
                          GUsers[_UserAddressStacked].workingPropertyid_,
                          GUsers[_UserAddressStacked].transferingPropertyid_,
                          GUsers[_UserAddressStacked].TokenBalanceLedgersTotal,
                          GUsers[_UserAddressStacked].PropertyAvecBalance[GUsers[_UserAddressStacked].transferingPropertyid_],
                          GUsers[_UserAddressStacked].propertyPriceUpdateCountMember_[msg.sender][GUsers[_UserAddressStacked].transferingPropertyid_],
                          GUsers[_UserAddressStacked].mintingDepositsOf_,
                          GUsers[_UserAddressStacked].amountCirculated_,
                          GUsers[_UserAddressStacked].burnrequestwhitelist_[GUsers[_UserAddressStacked].transferingPropertyid_],
                          GUsers[_UserAddressStacked].propertyvalueOld_[GUsers[_UserAddressStacked].transferingPropertyid_],
                          GUsers[_UserAddressStacked].lastknownPropertyEscrowAgreementNumber[GUsers[_UserAddressStacked].transferingPropertyid_],
                          GUsers[_UserAddressStacked].transferType_);
                  } else {
                      revert();
                  }
      }
      function agetUserPropertyAvecBalance(
          address _InsUserAddress, 
          bytes32 _PropertyID) 
          view
          public
          returns (
          address,
          uint256,
          uint256) {
              address _UserAddress = _InsUserAddress;
        return (
            GUsers[_UserAddress].UserAddress,
            GUsers[_UserAddress].TokenBalanceLedgersTotal,
            GUsers[_UserAddress].PropertyAvecBalance[_PropertyID]);
      }
      function agetUserCount() 
          view
          public
          returns (uint) {
        return userAccounts.length;
      }
      function agetUserPropertiesCount(
          address _UserAddress) 
          view
          public
          returns (uint) {
        return GUsers[_UserAddress].Properties.length;
      }
      function agetDividendsOf(
          address _UserAddress, 
          uint8 _envelopeNumber)
          view
          public
          returns(uint256)
      {
        if(GUsers[_UserAddress].amountCirculated_ >= 1){
          if(GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber] >= 1){
              uint256 _dividendPershare
              = divi(divi(divi(LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14], 2) , 8), LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1]);
              uint256 _taxesSharehold
              = GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber];
              uint256 _LCalculate
              = divi(subt(mult(_dividendPershare, _taxesSharehold),
              addi(GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber], GUsers[_UserAddress].FeesPreviousWithdrawnByEnvelope_[_envelopeNumber])),
              divi(addi(GUsers[_UserAddress].mintingDepositsOf_, 1), addi(GUsers[_UserAddress].amountCirculated_, 1)));
              return  _LCalculate;
          } else {
              return 0;
          }
        } else {
            return 0;
        }
      }
      function agetShareHoldOf(
          address _UserAddress, 
          uint8 _envelopeNumber)
          view
          public
          returns(uint256, uint8)
      {
          if(_envelopeNumber >= 1
          && _envelopeNumber <= 13){
              return (GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber], 1);
          } else {
              return (0, 0);
          }
      }
      function agetEscrow(
          bytes32 _PropertyID) 
          view
          public
          returns (
          bytes32,
          address,
          bytes32,
          uint8,
          bool,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256) {
              bytes32 _PropertyId = _PropertyID;
              return (
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].PropertyID,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].recipientOfFunds,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].recipientName,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].escrowAgreementNumber,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].escrowCompleted,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].tokensAvailableTotal,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].tokensAvailableCurrent,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].totalETHReceived,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].ethPerToken,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].propertyIncrease,
                  GEscrowAgreements[_PropertyId][Properties[_PropertyId].currentEscrowAgreementNumber].AgreementAmountDueInTokens[msg.sender]
              );
      }
      function getBalance() 
          public 
          view 
          returns (uint) {
              return address(this).balance;
          }
      /*==============================
      =        public function       =
      ==============================*/
      constructor()
          public
      {
      }
      function adminInitialSet()
          public
      {
          if(adminset_ 
          == false){
              GUsers[msg.sender].Set = true;
              GUsers[msg.sender].UserAddress = msg.sender;
              GUsers[msg.sender].UserPrivilegeLevel = 4;
              GUsers[msg.sender].FounderDeveloperOne = msg.sender;
              GUsers[msg.sender].FounderDeveloperTwo = msg.sender;
              GUsers[msg.sender].Ceva = msg.sender;
              adminset_
              = true;
              emit UserSet(msg.sender);
          } else {
              revert();
          }
      }
      function aSellFeeSharehold(
          address _toAddress, 
          uint256 _amount, 
          uint8 _envelopeNumber)
          public
          returns(bool)
      {
          requireUserPrivilegeLevel(0, msg.sender);
          requireUserPrivilegeLevel(0, _toAddress);
          if(_amount > 0
          && _envelopeNumber == 1){
          // setup
              address _UserAddress
              = msg.sender;
              if(_amount <= GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]
              && _amount >= 0
              && _toAddress != _UserAddress){
                  GUsers[_toAddress].FeesPreviousWithdrawnByEnvelope_[_envelopeNumber]
                  += mult(divi(GUsers[_UserAddress].FeesTotalWithdrawnByEnvelope_[_envelopeNumber], GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]), _amount);
                  GUsers[_toAddress].FeeShareholdByEnvelope_[_envelopeNumber]
                  += _amount;
                  GUsers[_UserAddress].FeeShareholdByEnvelope_[_envelopeNumber]
                  -= _amount;
              }
          } else {
              revert();
          }
            GUsers[_toAddress].mintingDepositsOf_ += mult(_amount, 1e18);
            GUsers[_toAddress].amountCirculated_ += mult(_amount, 1e18);
            
            emit FeeShareholdSOLD(msg.sender, _toAddress, _amount);
            return true;
      }
      function amemberUpdateRollingPropertyValue(
          address _holderAddress, 
          bytes32 _propertyUniqueId)
          public
          returns(uint8)
      {
          requireUserPrivilegeLevel(0, msg.sender);
          if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ != GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
          && GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId] > 0
          && Properties[_propertyUniqueId].Set == true
          && Properties[_propertyUniqueId].Value > 0){
              updateRollingPropertyValueMember(_holderAddress,_propertyUniqueId);
              return 1;
          } else {
              return 2;
          }
      }
      /**
       * Select a specific property unique id to swap its AVEC when calling the transfer function.
       * 0x676c6f62616c0000000000000000000000000000000000000000000000000000
       * ONUS ^
       * 0x4f4d4e4900000000000000000000000000000000000000000000000000000000
       * OMNI ^
       */
      function aaswapType(
          bytes32 _propertyUniqueID, 
          uint8 _tokenType)
              public
              returns(bytes32, uint8)
          {
              if(_tokenType <= 3 
              && _tokenType >= 1
              && GUsers[msg.sender].UserPrivilegeLevel >= 1){
                  updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
                if(_tokenType == 1){
                    updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
                    GUsers[msg.sender].transferingPropertyid_
                    = _propertyUniqueID;
                    GUsers[msg.sender].transferType_
                    = 1;
                } else if(_tokenType == 2){
                    updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
                    GUsers[msg.sender].transferingPropertyid_
                    = 0x676c6f62616c0000000000000000000000000000000000000000000000000000;
                    GUsers[msg.sender].transferType_
                    = 2;
                } else if(_tokenType == 3){
                    updateRollingPropertyValueMember(msg.sender, _propertyUniqueID);
                    GUsers[msg.sender].transferingPropertyid_
                    = 0x4f4d4e4900000000000000000000000000000000000000000000000000000000;
                    GUsers[msg.sender].transferType_
                    = 3;
                }
                return (GUsers[msg.sender].transferingPropertyid_, _tokenType);
              }
      }
      function withdrawAVECFromEscrow(
          bytes32 _PropertyID) 
          public{
              uint256 tokens = GEscrowAgreements[_PropertyID][GUsers[msg.sender].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[msg.sender];
              address _userAddress = msg.sender;
              if(GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress] >= 1e18 
              && GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].escrowCompleted == true
              && GUsers[msg.sender].UserPrivilegeLevel >= 0){
                  if(GUsers[_userAddress].UserPrivilegeLevel == 0){
                      GUsers[_userAddress].TokenBalanceLedgersTotal 
                      += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      GUsers[_userAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000]
                      += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      Properties[_PropertyID].propertyGlobalBalance_
                      += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress]
                      -= GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      emit AVECWithdrawnFromEscrow(msg.sender, tokens, _PropertyID);
                  } else if(GUsers[_userAddress].UserPrivilegeLevel >= 1)
                      GUsers[_userAddress].TokenBalanceLedgersTotal
                      += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      GUsers[_userAddress].PropertyAvecBalance[_PropertyID]
                      += GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress]
                      -= GEscrowAgreements[_PropertyID][GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID]].AgreementAmountDueInTokens[_userAddress];
                      emit AVECWithdrawnFromEscrow(msg.sender, tokens, _PropertyID);
              } else {
              }
              updateRollingPropertyValueMember(msg.sender, _PropertyID);
      }
      /*==============================
      =        payable function     =
      ==============================*/
      function contributeToEscrowForProperty(
          bytes32 _PropertyID)
          public
          payable
          returns(bytes memory){
              if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == true){
                  revert();
              } else {
              if(GUsers[msg.sender].Set != true){
                  asetMyUser();
              }
              address _userAddress = msg.sender;
              uint256 _value;
              uint256 _amountOfAVEC = divi(msg.value, GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken);
              bytes32 stacked = _PropertyID;      
              if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == false
                  && GUsers[msg.sender].UserPrivilegeLevel >= 0
                  && GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived 
                  >= GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH){
                      GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent = 0;
                      (bool success, bytes memory tf) = GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].recipientOfFunds.call
                      {value: GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH}("");
                      GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted = success;
              if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].propertyIncrease > 0 
                  && GUsers[msg.sender].UserPrivilegeLevel >= 3 
                  && GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].escrowCompleted == true
                  ){
                      bytes32 wpIDTemp = GUsers[msg.sender].workingPropertyid_;
                      GUsers[msg.sender].workingPropertyid_ = _PropertyID;
                      adjustPropertyValue(addi(Properties[stacked].Value, GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].propertyIncrease));
                      GUsers[msg.sender].workingPropertyid_ = wpIDTemp;
                      GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].propertyIncrease = 0;
                  }
                  emit ContributionMade(_userAddress, msg.value, stacked, Properties[stacked].currentEscrowAgreementNumber, GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].escrowCompleted);
                  return tf;
              } else {
              if(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent <= _amountOfAVEC){
                  _value = subt(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].milestonePriceOfEscrowInETH, 
                  GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived);
                  _amountOfAVEC = GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent;
                  if(msg.value > addi(_value, GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken) || 
                  msg.value < GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken){
                      revert();
                  }}
              
              GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].tokensAvailableCurrent -= _amountOfAVEC;
              _value = mult(GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].ethPerToken, _amountOfAVEC);
              withdrawAVECFromEscrow(_PropertyID);
              GUsers[_userAddress].lastknownPropertyEscrowAgreementNumber[_PropertyID] = Properties[_PropertyID].currentEscrowAgreementNumber;
              address(this).call{value: _value};
              updateRollingPropertyValueMember(msg.sender, _PropertyID);
              GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].totalETHReceived += _value;
              ETHERTOTALRECEIVED += _value;
              amountDueInTokens[_userAddress] += mult(_amountOfAVEC, 1e18);
              GEscrowAgreements[_PropertyID][Properties[_PropertyID].currentEscrowAgreementNumber].AgreementAmountDueInTokens[_userAddress] = mult(_amountOfAVEC, 1e18);
              emit ContributionMade(_userAddress, _value, stacked, Properties[stacked].currentEscrowAgreementNumber, GEscrowAgreements[stacked][Properties[stacked].currentEscrowAgreementNumber].escrowCompleted);
              
         
          }
              }
              }
          
          
              
          
          
      /*==============================
      =        internal function     =
      ==============================*/
      function updateRollingPropertyValueMember(
          address _holderAddress, 
          bytes32 _propertyUniqueId)
          internal
          returns (uint8)
      {
          uint256 _propertyBalanceLedger
          = GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId];
          //if holding burned value
          if(_propertyBalanceLedger >= 1 && Properties[_propertyUniqueId].Value == 0 && _propertyUniqueId != 0x676c6f62616c0000000000000000000000000000000000000000000000000000){
             GUsers[_holderAddress].PropertyAvecBalance[0x676c6f62616c0000000000000000000000000000000000000000000000000000] = GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]; 
             GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId] -= GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId];
             emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
          } else {
          if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ > GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
          && GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId] == 0) {
              Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress]
              = Properties[_propertyUniqueId].Value;
              GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
              = Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_;
              emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
          } else if(Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_ > GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]){
              uint256 _divideby
              = divi(mult(divi(mult(Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress], 1e18), 100), 1000000), _propertyBalanceLedger);
              uint256 _propertyValue
              = mult(divi(mult(Properties[_propertyUniqueId].Value, 1e18), 100), 1000000);
              uint256 _LCalculate
              = divi(_propertyValue, _divideby);
              GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]
              = _LCalculate;
              GUsers[_holderAddress].TokenBalanceLedgersTotal
              = subt(addi(GUsers[_holderAddress].TokenBalanceLedgersTotal, _LCalculate), _propertyBalanceLedger);
              GUsers[_holderAddress].propertyPriceUpdateCountMember_[_holderAddress][_propertyUniqueId]
              = Properties[_propertyUniqueId].propertyPriceUpdateCountAsset_;
              Properties[_propertyUniqueId].propertyLastKnownValue_[_holderAddress]
              = Properties[_propertyUniqueId].Value;
              emit ValueUpdate(_holderAddress, _propertyUniqueId, _propertyBalanceLedger, GUsers[_holderAddress].PropertyAvecBalance[_propertyUniqueId]);
          }}
      }
      function updateHoldsandSupply(uint256 _amountOfTokens)
              internal
              returns(bool)
          {
              uint48 _tokenCount = uint48(divi(_amountOfTokens, 1e18));
              totalSupply
              += _amountOfTokens;
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[1]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[2]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[2]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[3]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[3]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[4]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[4]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[5]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[5]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[6]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[6]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[7]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[7]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[8]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[8]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[9]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[9]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[10]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[10]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[11]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[11]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[12]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[12]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[13]
              = uint48(addi(_tokenCount, LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[13]));
              LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[15]
              = uint48(addi(mult(_tokenCount, 13), LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[15]));
              return true;
      }
      function updateEquityRents(uint256 _amountOfTokens)
              internal
              returns(bool)
          {
              if(_amountOfTokens > 0){
                  LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14]
                  = uint48(addi(LatestTotalHolds[address(this)].feeHoldsTotalByEnvelope[14], divi(_amountOfTokens, 50)));
              } else {
                  revert();
              }
      }
      function creditFeeSharehold(uint256 _amountOfTokens, address _UserAddress, address _toAddress, address _toAddresstwo, address _toAddressthree)
              internal
              returns(bool)
          {
              GUsers[_UserAddress].FeeShareholdByEnvelope_[1]
              += divi(_amountOfTokens, 1e18);
              GUsers[_UserAddress].FeeShareholdByEnvelope_[2]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].whoamaintenanceaddress].FeeShareholdByEnvelope_[3]
              += divi(_amountOfTokens, 1e18);
              GUsers[_UserAddress].FeeShareholdByEnvelope_[4]          
              += divi(_amountOfTokens, 1e18);
              GUsers[_toAddress].FeeShareholdByEnvelope_[5]
              += divi(_amountOfTokens, 1e18);
              GUsers[_toAddresstwo].FeeShareholdByEnvelope_[6]
              += divi(_amountOfTokens, 1e18);
              GUsers[_toAddressthree].FeeShareholdByEnvelope_[7]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].whoarewardsaddress].FeeShareholdByEnvelope_[8]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].techaddress].FeeShareholdByEnvelope_[9]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].existholdingsaddress].FeeShareholdByEnvelope_[10]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].existcryptoaddress].FeeShareholdByEnvelope_[11]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].whoaaddress].FeeShareholdByEnvelope_[12]
              += divi(_amountOfTokens, 1e18);
              GUsers[GFeeWallets[GfeeWalletSecretID_].credibleyouaddress].FeeShareholdByEnvelope_[13]
              += divi(_amountOfTokens, 1e18);
              return true;
          }
      }