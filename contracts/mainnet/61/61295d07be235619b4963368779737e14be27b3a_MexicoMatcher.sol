pragma solidity ^0.4.13;
/*
    Copyright 2017, Griff Green

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of BasicToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/// @dev `Escapable` is a base level contract for and contract that wants to
///  add an escape hatch for a contract that holds ETH or ERC20 tokens. This
///  contract creates an `escapeHatch()` function to send its `baseTokens` to
///  `escapeHatchDestination` when called by the `escapeHatchCaller` in the case that
///  something unexpected happens
contract Escapable {
    BasicToken public baseToken;

    address public escapeHatchCaller;
    address public escapeHatchDestination;

    /// @notice The Constructor assigns the `escapeHatchDestination`, the
    ///  `escapeHatchCaller`, and the `baseToken`
    /// @param _baseToken The address of the token that is used as a store value
    ///  for this contract, 0x0 in case of ether. The token must have the ERC20
    ///  standard `balanceOf()` and `transfer()` functions
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the `baseToken` held in this contract
    /// @param _escapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the `baseToken` in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    /// cannot move funds out of `escapeHatchDestination`
    function Escapable(
        address _baseToken,
        address _escapeHatchCaller,
        address _escapeHatchDestination) {
        baseToken = BasicToken(_baseToken);
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned the `escapeHatchCaller` role
    ///  is the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCaller {
        require (msg.sender == escapeHatchCaller);
        _;
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    function escapeHatch() onlyEscapeHatchCaller {
        uint total = getBalance();
        // Send the total balance of this contract to the `escapeHatchDestination`
        transfer(escapeHatchDestination, total);
        EscapeHatchCalled(total);
    }
    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller` cannot
    ///  move funds out of `escapeHatchDestination`
    function changeEscapeHatchCaller(address _newEscapeHatchCaller
        ) onlyEscapeHatchCaller 
    {
        escapeHatchCaller = _newEscapeHatchCaller;
        EscapeHatchCallerChanged(escapeHatchCaller);
    }
    /// @notice Returns the balance of the `baseToken` stored in this contract
    function getBalance() constant returns(uint) {
        if (address(baseToken) != 0) {
            return baseToken.balanceOf(this);
        } else {
            return this.balance;
        }
    }
    /// @notice Sends an `_amount` of `baseToken` to `_to` from this contract,
    /// and it can only be called by the contract itself
    /// @param _to The address of the recipient
    /// @param _amount The amount of `baseToken to be sent
    function transfer(address _to, uint _amount) internal {
        if (address(baseToken) != 0) {
            require (baseToken.transfer(_to, _amount));
        } else {
            require ( _to.send(_amount));
        }
    }


//////
// Receive Ether
//////

    /// @notice Called anytime ether is sent to the contract && creates an event
    /// to more easily track the incoming transactions
    function receiveEther() payable {
        // Do not accept ether if baseToken is not ETH
        require (address(baseToken) == 0);
        EtherReceived(msg.sender, msg.value);
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyEscapeHatchCaller {
        if (_token == 0x0) {
            escapeHatchDestination.transfer(this.balance);
            return;
        }

        BasicToken token = BasicToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(escapeHatchDestination, balance);
        ClaimedTokens(_token, escapeHatchDestination, balance);
    }

    /// @notice The fall back function is called whenever ether is sent to this
    ///  contract
    function () payable {
        receiveEther();
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event EscapeHatchCalled(uint amount);
    event EscapeHatchCallerChanged(address indexed newEscapeHatchCaller);
    event EtherReceived(address indexed from, uint amount);
}

/// @title Mexico Matcher
/// @author Vojtech Simetka, Jordi Baylina, Dani Philia, Arthur Lunn, Griff Green
/// @notice This contract is used to match donations inspired by the generosity
///  of Bitso:  
///  The escapeHatch allows removal of any other tokens deposited by accident.


/// @dev The main contract which forwards funds sent to contract.
contract MexicoMatcher is Escapable {
    address public beneficiary; // expected to be a Giveth campaign

    /// @notice The Constructor assigns the `beneficiary`, the
    ///  `escapeHatchDestination` and the `escapeHatchCaller` as well as deploys
    ///  the contract to the blockchain (obviously)
    /// @param _beneficiary The address that will receive donations
    /// @param _escapeHatchDestination The address of a safe location (usually a
    ///  Multisig) to send the ether deposited to be matched in this contract if
    ///  there is an issue
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the 
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    function MexicoMatcher(
            address _beneficiary, // address that receives ether
            address _escapeHatchCaller,
            address _escapeHatchDestination
        )
        // Set the escape hatch to accept ether (0x0)
        Escapable(0x0, _escapeHatchCaller, _escapeHatchDestination)
    {
        beneficiary = _beneficiary;
    }
    
    /// @notice Simple function to deposit more ETH to match future donations
    function depositETH() payable {
        DonationDeposited4Matching(msg.sender, msg.value);
    }
    /// @notice Donate ETH to the `beneficiary`, and if there is enough in the 
    ///  contract double it. The `msg.sender` is rewarded with Campaign tokens;
    ///  This contract may have a high gasLimit requirement
    function () payable {
        uint256 amount;
        
        // If there is enough ETH in the contract to double it, DOUBLE IT!
        if (this.balance >= msg.value*2){
            amount = msg.value*2; // do it two it!
        
            // Send ETH to the beneficiary; must be an account, not a contract
            require (beneficiary.send(amount));
            DonationMatched(msg.sender, amount);
        } else {
            amount = this.balance;
            require (beneficiary.send(amount));
            DonationSentButNotMatched(msg.sender, amount);
        }
    }
    event DonationDeposited4Matching(address indexed sender, uint amount);
    event DonationMatched(address indexed sender, uint amount);
    event DonationSentButNotMatched(address indexed sender, uint amount);
}