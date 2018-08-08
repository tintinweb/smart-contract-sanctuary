pragma solidity ^0.4.14;

contract DSMath {
    
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

contract Owned
{
    address public owner;
    
    function Owned()
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner()
    {
        if (msg.sender != owner) revert();
        _;
    }
}

contract ProspectorsCrowdsale is Owned, DSMath
{
    ProspectorsGoldToken public token;
    address public dev_multisig; //multisignature wallet to collect funds
    
    uint public total_raised; //crowdsale total funds raised
    uint public contributors_count = 0; //crowdsale total funds raised
    
    uint public constant start_time = 1502377200; //crowdsale start time - August 10, 15:00 UTC
    uint public constant end_time = 1505055600; //crowdsale end time - Septempber 10, 15:00 UTC
    uint public constant bonus_amount = 10000000 * 10**18; //amount of tokens by bonus price
    uint public constant start_amount = 60000000 * 10**18; //tokens amount allocated for crowdsale
    uint public constant price =  0.0005 * 10**18; //standart token price in ETH 
    uint public constant bonus_price = 0.0004 * 10**18; //bonus token price in ETH
    uint public constant goal = 2000 ether; //soft crowdsale cap. If not reached funds will be returned
    bool private closed = false; //can be true after end_time or when all tokens sold
    
    mapping(address => uint) funded; //needed to save amounts of ETH for refund
    
    modifier in_time //allows send eth only when crowdsale is active
    {
        if (time() < start_time || time() > end_time)  revert();
        _;
    }

    function is_success() public constant returns (bool)
    {
        return closed == true && total_raised >= goal;
    }
    
    function time() public constant returns (uint)
    {
        return block.timestamp;
    }
    
    function my_token_balance() public constant returns (uint)
    {
        return token.balanceOf(this);
    }
    
    //tokens amount available by bonus price
    function available_with_bonus() public constant returns (uint)
    {
        return my_token_balance() >=  min_balance_for_bonus() ? 
                my_token_balance() - min_balance_for_bonus() 
                : 
                0;
    }
    
    function available_without_bonus() private constant returns (uint)
    {
        return min(my_token_balance(),  min_balance_for_bonus());
    }
    
    function min_balance_for_bonus() private constant returns (uint)
    {
        return start_amount - bonus_amount;
    }
    
    //prevent send less than 0.01 ETH
    modifier has_value
    {
        if (msg.value < 0.01 ether) revert();
        _;
    }

    function init(address _token_address, address _dev_multisig) onlyOwner
    {
        if (address(0) != address(token)) revert();
        token = ProspectorsGoldToken(_token_address);
        dev_multisig = _dev_multisig;
    }
    
    //main contribute function
    function participate() in_time has_value private {
        if (my_token_balance() == 0 || closed == true) revert();

        var remains = msg.value;
        
         //calculate tokens amount by bonus price
        var can_with_bonus = wdiv(cast(remains), cast(bonus_price));
        var buy_amount = cast(min(can_with_bonus, available_with_bonus()));
        remains = sub(remains, wmul(buy_amount, cast(bonus_price)));
        
        if (buy_amount < can_with_bonus) //calculate tokens amount by standart price if tokens with bonus don&#39;t cover eth amount
        {
            var can_without_bonus = wdiv(cast(remains), cast(price));
            var buy_without_bonus = cast(min(can_without_bonus, available_without_bonus()));
            remains = sub(remains, wmul(buy_without_bonus, cast(price)));
            buy_amount = hadd(buy_amount, buy_without_bonus);
        }

        if (remains > 0) revert();

        total_raised = add(total_raised, msg.value);
        if (funded[msg.sender] == 0) contributors_count++;
        funded[msg.sender] = add(funded[msg.sender], msg.value);

        token.transfer(msg.sender, buy_amount); //transfer tokens to participant
    }
    
    function refund() //allows get eth back if min goal not reached
    {
        if (total_raised >= goal || closed == false) revert();
        var amount = funded[msg.sender];
        if (amount > 0)
        {
            funded[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }
    
    function closeCrowdsale() //close crowdsale. this action unlocks refunds or token transfers
    {
        if (closed == false && time() > start_time && (time() > end_time || my_token_balance() == 0))
        {
            closed = true;
            if (is_success())
            {
                token.unlock(); //unlock token transfers
                if (my_token_balance() > 0)
                {
                    token.transfer(0xb1, my_token_balance()); //move not saled tokens to game balance
                }
            }
        }
        else
        {
            revert();
        }
    }
    
    function collect() //collect eth by devs if min goal reached
    {
        if (total_raised < goal) revert();
        dev_multisig.transfer(this.balance);
    }

    function () payable external 
    {
        participate();
    }
    
    //allows destroy this whithin 180 days after crowdsale ends
    function destroy() onlyOwner
    {
        if (time() > end_time + 180 days)
        {
            selfdestruct(dev_multisig);
        }
    }
}

contract ProspectorsGoldToken {
    function balanceOf( address who ) constant returns (uint value);
    function transfer( address to, uint value) returns (bool ok);
    function unlock() returns (bool ok);
}