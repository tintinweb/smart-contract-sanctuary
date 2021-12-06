// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./GIGToken.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GIGVendor {
    event Bought(address payer, uint256 value);
    event BoughtFailed(address payer, uint256 value, string reason);
    AggregatorV3Interface internal priceEth;

    GIGToken public token;
    // address public daiToken = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
    IERC20 daiToken;

    constructor() {
        daiToken = IERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);
        token = new GIGToken();
        priceEth = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    function getEthPrice() public view returns (int256) {
        (, int256 price, , , ) = priceEth.latestRoundData();
        return price / (10**8);
    }

    function balanceThis() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function balancePayer(address _payerAddress) public view returns (uint256) {
        return token.balanceOf(_payerAddress);
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy some tokens");
        // uint256 amountToBuy = ((msg.value * uint256(getEthPrice())) / 1);
        uint256 amountToBuy = ((msg.value * 4213) / 1);

        try token.transfer(msg.sender, amountToBuy) {
            emit Bought(msg.sender, msg.value);
        } catch Error(string memory reason) {
            emit BoughtFailed(msg.sender, msg.value, reason);
            (bool success, ) = msg.sender.call{value: msg.value}(bytes(reason));
            require(success, "External call failed");
        } catch (bytes memory reason) {
            (bool success, ) = msg.sender.call{value: msg.value}(reason);
            require(success, "External call failed");
        }
    }

    function daiBalanceThis() public view returns (uint256) {
        return daiToken.balanceOf(address(this));
    }

    function buyTokensDai(uint256 _amount) public {
        if (_amount == 0) {
            (bool sent, ) = msg.sender.call("Don`t have enough dai tokens");
            return;
        } else if (token.balanceOf(address(this)) < _amount) {
            (bool sent, ) = msg.sender.call(
                "Sorry, there is not enough tokens to buy!"
            );
            return;
        }
        uint256 tokenByDai = _amount;
        daiToken.transferFrom(msg.sender, address(this), _amount);
        token.transfer(msg.sender, tokenByDai);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract GIGToken is IERC20 {
    string public constant name = "GreedIsGood";
    string public constant symbol = "GIG";
    uint8 public constant decimals = 18;

    event Appr(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Trans(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_ = 10000 ether;

    using SafeMath for uint256;

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        override
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        override
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}