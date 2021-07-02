/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// Sources flattened with hardhat v2.3.3 https://hardhat.org

// File contracts/interfaces/ITemplate.sol

pragma solidity ^0.6.0;

interface ITemplate {

    function withdrawFees(address) external returns(uint256);

    function setPaused(bool) external;

    function transferFrom(address, address, uint256)external returns(bool);

    function transfer(address, uint256)external returns(bool);

    function changeMetadata(string calldata)external;

    function applyCover(
        uint256,
        uint256,
        uint256,
        uint256,
        bytes32[] calldata
    ) external;
}


// File contracts/interfaces/IDistributor.sol

pragma solidity ^0.6.0;

interface IDistributor {
    function distribute(address _coin) external returns(bool);

}


// File contracts/interfaces/IRegistry.sol

pragma solidity ^0.6.0;

interface IRegistry {
    function commit_transfer_ownership(address)external;

    function apply_transfer_ownership()external;

    function supportMarket(address _market) external;

    function setCDS(address _address, address _target) external; 

    function isListed(address _market) external view returns (bool);

    function getVault(address _token) external view returns(address);
}


// File contracts/interfaces/IParameters.sol

pragma solidity ^0.6.0;

interface IParameters {
    function commit_transfer_ownership(address)external;

    function apply_transfer_ownership()external;

    function setLockup(address, uint256)external;

    function setGrace(address, uint256)external;

    function setMindate(address, uint256)external;

    function setPremium2(address, uint256)external;

    function setFee2(address, uint256)external;

    function setPremiumModel(address, address)external;

    function setFeeModel(address, address)external;

    function setVault(address, address)external;

    function setWithdrawable(address, uint256)external;

    function setCondition(bytes32 _reference, bytes32 _target)external;
}


// File contracts/interfaces/IVault.sol

pragma solidity ^0.6.0;

interface IVault {
    function commit_transfer_ownership(address)external;

    function apply_transfer_ownership()external;

    function setController(address)external;

    function setMin(uint256)external;

    function withdrawAllAttribution(address _to)external returns(uint256);
}


// File contracts/interfaces/IUniversalMarket.sol

pragma solidity ^0.6.0;

interface IUniversalMarket {
    function initialize(
        address _owner,
        string calldata _metaData,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external returns (bool);
}


// File contracts/interfaces/IFactory.sol

pragma solidity ^0.6.0;


interface IFactory {
    function commit_transfer_ownership(address)external;

    function apply_transfer_ownership()external;

    function approveReference(IUniversalMarket, uint256, address, bool)external;
    
    function approveTemplate(IUniversalMarket, bool, bool)external;

