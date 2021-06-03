/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: Queue

contract Queue {
    //адрес-имя всех участников
    mapping(address => string) peoples;

    struct allowance {
        address addr;
        uint256 timestamp;
    }

    event ParticipantAdded(address _address, string name, uint256 position);
    event TaskCompleted(uint256 oldPos, uint256 newPos);
    event Allowance(address slave, address master);
    event Finalization(address lastAdr, string lastName, uint256 totalLength);
    event ParticipantExchanged(address _address1, string name1, uint256 pos1, address _address2, string name2, uint256 pos2);

    string public eventName;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public maxParticipants;
    uint256 constant TimeoutForChangePosition = 5 minutes;
    address  owner;
    uint256 minFee = 0;
    //указатель на текущего сдающего
    uint256 ESP = 0;
    //    address[] paricipantsList;
    //пример 0x8D56f551b44a6dA6072a9608d63d664ce67681a5 -- место 1
    //пример 0x9CA585bCc394E71A239f59bcF31F32fDB878738C -- место 2
    address[] public queueList;
    //у кого есть права поменяться местами(master-slave) те Петя должен вызвать changePosition()
    //пример Петя(0x8D56f551b44a6dA6072a9608d63d664ce67681a5) -- Вася(0x9CA585bCc394E71A239f59bcF31F32fDB878738C)
    mapping(address => allowance) allowanceList;
    //проверим что запись уже доступна и еще не завершена
    modifier checkTime() {
        require(block.timestamp <= endTime, "Event already finished");
        require(block.timestamp >= startTime, "Event doesn't started");
        _;
    }
    //чекнем огранчения на кол-во участников
    modifier checkMaxParticipants() {
        require(queueList.length < maxParticipants, "A lot of members");
        _;
    }
    //чекнем огранчения на размер минимального платежа
    modifier checkMinFee(uint256 currPayment) {
        require(currPayment >= minFee, "Too small payment");
        _;
    }
    //чекнем огранчения на таймаут обмена позициями
    modifier checkAllowance(address slave) {
        require(allowanceList[msg.sender].addr == slave, "Inccorrect slave address");
        require(block.timestamp - allowanceList[msg.sender].timestamp <= TimeoutForChangePosition, "Timeout for change position");
        _;
    }


    constructor(uint256 start, uint256 end, string memory title, uint256 maxLength, uint256 _minFee, address _owner){
        require(block.timestamp <= start, "Event must not have already begun");
        require(block.timestamp < end, "Event must not have already finished");
        startTime = start;
        endTime = end;
        eventName = title;
        maxParticipants = maxLength;
        minFee = _minFee;
        //        owner = _owner;
    }
    //вернет указатель на текущего сдающего
    function getCurrCompletePosition() external view returns (uint256) {
        return ESP;
    }
    //моя позиция в очереди
    function getMyPosition() external view returns (uint256) {
        return getFromQueueByID(msg.sender);
    }
    //текущая длина при записи
    function getCurrLen() external view returns (uint256) {
        return queueList.length;
    }
    //разрешение участнику поменятся в тобой местами
    function allowanceChangePosition(address whoCanChange) external checkTime {
        require(whoCanChange != address(0));
        allowanceList[whoCanChange].addr = msg.sender;
        allowanceList[whoCanChange].timestamp = block.timestamp;
        emit Allowance(msg.sender, whoCanChange);
    }
    //обмен местами с другом
    function changePosition(address whoIamChanging) external
    checkAllowance(whoIamChanging) checkTime {
        uint256 pos1 = getFromQueueByID(msg.sender);
        uint256 pos2 = getFromQueueByID(whoIamChanging);
        //чтобы не менялись уже те кто сдал лабу
        require(pos1 >= ESP, "This participant has already dropped out of the queue");
        require(pos2 >= ESP, "This participant has already dropped out of the queue");
        address temp = queueList[pos1];
        queueList[pos1] = queueList[pos2];
        queueList[pos2] = temp;

        emit ParticipantExchanged(whoIamChanging, peoples[whoIamChanging], pos1, msg.sender, peoples[msg.sender], pos2);
    }

    //записаться в очередь
    function addToQueue(string memory name) public payable
    checkMinFee(msg.value) checkMaxParticipants checkTime returns (uint256){
        //добавляем в конце очереди
        require(keccak256(bytes(peoples[msg.sender])) == keccak256(bytes("")), "Participant already exist in queue");
        queueList.push(msg.sender);
        peoples[msg.sender] = name;
        //если шлет эфир, то сразу владельцу контракта отправляем
        emit ParticipantAdded(msg.sender, name, queueList.length - 1);
        return queueList.length - 1;
    }

    //сказать всем, что сдал лабу, если пустой слот то пропускаем
    function completeTask() external checkTime {
        uint256 pos = getFromQueueByID(msg.sender);
        //чтобы не подтверждали другие участники
        require(pos == ESP, "Only one persone can confirm that position");
        ESP += 1;
        emit TaskCompleted(ESP - 1, ESP);
        if (ESP == queueList.length)
            emit Finalization(msg.sender, peoples[msg.sender], queueList.length);
    }

    //список адресов участников
    function getParticipantAddresses() external view returns (address[] memory) {
        return queueList;
    }
    //получить список участников
    function getParticipantNames() external view returns (string[] memory) {
        string [] memory names = new string[](queueList.length);
        for (uint256 i = 0; i < queueList.length; i++) {
            names[i] = peoples[queueList[i]];
        }
        return names;
    }


    function getFromQueueByID(address addr) private view returns (uint256){
        for (uint256 i = 0; i < queueList.length; i++) {
            if (queueList[i] == addr)
                return i;
        }
        revert("Participant with that address was not found");
    }

    fallback() external {}
}

// File: Queue.sol

contract Factory {
    mapping(address => Queue)public children;

    event QueueCreated(address ctrctAdr, address ownerAdr);

    function createQueue(uint256 start, uint256 end, string memory title, uint256 maxLength, uint256 _minFee) external returns (address){
        children[msg.sender] = new Queue(start, end, title, maxLength, _minFee, msg.sender);
        //        Queue child = new Queue(start, end, "kek", maxLength, _minFee, msg.sender);
        emit QueueCreated(address(children[msg.sender]), msg.sender);
        return address(children[msg.sender]);
    }

}