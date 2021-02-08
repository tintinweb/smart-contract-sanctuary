// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./IERC20.sol";
import "./Owned.sol";
import "./IValidatorRegistration.sol";

/**
 * @title ValidatorRegistration
 * @dev Implements managing AvN stake and fees
 */
contract ValidatorRegistration2 is Owned {  
  // specifies the number of nodes availible to stake
  uint8 public constant NUM_NODES = 10;
  // specifies the number of months fees will be generated for
  uint8 public constant NUM_MONTHS = 12;

  // Data structure to represent each Aventus Node
  struct Node {
    // Amount deposited in stake for a node
    uint stake;
    // Fees associated with a node for each month
    Fee[NUM_MONTHS] fees;
    // Amount of stake associated with any particular staker
    mapping (address => uint) stakerBalance;
  }

  // Data structure to represent each month's worth of fees for a node
  struct Fee {
    // Total fees remaining to be distributed
    uint balance;
    // Which stakers have already withdrawn their fees for the month
    mapping (address => bool) isWithdrawn;
  }

  // address for the AVT token contract
  IERC20 public avt;
  // address for the Validator Registration token contract
  IValidatorRegistration public vr;
  // sets whether stake deposits or withdrawals are active
  bool public isWithdrawStake;
  // sets whether stake deposits or withdrawals are active
  bool public isWithdrawFees;
  // specifies the maximum amount of stake per node
  uint[NUM_NODES] public MAX_NODE_STAKE;
  // stores each of the 10 nodes
  Node[NUM_NODES] public nodes;

  /**
   * @dev Initilaise contract to point to AVT token.
   * @param _vr address of Validator Registration token contract
   */
  constructor(IValidatorRegistration _vr, IERC20 _avt) {
    vr = _vr;
    avt = _avt;
    isWithdrawStake = false;
    isWithdrawFees = false;
  }

  /**
   * @dev Getter for the stake associated with a node
   * @param node the index of the node associated with the AVT
   */
  function getNodeStake(uint8 node)
    external
    view
    returns (uint)
  {
    require(node <= 9, "Invalid node index specified");
    return nodes[node].stake;
  }

  /**
   * @dev Getter for the staker balance associated with a node
   * @param node the index of the node associated with the AVT
   * @param staker the address of the staker for which the balance is retrieved
   */
  function getStakerBalance(uint8 node, address staker)
    external
    view
    returns (uint)
  {
    require(node <= 9, "Invalid node index specified");
    require(staker != address(0x0), "Staker is null address");
    return nodes[node].stakerBalance[staker];
  }

  /**
   * @dev deposit AVT tokens for staking.
   * @param amount number of AVT tokens to be deposited as stake for a node
   * @param node the index of the node to associate the AVT stake with
   */
  function depositStakeAndAgreeToTermsAndConditions(uint amount, uint8 node)
    external
  {
    require(node <= 9, "Invalid node index specified");
    require(nodes[node].stake + amount <= MAX_NODE_STAKE[node], "Balance being deposited is too much for specified bucket");

    nodes[node].stake += amount;
    nodes[node].stakerBalance[msg.sender] += amount;

    require(avt.transferFrom(msg.sender, address(this), amount), "Approved insufficient funds for deposit");
  }

  /**
   * @dev withdraw AVT tokens from staking. Only active after the 12 month period, manually set by owner.
   * @param amount number of AVT tokens to be withdrawn from stake for a node
   * @param node the index of the node associated with the AVT stake
   */
  function withdrawStake(uint amount, uint8 node)
    external
  {
    require(node <= 9, "Invalid node index specified");
    require(isWithdrawStake, "Contract is not currently accepting withdrawals of stake");
    require(nodes[node].stakerBalance[msg.sender] >= amount, "Balance being withdrawn is too much for msg.sender");

    nodes[node].stake -= amount;
    nodes[node].stakerBalance[msg.sender] -= amount;

    require(avt.transfer(msg.sender, amount), "Insufficient contract AVT balance to withdraw stake");
  }

  /**
   * @dev deposit AVT fees associated with each node for each month in the Validator registration contract. 
   * @param node the index of the node having the fees deposited
   * @param month the month for which the fees are being deposited
   */
  function depositFees(uint8 node, uint8 month)
    external
  {
    require(node <= 9, "Invalid node index specified");
    require(month <= 12, "Invalid month specified");

    uint amount = avt.balanceOf(address(this));

    vr.withdrawFees(node, month);

    nodes[node].fees[month].balance += avt.balanceOf(address(this)) - amount;
  }

  /**
   * @dev withdraw AVT fees associated with each node for each month for a particular staker.
   * @param node the index of the node from which fees are being withdrawn
   * @param month the month for which the fees are being withdrawn
   */
  function withdrawFees(uint8 node, uint8 month)
    external
  {
    require(node <= 9, "Invalid node index specified");
    require(month <= 12, "Invalid month specified");
    require(isWithdrawFees, "Contract is not currently accepting withdrawals of fees");

    require(!nodes[node].fees[month].isWithdrawn[msg.sender], "Transaction sender is not owed any fees for specified node and month");

    // Safe for integer overflow. fee.balance is always < 100,000e18, staker balance is always < 250,000e18, node.stake is always 250,000e18.
    uint amount = nodes[node].fees[month].balance * nodes[node].stakerBalance[msg.sender] / nodes[node].stake;

    // Safe from underflow
    require(amount > 0, "No amount to be withdrawn");

    nodes[node].fees[month].balance -= amount;
    nodes[node].fees[month].isWithdrawn[msg.sender] = true;

    require(avt.transfer(msg.sender, amount), "Contract has insufficient funds for withdrawal");
  }

  /**
   * @dev add AVT tokens to staking.
   * @param amount number of AVT tokens to be deposited as stake for a node
   * @param node the index of the node associated with the AVT stake
   */

  function stakeInValidatorRegistration(uint8 node, uint amount) 
    external
    onlyOwner
  {
    require(node <= 9, "Invalid node index specified");
    require(avt.approve(address(vr), amount), "Specified amount of AVT cannot be approved");

    vr.depositStakeAndAgreeToTermsAndConditions(amount, node);
  }

  /**
   * @dev Switch between (not) accepting withdrawals of stake.
   * Only owner can do this and will do so at the end of NUM_MONTHS to return stake.
   */
  function flipIsWithdrawStake()
    external
    onlyOwner
  {
    isWithdrawStake = !isWithdrawStake;
  }

  /**
   * @dev Switch between (not) accepting withdrawals of fees.
   * Only owner can do this and will do so at the end of staking phase.
   */
  function flipIsWithdrawFees()
    external
    onlyOwner
  {
    isWithdrawFees = !isWithdrawFees;
  }

  /**
   * @dev Setter for the maximum stake associated with a node
   * @param node the index of the node associated with the AVT
   * @param amount[10] the maximum stake associated with nodes at indeces
   */
  function setMaxNodeStake(uint8 node, uint amount)
    external
    onlyOwner
  {
    require(node <= 9, "Invalid node index specified");
    require(amount <= 250000 ether, "Invalid amount specified");
    MAX_NODE_STAKE[node] = amount;
  }

  /**
   * @dev Remove the balance of AVT associated with a staker.
   * @param staker the address of the staker
   * @param node the index of the node
   */
  function removeStaker(address staker, uint8 node)
    external
    onlyOwner
  {
    require(staker != address(0x0), "Staker is null address");
    require(node <= 9, "Invalid node index specified");

    // Update total stake associated with a node
    nodes[node].stake -= nodes[node].stakerBalance[staker];

    // Update staker avt
    nodes[node].stakerBalance[staker] = 0;
  }

   /**
   * @dev Sends AVT associated with this contract to the dst address. Only owner can do this to get stake for nodes.
   * @param dst is the destination address where the stake should be sent
   */
  function drain(address dst)
    external
    onlyOwner
  {
    require(dst != address(0x0), "dst is null address");
    require(avt.transfer(dst, avt.balanceOf(address(this))), "AVT transfer failed");
  }
}