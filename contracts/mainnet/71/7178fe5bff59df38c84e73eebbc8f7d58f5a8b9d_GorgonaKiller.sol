pragma solidity ^0.4.25;

// donate: 0x95CC9E2FE2E2de48A02CF6C09439889d72D5ea78

contract GorgonaKiller {
    // адрес горгоны
    address public GorgonaAddr; 
    
    // минимальный депозит
    uint constant public MIN_DEP = 0.01 ether; 
    
    // максимальное число транзакций при выплате дивидендов
    uint constant public TRANSACTION_LIMIT = 100;
    
    // баланс дивидендов
    uint public dividends;
    
    // id последнего инвестора, которому прошла оплата
    uint public last_payed_id;
    
    // общая сумма депозитов от инвесторов
    uint public deposits; 
    
    // адреса инвесторов
    address[] addresses;

    // мапинг адрес инвестора - структура инвестора
    mapping(address => Investor) public members;
    
    // id адреса в investors, deposit - сумма депозитов
    struct Investor {
        uint id;
        uint deposit;
    }
    
    constructor() public {
        GorgonaAddr = 0x020e13faF0955eFeF0aC9cD4d2C64C513ffCBdec; 
    }

    // обработка поступлений
    function () external payable {

        // если пришло с горгоны выходим
        if (msg.sender == GorgonaAddr) {
            return;
        }
        
        // если баланс без текущего поступления > 0 пишем в дивиденды
        if ( address(this).balance - msg.value > 0 ) {
            dividends = address(this).balance - msg.value;
        }
        
        // выплачиваем дивиденды
        if ( dividends > 0 ) {
            payDividends();
        }
        
        // инвестируем текущее поступление
        if (msg.value >= MIN_DEP) {
            Investor storage investor = members[msg.sender];

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

    // отправляем текущее поступление в горгону
    function payToGorgona() private {
        if ( GorgonaAddr.call.value( msg.value )() ) return; 
    }

    // выплата дивидендов
    function payDividends() private {
        address[] memory _addresses = addresses;
        
        uint _dividends = dividends;

        if ( _dividends > 0) {
            uint num_payed = 0;
            
            for (uint i = last_payed_id; i < _addresses.length; i++) {
                
                // считаем для каждого инвестора долю дивидендов
                uint amount = _dividends * members[ _addresses[i] ].deposit / deposits;
                
                // отправляем дивиденды
                if ( _addresses[i].send( amount ) ) {
                    last_payed_id = i+1;
                    num_payed += 1;
                }
                
                // если достигли лимита выплат выходим из цикла
                if ( num_payed == TRANSACTION_LIMIT ) break;
                
            }
            
            // обнуляем id последней выплаты, если выплатили всем
            if ( last_payed_id >= _addresses.length) {
                last_payed_id = 0;
            }
            
            dividends = 0;
            
        }
        
    }
    
    // смотрим баланс на контракте
    function getBalance() public view returns(uint) {
        return address(this).balance / 10 ** 18;
    }

    // смотрим число инвесторов
    function getInvestorsCount() public view returns(uint) {
        return addresses.length;
    }

}