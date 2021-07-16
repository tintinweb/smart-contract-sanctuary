//SourceUnit: yoomper.sol

pragma solidity ^0.4.24;

/*
__   __                                    
\ \ / /                                    
 \ V /___   ___  _ __ ___  _ __   ___ _ __ 
  \ // _ \ / _ \| '_ ` _ \| '_ \ / _ \ '__|
  | | (_) | (_) | | | | | | |_) |  __/ |   
  \_/\___/ \___/|_| |_| |_| .__/ \___|_|   
                          | |              
                          |_|             
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
contract Yoomper {
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
        address padre;
        address[] hijos;
        address[] indirectos;
        uint [] pagos;
        uint fechainicio;
        uint fechaingreso;
        uint fechafinal;
        uint fecharepago;
        bool activo;
        uint donados;
        uint recibidos;
        uint metas;
        uint ganancias;
    }
    //valores
    uint public valor=2600 trx;
    uint public pago=2200;
    
    uint pinv1=320;
    uint pinv2=80;
    
    //
    uint public suny=1000000;
    uint ids=1;
    mapping (address=>Users) private list_users;
    address[] private users_array;

address private owner;


address private inv1;
address private inv2;

      constructor() public{
            owner = msg.sender;
    }
    
    function enter(address padre) public payable{
         require(limite_usuario(padre)<=2 , "Hijos completos");
        require(msg.value== valor );
        require(list_users[msg.sender].id==0);
        agregar_usuario(padre);
        send_pays(pinv1*suny,inv1);
        send_pays(pinv2*suny,inv2);
    }
    function add_invs(address a,address b) public isowner{
        inv1=a;
        inv2=b;
    }

    function mirar_inv() public view returns(address a,address b){
        a=inv1;
        b=inv2;
    }
    
    function limite_usuario(address _user) public view returns (uint){
        return list_users[_user].hijos.length;
    }
    
    function tamano(address padre) public  view returns(uint){
         uint tam=list_users[padre].hijos.length;
         return tam;
    }
    

    
     function agregar_usuario(address _padre) private {
        Users storage usuario=list_users[msg.sender];
        usuario.id=ids;
        usuario.billetera=msg.sender;
        usuario.donados=0;
        usuario.recibidos=0;
        usuario.metas=10;
        usuario.ganancias=0;
        usuario.activo=true;
        usuario.fechainicio=now;
        usuario.fechaingreso=now;
        uint fechas=addDays(now,30);
        usuario.fechafinal=fechas;
        usuario.fecharepago=addDays(fechas,5);
        if(users_array.length!=0){
           require(list_users[_padre].id!=ids,"No existe este referido");
           proceso_hijos(_padre,msg.sender);
        }else{
        usuario.padre=_padre;
        }
        users_array.push(msg.sender);
        ids++;
       // levels();
    }

    function trabajo_equipo(address _user)public view returns(uint){
        uint a= list_users[_user].hijos.length;
        uint b=list_users[_user].indirectos.length;
        return a+b;
    }
    
    function proceso_hijos(address padre,address hijo) private {
       uint cantidad=list_users[padre].hijos.length;
       address p=list_users[padre].padre;
           if(cantidad==0){
               address abuelo=list_users[padre].padre;
                uint a= list_users[abuelo].hijos.length;
                uint b=list_users[abuelo].indirectos.length;
                uint totales=a+b;
                uint suma=totales+1;
                if(suma == list_users[abuelo].metas){
                       list_users[abuelo].metas= list_users[abuelo].metas+10;
                       list_users[padre].hijos.push(hijo);
                       list_users[hijo].padre=padre;
                       send_pays(pago*suny,abuelo);
                       list_users[abuelo].ganancias= list_users[abuelo].ganancias+pago;
                   }else{
                           list_users[padre].hijos.push(hijo);
                           list_users[p].indirectos.push(hijo);
                           list_users[hijo].padre=p;
                           list_users[p].ganancias= list_users[p].ganancias+pago;
                           send_pays(pago*suny,p);
                    }
           }
           if(cantidad==1) {
               list_users[padre].hijos.push(hijo);
                list_users[hijo].padre=padre;
                list_users[padre].ganancias= list_users[padre].ganancias+pago;
                send_pays(pago*suny,padre);
           }
           if(cantidad==2){ 
               list_users[padre].hijos.push(hijo);
                list_users[hijo].padre=padre;
                 list_users[padre].ganancias= list_users[padre].ganancias+pago;
                 send_pays(pago*suny,padre);
           }
       
    }
    

    function sesion(address user)public view returns(uint _id,address _billera,address _padre,uint fi,uint ff,uint fr,uint ganancias,uint meta){
        _id=list_users[user].id;
        _billera=list_users[user].billetera;
        _padre=list_users[user].padre;
        fi=list_users[user].fechaingreso;
        ff=list_users[user].fechafinal;
        fr=list_users[user].fecharepago;
        ganancias=list_users[user].ganancias;
        meta=list_users[user].metas;
    }
    function addDays(uint timestamp, uint _days) private pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
    }


    function aun_activo(address _user)public view returns(uint times,string mesage){
      
        uint b=list_users[_user].fechafinal;
        uint c=list_users[_user].fecharepago;
        if(now<=b){
            mesage="Activo";
            times=diffDays(now,b);
             
        }else{
            if(now<=c){
                mesage="Recarga";
                times=diffDays(now,c);
           
            }else {
                mesage="Suspendido por pago";
                times=0;
               
            }
        }
       
    }
    function tiempo_en_contract(address _user)public view returns(uint times){
        uint inicio=list_users[_user].fechainicio;
        return times=diffDays(inicio,now);
    }
    function donados(address _user)public payable{
        require(msg.value== valor );
        address padre=list_users[_user].padre;
        uint fecharepago=list_users[padre].fecharepago;
        bool buscador=true;
        if(now<=fecharepago){
            //paga
            list_users[_user].donados++;
            list_users[padre].recibidos++;
             list_users[padre].ganancias= list_users[padre].ganancias+pago;
             send_pays(pago*suny,padre);
            uint restos=diffDays(now,list_users[_user].fecharepago);
            uint nuevosdias=30+restos;
            list_users[_user].fechainicio=now;
            uint fechasn=addDays(now,nuevosdias);
            list_users[_user].fechafinal=fechasn;
            list_users[_user].fecharepago=addDays(fechasn,5);
        }else{
             address p=list_users[padre].padre;
            while(buscador==true){
                if(now<=list_users[p].fecharepago){
                    list_users[_user].donados++;
                    list_users[p].recibidos++;
                     list_users[p].ganancias= list_users[p].ganancias+pago;
                     send_pays(pago*suny,p);
                    list_users[_user].padre=list_users[p].billetera;
                    list_users[p].indirectos.push(list_users[_user].billetera);
                    uint restosa=diffDays(now,list_users[_user].fecharepago);
                    uint nuevosdiasa=30+restosa;
                    list_users[_user].fechainicio=now;
                    uint fechasna=addDays(now,nuevosdiasa);
                    list_users[_user].fechafinal=fechasna;
                    list_users[_user].fecharepago=addDays(fechasna,5);
                    buscador=false;
                }else{
                    p=list_users[p].padre;
                }
            }
        }
        send_pays(pinv1*suny,inv1);
        send_pays(pinv2*suny,inv2);
    }
    function mira_donados(address _user)public view returns(uint donacion){
        return donacion=list_users[_user].donados;
    }
    function mira_recibidos(address _user)public view returns(uint recibios){
        return recibios=list_users[_user].recibidos;
    }
    function ganancias(address _user) public view returns(uint ganancia) {
        return ganancia=list_users[_user].ganancias;
    }
  
    function diffDays(uint fromTimestamp, uint toTimestamp) private pure returns (uint _days) {
        _days = BokkyPooBahsDateTimeLibrary.diffDays(fromTimestamp, toTimestamp);
    }
    function equipohijos(address _user) public view returns(address[] hijos){
        hijos=list_users[_user].hijos;
        return hijos;  
    }
    function equipopadres(address _user) public view returns (address [] indirectos){
        indirectos=list_users[_user].indirectos;
        return indirectos;  
    }
    function cambios_pays(uint ingreso,uint pagar,uint a,uint b)public isowner{
        valor=ingreso*suny;
        pago=pagar;
        pinv1=a;
        pinv2=b;
    }
    function view_adrees(uint a) public view returns (address){
        return users_array[a-1];
    }
   /* function reinvertir(address _user)public payable{
        uint fi=list_users[_user].fechainicio;
        uint ff=list_users[_user].fechainicio;
        
    }*/
    function send_pays(uint amount,address to)private{
        require(address(this).balance >=amount);
        require(to != address(0));
        to.transfer(amount);
    }
    function edits(address user,uint fi,uint ff,uint fr,address padre) public isowner{
        list_users[user].fechainicio=fi;
        list_users[user].fechafinal=ff;
        list_users[user].fecharepago=fr;
        list_users[user].padre=padre;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, hour, minute, second);
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