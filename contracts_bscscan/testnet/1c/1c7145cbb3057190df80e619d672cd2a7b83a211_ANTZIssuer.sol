/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract ANTZIssuer is Ownable {
  using SafeMath for uint256;

  struct Queen {
      address[] chequebooks;
      address queenAddress;
      uint256 balance;
  }

  event AddQueen(address indexed queenAddress);
  event RemoveQueen(address indexed queenAddress);
  event AddChequebooks(address indexed queenAddress, address[] chequebooks);
  event RemoveChequebooks(address indexed queenAddress, address[] chequebooks);
  event QueenWithdraw(address indexed queenAddress, uint256 queen_amount, address indexed ecologicalFund, uint256 eco_amount, uint256 ant_amount);

  IERC20 public token;

  mapping (address => uint) public queenIndex;
  Queen [] public queens;
  
  uint256 public lastSettlementAt;
  mapping (address => uint) public lastWithdrawAt;

  address public ecologicalFund;

  uint public queenNodeRate = 15;
  uint public antNodeRate = 80;

  uint fourYearHeight = 42048000; //4*365*24*60*60/3

  constructor(address tokenContract) {
     token = IERC20(tokenContract);
     lastSettlementAt = 0;
  }

  function init(uint256 height)  public onlyOwner {
     require(lastSettlementAt == 0);
     lastSettlementAt = height;
  }

  function setEcologicalFundAddress(address _ecologicalFund) public onlyOwner {
      require(_ecologicalFund != address(0));
      ecologicalFund = _ecologicalFund;
  }

  function setDistributionRate(uint _queenNodeRate , uint _antNodeRate) public onlyOwner {
      require(_queenNodeRate + _antNodeRate <= 100);
      if (queenNodeRate == _queenNodeRate && antNodeRate == _antNodeRate) {
         return;
      }
       _settlement();
      queenNodeRate = _queenNodeRate;
      antNodeRate = _antNodeRate;
  }

  function addQueen(address queenAddress) public onlyOwner {
      require(queenAddress != address(0), "queenAddress cannot be the zero address");
      require (queenIndex[queenAddress] == 0, "queen exists");

      _settlement();

      queens.push();
      Queen storage q = queens[queens.length - 1];
      q.queenAddress = queenAddress;

      queenIndex[queenAddress] = queens.length;

      emit AddQueen(queenAddress);
  }

  function addChequebooks(address queenAddress, address[] memory chequebooks) public onlyOwner {
      require(queenAddress != address(0), "queenAddress cannot be the zero address");
      require (queenIndex[queenAddress] > 0, "queue must exists");

      uint idx = queenIndex[queenAddress] - 1;
      Queen storage q = queens[idx];

      for (uint i = 0; i < chequebooks.length; i++) {
          address chequebook = chequebooks[i];
          require(chequebook != address(0), "chequebook cannot be the zero address");
          q.chequebooks.push(chequebook);
      }

      emit AddChequebooks(queenAddress, chequebooks);
  }

  function removeQueen(address queenAddress) public onlyOwner {
     require(queenIndex[queenAddress] != 0, "queenAddress must bee a queen");

     _settlement();

     uint idx = queenIndex[queenAddress] - 1;

     uint len = queens.length;
     queens[idx] = queens[len-1];

     queenIndex[queens[idx].queenAddress] = idx + 1;
     queens.pop();
     delete queenIndex[queenAddress];

     emit RemoveQueen(queenAddress);
  }

  function removeChequebooks(address queenAddress, address[] memory chequebooks) public onlyOwner {
      require(queenAddress != address(0), "queenAddress cannot be the zero address");
      require (queenIndex[queenAddress] > 0, "queen must exists");

      uint idx = queenIndex[queenAddress] - 1;
      Queen storage q = queens[idx];

      for (uint i = 0; i < chequebooks.length; i++) {
          for (uint j = 0; j < q.chequebooks.length; j++) {
              if (chequebooks[i] == q.chequebooks[j]) {
                  q.chequebooks[j] = q.chequebooks[q.chequebooks.length - 1];
                  q.chequebooks.pop();
                  break;
              }
          }
      }

      emit RemoveChequebooks(queenAddress, chequebooks);
  }

  function queenCount() public view returns (uint){
       return queens.length;
  }

  function _settlement() private {
      if (lastSettlementAt == 0 || lastSettlementAt >= block.number || queens.length == 0) {
          return;
      }
      uint256 amount = _getSettlementAmount().div(queens.length);
      if (amount == 0) {
          return;
      }

      for(uint i = 0; i < queens.length; i++) {
          queens[i].balance = queens[i].balance.add(amount);
      }
      lastSettlementAt = block.number;
  }

  function settlement() public {
      _settlement();
  }

  function _getSettlementAmount() view private returns(uint256) {
        if (block.number <= lastSettlementAt) {
            return 0;
        }
        uint256 blocks = block.number - lastSettlementAt;
        return getReleaseAmountPerHeight().mul(blocks);
  }

  function queenWithdraw(address queenAddress) public {
      uint idx = queenIndex[queenAddress];
      require(idx > 0);

      Queen storage q = queens[idx - 1];

      uint256 amount = q.balance;
      require(amount > 0);

      q.balance = 0;

      uint256 ant_amount = amount.mul(antNodeRate).div(100);
      uint256 queen_amount = amount.mul(queenNodeRate).div(100);
      uint256 ant_amount_per_node =  ant_amount.div(q.chequebooks.length);
      queen_amount = ant_amount_per_node.mul(q.chequebooks.length);
      uint256 eco_amount = amount.sub(ant_amount).sub(queen_amount);

      for (uint i = 0; i < q.chequebooks.length; i++) {
          require(token.transfer(q.chequebooks[i], ant_amount_per_node), "failed to transfer token");
      }

      require(token.transfer(q.queenAddress, queen_amount), "failed to transfer token");
      require(token.transfer(ecologicalFund, eco_amount), "failed to transfer token");

      emit QueenWithdraw(q.queenAddress, queen_amount, ecologicalFund, eco_amount, ant_amount);
      
      lastWithdrawAt[queenAddress] = block.number;
  }

  function getReleaseAmountPerHeight() public view returns (uint256) {
     if (block.number < lastSettlementAt) {
          return 0;
     }
     uint256 blocks = block.number - lastSettlementAt;
     //uint256 amount = 10 ** uint256(token.decimals());
     uint256 amount = 10 ** uint256(16);
     for (uint256 k = fourYearHeight; k < blocks; k = k.mul(2)) {
         amount = amount.div(2);
     }
     return amount;
  }

  function blockNumber() public view returns (uint256) {
      return block.number;
  }

  function queenChequebooks(address queenAddress) public view returns (address[] memory) {
     uint idx = queenIndex[queenAddress];
     require(idx > 0);
     return queens[idx - 1].chequebooks;
  }
}