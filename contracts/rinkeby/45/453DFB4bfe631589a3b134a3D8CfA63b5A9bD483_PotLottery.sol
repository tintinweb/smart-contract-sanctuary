/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IPRC20

interface IPRC20 {
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

// File: PotContract.sol

contract PotLottery {
    /*
     ***Start of function, Enum, Variables, array and mappings to set and edit the Pot State such that accounts can enter the pot
     */

    address owner;
    address internal admin;

    constructor(address _owner) {
        owner = _owner;
        admin = _owner;
        pot_state = POT_STATE.ENDED;
        potDuration = 300;
        minEntranceFeeInUsd = 100;
        percentageFee = 1;
    }

    POT_STATE public pot_state;
    mapping(string => Token) public tokenWhiteList;
    string[] tokenWhiteListNames;
    uint256 public minEntranceFeeInUsd;
    uint256 public potCount;
    uint256 public potDuration;
    uint256 public percentageFee;
    mapping(string => uint256) public tokenLatestPriceFeed;

    struct Token {
        address tokenAddress;
        string tokenSymbol;
        uint256 tokenDecimal;
    }

    enum POT_STATE {
        ENDED,
        STARTED,
        ACTIVE,
        CALCULATING_WINNER
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin || msg.sender == owner,
            "Only an admin level user can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function changeAdmin(address _adminAddress) public onlyOwner {
        admin = _adminAddress;
    }

    function addToken(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _tokenAddress,
        uint256 _decimal
    ) public onlyAdmin {
        bool istokenInWhiteList = false;
        tokenWhiteList[_tokenName] = Token(
            _tokenAddress,
            _tokenSymbol,
            _decimal
        );
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (
                keccak256(bytes(_tokenName)) ==
                keccak256(bytes(tokenWhiteListNames[index]))
            ) {
                istokenInWhiteList = true;
                tokenWhiteListNames[index] = _tokenName;
            }
        }
        if (!istokenInWhiteList) {
            tokenWhiteListNames.push(_tokenName);
        }
    }

    function removeToken(string memory _tokenName) public onlyAdmin {
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (
                keccak256(bytes(_tokenName)) ==
                keccak256(bytes(tokenWhiteListNames[index]))
            ) {
                delete tokenWhiteList[_tokenName];
                tokenWhiteListNames[index] = tokenWhiteListNames[
                    tokenWhiteListNames.length - 1
                ];
                tokenWhiteListNames.pop();
            }
        }
    }

    function updateTokenUsdValue(string memory _tokenName, uint256 _valueInUsd)
        public
        onlyAdmin
    {
        tokenLatestPriceFeed[_tokenName] = _valueInUsd;
    }

    function updateTokenUsdValues(
        string[] memory _tokenNames,
        uint256[] memory _valuesInUsd
    ) public onlyAdmin {
        require(
            _tokenNames.length == _valuesInUsd.length,
            "No of address is not equal to number of usd values"
        );
        for (uint256 index = 0; index < _tokenNames.length; index++) {
            tokenLatestPriceFeed[_tokenNames[index]] = _valuesInUsd[index];
        }
    }

    function changePotState(POT_STATE _potState) public onlyAdmin {
        pot_state = _potState;
    }

    function setMinimumUsdEntranceFee(uint256 _minimumUsdEntranceFee)
        public
        onlyAdmin
    {
        minEntranceFeeInUsd = _minimumUsdEntranceFee;
    }

    function setPercentageFee(uint256 _percentageFee) public onlyAdmin {
        percentageFee = _percentageFee;
    }

    function setPotDuration(uint256 _potDuration) public onlyAdmin {
        potDuration = _potDuration;
    }

    /*
     ***End of function, Enum, Variables, array and mappings to set and edit the Pot State such that accounts can enter the pot
     */

    /*
     ***Start of function, Enum, Variables, array and mappings to allow accounts to enter the pot
     */

    /*
     *START
     *The following dataTypes are responsible for keeping the state of the Pot
     */

    /*
     *END
     */

    modifier tokenInWhiteList(string memory _tokenName) {
        bool istokenWhiteListed = false;
        for (uint256 index = 0; index < tokenWhiteListNames.length; index++) {
            if (
                keccak256(bytes(tokenWhiteListNames[index])) ==
                keccak256(bytes(_tokenName))
            ) {
                istokenWhiteListed = true;
            }
        }
        require(istokenWhiteListed, "Token not supported");
        _;
    }

    uint256 public startTime;
    address[] participants;
    string[] public tokensInPotNames;
    mapping(address => uint256) public participantsTotalEntryInUsd;
    mapping(string => uint256) public tokenTotalEntry;

    mapping(address => mapping(string => uint256))
        public participantsTokenEntries;

    function enterPot(string memory _tokenName, uint256 _amount)
        public
        payable
        tokenInWhiteList(_tokenName)
    {
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[msg.sender] == 0
            ? false
            : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        bool isPulse = keccak256(bytes(_tokenName)) == "PULSE";

        uint256 tokenUsdValue = isPulse
            ? (tokenLatestPriceFeed[_tokenName] * msg.value) / 10**tokenDecimal
            : (tokenLatestPriceFeed[_tokenName] * _amount) / 10**tokenDecimal;

        require(
            pot_state == POT_STATE.ACTIVE || pot_state == POT_STATE.STARTED,
            "Lottery not active"
        );

        IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
        if (isPulse) {
            require(
                tokenUsdValue >= minEntranceFeeInUsd,
                "Your entrance fee is less than the minimum entrance fee"
            );
        } else {
            require(
                tokenUsdValue >= minEntranceFeeInUsd,
                "Your entrance fee is less than the minimum entrance fee"
            );
            require(
                token.transferFrom(msg.sender, address(this), _amount),
                "Unable to charge user"
            );
        }

        participantsTokenEntries[msg.sender][_tokenName] += _amount;
        participantsTotalEntryInUsd[msg.sender] +=
            (tokenLatestPriceFeed[_tokenName] * _amount) /
            10**tokenDecimal;

        tokenTotalEntry[_tokenName] += _amount;
        if (!hasEntryInCurrentPot) {
            participants.push(msg.sender);
        }
        if (!tokenIsInPot) {
            tokensInPotNames.push(_tokenName);
        }
    }
}