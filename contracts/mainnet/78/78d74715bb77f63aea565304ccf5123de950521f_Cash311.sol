pragma solidity ^0.4.18;

contract DelegateERC20 {
  function delegateTotalSupply() public view returns (uint256);
  function delegateBalanceOf(address who) public view returns (uint256);
  function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);
  function delegateAllowance(address owner, address spender) public view returns (uint256);
  function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);
  function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);
  function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);
  function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}
contract Ownable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function transferOwnership(address newOwner) public;
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  function pause() public;
  function unpause() public;
}
contract CanReclaimToken is Ownable {
  function reclaimToken(ERC20Basic token) external;
}
contract Claimable is Ownable {
  function transferOwnership(address newOwner) public;
  function claimOwnership() public;
}
contract AddressList is Claimable {
    event ChangeWhiteList(address indexed to, bool onList);
    function changeList(address _to, bool _onList) public;
}
contract HasNoContracts is Ownable {
  function reclaimContract(address contractAddr) external;
}
contract HasNoEther is Ownable {
  function() external;
  function reclaimEther() external;
}
contract HasNoTokens is CanReclaimToken {
  function tokenFallback(address from_, uint256 value_, bytes data_) external;
}
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}
contract AllowanceSheet is Claimable {
    function addAllowance(address tokenHolder, address spender, uint256 value) public;
    function subAllowance(address tokenHolder, address spender, uint256 value) public;
    function setAllowance(address tokenHolder, address spender, uint256 value) public;
}
contract BalanceSheet is Claimable {
    function addBalance(address addr, uint256 value) public;
    function subBalance(address addr, uint256 value) public;
    function setBalance(address addr, uint256 value) public;
}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract BasicToken is ERC20Basic, Claimable {
  function setBalanceSheet(address sheet) external;
  function totalSupply() public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal;
  function balanceOf(address _owner) public view returns (uint256 balance);
}
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public;
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
}
contract StandardToken is ERC20, BasicToken {
  function setAllowanceSheet(address sheet) external;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function transferAllArgsYesAllowance(address _from, address _to, uint256 _value, address spender) internal;
  function approve(address _spender, uint256 _value) public returns (bool);
  function approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal;
  function allowance(address _owner, address _spender) public view returns (uint256);
  function increaseApproval(address _spender, uint _addedValue) public returns (bool);
  function increaseApprovalAllArgs(address _spender, uint _addedValue, address tokenHolder) internal;
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool);
  function decreaseApprovalAllArgs(address _spender, uint _subtractedValue, address tokenHolder) internal;
}
contract CanDelegate is StandardToken {
    event DelegatedTo(address indexed newContract);
    function delegateToNewContract(DelegateERC20 newContract) public;
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address _owner, address spender) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function increaseApproval(address spender, uint addedValue) public returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool);
}
contract StandardDelegate is StandardToken, DelegateERC20 {
    function setDelegatedFrom(address addr) public;
    function delegateTotalSupply() public view returns (uint256);
    function delegateBalanceOf(address who) public view returns (uint256);
    function delegateTransfer(address to, uint256 value, address origSender) public returns (bool);
    function delegateAllowance(address owner, address spender) public view returns (uint256);
    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public returns (bool);
    function delegateApprove(address spender, uint256 value, address origSender) public returns (bool);
    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public returns (bool);
    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public returns (bool);
}
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);
}
contract TrueUSD is StandardDelegate, PausableToken, BurnableToken, NoOwner, CanDelegate {
    event ChangeBurnBoundsEvent(uint256 newMin, uint256 newMax);
    event Mint(address indexed to, uint256 amount);
    event WipedAccount(address indexed account, uint256 balance);
    function setLists(AddressList _canReceiveMintWhiteList, AddressList _canBurnWhiteList, AddressList _blackList, AddressList _noFeesList) public;
    function changeName(string _name, string _symbol) public;
    function burn(uint256 _value) public;
    function mint(address _to, uint256 _amount) public;
    function changeBurnBounds(uint newMin, uint newMax) public;
    function transferAllArgsNoAllowance(address _from, address _to, uint256 _value) internal;
    function wipeBlacklistedAccount(address account) public;
    function payStakingFee(address payer, uint256 value, uint80 numerator, uint80 denominator, uint256 flatRate, address otherParticipant) private returns (uint256);
    function changeStakingFees(uint80 _transferFeeNumerator, uint80 _transferFeeDenominator, uint80 _mintFeeNumerator, uint80 _mintFeeDenominator, uint256 _mintFeeFlat, uint80 _burnFeeNumerator, uint80 _burnFeeDenominator, uint256 _burnFeeFlat) public;
    function changeStaker(address newStaker) public;
}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library NewSafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Cash311
 * @dev The main contract of the project.
 */
  /**
    * @title Cash311
    * @dev https://311.cash/;
    */
    contract Cash311 {
        // Connecting SafeMath for safe calculations.
          // Подключает библиотеку безопасных вычислений к контракту.
        using NewSafeMath for uint;

        // A variable for address of the owner;
          // Переменная для хранения адреса владельца контракта;
        address owner;

        // A variable for address of the ERC20 token;
          // Переменная для хранения адреса токена ERC20;
        TrueUSD public token = TrueUSD(0x8dd5fbce2f6a956c3022ba3663759011dd51e73e);

        // A variable for decimals of the token;
          // Переменная для количества знаков после запятой у токена;
        uint private decimals = 10**18;

        // A variable for storing deposits of investors.
          // Переменная для хранения записей о сумме инвестиций инвесторов.
        mapping (address => uint) deposit;
        uint deposits;

        // A variable for storing amount of withdrawn money of investors.
          // Переменная для хранения записей о сумме снятых средств.
        mapping (address => uint) withdrawn;

        // A variable for storing reference point to count available money to withdraw.
          // Переменная для хранения времени отчета для инвесторов.
        mapping (address => uint) lastTimeWithdraw;


        // RefSystem
        mapping (address => uint) referals1;
        mapping (address => uint) referals2;
        mapping (address => uint) referals3;
        mapping (address => uint) referals1m;
        mapping (address => uint) referals2m;
        mapping (address => uint) referals3m;
        mapping (address => address) referers;
        mapping (address => bool) refIsSet;
        mapping (address => uint) refBonus;


        // A constructor function for the contract. It used single time as contract is deployed.
          // Единоразовая функция вызываемая при деплое контракта.
        function Cash311() public {
            // Sets an owner for the contract;
              // Устанавливает владельца контракта;
            owner = msg.sender;
        }

        // A function for transferring ownership of the contract (available only for the owner).
          // Функция для переноса права владения контракта (доступна только для владельца).
        function transferOwnership(address _newOwner) external {
            require(msg.sender == owner);
            require(_newOwner != address(0));
            owner = _newOwner;
        }

        // RefSystem
        function bytesToAddress1(bytes source) internal pure returns(address parsedReferer) {
            assembly {
                parsedReferer := mload(add(source,0x14))
            }
            return parsedReferer;
        }

        // A function for getting key info for investors.
          // Функция для вызова ключевой информации для инвестора.
        function getInfo(address _address) public view returns(uint Deposit, uint Withdrawn, uint AmountToWithdraw, uint Bonuses) {

            // 1) Amount of invested tokens;
              // 1) Сумма вложенных токенов;
            Deposit = deposit[_address].div(decimals);
            // 2) Amount of withdrawn tokens;
              // 3) Сумма снятых средств;
            Withdrawn = withdrawn[_address].div(decimals);
            // Amount of tokens which is available to withdraw.
            // Formula without SafeMath: ((Current Time - Reference Point) / 1 period)) * (Deposit * 0.0311)
              // Расчет количества токенов доступных к выводу;
              // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) / 1 period)) * (Сумма депозита * 0.0311)
            uint _a = (block.timestamp.sub(lastTimeWithdraw[_address])).div(1 days).mul(deposit[_address].mul(311).div(10000));
            AmountToWithdraw = _a.div(decimals);
            // RefSystem
            Bonuses = refBonus[_address].div(decimals);
        }

        // RefSystem
        function getRefInfo(address _address) public view returns(uint Referals1, uint Referals1m, uint Referals2, uint Referals2m, uint Referals3, uint Referals3m) {
            Referals1 = referals1[_address];
            Referals1m = referals1m[_address].div(decimals);
            Referals2 = referals2[_address];
            Referals2m = referals2m[_address].div(decimals);
            Referals3 = referals3[_address];
            Referals3m = referals3m[_address].div(decimals);
        }

        function getNumber() public view returns(uint) {
            return deposits;
        }

        function getTime(address _address) public view returns(uint Hours, uint Minutes) {
            Hours = (lastTimeWithdraw[_address] % 1 days) / 1 hours;
            Minutes = (lastTimeWithdraw[_address] % 1 days) % 1 hours / 1 minutes;
        }




        // A "fallback" function. It is automatically being called when anybody sends ETH to the contract. Even if the amount of ETH is ecual to 0;
          // Функция автоматически вызываемая при получении ETH контрактом (даже если было отправлено 0 эфиров);
        function() external payable {

            // If investor accidentally sent ETH then function send it back;
              // Если инвестором был отправлен ETH то средства возвращаются отправителю;
            msg.sender.transfer(msg.value);
            // If the value of sent ETH is equal to 0 then function executes special algorithm:
            // 1) Gets amount of intended deposit (approved tokens).
            // 2) If there are no approved tokens then function "withdraw" is called for investors;
              // Если было отправлено 0 эфиров то исполняется следующий алгоритм:
              // 1) Заправшивается количество токенов для инвестирования (кол-во одобренных к выводу токенов).
              // 2) Если одобрены токенов нет, для действующих инвесторов вызывается функция инвестирования (после этого действие функции прекращается);
            uint _approvedTokens = token.allowance(msg.sender, address(this));
            if (_approvedTokens == 0 && deposit[msg.sender] > 0) {
                withdraw();
                return;
            // If there are some approved tokens to invest then function "invest" is called;
              // Если были одобрены токены то вызывается функция инвестирования (после этого действие функции прекращается);
            } else {
                if (msg.data.length == 20) {
                    address referer = bytesToAddress1(bytes(msg.data));
                    if (referer != msg.sender) {
                        invest(referer);
                        return;
                    }
                }
                invest(0x0);
                return;
            }
        }

        // RefSystem
        function refSystem(uint _value, address _referer) internal {
            refBonus[_referer] = refBonus[_referer].add(_value.div(40));
            referals1m[_referer] = referals1m[_referer].add(_value);
            if (refIsSet[_referer]) {
                address ref2 = referers[_referer];
                refBonus[ref2] = refBonus[ref2].add(_value.div(50));
                referals2m[ref2] = referals2m[ref2].add(_value);
                if (refIsSet[referers[_referer]]) {
                    address ref3 = referers[referers[_referer]];
                    refBonus[ref3] = refBonus[ref3].add(_value.mul(3).div(200));
                    referals3m[ref3] = referals3m[ref3].add(_value);
                }
            }
        }

        // RefSystem
        function setRef(uint _value, address referer) internal {

            if (deposit[referer] > 0) {
                referers[msg.sender] = referer;
                refIsSet[msg.sender] = true;
                referals1[referer] = referals1[referer].add(1);
                if (refIsSet[referer]) {
                    referals2[referers[referer]] = referals2[referers[referer]].add(1);
                    if (refIsSet[referers[referer]]) {
                        referals3[referers[referers[referer]]] = referals3[referers[referers[referer]]].add(1);
                    }
                }
                refBonus[msg.sender] = refBonus[msg.sender].add(_value.div(50));
                refSystem(_value, referer);
            }
        }



        // A function which accepts tokens of investors.
          // Функция для перевода токенов на контракт.
        function invest(address _referer) public {

            // Gets amount of deposit (approved tokens);
              // Заправшивает количество токенов для инвестирования (кол-во одобренных к выводу токенов);
            uint _value = token.allowance(msg.sender, address(this));

            // Transfers approved ERC20 tokens from investors address;
              // Переводит одобренные к выводу токены ERC20 на данный контракт;
            token.transferFrom(msg.sender, address(this), _value);
            // Transfers a fee to the owner of the contract. The fee is 10% of the deposit (or Deposit / 10)
              // Начисляет комиссию владельцу (10%);
            refBonus[owner] = refBonus[owner].add(_value.div(10));

            // The special algorithm for investors who increases their deposits:
              // Специальный алгоритм для инвесторов увеличивающих их вклад;
            if (deposit[msg.sender] > 0) {
                // Amount of tokens which is available to withdraw.
                // Formula without SafeMath: ((Current Time - Reference Point) / 1 period)) * (Deposit * 0.0311)
                  // Расчет количества токенов доступных к выводу;
                  // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) / 1 period)) * (Сумма депозита * 0.0311)
                uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender])).div(1 days).mul(deposit[msg.sender].mul(311).div(10000));
                // The additional algorithm for investors who need to withdraw available dividends:
                  // Дополнительный алгоритм для инвесторов которые имеют средства к снятию;
                if (amountToWithdraw != 0) {
                    // Increasing the withdrawn tokens by the investor.
                      // Увеличение количества выведенных средств инвестором;
                    withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
                    // Transferring available dividends to the investor.
                      // Перевод доступных к выводу средств на кошелек инвестора;
                    token.transfer(msg.sender, amountToWithdraw);

                    // RefSystem
                    uint _bonus = refBonus[msg.sender];
                    if (_bonus != 0) {
                        refBonus[msg.sender] = 0;
                        token.transfer(msg.sender, _bonus);
                        withdrawn[msg.sender] = withdrawn[msg.sender].add(_bonus);
                    }

                }
                // Setting the reference point to the current time.
                  // Установка нового отчетного времени для инвестора;
                lastTimeWithdraw[msg.sender] = block.timestamp;
                // Increasing of the deposit of the investor.
                  // Увеличение Суммы депозита инвестора;
                deposit[msg.sender] = deposit[msg.sender].add(_value);
                // End of the function for investors who increases their deposits.
                  // Конец функции для инвесторов увеличивающих свои депозиты;

                // RefSystem
                if (refIsSet[msg.sender]) {
                      refSystem(_value, referers[msg.sender]);
                  } else if (_referer != 0x0 && _referer != msg.sender) {
                      setRef(_value, _referer);
                  }
                return;
            }
            // The algorithm for new investors:
            // Setting the reference point to the current time.
              // Алгоритм для новых инвесторов:
              // Установка нового отчетного времени для инвестора;
            lastTimeWithdraw[msg.sender] = block.timestamp;
            // Storing the amount of the deposit for new investors.
            // Установка суммы внесенного депозита;
            deposit[msg.sender] = (_value);
            deposits += 1;

            // RefSystem
            if (refIsSet[msg.sender]) {
                refSystem(_value, referers[msg.sender]);
            } else if (_referer != 0x0 && _referer != msg.sender) {
                setRef(_value, _referer);
            }
        }

        // A function for getting available dividends of the investor.
          // Функция для вывода средств доступных к снятию;
        function withdraw() public {

            // Amount of tokens which is available to withdraw.
            // Formula without SafeMath: ((Current Time - Reference Point) / 1 period)) * (Deposit * 0.0311)
              // Расчет количества токенов доступных к выводу;
              // Формула без библиотеки безопасных вычислений: ((Текущее время - Отчетное время) / 1 period)) * (Сумма депозита * 0.0311)
            uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender])).div(1 days).mul(deposit[msg.sender].mul(311).div(10000));
            // Reverting the whole function for investors who got nothing to withdraw yet.
              // В случае если к выводу нет средств то функция отменяется;
            if (amountToWithdraw == 0) {
                revert();
            }
            // Increasing the withdrawn tokens by the investor.
              // Увеличение количества выведенных средств инвестором;
            withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
            // Updating the reference point.
            // Formula without SafeMath: Current Time - ((Current Time - Previous Reference Point) % 1 period)
              // Обновление отчетного времени инвестора;
              // Формула без библиотеки безопасных вычислений: Текущее время - ((Текущее время - Предыдущее отчетное время) % 1 period)
            lastTimeWithdraw[msg.sender] = block.timestamp.sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days));
            // Transferring the available dividends to the investor.
              // Перевод выведенных средств;
            token.transfer(msg.sender, amountToWithdraw);

            // RefSystem
            uint _bonus = refBonus[msg.sender];
            if (_bonus != 0) {
                refBonus[msg.sender] = 0;
                token.transfer(msg.sender, _bonus);
                withdrawn[msg.sender] = withdrawn[msg.sender].add(_bonus);
            }

        }
    }