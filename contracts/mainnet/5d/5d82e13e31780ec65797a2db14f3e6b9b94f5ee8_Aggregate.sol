pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

    /// @title A Fee on Transfer token with automatic reflections to holders.
    /// @notice Token contract inheriting ERC20 standard with basic access
    /// control and emergency pause mechanism. The token contract implements
    /// Fee on Transfer distributed among marketing wallet, acquisition wallets,
    /// and all token holders (via reflections) on Buy / Sell transactions
    /// only. Wallet-to-wallet transfers do not incur a fee on transfer.
contract Aggregate is ERC20, Pausable, Ownable {

    //--------------------------State Variables---------------------------------

    struct FeeValues {
          uint256 Amount;
          uint256 TransferAmount;
          uint256 ReflectFee;
          uint256 MarketingFee;
          uint256 AcquisitionFee;
      }
    enum MarketSide {
      NONE,
      BUY,
      SELL
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    address private _marketingWallet;
    address[5] private _acquisitionWallets;
    mapping (address => bool) private _isExchange;

    uint8 private _buyFeeReflect;
    uint8 private _buyFeeMarketing;
    uint8 private _buyFeeAcquisition;
    uint8 private _sellFeeReflect;
    uint8 private _sellFeeMarketing;
    uint8 private _sellFeeAcquisition;

    //--------------------------Constructor-------------------------------------

    /// @notice Sets the values for name, symbol, totalSupply, marketingWallet,
    /// and acquisitionWallets. Initial allocation: 95% to Admin account (for
    /// liquidity), 2% to Marketing wallet, 3% to Acquisition wallets.
    /// @param name_ is token name.
    /// @param symbol_ is token symbol.
    /// @param supply_ is total token supply.
    /// @param marketing_ is inital marketing wallet address.
    /// @param acquisition_ is list of initial 5 acquisition wallet addresses.
    constructor (
      string memory name_,
      string memory symbol_,
      uint256 supply_,
      address marketing_,
      address[] memory acquisition_
      ) {

      _name = name_;
      _symbol = symbol_;
      _tTotal = supply_ * 10**4;
      _rTotal = (~uint256(0) - (~uint256(0) % _tTotal));
      _buyFeeReflect = 1;
      _buyFeeMarketing = 1;
      _buyFeeAcquisition = 7;
      _sellFeeReflect = 5;
      _sellFeeMarketing = 1;
      _sellFeeAcquisition = 3;
      _marketingWallet = marketing_;
      for(uint i = 0; i < _acquisitionWallets.length; i++) {
        _acquisitionWallets[i] = acquisition_[i];
      }

      _tOwned[_msgSender()] += _tTotal * 95 / 100;
      _rOwned[_msgSender()] += _rTotal / 100 * 95;
      emit Transfer(address(0), _msgSender(), _tOwned[_msgSender()]);

      _tOwned[_marketingWallet] += _tTotal * 2 / 100;
      _rOwned[_marketingWallet] += _rTotal / 100 * 2;
      emit Transfer(address(0), _marketingWallet, _tTotal * 2 / 100);

      for(uint i = 0; i < _acquisitionWallets.length; i++){
        _tOwned[_acquisitionWallets[i]] +=
          _tTotal * 3 / 100 / _acquisitionWallets.length;
        _rOwned[_acquisitionWallets[i]] +=
          _rTotal / 100 * 3 / _acquisitionWallets.length;

        emit Transfer(
          address(0),
          _acquisitionWallets[i],
          _tTotal * 3 / 100 / _acquisitionWallets.length
          );
      }

    }

    //--------------------------ERC20 Override Functions------------------------

    /// @notice See {IERC20-totalSupply}.
    /// @dev Overrides ERC20 totalSupply function.
    /// @return supply_ is total token supply.
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /// @notice See {IERC20-balanceOf}.
    /// @dev Overrides ERC20 balanceOf function. If account is excluded then
    /// _tOwned balance is returned since that tracks token balance without
    /// reflections. Otherwise, _rOwned balance is returned after scaling down
    /// by reflection rate.
    /// @param account is address to be checked for token balance.
    /// @return balance_ is token balance of 'account'.
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /// @notice Number of decimals for token representation.
    /// @dev Overrides ERC20 decimals function. Value of 4 decimals is required
    /// to maintain precision of arithmetic operations for reflection fee
    /// distributions, given the token supply.
    /// @return decimals_ is number of decimals for display purposes.
    function decimals() public pure override returns (uint8) {
        return 4;
    }

    /// @notice See {IERC20-transfer}.
    /// @dev Overrides ERC20 _transfer function. Requires 'sender' and
    /// 'recipient' to be non-zero address to prevent minting/burning and
    /// non-zero transfer amount. Function determines transaction type 'BUY',
    /// 'SELL', or 'NONE' depending on whether sender or recipient is exchange
    /// pair address. Actual token transfer is delegated to {_transferStandard}.
    /// Function is pausable by token administrator.
    /// @param sender is address sending token.
    /// @param recipient is address receiving token.
    /// @param amount is number of tokens being transferred.
    function _transfer(
      address sender,
      address recipient,
      uint256 amount
      ) internal override whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        MarketSide _side;
        if(_isExchange[sender]){
            _side = MarketSide.BUY;
        } else if(_isExchange[recipient]) {
            _side = MarketSide.SELL;
        } else {
            _side = MarketSide.NONE;
        }

        _transferStandard(sender, recipient, amount, _side);
    }

    //--------------------------View Functions----------------------------------

    /// @notice Provides scaled down amount based on current reflection rate.
    /// @dev Helper function for balanceOf function. Scales down a given amount,
    /// inclusive of reflections, by reflection rate.
    /// @param rAmount is the amount, inclusive of reflections, to be scaled
    /// down by reflection rate.
    /// @return tAmount_ is amount scaled down by current reflection rate.
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total supply");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    /// @notice Allows checking whether an account has been excluded from
    /// receiving reflection distributions.
    /// @param account is address to be checked if excluded from reflections.
    /// @return excluded_ is true if account is excluded, otherwise, returns
    /// false.
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /// @notice Returns which address is receiving marketing fees
    /// from 'BUY' / 'SELL' transactions.
    function getMarketingWallet() public view returns (address){
      return _marketingWallet;
    }

    /// @notice Returns which address is receiving acquisition fees
    /// from 'BUY' / 'SELL' transactions at a given index.
    /// @param index is number between 0 - 4 representing wallets 1 through 5.
    function getAcquisitionWallet(uint256 index) public view returns (address){
      require(index < _acquisitionWallets.length, "Invalid index");
      return _acquisitionWallets[index];
    }

    /// @notice Allows to view total amount of reflection fees collected since
    /// contract creation.
    /// @return totalFees_ is total reflection fees collected.
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    //--------------------------Token Transfer----------------------------------

    /// @dev Updates _rOwned and _tOwned balances after deducting applicable
    /// transaction fees and allocates fees to marketing and acquisition
    /// wallets. {_getValues} helper function calculates all relevant amounts.
    /// Emits a {Transfer} event after the balances have been updated.
    /// @param sender is address sending token.
    /// @param recipient is address receiving token.
    /// @param tAmount is number of tokens being transferred.
    /// @param _side is transaction type: 'BUY', 'SELL', 'NONE'.
    function _transferStandard(
      address sender,
      address recipient,
      uint256 tAmount,
      MarketSide _side
      ) private {

        (
          FeeValues memory _tValues,
          FeeValues memory _rValues
          ) = _getValues(tAmount, _side);

        if(_isExcluded[sender]){
          _tOwned[sender] -= _tValues.Amount;
          _rOwned[sender] -= _rValues.Amount;
        } else {
          _rOwned[sender] -= _rValues.Amount;
        }

        if(_isExcluded[recipient]){
          _tOwned[recipient] += _tValues.TransferAmount;
          _rOwned[recipient] += _rValues.TransferAmount;
        } else {
          _rOwned[recipient] += _rValues.TransferAmount;
        }
        emit Transfer(sender, recipient, _tValues.TransferAmount);

        if(_side != MarketSide.NONE){
          _reflectFee(_rValues.ReflectFee, _tValues.ReflectFee);
          if(_tValues.MarketingFee > 0) {
            if(_isExcluded[_marketingWallet]){
              _tOwned[_marketingWallet] += _tValues.MarketingFee;
              _rOwned[_marketingWallet] += _rValues.MarketingFee;
            } else {
              _rOwned[_marketingWallet] += _rValues.MarketingFee;
            }
            emit Transfer(sender, _marketingWallet, _tValues.MarketingFee);
          }

          if(_tValues.AcquisitionFee > 0) {
            _acquisitionWalletAlloc(
              sender, _tValues.AcquisitionFee,
              _rValues.AcquisitionFee
              );
          }
        }
    }

    /// @dev Allocates the acquisition wallet fees to each of the five
    /// acquisition addresses in equal proportion.
    /// @param sender is address sending token.
    /// @param tAmount is amount of tokens to be allocated.
    /// @param rAmount is scaled up amount, inclusive of reflections, of tokens
    /// to be allocated.
    function _acquisitionWalletAlloc(
      address sender,
      uint256 tAmount,
      uint256 rAmount
      ) private {
        uint256 _tAllocation = tAmount / _acquisitionWallets.length;
        uint256 _rAllocation = rAmount / _acquisitionWallets.length;

        for(uint i = 0; i < _acquisitionWallets.length; i++){
          if(_isExcluded[_acquisitionWallets[i]]){
            _tOwned[_acquisitionWallets[i]] += _tAllocation;
            _rOwned[_acquisitionWallets[i]] += _rAllocation;
          } else {
            _rOwned[_acquisitionWallets[i]] += _rAllocation;
          }
          emit Transfer(sender, _acquisitionWallets[i], _tAllocation);
        }
    }

    //--------------------------Fee Calculation---------------------------------

    /// @dev Updates {_rTotal} supply by subtracting reflection fees. Updates
    /// {_tFeeTotal} to add reflection fees. This is used to update the
    /// reflection rate to calculate users' balances included in reflection.
    /// @param rFee Scaled up reflection fees from transaction
    /// @param tFee Actual reflection fees from transaction
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    /// @dev Calculates the required fees to be deducted for given transaction
    /// amount and transaction type.
    /// @param tAmount is the amount being transferred by user.
    /// @param _side is the transaction type: {BUY}, {SELL}, {NONE}.
    /// @return tValues_ is the calculated actual fee values for transfer
    /// amount {tAmount}.
    function _getValues(
      uint256 tAmount,
      MarketSide _side
      ) private view returns (
        FeeValues memory tValues_,
        FeeValues memory rValues_
        ) {

        uint256 currentRate =  _getRate();
        FeeValues memory _tValues = _getTValues(tAmount, _side);
        FeeValues memory _rValues = _getRValues(_tValues, currentRate);

        return (_tValues, _rValues);
    }

    /// @dev Function call {_getFeeValues} to obtain the relevant fee
    /// percentage for the {_side} transaction type. Calculates the actual
    /// marketing, acquistion, and reflection fees to be deducted from the
    /// transfer amount.
    /// @param tAmount is the amount being transferred by user.
    /// @param _side is the transaction type: 'BUY', 'SELL', 'NONE'.
    function _getTValues(
      uint256 tAmount,
      MarketSide _side
      ) private view returns (FeeValues memory) {
        (
          uint8 feeReflect_,
          uint8 feeMarketing_,
          uint8 feeAcquisition_
          ) = _getFeeValues(_side);

        FeeValues memory _tValues;
        _tValues.Amount = tAmount;
        _tValues.ReflectFee = tAmount * feeReflect_ / 100;
        _tValues.MarketingFee = tAmount * feeMarketing_ / 100;
        _tValues.AcquisitionFee = tAmount * feeAcquisition_ / 100;
        _tValues.TransferAmount =
          _tValues.Amount
          - _tValues.ReflectFee
          - _tValues.MarketingFee
          - _tValues.AcquisitionFee;

        return (_tValues);
    }

    /// @dev Scales up the actual transaction fees {_tValues} by reflection
    /// rate to allow proper update of _rOwned user balance.
    /// @param _tValues is the struct containing actual transfer amount and
    /// fees to be deducted.
    /// @param currentRate is current reflection rate.
    function _getRValues(
      FeeValues memory _tValues,
      uint256 currentRate
      ) private pure returns (FeeValues memory) {

        FeeValues memory _rValues;
        _rValues.Amount = _tValues.Amount * currentRate;
        _rValues.ReflectFee = _tValues.ReflectFee * currentRate;
        _rValues.MarketingFee = _tValues.MarketingFee * currentRate;
        _rValues.AcquisitionFee = _tValues.AcquisitionFee * currentRate;
        _rValues.TransferAmount =
          _rValues.Amount
          - _rValues.ReflectFee
          - _rValues.MarketingFee
          - _rValues.AcquisitionFee;

        return (_rValues);
    }

    /// @dev Calculates the reflection rate based on rSupply and rSupply. As
    /// reflection fees are deducted from rSupply by {_reflectFee} function,
    /// the reflection rate will decrease, causing users' balances to increase
    /// by the reflection fee in proportion to the user's balance / total supply
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /// @dev Calculates the transaction fee percentages depending on whether
    /// user is buying, selling, or transferring the token.
    /// @param _side is the transaction type: 'BUY', 'SELL', 'NONE'.
    function _getFeeValues(MarketSide _side) private view returns (
      uint8,
      uint8,
      uint8
      ) {
        if(_side == MarketSide.BUY){
            return (_buyFeeReflect, _buyFeeMarketing, _buyFeeAcquisition);
        } else if(_side == MarketSide.SELL){
            return (_sellFeeReflect, _sellFeeMarketing, _sellFeeAcquisition);
        } else {
            return (0, 0, 0);
        }
    }

    /// @dev Calculates the scaled up and actual token supply exclusive of
    /// excluded addresses. This impacts the reflection rate (greater decrease)
    /// to allow included addresses to receive reflections that would have gone
    /// to excluded accounts.
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
          if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
          return (_rTotal, _tTotal);

          rSupply = rSupply - _rOwned[_excluded[i]];
          tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    //--------------------------Restricted Functions----------------------------

    /// @notice Sets the exchange pair address for the token to detect 'BUY',
    /// 'SELL', or 'NONE' transactions for fee collection. Can only be updated
    /// by administrator.
    /// @dev Only transactions to, and from this address will trigger fee
    /// collection.
    /// @param exchangePair is the DEX-created contract address of the
    /// exchange pair.
    function setExchange(address exchangePair) external onlyOwner {
        require(!_isExchange[exchangePair], "Address already Exchange");
        _isExchange[exchangePair] = true;
    }

    /// @notice Removes an exchange pair address from fee collection. Can
    /// only be updated by administrator.
    /// @param exchangePair is the DEX-created contract address of the exchange
    /// pair to be removed as an "exchange" for fee collection.
    function removeExchange(address exchangePair) external onlyOwner {
        require(_isExchange[exchangePair], "Address not Exchange");
        _isExchange[exchangePair] = false;
    }

    /// @notice Changes marketing wallet address to receive marketing fee going
    /// forward. Can only be updated by administrator.
    /// @param newAddress is the new address to replace existing
    /// marketing wallet address.
    function changeMarketing(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero address");
        _marketingWallet = newAddress;
    }

    /// @notice Changes acquisition wallets address to receive acquisition fee
    /// going forward. Can only be updated by administrator.
    /// @param index is the acquisition wallet address to be replaced,
    /// from 0 to 4.
    /// @param newAddress is the new address to replace existing
    /// acquisition wallet address.
    function changeAcquisition(
      uint256 index,
      address newAddress
      ) external onlyOwner {
        require(index < _acquisitionWallets.length, "Invalid index value");
        require(newAddress != address(0), "Address cannot be zero address");
        _acquisitionWallets[index] = newAddress;
    }

    /// @notice Changes the reflection, marketing, and acquisition fee
    /// percentages to be deducted from 'BUY' transaction type. Can only be
    /// updated by administrator.
    /// @param reflectFee is the new reflection fee percentage.
    /// @param marketingFee is the new marketing fee percentage.
    /// @param acquisitionFee is the new acquisition fee percentage.
    function setBuyFees(
      uint8 reflectFee,
      uint8 marketingFee,
      uint8 acquisitionFee
      ) external onlyOwner {
        require(reflectFee + marketingFee + acquisitionFee < 100,
          "Total fee percentage must be less than 100%"
          );

        _buyFeeReflect = reflectFee;
        _buyFeeMarketing = marketingFee;
        _buyFeeAcquisition = acquisitionFee;
    }

    /// @notice Changes the reflection, marketing, and acquisition fee
    /// percentages to be deducted from {SELL} transaction type. Can only be
    /// updated by administrator.
    /// @param reflectFee is the new reflection fee percentage.
    /// @param marketingFee is the new marketing fee percentage.
    /// @param acquisitionFee is the new acquisition fee percentage.
    function setSellFees(
      uint8 reflectFee,
      uint8 marketingFee,
      uint8 acquisitionFee
      ) external onlyOwner {
        require(reflectFee + marketingFee + acquisitionFee < 100,
          "Total fee percentage must be less than 100%"
          );

        _sellFeeReflect = reflectFee;
        _sellFeeMarketing = marketingFee;
        _sellFeeAcquisition = acquisitionFee;
    }

    /// @notice Removes address from receiving future reflection distributions.
    /// Can only be updated by administrator.
    /// @param account is address to be excluded from reflections.
    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account already excluded");
        require(balanceOf(account) < _tTotal, "Cannot exclude total supply");
         _tOwned[account] = balanceOf(account);
         _excluded.push(account);
        _isExcluded[account] = true;
    }

    /// @notice Includes previously excluded address to receive reflection
    /// distributions in case of erroneously excluded address. NOTE: Included
    /// address will receive all previous reflection distribution it should
    /// have received while address was excluded. Can only be updated by
    /// administrator.
    /// @param account is address to be re-included to reflections.
    function includeAccount(address account) external onlyOwner {
      require(_isExcluded[account], "Account already included");

      for (uint256 i = 0; i < _excluded.length; i++) {
        if (_excluded[i] == account) {
          _excluded[i] = _excluded[_excluded.length - 1];
          _excluded.pop();
          _isExcluded[account] = false;
          break;
        }
      }
    }

    /// @notice Pauses token transfer functionality in case of emergency.
    /// Can only be updated by administrator.
    function lockToken() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses token transfer functionality to allow users to
    /// transfer token. Can only be updated by administrator.
    function unlockToken() external onlyOwner {
        _unpause();
    }
}