    function setCondition(IUniversalMarket _template, uint256 _slot, uint256 _target) external;
}


// File contracts/libraries/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/***
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /***
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /***
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /***
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /***
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /***
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /***
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /***
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /***
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libraries/math/Math.sol

pragma solidity ^0.6.0;

/***
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /***
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /***
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /***
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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


// File contracts/libraries/math/SignedSafeMath.sol

pragma solidity ^0.6.0;

/***
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    //int256 constant private _INT256_MIN = -2**255;

    int128 constant private _INT256_MIN = -2**127;

    /***
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int128 a, int128 b) internal pure returns (int128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int128 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /***
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int128 a, int128 b) internal pure returns (int128) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int128 c = a / b;

        return c;
    }

    /***
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /***
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}


// File contracts/libraries/utils/ReentrancyGuard.sol

pragma solidity >=0.6.0 <0.8.0;

/***
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make Insure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /***
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File contracts/PoolProxy.sol

pragma solidity 0.6.12;

/***
*@title PoolProxy
*@author InsureDAO
*SPDX-License-Identifier: MIT
*@notice Ownership proxy for Insurance Pools
*/
//This contracts hold many tokens to be distributed.











//Proxy and fee management for single asset
contract PoolProxy is ReentrancyGuard{
    using SafeMath for uint256;

    event CommitAdmins(address ownership_admin, address parameter_admin, address emergency_admin);
    event ApplyAdmins(address ownership_admin, address parameter_admin, address emergency_admin); 
    event CommitReportingAdmins(address pool_address, address reporting_admin);
    event ApplyReportingAdmins(address pool_address, address reporting_admin);
    event AddDistributor(address distributor);


    address public ownership_admin;
    address public parameter_admin;
    address public emergency_admin;
    mapping(address => address)public reporting_admin;

    address registry;

    address public future_ownership_admin;
    address public future_parameter_admin;
    address public future_emergency_admin;
    mapping(address => address)public future_reporting_admin;

    struct Distributor{
        string name;
        address addr;
    }

    /***
    DAI
    id 1 = dev
    id 2 = buy back and burn
    id 3 = reporting member
    */

    mapping(address => mapping(uint256 => Distributor))public distributors; // token distibutor contracts. token => ID => Distributor / (ex. DAI => 2 => FeeDistributorV1)
    mapping(address => uint256) public n_distributors; //distributors# of token
    mapping(address => mapping(uint256 => uint256))public distributor_weight; // token => ID => weight
    mapping(address => mapping(uint256 => uint256))public distributable; //distributor => allocated amount
    mapping(address => uint256)public total_weights; //token => total allocation point

    bool public distributor_kill;

    constructor(
        address _ownership_admin,
        address _parameter_admin,
        address _emergency_admin
    )public{
        ownership_admin = _ownership_admin;
        parameter_admin = _parameter_admin;
        emergency_admin = _emergency_admin;
    }

    //-------- distributor ---------//
    function add_distributor(address _token, string memory _name, address _addr)external returns(bool){
        /***
        *@notice add new distributor
        */
        require(msg.sender == ownership_admin, "only ownership admin");
        require(_token != address(0), "_token cannot be zero address");


        Distributor memory new_distributor = Distributor({name: _name, addr: _addr});
        uint256 id = n_distributors[_token];
        distributors[_token][id] = new_distributor;
        n_distributors[_token] = n_distributors[_token].add(1);
        //distributor weight is 0 at this point.
    }

    function _set_distributor(address _token, uint256 _id, Distributor memory _distributor)internal {
        /***
        *@notice overwrites new distributor to distributor already existed;
        *@dev new distributor takes over the old distributor's weight and distributable state;
        */
        require(_id < n_distributors[_token], "not added yet");

        //if Distributor set to ZERO_ADDRESS, set the weight to 0.
        if(_distributor.addr == address(0)){
            _set_distributor_weight(_token, _id, 0);
        }

        distributors[_token][_id] = _distributor;
    }

    function set_distributor(address _token, uint256 _id, string memory _name, address _distributor)external {
        /***
        *@notice Set burner of `_coin` to `_burner` address
        *@param _token Token address
        *@param _id Distribution ID
        *@param _name Distributor name
        *@param _distributor Distributor contract address
        */
        require(msg.sender == ownership_admin, "only ownership admin");

        Distributor memory new_distributor = Distributor(_name, _distributor);

        _set_distributor(_token, _id, new_distributor);
    }

    function _set_distributor_weight(address _token, uint256 _id, uint256 _weight)internal{
        require(_id < n_distributors[_token], "not added yet");
        require(distributors[_token][_id].addr != address(0), "distributor not set");
        
        uint256 new_weight = _weight;
        uint256 old_weight = distributor_weight[_token][_id];

        //update distibutor weight and total_weight
        distributor_weight[_token][_id] = new_weight;
        total_weights[_token] = total_weights[_token].add(new_weight).sub(old_weight);
    }

    function set_distributor_weight(address _token, uint256 _id, uint256 _weight)external returns(bool){
        require(msg.sender == parameter_admin, "only parameter admin");

        _set_distributor_weight(_token, _id, _weight);

        return true;
    }

    function set_distributor_weight_many(address[20] memory _tokens, uint256[20] memory _ids, uint256[20] memory _weights)external{
        require(msg.sender == parameter_admin, "only parameter admin");

        for(uint256 i=0; i<20; i++){
            if(_tokens[i] == address(0)){
                break;
            }
            _set_distributor_weight(_tokens[i], _ids[i], _weights[i]);
        }
    }

    function get_distributor_name(address _token, uint256 _id)external view returns(string memory){
        return distributors[_token][_id].name;
    }

    function get_distributor_address(address _token, uint256 _id)external view returns(address){
        return distributors[_token][_id].addr;
    }

    //------------- distribution ----------------//
    function withdraw_admin_fee(address _token) external nonReentrant{//any accounts
        /***
        *@notice Withdraw admin fees from `_vault`
        *@param _vault Vault address to withdraw admin fees from
        */
        //Do we really need nonReentrant for this?
        require(_token != address(0), "_token cannot be zero address");

        address _vault = IRegistry(registry).getVault(_token); //dev: revert when registry not set
        uint256 amount = IVault(_vault).withdrawAllAttribution(address(this));

        if(amount != 0){
            //allocate the fee to corresponding distributors
            for(uint256 id=0; id<n_distributors[_token]; id++){
                uint256 aloc_point = distributor_weight[_token][id];

                uint256 aloc_amount = amount.mul(aloc_point).div(total_weights[_token]); //round towards zero.
                distributable[_token][id] = distributable[_token][id].add(aloc_amount); //count up allocated fee
            }
        }
    }

    /***
    *@notice Re_allocate _token in this contract with the latest allocation. For token left after rounding down
    */
    /**
    function re_allocate(address _token)external{
        require(msg.sender == parameter_admin, "only parameter admin");

        uint256 amount = IERC20(_token).balanceOf(address(this));

        //allocate the fee to corresponding distributors
        for(uint256 id=0; id<n_distributors[_token]; id++){
            uint256 aloc_point = distributor_weight[_token][id];

            uint256 aloc_amount = amount.mul(aloc_point).div(total_weights[_token]); //round towards zero.
            distributable[_token][id] = aloc_amount;
        }
    }
    */

    function _distribute(address _token, uint256 _id)internal{
        require(_id < n_distributors[_token], "not added yet");

        address _addr = distributors[_token][_id].addr;
        uint256 amount = distributable[_token][_id];
        distributable[_token][_id] = 0;
        IERC20(_token).approve(_addr, amount);
        require(IDistributor(_addr).distribute(_token), "dev: should implement distribute()");
    }
    
    function distribute(address _token, uint256 _id)external nonReentrant{//any EOA
        /***
        *@notice distribute accrued `_token` via a preset distributor
        *@dev Only callable by an EOA to prevent
        *@param _id distributor id
        */
        assert(tx.origin == msg.sender);
        require(!distributor_kill, "distribution killed");

        _distribute(_token, _id);
    }

    function distribute_many(address[20] memory _tokens, uint256[20] memory _ids)external nonReentrant{//any EOA
        /***
        *@notice distribute accrued admin fees from multiple coins
        *@dev Only callable by an EOA to prevent flashloan exploits
        *@param _id List of distributor id
        */
        assert(tx.origin == msg.sender);
        require(!distributor_kill, "distribution killed");

        for(uint i=0; i < 20; i++){
            if(_tokens[i] == address(0)){
                break;
            }
            _distribute(_tokens[i], _ids[i]);
        }
    }

    function set_distributor_kill(bool _is_killed)external{
        /***
        @notice Kill or unkill `distribute` functionality
        @param _is_killed Distributor kill status
        */
        require(msg.sender == emergency_admin || msg.sender == ownership_admin, "Access denied");
        distributor_kill = _is_killed;
    }


    //-------- configuration ---------//
    // admins
    function commit_set_admins(address _o_admin, address _p_admin, address _e_admin)external{
        /***
        *@notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
        *@param _o_admin Ownership admin
        *@param _p_admin Parameter admin
        *@param _e_admin Emergency admin
        */
        require(msg.sender == ownership_admin, "Access denied");

        future_ownership_admin = _o_admin;
        future_parameter_admin = _p_admin;
        future_emergency_admin = _e_admin;

        emit CommitAdmins(_o_admin, _p_admin, _e_admin);
    }
    function apply_set_admins()external{
        /***
        *@notice Apply the effects of `commit_set_admins`
        */
        require( msg.sender == ownership_admin, "Access denied");

        address _o_admin = future_ownership_admin;
        address _p_admin = future_parameter_admin;
        address _e_admin = future_emergency_admin;

        ownership_admin = _o_admin;
        parameter_admin = _p_admin;
        emergency_admin = _e_admin;

        emit ApplyAdmins(_o_admin, _p_admin, _e_admin);
    }

    // reporting admins
    function commit_set_reporting_admin(address _pool, address _r_admin)external{
        /***
        *@notice Set reporting admin to `_r_admin`
        *@param _pool Target address
        *@param _r_admin Reporting admin
        */
        require(msg.sender == ownership_admin, "Access denied");

        future_reporting_admin[_pool] = _r_admin;

        emit CommitReportingAdmins(_pool, _r_admin);
    }

    function apply_set_reporting_admin(address _pool)external{
        /***
        *@notice Apply the effects of `commit_set_reporting_admin`
        */
        require(msg.sender == ownership_admin, "Access denied");
        require(future_reporting_admin[_pool] != address(0), "future admin not set");
        address _r_admin = future_reporting_admin[_pool];

        reporting_admin[_pool] = _r_admin;

        emit ApplyReportingAdmins(_pool, _r_admin);
    }



    //--------------Vault-----------------//
    function commit_transfer_ownership_vault(address _vault, address _future_owner)external{
        /***
        *@param _vault address of Vault contract of the Vault
        *@param _future_owner address of the future owner
        */
        require(msg.sender == ownership_admin, "Access denied");
        IVault(_vault).commit_transfer_ownership(_future_owner);

    }

    function apply_transfer_ownership_vault(address _vault)external{
        /***
        *@notice 
        *@param _vault Vault address
        */
        
        IVault(_vault).apply_transfer_ownership();
    }

    function set_controller(address _vault, address _controller)external{
        /***
        *@param _vault Vault address
        *@param _controller new controller address
        */
        require(msg.sender == parameter_admin, "Access denied");

        IVault(_vault).setController(_controller);
    }

    function set_min(address _vault, uint256 _min)external {
        /***
        *@notice how much can the vault can lend out to controller
        *@param _vault Vault address
        *@param _min minimum
        */
        require(msg.sender == parameter_admin, "Access denied");

        IVault(_vault).setMin(_min);
    }


    //--------------Parameters-----------------//
    function commit_transfer_ownership_parameters(address _parameters, address _future_owner)external{
        /***
        *@param _parameters Parameters address
        *@param _future_owner address of the future owner
        */
        require(msg.sender == ownership_admin, "Access denied");
        IParameters(_parameters).commit_transfer_ownership(_future_owner);
    }

    function apply_transfer_ownership_parameters(address _parameters)external{
        /***
        *@param _parameters Parameters address
        */
        IParameters(_parameters).apply_transfer_ownership();
    }

    function set_vault(address _parameters, address _token, address _vault)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setVault(_token, _vault);
    }

