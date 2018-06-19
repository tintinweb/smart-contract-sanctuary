pragma solidity ^0.4.11;

/*
  Copyright 2017, Anton Egorov (Mothership Foundation)
  Copyright 2017, Klaus Hott (BlockchainLabs.nz)
  Copyright 2017, Jorge Izquierdo (Aragon Foundation)
  Copyright 2017, Jordi Baylina (Giveth)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract Controlled {
  /// @notice The address of the controller is the only address that can call
  ///  a function with this modifier
  modifier onlyController { if (msg.sender != controller) throw; _; }

  address public controller;

  function Controlled() { controller = msg.sender;}

  /// @notice Changes the controller of the contract
  /// @param _newController The new controller of the contract
  function changeController(address _newController) onlyController {
    controller = _newController;
  }
}

contract Refundable {
  function refund(address th, uint amount) returns (bool);
}

/// @dev The token controller contract must implement these functions
contract TokenController {
  /// @notice Called when `_owner` sends ether to the MiniMe Token contract
  /// @param _owner The address that sent the ether to create tokens
  /// @return True if the ether is accepted, false if it throws
  function proxyPayment(address _owner) payable returns(bool);

  /// @notice Notifies the controller about a token transfer allowing the
  ///  controller to react if desired
  /// @param _from The origin of the transfer
  /// @param _to The destination of the transfer
  /// @param _amount The amount of the transfer
  /// @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount) returns(bool);

  /// @notice Notifies the controller about an approval allowing the
  ///  controller to react if desired
  /// @param _owner The address that calls `approve()`
  /// @param _spender The spender in the `approve()` call
  /// @param _amount The amount in the `approve()` call
  /// @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount)
    returns(bool);
}

contract ERC20Token {
  /* This is a slight change to the ERC20 base standard.
     function totalSupply() constant returns (uint256 supply);
     is replaced with:
     uint256 public totalSupply;
     This automatically creates a getter function for the totalSupply.
     This is moved to the base contract since public getter functions are not
     currently recognised as an implementation of the matching abstract
     function by the compiler.
  */
  /// total amount of tokens
  function totalSupply() constant returns (uint256 balance);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Burnable is Controlled {
  /// @notice The address of the controller is the only address that can call
  ///  a function with this modifier, also the burner can call but also the
  /// target of the function must be the burner
  modifier onlyControllerOrBurner(address target) {
    assert(msg.sender == controller || (msg.sender == burner && msg.sender == target));
    _;
  }

  modifier onlyBurner {
    assert(msg.sender == burner);
    _;
  }
  address public burner;

  function Burnable() { burner = msg.sender;}

  /// @notice Changes the burner of the contract
  /// @param _newBurner The new burner of the contract
  function changeBurner(address _newBurner) onlyBurner {
    burner = _newBurner;
  }
}

contract MiniMeTokenI is ERC20Token, Burnable {

      string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
      uint8 public decimals;             //Number of decimals of the smallest unit
      string public symbol;              //An identifier: e.g. REP
      string public version = &#39;MMT_0.1&#39;; //An arbitrary versioning scheme

///////////////////
// ERC20 Methods
///////////////////


    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) returns (bool success);

////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(
        address _owner,
        uint _blockNumber
    ) constant returns (uint);

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) constant returns(uint);

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
    ) returns(address);

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) returns (bool);


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) returns (bool);

////////////////
// Enable tokens transfers
////////////////

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled);

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token);

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}

contract Finalizable {
  uint256 public finalizedBlock;
  bool public goalMet;

  function finalize();
}

