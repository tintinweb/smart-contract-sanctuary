/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface PriceFeedInterface {
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

pragma solidity 0.8.4;

contract SmartHoldERC20 {
    address public immutable owner = msg.sender;
    uint256 public immutable createdAt = block.timestamp;
    mapping(address => bool) public configuredTokens;
    mapping(address => Token) public tokensData;
    address[] public tokenAddresses;

    struct Token {
        uint256 lockForDays;
        int256 minExpectedPrice;
        int256 pricePrecision;
        address priceFeed;
    }

    address private constant ZERO = address(0x0);
    string private constant ERRBADCONFIG = "Invalid price configuration";
    string private constant ERRNOTCONFIGURED = "Token not configured";

    modifier restricted() {
        require(msg.sender == owner, "Access denied!");
        _;
    }

    function configureToken(
        address _tokenAddress,
        uint256 _lockForDays,
        address _priceFeed,
        int256 _minExpectedPrice,
        int256 _pricePrecision
    ) external restricted {
        require(_lockForDays > 0, "Invalid lockForDays value.");
        require(_minExpectedPrice >= 0, "Invalid minExpectedPrice value.");
        require(!configuredTokens[_tokenAddress], "Token already configured!");

        if (_minExpectedPrice == 0) {
            require(_priceFeed == ZERO, ERRBADCONFIG);
        } else {
            require(_priceFeed != ZERO, ERRBADCONFIG);
            // check feed address interface
            PriceFeedInterface(_priceFeed).latestRoundData();
        }

        tokenAddresses.push(_tokenAddress);

        Token memory newToken = Token({
            lockForDays: _lockForDays,
            minExpectedPrice: _minExpectedPrice,
            pricePrecision: _pricePrecision,
            priceFeed: _priceFeed
        });

        tokensData[_tokenAddress] = newToken;
        configuredTokens[_tokenAddress] = true;
    }

    function increaseMinExpectedPrice(
        address _tokenAddress,
        int256 _newMinExpectedPrice
    ) external restricted {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token storage token = tokensData[_tokenAddress];
        require(
            token.minExpectedPrice < _newMinExpectedPrice,
            "New price value invalid!"
        );

        token.minExpectedPrice = _newMinExpectedPrice;
    }

    function increaseLockForDays(address _tokenAddress, uint256 _newLockForDays)
        external
        restricted
    {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token storage token = tokensData[_tokenAddress];
        require(
            token.lockForDays < _newLockForDays,
            "New lockForDays value invalid!"
        );
        token.lockForDays = _newLockForDays;
    }

    function getPrice(address _tokenAddress) public view returns (int256) {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token storage token = tokensData[_tokenAddress];
        if (token.priceFeed == ZERO) {
            return 0;
        }

        (, int256 price, , , ) = PriceFeedInterface(token.priceFeed)
        .latestRoundData();
        return price / token.pricePrecision;
    }

    function canWithdraw(address _tokenAddress) public view returns (bool) {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token memory token = tokensData[_tokenAddress];

        uint256 releaseAt = createdAt + (token.lockForDays * 1 days);

        if (releaseAt < block.timestamp) {
            return true;
        } else if (token.minExpectedPrice == 0) {
            return false;
        } else if (token.minExpectedPrice < getPrice(_tokenAddress)) {
            return true;
        } else return false;
    }

    function checkPriceFeed(address _feedAddress, int256 _precision)
        external
        view
        returns (int256)
    {
        (, int256 price, , , ) = PriceFeedInterface(_feedAddress)
        .latestRoundData();
        return price / _precision;
    }

    function getConfiguredTokens() external view returns (address[] memory) {
        return tokenAddresses;
    }

    function getLockForDaysDuration(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token memory token = tokensData[_tokenAddress];
        return token.lockForDays;
    }

    function getPricePrecision(address _tokenAddress)
        external
        view
        returns (int256)
    {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token memory token = tokensData[_tokenAddress];
        return token.pricePrecision;
    }

    function getMinExpectedPrice(address _tokenAddress)
        external
        view
        returns (int256)
    {
        require(configuredTokens[_tokenAddress], ERRNOTCONFIGURED);
        Token memory token = tokensData[_tokenAddress];
        return token.minExpectedPrice;
    }

    function withdraw(address _tokenAddress) external restricted {
        require(canWithdraw(_tokenAddress), "You cannot withdraw yet!");

        if (_tokenAddress == ZERO) {
            payable(owner).transfer(address(this).balance);
        } else {
            IERC20 erc20 = IERC20(_tokenAddress);
            uint256 tokenBalance = erc20.balanceOf(address(this));
            if (tokenBalance > 0) {
                erc20.transfer(owner, tokenBalance);
            }
        }
    }

    receive() external payable {}
}