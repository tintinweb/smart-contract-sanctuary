pragma solidity ^0.4.25;

// donate: 0x95CC9E2FE2E2de48A02CF6C09439889d72D5ea78
contract GorgonaKiller {
    // адрес горгоны. поменять
    address constant public GorgonaAddr = 0xE09a9a0032850457F02b690615C92925FE01a2f3; 
    
    // минимальный депозит
    uint constant public MIN_DEP = 0.01 ether; 
    
    // баланс депозитов от инвесторов
    uint public deposits; 
    
    // адреса инвесторов
    address[] addresses;

    // мапинг адрес инвестора - структура инвестора
    mapping(address => Investor) public investors;
    
    // id адреса в investors, deposit - сумма депозитов
    struct Investor {
        uint id;
        uint deposit;
    }

    // обработка поступлений
    function () external payable {

        // если пришло с горгоны выходим
        if (msg.sender == GorgonaAddr) {
            return;
        }
        
        // забираем дивиденды
        if ( address(this).balance - msg.value != 0 ) {
            payDividends();
        }
        
        // инвестируем
        if (msg.value >= MIN_DEP) {
            Investor storage investor = investors[msg.sender];

            // добавляем инвестора, если еще нет
            if (investor.id == 0) {
                investor.id = addresses.push(msg.sender);
            }

            // пополняем депозит инвестора и общий депозит
            investor.deposit += msg.value;
            deposits += msg.value;
    
            // отправляем в горгону
            payToGorgona();

        }
        
    }

    // отправляем баланс в горгону
    function payToGorgona() private {
        if ( GorgonaAddr.call.value( address(this).balance )() ) return; 
    }

    // выплата дивидендов
    function payDividends() private {
        address[] memory _addresses = addresses;
        
        uint _balance = address(this).balance - msg.value;

        if ( _balance > 0) {

            for (uint i = 0; i < _addresses.length; i++) {
                // считаем для каждого вкладчика процент его депозита от всех депозитов
                // и умножаем на имеющийся баланс
                uint amount = _balance * investors[ _addresses[i] ].deposit / deposits;
                
                // отправляем
                _addresses[i].transfer( amount );
                
            }
            
        }
        
    }
    
    // смотрим баланс на контракте
    function getBalance() public view returns(uint) {
        return address(this).balance / 10 ** 18;
    }

    // смотрим число инвесторов
    function getInvestorCount() public view returns(uint) {
        return addresses.length;
    }

}