    function set_lockup(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setLockup(_address, _target);
    }

    function set_grace(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setGrace(_address, _target);
    }

    function set_mindate(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setMindate(_address, _target);
    }

    function set_premium2(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setPremium2(_address, _target);
    }

    function set_fee2(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setFee2(_address, _target);
    }

    function set_withdrawable(address _parameters, address _address, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setWithdrawable(_address, _target);
    }

    function set_premium_model(address _parameters, address _address, address _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setPremiumModel(_address, _target);
    }

    function set_fee_model(address _parameters, address _address, address _target)external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setFeeModel(_address, _target);
    }

    function set_condition_parameters(address _parameters, bytes32 _reference, bytes32 _target) external{
        require(msg.sender == parameter_admin, "Access denied");

        IParameters(_parameters).setCondition(_reference, _target);
    }


    //--------------Registry-----------------//
    function set_registry(address _registry)external {
        require(msg.sender == ownership_admin, "Access denied");
        registry = _registry;
    }

    function commit_transfer_ownership_registry(address _registry, address _future_admin)external{
        require(msg.sender == ownership_admin, "Access denied");
        IRegistry(_registry).commit_transfer_ownership(_future_admin);
    }

    function apply_transfer_ownership_registry(address _registry)external{
        /***
        *@param _registry Registry address
        */
        IRegistry(_registry).apply_transfer_ownership();
    }

    function support_market(address _registry, address _market) external{
        require(msg.sender == parameter_admin, "Access denied");
        IRegistry(_registry).supportMarket(_market);
    }

    function set_cds(address _registry, address _address, address _target) external{
        require(msg.sender == parameter_admin, "Access denied");
        IRegistry(_registry).setCDS(_address, _target);
    }


    //--------------Factory-----------------//
    function commit_transfer_ownership_factory(address _factory, address _future_admin)external{
        require(msg.sender == ownership_admin, "Access denied");
        IFactory(_factory).commit_transfer_ownership(_future_admin);
    }

    function apply_transfer_ownership_factory(address _factory)external{
        /***
        *@param _factory Factory address
        */
        IFactory(_factory).apply_transfer_ownership();
    }

    function approve_reference(address _factory, address _template_addr, uint256 _slot, address _target, bool _approval)external{
        require(msg.sender == parameter_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveReference(_template, _slot, _target, _approval);
    }

    function approve_template(address _factory, address _template_addr, bool _approval, bool _isOpen)external{
        require(msg.sender == parameter_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).approveTemplate(_template, _approval, _isOpen);
    }

    function set_condition_factory(address _factory, address _template_addr, uint256 _slot, uint256 _target)external{
        require(msg.sender == parameter_admin, "Access denied");
        IUniversalMarket _template = IUniversalMarket(_template_addr);

        IFactory(_factory).setCondition(_template, _slot, _target);
    }


    //--------------Pool-----------------//
    function set_paused(address _pool, bool _state)external nonReentrant{
        /***
        *@notice 
        *@param _pool Pool address to pause
        */
        require(msg.sender == emergency_admin || msg.sender == ownership_admin, "Access denied");
        ITemplate(_pool).setPaused(_state);
    }

    function change_metadata(address _pool, string calldata _metadata) external {
        require(msg.sender == parameter_admin, "Access denied");
        ITemplate(_pool).changeMetadata(_metadata);
    }

    function apply_cover(
        address _pool,
        uint256 _pending,
        uint256 _payoutNumerator,
        uint256 _payoutDenominator,
        uint256 _incidentTimestamp,
        bytes32[] calldata _targets
    ) external{
        require(msg.sender == reporting_admin[_pool], "Access denied");

        ITemplate(_pool).applyCover(_pending, _payoutNumerator, _payoutDenominator, _incidentTimestamp, _targets);
    }

    fallback()external payable{
        // required to receive ETH fees
    }

}