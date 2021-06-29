// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IShibaSwapPoolNames {
    function logos(uint256) external view returns(string memory);
    function names(uint256) external view returns(string memory);
    function setPoolInfo(uint256 pid, string memory logo, string memory name) external;
}

interface IBoneToken is IERC20{
    function delegates(address who) external view returns(address);
    function getCurrentVotes(address who) external view returns(uint256);
    function nonces(address who) external view returns(uint256);
}

interface ITopDog {
    function BONUS_MULTIPLIER() external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function devaddr() external view returns (address);
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startBlock() external view returns (uint256);
    function bone() external view returns (address);
    function bonePerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingBone(uint256 nr, address who) external view returns (uint256);
}

interface IFactory {
    function allPairsLength() external view returns (uint256);
    function allPairs(uint256 i) external view returns (address);
    function getPair(address token0, address token1) external view returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}

interface IPair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) { return 0; } uint256 c = a * b; require(c / a == b); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0); uint256 c = a / b; return c; }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

contract BoringCryptoTokenScan
{
    using SafeMath for uint256;

    struct Balance {
        address token;
        uint256 balance;
    }

    struct BalanceFull {
        address token;
        uint256 balance;
        uint256 rate;
    }

    struct TokenInfo {
        address token;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokenInfo(address[] calldata addresses) public view returns(TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            infos[i].token = address(token);

            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
        }

        return infos;
    }

    function findBalances(address who, address[] calldata addresses) public view returns(Balance[] memory) {
        uint256 balanceCount;

        for (uint256 i = 0; i < addresses.length; i++) {
            if (IERC20(addresses[i]).balanceOf(who) > 0) {
                balanceCount++;
            }
        }

        Balance[] memory balances = new Balance[](balanceCount);

        balanceCount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            uint256 balance = token.balanceOf(who);
            if (balance > 0) {
                balances[balanceCount].token = address(token);
                balances[balanceCount].balance = token.balanceOf(who);
                balanceCount++;
            }
        }

        return balances;
    }

    function getBalances(address who, address[] calldata addresses, IFactory factory, address currency) public view returns(BalanceFull[] memory) {
        BalanceFull[] memory balances = new BalanceFull[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            balances[i].token = address(token);
            balances[i].balance = token.balanceOf(who);

            IPair pair = IPair(factory.getPair(addresses[i], currency));
            if(address(pair) != address(0))
            {
                uint256 reserveCurrency;
                uint256 reserveToken;
                if (pair.token0() == currency) {
                    (reserveCurrency, reserveToken,) = pair.getReserves();
                }
                else
                {
                    (reserveToken, reserveCurrency,) = pair.getReserves();
                }
                balances[i].rate = reserveToken * 1e18 / reserveCurrency;
            }
        }

        return balances;
    }

    struct Factory {
        IFactory factory;
        uint256 allPairsLength;
        address feeTo;
        address feeToSetter;
    }

    function getFactoryInfo(IFactory[] calldata addresses) public view returns(Factory[] memory) {
        Factory[] memory factories = new Factory[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IFactory factory = addresses[i];
            factories[i].factory = factory;

            factories[i].allPairsLength = factory.allPairsLength();
            factories[i].feeTo = factory.feeTo();
            factories[i].feeToSetter = factory.feeToSetter();
        }

        return factories;
    }

    struct Pair {
        address token;
        address token0;
        address token1;
    }

    function getPairs(IFactory factory, uint256 fromID, uint256 toID) public view returns(Pair[] memory) {
        if (toID == 0){
            toID = factory.allPairsLength();
        }

        Pair[] memory pairs = new Pair[](toID - fromID);

        for(uint256 id = fromID; id < toID; id++) {
            address token = factory.allPairs(id);
            uint256 i = id - fromID;
            pairs[i].token = token;
            pairs[i].token0 = IPair(token).token0();
            pairs[i].token1 = IPair(token).token1();
        }
        return pairs;
    }

    function findPairs(address who, IFactory factory, uint256 fromID, uint256 toID) public view returns(Pair[] memory) {
        if (toID == 0){
            toID = factory.allPairsLength();
        }

        uint256 pairCount;

        for(uint256 id = fromID; id < toID; id++) {
            address token = factory.allPairs(id);
            if (IERC20(token).balanceOf(who) > 0) {
                pairCount++;
            }
        }

        Pair[] memory pairs = new Pair[](pairCount);

        pairCount = 0;
        for(uint256 id = fromID; id < toID; id++) {
            address token = factory.allPairs(id);
            uint256 balance = IERC20(token).balanceOf(who);
            if (balance > 0) {
                pairs[pairCount].token = token;
                pairs[pairCount].token0 = IPair(token).token0();
                pairs[pairCount].token1 = IPair(token).token1();
                pairCount++;
            }
        }

        return pairs;
    }

    struct PairFull {
        address token;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 balance;
    }

    function getPairsFull(address who, address[] calldata addresses) public view returns(PairFull[] memory) {
        PairFull[] memory pairs = new PairFull[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            address token = addresses[i];
            pairs[i].token = token;
            pairs[i].token0 = IPair(token).token0();
            pairs[i].token1 = IPair(token).token1();
            (uint256 reserve0, uint256 reserve1,) = IPair(token).getReserves();
            pairs[i].reserve0 = reserve0;
            pairs[i].reserve1 = reserve1;
            pairs[i].balance = IERC20(token).balanceOf(who);
            pairs[i].totalSupply = IERC20(token).totalSupply();
        }
        return pairs;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 5000
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
  "libraries": {}
}