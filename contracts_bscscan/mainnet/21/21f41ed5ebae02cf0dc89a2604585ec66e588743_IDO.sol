// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract IDO is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeBEP20 for IBEP20;

  // Info of each user.
  struct UserInfo {
    uint256 amount;   // How many tokens the user has provided.
    bool claimed;  // default false
  }

  // admin address
  address public adminAddress;
  // The raising token
  IBEP20 public lpToken;
  // The offering token
  IBEP20 public offeringToken;
  // The block number when IFO starts
  uint256 public startBlock;
  // The block number when IFO ends
  uint256 public endBlock;
  // total amount of raising tokens need to be raised
  uint256 public raisingAmount;
  // total amount of offeringToken that will offer
  uint256 public offeringAmount;
  // total amount of raising tokens that have already raised
  uint256 public totalAmount;
  // address => amount
  mapping(address => UserInfo) public userInfo;
  // participators
  address[] public addressList;
  // final withdraw to address
  address public withdrawAddress;


  event Deposit(address indexed user, uint256 amount);
  event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount);

  constructor(
    IBEP20 _lpToken,
    IBEP20 _offeringToken,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _offeringAmount,
    uint256 _raisingAmount,
    address _adminAddress,
    address _withdrawAddress
  ) public {
    lpToken = _lpToken;
    offeringToken = _offeringToken;
    startBlock = _startBlock;
    endBlock = _endBlock;
    offeringAmount = _offeringAmount;
    raisingAmount = _raisingAmount;
    totalAmount = 0;
    adminAddress = _adminAddress;
    withdrawAddress = _withdrawAddress;
  }

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "admin: wut?");
    _;
  }

  function setOfferingAmount(uint256 _offerAmount) public onlyAdmin {
    require(block.number < startBlock, 'no');
    offeringAmount = _offerAmount;
  }

  function setRaisingAmount(uint256 _raisingAmount) public onlyAdmin {
    require(block.number < endBlock, 'no');
    raisingAmount = _raisingAmount;
  }

  function setBlocks(uint256 _startBlock, uint256 _endBlock) external onlyAdmin {
    require(block.number < startBlock, 'no');
    startBlock = _startBlock;
    endBlock = _endBlock;
  }

  function deposit(uint256 _amount) public nonReentrant {
    require(block.number > startBlock && block.number < endBlock, 'not ifo time');
    require(_amount > 0, 'need _amount > 0');
    lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
    totalAmount = totalAmount.add(_amount);
    emit Deposit(msg.sender, _amount);
  }

  function harvest() public nonReentrant {
    require(block.number > endBlock, 'not harvest time');
    require(userInfo[msg.sender].amount > 0, 'have you participated?');
    require(!userInfo[msg.sender].claimed, 'nothing to harvest');
    uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
    uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
    if (offeringTokenAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
    }
    if (refundingTokenAmount > 0) {
      lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
    }
    userInfo[msg.sender].claimed = true;
    emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount);
  }

  function hasHarvest(address _user) external view returns (bool) {
    return userInfo[_user].claimed;
  }

  // allocation 100000 means 0.1(10%), 1 means 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns (uint256) {
    return userInfo[_user].amount.mul(1e12).div(totalAmount).div(1e6);
  }

  // get the amount of IFO token you will get
  function getOfferingAmount(address _user) public view returns (uint256) {
    if (totalAmount > raisingAmount) {
      uint256 allocation = getUserAllocation(_user);
      return offeringAmount.mul(allocation).div(1e6);
    }
    else {
      // userInfo[_user] / (raisingAmount / offeringAmount)
      return userInfo[_user].amount.mul(offeringAmount).div(raisingAmount);
    }
  }

  // get the amount of lp token you will be refunded
  function getRefundingAmount(address _user) public view returns (uint256) {
    if (totalAmount <= raisingAmount) {
      return 0;
    }
    uint256 allocation = getUserAllocation(_user);
    uint256 payAmount = raisingAmount.mul(allocation).div(1e6);
    return userInfo[_user].amount.sub(payAmount);
  }

  function getAddressListLength() external view returns (uint256) {
    return addressList.length;
  }

  function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) public onlyAdmin {
    require(_lpAmount <= lpToken.balanceOf(address(this)), 'not enough token 0');
    require(_offerAmount <= offeringToken.balanceOf(address(this)), 'not enough token 1');
    if (_offerAmount > 0) {
      offeringToken.safeTransfer(withdrawAddress, _offerAmount);
    }
    if (_lpAmount > 0) {
      lpToken.safeTransfer(withdrawAddress, _lpAmount);
    }
  }
}