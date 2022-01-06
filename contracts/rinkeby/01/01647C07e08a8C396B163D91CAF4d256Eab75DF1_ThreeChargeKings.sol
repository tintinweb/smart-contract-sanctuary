/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.9 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ThreeChargeKings {
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private emptyAccount = 0x7b5B82967246A040Df465715362ECd390ead34BE;
    address private devAddress = 0xA8544199b573dbeFd2a1388820B527E01C3184CA;
    //address private reviewerAddress = 0xcC8376Ff36424C02EbfE35f5E7C202084789B345;
    address private reviewerAddress = 0xA8544199b573dbeFd2a1388820B527E01C3184CA;

    address[3] private threeKings = [emptyAccount,emptyAccount,emptyAccount];

    address payable private owner_;
    IERC20 chargeContract;
    address private chargeContractAddress;
    bool private lock = false;
    uint private dayCount = 30 seconds;//1 days;

    mapping(address => uint) balances;
    mapping(address => uint) pieBonus;
    mapping(address => uint) stakeBalances;
    mapping(address => uint) threeKingsLockTimes;
    mapping(address => uint) stakeLockTimes;

    address[] balanceKeys;
    uint totalAmount;
    uint totalChargeStaked;

    constructor(address _address) {
        chargeContractAddress = _address;
        chargeContract = IERC20(_address);
        owner_ = payable(msg.sender);   
    }

    function stakeCharge(uint256 amount) external {
        require(amount > 0, "You need to deposit at least something");
        uint256 allowance = chargeContract.allowance(msg.sender, address(this));
        require(allowance >= amount, "Not enough allowance");
        require(chargeContract.transferFrom(msg.sender, address(this), amount));
        require(lock == false);
        lock = true;

        _needsToAppend();

        uint burnTax = amount / 20;
        uint distributeAmount = amount / 20;
        uint threeKingsTax = amount / 100;
        uint devTax = amount / 100;

        uint totalAmountToAdd = amount - burnTax - distributeAmount - threeKingsTax - devTax;

        stakeBalances[msg.sender] += totalAmountToAdd;
        totalChargeStaked += totalAmountToAdd;

        stakeLockTimes[msg.sender] = block.timestamp + dayCount;

        uint count = balanceKeys.length;
        for (uint i=0; i < count; i++) {
            if(msg.sender != balanceKeys[i]) {
                uint stakePercent = _stakeFromDistribution(balanceKeys[i], distributeAmount);
                pieBonus[balanceKeys[i]] += stakePercent;
            }
        }

        lock = false;
        require(chargeContract.transfer(devAddress, devTax));
        require(chargeContract.transfer(deadAddress, burnTax));
    }

    function unStake() external {
        require(totalChargeStaked > 0, "Not enough charge staked");
        require(stakeBalances[msg.sender] > 0, "User has nothing staked");
        require(block.timestamp > stakeLockTimes[msg.sender], "Lock time has not expired yet");

        require(lock == false);
        lock = true;

        uint piBonus = (balances[msg.sender] == 0) ? pieBonus[msg.sender] : 0;
        uint amountPotential = stakeBalances[msg.sender];

        if(balances[msg.sender] == 0) {
            pieBonus[msg.sender] = 0;
        }
        stakeBalances[msg.sender] = 0;
        totalChargeStaked -= amountPotential;

        lock = false;
        require(chargeContract.transfer(msg.sender, amountPotential + piBonus));
    }

    receive() external payable {
        require(lock == false);

        uint devTax = msg.value / 400;
        if(msg.value > 0) {
            // there is a require in the else branch
            // that we need to check before locking
            // thats why its within each branch
            lock = true;

            threeKingsLockTimes[msg.sender] = block.timestamp + dayCount;
            _handleDeposit(devTax);

            lock = false;
        } else {
            require(balances[msg.sender] > 0);
            require(block.timestamp > threeKingsLockTimes[msg.sender], "Lock time has not expired yet");
            lock = true;

            devTax = balances[msg.sender] / 400;
            uint amountToSend = _handleFundsReturn(devTax);

            lock = false;
            
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
        }
        uint reviewerCut = devTax / 10;
        (bool sentDev, ) = devAddress.call{value: devTax - reviewerCut}("");
        (bool sentReviewer, ) = reviewerAddress.call{value: reviewerCut}("");
        require(sentDev, "Failed to send Ether");
        require(sentReviewer, "Failed to send Ether");
    }

    function _handleDeposit(uint devTax) internal {
        uint amount = msg.value - devTax;
        balances[msg.sender] += amount;
        totalAmount += amount;
        _needsToAppend();
        _updateKing();
    }

    function _needsToAppend() internal {
        uint count = balanceKeys.length;
        bool needsToAppend = true;
        for (uint i=0; i < count; i++) {
            if(balanceKeys[i] == msg.sender) {
                needsToAppend = false;
                break;
            }
        }
        if(needsToAppend) {
            balanceKeys.push(msg.sender);
        }
    }

    function _handleFundsReturn(uint devTax) internal returns (uint) {
        uint amountToRedistribute = _sendTokenAmount() / 20;
        uint potential = _sendTokenAmount() - amountToRedistribute;

        uint amountToSend = balances[msg.sender] - devTax;
        balances[msg.sender] = 0;
        totalAmount -= amountToSend;
        totalAmount -= devTax;

        if(isThreeKing(msg.sender)) {
            uint balanceKeysCount = balanceKeys.length;
            if(balanceKeysCount > 3) {
                balanceKeysCount -= 3;
            } else if(balanceKeysCount == 0) {
                lock = false;
                require(false, "Balance keys need to exist");
            }

            uint sliceOfPie = amountToRedistribute / balanceKeysCount;
                uint count = balanceKeys.length;
                for (uint i=0; i < count; i++) {
                    if(threeKings[0] != balanceKeys[i]
                    && threeKings[1] != balanceKeys[i]
                    && threeKings[2] != balanceKeys[i]) {
                        pieBonus[balanceKeys[i]] += sliceOfPie;
                    }
                }
        } else {
            uint sliceOfPie = amountToRedistribute / 3;
            for (uint i=0; i < 3; i++) {
                if(threeKings[i] == emptyAccount) {
                    continue;
                }
                pieBonus[threeKings[i]] += sliceOfPie;
            }
        }

        uint piBonusForUser = pieBonus[msg.sender];
        pieBonus[msg.sender] = 0;
        uint chargeToPayout = potential + piBonusForUser;
        uint amountToBurn = chargeToPayout / 20;

        _resetKing();

        if(chargeToPayout <= totalThreeChargeKingBalance()) {
            // we unlock twice if we hit this branch
            // never want to leave the contract in a locked state
            lock = false;
            require(chargeContract.transfer(deadAddress, amountToBurn));
            require(chargeContract.transfer(msg.sender, chargeToPayout - amountToBurn));
        }
        return amountToSend;
    }

    function _updateKing() internal {
        uint amount = balances[msg.sender];
        uint oldKingOne = balances[threeKings[0]];
        uint oldKingTwo = balances[threeKings[1]];
        uint oldKingThree = balances[threeKings[2]];

        if(oldKingOne < amount) {
            threeKings[2] = threeKings[1];
            threeKings[1] = threeKings[0];
            threeKings[0] = msg.sender;
        } else if(oldKingTwo < amount) {
            threeKings[2] = threeKings[1];
            threeKings[1] = msg.sender;
        } else if(oldKingThree < amount) {
            threeKings[2] = msg.sender;
        }
    }

    function _resetKing() internal {
        uint count = balanceKeys.length;
        uint rollingCurrentBalance;
        address currentAddressToReplace = emptyAccount;
        for (uint i=0; i < count; i++) {
            if(threeKings[0] != balanceKeys[i]
               && threeKings[1] != balanceKeys[i]
               && threeKings[2] != balanceKeys[i]
               && balances[balanceKeys[i]] > rollingCurrentBalance) {
                   rollingCurrentBalance = balances[balanceKeys[i]];
                   currentAddressToReplace = balanceKeys[i];
               }
        }
        
        if(threeKings[0] == msg.sender) {
            threeKings[0] = threeKings[1];
            threeKings[1] = threeKings[2];
            threeKings[2] = currentAddressToReplace;
        } else if(threeKings[1] == msg.sender) {
            threeKings[1] = threeKings[2];
            threeKings[2] = currentAddressToReplace;
        } else if(threeKings[2] == msg.sender) {
            threeKings[2] = currentAddressToReplace;
        }
    }

    function updateChargeContract(address newAddress) external {
        require(msg.sender == owner_, "You are not the owner");

        chargeContractAddress = newAddress;
        chargeContract = IERC20(newAddress);
        uint count = balanceKeys.length;
        for(uint i = 0; i < count; i++) {
            pieBonus[balanceKeys[i]] = 0;
            stakeBalances[balanceKeys[i]] = 0;
            stakeLockTimes[balanceKeys[i]] = 0;
            threeKingsLockTimes[balanceKeys[i]] = 0;
        }
    }

    function getTokens(address tokenAddress) external {
        require(msg.sender == owner_, "You are not the owner");
        require(tokenAddress != chargeContractAddress, "Sorry bro that would be unfair");
        
        IERC20 found = IERC20(tokenAddress);
        uint256 contract_token_balance = found.balanceOf(address(this));
        require(contract_token_balance != 0);
        require(found.transfer(owner_, contract_token_balance));
    }

    function _stakeFromDistribution(address forAddress, uint distributeAmount) view internal returns (uint) {
        if(totalChargeStaked == 0) return 0;
        return (stakeBalances[forAddress] * distributeAmount) / totalChargeStaked;
    }

    function _sendTokenAmount() view internal returns (uint) {
        if(totalThreeChargeKingBalance() > 0) {
            uint potential;
            if(threeKings[0] == msg.sender) {
                potential = totalThreeChargeKingBalance() / 2;
            } else if(threeKings[1] == msg.sender || threeKings[2] == msg.sender) {
                potential = totalThreeChargeKingBalance() / 4;
            } else {
                potential = totalThreeChargeKingBalance() / 2000;
            }
            return potential;
        }
        return 0;
    }

    function isThreeKing(address addressInQuestion) view public returns (bool) {
        bool isKing = false;
        for (uint i=0; i < 3; i++) {
            if(threeKings[i] == addressInQuestion) {
                isKing = true;
                break;
            }
        }
        return isKing;
    }

    function totalThreeChargeKingBalance() view public returns (uint) {
        return chargeContract.balanceOf(address(this)) - totalChargeStaked;
    }

    function totalEthBalance() view public returns (uint) {
        return totalAmount;
    }

    function ethForAddress(address forAddress) view public returns (uint) {
        return balances[forAddress];
    }

    function chargeForAddress(address toFind) view public returns (uint) {
        return stakeBalances[toFind];
    }

    function pieBonusForAddress(address forAddress) view public returns (uint) {
        return pieBonus[forAddress];
    }

    function firstKing() view public returns (address) {
        return threeKings[0];
    }

    function secondKing() view public returns (address) {
        return threeKings[1];
    }

    function thirdKing() view public returns (address) {
        return threeKings[2];
    }

    function firstKingBalance() view public returns (uint) {
        return balances[threeKings[0]];
    }

    function secondKingBalance() view public returns (uint) {
        return balances[threeKings[1]];
    }

    function thirdKingBalance() view public returns (uint) {
        return balances[threeKings[2]];
    }
}