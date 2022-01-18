/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.11 <0.9.0;

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
    bool private lock = false;
    uint private dayCount = 30 seconds;//1 days;

    uint reviewETHBalance;
    uint devETHBalance;
    uint burnChargeAmount;
    uint totalChargeStaked;
    uint totalPieBonus;
    uint currentJuice;

    IERC20 chargeContract;
    address private owner_;
    address private chargeContractAddress;

    address private constant emptyAccount = 0x7b5B82967246A040Df465715362ECd390ead34BE;
    address private constant devAddress = 0xA8544199b573dbeFd2a1388820B527E01C3184CA;
    address private constant reviewerAddress = 0xcC8376Ff36424C02EbfE35f5E7C202084789B345;

    address[3] private threeKings = [emptyAccount,emptyAccount,emptyAccount];

    mapping(address => uint) balances;
    mapping(address => uint) pieBonus;
    mapping(address => uint) stakeBalances;
    mapping(address => uint) threeKingsLockTimes;
    mapping(address => uint) stakeLockTimes;
    mapping(address => bool) addressExists;

    address[] balanceKeys;

    constructor(address _address) {
        chargeContractAddress = _address;
        chargeContract = IERC20(_address);
        owner_ = msg.sender;   
    }

    //
    //  The first thing you have to do is jump in zPool
    //  The UI will make sure the user does this
    //
    function z_jumpInThePool() external {
        require(addressExists[msg.sender] == false, "You are in the pool already");
        addressExists[msg.sender] = true;
        balanceKeys.push(msg.sender);
    }

    function a_stakeCharge(uint256 amount) external {
        _checkAllowance(amount);
        require(chargeContract.transferFrom(msg.sender, address(this), amount));
        
        require(lock == false);
        lock = true;

        uint disPercent = amount / 8;
        uint totalAmountToAdd = amount - disPercent;

        currentJuice += disPercent;
        totalChargeStaked += totalAmountToAdd;
        stakeBalances[msg.sender] += totalAmountToAdd;
        stakeLockTimes[msg.sender] = block.timestamp + dayCount;

        lock = false;
    }

    function a_unStake() external {
        require(stakeBalances[msg.sender] > 0, "User has nothing staked");
        require(block.timestamp > stakeLockTimes[msg.sender], "Lock time has not expired yet");

        require(lock == false);
        lock = true;

        uint piBonus = pieBonus[msg.sender];
        uint amountPotential = stakeBalances[msg.sender];

        totalChargeStaked -= amountPotential;
        totalPieBonus -= piBonus;

        pieBonus[msg.sender] = 0;
        stakeBalances[msg.sender] = 0;

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
            handleETHCutLogic(devTax);
            handleDeposit(devTax);

            lock = false;
        } else {
            require(balances[msg.sender] > 0);
            require(block.timestamp > threeKingsLockTimes[msg.sender], "Lock time has not expired yet");
            lock = true;

            devTax = balances[msg.sender] / 400;

            handleETHCutLogic(devTax);
            uint amountToSend = handleFundsReturn(devTax);

            lock = false;
            
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
        }
    }

    function handleETHCutLogic(uint devTax) private {
        uint reviewerTax = devTax / 10;
        devETHBalance += devTax - reviewerTax;
        reviewETHBalance += reviewerTax;
    }

    function handleDeposit(uint devTax) private {
        uint amount = msg.value - devTax;
        balances[msg.sender] += amount;
        updateKing(balances[msg.sender]);
    }

    function handleFundsReturn(uint devTax) private returns (uint) {
        uint amountToRedistribute = sendTokenAmount() / 10;
        uint potential = sendTokenAmount() - amountToRedistribute;

        uint amountToSend = balances[msg.sender] - devTax;
        balances[msg.sender] = 0;

        currentJuice += amountToRedistribute;

        uint piBonusForUser = pieBonus[msg.sender];
        totalPieBonus -= piBonusForUser;
        pieBonus[msg.sender] = 0;
        uint chargeToPayoutPotential = potential + piBonusForUser;
        
        if(isThreeKing(msg.sender)) {
            resetKing();
        }

        if(chargeToPayoutPotential <= totalThreeChargeKingBalance()) {
            // we unlock twice if we hit this branch
            // never want to leave the contract in a locked state
            lock = false;
            require(chargeContract.transfer(msg.sender, chargeToPayoutPotential));
        }
        return amountToSend;
    }

    function updateKing(uint newBalance) private {
        uint oldKingOne = balances[threeKings[0]];
        uint oldKingTwo = balances[threeKings[1]];
        uint oldKingThree = balances[threeKings[2]];

        if(isThreeKing(msg.sender)) {
            if(msg.sender == threeKings[1] && oldKingOne < newBalance) {
                threeKings[1] = threeKings[0];
                threeKings[0] = msg.sender;
            } else if(msg.sender == threeKings[2] && oldKingTwo < newBalance && oldKingOne >= newBalance) {
                threeKings[2] = threeKings[1];
                threeKings[1] = msg.sender;
            } else if(msg.sender == threeKings[2] && oldKingOne < newBalance) {
                threeKings[2] = threeKings[1];
                threeKings[1] = threeKings[0];
                threeKings[0] = msg.sender;
            }
        } else if(oldKingOne < newBalance) {
            threeKings[2] = threeKings[1];
            threeKings[1] = threeKings[0];
            threeKings[0] = msg.sender;
        } else if(oldKingTwo < newBalance) {
            threeKings[2] = threeKings[1];
            threeKings[1] = msg.sender;
        } else if(oldKingThree < newBalance) {
            threeKings[2] = msg.sender;
        }
    }

    function resetKing() private {
        uint count = balanceKeys.length;
        uint rollingCurrentBalance;
        address currentAddressToReplace = emptyAccount;
        
        for (uint i=0; i < count; i++) {
            if(isThreeKing(balanceKeys[i]) == false
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

    function z_updateChargeContract(address newAddress) external {
        require(msg.sender == owner_, "You are not the owner");

        chargeContractAddress = newAddress;
        chargeContract = IERC20(newAddress);
        uint count = balanceKeys.length;
        for(uint i = 0; i < count; i++) {
            pieBonus[balanceKeys[i]] = 0;
        }

        totalPieBonus = 0;
        totalChargeStaked = 0;
        burnChargeAmount = 0;
        currentJuice = 0;
    }

    function z_getTokens(address tokenAddress) external {
        require(msg.sender == owner_, "You are not the owner");
        require(tokenAddress != chargeContractAddress, "Sorry bro that would be unfair");
        
        IERC20 found = IERC20(tokenAddress);
        uint256 contract_token_balance = found.balanceOf(address(this));
        require(contract_token_balance != 0);
        require(found.transfer(owner_, contract_token_balance));
    }

    function stakeFromDistribution(address forAddress, uint distributeAmount) view internal returns (uint) {
        if(totalChargeStaked == 0) return 0;
        return (stakeBalances[forAddress] * distributeAmount) / totalChargeStaked;
    }

    function sendTokenAmount() view private returns (uint) {
        if(totalThreeChargeKingBalance() > 0) {
            uint potential;
            if(threeKings[0] == msg.sender) {
                potential = totalThreeChargeKingBalance() / 2;
            } else if(threeKings[1] == msg.sender) {
                potential = totalThreeChargeKingBalance() / 4;
            } else if(threeKings[2] == msg.sender) {
                potential = totalThreeChargeKingBalance() / 5;
            } else {
                potential = totalThreeChargeKingBalance() / 100;
            }
            return potential;
        }
        return 0;
    }

    function shareTheJuice() external {
        shareTheJuiceWithEveryone(0);
    }

    function distributeRewards(uint256 amount) external {
        _checkAllowance(amount);
        require(chargeContract.transferFrom(msg.sender, address(this), amount));
        shareTheJuiceWithEveryone(amount);
    }

    function shareTheJuiceWithEveryone(uint amount) private {
        require(lock == false);
        lock = true;

        uint halfPercent = currentJuice / 200;
        uint fivePercent = currentJuice / 20;

        totalPieBonus += halfPercent + halfPercent;
        pieBonus[reviewerAddress] += halfPercent;
        pieBonus[devAddress] += halfPercent;

        burnChargeAmount += fivePercent;

        uint distributeAmount = (amount / 2) + (currentJuice - (halfPercent + halfPercent) - fivePercent - fivePercent);
        currentJuice = 0;
        uint count = balanceKeys.length;
        for (uint i = 0; i < count; i++) {
            uint stakePercent = stakeFromDistribution(balanceKeys[i], distributeAmount);
            totalPieBonus += stakePercent;
            pieBonus[balanceKeys[i]] += stakePercent;
        }

        lock = false;
    }

    function z_devETH() external {
        require(msg.sender == devAddress);
        require(devETHBalance > 0);
        require(address(this).balance >= devETHBalance);
        require(lock == false);
        lock = true;
        uint amountToSend = devETHBalance;
        devETHBalance = 0;
        lock = false;
        (bool sent, ) = msg.sender.call{value: amountToSend}("");
        require(sent, "Failed to send Ether");
    }
    
    function z_reviewerETH() external {
        require(msg.sender == reviewerAddress);
        require(reviewETHBalance > 0);
        require(address(this).balance >= reviewETHBalance);
        require(lock == false);
        lock = true;
        uint amountToSend = reviewETHBalance;
        reviewETHBalance = 0;
        lock = false;
        (bool sent, ) = msg.sender.call{value: amountToSend}("");
        require(sent, "Failed to send Ether");
    }

    function z_devCharge() external {
        require(msg.sender == devAddress);
        require(pieBonus[devAddress] > 0);
        require(lock == false);
        lock = true;
        uint amountToSend = pieBonus[devAddress];
        totalPieBonus -= amountToSend;
        pieBonus[devAddress] = 0;
        lock = false;
        require(chargeContract.transfer(msg.sender, amountToSend));
    }
    
    function z_reviewerCharge() external {
        require(msg.sender == reviewerAddress);
        require(pieBonus[reviewerAddress] > 0);
        require(lock == false);
        lock = true;
        uint amountToSend = pieBonus[reviewerAddress];
        totalPieBonus -= amountToSend;
        pieBonus[reviewerAddress] = 0;
        lock = false;
        require(chargeContract.transfer(msg.sender, amountToSend));
    }
    
    function z_zburnCharge() external {
        require(burnChargeAmount > 0);
        require(chargeContract.balanceOf(address(this)) >= burnChargeAmount);
        require(lock == false);
        lock = true;
        uint amountToSend = burnChargeAmount;
        burnChargeAmount = 0;
        lock = false;
        require(chargeContract.transfer(0x000000000000000000000000000000000000dEaD, amountToSend));
    }

    function _checkAllowance(uint amount) private view {
        require(chargeContract.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
    }

    function isThreeKing(address addressInQuestion) view public returns (bool) {
        if(addressInQuestion == threeKings[0]
            || addressInQuestion == threeKings[1]
            || addressInQuestion == threeKings[2]) {
            return true;
        }
        return false;
    }

    function totalThreeChargeKingBalance() view public returns (uint) {
        return chargeContract.balanceOf(address(this)) - totalChargeStaked - totalPieBonus - burnChargeAmount - currentJuice;
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

    function juiceAmount() view public returns (uint) {
        return currentJuice;
    }

    function burnAmount() view public returns (uint) {
        return burnChargeAmount;
    }
    
    function zDevETHBalance() view public returns (uint) {
        return devETHBalance;
    }

    function zReviewBalance() view public returns (uint) {
        return reviewETHBalance;
    }

    function _isInThePool(address user) view public returns (bool) {
        return addressExists[user];
    }

    function currentPotentialStakingBonus(address user) view public returns (uint) {
        uint onePercent = currentJuice / 100;
        uint tenPercent = currentJuice / 10;
        uint distributeAmount = (currentJuice - onePercent - tenPercent);
        uint count = balanceKeys.length;
        uint valueToReturn = 0;
        for (uint i = 0; i < count; i++) {
            if(user == balanceKeys[i]) {
                valueToReturn = stakeFromDistribution(balanceKeys[i], distributeAmount);
                break;
            }
        }
        return valueToReturn;
    }
}