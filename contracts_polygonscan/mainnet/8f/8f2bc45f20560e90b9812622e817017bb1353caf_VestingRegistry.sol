pragma solidity ^0.5.8;

import "./Token.sol";

/// @title Disbursement contract - allows to distribute tokens over time
/// @author Stefan George - <[email protected]>
contract Disbursement {

    /*
     *  Storage
     */
    address public receiver;
    address public wallet;
    uint public disbursementPeriod;
    uint public startDate;
    uint public withdrawnTokens;
    Token public token;

    /*
     *  Modifiers
     */
    modifier isReceiver() {
        if (msg.sender != receiver)
            revert("Only receiver is allowed to proceed");
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet)
            revert("Only wallet is allowed to proceed");
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Constructor function sets the wallet address, which is allowed to withdraw all tokens anytime
    /// @param _receiver Receiver of vested tokens
    /// @param _wallet Gnosis multisig wallet address
    /// @param _disbursementPeriod Vesting period in seconds
    /// @param _startDate Start date of disbursement period (cliff)
    /// @param _token ERC20 token used for the vesting
    constructor(address _receiver, address _wallet, uint _disbursementPeriod, uint _startDate, Token _token)
        public
    {
        if (_receiver == address(0) || _wallet == address(0) || _disbursementPeriod == 0 || address(_token) == address(0))
            revert("Arguments are null");
        receiver = _receiver;
        wallet = _wallet;
        disbursementPeriod = _disbursementPeriod;
        startDate = _startDate;
        token = _token;
        if (startDate == 0){
          startDate = now;
        }
    }

    /// @dev Transfers tokens to a given address
    /// @param _to Address of token receiver
    /// @param _value Number of tokens to transfer
    function withdraw(address _to, uint256 _value)
        public
        isReceiver
    {
        uint maxTokens = calcMaxWithdraw();
        if (_value > maxTokens){
          revert("Withdraw amount exceeds allowed tokens");
        }
        withdrawnTokens += _value;
        token.transfer(_to, _value);
    }

    /// @dev Transfers all tokens to multisig wallet
    function walletWithdraw()
        public
        isWallet
    {
        uint balance = token.balanceOf(address(this));
        withdrawnTokens += balance;
        token.transfer(wallet, balance);
    }

    /// @dev Calculates the maximum amount of vested tokens
    /// @return Number of vested tokens to withdraw
    function calcMaxWithdraw()
        public
        view
        returns (uint)
    {
        uint maxTokens = (token.balanceOf(address(this)) + withdrawnTokens) * (now - startDate) / disbursementPeriod;
        if (withdrawnTokens >= maxTokens || startDate > now){
          return 0;
        }
        return maxTokens - withdrawnTokens;
    }
}

/**
 *Submitted for verification at Etherscan.io on 2020-11-23
*/

// File: @gnosis.pm/util-contracts/contracts/Token.sol

/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
pragma solidity ^0.5.2;

/// @title Abstract token contract - Functions to be implemented by token contracts
contract Token {
    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function totalSupply() public view returns (uint);
}

pragma solidity ^0.5.8;

import "./Disbursement.sol";
import "./Token.sol";

contract VestingRegistry {

  address public admin;
  Token public token;
  mapping (address => Disbursement) internal vesting;


  event MemberAdded(address member, address vestingAddress);
  event MemberRemoved(address member);

  modifier isAdmin () {
    if (msg.sender != admin)
      revert("Only Admin is allowed to add Members");
    _; 
  }

  constructor (address _token) public {
    admin = msg.sender;
    token = Token(_token);
  }

  function addMember (address member, address vestingAddress) public isAdmin {
    Disbursement vcontract = Disbursement(vesting[member]);    
    if (address(vcontract) != address(0x0)) {
      // member already exists
      // TODO should I revert it here or overwrite the value?
      revert("member is already in the VestingRegistry");
    }
 
    vesting[member] = Disbursement(vestingAddress);
    emit MemberAdded(member, vestingAddress);
  }

  function removeMember (address member) public isAdmin {
    Disbursement vcontract = Disbursement(vesting[member]);
    if (address(vcontract) == address(0x0)) {
      revert("member is not part of the VestingRegistry");
    }

    vesting[member] = Disbursement(address(0x0));
    emit MemberRemoved(member);
  }

  function getVestingContract (address member) external view returns (address) {
    Disbursement vcontract = vesting[member];
    if (address(vcontract) == address(0x0)) {
      return address(0x0);
    }

    return address(vcontract);
  }

  function BalanceOf (address member) external view returns (uint) {
    Disbursement vcontract = vesting[member];
    if (address(vcontract) == address(0x0)) {
      revert("member is not part of the VestingRegistry");
    }
    
    return token.balanceOf(address(vcontract));
  }
}