/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IErc20Contract {
    // External ERC20 contract
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

struct VestingIndex {
    address _wallet;
    uint256 _amount;
    uint256 _date;
}

contract LOAStakeWin {
    IErc20Contract public _erc20Contract; // External ERC20 contract
    address _admin;
    uint256 _startDate = 1641254400;
    uint256 _endDate = 1641859200;
    mapping(address => uint256) public _totalAddressAmount;
    VestingIndex public _vestingIndex;
    VestingIndex[] public _vesting;
    uint256 public _totalAmount;
    mapping(address => VestingIndex[]) _vestedAddress;
    uint256 eighteen_digit = 1_000_000_000_000_000_000;
    constructor(address erc20Contract) {
        _admin = msg.sender;
        _erc20Contract = IErc20Contract(erc20Contract);
    }

    // receive erc20 token with the amount
    function deposit(uint256 amount) external {
        require(amount >= 100 * eighteen_digit, "Amount Should be more than 100 $LOA");
        require(
            block.timestamp >= _startDate && block.timestamp <= _endDate,
            "Deposit rejected, Stake2Win has either not yet started or ended"
        );
        require(
            _erc20Contract.transferFrom(msg.sender, address(this), amount),
            "transferFrom failed"
        );

        _vestingIndex = VestingIndex(msg.sender, amount, block.timestamp);
        _totalAddressAmount[msg.sender] += amount;
        _totalAmount += amount;
        _vesting.push(_vestingIndex);
        _vestedAddress[msg.sender].push(_vestingIndex);
    }

    function withdraw() external {
        uint256 length = _vestedAddress[msg.sender].length;
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 date = _vestedAddress[msg.sender][i]._date + 30 days;
                if (block.timestamp >= date) {
                    require(
                        _erc20Contract.transfer(
                            _vestedAddress[msg.sender][i]._wallet,
                            _vestedAddress[msg.sender][i]._amount
                        ),
                        "transfer failed"
                    );
                    _totalAmount -= _vestedAddress[msg.sender][i]._amount;
                    _vestedAddress[msg.sender][i]._amount = 0;
                    delete _vestedAddress[msg.sender][i];
                }
            }
        }
    }

    function returnAddresses() external view returns (VestingIndex[] memory) {
        return _vesting;
    }

    // Reject all direct deposit to this contract
    receive() external payable {
        revert();
    }
}