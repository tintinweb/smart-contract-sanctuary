/**
 *Submitted for verification at polygonscan.com on 2021-08-04
*/

// pragma solidity ^0.7.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// contract Test{
    
//     // IERC20 USDP;
//     // constructor (address USDP_){
//     //     USDP = IERC20(USDP_);
//     // }
    
//     // uint256 public contractBalance;
    
//     // function deliverToken() public {
//     //     USDP.transfer(msg.sender,100);
//     //     contractBalance = USDP.balanceOf(address(this));
//     // }
    
//     // struct CustomerCommissionerPair{
//     //     address customer;
//     //     address commissioneer;
//     // }
    
//     // mapping(address => mapping(CustomerCommissionerPair,uint8) commissionRate;
    
//     // CustomerCommissionerPair customerCommissionerPair = CustomerCommissionerPair(msg.sender);
//     // commissionRate[address(this)][customerCommisisonPair];
    
//     // contract subscriptionService {
    
//     struct Service{
//         string serviceName;
//         uint256 serviceFee;
//         uint8 isSet;
//     }
    
//     mapping(address => mapping(uint16 => Service)) public serviceSubscriptionInfo;
//     mapping(address => mapping(uint16 => address[])) subscriber; 
    
//     function setSubscriptionServiceInfo (address feeReceiver, uint16 index, uint256 fee, string memory serviceName) external{
//         require(msg.sender == feeReceiver, "Only account owner is allowed to set the service fee");
//         // require(serviceSubscriptionInfo[feeReceiver][index]);
//         require(fee > 0,"Subscription fee should > 0");
//         Service memory service = Service(serviceName, fee, 1);
//         serviceSubscriptionInfo[feeReceiver][index] = service;
//     }
    
//     function test(address receiver, uint16 index) public view returns (bool) {
//         return serviceSubscriptionInfo[receiver][index].isSet == 0;
//     }
    
//     function test2() public view returns(uint256) {
//         return block.timestamp;
//     }
    
//     // uint16[] num;
//     // function test3() public view returns(uint256) {
//     //     return num.push(1);
//     // }
    
//     Service service;
//     function test4() public view returns(bool) {
//         return service.serviceFee == 0;
//     }
    
//     address[] array;
    
//     function test5() public {
//         // array[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
//         // array[1] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
//         // delete array[0];
//         array.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
//         array.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
//         delete array[0];
//         // return result;
//     }
    
//     function print(uint8 index) public view returns(address){
//         return array[index];
//     }
    
//     struct Subscription{
//         uint256 id;
//         uint256 subscriptionTime;
//         uint256 expirationTime;
//     }
    
//     // function test6() public{
//     //     Service service = serviceInfo[feeReceiver][index];
//     // }
    
    
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

library SafeMath {
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

interface ERC20Interface {

  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender, uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20Interface {
    using SafeMath for uint256;

    // Determined in compile-time, not take up state variable storage space 
    // -> cheaper & safer
    string public constant name = "USDT(S)";
    string public constant symbol = "USDT(S)";
    
    uint8 public immutable decimals;
    uint256 toalSupply_;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor(uint8 _decimals, uint256 _totalSupply) {
        decimals = _decimals;
        toalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public override view returns (uint256) {
        return toalSupply_;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfertwo(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0), "Cannot transfer to address(0)");
        require(_value <= balances[msg.sender], "Balance not enough!");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfertwo(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_to != address(0), "Cannot transfer to address(0)");
        require(_value <= allowed[_from][msg.sender], "Tokens allowed is not enough!");
        require(_value <= balances[_from], "Balance not enough!");
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}