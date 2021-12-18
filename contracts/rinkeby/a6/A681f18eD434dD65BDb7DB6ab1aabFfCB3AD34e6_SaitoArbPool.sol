/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

pragma solidity >=0.8.0;

abstract contract AbstractArbitrum {
    function depositEth(uint256 maxSubmissionCost) external payable virtual returns (uint256);
}

contract SaitoArbPool {
  // address owner;
  address immutable Arbitrum;
  mapping(address => uint256) public poolBalance;
  address[] public poolUsers;
  uint256 public poolUsersQty;
  uint256 public poolTotal;
  bool public isPoolOpen;

  uint256 public MIN_USERS;
  uint256 public MIN_TOTAL;

  constructor(address _arbitrum, uint256 _minUsers, uint256 _minTotal) {
    Arbitrum = _arbitrum;
    MIN_USERS = _minUsers;
    MIN_TOTAL = _minTotal;

    isPoolOpen = true;
  }

  // helper functions
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
  }

  function remove(address _addressToRemove) public {
    uint256 index = 0;

    for (uint i = 0; i < poolUsers.length; i++){
        if(poolUsers[i] != _addressToRemove)
            index = i;
    }

    delete poolUsers[index];
  }

  function checkDeposit() public returns(bool success) {
    if (poolUsersQty >= MIN_USERS && poolTotal >= MIN_TOTAL) {
      closePool();
      return true;
    }

    return false;
  }

  function calcTotalFees(uint256 _avgGas) public returns(uint256 fees) {
    uint256 fees = _avgGas + (_avgGas * sqrt(poolUsersQty));

    return fees;
  }


  // pool user functions
  function addPoolUser(address _depositer, uint256 _amount) public returns(bool success) {
    if (poolBalance[_depositer] == 0) {
      poolUsersQty += 1;
      poolUsers.push(_depositer);
    }

    poolBalance[_depositer] += _amount;
    poolTotal += _amount;

    return true;
  }

  function removePoolUser(address _depositer) public returns(bool success) {
    poolUsersQty -= 1;
    remove(_depositer);

    return true;
  }

  function withdrawPoolUser(address _depositer, uint256 _amount) public returns(bool success) {
    require(poolBalance[_depositer] >= _amount);

    poolBalance[_depositer] -= _amount;
    poolTotal -= _amount;

    if (poolBalance[_depositer] == 0) {
      removePoolUser(_depositer);
    }

    return true;
  }

  // pool actions
  function openPool() public returns(bool success) {
    isPoolOpen = true;
  }

  function closePool() public returns(bool success) {
    isPoolOpen = false;

    return true;
  }

  function bridge() public returns(bool success) {
    require(!isPoolOpen);
    uint256 fees = calcTotalFees(10000000000000000);
    uint256 poolTotalNetFees = poolTotal - fees;

    AbstractArbitrum arbi = AbstractArbitrum(Arbitrum);

    arbi.depositEth{value:poolTotalNetFees}(1000000000000);
    openPool();

    return true;
  }

  // allow deposits
  fallback() payable external {}		
}