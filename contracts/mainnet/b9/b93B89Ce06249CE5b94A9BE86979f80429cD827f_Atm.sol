// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Atm {
    uint256 public constant SHARE_DENOMINATOR = 10000;
    IERC20 public immutable token;

    uint256 public depositTotal;
    uint256 public withdrawTotal;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public withdrawn;

    modifier updateDeposits {
        depositTotal += (token.balanceOf(address(this)) + withdrawTotal - depositTotal);
        _;
    }

    event Withdraw(address wallet, uint256 amount);

    constructor(IERC20 _token, address[] memory _wallets, uint256[] memory _shares) {
        require(_wallets.length == _shares.length, "ATM: corrupt data");

        token = _token;

        for (uint256 i = 0; i < _wallets.length; i++) {
            shares[_wallets[i]] = _shares[i];
        }
    }

    function currentDepositTotal() public view returns (uint256) {
        uint256 _depositTotal = depositTotal;
        _depositTotal += (token.balanceOf(address(this)) + withdrawTotal - depositTotal);
        return _depositTotal;
    }

    function available(address wallet) public view returns (uint256) {
        uint256 totalWithdraw = currentDepositTotal() * shares[wallet] / SHARE_DENOMINATOR;
        return totalWithdraw - withdrawn[wallet];
    }

    function withdraw() external updateDeposits {
        require(shares[msg.sender] > 0, "ATM: no shares");

        uint256 availableWithdraw = available(msg.sender);

        withdrawn[msg.sender] += availableWithdraw;
        withdrawTotal += availableWithdraw;

        emit Withdraw(msg.sender, availableWithdraw);

        token.transfer(msg.sender, availableWithdraw);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {
    "": {
      "__CACHE_BREAKER__": "0x00000000d41867734bbee4c6863d9255b2b06ac1"
    }
  }
}