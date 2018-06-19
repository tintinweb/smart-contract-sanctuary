pragma solidity ^0.4.20;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract BGXTokenInterface{

    function distribute( address _to, uint256 _amount ) public returns( bool );
    function finally( address _teamAddress ) public returns( bool );

}

contract BGXCrowdsale is Ownable{

    using SafeMath for uint256;

    BGXTokenInterface bgxTokenInterface;

    address   public bgxWallet;
    address[] public adviser;
    address[] public bounty;
    address[] public team;

    mapping( address => uint256 ) adviserAmount;
    mapping( address => uint256 ) bountyAmount;
    mapping( address => uint256 ) teamAmount;

    uint256 public presaleDateStart      = 1524571200;
    uint256 public presaleDateFinish     = 1526385600;
    uint256 public saleDateStart         = 1526990400;
    uint256 public saleDateFinish        = 1528200000;

    uint256 constant public hardcap      = 500000000 ether;
    uint256 public presaleHardcap        = 30000000  ether;
    uint256 public softcap               = 40000000  ether;
    uint256 public totalBGX              = 0;
    uint256 constant public minimal      = 1000 ether;

    uint256 reserved                     = 250000000 ether;
    uint256 constant teamLimit           = 100000000 ether;
    uint256 constant advisersLimit       = 100000000 ether;
    uint256 constant bountyLimit         = 50000000 ether;
    uint256 public distributionDate      = 0;

    bool paused = false;

    enum CrowdsaleStates { Pause, Presale, Sale, OverHardcap, Finish }

    CrowdsaleStates public state = CrowdsaleStates.Pause;

    uint256 public sendNowLastCount = 0;
    uint256 public finishLastCount = 0;
    uint256 public finishCurrentLimit = 0;

    modifier activeState {
        require(
            getState() == CrowdsaleStates.Presale
            || getState() == CrowdsaleStates.Sale
        );
        _;
    }

    modifier onPause {
        require(
            getState() == CrowdsaleStates.Pause
        );
        _;
    }

    modifier overSoftcap {
        require(
            totalBGX >= softcap
        );
        _;
    }

    modifier finishOrHardcap {
        require(
            getState() == CrowdsaleStates.OverHardcap
            || getState() == CrowdsaleStates.Finish
        );
        _;
    }

    // fix for short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4);
        _;
    }

    address[]                     public investors;
    mapping( address => uint256 ) public investorBalance;
    mapping( address => bool )    public inBlackList;



    function setBgxWalletAddress( address _a ) public onlyOwner returns( bool )
    {
        require( address(0) != _a );
        bgxWallet = _a;
        return true;
    }

    function setCrowdsaleDate( uint256 _presaleStart, uint256 _presaleFinish, uint256 _saleStart, uint256 _saleFinish ) public onlyOwner onPause returns( bool )
    {
        presaleDateStart = _presaleStart;
        presaleDateFinish = _presaleFinish;
        saleDateStart = _saleStart;
        saleDateFinish = _saleFinish;

        return true;
    }

    function setCaps( uint256 _presaleHardcap, uint256 _softcap ) public onlyOwner onPause returns( bool )
    {
        presaleHardcap = _presaleHardcap;
        softcap = _softcap;

        return true;
    }


    function getState() public returns( CrowdsaleStates )
    {

        if( state == CrowdsaleStates.Pause || paused ) return CrowdsaleStates.Pause;
        if( state == CrowdsaleStates.Finish ) return CrowdsaleStates.Finish;

        if( totalBGX >= hardcap ) return CrowdsaleStates.OverHardcap;


        if( now >= presaleDateStart && now <= presaleDateFinish ){

            if( totalBGX >= presaleHardcap ) return CrowdsaleStates.Pause;
            return CrowdsaleStates.Presale;

        }

        if( now >= saleDateStart && now <= saleDateFinish ){

            if( totalBGX >= hardcap ) {
                _startCounter();
                return CrowdsaleStates.OverHardcap;
            }
            return CrowdsaleStates.Sale;

        }

        if( now > saleDateFinish ) {
            _startCounter();
            return CrowdsaleStates.Finish;
        }

        return CrowdsaleStates.Pause;

    }

    function _startCounter() internal
    {
        if (distributionDate <= 0) {
            distributionDate = now + 2 days;
        }
    }


    function pauseStateSwithcer() public onlyOwner returns( bool )
    {
        paused = !paused;
    }

    function start() public onlyOwner returns( bool )
    {
        state = CrowdsaleStates.Presale;

        return true;
    }


    function send(address _addr, uint _amount) public onlyOwner activeState onlyPayloadSize(2 * 32) returns( bool )
    {
        require( address(0) != _addr && _amount >= minimal && !inBlackList[_addr] );

        if( getState() == CrowdsaleStates.Presale ) require( totalBGX.add( _amount ) <= presaleHardcap );
        if( getState() == CrowdsaleStates.Sale )    require( totalBGX.add( _amount ) <= hardcap );


        investors.push( _addr );


        investorBalance[_addr] = investorBalance[_addr].add( _amount );
        if ( !inBlackList[_addr]) {
            totalBGX = totalBGX.add( _amount );
        }
        return true;

    }

    function investorsCount() public constant returns( uint256 )
    {
        return investors.length;
    }

    function sendNow( uint256 _count ) public onlyOwner overSoftcap  returns( bool )
    {
        require( sendNowLastCount.add( _count ) <= investors.length );

        uint256 to = sendNowLastCount.add( _count );

        for( uint256 i = sendNowLastCount; i <= to - 1; i++ )
            if( !inBlackList[investors[i]] ){
                investorBalance[investors[i]] = 0;
                bgxTokenInterface.distribute( investors[i], investorBalance[investors[i]] );
            }

        sendNowLastCount = sendNowLastCount.add( _count );
    }


    function blackListSwithcer( address _addr ) public onlyOwner returns( bool )
    {
        require( address(0) != _addr );

        if( !inBlackList[_addr] ){
            totalBGX = totalBGX.sub( investorBalance[_addr] );
        } else {
            totalBGX = totalBGX.add( investorBalance[_addr] );
        }

        inBlackList[_addr] = !inBlackList[_addr];

    }


    function finish( uint256 _count) public onlyOwner finishOrHardcap overSoftcap returns( bool )
    {
        require(_count > 0);
        require(distributionDate > 0 && distributionDate <= now);
        if (finishCurrentLimit == 0) {
            finishCurrentLimit = bountyLimit.add(teamLimit.add(advisersLimit));
        }
        // advisers + bounters total cnt
        uint256 totalCnt = adviser.length.add(bounty.length);

        if (finishLastCount < adviser.length) {
            for( uint256 i = finishLastCount; i <= adviser.length - 1; i++  ){
                finishCurrentLimit = finishCurrentLimit.sub( adviserAmount[adviser[i]] );
                bgxTokenInterface.distribute( adviser[i],adviserAmount[adviser[i]] );
                finishLastCount++;
                _count--;
                if (_count <= 0) {
                    return true;
                }
            }
        }
        if (finishLastCount < totalCnt) {
            for( i = finishLastCount.sub(adviser.length); i <= bounty.length - 1; i++  ){
                finishCurrentLimit = finishCurrentLimit.sub( bountyAmount[bounty[i]] );
                bgxTokenInterface.distribute( bounty[i],bountyAmount[bounty[i]] );
                finishLastCount ++;
                _count--;
                if (_count <= 0) {
                    return true;
                }
            }
        }
        if (finishLastCount >= totalCnt && finishLastCount < totalCnt.add(team.length)) {
            for( i =  finishLastCount.sub(totalCnt); i <= team.length - 1; i++  ){

                finishCurrentLimit = finishCurrentLimit.sub( teamAmount[team[i]] );
                bgxTokenInterface.distribute( team[i],teamAmount[team[i]] );
                finishLastCount ++;
                _count--;
                if (_count <= 0) {
                    return true;
                }
            }
        }

        reserved = reserved.add( finishCurrentLimit );

        return true;

    }



    function sendToTeam() public onlyOwner finishOrHardcap overSoftcap returns( bool )
    {
        bgxTokenInterface.distribute( bgxWallet, reserved );
        bgxTokenInterface.finally( bgxWallet );

        return true;
    }




    function setAdvisers( address[] _addrs, uint256[] _amounts ) public onlyOwner finishOrHardcap returns( bool )
    {
        require( _addrs.length == _amounts.length );

        adviser = _addrs;
        uint256 limit = 0;

        for( uint256 i = 0; i <= adviser.length - 1; i++  ){
            require( limit.add( _amounts[i] ) <= advisersLimit );
            adviserAmount[adviser[i]] = _amounts[i];
            limit.add( _amounts[i] );
        }
    }

    function setBounty( address[] _addrs, uint256[] _amounts ) public onlyOwner finishOrHardcap returns( bool )
    {
        require( _addrs.length == _amounts.length );

        bounty = _addrs;
        uint256 limit = 0;

        for( uint256 i = 0; i <= bounty.length - 1; i++  ){
            require( limit.add( _amounts[i] ) <= bountyLimit );
            bountyAmount[bounty[i]] = _amounts[i];
            limit.add( _amounts[i] );
        }
    }

    function setTeams( address[] _addrs, uint256[] _amounts ) public onlyOwner finishOrHardcap returns( bool )
    {
        require( _addrs.length == _amounts.length );

        team = _addrs;
        uint256 limit = 0;

        for( uint256 i = 0; i <= team.length - 1; i++  ){
            require( limit.add( _amounts[i] ) <= teamLimit );
            teamAmount[team[i]] = _amounts[i];
            limit.add( _amounts[i] );
        }
    }


    function setBGXTokenInterface( address _BGXTokenAddress ) public onlyOwner returns( bool )
    {
        require( _BGXTokenAddress != address(0) );
        bgxTokenInterface = BGXTokenInterface( _BGXTokenAddress );
    }


    function time() public constant returns(uint256 )
    {
        return now;
    }




}