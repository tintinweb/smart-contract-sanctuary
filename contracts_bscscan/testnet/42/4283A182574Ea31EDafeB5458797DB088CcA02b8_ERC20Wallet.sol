// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//Кошелек для ETH
contract Wallet {
    
    address payable public Owner; // address Владелец кошелька
    
    uint256 totalEthAmount; //
    
    //ether
    mapping(address => uint256) balances_eth; // Хеш-таблица хранящая остаток на счете
    
    constructor() payable{
        Owner = payable(msg.sender);
        totalEthAmount = 10000;
        balances_eth[Owner] = totalEthAmount;
    }
    
    uint256 public eth_fee; //Комиссия eth
    address payable public constant eth_fee_addr = payable(0x41E9B9ac40A478362315DBbD127EDe37Cb1aa7f1); //Комиссия eth (hardcode)
    
    //event для транзакции
    event Transfer(address from, address to, uint256 amount);
    
    //Баланс
    function balance(address ethOwner) public view returns (uint256){
        return balances_eth[ethOwner];
    }
   
    //Вывод текущей комиссии
    function currentFee() public view returns (uint256){
        return eth_fee;
    }
    //Изменить комиссию
    function changeFee(uint newFee) public {
        require(newFee <= totalEthAmount/10); //В данном примере комиссия должна быть меньше баланса кошелька в 10 раз
        eth_fee = newFee;
    }
    
    //Отправить комиссию
    function transferFee() public payable {
        balances_eth[eth_fee_addr] += eth_fee;
    }
    
    //Отправить ETH
    function sendEther(address payable receiver, uint256 numEther) public payable returns (bool){
        require(balances_eth[msg.sender] >= (numEther + eth_fee), "A");
        balances_eth[msg.sender] -= numEther;
        balances_eth[msg.sender] -= eth_fee;
        transferFee();
        balances_eth[receiver] += numEther;
        emit Transfer(msg.sender,receiver,numEther);
        return true;
    }
}

//В данном контракте реализована возможность: -отпралять/принимать токены, -делать allowance
contract ERC20Wallet{
    
    address public ECO_Owner; // address Владелец кошелька
    
    mapping(address => uint256) balances_eco; // Хеш-таблица хранящая остаток на счете
    mapping(address => mapping (address => uint256)) allowed_eco; // Хеш таблица где счет А дает доступ счету Б доступ к нек. кол-ву токенов
    
    
    constructor(uint256 Ecoin_amount) {
        ECO_Owner = msg.sender;
        balances_eco[ECO_Owner] = Ecoin_amount;
    }
    
    event Transfer(address from, address to, uint256 amount);
    //Event для разрешения на получение средств Получателем от Отправителя
    event ApprovalToken(address indexed tokenOwner, address indexed spender, uint tokens);
    
    function balanceEco(address tokenOwner) public view returns (uint256){
        return balances_eco[tokenOwner];
    }
        //Разрешение на получение средств клиентом Б от клиента А(msg.sender)
    function approve(address delegate, uint numTokens) public returns (bool) {
        require(balances_eco[msg.sender] >= numTokens);
        allowed_eco[msg.sender][delegate] = numTokens;
        emit ApprovalToken(msg.sender, delegate, numTokens);
        return true;
    }
    
    //Возможность принять средства от счета А счетом Б
    function allowance(address fromAcc, address toAcc) public view returns (uint) {
        return allowed_eco[fromAcc][toAcc];
    }
    
    function sendEther(address receiver, uint256 numEco) public returns (bool){
        require(balances_eco[msg.sender] >= (numEco), "A");
        balances_eco[msg.sender] -= numEco;
        balances_eco[receiver] += numEco;
        emit Transfer(msg.sender,receiver,numEco);
        return true;
    }
   
    function getEther(address seller, address buyer, uint256 numEco) public returns (bool) {
        require(balances_eco[seller] >= numEco);
        require(allowed_eco[seller][buyer] >= numEco);
        // require(buyer == msg.sender); // проверка проведения транзакции с адреса получателя
        balances_eco[seller] -= numEco;
        allowed_eco[seller][buyer] -= numEco;
        balances_eco[buyer] += numEco;
        emit Transfer(seller,buyer,numEco);
        return true;
    }
    
}

