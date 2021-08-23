// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./IUniswapV2Router.sol";
import "./RewManagerInterface.sol";

interface RewDoge is IERC20 {
    function excludeFromFee(address account) external;
    function includeInFee(address account) external;
    function setCooldownEnabled(bool onoff) external;

    function setMaxTxPercent(uint256 maxTxPercent) external;
    
    function transferOwnership(address newOwner) external;
}

contract MDivManager is RewManagerInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // The currency in which we pays dividends.
  RewDoge public REWDOGE = RewDoge(0x1a9B9e13380c480b467373F6bEb274ebd5BF677C);
  
  // other fixed addresses
  address payable private devWallet = 0xd91334849E208cbd56131a875eC2914A5eB3472e;  // TODO
  IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);  // TODO check this.  also should we add a way to update theses?

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;


  mapping (IERC20 => bool) internal authorizedClients;

  // _client => magnifiedDividendPerShare.  _client is the contract we are managing dividends for.
  mapping (IERC20 => uint256) internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  //
  // These maps are _client => _user => value
  mapping(IERC20 => mapping(address => int256)) internal magnifiedDividendCorrections;
  mapping(IERC20 => mapping(address => uint256)) internal withdrawnDividends;

  // _client => value
  mapping (IERC20 => uint256) public totalDividendsDistributed;
  
  uint256 internal owedDividends;
  
  /// @dev every bonusFrequency payouts, we add the accumulated reflections to the next payout as a bonus to that lucky person.
  uint256 internal bonusFrequency;
  uint256 internal paymentsSinceBonus;

  constructor() public {
      owedDividends = 0;
      bonusFrequency = 1000;
      paymentsSinceBonus = 0;
  }

  function authorizeClient(IERC20 _client) public onlyOwner {
      authorizedClients[_client] = true;
  }
  
  function deauthorizeClient(IERC20 _client) public onlyOwner {
      authorizedClients[_client] = false;
  }

  // swap ETH for rew (taking fee, if applicable).  Returns number of tokens received.
  function swapETHforRew(uint256 _amount) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(REWDOGE);

    // We swap 99% of the sent ETH, and keep 1% as fee.
    uint256 toSwap = _amount.mul(99).div(100);

    uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value : toSwap}(
      0,
      path,
      address(this),
      block.timestamp
    );
    
    // remaining 1% is fee.  There should be no other ETH in the contract at this point.
    devWallet.transfer(address(this).balance);
    
    return amounts[1];
  }

  function distributeDividends() public payable override {
    // Only authorized clients can distribute dividends.
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client]);
    
    // Dividend distribution only makes sense for clients that have tokens out there.
    uint256 clientSupply = client.totalSupply();
    require(clientSupply > 0);    
    
    if (msg.value > 0) {
      uint256 numTokens = swapETHforRew(msg.value);
        
      magnifiedDividendPerShare[client] = magnifiedDividendPerShare[client].add(
        (numTokens).mul(magnitude) / clientSupply
      );
      emit DividendsDistributed(client, numTokens);

      owedDividends = owedDividends.add(numTokens);
      totalDividendsDistributed[client] = totalDividendsDistributed[client].add(numTokens);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  /// This may only be called by the client contract or the user themselves.
  function withdrawDividend(IERC20 _client, address payable _user) public virtual override returns (uint256) {
    require(IERC20(msg.sender) == _client || msg.sender == _user);
    return _withdrawDividendOfUser(_client, _user);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn RewDoge is greater than 0.
 function _withdrawDividendOfUser(IERC20 _client, address payable _user) internal returns (uint256) {
    require(authorizedClients[_client]);

    uint256 _withdrawableDividend = withdrawableDividendOf(_client, _user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[_client][_user] = withdrawnDividends[_client][_user].add(_withdrawableDividend);

      // this pays out 
      uint256 bonus = 0;
      if(paymentsSinceBonus >= bonusFrequency) {
          bonus = bonus.add(unallocatedRewardTokens());
      }
      bool success = REWDOGE.transfer(_user, _withdrawableDividend.add(bonus));

      if(success) {
        emit DividendWithdrawn(_client, _user, _withdrawableDividend);
        if(bonus > 0) {
            paymentsSinceBonus = 0;
            emit BonusPaid(_client, _user, bonus);
        }
      } else {
        withdrawnDividends[_client][_user] = withdrawnDividends[_client][_user].sub(_withdrawableDividend);
        return 0;
      }

      owedDividends = owedDividends.sub(_withdrawableDividend);
      return _withdrawableDividend;
    }
    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _client The contract for which Dog Walker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_client, _owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _client The contract for which Dog Walker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    require(authorizedClients[_client]);
    return accumulativeDividendOf(_client,_owner).sub(withdrawnDividends[_client][_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _client The contract for which Dog Walker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    require(authorizedClients[_client]);
    return withdrawnDividends[_client][_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _client The contract for which Dog Walker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    require(authorizedClients[_client]);
    return magnifiedDividendPerShare[_client].mul(_client.balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_client][_owner]).toUint256Safe() / magnitude;
  }
  
  /// @dev Client contracts must call this whenever they transfer tokens.
  /// Updates magnifiedDividendCorrections to keep dividends unchanged.
  /// @param _from The address to transfer from.
  /// @param _to The address to transfer to.
  /// @param _value The amount to be transferred.
  function clientTransfer(address _from, address _to, uint256 _value) public override {
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client]);
    
    int256 _magCorrection = magnifiedDividendPerShare[client].mul(_value).toInt256Safe();
    magnifiedDividendCorrections[client][_from] = magnifiedDividendCorrections[client][_from].add(_magCorrection);
    magnifiedDividendCorrections[client][_to] = magnifiedDividendCorrections[client][_to].sub(_magCorrection);
  }

  /// @dev Client contracts must call this whenever they mint tokens.
  /// Updates magnifiedDividendCorrections to keep dividends unchanged.
  /// @param _account The account that will receive the created tokens.
  /// @param _value The amount that will be created.
  function clientMint(address _account, uint256 _value) public override {
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client]);

    magnifiedDividendCorrections[client][_account] = magnifiedDividendCorrections[client][_account]
      .sub( (magnifiedDividendPerShare[client].mul(_value)).toInt256Safe() );
  }

  /// @dev Client contracts must call this whenever they burn tokens.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param _account The account whose tokens will be burnt.
  /// @param _value The amount that will be burnt.
  function clientBurn(address _account, uint256 _value) public override {
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client]);

    magnifiedDividendCorrections[client][_account] = magnifiedDividendCorrections[client][_account]
      .add( (magnifiedDividendPerShare[client].mul(_value)).toInt256Safe() );
  }

  /// @dev Client contracts must call this when token balances change in ways that aren't captured
  ///      by clientTransfer/clientBurn/clientMint.
  function clientSetBalance(address _account, uint256 _oldBalance, uint256 _newBalance) external override {
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client]);

    if(_newBalance > _oldBalance) {
      uint256 mintAmount = _newBalance.sub(_oldBalance);
      clientMint(_account, mintAmount);
    } else if(_newBalance < _oldBalance) {
      uint256 burnAmount = _oldBalance.sub(_newBalance);
      clientBurn(_account, burnAmount);
    }
  }
  
  // The total dividends distributed for a given client contract
  function dividendsDistributed(IERC20 _client) external view override  returns (uint256) {
    require(authorizedClients[_client]);
    return totalDividendsDistributed[_client];
  }
  
  function rewExcludeFromFee(address _account) external override onlyOwner {
      REWDOGE.excludeFromFee(_account);
  }
  
  function rewIncludeInFee(address _account) external override onlyOwner {
      REWDOGE.includeInFee(_account);
      
  }
  
  function rewSetCooldownEnabled(bool _onoff) external override onlyOwner {
      REWDOGE.setCooldownEnabled(_onoff);
  }

  function rewSetMaxTxPercent(uint256 _maxTxPercent) external override onlyOwner {
      REWDOGE.setMaxTxPercent(_maxTxPercent);
  }
  
  function rewTransferOwnership(address newOwner) external override onlyOwner {
      REWDOGE.transferOwnership(newOwner);
  }
  
  function totalOwedDividends() public view override returns (uint256) {
      return owedDividends;
  }
  
  function unallocatedRewardTokens() public view override returns (uint256) {
      return REWDOGE.balanceOf(address(this)).sub(owedDividends);
  }
}