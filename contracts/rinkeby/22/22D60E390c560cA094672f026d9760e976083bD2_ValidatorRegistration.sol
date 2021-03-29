/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// File: contracts\interfaces\IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

// As described in https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts\Owned.sol


pragma solidity 0.7.5;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: ..\contracts\ValidatorRegistration.sol



pragma solidity 0.7.5;

/**
 * @title ValidatorRegistration
 * @dev Implements managing AvN stake and fees
 */
contract ValidatorRegistration is Owned {

  // specifies the maximum amount of stake per node
  uint public constant MAX_NODE_STAKE = 250000 ether;
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
  // sets whether stake deposits or withdrawals are active
  bool public isWithdrawStake;
  // stores each of the 10 nodes
  Node[NUM_NODES] public nodes;

  /**
   * @dev Initilaise contract to point to AVT token.
   * @param _avt address of AVT token contract
   */
  constructor(IERC20 _avt) {
    avt = _avt;
    isWithdrawStake = false;
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
    require(nodes[node].stake + amount <= MAX_NODE_STAKE, "Balance being deposited is too much for specified bucket");

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
    require(isWithdrawStake, "Contract is not currently accepting withdrawals of stake");
    require(nodes[node].stakerBalance[msg.sender] >= amount, "Balance being withdrawn is too much for msg.sender");

    nodes[node].stake -= amount;
    nodes[node].stakerBalance[msg.sender] -= amount;

    require(avt.transfer(msg.sender, amount), "Insufficient contract AVT balance to withdraw stake");
  }

  /**
   * @dev deposit AVT fees associated with each node for each month. Anyone can deposit fees but likely will only be owner.
   * @param amount number of AVT tokens to be deposited as fees
   * @param node the index of the node having the fees deposited
   * @param month the month for which the fees are being deposited
   */
  function depositFees(uint amount, uint8 node, uint8 month)
    external
  {
    nodes[node].fees[month].balance += amount;

    require(avt.transferFrom(msg.sender, address(this), amount), "Approved insufficient funds for deposit");
  }

  /**
   * @dev withdraw AVT fees associated with each node for each month for a particular staker.
   * @param _node the index of the node from which fees are being withdrawn
   * @param month the month for which the fees are being withdrawn
   */
  function withdrawFees(uint8 _node, uint8 month)
    external
  {
    Node storage node = nodes[_node];
    Fee storage fee = node.fees[month];

    require(!fee.isWithdrawn[msg.sender], "Transaction sender is not owed any fees for specified node and month");

    // Safe for integer overflow. fee.balance is always < 100,000e18, staker balance is always < 250,000e18, node.stake is always 250,000e18.
    uint amount = fee.balance * node.stakerBalance[msg.sender] / node.stake;

    // Safe from underflow
    require(amount > 0, "No amount to be withdrawn");

    fee.balance -= amount;
    fee.isWithdrawn[msg.sender] = true;

    require(avt.transfer(msg.sender, amount), "Contract has insufficient funds for withdrawal");
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
   * @dev Remove the balance of AVT associated with a staker.
   * @param staker the address of the staker
   * @param _node the index of the node
   */
  function removeStaker(address staker, uint8 _node)
    external
    onlyOwner
  {
    Node storage node = nodes[_node];

    // Update total stake associated with a node
    node.stake -= node.stakerBalance[staker];

    // Update staker avt
    node.stakerBalance[staker] = 0;
  }

   /**
   * @dev Sends AVT associated with this contract to the dst address. Only owner can do this to get stake for nodes.
   * @param dst is the destination address where the stake should be sent
   */
  function drain(address dst)
    external
    onlyOwner
  {
    require(avt.transfer(dst, avt.balanceOf(address(this))));
  }
}