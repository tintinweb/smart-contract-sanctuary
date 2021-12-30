// Submitted for verification at BscScan.com on 2021-10-01

/*
The Artzeex Ecosystem is a project focused on revolutionizing the art world by adding value to the world of NFT's 
and the metaverse. For more information visit the link bellow:
https://artzeex.com/

200,000,000 Total Supply

Name: Artzeex
Symbol: ZEEX
Decimals: 6
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20Token.sol";
import "./Migration.sol";

contract Zeex is BEP20Token, Migration {

  struct Wallet {
    address holders;
    address operation;
    address growth;
    address fundation;

    address stake;
    address publicOffer;
    address employees;
    address founders;
    address influencers;
    address privateOffer;
    address airDrop;
    address initialPublicOffer;
    address presale;
    address seed;
    address launchPad;
  }
  Wallet internal _wallet; 

  // 0 - 100000  /  0% - 100%  - ex 4075 = 4,075%    
  struct MintSplit {
    uint32 holders;
    uint32 operation;
    uint32 growth;
    uint32 fundation;

    uint32 stake;
    uint32 publicOffer;
    uint32 employees;
    uint32 founders;
    uint32 influencers;
    uint32 privateOffer;
    uint32 airDrop;
    uint32 initialPublicOffer;
    uint32 presale;
    uint32 seed;
    uint32 launchPad;
  }
  MintSplit internal _mintSplit; 


  // 0 - 100  / 0% - 100%
  struct FeeSplit {
    uint8 holders;
    uint8 operation;
    uint8 growth;
    uint8 fundation; 
  }
  FeeSplit internal _feeSplit;

  struct Lock {
    uint256[] amount;
    uint256[] end;
  }

  mapping (address => Lock) internal _locks;
  mapping (address => bool) internal _noFee;
  mapping (address => uint8) internal _customFee;

  uint8 internal _standartFee = 2;

  uint256 constant _maxSupply = 200000000 * 10 ** 6; // iquedev
  uint256 constant _maxBurn   = 100000000 * 10 ** 6; // iquedev

  uint256 _alreadyMinted = 0; //iquedev

  event setLockEvent(address indexed wallet, uint256 amount, uint256 end);
  
  constructor() {
    _name = "Artzeex Faucet V2.2";
    _symbol = "fZEEX2_2";
    _decimals = 6;
    _totalSupply = 1100000 * 10 ** 6;
    _alreadyMinted = _totalSupply;
    _balances[msg.sender] = _totalSupply;

    _wallet.holders            = 0xD73818D26d12dDa5eB449F419bF565700e0B5e01;
    _wallet.operation          = 0xeDF88fE0E01526adb75F6f0A54888ddDb9C3Ad9c;
    _wallet.growth             = 0x72D226c98538815b5Eaf14B79D98F12C5051AF5d;
    _wallet.fundation          = 0x0d4a003C1f98E736814a96b76804c74311994b08;   

    _wallet.stake              = 0x4ea5fff2718C9E9fFD1Da528c0af5BA847C41730;
    _wallet.publicOffer        = 0xc8166AC778a6943E32d9db45d33DA2dE376D8702;
    _wallet.employees          = 0x4c5eD64Bf409A9196703572919b8d0ab7b5C19d9;
    _wallet.founders           = 0x0Cf463ED43B05FF29866435de860FBf6f62A3150;
    _wallet.influencers        = 0xeFD7c11Cdf32bde869D0ddb14Fd67393B5b07edC;
    _wallet.privateOffer       = 0xf6C8F134020590A658E2FA85108636678d5654CA;
    _wallet.airDrop            = 0x157642Adfb81301fC7DFeFf41Da3fac369d25374;
    _wallet.initialPublicOffer = 0xc2F91B827570Eb111d7851B8aC32e9E85581a3ef;
    _wallet.presale            = 0xa903C02E0B60020d4df38464E11ecf6280033CeA;
    _wallet.seed               = 0xcC579E57B72bEc0c8C65C23E020C15510EA77D7b;
    _wallet.launchPad          = 0xa7Ada24C9E91e50c2d9C98B15635f4e8CDeC45C2;
    

    _feeSplit.holders   = 35;
    _feeSplit.operation = 25;
    _feeSplit.growth    = 25;
    _feeSplit.fundation = 15;

    _mintSplit.growth             = 30000;
    _mintSplit.stake              = 20000;
    _mintSplit.publicOffer        = 10000;
    _mintSplit.employees          =  7500;
    _mintSplit.founders           =  6000;
    _mintSplit.fundation          =  5000;
    _mintSplit.influencers        =  5000;
    _mintSplit.operation          =  4075;
    _mintSplit.privateOffer       =  2500;
    _mintSplit.airDrop            =  2500;
    _mintSplit.initialPublicOffer =  2500;
    _mintSplit.presale            =  1750;
    _mintSplit.seed               =  1675;    
    _mintSplit.launchPad          =  1500; 

    _noFee[msg.sender]                 = true;
    _noFee[_wallet.holders]            = true;
    _noFee[_wallet.operation]          = true;
    _noFee[_wallet.growth]             = true;
    _noFee[_wallet.fundation]          = true;
    _noFee[_wallet.stake]              = true;
    _noFee[_wallet.publicOffer]        = true;
    _noFee[_wallet.employees]          = true;
    _noFee[_wallet.founders]           = true;
    _noFee[_wallet.influencers]        = true;
    _noFee[_wallet.privateOffer]       = true;
    _noFee[_wallet.airDrop]            = true;
    _noFee[_wallet.initialPublicOffer] = true;
    _noFee[_wallet.presale]            = true;
    _noFee[_wallet.seed]               = true;
    _noFee[_wallet.launchPad]          = true; 

    
    emit Transfer(address(0), msg.sender, _totalSupply);

    for (uint256 i = 0; i < migraWallets.length; i++) {
      _alreadyMinted = _alreadyMinted + migraAmounts[i];
      _mint(migraWallets[i], migraAmounts[i]);
    }

    
  }

  /**
   * @dev set wallets.
   */
  function setWallet(address holders, address operation, address growth, address fundation) external onlyOwner {
    _wallet.holders   = holders;
    _wallet.operation = operation;
    _wallet.growth    = growth;
    _wallet.fundation = fundation;
  }

  /**
   * @dev returns the addresses of the wallets receiving fees.
   */
  function getWallet() external view returns (address, address, address, address)  {
    return (_wallet.holders, _wallet.operation, _wallet.growth, _wallet.fundation);
  }

  /**
   * @dev sets the default fee for all address
   */
  function setStandartFee(uint8 fee) external onlyOwner {
    _standartFee = fee;
  }

  /**
   * @dev returns the default fee.
   */
  function getStandartFee() external view returns (uint8)  {
    return (_standartFee);
  }

  /**
   * @dev sets a custom fee for a specific address.
   */
  function setCustomFee(address wallet, uint8 fee) external onlyOwner {
    _customFee[wallet] = fee;
  }

  /**
   * @dev return the custom address fee.
   */
  function getCustomFee(address wallet) external view returns (uint8)  {
    return (_customFee[wallet]);
  }

  /**
   * @dev sets the percentages of fee sharing in the wallets.
   */
  function setFeeSplit(uint8 holders, uint8 operation, uint8 growth, uint8 fundation) external onlyOwner {
    require(holders + operation + growth + fundation == 100, "BEP20: split sum has to be 100.");
    _feeSplit.holders   = holders;
    _feeSplit.operation = operation;
    _feeSplit.growth    = growth;
    _feeSplit.fundation = fundation;
  }

  /**
   * @dev returns fee split setting.
   */
  function getFeeSplit() external view returns (uint8, uint8, uint8, uint8)  {
    return (_feeSplit.holders, _feeSplit.operation, _feeSplit.growth, _feeSplit.fundation);
  }


 /**
   * @dev sets the percentages of fee sharing in the wallets.
   */
 function setMintSplit(MintSplit memory mintSplit) external onlyOwner {
    require(mintSplit.holders + mintSplit.operation + mintSplit.growth + mintSplit.fundation + mintSplit.stake + mintSplit.publicOffer + mintSplit.employees + 
            mintSplit.founders + mintSplit.influencers + mintSplit.privateOffer + mintSplit.airDrop + mintSplit.initialPublicOffer + mintSplit.presale
            + mintSplit.seed + mintSplit.launchPad == 100000, "BEP20: split sum has to be 100000 -> 100%.");
    
    _mintSplit = mintSplit;
  }

  /**
   * @dev returns fee split setting.
   */
  function getMintSplit() external view returns ( MintSplit memory )  {
    return (_mintSplit);
  }
 
  /**
   * @dev set address without transaction fee implications (true) or with fee (false).
   */
  function setNoFee(address wallet, bool noFee) external onlyOwner {
    _noFee[wallet] = noFee;
  }

  /**
   * @dev returns fee status of an address
   */
  function getNoFee(address wallet) external view returns (bool)  {
    return (_noFee[wallet]);
  }

   
  /**
   * @dev set lock in a address.
   */
  function setLock(uint256 amount, uint256 end) external {
    require( block.timestamp < end, "BEP20: Invalid timestamp!");
    _locks[msg.sender].amount.push(amount);
    _locks[msg.sender].end.push(end);
    emit setLockEvent( msg.sender, amount, end);
  }

  /**
   * @dev Returns the lock info of a address.
   */
  function getLockInfo(address wallet) external view returns (Lock memory) {
    return (_locks[wallet]);
  }
  

  /**
   * @dev Returns amount to burn.
  */
  function amountBurn(uint256 amount) internal view returns (uint256) {
    uint256 alreadyBurned = _maxSupply - ( _maxSupply - _alreadyMinted + _totalSupply );   
    uint256 newBurned = alreadyBurned + amount;
    if (newBurned <= _maxBurn) {
      return amount;
    }
    uint256 toBurn = _maxBurn - alreadyBurned;
    return toBurn;  
  }
   
   /**
   * @dev token-specific transfer function - considers locked tokens and transaction fee
   */
  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    uint256 balanceLock = 0;
    for (uint i =0; i < _locks[sender].end.length; i++) {
      if (block.timestamp <= _locks[sender].end[i]) {
        balanceLock += _locks[sender].amount[i];
      }
      else {
        _locks[sender].amount[i] = 0;  
      }
    }
  
    uint256 balance     = _balances[sender];
    //uint256 balanceLock = _locks[sender].amount;
    uint256 balanceFree = balance - balanceLock;
    require(balanceFree >= amount, "BEP20: transfer amount exceeds balance free");
    
    uint256 amountFree = amount;
    _balances[sender] -= amount;

    if (_noFee[sender] == false) {

      uint8 _realFee = _standartFee;
      if (_customFee[sender] > 0) {
        _realFee = _customFee[sender];
      }

      uint256 _feeAmount = (amount * _realFee * 100) / 10000;

      uint256 amountHolders   = (_feeAmount * _feeSplit.holders   * 100) / 10000;
      uint256 amountOperation = (_feeAmount * _feeSplit.operation * 100) / 10000;
      uint256 amountGrowth    = (_feeAmount * _feeSplit.growth    * 100) / 10000;
      uint256 amountFundation = (_feeAmount * _feeSplit.fundation * 100) / 10000;

      amountFree = amount - amountHolders - amountOperation - amountGrowth - amountFundation;
      
      if (amountHolders > 0) {
        _balances[_wallet.holders]   += amountHolders;
        emit Transfer(sender, _wallet.holders, amountHolders);
      }
      if (amountOperation > 0) {
        _balances[_wallet.operation] += amountOperation;
        emit Transfer(sender, _wallet.operation, amountOperation);
      }
      if (amountGrowth > 0) {
         _balances[_wallet.growth]    += amountGrowth;
        emit Transfer(sender, _wallet.growth, amountGrowth);
      }
      if (amountFundation > 0) {
        _balances[_wallet.fundation] += amountFundation;
        emit Transfer(sender, _wallet.fundation, amountFundation);
      }

      uint256 toBurn = amountBurn(amountHolders);
      if (toBurn > 0) {
        _burn(_wallet.holders, toBurn);
      }

    }

    _balances[recipient] += amountFree;
    emit Transfer(sender, recipient, amountFree);

  
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mintUnic(uint256 amount) public onlyOwner returns (bool) {
    require( amount + _alreadyMinted <= _maxSupply , "BEP20: maxMinted invalid!");
    _alreadyMinted = _alreadyMinted + amount;
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to the tokenomics portfolios, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mintTokenomics(uint256 amount) public onlyOwner returns (bool) {
    require( amount + _alreadyMinted <= _maxSupply , "BEP20: maxMinted invalid!");
    _alreadyMinted = _alreadyMinted + amount;
    _mint(_wallet.growth,             (_mintSplit.growth * amount)             / 100000 );
    _mint(_wallet.stake,              (_mintSplit.stake * amount)              / 100000 );
    _mint(_wallet.publicOffer,        (_mintSplit.publicOffer * amount)        / 100000 );
    _mint(_wallet.employees,          (_mintSplit.employees * amount)          / 100000 );
    _mint(_wallet.founders,           (_mintSplit.founders * amount)           / 100000 );
    _mint(_wallet.fundation,          (_mintSplit.fundation * amount)          / 100000 );
    _mint(_wallet.influencers,        (_mintSplit.influencers * amount)        / 100000 );
    _mint(_wallet.operation,          (_mintSplit.operation * amount)          / 100000 );
    _mint(_wallet.privateOffer,       (_mintSplit.privateOffer * amount)       / 100000 );
    _mint(_wallet.airDrop,            (_mintSplit.airDrop * amount)            / 100000 );
    _mint(_wallet.initialPublicOffer, (_mintSplit.initialPublicOffer * amount) / 100000 );
    _mint(_wallet.presale,            (_mintSplit.presale * amount)            / 100000 );
    _mint(_wallet.seed,               (_mintSplit.seed * amount)               / 100000 );
    _mint(_wallet.launchPad,          (_mintSplit.launchPad * amount)          / 100000 );
    return true;
  }

  /**
   * @dev Returns the lock info of a address.
   */
  function getAlreadyMinted() external view returns (uint256) {
    return (_alreadyMinted);
  }

}