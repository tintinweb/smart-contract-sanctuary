/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title HamsterTigerHype
 */
contract HamsterTigerHype {

    // структура пользователя, куда заносится информация о депозите пользователя, времени его инвестов и проверка на участие в программе
    struct User {
        uint256 deposit;
        uint256 time;
        uint256 round;
        uint idx;
    }

    //Данный параметр хранит информацию о структурах всех пользователей, которые участвуют в проекте
    mapping(address => User) users;
    uint8 investorsSize = 20;
    uint8 investedCount = 0;
    //Массив адресов инвесторов, у которых депозит больше 0,05 eth
    address payable[] investors = new address payable[](investorsSize);
    //Адрес последнего инвестораф
    address payable lastInvestor;
    //Рекламный адрес
    address payable advertising;
    //Баланс контракта
    uint256 totalBalance;
    //Время последней отправки процента на рекламный адрес
    uint256 advertisingLast;
    //Время последнего инвеста
    uint256 lastInvest;
    //Общая сумма необходиммая на вывод
    uint256 withdrawSum;
    //Время которое должно пройти для получения выплаты
    uint256 withdrawTime = 1 minutes;
    //Время которое должно пройти для получения выплаты на рекламный счёт
    uint256 advertisingTime = 1 minutes;
    //Время игры тигров
    uint256 tigerGameTime = 2 minutes;
    uint256 round = 1;
    //Тип игры Хомяки/Тигры
    enum GameType {Hamster, Tiger}
    GameType game = GameType.Hamster;
    // Переменная для индексов инвесторов
    uint index = 0;
    event StartHamsterGame();
    event StartTigerGame();
    event SendETH(address, uint256);

    constructor() {
        advertising = payable(msg.sender);
        advertisingLast = block.timestamp;
        lastInvest = block.timestamp;
    }

    //Вывод средств или инвестирвоание
    function delegate() payable public {
        withdrawDividends();
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    //функция вывода средств(вызывается при отправке 0 eth)
    function withdraw() internal {
        User storage user = users[msg.sender];
        uint256 payout = user.deposit / 5;
        uint256 period = block.timestamp - user.time;
        // при работе режима мультипликатора функция не позволяет вывести средства
        require(game == GameType.Hamster, "Only invest");
        // если все условия соблюдены, то пользователю выплачивается сумма его ежедневных выплат
        require(period > withdrawTime, "Time error");
        if (payable(msg.sender).send(payout)) {
            user.time = block.timestamp;
            emit SendETH(msg.sender, payout);
        }
        if (withdrawSum > address(this).balance) {
            game = GameType.Tiger;
            emit StartTigerGame();
            lastInvest = block.timestamp;
        }
    }

    //функция инвест срабатывает при поступлении средств на контракт
    function invest() internal {
        uint balance = address(this).balance;
        investmentOperations();
        if (game == GameType.Hamster) {
            if (withdrawSum > balance) {
                //если больше (investorsSize - настройка) участников с депозитом больше 0.05 eth, то включается режим тигров
                if (investors.length >= investorsSize) {
                    game = GameType.Tiger;
                    emit StartTigerGame();
                }
            }
        } else {
            if (withdrawSum < balance) {
                game = GameType.Hamster;
                emit StartHamsterGame();
            } else {
                if (block.timestamp - lastInvest > tigerGameTime) {
                    multiplier();
                    emit StartHamsterGame();
                    game = GameType.Hamster;
                }
            }
        }
        lastInvest = block.timestamp;
    }

    //внутренняя логика функции инвест
    function investmentOperations() internal {
        User storage user = users[msg.sender];
        if (user.round != round) {
            user.round = round;
            user.deposit = 0;
        }
        if (lastInvestor != msg.sender) {
            if (msg.value >= 0.05 ether) {
                if (investors[user.idx] != msg.sender) {
                    investedCount++;
                    uint idx = addInvestor(payable(msg.sender));
                    user.idx = idx;
                }
                lastInvestor = payable(msg.sender);
            }
        }
        //Обновляем информация пользователя
        user.deposit += msg.value;
        user.time = block.timestamp;

        totalBalance += msg.value;
        withdrawSum += msg.value / 5;
    }

    // Получить следующий индекс для массива инветоров
    function getIndex(uint num) internal view returns (uint){
        return (index + num) % investorsSize;
    }

    //Добовляем инвестора в список
    function addInvestor(address payable investor) public returns (uint) {
        index = getIndex(1);
        investors[index] = investor;
        return index;
    }

    //Режим мультипликатора(срабатывает при превышении суммы ежедневных выплат над балансом контракта)
    function multiplier() internal {
        uint256 one = address(this).balance / 100;
        uint256 twentieth = one * 20;
        uint256 five = one * 5;
        address payable[] memory sorted = sort();
        for (uint256 i = 0; i < investorsSize; i++) {
            address payable to = sorted[i];
            if (i == 0) {
                to.transfer(twentieth);
                emit SendETH(to, twentieth);
            } else if (i >= 1 && i <= 10) {
                to.transfer(five);
                emit SendETH(to, five);
            } else {
                to.transfer(one);
                emit SendETH(to, one);
            }
        }
        advertising.transfer(twentieth);
        delete investors;
        withdrawSum = 0;
        totalBalance = 0;
        investedCount = 0;
        round++;
    }

    //Функция отправки средств на рекламный адрес(вызывается при использовании внутренней логики контракта пользователями)
    function withdrawDividends() internal {
        if (totalBalance > 0 && block.timestamp - advertisingLast > advertisingTime) {
            uint256 dividends = totalBalance * 10 / 100;
            advertising.transfer(dividends);
            totalBalance = 0;
            advertisingLast = block.timestamp;
        }
    }

    // Функция сортировки инвесторов по времени инвестирования
    function sort() internal view returns (address payable[] memory) {
        address payable[] memory sorting = investors;
        uint256 l = investorsSize;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                uint us1 = 0;
                uint us2 = 0;
                if(investors[i] != address(0)){
                    us1 = users[sorting[i]].time;
                }
                if(investors[j] != address(0)){
                    us2 = users[sorting[j]].time;
                }
                if(us1 < us2) {
                    address payable temp = sorting[i];
                    sorting[i] = sorting[j];
                    sorting[j] = temp;
                }
            }
        }
        return sorting;
    }

    function getInvestors() public view returns (address payable [] memory) {
        return investors;
    }

    function getDeposit(address _address) public view returns (uint256) {
        return users[_address].deposit;
    }

    function getLastInvest() public view returns (uint256) {
        return lastInvest;
    }

    function getWithdrawSum() public view returns (uint256) {
        return withdrawSum;
    }

    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }

    function getRound() public view returns (uint256) {
        return round;
    }

    function getAdvertisingLast() public view returns (uint256) {
        return advertisingLast;
    }

    function getLastInvestor() public view returns (address payable) {
        return lastInvestor;
    }

    function getInvestedCount() public view returns (uint256) {
        return investedCount;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getGame() public view returns (GameType) {
        return game;
    }
}