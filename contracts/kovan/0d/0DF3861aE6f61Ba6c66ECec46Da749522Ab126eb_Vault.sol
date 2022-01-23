// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Adaption of https://tinyurl.com/ycwnwxaw
abstract contract ReentrancyGuard {
    uint256 private _locked = 1;

    modifier nonReentrant() {
        require(_locked == 1, "Reentrancy");

        _locked = 2;
        _;
        _locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "./interfaces/IERC20.sol";
import { IVault } from "./interfaces/IVault.sol";
import { IExchange } from "./interfaces/IExchange.sol";
import { IKeeperCompatible } from "./interfaces/IKeeperCompatible.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

library Errors {
    string internal constant _AmountZero = "Amount can't be 0";
    string internal constant _WrongToken = "Token not allowed";
    string internal constant _ExceedsBalance = "Amount exceeds balance";
    string internal constant _BalanceZero = "Token balance is 0";
    string internal constant _NothingToSell = "Nothing to sell";
}

contract Vault is ReentrancyGuard, IVault, IKeeperCompatible {
    IERC20 public from;
    IERC20 public to;
    IExchange public exchange;
    address[] public participants;
    mapping(address => uint256) public amountPerDay;
    mapping(address => mapping(IERC20 => uint256)) public balances;

    constructor(
        IERC20 from_,
        IERC20 to_,
        IExchange exchange_
    ) {
        from = from_;
        to = to_;
        exchange = exchange_;
    }

    function deposit(uint256 amount) external override {
        require(amount > 0, Errors._AmountZero);

        balances[msg.sender][from] += amount;

        if (!_isInArray(participants, msg.sender)) {
            participants.push(msg.sender);
        }

        IERC20(from).transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function withdraw(IERC20 token, uint256 amount) external override nonReentrant {
        require(amount > 0, Errors._AmountZero);
        require(token == from || token == to, Errors._WrongToken);

        uint256 fromBalance = balances[msg.sender][from];
        uint256 toBalance = balances[msg.sender][to];
        require(amount <= fromBalance || amount <= toBalance, Errors._ExceedsBalance);

        balances[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    function allocate(uint256 amountPerDay_) external override {
        require(amountPerDay_ > 0, Errors._AmountZero);
        require(amountPerDay_ <= balances[msg.sender][from], Errors._ExceedsBalance);

        amountPerDay[msg.sender] = amountPerDay_;

        emit Allocate(msg.sender, amountPerDay_);
    }

    function performUpkeep(bytes calldata) external override {
        buy();
    }

    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        bool upkeepNeeded;
        bytes memory performData = new bytes(0);

        uint256 toSell = _calcAmountToSell();
        uint256 vaultBalance = from.balanceOf(address(this));

        if (vaultBalance > 0 && toSell > 0 && toSell <= vaultBalance) upkeepNeeded = true;

        return (upkeepNeeded, performData);
    }

    function buy() public override returns (uint256) {
        require(from.balanceOf(address(this)) > 0, Errors._BalanceZero);

        uint256 fromSold = _calcAmountToSell();
        require(fromSold > 0, Errors._NothingToSell);

        from.approve(address(exchange), fromSold);
        uint256 toBought = exchange.swap(from, to, fromSold);

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint256 balance = balances[participant][from];
            uint256 perDay = amountPerDay[participant];

            // Exclude users who haven't allocated yet or don't have enough funds
            if (perDay == 0 || balance < perDay) continue;

            // Basis Points describing the user's ownership over the `from` tokens sold
            uint256 bps = (perDay * 10000) / fromSold;

            // The amount of the bought `to` tokens the user should receive based on the `bps` calculation above
            uint256 slice = (toBought * bps) / 10000;

            // Remove the user's `from` tokens from the internal balance sheet
            balances[participant][from] -= perDay;
            // Add the user's slice of the bought `to` tokens to the internal balance sheet
            balances[participant][to] += slice;
        }

        emit Buy(fromSold, toBought);

        return toBought;
    }

    function _calcAmountToSell() private view returns (uint256) {
        uint256 result;

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            uint256 balance = balances[participant][from];
            uint256 perDay = amountPerDay[participant];

            // Exclude users who haven't allocated yet or don't have enough funds
            if (perDay == 0 || balance < perDay) continue;

            // Update the running total of `from` tokens to sell
            result += perDay;
        }

        return result;
    }

    function _isInArray(address[] storage haystack, address needle) private view returns (bool) {
        for (uint256 i = 0; i < haystack.length; i++) {
            if (haystack[i] == needle) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(address spender, uint256 value) external returns (bool success);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "./IERC20.sol";

interface IExchange {
    event Swap(IERC20 indexed from, IERC20 indexed to, uint256 amount, uint256 received);

    function swap(
        IERC20 from,
        IERC20 to,
        uint256 amount
    ) external returns (uint256 received);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Adaption of https://tinyurl.com/yck327nn
interface IKeeperCompatible {
    function performUpkeep(bytes calldata performData) external;

    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "./IERC20.sol";
import { IExchange } from "./IExchange.sol";

interface IVault {
    event Deposit(address indexed sender, uint256 indexed amount);

    event Withdraw(address indexed sender, IERC20 token, uint256 indexed amount);

    event Allocate(address indexed sender, uint256 indexed amountPerDay);

    event Buy(uint256 indexed fromSold, uint256 indexed toBought);

    function deposit(uint256 amount) external;

    function withdraw(IERC20 token, uint256 amount) external;

    function allocate(uint256 amountPerDay) external;

    function buy() external returns (uint256);

    function from() external view returns (IERC20);

    function to() external view returns (IERC20);

    function exchange() external view returns (IExchange);
}