pragma solidity ^0.4.11;
contract SafeMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {
    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Contribution is SafeMath, Owned {
    uint256 public constant MIN_FUND = (0.01 ether);
    uint256 public constant CRAWDSALE_START_DAY = 1;
    uint256 public constant CRAWDSALE_END_DAY = 7;

    uint256 public dayCycle = 24 hours;
    uint256 public fundingStartTime = 0;
    address public ethFundDeposit = 0;
    address public investorDeposit = 0;
    bool public isFinalize = false;
    bool public isPause = false;
    mapping (uint => uint) public dailyTotals; //total eth per day
    mapping (uint => mapping (address => uint)) public userBuys; // otal eth per day per user
    uint256 public totalContributedETH = 0; //total eth of 7 days

    // events
    event LogBuy (uint window, address user, uint amount);
    event LogCreate (address ethFundDeposit, address investorDeposit, uint fundingStartTime, uint dayCycle);
    event LogFinalize (uint finalizeTime);
    event LogPause (uint finalizeTime, bool pause);

    function Contribution (address _ethFundDeposit, address _investorDeposit, uint256 _fundingStartTime, uint256 _dayCycle)  {
        require( now < _fundingStartTime );
        require( _ethFundDeposit != address(0) );

        fundingStartTime = _fundingStartTime;
        dayCycle = _dayCycle;
        ethFundDeposit = _ethFundDeposit;
        investorDeposit = _investorDeposit;
        LogCreate(_ethFundDeposit, _investorDeposit, _fundingStartTime,_dayCycle);
    }

    //crawdsale entry
    function () payable {  
        require(!isPause);
        require(!isFinalize);
        require( msg.value >= MIN_FUND ); //eth >= 0.01 at least

        ethFundDeposit.transfer(msg.value);
        buy(today(), msg.sender, msg.value);
    }

    function importExchangeSale(uint256 day, address _exchangeAddr, uint _amount) onlyOwner {
        buy(day, _exchangeAddr, _amount);
    }

    function buy(uint256 day, address _addr, uint256 _amount) internal {
        require( day >= CRAWDSALE_START_DAY && day <= CRAWDSALE_END_DAY ); 

        //record user&#39;s buy amount
        userBuys[day][_addr] += _amount;
        dailyTotals[day] += _amount;
        totalContributedETH += _amount;

        LogBuy(day, _addr, _amount);
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }

    function pause(bool _isPause) onlyOwner {
        isPause = _isPause;
        LogPause(now,_isPause);
    }

    function finalize() onlyOwner {
        isFinalize = true;
        LogFinalize(now);
    }

    function today() constant returns (uint) {
        return sub(now, fundingStartTime) / dayCycle + 1;
    }
}