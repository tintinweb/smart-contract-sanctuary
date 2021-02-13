/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface IFenumCrowdsale {
  function launch(bool status) external returns (bool);
  function setRate(uint256 rate_) external returns (bool);
  function setWallet(address wallet_) external returns (bool);
  function tokensDeposit(uint256 amount) external returns (bool);
  function tokensWithdraw(uint256 amount) external returns (bool);
  function tokensTransfer(uint256 amount) external returns (bool);
}

interface IFenumVesting {
  function drawDown() external returns (bool);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}


contract FenumDevPool is Context {
  using SafeMath for uint256;
  address[] private _approvers;
  uint256 private _threshold;
  address private _token;
  address private _vesting;
  address private _crowdsale;

  struct Transfer {
    uint256 id;
    uint256 approvals;
    bool sent;
    address token;
    uint256 amount;
    address payable to;
  }

  Transfer[] public transfers;
  mapping(address => mapping(uint256 => bool)) private _approvals;

  event TransferCreated(uint256 indexed id, uint256 approvals, bool sent, address indexed token, uint256 amount, address indexed to);
  event TransferExecuted(uint256 indexed id, uint256 approvals, bool sent, address indexed token, uint256 amount, address indexed to);
  event ApprovershipTransferred(address indexed previousApprover, address indexed newApprover);

  constructor(address[] memory approvers_, uint threshold_, address token_) public {
    _approvers = approvers_;
    _threshold = threshold_;
    _token = token_;
  }

  function balance(address token) public view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function crowdsale() public view returns (address) {
    return _crowdsale;
  }

  function setCrowdsale(address crowdsale_) public onlyApprover returns (bool) {
    require(crowdsale_ != address(0), "FenumDevPool: New crowdsale is the zero address");
    _crowdsale = crowdsale_;
    return true;
  }

  function crowdsaleSetRate(bool status) public onlyApprover returns (bool) {
    return IFenumCrowdsale(_crowdsale).launch(status);
  }

  function crowdsaleSetRate(uint256 rate_) public onlyApprover returns (bool) {
    return IFenumCrowdsale(_crowdsale).setRate(rate_);
  }

  function crowdsaleSetWallet() public onlyApprover returns (bool) {
    return IFenumCrowdsale(_crowdsale).setWallet(address(this));
  }

  function crowdsaleTokensDeposit(uint256 amount) public onlyApprover returns (bool) {
    IERC20(_token).approve(_crowdsale, amount);
    return IFenumCrowdsale(_crowdsale).tokensDeposit(amount);
  }

  function crowdsaleTokensWithdraw(uint256 amount) public onlyApprover returns (bool) {
    return IFenumCrowdsale(_crowdsale).tokensWithdraw(amount);
  }

  function crowdsaleTokensTransfer(uint256 amount) public onlyApprover returns (bool) {
    return IFenumCrowdsale(_crowdsale).tokensTransfer(amount);
  }

  function vesting() public view returns (address) {
    return _vesting;
  }

  function setVesting(address vesting_) public onlyApprover returns (bool) {
    require(vesting_ != address(0), "FenumDevPool: New vesting is the zero address");
    _vesting = vesting_;
    return true;
  }

  function vestingDrawDown() public {
    IFenumVesting(_vesting).drawDown();
  }

  function threshold() public view returns(uint256) {
    return _threshold;
  }

  function approver(uint256 id) public view returns(address) {
    return _approvers[id];
  }

  function approvers() public view returns(address[] memory) {
    return _approvers;
  }

  function approversLength() public view returns (uint256) {
    return _approvers.length;
  }

  function transfer(uint256 id) public view returns(Transfer memory) {
    return transfers[id];
  }

  function transfersLength() public view returns (uint256) {
    return transfers.length;
  }

  function createTransferETH(uint256 amount, address payable to) external onlyApprover returns (uint256) {
    return _createTransfer(address(0), amount, to);
  }

  function createTransferERC20(address token, uint256 amount, address payable to) external onlyApprover returns (uint256) {
    return _createTransfer(token, amount, to);
  }

  function approveTransfer(uint256 id) public onlyApprover returns (bool) {
    address msgSender = _msgSender();
    require(transfers[id].sent == false, "FenumDevPool: Transfer has already sent");
    require(_approvals[msgSender][id] == false, "FenumDevPool: Cannot approve transfer twice");
    _approvals[msgSender][id] = true;
    transfers[id].approvals = transfers[id].approvals.add(1);
    return true;
  }

  function executeTransfer(uint256 id) public onlyApprover returns (bool) {
    if (transfers[id].approvals >= _threshold) {
      if (transfers[id].token == address(0)) {
        require(_executeTransferETH(id), "FenumDevPool: Failed to transfer Ethers");
      } else {
        require(_executeTransferERC20(id), "FenumDevPool: Failed to transfer ERC20 tokens");
      }
      transfers[id].sent = true;
      emit TransferExecuted(transfers[id].id, transfers[id].approvals, transfers[id].sent, transfers[id].token, transfers[id].amount, transfers[id].to);
      return true;
    }
    return false;
  }

  function transferApprovership(address newApprover) public virtual {
    require(newApprover != address(0), "FenumDevPool: New approver is the zero address");
    (bool allowed, uint256 index) = _approverIndex(_msgSender());
    require(allowed == true, "FenumDevPool: Only approver allowed");
    _approvers[index] = newApprover;
    emit ApprovershipTransferred(_approvers[index], newApprover);
  }

  function _createTransfer(address token, uint256 amount, address payable to) internal returns (uint256) {
    require(to != address(0), "FenumDevPool: to is the zero address");
    require(amount > 0, "FenumDevPool: amount must be greater than 0");
    uint256 id = transfers.length;
    transfers.push(Transfer(id, 0, false, token, amount, to));
    emit TransferCreated(id, 0, false, token, amount, to);
    return id;
  }

  function _executeTransferETH(uint256 id) internal returns (bool) {
    return transfers[id].to.send(transfers[id].amount);
  }

  function _executeTransferERC20(uint256 id) internal returns (bool) {
    return IERC20(transfers[id].token).transfer(transfers[id].to, transfers[id].amount);
  }

  function _approverIndex(address approver) internal view returns (bool, uint256) {
    bool found = false;
    uint256 index = 0;
    for (uint256 i = 0; i < _approvers.length; i = i.add(1)) {
      if (_approvers[i] == approver) {
        found = true;
        index = i;
        break;
      }
    }
    return (found, index);
  }

  modifier onlyApprover() {
    (bool allowed, ) = _approverIndex(_msgSender());
    require(allowed == true, "FenumDevPool: Only approver allowed");
    _;
  }

  receive() external payable { }

  fallback() external {
    revert("FenumDevPool: contract action not found");
  }
}