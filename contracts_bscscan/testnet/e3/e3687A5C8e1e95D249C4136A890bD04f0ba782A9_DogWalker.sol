// SPDX-License-Identifier: MIT

// DogWalker is a contract that manages DrunkDoge rewards for multiple client
// contracts.
//
// The DrunkDoge contract is set up with cooldowns and fees that limit the ability of
// other contracts to distribute DrunkDoge as rewards.  To work around this problem,
// we've developed DogWalker.  DogWalker is the owner of the DrunkDoge contract, and
// therefore does not have the cooldowns and fees.  We have designed DogWalker so that
// it can distribute DrunkDoge as rewards to holder of multiple other "client" tokens.
//
// Features:
// - Tracks, purchases and distributes DrunkDoge rewards owed to holders if multiple
//   client contracts.
// - Any DrunkDoge tokens that DogWalker earns through reflections are paid out as a
//   bonus to lucky rewards earners every 1000 claims.
// - Limits use to manually authorized client contracts, to prevent abuse.

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router.sol";
import "./DogWalkerInterface.sol";

interface DrunkDoge is IERC20 {
    function excludeFromFee(address account) external;
    function includeInFee(address account) external;
    function setCooldownEnabled(bool onoff) external;

    function setMaxTxPercent(uint256 maxTxPercent) external;
    
    function transferOwnership(address newOwner) external;
}

contract DogWalker is DogWalkerInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // The currency in which we pays dividends.
  DrunkDoge public DRUNK = DrunkDoge(0xDC4361927Ec99992B387efe95E161d6ca9Bfa242);
  
  // other fixed addresses
  address payable private devWallet = 0xdceDC5C6AcAc8c3b323087Fbe3b1FeDfBa0e023A;
  IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  // Client contracts that wish to use DogWalker to distribute DrunkDoge must be
  // explicitly authorized by the DogWalker team, to prevent abuse.
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
  
  // This tracks how much DrunkDoge we're holding that we owe in rewards.  We might
  // accumulate more DrunkDoge due to reflections, and we pay that out every 1000
  // claims as a "bonus" to a lucky reward earner.
  uint256 internal owedDividends;
  
  /// @dev every bonusFrequency payouts, we add the accumulated reflections to the next payout as a bonus to that lucky person.
  uint256 internal bonusFrequency;
  uint256 internal paymentsSinceBonus;

  constructor() public {
      owedDividends = 0;
      bonusFrequency = 1000;
      paymentsSinceBonus = 0;
  }

  // The DogWalker team must explicitly authorize client contracts, to prevent abuse.
  // These functions manage the authorized client list.
  function authorizeClient(IERC20 _client) public onlyOwner {
      authorizedClients[_client] = true;
  }
  
  function deauthorizeClient(IERC20 _client) public onlyOwner {
      authorizedClients[_client] = false;
  }

  // swap ETH for DrunkDoge (taking fee, if applicable).  Returns number of tokens received.
  function swapETHforDD(uint256 _amount) internal returns (uint256) {
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(DRUNK);

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

  /// @notice Turns ETH paid by a client contract into DrunkDoge rewards for the client's holders.
  /// @dev It emits a `DividendsDistributed` event if the amount of distributed ETH is greater than 0.
  /// This may only be called by the client contract or the user themselves.
  function distributeDividends() public payable override {
    // Only authorized clients can distribute dividends.
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client], "DogWalker: distributeDividends called by unauthorized client.");
    
    // Dividend distribution only makes sense for clients that have tokens out there.
    uint256 clientSupply = client.totalSupply();
    require(clientSupply > 0, "DogWalker: client contract called distributeDividends but has no token supply.");    
    
    if (msg.value > 0) {
      uint256 numTokens = swapETHforDD(msg.value);
        
      magnifiedDividendPerShare[client] = magnifiedDividendPerShare[client].add(
        (numTokens).mul(magnitude) / clientSupply
      );
      emit DividendsDistributed(client, numTokens);

      owedDividends = owedDividends.add(numTokens);
      totalDividendsDistributed[client] = totalDividendsDistributed[client].add(numTokens);
    }
  }

  /// @notice Withdraws the DrunkDoge distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn DrunkDoge is greater than 0.
  /// This may only be called by the client contract or the user themselves.
  function withdrawDividend(IERC20 _client, address payable _user) public virtual override returns (uint256) {
    require(IERC20(msg.sender) == _client || msg.sender == _user);
    return _withdrawDividendOfUser(_client, _user);
  }

  /// @notice Withdraws the DrunkDoge distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn DrunkDoge is greater than 0.
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
      
      bool success = DRUNK.transfer(_user, _withdrawableDividend);

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


  /// @notice View the amount of dividend in DrunkDoge that an address can withdraw.
  /// @param _client The contract for which DogWalker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_client, _owner);
  }

  /// @notice View the amount of dividend in DrunkDoge that an address can withdraw.
  /// @param _client The contract for which DogWalker is managing dividends.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(IERC20 _client, address _owner) public view override returns(uint256) {
    require(authorizedClients[_client]);
    return accumulativeDividendOf(_client,_owner).sub(withdrawnDividends[_client][_owner]);
  }

  /// @notice View the amount of dividend in DrunkDoge that an address has withdrawn.
  /// @param _client The contract for which DogWalker is managing dividends.
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
    require(authorizedClients[client], "DogWalker: clientBurn called by unauthorized client.");

    magnifiedDividendCorrections[client][_account] = magnifiedDividendCorrections[client][_account]
      .add( (magnifiedDividendPerShare[client].mul(_value)).toInt256Safe() );
  }

  /// @dev Client contracts must call this when token balances change in ways that aren't captured
  ///      by clientTransfer/clientBurn/clientMint.
  function clientSetBalance(address _account, uint256 _oldBalance, uint256 _newBalance) external override {
    IERC20 client = IERC20(msg.sender);
    require(authorizedClients[client], "DogWalker: clientSetBalance called by unauthorized client.");

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
    require(authorizedClients[_client], "DogWalker: dividendsDistributed called for unauthorized client.");
    return totalDividendsDistributed[_client];
  }
  
  // These functions allow the DogWalker owner to control the DrunkDoge contract
  function ddExcludeFromFee(address _account) external override onlyOwner {
      DRUNK.excludeFromFee(_account);
  }
  
  function ddIncludeInFee(address _account) external override onlyOwner {
      DRUNK.includeInFee(_account);
      
  }
  
  function ddSetCooldownEnabled(bool _onoff) external override onlyOwner {
      DRUNK.setCooldownEnabled(_onoff);
  }

  function ddSetMaxTxPercent(uint256 _maxTxPercent) external override onlyOwner {
      DRUNK.setMaxTxPercent(_maxTxPercent);
  }
  
  function ddTransferOwnership(address newOwner) external override onlyOwner {
      DRUNK.transferOwnership(newOwner);
  }
  
  function totalOwedDividends() public view override returns (uint256) {
      return owedDividends;
  }
  
  function unallocatedRewardTokens() public view override returns (uint256) {
      return DRUNK.balanceOf(address(this)).sub(owedDividends);
  }
}