// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public owner;
    address public newowner;
    address public admin;
    address public dev;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyNewOwner {
        require(msg.sender == newowner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newowner = _newOwner;
    }
    
    function takeOwnership() public onlyNewOwner {
        owner = newowner;
    }    
    
    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }
    
    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == owner);
        _;
    }
}

abstract contract ContractConn{
    function transfer(address _to, uint _value) virtual public;
    function transferFrom(address _from, address _to, uint _value) virtual public;
    function balanceOf(address who) virtual public view returns (uint);
    function burn(uint256 _value) virtual public returns(bool);
}

contract Pledge is Ownable {

    using SafeMath for uint256;
    
    struct PledgeInfo {
        uint256 id;
        address pledgeor;
        string  coinType;
        uint256 amount;
        uint256 pledgeTime;
        uint256 pledgeBlock;
        uint256 ExpireBlock;
        bool    isValid;
    }
    
    ContractConn public zild;
    
    uint256 public pledgeBlock = 90000;
    uint256 public pledgeBlockChange = 0;
    uint256 public changePledgeTime;
    bool    public needChangeTime = false; 
	uint256 public burnCount = 0;
    uint256 public totalPledge;
    
    mapping(address => PledgeInfo[]) public zild_pledge;
    mapping(address => uint256) public user_pledge_amount;

    event SetPledgeBlock(uint256 pblock,address indexed who,uint256 time);
    event EffectPledgeBlock(uint256 pblock,address indexed who,uint256 time);
    event WithdrawZILD(address indexed to,uint256 pamount,uint256 time);
    event NeedBurnPledge(address indexed to,uint256 pleid,uint256 pamount);
    event BurnPledge(address  indexed from,uint256 pleid,uint256 pamount);
    event PledgeZILD(address indexed from,uint256 pleid,uint256 pamount,uint256 bblock,uint256 eblock,uint256 time);
    
    constructor(address _zild) public {
        zild = ContractConn(_zild);
    }

    function setpledgeblock(uint256 _block) public onlyAdmin {
        require(_block > 0,"Pledge: New pledge time must be greater than 0");
        pledgeBlockChange = _block;
        changePledgeTime = block.number;
        needChangeTime = true;
        emit SetPledgeBlock(_block,msg.sender,now);
    }

    function effectblockchange() public onlyAdmin {
        require(needChangeTime,"Pledge: No new deposit time are set");
        uint256 currentTime = block.number;
        uint256 effectTime = changePledgeTime.add(pledgeBlock);
        if (currentTime < effectTime) return;
        pledgeBlock = pledgeBlockChange;
        needChangeTime = false;
        emit EffectPledgeBlock(pledgeBlockChange,msg.sender,now);
    }
    

    function burn(uint256 _amount) public onlyAdmin returns(bool) {
        require(_amount > 0 || _amount < burnCount, "pledgeBurn：The amount exceeds the amount that should be burned");
        zild.burn(_amount);
        burnCount = burnCount.sub(_amount);
        emit BurnPledge(address(msg.sender),_amount,now);
        return true;
    }

    function pledgeZILD(uint256 _amount) public returns(uint256){
        zild.transferFrom(address(msg.sender), address(this), _amount);
        uint256 length = zild_pledge[msg.sender].length;
        zild_pledge[msg.sender].push(
            PledgeInfo({
                id: length,
                pledgeor: msg.sender,
                coinType: "zild",
                amount: _amount,
                pledgeTime: now,
                pledgeBlock: block.number,
                ExpireBlock: block.number.add(pledgeBlock),
                isValid: true
            })
        );
        user_pledge_amount[msg.sender] = user_pledge_amount[msg.sender].add(_amount); 
        totalPledge = totalPledge.add(_amount);
        emit PledgeZILD(msg.sender,length,_amount,block.number,block.number.add(pledgeBlock),now);
        return length;
    }

    function invalidPledge(address _user, uint256 _id) public onlyDev {
        require(zild_pledge[_user].length > _id);
        zild_pledge[_user][_id].isValid = false;
    }
    
    function validPledge(address _user, uint256 _id) public onlyAdmin{
        require(zild_pledge[_user].length > _id);
        zild_pledge[_user][_id].isValid = true;
    }
    
    function pledgeCount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Pledge: Only check your own pledge records");
        return zild_pledge[_user].length;
    }
 
     function pledgeAmount(address _user)  view public returns(uint256) {
        require(msg.sender == _user || msg.sender == owner, "Pledge: Only check your own pledge records");
        return user_pledge_amount[_user];
    }
    
    function clearInvalidOrder(address _user, uint256 _pledgeId) public onlyAdmin{
        PledgeInfo memory pledgeInfo = zild_pledge[address(_user)][_pledgeId];
        if(!pledgeInfo.isValid) {
            burnCount = burnCount.add(pledgeInfo.amount);
            user_pledge_amount[_user] = user_pledge_amount[_user].sub(pledgeInfo.amount); 
            totalPledge = totalPledge.sub(pledgeInfo.amount);
            zild_pledge[address(_user)][_pledgeId].amount = 0;
            emit NeedBurnPledge(_user,_pledgeId,pledgeInfo.amount);
        }
    }
 
    function withdrawZILD(uint256 _pledgeId) public returns(bool){
        PledgeInfo memory info = zild_pledge[msg.sender][_pledgeId]; 
        require(block.number > info.ExpireBlock, "The withdrawal block has not arrived!");
        require(info.isValid, "The withdrawal pledge has been breached!");
        zild.transfer(msg.sender,info.amount);
        user_pledge_amount[msg.sender] = user_pledge_amount[msg.sender].sub(info.amount); 
        totalPledge = totalPledge.sub(info.amount);
        zild_pledge[msg.sender][_pledgeId].amount = 0;
        emit WithdrawZILD(msg.sender,zild_pledge[msg.sender][_pledgeId].amount,now);
        return true;
    }
}