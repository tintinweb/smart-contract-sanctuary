/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;


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

    event owneraddress(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit owneraddress(address(0), msgSender);
    }

   //Текущий владелец - адресс
    function owner() public view returns (address) {
        return _owner;
    }

    //выбрасить если не владелец
    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }


   // Можно передать новому владельцу
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit owneraddress(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Redmond is Our {

    using Math for uint256;

    event UpdateMessage(string oldStr, string newStr);

    mapping (address => bool) public isDepositor;
    mapping (address => uint256) public amountDeposit;
    mapping (address => uint256) public amountDepositorEarned;
    mapping (uint256 => uint256) public levelPrice;
    mapping (address => uint256) public levelOfDepositor;
    mapping (address => bool) public hasSponsor;
    mapping (address => address) public sponsorOfDepositor;
    mapping (address => uint256) public feeFromRecruiters;
    mapping (address => uint256) public depositTime;


    string public message;
    uint256 public lastTimestampEthSentToInstitution;
    uint256 public lastTimestampProfitReceived;
    address public manager;
    address payable public institutionWallet;
    uint256 public totalEthDeposited;
    uint256 public currentEthDeposited;
    uint256 public totalEthSentToInstitution;
    uint256 public totalEthPendingSubscription;
    uint256 public totalEthPendingWithdrawal;
    uint256 public totalSharesPendingRedemption;
    uint256 public constant LAST_LEVEL = 5;
    bool private unlocked = true;


    constructor(string memory initMessage) public{
        manager = _msgSender();
        levelPrice[1] = 0.000000025 ether;
        for (uint256 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
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

    event Deposit(address depositer, uint256 amount, uint256 timestamp);

    //только менеджер может вызывать
    modifier onlyManager() {
        require(manager == _msgSender());
        _;
    }



    // Проверка что у менеджера есть адресс
    function setManager(address _manager) external onlyManager() {
        require(_manager != address(0));
        manager = _manager;
    }
    // Проверка что кошелек имеет адресс
    function setInstitutionWallet(address payable _wallet) external onlyManager() {
        require(_wallet != address(0));
        institutionWallet = _wallet;
    }

    function deposit(uint256 level) public payable {

        require(msg.value == levelPrice[level], "invalid price");
        require(level > 0 && level <= LAST_LEVEL, "invalid level number");
        totalEthDeposited = totalEthDeposited.add(msg.value);
        currentEthDeposited = currentEthDeposited.add(msg.value);
        isDepositor[msg.sender] = true;
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(msg.value);
        depositTime[msg.sender] = block.timestamp;
        levelOfDepositor[msg.sender] = level;


        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    //Функция повышения уровня
    function upgradeLevel() public payable {
        require(isDepositor[msg.sender]);
        uint256 currentLevel = levelOfDepositor[msg.sender];
        require(currentLevel + 1 <= LAST_LEVEL, "next level invalid");
        require(msg.value == levelPrice[currentLevel + 1], "invalid price");

        totalEthDeposited = totalEthDeposited.add(msg.value);
        currentEthDeposited = currentEthDeposited.add(msg.value);
        amountDeposit[msg.sender] = amountDeposit[msg.sender].add(msg.value);
        depositTime[msg.sender] = block.timestamp;
        levelOfDepositor[msg.sender] = currentLevel + 1;
    }

    //Отправляем деньги выше
    function sendFundsToInstitution() public onlyManager() {
        require(currentEthDeposited > 1 ether, "Funds not enought to send to institution.");
        require(address(this).balance >= currentEthDeposited, "Insufficient balance to send to institution.");
        require(institutionWallet != address(0), "No institutional wallet set up.");
        institutionWallet.transfer(currentEthDeposited);
        totalEthSentToInstitution = totalEthSentToInstitution.add(currentEthDeposited);
        currentEthDeposited = 0;
        lastTimestampEthSentToInstitution = block.timestamp;
    }

    function calculateReweard(address account) public view returns (uint256, uint256) {
        require(totalEthSentToInstitution > 0, "No funds have been transferred to the institutional wallet.");
        require(depositTime[account] < lastTimestampEthSentToInstitution && depositTime[account] < lastTimestampProfitReceived, "You don't have profit yet.");
        uint256 profit = totalEthPendingSubscription.mul(amountDeposit[account]).div(totalEthSentToInstitution);
        profit = profit.add(feeFromRecruiters[account]);

        uint256 feeToSponsor;
        if (hasSponsor[account])
        {
            feeToSponsor = profit.mul(2).div(10);
            profit = profit.sub(feeToSponsor);
        }

        if (profit < amountDepositorEarned[account])
        {
            return (0, 0);
        }
        else
        {
            profit = profit.sub(amountDepositorEarned[account]);
        }

        return (profit, feeToSponsor);
    }

    function claim() external lock {
        address claimer = msg.sender;
        require(isDepositor[claimer], "You must deposit first to earn profit.");
        uint256 earnedToDeposit = amountDepositorEarned[claimer].div(amountDeposit[claimer]);
        require(earnedToDeposit < 2, "You already have earned 200% of your deposit. Please upgrade your potfolio.");

        (uint256 profit, uint256 feeToSponsor) = calculateReweard(claimer);

        require(profit > 0, "No profit for your account");

        feeFromRecruiters[claimer] = 0;

        if (feeToSponsor > 0){
            address sponsor = sponsorOfDepositor[claimer];
            feeFromRecruiters[sponsor] = feeFromRecruiters[sponsor].add(feeToSponsor);
        }

        profit = profit.sub(amountDepositorEarned[claimer]);
        (bool success, /* bytes memory data */) = payable(claimer).call{value: profit, gas: 1}("");


        if (success) {
            amountDepositorEarned[claimer] = amountDepositorEarned[claimer].add(profit);
        }


    }

    /*function withdraw() external onlyManager {
        payable(manager).transfer(address(this).balance);
    }*/

    receive() external payable {
        totalEthPendingSubscription = msg.value;
        lastTimestampProfitReceived = block.timestamp;
    }

}

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