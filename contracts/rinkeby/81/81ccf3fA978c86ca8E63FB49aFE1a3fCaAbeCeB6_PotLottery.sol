/**
 *Submitted for verification at Etherscan.io on 2022-01-15
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

    address public owner;
    address public admin;

    constructor(address _owner) {
        owner = _owner;
        admin = _owner;
        accountToReceivePotFees = _owner;
        pot_state = POT_STATE.STARTED;
        potDuration = 300;
        minEntranceFeeInUsd = 100;
        percentageFee = 1;
        addToken(
            "SAS Coin",
            "SASC",
            address(0xcaF96d4ED3F96C1cbb1f2A7A039e4aa211d9C220),
            18
        );
        addToken(
            "Bright Side Token",
            "BST",
            address(0x674cc98546297f13b9d0179eaC2376Fda0152185),
            18
        );
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
        ACTIVE
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
    ) public {
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
        updateTokenUsdValue(_tokenName, 1000); //should be removed later
    }

    function removeToken(string memory _tokenName) public {
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
    {
        tokenLatestPriceFeed[_tokenName] = _valueInUsd;
    }

    function updateTokenUsdValues(
        string[] memory _tokenNames,
        uint256[] memory _valuesInUsd
    ) public {
        require(
            _tokenNames.length == _valuesInUsd.length,
            "No of address is not equal to number of usd values"
        );
        for (uint256 index = 0; index < _tokenNames.length; index++) {
            tokenLatestPriceFeed[_tokenNames[index]] = _valuesInUsd[index];
        }
    }

    function changePotState(POT_STATE _potState) public {
        pot_state = _potState;
    }

    function setMinimumUsdEntranceFee(uint256 _minimumUsdEntranceFee) public {
        minEntranceFeeInUsd = _minimumUsdEntranceFee;
    }

    function setPercentageFee(uint256 _percentageFee) public {
        percentageFee = _percentageFee;
    }

    function setPotDuration(uint256 _potDuration) public {
        potDuration = _potDuration;
    }

    function setAccountToRecieveFees(address _accountToRecieveFee) public {
        accountToReceivePotFees = _accountToRecieveFee;
    }

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

    uint256 public potStartTime;
    address[] participants;
    string[] public tokensInPotNames;
    uint256 public totalPotUsdValue;
    mapping(address => uint256) public participantsTotalEntryInUsd;
    mapping(string => uint256) public tokenTotalEntry;
    address[] public entriesAddress;
    uint256[] public entriesUsdValue;
    address public LAST_POT_WINNER;
    // bool calculatingWinner = false;
    address public accountToReceivePotFees;

    mapping(address => mapping(string => uint256))
        public participantsTokenEntries;

    function enterPot(string memory _tokenName, uint256 _amount)
        public
        payable
        tokenInWhiteList(_tokenName)
    {
        calculateWinner();
        uint256 tokenDecimal = tokenWhiteList[_tokenName].tokenDecimal;

        bool hasEntryInCurrentPot = participantsTotalEntryInUsd[msg.sender] == 0
            ? false
            : true;
        bool tokenIsInPot = tokenTotalEntry[_tokenName] == 0 ? false : true;
        bool isPulse = keccak256(bytes(_tokenName)) == "PULSE";

        uint256 tokenUsdValue = isPulse
            ? (tokenLatestPriceFeed["PULSE"] * _amount) / 10**tokenDecimal
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
        totalPotUsdValue += tokenUsdValue;
        entriesAddress.push(msg.sender);
        entriesUsdValue.push(tokenUsdValue);
        if (participants.length == 2) {
            potStartTime = block.timestamp;
            pot_state = POT_STATE.ACTIVE;
        }
        // return true;
    }

    function calculateWinner() public {
        /*
            This function is supposed to calculate the winner when the pot is potDuration minutes old
        */

        if (
            (potStartTime + potDuration) <= block.timestamp &&
            (participants.length > 1)
        ) {
            string
                memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();

            uint256 amountToPayAsFees = getAmountToPayAsFees();
            payAccount(
                tokenWithThehighestUsdValue,
                accountToReceivePotFees,
                amountToPayAsFees
            ); // Pay the dedicated account the percentage fee

            tokenTotalEntry[tokenWithThehighestUsdValue] =
                tokenTotalEntry[tokenWithThehighestUsdValue] -
                amountToPayAsFees;
            address pot_winner = determineWinner();
            for (uint256 index = 0; index < tokensInPotNames.length; index++) {
                payAccount(
                    tokensInPotNames[index],
                    pot_winner,
                    tokenTotalEntry[tokensInPotNames[index]]
                );
            } //Transfer all required tokens to the Pot winner
            startNewPot();
            //Start the new Pot and set calculating winner to true
            //After winner has been sent the token then set calculating winner to false
        } else {
            return;
        }
    }

    int256 public winningPoint; //to be deleted later
    int256[] public winning_point_during_processing; //this is to be deleted later, it stores the value of the winning point through out the process

    function determineWinner() public returns (address) {
        uint256 randomNumber = fullFillRandomness();
        winningPoint = int256(randomNumber % totalPotUsdValue);
        int256 winning_point = winningPoint;
        address pot_winner;

        for (uint256 index = 0; index < entriesAddress.length; index++) {
            winning_point_during_processing.push(winning_point);
            winning_point -= int256(entriesUsdValue[index]);
            if (winning_point <= 0) {
                //That means that the winner has been found here
                pot_winner = entriesAddress[index];
                break;
            }
        }
        return pot_winner;
    }

    function getAmountToPayAsFees() public view returns (uint256) {
        string
            memory tokenWithThehighestUsdValue = getPotTokenWithHighestValue();
        return
            (percentageFee *
                totalPotUsdValue *
                10**tokenWhiteList[tokenWithThehighestUsdValue].tokenDecimal) /
            (100 * tokenLatestPriceFeed[tokenWithThehighestUsdValue]);
    }

    function getPotTokenWithHighestValue() public view returns (string memory) {
        string memory tokenWithThehighestUsdValue = tokensInPotNames[0];
        for (uint256 index = 0; index < tokensInPotNames.length - 1; index++) {
            if (
                tokenTotalEntry[tokensInPotNames[index]] + 1 >=
                tokenTotalEntry[tokensInPotNames[index]]
            ) {
                tokenWithThehighestUsdValue = tokensInPotNames[index + 1];
            }
        }
        return tokenWithThehighestUsdValue;
    }

    function startNewPot() public {
        //should be changed to internal later
        if (potStartTime + potDuration <= block.timestamp) {
            for (uint256 index = 0; index < participants.length; index++) {
                delete participantsTotalEntryInUsd[participants[index]];
                for (
                    uint256 index2 = 0;
                    index2 < tokensInPotNames.length;
                    index2++
                ) {
                    delete tokenTotalEntry[tokensInPotNames[index2]];
                    delete participantsTokenEntries[participants[index]][
                        tokensInPotNames[index2]
                    ];
                }
            }
            delete participants;
            delete tokensInPotNames;
            totalPotUsdValue = 0;
            delete entriesAddress;
            delete entriesUsdValue;
            pot_state = POT_STATE.STARTED;
        }
        //This function set all the creterias for starting a new pot
    }

    function payAccount(
        string memory _tokenName,
        address _accountToPay,
        uint256 _tokenValue
    ) public {
        if (keccak256(bytes(_tokenName)) == keccak256(bytes("PULSE"))) {
            payable(_accountToPay).transfer(_tokenValue);
            // (bool sent, bytes memory data) = _to.call{value: msg.value}("");
            // require(sent, "Failed to send Ether");
        } else {
            IPRC20 token = IPRC20(tokenWhiteList[_tokenName].tokenAddress);
            require(
                token.transfer(_accountToPay, _tokenValue),
                "Unable to Send Token"
            );
        }
    }

    function fullFillRandomness() public view returns (uint256) {
        return
            uint256(
                uint128(
                    bytes16(
                        keccak256(
                            abi.encodePacked(block.difficulty, block.timestamp)
                        )
                    )
                )
            );
    }

    receive() external payable {
        require(
            (tokenLatestPriceFeed["PULSE"] * msg.value) / 10**18 >=
                minEntranceFeeInUsd,
            "Amount less than required entrance fee"
        );
        enterPot("PULSE", msg.value);
    }

    function sendPulse() public payable {}
}