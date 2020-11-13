// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20.sol";

contract HermezVesting {
    using SafeMath for uint256;

    address public distributor;

    mapping(address => uint256) public vestedTokens;
    mapping(address => uint256) public withdrawed;
    uint256 public totalVestedTokens;

    uint256 public startTime;
    uint256 public cliffTime;
    uint256 public endTime;
    uint256 public initialPercentage;

    address public constant HEZ = address(
        0xEEF9f339514298C6A857EfCfC1A762aF84438dEE
    );

    event Withdraw(address indexed recipient, uint256 amount);
    event Move(address indexed from, address indexed to, uint256 value);
    event ChangeAddress(address indexed oldAddress, address indexed newAddress);

    constructor(
        address _distributor,
        uint256 _totalVestedTokens,
        uint256 _startTime,
        uint256 _startToCliff,
        uint256 _startToEnd,
        uint256 _initialPercentage
    ) public {
        require(
            _startToEnd >= _startToCliff,
            "HermezVesting::constructor: START_GREATER_THAN_CLIFF"
        );
        require(
            _initialPercentage <= 100,
            "HermezVesting::constructor: INITIALPERCENTAGE_GREATER_THAN_100"
        );
        distributor = _distributor;
        totalVestedTokens = _totalVestedTokens;
        vestedTokens[_distributor] = _totalVestedTokens;
        startTime = _startTime;
        cliffTime = _startTime + _startToCliff;
        endTime = _startTime + _startToEnd;
        initialPercentage = _initialPercentage;
    }

    function totalTokensUnlockedAt(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (timestamp < startTime) return 0;
        if (timestamp > endTime) return totalVestedTokens;

        uint256 initialAmount = totalVestedTokens.mul(initialPercentage).div(
            100
        );
        if (timestamp < cliffTime) return initialAmount;

        uint256 deltaT = timestamp.sub(startTime);
        uint256 deltaTTotal = endTime.sub(startTime);
        uint256 deltaAmountTotal = totalVestedTokens.sub(initialAmount);
        return initialAmount.add(deltaT.mul(deltaAmountTotal).div(deltaTTotal));
    }

    function withdrawableTokens(address recipient)
        public
        view
        returns (uint256)
    {
        return withdrawableTokensAt(recipient, block.timestamp);
    }

    function withdrawableTokensAt(address recipient, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 unlockedAmount = totalTokensUnlockedAt(timestamp)
            .mul(vestedTokens[recipient])
            .div(totalVestedTokens);
        return unlockedAmount.sub(withdrawed[recipient]);
    }

    function withdraw() external {
        require(
            msg.sender != distributor,
            "HermezVesting::withdraw: DISTRIBUTOR_CANNOT_WITHDRAW"
        );

        uint256 remainingToWithdraw = withdrawableTokensAt(
            msg.sender,
            block.timestamp
        );

        withdrawed[msg.sender] = withdrawed[msg.sender].add(
            remainingToWithdraw
        );

        require(
            IERC20(HEZ).transfer(msg.sender, remainingToWithdraw),
            "HermezVesting::withdraw: TOKEN_TRANSFER_ERROR"
        );

        emit Withdraw(msg.sender, remainingToWithdraw);
    }

    function move(address recipient, uint256 amount) external {
        require(
            msg.sender == distributor,
            "HermezVesting::changeAddress: ONLY_DISTRIBUTOR"
        );
        vestedTokens[msg.sender] = vestedTokens[msg.sender].sub(amount);
        vestedTokens[recipient] = vestedTokens[recipient].add(amount);
        emit Move(msg.sender, recipient, amount);
    }

    function changeAddress(address newAddress) external {
        require(
            vestedTokens[newAddress] == 0,
            "HermezVesting::changeAddress: ADDRESS_HAS_BALANCE"
        );
        require(
            withdrawed[newAddress] == 0,
            "HermezVesting::changeAddress: ADDRESS_ALREADY_WITHDRAWED"
        );

        vestedTokens[newAddress] = vestedTokens[msg.sender];
        vestedTokens[msg.sender] = 0;
        withdrawed[newAddress] = withdrawed[msg.sender];
        withdrawed[msg.sender] = 0;

        if (msg.sender == distributor) {
            distributor = newAddress;
        }

        emit ChangeAddress(msg.sender, newAddress);
    }
}
