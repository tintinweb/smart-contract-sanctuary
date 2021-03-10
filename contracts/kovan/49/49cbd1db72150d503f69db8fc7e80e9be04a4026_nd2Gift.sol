/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// File: contracts/assets/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/assets/EnumerableSet.sol
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 */
library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/assets/Address.sol
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/assets/Context.sol
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/assets/AccessControl.sol
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function  hasRole(bytes32 role, address account) internal view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function minterRoleCount() public view returns (uint256) {
        return _roles[MINTER_ROLE].members.length();
    }
    function getMinters(uint256 index) public view returns (address) {
        if(index < minterRoleCount()){
            return _roles[MINTER_ROLE].members.at(index);
        }
        return address(0x00);
    }

    function grantMinterRole(address account) public virtual {
        require(hasRole(_roles[MINTER_ROLE].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public virtual {
        require(hasRole(_roles[MINTER_ROLE].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(MINTER_ROLE, account);
    }

    function renounceMinterRole() public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ND2-BEP20: must have minter role to renounce");
        
        _revokeRole(MINTER_ROLE, _msgSender());
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: references/nd6Reward/nd6Reward-improve-04.sol

interface Ind2Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
* @notice contribution handler
*/
contract nd2Gift is AccessControl {
    
    AggregatorV3Interface internal priceFeed;

    using SafeMath for uint256;
    //This funding have these possible states
    enum State {
        GIVING,
        Successful
    }
    //Public variables

    //Time-state Related
    State public state = State.GIVING;      //Set initial stage
    uint256 public nd2GivingStart = block.timestamp;    //Start now
    uint256 public nd2GivingDeadline = nd2GivingStart.add(180 days); //Human time (GMT):
    uint256 public completedAt;             //Set when funding finish
    //Token-eth related
    uint256 public totalRaised;             //eth collected in wei
    uint256 public totalContractSupply;        //Whole tokens distributed by this contract != totalSupply
    Ind2Token public nd2Token;       //Token contract address

    //Contract details
    address private creator;                 //Creator address
    address payable public nd2holder;       //Holder address
    //string public version = '0.1';          //Contract version

    //Price related
    //uint256 public nd2RateInWei;           // 0.01 cent (0.0001$) in wei

    //events for log
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _addr, uint256 _amount);
    event LogBeneficiaryPaid(address indexed _beneficiaryAddress);
    event LogWithdrawToHolder(address indexed _holderAddress, uint256 _amount);
    event LogDonatorsReward(address indexed _addr, uint256 _amount);
    event LogFundingSuccessful(uint256 _totalRaised);

    //Modifier to prevent execution if reward has ended or is holded
    modifier notFinished() {
        require(state != State.Successful, "Funding has ended and now is closed");
        _;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Sender must be an admin");
        _;
    }

    /**
    * @notice constructor
    */
    constructor() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        /**
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         */
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

        creator = _msgSender();                     //Creator is set from deployer address
        nd2holder = payable(creator);               //nd2holder is set to creator address
        nd2Token = Ind2Token(0x63a520951015d3418f861B79A875Ef8012143476);  //Token address is set during deployment
        emit LogFundrisingInitialized(creator);     //Log contract initialization

    }

    /**
    * @notice contribution handler
    */
    function contribute(address _target, uint256 _value) internal notFinished {
        require(block.timestamp >= nd2GivingStart); //Current time must be equal or greater than the start time
        address user = _target;
        uint256 remaining = _value;
        uint256 tokenDelivered;
        uint256 temp;
        uint80  round;
        //}

        //totalRaised = totalRaised.add(remaining.div(1e18));     //ether received updated

        //while(remaining > 0){

        (temp,remaining,round) = tokenGetCalc(remaining);
        tokenDelivered = tokenDelivered.add(temp);

       // }

        temp = 0;

        //totalContractSupply = totalContractSupply.add(tokenDelivered); //Whole tokens delivered updated
        
        nd2Token.mint(user, tokenDelivered);                    //Call token contract to mine 

        //emit LogFundingReceived(user, msg.value, totalRaised); //Log the donation
        emit LogFundingReceived(user, remaining);               //Log the donation

        checkIfFundingCompleteOrExpired();                      //Execute state checks
    }


    /*
    * This function handle the token rewards amounts
    */
    function tokenGetCalc(uint256 _value)
        internal
        view
        returns
        (
            uint256 give,
            uint256 price,
            uint80 roundID
        )
    {

        /** USD price from chainlink oracle https://chain.link/
         * @param startedAt, timeStamp & answeredInRound are not used here.
         */
         (
            uint80 _roundID, 
            int _price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint256 curSupply = nd2Token.totalSupply();
        uint256 priceUSD = uint(_price);                            //USD price from chainlink oracle https://chain.link/
        uint256 rewardByUSD = 10000000 - 2 * curSupply / 5e18;      //See convert rate at https://www.desmos.com/calculator/hfh2claisu
        give = _value * priceUSD * rewardByUSD / 1e14;              //div 1e2 to format priceUSD

        return (give, uint256(_price), _roundID);

    }

    /**
    * @notice function for move existents ether to nd2holder
    */    
    function withdrawToHolder () public isAdmin {
        require (address(this).balance > 0, "There are not balance to withdraw");
        uint256 withdrawAmount = address(this).balance;
        nd2holder.transfer(withdrawAmount);                                      //eth is send to nd2holder
        emit LogWithdrawToHolder(nd2holder, withdrawAmount);                            //Log transaction
    }
    

    /**
    * @notice Process to check contract current status
    */
    function checkIfFundingCompleteOrExpired() internal {

        if ( block.timestamp > nd2GivingDeadline && state != State.Successful){ //If Deadline is reached and not yet successful

            state = State.Successful; //Funding becomes Successful
            completedAt = block.timestamp; //Funding is complete

            emit LogFundingSuccessful(totalRaised); //we log the finish
            successful(); //and execute closure

        }

    }

    /**
    * @notice successful closure handler
    */
    function successful() public {
        require(state == State.Successful); //When successful
        uint256 temp = nd2Token.balanceOf(address(this)); //Remanent tokens handle
        nd2Token.transfer(creator,temp); //Try to transfer

        emit LogDonatorsReward(creator,temp); //Log transaction

        nd2holder.transfer(address(this).balance); //After successful eth is send to nd2holder

        emit LogBeneficiaryPaid(nd2holder); //Log transaction

    }

    /**
     * @notice Function to set a new hoder for withdraws
     * @param _holder Address of holder
    */
    function setHolder(address _holder) public isAdmin {

      nd2holder = payable(_holder);

    }

    /**
    * @notice Function to claim any token stuck on contract
    * @param _address Address of target token
    */
    function externalTokensRecovery(Ind2Token _address) public isAdmin {
        require(state == State.Successful); //Only when sale finish

        uint256 remainder = _address.balanceOf(address(this)); //Check remainder tokens
        _address.transfer(_msgSender(),remainder); //Transfer tokens to admin

    }


    /*
    * @dev Direct payments handler
    */
    receive () external payable {

        contribute(_msgSender(), msg.value);        //Forward to contribute function

    }
}