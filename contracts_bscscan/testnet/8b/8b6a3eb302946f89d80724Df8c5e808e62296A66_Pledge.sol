// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6;

/**
* @devIn the pledge agreement, 
* the player uses gs to calculate the corresponding GC through the pledge agreement, 
* GS price and pledge rule parameters and give it to the player
*/
import "./IPledgePeriod.sol";
import "./SafeMath256.sol";
import "./IERC20.sol";

contract Pledge{

    uint public GSPrice;
    uint32 public interestTime;
    uint32 public addDay = 1;

    using SafeMath256 for uint256;

    address public owner;
    address public dayRateWallet;
    address public punishRateWallet;
    address public GSWAPAddress;

    mapping (uint=>address) whose;
    mapping (address=>uint) playerRecordCount;
    IPledgePeriod PP;
    IERC20 GS;
    record[] pledges;

    /**
    * @dev  Loan record 
    * status  Mortgage record status 1: mortgage in progress; 2: repayment 
    * gsAmount  Number of pledged GS 
    * gcAmount  Number of GC's borrowed 
    * cycle  The borrowing cycle is also an index for obtaining borrowing rules 
    * startTime  Record creation time 
    * endTime  Maturity of loan 
    */
    struct record{
        uint8 status;
        uint gsAmount;
        uint gcAmount;
        uint32 cycle;
        uint32 startTime;
        uint32 interestDay;
        uint32 endTime;
    }

    event DoPledge(address indexed _owner, uint _gsAmount, uint _gcAmount, uint32 indexed _cycle, uint _pledgesId);
    event Repayment(address indexed _owner, uint indexed _pledgesId);
    event Replenishment(address indexed _owner, uint indexed _pledgesId, uint _amount);
    event DayInterest(address indexed _owner, uint indexed _pledgesId, uint _amount);
    event PunishInterest(address indexed _owner, uint indexed _pledgesId, uint _amount);
    event TimeOutInterest(address indexed _owner, uint indexed _pledgesId, uint _amount);

    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner err");
        _;
    }

    constructor(address _GSaddress, address _PPaddress, uint _gsPrice){
        owner = msg.sender;
        dayRateWallet = msg.sender;
        punishRateWallet = msg.sender;
        GSWAPAddress = msg.sender;
        GS = IERC20(_GSaddress);
        PP = IPledgePeriod(_PPaddress);
        interestTime = uint32(block.timestamp);
        GSPrice = _gsPrice;
    }

    function changeOwner(address _owner)external onlyOwner{
        owner = _owner;
    }

    /**
    * @dev  Loan: obtain relevant rules and systems by pledge days, calculate loan quantity and create loan records 
    * @param _cycle  The borrowing cycle is also an index for obtaining borrowing rules 
    * @param _gsAmount  Number of pledged GS 
    */
    function doPledge(uint32 _cycle, uint _gsAmount) external returns(bool){
        uint32 peledgeRate = PP.getPeriodRate(_cycle);
        require(peledgeRate > 0, "_cycle err");
        uint32  base= 1000000;
        uint gcAmount = GSPrice.mul(_gsAmount).div(10**18).mul(peledgeRate).div(base);
        uint _id = pledges.length;
        if(_id == 0){
            interestTime = uint32(block.timestamp);
        }
        uint32 _startTime = uint32(block.timestamp);
        uint32 _endTime = _startTime + _cycle * addDay;

        GS.transferFrom(msg.sender, address(this), _gsAmount);
        payable(msg.sender).transfer(gcAmount);
        uint32 _interestDay = _startTime / addDay;
        pledges.push(record(1, _gsAmount, gcAmount, _cycle, _startTime, _interestDay, _endTime));
        whose[_id] = msg.sender;
        playerRecordCount[msg.sender]++;
        emit DoPledge(msg.sender, _gsAmount, gcAmount, _cycle, _id);
        return true;
    }

    /**
    * @dev  Repayment: players can make repayment when the pledge is due to avoid being punished for overdue payment 
    * @param _index  Loan record index ID 
    */
    function repayment(uint _index) external payable returns(bool){
        require(whose[_index] == msg.sender, "owner err");
        require(pledges[_index].status == 1, "status err");
        require(msg.value == pledges[_index].gcAmount, "value err");
        uint32 nowTime = uint32(block.timestamp);
        require(nowTime>pledges[_index].endTime, "time err");
        GS.transfer(msg.sender, pledges[_index].gsAmount);
        emit Repayment(msg.sender, _index);
        pledges[_index].status = 2;
        return true;
    }

    /**
    * @dev Replenishment: increase the quantity of pledged gs to avoid the penalty caused by lending GC greater than GS when the price of GS decreases 
    * @param _index  Loan record index ID 
    * @param _gsAmount  Increased number of GS 
    */
    function replenishment(uint _index, uint _gsAmount) external returns(bool){
        require(whose[_index] == msg.sender, "owner err");
        uint32 nowTime = uint32(block.timestamp);
        require(nowTime < pledges[_index].endTime, "time err");
        GS.transferFrom(msg.sender, address(this), _gsAmount);
        pledges[_index].gsAmount = pledges[_index].gsAmount.add(_gsAmount);
        emit Replenishment(msg.sender, _index, _gsAmount);
        return true;
    }

    /**
    * @dev  Deducting daily interest / default interest / overdue interest 
    * @param _id  Loan record index ID 
    */
    function interestByTargetId(uint _id)external returns(bool){
        require(pledges[_id].status == 1, "status err");
        uint32 nowTime = uint32(block.timestamp);
        uint32 _nowDay = nowTime / addDay;
        if(pledges[_id].interestDay >= _nowDay){
            return false;
        }

        uint base = 1000000;
        uint punishGsAmount = 0;
        uint interestGsAmount = 0;
        record storage rec = pledges[_id];
        if(nowTime > rec.endTime){
            uint punishRate = PP.getPeriodPunishRate(rec.cycle);
            uint _punishGsAmount = rec.gcAmount.mul(10**18).mul(punishRate).div(base).div(GSPrice);
            if(_punishGsAmount > rec.gsAmount){
                _punishGsAmount = rec.gsAmount;
            }
            punishGsAmount = punishGsAmount.add(_punishGsAmount);
            
            rec.gsAmount = rec.gsAmount.sub(_punishGsAmount);
            emit TimeOutInterest(whose[_id], _id, _punishGsAmount);
        }
        else{
            uint gsForGcAmount = rec.gsAmount.mul(GSPrice).div(10**18);
            if(gsForGcAmount < rec.gcAmount){
                uint punishRate = PP.getPeriodPunishRate(rec.cycle);
                uint _punishGsAmount = (rec.gcAmount.sub(gsForGcAmount)).mul(10**18).mul(punishRate).div(base).div(GSPrice);
                if(_punishGsAmount > rec.gsAmount){
                    _punishGsAmount = rec.gsAmount;
                }
                punishGsAmount = punishGsAmount.add(_punishGsAmount);
                rec.gsAmount = rec.gsAmount.sub(_punishGsAmount);
                emit PunishInterest(whose[_id], _id, _punishGsAmount);
            }

            uint dayRate = PP.getPeriodDayRate(rec.cycle);
            uint _interestGsAmount = rec.gcAmount.mul(10**18).mul(dayRate).div(base).div(GSPrice);
            if(_interestGsAmount > rec.gsAmount){
                _interestGsAmount = rec.gsAmount;
            }
            interestGsAmount = interestGsAmount.add(_interestGsAmount);
            rec.gsAmount = rec.gsAmount.sub(_interestGsAmount);
            emit DayInterest(whose[_id], _id, _interestGsAmount);
        }
        GS.transfer(punishRateWallet, punishGsAmount);
        GS.transfer(dayRateWallet, interestGsAmount);
        rec.interestDay = _nowDay;
        return true;
    }

    function getInterestId()external view returns(uint[]memory){
        uint _len = pledges.length;
        uint[] memory res = new uint[](_len);
        uint32 nowDay = uint32(block.timestamp) / addDay;
        uint count = 0;
        for(uint i=0; i<_len; i++){
            if(pledges[i].status==1 && pledges[i].interestDay<nowDay){
                res[count] = i;
                count++;
            }
        }

        return res;
    }

    /**
    * @dev  Get all loan record IDs of the specified player 
    * @param _owner  Player wallet address 
    * @return res  Loan record ID array 
    */
    function getPledgesId(address _owner) external view returns(uint[] memory){
        uint _len = pledges.length;
        uint[] memory result = new uint[](playerRecordCount[_owner]);
        uint _count = 0;
        for(uint i=0; i<_len; i++){
            if(whose[i] == _owner){
                result[_count] = i;
                _count++;
            }
        }

        return result;
    }

    /**
    * @dev  Gets the pledge record information of the specified ID 
    * @param _index  Mortgage record index ID 
    * @return _status  Mortgage record status 1: mortgage in progress; 2: repayment 
    * @return _gsAmount  Number of pledged GS 
    * @return _gcAmount  Number of GC's borrowed 
    * @return _cycle  The borrowing cycle is also an index for obtaining borrowing rules 
    * @return _startTime  Record creation time 
    */
    function getPledgeInfo(uint _index)external view returns(uint8 _status, uint _gsAmount, uint _gcAmount, uint _cycle, uint32 _startTime, uint32 _endTime){
        return(pledges[_index].status, pledges[_index].gsAmount, pledges[_index].gcAmount, pledges[_index].cycle, pledges[_index].startTime, pledges[_index].endTime);
    }

    /**
    * @dev  Get the total quantity of GS in all pledge pools at present 
    */
    function getPledgeGsCount()external view returns(uint _gsCount){
        uint _len = pledges.length;
        for(uint i=0; i<_len; i++){
            if(pledges[i].status == 1){
                _gsCount = _gsCount.add(pledges[i].gsAmount);
            }
        }
    }

    /**
    * @dev  Get the total quantity of GC in all pledge pools at present 
    */
    function getPledgeGcCount()external view returns(uint _gcCount){
        uint _len = pledges.length;
        for(uint i=0; i<_len; i++){
            if(pledges[i].status == 1){
                _gcCount = _gcCount.add(pledges[i].gcAmount);
            }
        }
    }


    function setGSPrice(uint _gsp)external onlyOwner{
        GSPrice = _gsp;
    }
    function setPP(address _pp)external onlyOwner{
        PP = IPledgePeriod(_pp);
    }
    function setGS(address _gs)external onlyOwner{
        GS = IERC20(_gs);
    }
    function setDayRateWallet(address _dayRateWallet)external onlyOwner{
        dayRateWallet = _dayRateWallet;
    }
    function setPunishRateWallet(address _punishRateWallet)external onlyOwner{
        punishRateWallet = _punishRateWallet;
    }
    function setGSWAPAddress(address _GSWAPAddress)external onlyOwner{
        GSWAPAddress = _GSWAPAddress;
    }
    function setAddDay(uint32 _addDay)external onlyOwner{
        addDay = _addDay;
    }

    function Recharge()external payable{
        
    }

    function withdrawal()external payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback ()external payable{}
    receive ()external payable{}
}