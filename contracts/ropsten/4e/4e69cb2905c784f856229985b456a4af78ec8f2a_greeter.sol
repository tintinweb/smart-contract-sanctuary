contract mortal {
    /*Для адресов есть отдельный тип переменных*/
    address owner;

    /*Данная функция исполняется лишь однажды - при загрузки контракта в блокчейн
    Называется также как и контракт
    Переменной owner присвоится значение адреса отправителя контракта, то есть ваш адрес*/
    function mortal() { owner = msg.sender; }

    /*Функция selfdestruct уничтожает контракт и отправляет все средства со счета контракта на адрес, указанный в аргументе*/
    /*В Ethereum любой участник сети может вызвать любую функцию
    Проверка адреса позволит уничтожить контракт только вам*/
    function kill() { if (msg.sender == owner) selfdestruct(owner); }
}

/*Оператор is отвечает за наследование*/
/*Возможно множественное наследование вида contract_1 is contract_2, contract_3*/
contract greeter is mortal {
    string greeting;

    /*В этом случае при инициализации контракта нужно будет указать строку-аргумент
    В нашем случае это и будет "Hello, world!"*/
    function greeter(string _greeting) public {
        greeting = _greeting;
    }

    // Эта функция и отвечает за возвращение "Hello, world!"
    function greet() constant returns (string) {
        return greeting;
    }
}