// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../ERC20.sol";
import "../SafeMath.sol";
import "../Ownable.sol";
import "../Address.sol";

contract TestLord is Context, ERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  // users will not pay tax when _taxEnabled is true. It is for private-sale, pre-sale participants. It will be also managed by voting.
  // 3% fee on sell transaction will be used to burn/buyback manually
  // taxAddress will be managed to manual burn/buyback by team
  // wallets that excluded from fee will not pay fee. it is for extra functions like staking function.
  bool public taxEnabled;
  uint256 public taxFee = 300;
  address public taxAddress;
  mapping (address => bool) private _isExcludedFromFee;

  // Arbitrage Bot, Sniper Bot addresses will be listed to _isBlackListed
  mapping (address => bool) private _isBlackListed;
  
  // lp addresses to check sell transaction. ownly owner who have dev skill has to manage this.
  mapping (address => bool) public automatedMarketMakerPairs;

  constructor() ERC20("TestLord", "TESTLORD") {
        _isExcludedFromFee[owner()] = true;

        _mint(address(this), 100 * (10 ** 9) * (10 ** uint256(decimals())));
        _approve(address(this), _msgSender(), totalSupply());
        _transfer(address(this), _msgSender(), totalSupply());
  }
  
  function isBlackListed(address _account) public view returns (bool) {
        return _isBlackListed[_account];
  }

  function isExcludedFromFee(address _account) public view returns (bool) {
        return _isExcludedFromFee[_account];
  }

  function setExcludeFromFee(address _account, bool _enable) external onlyOwner() {
        require(_isExcludedFromFee[_account] != _enable, "excludeFromFee: Duplicate Process.");
        _isExcludedFromFee[_account] = _enable;
  }

  function setBlackList(address _account, bool _enable) external onlyOwner() {
        require(_isBlackListed[_account] != _enable, "setBlackList: Duplicate Process.");
        _isBlackListed[_account] = _enable;
  }

  function setTaxEnable(bool _enable) external onlyOwner() {
        require(taxEnabled != _enable, "setTaxEnable: Duplicate Process.");
        taxEnabled = _enable;
  }
  
  function setTaxFee(uint256 _amount) external onlyOwner() {
        require(_amount <= 300, "setTaxFee: taxFee cannot exceed 3%.");
        taxFee = _amount;
  }
  
  function setTaxAddress(address _newAddress) external onlyOwner() {
        require(taxAddress != _newAddress, "setTaxAddress: Duplicate Process.");
        taxAddress = _newAddress;
  }

  function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner() {
        require(automatedMarketMakerPairs[pair] != value, "HighLord: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
  }

  function recoverContractBalance(address _account) external onlyOwner() {
        uint256 recoverBalance = address(this).balance;
        payable(_account).transfer(recoverBalance);
  }

  function recoverERC20(IERC20 recoverToken, uint256 tokenAmount, address _recoveryAddress) external onlyOwner() {
        recoverToken.approve(address(this), tokenAmount);
        recoverToken.transfer(_recoveryAddress, tokenAmount);
  }

  function _transfer(address from, address to, uint256 amount ) internal virtual override {
        require(from != address(0), "HighLord: transfer from the zero address");
        require(to != address(0), "HighLord: transfer to the zero address");
        require(amount > 0, "HighLord: Transfer amount must be greater than zero");
        require(!_isBlackListed[from] && !_isBlackListed[to], "HighLord: BlackListed Address is not available.");

        bool _isTax = taxEnabled;
        if (_isTax && !_isExcludedFromFee[from] && !_isExcludedFromFee[to])
            _isTax = false;
        
        // tax on only sell transaction
        if (_isTax && !automatedMarketMakerPairs[to])
            _isTax = false;
        
        if(_isTax){
            uint256 taxAmount = amount.mul(taxFee).div(10000);
            uint256 sendAmount = amount.sub(taxAmount);
            super._transfer(from, to, sendAmount);
            super._transfer(from, taxAddress, taxAmount);
        }
        else{
           super._transfer(from, to, amount); 
        }
  }
}