contract Contribution is Controlled, TokenController, Finalizable {
  using SafeMath for uint256;

  uint256 public totalSupplyCap; // Total MSP supply to be generated
  uint256 public exchangeRate; // ETH-MSP exchange rate
  uint256 public totalSold; // How much tokens sold
  uint256 public totalSaleSupplyCap; // Token sale cap

  MiniMeTokenI public sit;
  MiniMeTokenI public msp;

  uint256 public startBlock;
  uint256 public endBlock;

  address public destEthDevs;
  address public destTokensSit;
  address public destTokensTeam;
  address public destTokensReferals;

  address public mspController;

  uint256 public initializedBlock;
  uint256 public finalizedTime;

  uint256 public minimum_investment;
  uint256 public minimum_goal;

  bool public paused;

  modifier initialized() {
    assert(address(msp) != 0x0);
    _;
  }

  modifier contributionOpen() {
    assert(getBlockNumber() >= startBlock &&
            getBlockNumber() <= endBlock &&
            finalizedBlock == 0 &&
            address(msp) != 0x0);
    _;
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  function Contribution() {
    // Booleans are false by default consider removing this
    paused = false;
  }

  /// @notice This method should be called by the controller before the contribution
  ///  period starts This initializes most of the parameters
  /// @param _msp Address of the MSP token contract
  /// @param _mspController Token controller for the MSP that will be transferred after
  ///  the contribution finalizes.
  /// @param _totalSupplyCap Maximum amount of tokens to generate during the contribution
  /// @param _exchangeRate ETH to MSP rate for the token sale
  /// @param _startBlock Block when the contribution period starts
  /// @param _endBlock The last block that the contribution period is active
  /// @param _destEthDevs Destination address where the contribution ether is sent
  /// @param _destTokensSit Address of the exchanger SIT-MSP where the MSP are sent
  ///  to be distributed to the SIT holders.
  /// @param _destTokensTeam Address where the tokens for the team are sent
  /// @param _destTokensReferals Address where the tokens for the referal system are sent
  /// @param _sit Address of the SIT token contract
  function initialize(
      address _msp,
      address _mspController,

      uint256 _totalSupplyCap,
      uint256 _exchangeRate,
      uint256 _minimum_goal,

      uint256 _startBlock,
      uint256 _endBlock,

      address _destEthDevs,
      address _destTokensSit,
      address _destTokensTeam,
      address _destTokensReferals,

      address _sit
  ) public onlyController {
    // Initialize only once
    assert(address(msp) == 0x0);

    msp = MiniMeTokenI(_msp);
    assert(msp.totalSupply() == 0);
    assert(msp.controller() == address(this));
    assert(msp.decimals() == 18);  // Same amount of decimals as ETH

    require(_mspController != 0x0);
    mspController = _mspController;

    require(_exchangeRate > 0);
    exchangeRate = _exchangeRate;

    assert(_startBlock >= getBlockNumber());
    require(_startBlock < _endBlock);
    startBlock = _startBlock;
    endBlock = _endBlock;

    require(_destEthDevs != 0x0);
    destEthDevs = _destEthDevs;

    require(_destTokensSit != 0x0);
    destTokensSit = _destTokensSit;

    require(_destTokensTeam != 0x0);
    destTokensTeam = _destTokensTeam;

    require(_destTokensReferals != 0x0);
    destTokensReferals = _destTokensReferals;

    require(_sit != 0x0);
    sit = MiniMeTokenI(_sit);

    initializedBlock = getBlockNumber();
    // SIT amount should be no more than 20% of MSP total supply cap
    assert(sit.totalSupplyAt(initializedBlock) * 5 <= _totalSupplyCap);
    totalSupplyCap = _totalSupplyCap;

    // We are going to sale 70% of total supply cap
    totalSaleSupplyCap = percent(70).mul(_totalSupplyCap).div(percent(100));

    minimum_goal = _minimum_goal;
  }

  function setMinimumInvestment(
      uint _minimum_investment
  ) public onlyController {
    minimum_investment = _minimum_investment;
  }

  function setExchangeRate(
      uint _exchangeRate
  ) public onlyController {
    assert(getBlockNumber() < startBlock);
    exchangeRate = _exchangeRate;
  }

  /// @notice If anybody sends Ether directly to this contract, consider he is
  ///  getting MSPs.
  function () public payable notPaused {
    proxyPayment(msg.sender);
  }


  //////////
  // TokenController functions
  //////////

  /// @notice This method will generally be called by the MSP token contract to
  ///  acquire MSPs. Or directly from third parties that want to acquire MSPs in
  ///  behalf of a token holder.
  /// @param _th MSP holder where the MSPs will be minted.
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
    require(_th != 0x0);
    doBuy(_th);
    return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
    return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
    return false;
  }

  function doBuy(address _th) internal {
    require(msg.value >= minimum_investment);

    // Antispam mechanism
    address caller;
    if (msg.sender == address(msp)) {
      caller = _th;
    } else {
      caller = msg.sender;
    }

    // Do not allow contracts to game the system
    assert(!isContract(caller));

    uint256 toFund = msg.value;
    uint256 leftForSale = tokensForSale();
    if (toFund > 0) {
      if (leftForSale > 0) {
        uint256 tokensGenerated = toFund.mul(exchangeRate);

        // Check total supply cap reached, sell the all remaining tokens
        if (tokensGenerated > leftForSale) {
          tokensGenerated = leftForSale;
          toFund = leftForSale.div(exchangeRate);
        }

        assert(msp.generateTokens(_th, tokensGenerated));
        totalSold = totalSold.add(tokensGenerated);
        if (totalSold >= minimum_goal) {
          goalMet = true;
        }
        destEthDevs.transfer(toFund);
        NewSale(_th, toFund, tokensGenerated);
      } else {
        toFund = 0;
      }
    }

    uint256 toReturn = msg.value.sub(toFund);
    if (toReturn > 0) {
      // If the call comes from the Token controller,
      // then we return it to the token Holder.
      // Otherwise we return to the sender.
      if (msg.sender == address(msp)) {
        _th.transfer(toReturn);
      } else {
        msg.sender.transfer(toReturn);
      }
    }
  }

  /// @dev Internal function to determine if an address is a contract
  /// @param _addr The address being queried
  /// @return True if `_addr` is a contract
  function isContract(address _addr) constant internal returns (bool) {
    if (_addr == 0) return false;
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  function refund() public {
    require(finalizedBlock != 0);
    require(!goalMet);

    uint256 amountTokens = msp.balanceOf(msg.sender);
    require(amountTokens > 0);
    uint256 amountEther = amountTokens.div(exchangeRate);
    address th = msg.sender;

    Refundable(mspController).refund(th, amountTokens);
    Refundable(destEthDevs).refund(th, amountEther);

    Refund(th, amountTokens, amountEther);
  }

  event Refund(address _token_holder, uint256 _amount_tokens, uint256 _amount_ether);

  /// @notice This method will can be called by the controller before the contribution period
  ///  end or by anybody after the `endBlock`. This method finalizes the contribution period
  ///  by creating the remaining tokens and transferring the controller to the configured
  ///  controller.
  function finalize() public initialized {
    assert(getBlockNumber() >= startBlock);
    assert(msg.sender == controller || getBlockNumber() > endBlock || tokensForSale() == 0);
    require(finalizedBlock == 0);

    finalizedBlock = getBlockNumber();
    finalizedTime = now;

    if (goalMet) {
      // Generate 5% for the team
      assert(msp.generateTokens(
        destTokensTeam,
        percent(5).mul(totalSupplyCap).div(percent(100))));

      // Generate 5% for the referal bonuses
      assert(msp.generateTokens(
        destTokensReferals,
        percent(5).mul(totalSupplyCap).div(percent(100))));

      // Generate tokens for SIT exchanger
      assert(msp.generateTokens(
        destTokensSit,
        sit.totalSupplyAt(initializedBlock)));
    }

    msp.changeController(mspController);
    Finalized();
  }

  function percent(uint256 p) internal returns (uint256) {
    return p.mul(10**16);
  }


  //////////
  // Constant functions
  //////////

  /// @return Total tokens issued in weis.
  function tokensIssued() public constant returns (uint256) {
    return msp.totalSupply();
  }

  /// @return Total tokens availale for the sale in weis.
  function tokensForSale() public constant returns(uint256) {
    return totalSaleSupplyCap > totalSold ? totalSaleSupplyCap - totalSold : 0;
  }


  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }


  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyController {
    if (msp.controller() == address(this)) {
      msp.claimTokens(_token);
    }
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token token = ERC20Token(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }


  /// @notice Pauses the contribution if there is any issue
  function pauseContribution() onlyController {
    paused = true;
  }

  /// @notice Resumes the contribution
  function resumeContribution() onlyController {
    paused = false;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event Finalized();
}

/// @title MSPPlaceholder Contract
/// @author Jordi Baylina
/// @dev The MSPPlaceholder contract will take control over the MSP after the contribution
///  is finalized and before the Mothership Network is deployed.
///  The contract allows for MSP transfers and transferFrom and implements the
///  logic for transferring control of the token to the network when the offering
///  asks it to do so.

contract MSPPlaceHolder is Controlled, TokenController, Refundable {
  using SafeMath for uint256;

  MiniMeTokenI public msp;
  Contribution public contribution;

  uint256 public activationTime;
  address public sitExchanger;

  /// @notice Constructor
  /// @param _controller Trusted controller for this contract.
  /// @param _msp MSP token contract address
  /// @param _contribution Contribution contract address
  /// @param _sitExchanger SIT-MSP Exchange address. (During the first day
  ///  only this exchanger will be able to move tokens)
  function MSPPlaceHolder(address _controller, address _msp, address _contribution, address _sitExchanger) {
    controller = _controller;
    msp = MiniMeTokenI(_msp);
    contribution = Contribution(_contribution);
    sitExchanger = _sitExchanger;
  }

  /// @notice The controller of this contract can change the controller of the MSP token
  ///  Please, be sure that the controller is a trusted agent or 0x0 address.
  /// @param _newController The address of the new controller

  function changeController(address _newController) public onlyController {
    msp.changeController(_newController);
    ControllerChanged(_newController);
  }

  function refund(address th, uint amount) returns (bool) {
    assert(msg.sender == address(contribution));
    msp.destroyTokens(th, amount);
    return true;
  }

  //////////
  // MiniMe Controller Interface functions
  //////////

  // In between the offering and the network. Default settings for allowing token transfers.
  function proxyPayment(address) public payable returns (bool) {
    return false;
  }

  function onTransfer(address _from, address, uint256) public returns (bool) {
    return transferable(_from);
  }

  function onApprove(address _from, address, uint256) public returns (bool) {
    return transferable(_from);
  }

  function transferable(address _from) internal returns (bool) {
    if (!contribution.goalMet()) return false;
    // Allow the exchanger to work from the beginning
    if (activationTime == 0) {
      uint256 f = contribution.finalizedTime();
      if (f > 0) {
        activationTime = f.add(24 hours);
      } else {
        return false;
      }
    }
    return (getTime() > activationTime) || (_from == sitExchanger);
  }


  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getTime() internal returns (uint256) {
    return now;
  }


  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyController {
    if (msp.controller() == address(this)) {
      msp.claimTokens(_token);
    }
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token token = ERC20Token(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event ControllerChanged(address indexed _newController);
}