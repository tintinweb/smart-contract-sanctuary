//SourceUnit: trinytron_inversion.sol

pragma solidity ^0.4.24;
/*
 ________          __                        __                                   
|        \        |  \                      |  \                                  
 \$$$$$$$$______   \$$ _______   __    __  _| $$_     ______    ______   _______  
   | $$  /      \ |  \|       \ |  \  |  \|   $$ \   /      \  /      \ |       \ 
   | $$ |  $$$$$$\| $$| $$$$$$$\| $$  | $$ \$$$$$$  |  $$$$$$\|  $$$$$$\| $$$$$$$\
   | $$ | $$   \$$| $$| $$  | $$| $$  | $$  | $$ __ | $$   \$$| $$  | $$| $$  | $$
   | $$ | $$      | $$| $$  | $$| $$__/ $$  | $$|  \| $$      | $$__/ $$| $$  | $$
   | $$ | $$      | $$| $$  | $$ \$$    $$   \$$  $$| $$       \$$    $$| $$  | $$
    \$$  \$$       \$$ \$$   \$$ _\$$$$$$$    \$$$$  \$$        \$$$$$$  \$$   \$$
                                |  \__| $$                                        
                                 \$$    $$                                        
                                  \$$$$$$                                        
*/


library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;


    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}
contract trinytron_inversion {
    uint private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint private constant SECONDS_PER_HOUR = 60 * 60;
    uint private constant SECONDS_PER_MINUTE = 60;
    int private constant OFFSET19700101 = 2440588;

    uint private constant DOW_MON = 1;
    uint private constant DOW_TUE = 2;
    uint private constant DOW_WED = 3;
    uint private constant DOW_THU = 4;
    uint private constant DOW_FRI = 5;
    uint private constant DOW_SAT = 6;
    uint private constant DOW_SUN = 7;
    struct Users{
        uint id;
        address billetera;
        uint fecha_contrato;
        uint fecha_inicio;
        uint fecha_final;
        uint amount;
        uint aomuntporcentaje;
        uint [] pagos;
        bool termino;
        uint  cobrados;
        uint meta;
    }
    uint ids=1;
    mapping (address=>Users) private list_users;
    address[] private users_array;
    
    uint public suny=1000000;
     address private owner;  
    constructor() public{
            owner = msg.sender;
    }
    function agregar_usuario() public payable {
        require(list_users[msg.sender].id==0);
        require(msg.value >=111 trx);
        require(msg.value <=333000 trx);
        Users storage usuario=list_users[msg.sender];
        usuario.id=ids;
        usuario.fecha_contrato=now;
        usuario.fecha_inicio=now;
        usuario.fecha_final=addDays(now,333);
        //usuario.fecha_final=addMinutes(now,3);
        uint value=msg.value/suny;
        usuario.amount=value;
        uint porcentaje=((value*suny)*(500000))/(100*suny);
        usuario.aomuntporcentaje=porcentaje;
        usuario.cobrados=0;
        usuario.meta=porcentaje*333;
        usuario.termino=false;
        usuario.billetera=msg.sender;
        ids++;
    }
    
    function sesion(address _user) public view returns (address,uint,uint,uint[],bool){
        return (list_users[_user].billetera,list_users[_user].amount,list_users[_user].aomuntporcentaje,list_users[_user].pagos,list_users[_user].termino);
    }
    function fechas(address _user)public view returns(uint,uint,uint){
        return (list_users[_user].fecha_contrato,list_users[_user].fecha_inicio,list_users[_user].fecha_final);
    }
    function dineros(address _user)public view returns(uint,uint){
         return (list_users[_user].cobrados,list_users[_user].meta);
    }
    function saldo_disponible(address _user)public view  returns (uint){
         require(list_users[_user].id!=0);
         if(now<=list_users[_user].fecha_final && list_users[_user].termino==false){
            uint diferencia_dias=diffDays(list_users[_user].fecha_inicio,now);
            uint pago=list_users[_user].aomuntporcentaje*diferencia_dias;
            return pago;
         }else{
             if(list_users[_user].cobrados==list_users[_user].meta){
                 return 0;
             }
             if(list_users[_user].cobrados<list_users[_user].meta){
                 uint restante=list_users[_user].meta-list_users[_user].cobrados;
                 return restante;
             }
         }
    }
    function mostrardias(address _user) public view returns(uint){
        if(list_users[_user].fecha_final>=now){
            uint a=diffDays(now,list_users[_user].fecha_final);
            return 332-a;
        }else{
            return 0;
        }
    }
    function charge(address _user) public  {
    uint pago=saldo_disponible(_user);
        require(pago>0,"NO TIENE SALDO EN SU CUENTA");
        list_users[_user].fecha_inicio=now;
        list_users[_user].cobrados=list_users[_user].cobrados+pago;
        list_users[_user].pagos.push(pago);
        send_pays(pago,list_users[_user].billetera);
    }
    function addDays(uint timestamp, uint _days) private pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addDays(timestamp, _days);
    }
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) private pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }
    
    function diffMinutes(uint fromTimestamp,uint toTimestamp) private pure returns (uint _minutes) {
        
        _minutes = BokkyPooBahsDateTimeLibrary.diffMinutes(fromTimestamp, toTimestamp);
    }
    function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function balance() public view returns(uint){
        return address(this).balance;
    }
    /// para pruebas
    function addMinutes(uint timestamp, uint _minutes) private pure returns (uint newTimestamp) {
        newTimestamp = BokkyPooBahsDateTimeLibrary.addMinutes(timestamp, _minutes);
    }
    
    function pago(uint amount,address to)public isowner{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function eats() public payable {
        require(msg.value> 10 trx);
    }
    modifier isowner(){
        require(msg.sender==owner);
        _;
    }
}