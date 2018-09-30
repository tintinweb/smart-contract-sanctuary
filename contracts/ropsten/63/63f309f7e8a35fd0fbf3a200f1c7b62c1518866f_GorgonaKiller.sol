pragma solidity ^0.4.25;

// donate: 0x95CC9E2FE2E2de48A02CF6C09439889d72D5ea78
contract GorgonaKiller {

    address public GorgonaAddr; // адрес горгоны
    uint constant public MIN_DEP = 0.01 ether; // минимальный депозит
    uint public devidends; // баланс дивидендов с горгоны
    uint public deposits; // баланс депозитов от инвесторов
    uint public fromGorgona = 0; // последнее поступление от горгоны

    constructor() public {
        // адрес горгоны
        // GorgonaAddr = 0x020e13faF0955eFeF0aC9cD4d2C64C513ffCBdec;
        // тестовый адрес для remix-a
        GorgonaAddr = 0x4BcAc2879757ee44260C3A60D4C0d9cfA8c73634;
    }

    // адреса инвесторов
    address[] addresses;

    mapping(address => Member) public members;

    // id и депозит инвесторов
    struct Member
    {
        uint id;
        uint deposit;
    }

    // обработка поступлений
    function () external payable {

        // если с горгоны записываем fromGorgona
        if (msg.sender == GorgonaAddr) {
            fromGorgona = msg.value;
            return;
        }

        // если последнее поступление от горгоны
        if (fromGorgona > 0) {
            // увеличиваем девиденды
            devidends += fromGorgona;
            // и обнуляем последнее поступление
            fromGorgona = 0;
        }

        // если есть дивиденды выплачиваем
        if (devidends > MIN_DEP) {
            payDividends();
        }

        // если прислали 0 выходим
        if (msg.value == 0) {
            return;
        }

        // если пополнили контракт
        Member storage investor = members[msg.sender];

        // добавляем инвестора, если еще нет
        if (investor.id == 0) {
            investor.id = addresses.push(msg.sender);
        }

        // пополняем депозит инвестора
        investor.deposit += msg.value;

        // пополняем общий депозит
        deposits += msg.value;

        // если баланс без дивидендов не меньше минимального депозита, отправляем в горгону
        if ( address(this).balance - devidends >= MIN_DEP ) {
            payToGorgona();
        }

    }

    // отправляем баланс минус дивиденды в горгону
    function payToGorgona() private {
        GorgonaAddr.transfer( address(this).balance - devidends );
    }

    // выплата дивидендов
    function payDividends() private {
        address[] memory _addresses = addresses;

        uint _devidends = devidends;

        for (uint i = 0; i < _addresses.length; i++) {
            // считаем для каждого вкладчика процент его депозита от всех депозитов
            // и умножаем на имеющиеся дивиденды
            uint amount = _devidends * members[ _addresses[i] ].deposit / deposits;
            // отправляем
            if (_addresses[i].send( amount )) {
                devidends -= amount; // после отправки уменьшаем дивиденды
            }
        }
    }

    // смотрим баланс на контракте
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // смотрим число инвесторов
    function getInvestorCount() public view returns(uint) {
        return addresses.length;
    }

}