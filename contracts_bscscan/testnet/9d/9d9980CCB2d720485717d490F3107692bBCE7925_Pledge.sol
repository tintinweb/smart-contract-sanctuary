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
    uint32 interestTime;

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
    function doPledge(uint32 _cycle, uint _gsAmount) external payable returns(bool){
        uint32 peledgeRate = PP.getPeriodRate(_cycle);
        require(peledgeRate > 0, "_cycle err");
        uint32  base= 1000000;
        uint gcAmount = GSPrice.mul(_gsAmount).div(10**18).mul(peledgeRate).div(base);
        uint _id = pledges.length;
        uint32 _startTime = uint32(block.timestamp);
        //uint32 _endTime = _startTime + _cycle * 3600 * 24;
        uint32 _endTime = _startTime + _cycle;

        GS.transferFrom(msg.sender, address(this), _gsAmount);
        payable(msg.sender).transfer(gcAmount);
        pledges.push(record(1, _gsAmount, gcAmount, _cycle, _startTime, _endTime));
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
        doInterest(GSPrice);
        pledges[_index].status = 2;
        return true;
    }

    /**
    * @dev Replenishment: increase the quantity of pledged gs to avoid the penalty caused by lending GC greater than GS when the price of GS decreases 
    * @param _index  Loan record index ID 
    * @param _gsAmount  Increased number of GS 
    */
    function replenishment(uint _index, uint _gsAmount) external payable returns(bool){
        require(whose[_index] == msg.sender, "owner err");
        uint32 nowTime = uint32(block.timestamp);
        require(nowTime < pledges[_index].endTime, "time err");
        GS.transferFrom(msg.sender, address(this), _gsAmount);
        pledges[_index].gsAmount = pledges[_index].gsAmount.add(_gsAmount);
        emit Replenishment(msg.sender, _index, _gsAmount);
        return true;
    }

    /**
    * @dev  Deduction for external swap calls 
    * @param gsPrice  Price of GS corresponding to GC 
    */
    function interest(uint gsPrice) external{
        require(msg.sender == GSWAPAddress, " Insufficient permissions ");
        require(doInterest(gsPrice), "today has done");
    }

    /**
    * @dev  Deducting daily interest / default interest / overdue interest 
    * @param gsPrice  Price of GS corresponding to GC 
    */
    function doInterest(uint gsPrice) internal returns(bool){
        
        //uint _interestDay = interestTime / 3600 / 24;
        //uint _nowDay = block.timestamp / 3600 / 24;
        uint _interestDay = interestTime;
        uint _nowDay = block.timestamp;
        if(_interestDay == _nowDay){
            return false;
        }
        uint _len = pledges.length;
        uint base = 1000000;
        uint32 nowTime = uint32(block.timestamp);
        uint32 addDay = 1; // addDay = 3600 * 24;
        uint times = _nowDay - _interestDay;
        for(uint j=0; j<times; j++){
            for(uint i=0; i<_len; i++){
                if(pledges[i].status == 1){
                    if(pledges[i].startTime > interestTime){
                        continue;
                    }

                    if(nowTime > pledges[i].endTime){
                        uint punishRate = PP.getPeriodPunishRate(pledges[i].cycle);
                        uint punishGsAmount = pledges[i].gcAmount.mul(10**18).mul(punishRate).div(base).div(gsPrice);
                        if(punishGsAmount > pledges[i].gsAmount){
                            punishGsAmount = pledges[i].gsAmount;
                        }
                        GS.transfer(punishRateWallet, punishGsAmount);
                        pledges[i].gsAmount = pledges[i].gsAmount.sub(punishGsAmount);
                        emit TimeOutInterest(whose[i], i, punishGsAmount);
                    }
                    else{
                        uint gsForGcAmount = pledges[i].gsAmount.mul(gsPrice).div(10**18);
                        if(gsForGcAmount < pledges[i].gcAmount){
                            uint punishRate = PP.getPeriodPunishRate(pledges[i].cycle);
                            uint punishGsAmount = (pledges[i].gcAmount.sub(gsForGcAmount)).mul(10**18).mul(punishRate).div(base).div(gsPrice);
                            if(punishGsAmount > pledges[i].gsAmount){
                                punishGsAmount = pledges[i].gsAmount;
                            }
                            GS.transfer(punishRateWallet, punishGsAmount);
                            pledges[i].gsAmount = pledges[i].gsAmount.sub(punishGsAmount);
                            emit PunishInterest(whose[i], i, punishGsAmount);
                        }

                        uint dayRate = PP.getPeriodDayRate(pledges[i].cycle);
                        uint interestGsAmount = pledges[i].gcAmount.mul(10**18).mul(dayRate).div(base).div(gsPrice);
                        if(interestGsAmount > pledges[i].gsAmount){
                            interestGsAmount = pledges[i].gsAmount;
                        }
                        GS.transfer(dayRateWallet, interestGsAmount);
                        pledges[i].gsAmount = pledges[i].gsAmount.sub(interestGsAmount);
                        emit DayInterest(whose[i], i, interestGsAmount);
                    }
                    
                }
            }
            interestTime += addDay;
        }
        
        GSPrice = gsPrice;
        return true;
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
    function getPledgeInfo(uint _index)external view returns(uint8 _status, uint _gsAmount, uint _gcAmount, uint _cycle, uint32 _startTime){
        return(pledges[_index].status, pledges[_index].gsAmount, pledges[_index].gcAmount, pledges[_index].cycle, pledges[_index].startTime);
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

    function Recharge()external payable{
        
    }

    function withdrawal()external payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback ()external payable{}
    receive ()external payable{}
}