/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/dao/IInsureToken.sol

pragma solidity 0.6.12;

interface IInsureToken {
    function mint(address _to, uint256 _value)external returns(bool);
    function emergency_mint(uint256 _amountOut, address _to)external;
    function approve(address _spender, uint256 _value)external;
}


// File contracts/interfaces/dao/IVotingEscrow.sol

pragma solidity 0.6.12;

interface IVotingEscrow {
    function get_last_user_slope(address addr)external view returns(uint256);
    function locked__end(address _addr)external view returns (uint256);
}


// File contracts/libraries/math/SafeMath.sol

pragma solidity ^0.6.0;

/***
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /***
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /***
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /***
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /***
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /***
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /***
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /***
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /***
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/GaugeController.sol

pragma solidity 0.6.12;
/***
*@title Gauge Controller
*@author InsureDAO
*SPDX-License-Identifier: MIT
*@notice Controls liquidity gauges and the issuance of INSURE token through the gauges
*/



contract GaugeController{
    using SafeMath for uint256;

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 constant WEEK = 604800;

    // Cannot change weight votes more often than once in 10 days.
    uint256 constant WEIGHT_VOTE_DELAY = 10 * 86400;

    struct Point{
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope{
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event AddType(string name, uint256 type_id);
    event NewTypeWeight(uint256 type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGaugeWeight(address gauge_address, uint256 time, uint256 weight, uint256 total_weight);
    event VoteForGauge(uint256 time, address user, address gauge_addr, uint256 weight);
    event NewGauge(address addr, uint256 gauge_type, uint256 weight);

    uint256 constant MULTIPLIER = 10 ** 18;

    address public admin;  // Can and will be a smart contract (Ownership admin)
    address public future_admin;  // Can and will be a smart contract

    IInsureToken public token;
    IVotingEscrow public voting_escrow;

    // Gauge parameters
    // All numbers are "fixed point" on the basis of 1e18
    uint256 public n_gauge_types = 1; // There is [gauge_type(0) : unset] as default. [gauge_type(1) : LiquidityGauge] will be added as the contract is deployed, and "n_gauge_types" will be incremented to 2. This part is modified from Curve's contract.
    uint256 public n_gauges; //number of gauges
    mapping (uint256 => string) public gauge_type_names;

    // Needed for enumeration
    address[1000000000] public gauges;

    // "0" means that a gauge has not been set
    mapping (address => uint256) gauge_types_;
    mapping (address => mapping(address => VotedSlope))public vote_user_slopes; // user -> gauge_addr -> VotedSlope
    mapping (address => uint256)public vote_user_power; // Total vote power used by user
    mapping (address => mapping(address => uint256)) public last_user_vote; // Last user vote's timestamp for each gauge address



    // Past and scheduled points for gauge weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    mapping (address => mapping(uint256 => Point)) public points_weight; // gauge_addr -> time -> Point
    mapping (address => mapping(uint256 => uint256)) public changes_weight; // gauge_addr -> time -> slope
    mapping (address => uint256) public time_weight;  // gauge_addr -> last scheduled time (next week)

    mapping (uint256 => mapping(uint256 => Point)) public points_sum; // type_id -> time -> Point
    mapping (uint256 => mapping(uint256 => uint256)) public changes_sum; // type_id -> time -> slope
    uint256[1000000000] public time_sum;  // type_id -> last scheduled time (next week)

    mapping (uint256 => uint256) public points_total; // time -> total weight
    uint256 public time_total;  // last scheduled time

    mapping (uint256 => mapping(uint256 => uint256)) public points_type_weight;  // type_id -> time -> type weight
    uint256[1000000000] public time_type_weight; // type_id -> last scheduled time (next week)

    constructor(address _token, address _voting_escrow)public {
        /***
        *@notice Contract constructor
        *@param _token `InsureToken` contract address
        *@param _voting_escrow `VotingEscrow` contract address
        */
        assert (_token != address(0));
        assert (_voting_escrow != address(0));

        admin = msg.sender;
        token = IInsureToken(_token);
        voting_escrow = IVotingEscrow(_voting_escrow);
        time_total = block.timestamp.div(WEEK).mul(WEEK);
    }

    function get_voting_escrow()external view returns(address){
        return address(voting_escrow);
    }

    function commit_transfer_ownership(address addr)external {
        /***
        *@notice Transfer ownership of GaugeController to `addr`
        *@param addr Address to have ownership transferred to
        */
        require (msg.sender == admin, "dev: admin only");
        future_admin = addr;
        emit CommitOwnership(addr);
    }

    function apply_transfer_ownership()external{
        /***
        * @notice Apply pending ownership transfer
        */
        require (msg.sender == admin, "dev: admin only");
        address _admin = future_admin;
        require (_admin != address(0), "dev: admin not set");
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    function gauge_types(address _addr)external view returns(uint256){
        /***
        *@notice Get gauge type for address
        *@param _addr Gauge address
        *@return Gauge type id
        */
        uint256 gauge_type = gauge_types_[_addr];
        //assert (gauge_type != 0);

        return gauge_type; //LG = 1
    }

    function _get_type_weight(uint256 gauge_type)internal returns(uint256){
        /***
        *@notice Fill historic type weights week-over-week for missed checkins
        *        and return the type weight for the future week
        *@param gauge_type Gauge type id
        *@return Type weight of next week
        */
        require(gauge_type != 0, "unset");//s
        uint256 t = time_type_weight[gauge_type];
        if(t > 0){
            uint256 w = points_type_weight[gauge_type][t];
            for(uint256 i; i < 500; i++){
                if(t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                points_type_weight[gauge_type][t] = w;
                if(t > block.timestamp){
                    time_type_weight[gauge_type] = t;
                }
            }
            return w;
        }else{
            return 0;
        }
    }

    function _get_sum(uint256 gauge_type)internal returns(uint256){
        /***
        *@notice Fill sum of gauge weights for the same type week-over-week for
        *        missed checkins and return the sum for the future week
        *@param gauge_type Gauge type id
        *@return Sum of weights
        */
        require(gauge_type != 0, "unset");
        uint256 t = time_sum[gauge_type];
        if (t > 0){
            Point memory pt = points_sum[gauge_type][t];
            for(uint256 i; i<500; i++){
                if (t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                uint256 d_bias = pt.slope.mul(WEEK);
                if (pt.bias > d_bias){
                    pt.bias = pt.bias.sub(d_bias);
                    uint256 d_slope = changes_sum[gauge_type][t];
                    pt.slope = pt.slope.sub(d_slope);
                }else{
                    pt.bias = 0;
                    pt.slope = 0;
                }
                points_sum[gauge_type][t] = pt;
                if (t > block.timestamp){
                    time_sum[gauge_type] = t;
                }
            }
            return pt.bias;
        }else{
            return 0;
        }
    }

    function _get_total()internal returns(uint256){
        /***
        *@notice Fill historic total weights week-over-week for missed checkins
        *        and return the total for the future week
        *@return Total weight
        */
        uint256 t = time_total;
        uint256 _n_gauge_types = n_gauge_types;
        if (t > block.timestamp){
            // If we have already checkpointed - still need to change the value
            t = t.sub(WEEK);
        }
        uint256 pt = points_total[t];

        for (uint256 gauge_type = 1; gauge_type < 100; gauge_type++){
            if(gauge_type == _n_gauge_types){
                break;
            }
            _get_sum(gauge_type);
            _get_type_weight(gauge_type);
        }
        for (uint i; i<500; i++){
            if(t > block.timestamp){
                break;
            }
            t = t.add(WEEK);
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for(uint gauge_type = 1; gauge_type < 100; gauge_type++){
                if ( gauge_type == _n_gauge_types){
                    break;
                }
                uint256 type_sum = points_sum[gauge_type][t].bias;
                uint256 type_weight = points_type_weight[gauge_type][t];
                pt = pt.add(type_sum.mul(type_weight));
            }
            points_total[t] = pt;

            if(t > block.timestamp){
                time_total = t;
            }
        }
        return pt;
    }

    function _get_weight(address gauge_addr)internal returns(uint256){
        /***
        *@notice Fill historic gauge weights week-over-week for missed checkins
        *        and return the total for the future week
        *@param gauge_addr Address of the gauge
        *@return Gauge weight
        */
        uint256 t = time_weight[gauge_addr];
        if (t > 0){
            Point memory pt = points_weight[gauge_addr][t];
            for(uint256 i; i<500; i++){
                if (t > block.timestamp){
                    break;
                }
                t = t.add(WEEK);
                uint256 d_bias = pt.slope.mul(WEEK);
                if (pt.bias > d_bias){
                    pt.bias = pt.bias.sub(d_bias);
                    uint256 d_slope = changes_weight[gauge_addr][t];
                    pt.slope = pt.slope.sub(d_slope);
                }else{
                    pt.bias = 0;
                    pt.slope = 0;
                }
                points_weight[gauge_addr][t] = pt;
                if (t > block.timestamp){
                    time_weight[gauge_addr] = t;
                }
            }
            return pt.bias;
        }else{
            return 0;
        }
    }

    function add_gauge(address addr, uint256 gauge_type, uint256 weight)external{
        /***
        *@notice Add gauge `addr` of type `gauge_type` with weight `weight`
        *@param addr Gauge address
        *@param gauge_type Gauge type
        *@param weight Gauge weight
        */
        assert (msg.sender == admin);
        assert ((gauge_type >= 1) && (gauge_type < n_gauge_types)); //gauge_type 0 means unset
        require (gauge_types_[addr] == 0, "dev: cannot add the same gauge twice");//before adding, addr must be 0 in the mapping.
        uint256 n = n_gauges;
        n_gauges = n.add(1);
        gauges[n] = addr;

        gauge_types_[addr] = gauge_type;
        uint256 next_time = (block.timestamp.add(WEEK)).div(WEEK).mul(WEEK);

        if (weight > 0){
            uint256 _type_weight = _get_type_weight(gauge_type);
            uint256 _old_sum = _get_sum(gauge_type);
            uint256 _old_total = _get_total();

            points_sum[gauge_type][next_time].bias = weight.add(_old_sum);
            time_sum[gauge_type] = next_time;
            points_total[next_time] = _old_total.add(_type_weight.mul(weight));
            time_total = next_time;

            points_weight[addr][next_time].bias = weight;
        }
        if (time_sum[gauge_type] == 0){
            time_sum[gauge_type] = next_time;
        }
        time_weight[addr] = next_time;

        emit NewGauge(addr, gauge_type, weight);
    }

    function checkpoint()external{
        /***
        * @notice Checkpoint to fill data common for all gauges
        */
        _get_total();
    }

    function checkpoint_gauge(address addr)external{
        /***
        *@notice Checkpoint to fill data for both a specific gauge and common for all gauges
        *@param addr Gauge address
        */
        _get_weight(addr);
        _get_total();
    }

    function _gauge_relative_weight(address addr, uint256 time)internal view returns(uint256){
        /***
        *@notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
        *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
        *       inflation_rate * relative_weight / 1e18
        *@param addr Gauge address
        *@param time Relative weight at the specified timestamp in the past or present
        *@return Value of relative weight normalized to 1e18
        */
        uint256 t = time.div(WEEK).mul(WEEK);
        uint256 _total_weight = points_total[t];

        if(_total_weight > 0){
            uint256 gauge_type = gauge_types_[addr];
            uint256 _type_weight = points_type_weight[gauge_type][t];
            uint256 _gauge_weight = points_weight[addr][t].bias;

            return MULTIPLIER.mul(_type_weight).mul(_gauge_weight).div(_total_weight);
        }else{
            return 0;
        }
    }

    function gauge_relative_weight(address addr, uint256 time)external view returns(uint256){
        /***
        *@notice Get Gauge relative weight (not more than 1.0) normalized to 1e18
        *        (e.g. 1.0 == 1e18). Inflation which will be received by it is
        *        inflation_rate * relative_weight / 1e18
        *@param addr Gauge address
        *@param time Relative weight at the specified timestamp in the past or present
        *@return Value of relative weight normalized to 1e18
        */

        //default value
        if(time == 0){
            time = block.timestamp;
        }

        return _gauge_relative_weight(addr, time);
    }

    function gauge_relative_weight_write(address addr, uint256 time)external returns(uint256){

        //default value
        if(time == 0){
            time = block.timestamp;
        }
        
        _get_weight(addr);
        _get_total();  // Also calculates get_sum
        return _gauge_relative_weight(addr, time);
    }

    function _change_type_weight(uint256 type_id, uint256 weight)internal{
        /***
        *@notice Change type weight
        *@param type_id Type id
        *@param weight New type weight
        */
        
        uint256 old_weight = _get_type_weight(type_id);
        uint256 old_sum = _get_sum(type_id);
        uint256 _total_weight = _get_total();
        uint256 next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);

        _total_weight = _total_weight.add(old_sum.mul(weight)).sub(old_sum.mul(old_weight));
        points_total[next_time] = _total_weight;
        points_type_weight[type_id][next_time] = weight;
        time_total = next_time;
        time_type_weight[type_id] = next_time;

        emit NewTypeWeight(type_id, next_time, weight, _total_weight);
    }

    function add_type(string memory _name, uint256 weight)external{
        /***
        *@notice Add gauge type with name `_name` and weight `weight`　//ex. type=1, Liquidity, 1*1e18
        *@param _name Name of gauge type
        *@param weight Weight of gauge type
        */
        assert(msg.sender == admin);
        uint256 type_id = n_gauge_types;
        gauge_type_names[type_id] = _name;
        n_gauge_types = type_id.add(1);
        if(weight != 0){
            _change_type_weight(type_id, weight);
            emit AddType(_name, type_id);
        }
    }

    function change_type_weight(uint256 type_id, uint256 weight)external{
        /***
        *@notice Change gauge type `type_id` weight to `weight`
        *@param type_id Gauge type id
        *@param weight New Gauge weight
        */
        assert (msg.sender == admin);
        _change_type_weight(type_id, weight);
    }

    function _change_gauge_weight(address addr, uint256 weight)internal {
        // Change gauge weight
        // Only needed when testing in reality
        uint256 gauge_type = gauge_types_[addr];
        uint256 old_gauge_weight = _get_weight(addr);
        uint256 type_weight = _get_type_weight(gauge_type);
        uint256 old_sum = _get_sum(gauge_type);
        uint256 _total_weight = _get_total();
        uint256 next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);

        points_weight[addr][next_time].bias = weight;
        time_weight[addr] = next_time;

        uint256 new_sum = old_sum.add(weight).sub(old_gauge_weight);
        points_sum[gauge_type][next_time].bias = new_sum;
        time_sum[gauge_type] = next_time;

        _total_weight = _total_weight.add(new_sum.mul(type_weight)).sub(old_sum.mul(type_weight));
        points_total[next_time] = _total_weight;
        time_total = next_time;

        emit NewGaugeWeight(addr, block.timestamp, weight, _total_weight);
    }

    function change_gauge_weight(address addr, uint256 weight)external{
        /***
        *@notice Change weight of gauge `addr` to `weight`
        *@param addr `GaugeController` contract address
        *@param weight New Gauge weight
        */
        assert (msg.sender == admin);
        _change_gauge_weight(addr, weight);
    }

    struct VotingParameter{ //to avoid "Stack too deep" issue
        uint256 slope;
        uint256 lock_end;
        uint256 _n_gauges;
        uint256 next_time;
        uint256 gauge_type;
        uint256 old_dt;
        uint256 old_bias;
    }

    function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight)external{
        /****
        *@notice Allocate voting power for changing pool weights
        *@param _gauge_addr Gauge which `msg.sender` votes for
        *@param _user_weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0. bps = basis points
        */

        VotingParameter memory vp;
        vp.slope = uint256(voting_escrow.get_last_user_slope(msg.sender));
        vp.lock_end = voting_escrow.locked__end(msg.sender);
        vp._n_gauges = n_gauges;
        vp.next_time = block.timestamp.add(WEEK).div(WEEK).mul(WEEK);
        require (vp.lock_end > vp.next_time, "Your token lock expires too soon");
        require ((_user_weight >= 0) && (_user_weight <= 10000), "You used all your voting power");
        require (block.timestamp >= last_user_vote[msg.sender][_gauge_addr].add(WEIGHT_VOTE_DELAY), "Cannot vote so often");

        vp.gauge_type = gauge_types_[_gauge_addr];
        require (vp.gauge_type >= 1, "Gauge not added");
        // Prepare slopes and biases in memory
        VotedSlope memory old_slope = vote_user_slopes[msg.sender][_gauge_addr];
        vp.old_dt = 0;
        if (old_slope.end > vp.next_time){
            vp.old_dt = old_slope.end.sub(vp.next_time);
        }
        vp.old_bias = old_slope.slope.mul(vp.old_dt);
        VotedSlope memory new_slope = VotedSlope({
            slope: vp.slope.mul(_user_weight).div(10000),
            power: _user_weight,
            end: vp.lock_end
        });
        uint256 new_dt = vp.lock_end.sub(vp.next_time);  // dev: raises when expired
        uint256 new_bias = new_slope.slope.mul(new_dt);

        // Check and update powers (weights) used
        uint256 power_used = vote_user_power[msg.sender];
        power_used = power_used.add(new_slope.power).sub(old_slope.power);
        vote_user_power[msg.sender] = power_used;
        require ( (power_used >= 0) && (power_used <= 10000), 'Used too much power');

        //// Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for next_time
        uint256 old_weight_bias = _get_weight(_gauge_addr);
        uint256 old_weight_slope = points_weight[_gauge_addr][vp.next_time].slope;
        uint256 old_sum_bias = _get_sum(vp.gauge_type);
        uint256 old_sum_slope = points_sum[vp.gauge_type][vp.next_time].slope;

        points_weight[_gauge_addr][vp.next_time].bias = max(old_weight_bias.add(new_bias), vp.old_bias).sub(vp.old_bias);
        points_sum[vp.gauge_type][vp.next_time].bias = max(old_sum_bias.add(new_bias), vp.old_bias).sub(vp.old_bias);
        if (old_slope.end > vp.next_time){
            points_weight[_gauge_addr][vp.next_time].slope = max(old_weight_slope.add(new_slope.slope), old_slope.slope).sub(old_slope.slope);
            points_sum[vp.gauge_type][vp.next_time].slope = max(old_sum_slope.add(new_slope.slope), old_slope.slope).sub(old_slope.slope);
        }else{
            points_weight[_gauge_addr][vp.next_time].slope = points_weight[_gauge_addr][vp.next_time].slope.add(new_slope.slope);
            points_sum[vp.gauge_type][vp.next_time].slope = points_sum[vp.gauge_type][vp.next_time].slope.add(new_slope.slope);
        }
        if (old_slope.end > block.timestamp){
            // Cancel old slope changes if they still didn't happen
            changes_weight[_gauge_addr][old_slope.end] = changes_weight[_gauge_addr][old_slope.end].sub(old_slope.slope);
            changes_sum[vp.gauge_type][old_slope.end] = changes_sum[vp.gauge_type][old_slope.end].sub(old_slope.slope);
        }
        // Add slope changes for new slopes
        changes_weight[_gauge_addr][new_slope.end] = changes_weight[_gauge_addr][new_slope.end].add(new_slope.slope);
        changes_sum[vp.gauge_type][new_slope.end] = changes_sum[vp.gauge_type][new_slope.end].add(new_slope.slope);

        _get_total();

        vote_user_slopes[msg.sender][_gauge_addr] = new_slope;

        // Record last action time
        last_user_vote[msg.sender][_gauge_addr] = block.timestamp;

        emit VoteForGauge(block.timestamp, msg.sender, _gauge_addr, _user_weight);
    }

    function get_gauge_weight(address addr)external view returns (uint256){
        /***
        *@notice Get current gauge weight
        *@param addr Gauge address
        *@return Gauge weight
        */
        return points_weight[addr][time_weight[addr]].bias;
    }

    function get_type_weight(uint256 type_id)external view returns (uint256){
        /***
        *@notice Get current type weight
        *@param type_id Type id
        *@return Type weight
        */
        return points_type_weight[type_id][time_type_weight[type_id]];
    }

    function get_total_weight()external view returns (uint256){
        /***
        *@notice Get current total (type-weighted) weight
        *@return Total weight
        */
        return points_total[time_total];
    }

    function get_weights_sum_per_type(uint256 type_id)external view returns (uint256){
        /***
        *@notice Get sum of gauge weights per type
        *@param type_id Type id
        *@return Sum of gauge weights
        */
        return points_sum[type_id][time_sum[type_id]].bias;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}