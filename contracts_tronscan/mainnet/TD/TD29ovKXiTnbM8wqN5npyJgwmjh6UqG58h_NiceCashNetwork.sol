//SourceUnit: nicecashnetwork1.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c=a+b;
        require(c>=a,"addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b<=a,"subtraction overflow");
        uint256 c=a-b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) return 0;
        uint256 c=a*b;
        require(c/a==b,"multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b>0,"division by zero");
        uint256 c=a/b;
        return c;
    }
}

interface Token {
    function decimals() view external returns (uint8 _decimals);
    function balanceOf(address _owner) view external returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) view external returns (uint256 remaining);
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address payable public owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract NiceCashNetwork is Owned{
    using SafeMath for uint256;
    uint16 public matrixShare;
    uint16[3] public passiveShare;
    uint16 public teamShare;
    address payable root;
    address payable[3] public passiveShareAdr;
    address payable public teamShareAdr;
    address payable public infinityAdr;
    uint public rate;
    uint8 public pack;
    uint8 public packs;
    uint16[] public matrixBonuses;
    uint8[] public qualified;
    uint16[] public rankBonuses;
    uint8[] public rankTeam;
    uint16 public personalBonus;
    uint16 public rankBonus;
    uint[] public rankedUsers;
    uint8 public infinityBonus;
    uint8 public cols;
    uint8 public rows;
    address payable admin;
    bool public isLocked;
    bool public useTrx;
    bool public isPaused;
    Token public token;
    mapping (address=>User) public users;
    mapping (address=>Matrix[10]) public matrix;
    struct User{
        address payable ref;
        uint256 deposit;
        uint8 pack;
        uint8 rank;
        uint frontline;
        uint[6] team;
        uint256[10] packLocked;
        uint256[10] teamLocked;
        uint lastPackLocked;
        uint lastTeamLocked;
        bool vip;
    }
    struct Matrix{
        address payable ref;
        uint start;
        uint8 team;
        address[3] frontline;
    }
    //events
    event Deposit(address indexed _from,uint256 _amount, uint8 _pack);
    event SystemDeposit(address indexed _from,uint256 _amount, uint8 _pack);
    event Upgrade(address indexed _from, address indexed _ref, uint256 _amount, uint8 _pack);
    event Bonus(address indexed _to, uint8 _type, uint256 _amount);
    event NewRank(address indexed _user,uint8 _rank);
    event Locked(address indexed _user, uint8 _pack, uint256 _amount);
    event Unlocked(address indexed _user, uint8 _pack, uint256 _amount);
    event Lost(address indexed _user, uint8 _pack, uint256 _amount);

    modifier isAdmin() {
        require(msg.sender==admin);
        _;
    }

    constructor(address payable _owner, address payable _admin, address payable _root, address _token, address payable _passiveShareAdr1, address payable _passiveShareAdr2, address payable _passiveShareAdr3) public{
        matrixShare = 4500;//% 10**2
        passiveShare = [2000,1500,1500];//% 10**2
        teamShare = 500;//% 10**2
        rate = 1000000;//SUNs in 1 USD
        pack = 128;//pack price USD
        packs = 10;//10 packs
        cols = 3;//matrix width
        rows = 10;//matrix depth
        matrixBonuses = [500,500,400,300,300,200,200,200,400,400];//matrix bonuses % 10**2
        qualified = [0,0,3,4,5,6,7,8,9,10];//personal refs to unlock matrix bonus
        rankBonuses = [0,100,200,300,400,500];//rank % 10**2
        rankTeam = [3,3,3,3,3];//min teams for ranks
        rankedUsers = [0,0,0,0,0,0];
        personalBonus = 500;//% 10**2
        rankBonus = 500;//% 10**2
        infinityBonus = 200;//infinity bonus % 10**2
        owner = _owner;
        admin = _admin;
        root = _root;
        users[root].ref = root;
        users[root].pack = packs-1;
        users[root].rank = 5;
        passiveShareAdr[0] = _passiveShareAdr1;
        passiveShareAdr[1] = _passiveShareAdr2;
        passiveShareAdr[2] = _passiveShareAdr3;
        infinityAdr = admin;
        teamShareAdr = root;
        token = Token(_token);
        useTrx = false;
        isPaused = false;
        isLocked = false;
    }

    receive() external payable {
        revert();
    }

    function deposit(address _user,uint8 _pack) public payable returns(bool){
        //check if SC isPaused
        require(!isPaused,"sс is paused");

        //check user address
        require(_user!=address(0),"wrong user");

        //check user pack
        require(_pack>=0&&_pack<packs,"wrong pack");
        require(users[_user].pack<packs-1,"max pack");
        if (_pack>0) require(_pack-users[_user].pack==1&&matrix[_user][_pack-1].start>0,"wrong next pack");
        else require(matrix[_user][_pack].start==0,"user is in matrix");

        //check user has deposit
        require(users[_user].deposit==0,"has deposit");

        //check pack amount
        uint256 _price;
        uint256 _paid;
        if (useTrx) {
            _price = uint256(pack)*2**uint256(_pack)*10**6/rate;
            _paid = msg.value;
            require(_paid>=_price,"wrong pack amount");
        }
        else {
            _price = uint256(pack)*2**uint256(_pack)*10**uint256(token.decimals());
            _paid = _price;
            require(token.balanceOf(msg.sender)>=_price,"low token balance");
            require(token.allowance(msg.sender,address(this))>=_price,"low token allowance");
            token.transferFrom(msg.sender,address(this),_paid);
        }

        //add users deposit
        users[_user].deposit += _paid;

        //emit event
        if (msg.sender!=admin) emit Deposit(_user,_paid,_pack);
        else emit SystemDeposit(_user,_paid,_pack);
        return true;
    }

    function upgrade(address payable _user, address payable _ref,address payable _matrix) public returns(bool){
        //check if SC isPaused
        require(!isPaused,"sc is paused");

        //check reentrancy lock
        require(!isLocked,"reentrancy lock");
        isLocked = true;

        //check user
        require(_user!=address(0)&&_user!=root&&_user!=_ref&&_user!=_matrix,"wrong user");

        //check pack
        uint8 _pack = users[_user].pack;
        require(_pack<packs-1,"max pack");
        if (matrix[_user][_pack].start>0) _pack++;

        //check personal ref
        if (_ref!=root) require(_ref!=address(0)&&users[_ref].ref!=address(0),"wrong personal ref");

        //check matrix ref
        if (_matrix!=root) require(_matrix!=address(0)&&matrix[_matrix][_pack].start>0,"wrong matrix ref");
        else if (matrix[root][_pack].start==0) matrix[root][_pack].start = block.timestamp;

        //check ref frontline
        require (matrix[_matrix][_pack].team<cols,"frontline is full");

        //check deposit
        require(users[_user].deposit>0,"no deposit");

        //check SC balance
        if (useTrx) require (address(this).balance>=users[_user].deposit,"low TRX balance");
        else require(token.balanceOf(address(this))>=users[_user].deposit,"low token balance");

        //define vars
        uint8 i=0;
        uint256 _value = users[_user].deposit;
        uint256 _bonus = 0;
        uint256 _payout = 0;
        address payable _nextRef;

        //update user
        users[_user].ref = _ref;
        users[_user].pack = _pack;
        users[_user].vip = false;

        //unlock pack locked bonuses for user
        if (users[_user].packLocked[_pack]>0) {
            if (!users[_user].vip&&block.timestamp-users[_user].lastPackLocked>=2592000) {
                _sendBonus(admin,0,users[_user].packLocked[_pack]);
                emit Lost(_user,pack,users[_user].packLocked[_pack]);
            }
            else {
                _sendBonus(_user,0,users[_user].packLocked[_pack]);
                emit Unlocked(_user,_pack,users[_user].packLocked[_pack]);
            }
            users[_user].packLocked[_pack] = 0;
        }

        //update rank for user
        _updateUserRank(_user,_pack);

        //add rank0 matrix2 team
        if (_pack==2&&users[_user].rank==0) users[_ref].team[users[_user].rank]++;

        //update sponsor frontline
        if (_pack==0) {
            users[_ref].frontline++;
            //unlock team locked bonuses
            for(i=0;i<rows;i++){
                if (users[_ref].frontline<qualified[i]||users[_ref].teamLocked[i]==0) continue;
                _bonus+=users[_ref].teamLocked[i];
                users[_ref].teamLocked[i] = 0;
            }
            if (_bonus>0) {
                if (!users[_ref].vip&&block.timestamp-users[_ref].lastTeamLocked>=2592000) {
                    _sendBonus(admin,0,_bonus);
                    emit Lost(_ref,pack,_bonus);
                }
                else {
                    _sendBonus(_ref,0,_bonus);
                    emit Unlocked(_ref,0,_bonus);
                }
            }
        }

        //check sponsor rank update
        _updateUserRank(_ref,_pack);

        //place user into matrix
        matrix[_user][_pack].ref = _matrix;
        matrix[_user][_pack].start = block.timestamp;

        //update matrix ref
        matrix[_matrix][_pack].frontline[matrix[_matrix][_pack].team] = _user;
        matrix[_matrix][_pack].team++;

        //personal bonus
        _bonus = (_value.mul(personalBonus)).div(10**4);
        if (_ref==root||matrix[_ref][_pack].start>0) _sendBonus(_ref,1,_bonus);
        else {
            users[_ref].packLocked[_pack]+=_bonus;
            users[_ref].lastPackLocked = block.timestamp;
            emit Locked(_ref,_pack,_bonus);
        }
        _payout = _payout.add(_bonus);

        //rank bonus
        _nextRef = _ref;
        uint16[4] memory _data = [0,rankBonus,0,30];//[maxRank,maxBonus,bonusDiff,maxUp]
        while (_data[1]>0) {
            _data[2] = rankBonuses[users[_nextRef].rank] - rankBonuses[_data[0]];
            if (_data[2]>0) {
                _data[0] = users[_nextRef].rank;
                if (_data[2]>_data[1]) _data[2] = _data[1];
                _bonus = (_value.mul(_data[2])).div(10**4);
                if (_bonus>0) {
                    _sendBonus(_nextRef,2,_bonus);
                    _payout = _payout.add(_bonus);
                }
                _data[1] -= _data[2];
            }
            _nextRef = users[_nextRef].ref;
            if (_nextRef==root) break;
            if (_data[3]>0) _data[3]--;
            else break;
        }

        //matrix bonus
        _nextRef = _matrix;
        for(i=0;i<rows;i++){
            _bonus = (_value.mul(matrixBonuses[i])).div(10**4);
            if (_bonus==0) break;
            //lock bonus if user is not qualified with n personal refs
            if (_nextRef!=root&&users[_nextRef].frontline<qualified[i]&&!users[_nextRef].vip) {
                users[_nextRef].teamLocked[i]+=_bonus;
                users[_nextRef].lastTeamLocked = block.timestamp;
                emit Locked(_nextRef,0,_bonus);
            }
            else _sendBonus(_nextRef,3,_bonus);
            _payout = _payout.add(_bonus);
            if (_nextRef==root) break;
            _nextRef = matrix[_nextRef][_pack].ref;
        }

        //infinity bonus
        _bonus = (_value.mul(infinityBonus)).div(10**4);
        _sendBonus(infinityAdr,0,_bonus);
        _payout = _payout.add(_bonus);

        //passive share
        for (i=0;i<passiveShare.length;i++) {
            _bonus = (_value.mul(passiveShare[i])).div(10**4);
            _sendBonus(passiveShareAdr[i],0,_bonus);
            _payout = _payout.add(_bonus);
        }

        //team share
        _bonus = (_value.mul(teamShare)).div(10**4);
        if (_bonus>_value.sub(_payout)) _bonus = _value.sub(_payout);
        _sendBonus(teamShareAdr,0,_bonus);
        _payout = _payout.add(_bonus);

        //send unpaid amount to root
        if (_value>_payout) _sendBonus(root,0,_value.sub(_payout));

        //close deposit
        users[_user].deposit = 0;

        //emit Upgrade event
        emit Upgrade(_user,_matrix,_value,_pack);

        isLocked = false;
        return true;
    }

    function _sendBonus(address payable _user, uint8 _type, uint256 _amount) private {
        require(_user!=address(0)&&_amount>0,"wrong data");
        if (useTrx) {
            require(_amount<=address(this).balance,"low trx balance");
            _user.transfer(_amount);
        }
        else {
            require(_amount<=token.balanceOf(address(this)),"low token balance");
            token.transfer(_user,_amount);
        }
        if (_type>0) emit Bonus(_user,_type,_amount);
    }

    function _updateUserRank(address _user, uint8 _pack) private returns(bool){
        if (_pack>=2&&users[_user].rank<5&&users[_user].pack>=users[_user].rank+2&&users[_user].team[users[_user].rank]>=rankTeam[users[_user].rank]) {
            if (rankedUsers[users[_user].rank]>0) rankedUsers[users[_user].rank]--;
            users[_user].rank++;
            rankedUsers[users[_user].rank]++;
            //update refs ref team
            if (_user!=root) users[users[_user].ref].team[users[_user].rank]++;
            emit NewRank(_user,users[_user].rank);
        }
    }

    function getUserTeam(address _user,uint8 _rank) public view returns(uint){
        return users[_user].team[_rank];
    }

    function getPackLocked(address _user, uint8 _pack) public view returns(uint256){
        return users[_user].packLocked[_pack];
    }

    function getTeamLocked(address _user, uint8 _pack) public view returns(uint256){
        return users[_user].teamLocked[_pack];
    }

    function withdrawPackLocked(address _user, uint8 _pack) public isAdmin returns(bool){
        require(_pack>=0&&_pack<packs,"wrong pack");
        require(users[_user].packLocked[_pack]>0,"empty bonus");
        require(block.timestamp-users[_user].lastPackLocked>=2592000,"too yearly");
        _sendBonus(admin,0,users[_user].packLocked[_pack]);
        users[_user].packLocked[_pack] = 0;
        return true;
    }

    function withdrawTeamLocked(address _user, uint8 _pack) public isAdmin returns(bool){
        require(_pack>=0&&_pack<packs,"wrong pack");
        require(users[_user].teamLocked[_pack]>0,"empty bonus");
        require(block.timestamp-users[_user].lastTeamLocked>=2592000,"too yearly");
        _sendBonus(admin,0,users[_user].teamLocked[_pack]);
        users[_user].teamLocked[_pack] = 0;
        return true;
    }

    function changeStatus(address _user) public isAdmin returns(bool){
        require(matrix[_user][0].start>0,"wrong user");
        users[_user].vip = !users[_user].vip;
        return users[_user].vip;
    }

    function setRate(uint _rate) public isAdmin returns(bool){
        require(_rate>0&&_rate!=rate,"wrong value");
        rate = _rate;
        return true;
    }

    function switchUseTrx() public onlyOwner returns(bool){
        useTrx = !useTrx;
        return useTrx;
    }

    function pause() public onlyOwner returns(bool){
        isPaused = !isPaused;
        return isPaused;
    }
}