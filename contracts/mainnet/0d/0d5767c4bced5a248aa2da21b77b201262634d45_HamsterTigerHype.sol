/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract HamsterTigerHype {

    // структура пользователя, куда заносится информация о депозите пользователя, времени его инвестов и проверка на участие в программе
    struct User {
        uint256 deposit;
        uint256 time;
        uint256 timeDeposit;
        uint256 round;
        uint idx;
    }

    //Данный параметр хранит информацию о структурах всех пользователей, которые участвуют в проекте
    mapping(address => User) users;
    //Массив адресов инвесторов, у которых депозит больше минимального (minValueInvest - настройка)
    address payable[] investors = new address payable[](5);
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
    // Минимальная сумма для участия в режиме Тигров
    uint256 minValueInvest = 0.05 ether;
    // Раунд
    uint256 round = 1;
    //Тип игры Хомяки/Тигры
    enum GameType {Hamster, Tiger}
    GameType game = GameType.Hamster;
    // Переменная для индексов инвесторов
    uint index = 0;
    // Подсчёт инвесторов
    uint8 investedCount = 0;
    // Событие старта игры Хомяков
    event StartHamsterGame();
    // Событие старта игры Тигров
    event StartTigerGame();

    constructor() {
        advertising = payable(msg.sender);
        advertisingLast = block.timestamp;
        lastInvest = block.timestamp;
    }

    //Вывод средств или инвестирвоание
    receive() external payable {
        withdrawDividends();
        if (msg.value > 0) {
            invest();
        } else {
            withdraw();
        }
    }

    //функция вывода средств(вызывается при отправке 0 eth)
    function withdraw() internal {
        User storage user = users[msg.sender];
        if (user.round != round) {
            user.round = round;
            user.deposit = 0;
            user.timeDeposit = 0;
            user.time = 0;
        }
        uint256 payout = user.deposit / 5;
        uint256 period = block.timestamp - user.time;
        // при работе режима тигров функция не позволяет вывести средства
        require(game == GameType.Hamster, "Only invest");
        // если все условия соблюдены, то пользователю выплачивается сумма его ежедневных выплат
        require(period > withdrawTime, "Very early");
        require(payout > 0, "Deposit is Zero");
        if (payable(msg.sender).send(payout)) {
            user.time = block.timestamp;
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
                //если больше 5 участников с депозитом больше (настройки-minValueInvest), то включается режим тигров
                if (investors.length >= 5) {
                    game = GameType.Tiger;
                    emit StartTigerGame();
                }
            }
        } else {
            // если сумма баланса больше суммы которую нужно выплатить в 2 раза включается режим хомяков
            if ((withdrawSum * 2) < balance) {
                game = GameType.Hamster;
                emit StartHamsterGame();
            } else {
                if (msg.value >= minValueInvest && block.timestamp - lastInvest > tigerGameTime) {
                    multiplier();
                    emit StartHamsterGame();
                    game = GameType.Hamster;
                }
            }
        }
        if(msg.value >= minValueInvest){
            lastInvest = block.timestamp;
        }
    }

    //внутренняя логика функции инвест
    function investmentOperations() internal {
        User storage user = users[msg.sender];
        if (user.round != round) {
            user.round = round;
            user.deposit = 0;
            user.timeDeposit = 0;
            user.time = 0;
        }
        // Если последний инвестор не мы заносим в список инвесторов
        if (lastInvestor != msg.sender) {
            if (msg.value >= minValueInvest) {
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
        user.timeDeposit = block.timestamp;
        if(user.time == 0){
            user.time = block.timestamp;
        }

        totalBalance += msg.value / 10;
        withdrawSum += msg.value / 5;
    }

    // Получить следующий индекс для массива инветоров
    function getIndex(uint num) internal view returns (uint){
        return (index + num) % 5;
    }

    //Добовляем инвестора в список
    function addInvestor(address payable investor) internal returns (uint) {
        index = getIndex(1);
        investors[index] = investor;
        return index;
    }

    //Режим мультипликатора(срабатывает при превышении суммы ежедневных выплат над балансом контракта)
    function multiplier() internal {
        uint256 one = address(this).balance / 100;
        uint256 fifty = one * 50;
        uint256 seven = one * 7;
        address payable[] memory sorted = sort();
        for (uint256 i = 0; i < 5; i++) {
            address payable to = sorted[i];
            if (i == 0) {
                to.transfer(fifty);
            } else if (i >= 1 && i <= 4) {
                to.transfer(seven);
            }
        }
        advertising.transfer(one * 22);
        investors = new address payable[](5);
        withdrawSum = 0;
        totalBalance = 0;
        investedCount = 0;
        round++;
    }

    //Функция отправки средств на рекламный адрес(вызывается при использовании внутренней логики контракта пользователями)
    function withdrawDividends() internal {
        if (totalBalance > 0 && address(this).balance > totalBalance && block.timestamp - advertisingLast > advertisingTime) {
            advertising.transfer(totalBalance);
            totalBalance = 0;
            advertisingLast = block.timestamp;
        }
    }

    // Функция сортировки инвесторов по времени инвестирования
    function sort() internal view returns (address payable[] memory) {
        address payable[] memory sorting = investors;
        uint256 l = 5;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                uint us1 = 0;
                uint us2 = 0;
                if(investors[i] != address(0)){
                    us1 = users[sorting[i]].timeDeposit;
                }
                if(investors[j] != address(0)){
                    us2 = users[sorting[j]].timeDeposit;
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
        return users[_address].round != round ? 0 : users[_address].deposit;
    }

    function getWithdrawSum() public view returns (uint256) {
        return withdrawSum;
    }

    function getRound() public view returns (uint256) {
        return round;
    }

    function getLastInvestor() public view returns (address payable) {
        return lastInvestor;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getGame() public view returns (GameType) {
        return game;
    }
}