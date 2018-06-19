pragma solidity ^0.4.8;
contract token { function transfer(address receiver, uint amount) returns (bool) {  } }

contract LuxPresale {
    address public beneficiary;
    uint public totalLux; uint public amountRaised; uint public deadline; uint public price; uint public presaleStartDate;
    token public tokenReward;
    mapping(address => uint) public balanceOf;
    bool fundingGoalReached = false; //закрыт ли сбор денег
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool crowdsaleClosed = false;

    /* data structure to hold information about campaign contributors */

    /*  at initialization, setup the owner */
    function LuxPresale(
        address ifSuccessfulSendTo,
        uint fundingGoalInLux,
        uint startDate,
        uint durationInMinutes,
        token addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        totalLux = fundingGoalInLux * 100; // сколько люксов раздадим
        presaleStartDate = startDate; // дата начала пресейла
        deadline = startDate + durationInMinutes * 1 minutes;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    
    function () payable {
        if (now < presaleStartDate) throw; // A participant cannot send funds before the presale start date

        if (crowdsaleClosed) { // выплачиваем токины 
			if (msg.value > 0) throw; // если после закрытия перечисляем эфиры
            uint reward = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (reward > 0) {
                if (!tokenReward.transfer(msg.sender, reward/price)) {
                    balanceOf[msg.sender] = reward;
                }
            }        
        } else { // Сохраняем данные о том кто сколько заплатил
            uint amount = msg.value; // сколько переведено средств
            balanceOf[msg.sender] += amount; // обновляем баланс
            amountRaised += amount; // увеличиваем сумму собранных денег
        }
    }
    
    modifier afterDeadline() { if (now >= deadline) _; }
    
    modifier onlyOwner() {
        if (msg.sender != beneficiary) {
            throw;
        }
        _;
    }

    /* checks if the goal or time limit has been reached and ends the campaign */
    /* закрываем сбор денег */
    function setGoalReached() afterDeadline {
        if (amountRaised == 0) throw; // если не собрали денег
        if (crowdsaleClosed) throw; // попытка второй раз закрыть
        crowdsaleClosed = true;
        price = amountRaised/totalLux; // цена 1 люкса
    }

    /*  */
    function safeWithdrawal() afterDeadline onlyOwner {
        if (!crowdsaleClosed) throw;
        if (beneficiary.send(amountRaised)) {
            FundTransfer(beneficiary, amountRaised, false);
        }
    }
}