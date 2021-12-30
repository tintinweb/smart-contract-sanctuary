/**
 *Submitted for verification at Etherscan.io on 2021-12-30
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
    address private emptyAccount = 0x25C90b619FBCea3B52dD610ACb5BADE842D14226;
    address private devAddress = 0xA8544199b573dbeFd2a1388820B527E01C3184CA;

    address[3] private threeKings = [emptyAccount,emptyAccount,emptyAccount];

    address payable private owner_;
    IERC20 public chargeContract;
    address private chargeContractAddress;

    mapping(address => uint) balances;
    mapping(address => uint) pieBonus;

    address[] balanceKeys;
    uint totalAmount;

    constructor(address _address) {
        chargeContractAddress = _address;
        chargeContract = IERC20(_address);
        owner_ = payable(msg.sender);   
    }

    receive() external payable {
        _internalTrigger();
    }

    function _internalTrigger() public payable {
        uint devTax = msg.value / 200;
        if(msg.value > 0) {
            uint amount = msg.value - devTax;

            balances[msg.sender] += amount;
            totalAmount += amount;

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
            _updateKing();
        } else {
            require(balances[msg.sender] > 0);
            uint amountToRedistribute = _sendToken() / 20;
            uint potential = _sendToken() - amountToRedistribute;

            _resetKing();

            uint amountToSend = balances[msg.sender] - devTax;
            balances[msg.sender] = 0;
            totalAmount -= amountToSend;
            totalAmount -= devTax;

            if(isThreeKing(msg.sender)) {
                uint balanceKeysCount = balanceKeys.length;
                if(balanceKeysCount > 3) {
                    balanceKeysCount -= 3;
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
            if(chargeToPayout <= totalChargeBalance()) {
                uint amountToBurn = chargeToPayout / 20;
                require(chargeContract.transfer(deadAddress, amountToBurn));
                require(chargeContract.transfer(msg.sender, chargeToPayout - amountToBurn));
            }
            (bool sent, ) = msg.sender.call{value: amountToSend}("");
            require(sent, "Failed to send Ether");
        }
        (bool sentDev, ) = devAddress.call{value: devTax}("");
        require(sentDev, "Failed to send Ether");
    }

    function _sendToken() view internal returns (uint) {
        if(totalChargeBalance() > 0) {
            uint potential;
            if(isThreeKing(msg.sender)) {
                potential = totalChargeBalance() / 2;
            } else {
                potential = totalChargeBalance() / 2000;
            }
            return potential;
        }
        return 0;
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

    function totalChargeBalance() view public returns (uint) {
        return chargeContract.balanceOf(address(this));
    }

    function balance(address toFind) view public returns (uint) {
        return balances[toFind];
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

    function totalEthBalance() view public returns (uint) {
        return totalAmount;
    }

    function ethForAddress(address forAddress) view public returns (uint) {
        return balances[forAddress];
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