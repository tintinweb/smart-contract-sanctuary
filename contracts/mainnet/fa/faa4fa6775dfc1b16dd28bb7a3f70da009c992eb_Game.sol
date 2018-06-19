pragma solidity ^0.4.18;

contract ownerOnly {
    
    function ownerOnly() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract Game is ownerOnly {
    
    //Уникальный код коровы
    uint cow_code;
    
    struct cows {
        uint cow;
        bool place;
        uint date_buy;
        bool cow_live;
        uint milk;
        uint date_milk;
    } 
    
    //Маппинг количество коров у пользователя
    mapping (address => uint) users_cows;
    //Маппинг коровы у пользователя
    mapping (bytes32 => cows) user;
    //Маппинг телеги
    mapping (address => bool) telega;
    //Адрес кошелька движка
    address multisig;
    //Адрес кошелька rico
    address rico;
    
    
    //сколько корова дает молока за одну дойку
    uint volume_milk;
    //сколько нужно времени между доениями
    uint time_to_milk;
    //времмя жизни коровы
    uint time_to_live;   
        
    //сколько стоит молоко в веях в розницу
    uint milkcost;
    

    //инициируем переменные движка
    function Game() public {
        
        //устанавливаем кошелек движка для управления
    	multisig = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        //устанавливаем кошелек движка для управления
    	rico = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    	
    	//Устанавливаем счетчик коров
    	cow_code = 0;
    	
        //сколько литров дает корова на 5 минут
        volume_milk = 20;
        //через сколько секунд можно доить корову
        time_to_milk = 60;
        //сколько секунд живет корова - 30 мин
        time_to_live = 1800;  
        
        //Сколько стоит продать молоко в розницу
        milkcost = 0.001083333333333 ether;
    }
    
    function pay(uint cor) public payable {
       
        if (cor==0) {
            payCow();    
        }
        else {
            payPlace(cor);
        }
    }        
    
    //покупаем коров только от движка
    function payCow() private {
       
        uint time= now;
        uint cows_count = users_cows[msg.sender];
        
        uint index = msg.value/0.09 ether;
        
        for (uint i = 1; i <= index; i++) {
            
            cow_code++;
            cows_count++;
            user[keccak256(msg.sender) & keccak256(i)]=cows(cow_code,false,time,true,0,time);
        }
        users_cows[msg.sender] = cows_count;
    }    
    
    //покупаем поле
    function payPlace(uint cor) private {

        uint index = msg.value/0.01 ether;
        user[keccak256(msg.sender) & keccak256(cor)].place=true;
        rico.transfer(msg.value);
    }        
    
    
    
    //доим корову
    function MilkCow(address gamer) private {
       
        uint time= now;
        uint time_milk;
        
        //получеем количество коров пользователя
        uint cows_count = users_cows[gamer];
        
        for (uint i=1; i<=cows_count; i++) {
            
            //получеем анкету коровы
            cows tmp = user[keccak256(gamer) & keccak256(i)];
            
            //если корова пока жива тогда доим
            if (tmp.cow_live==true && tmp.place) {
                
                //получаем время смерти коровы
                uint datedeadcow=tmp.date_buy+time_to_live;
               
                //если время смерти коровы уже наступило
                if (time>=datedeadcow) {
                    
                    //получаем сколько доек мы пропустили
                    time_milk=(time-tmp.date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        //кидаем на склад молоко которое мы надоили за пропущенные дойки
                        tmp.milk+=(volume_milk*time_milk);
                        //убиваем корову
                        tmp.cow_live=false;
                        //устанавливаем последнее время доения
                        tmp.date_milk+=time_milk*time_to_milk;
                    }
                    
                } else {
                    
                    time_milk=(time-tmp.date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        tmp.milk+=volume_milk*time_milk;
                        tmp.date_milk+=time_milk*time_to_milk;
                    }
                }
           
                //обновляем анкету коровы
                user[keccak256(gamer) & keccak256(i)] = tmp;
            }
        }
    }    
  
    //продаем молоко, если указано 0 тогда все молоко, иначе сколько сколько указано
    function saleMilk(uint vol, uint num_cow) public {
        
        //сколько будем продовать молока
        uint milk_to_sale;
        
        //отгрузка молока возможно только при наличии телеги у фермера
        if (telega[msg.sender]==true) {
            
            MilkCow(msg.sender);
            
            //Получаем количество коров у пользователя
            uint cows_count = users_cows[msg.sender];            
        
            //обнуляем все молоко на продажу
            milk_to_sale=0;
            
            //если мы продаем молоко всех коров
            if (num_cow==0) {
                
                for (uint i=1; i<=cows_count; i++) {
                    
                    if (user[keccak256(msg.sender) & keccak256(i)].place) {
                        
                        milk_to_sale += user[keccak256(msg.sender) & keccak256(i)].milk;
                        //удаляем из анкеты все молоко
                        user[keccak256(msg.sender) & keccak256(i)].milk = 0;
                    }
                }
            }
            //если указана корова которую мы должны подоить
            else {
                
                //получеем анкету коровы
                cows tmp = user[keccak256(msg.sender) & keccak256(num_cow)];
                            
                //если будем продовать все молоко
                if (vol==0) {
                
                    //запоминаем сколько молока продавать
                    milk_to_sale = tmp.milk;
                    //удаляем из анкеты все молоко
                    tmp.milk = 0;    
                } 
                //если будем продовать часть молока
                else {
                        
                    //если молока которого хочет продать фермер меньше чем есть
                    if (tmp.milk>vol) {
                    
                        milk_to_sale = vol;
                        tmp.milk -= milk_to_sale;
                    } 
                    
                    //если молока который хочет продать фермер недостаточно, то продаем только то что есть
                    else {
                        
                        milk_to_sale = tmp.milk;
                        tmp.milk = 0;
                    }                        
                } 
                
                user[keccak256(msg.sender) & keccak256(num_cow)] = tmp;
            }
            
            //отсылаем эфир за купленное молоко
            msg.sender.transfer(milkcost*milk_to_sale);
        }            
    }
            
    //продаем корову от фермера фермеру, историю передачи всегда можно узнать из чтения бд
    function TransferCow(address gamer, uint num_cow) public {
       
        //получеем анкету коровы
        cows cow= user[keccak256(msg.sender) & keccak256(num_cow)];
        
        //продавать разрешается только живую корову
        if (cow.cow_live == true && cow.place==true) {
            
            //получаем количество коров у покупателя
            uint cows_count = users_cows[gamer];
            
            //увеличиваем счетчик коров покупателя
            cows_count++;
            
            //создаем и заполняем анкету коровы для нового фермера, при этом молоко не передается
            user[keccak256(gamer) & keccak256(cows_count)]=cows(cow.cow,true,cow.date_buy,cow.cow_live,0,now);
            
            //убиваем корову и прошлого фермера
            cow.cow_live= false;
            //обновляем анкету коровы предыдущего фермера
            user[keccak256(msg.sender) & keccak256(num_cow)] = cow;
            
            users_cows[gamer] = cows_count;
        }
    }
    
    //убиваем корову принудительно из движка
    function DeadCow(address gamer, uint num_cow) public onlyOwner {
       
        //обновляем анкету коровы
        user[keccak256(gamer) & keccak256(num_cow)].cow_live = false;
    }  
    
    //Послать телегу фермеру
    function TelegaSend(address gamer) public onlyOwner {
       
        //Послать телегу
        telega[gamer] = true;
       
    }  
    
    //Вернуть деньги
    function SendOwner() public onlyOwner {
        msg.sender.transfer(this.balance);
    }      
    
    //Послать телегу фермеру
    function TelegaOut(address gamer) public onlyOwner {
       
        //Послать телегу
        telega[gamer] = false;
       
    }  
    
    //Вывести сколько коров у фермера
    function CountCow(address gamer) public view returns (uint) {
        return users_cows[gamer];   
    }

    //Вывести сколько коров у фермера
    function StatusCow(address gamer, uint num_cow) public view returns (uint,bool,uint,bool,uint,uint) {
        return (user[keccak256(gamer) & keccak256(num_cow)].cow,
        user[keccak256(gamer) & keccak256(num_cow)].place,
        user[keccak256(gamer) & keccak256(num_cow)].date_buy,
        user[keccak256(gamer) & keccak256(num_cow)].cow_live,
        user[keccak256(gamer) & keccak256(num_cow)].milk,
        user[keccak256(gamer) & keccak256(num_cow)].date_milk);   
    }
    
    //Вывести наличие телеги у фермера
    function Statustelega(address gamer) public view returns (bool) {
        return telega[gamer];   
    }    
    
}