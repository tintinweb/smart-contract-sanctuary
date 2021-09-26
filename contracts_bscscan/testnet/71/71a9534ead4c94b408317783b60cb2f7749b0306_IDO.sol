/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer () {
        require ( _initializing || !_initialized, "Initializableb : Contract is allready Initializezld");
        bool isTopLevelCall = !_initializing;
        if(isTopLevelCall){
            _initializing = true;
            _initialized = true;
        }
        _;
       if(isTopLevelCall){
            _initializing = false;
       }
    }
}

abstract contract Context is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library Address {
  
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address hardCap, bytes memory data) internal returns (bytes memory) {
      return functionCall(hardCap, data, "Address: low-level call failed");
    }

    function functionCall(address hardCap, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(hardCap, data, 0, errorMessage);
    }

    function functionCallWithValue(address hardCap, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(hardCap, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address hardCap, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(hardCap, data, value, errorMessage);
    }

    function _functionCallWithValue(address hardCap, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(hardCap), "Address: call to non-contract");

        (bool success, bytes memory returndata) = hardCap.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string  memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract interfaceIDO is Initializable, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public maxInvest = 0;
    uint8 public minInvest = 0;
    IERC20 public inputToken;
    IERC20 public outputToken;
    uint256 public valueToken;
    
    mapping (address => bool) userExist;
    mapping (address => uint256) invested;
    address[] public investors;
    uint256 public hardCap;
    uint256 public tokenPrice;
    uint256 public raisedFund;
    uint8 public index;
    
    bool public startClaim = false;
    bool public startInvest = false;
    
    function initialize (address _token) public initializer {
        inputToken = IERC20(_token);
    }
    
    function _valueToken() public view returns (uint256) {
        return IERC20(outputToken).balanceOf(address(this));
    }
    
    function _investing(uint256 _amount) internal {
        raisedFund = raisedFund.add(_amount);
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit Investing(msg.sender, _amount);
    }
    
    function _claim (uint256 _amount) internal {
        uint8 decimal = IERC20(outputToken).decimals();
        uint256 amount = _amount * 10**decimal;
        IERC20(outputToken).safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }
    
    event Investing(address indexed _user, uint256 _amount);
    event Claim(address indexed _user, uint256 _amount);
    event start(address indexed _user, bool _startIdo);
}

//SPDX-License-Identifier : Unlicensed
pragma solidity ^0.6.1;

contract IDO is interfaceIDO {
    
    function initializeIDO ( address _inputToken, address _outputToken, uint256 _tokenPrice, uint256 _maxInvest) public onlyOwner() {
        
        require(_tokenPrice > 0);
        
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);
        tokenPrice = _tokenPrice;
        valueToken = outputToken.balanceOf(address(this));
        uint8 decimalToken = outputToken.decimals();
        uint256 prices = tokenPrice * 10**decimalToken;
        hardCap = valueToken.div(prices);
        require(hardCap > maxInvest);
        maxInvest = _maxInvest;
    }
    
    function editMax(uint256 _amount) public onlyOwner() {
        maxInvest = _amount;
    }
    
    function setminInvest(uint8 _amount) public onlyOwner() {
        minInvest = _amount;
    }
    
    function resetIDO() public onlyOwner(){ 
        for(uint256 i=0; i < investors.length; i++ ) {
            if(userExist[investors[i]] == true){
                userExist[investors[i]] = false;
                invested[investors[i]] = 0;
            }
        }
        valueToken = 0;
        maxInvest  = 0;
        minInvest  = 0;
        tokenPrice = 0;
        hardCap    = 0;
        raisedFund = 0;
        index      = 0;
        startClaim = false;
        startInvest = false;
        inputToken = IERC20(address(0));
        outputToken = IERC20(address(0));
        delete investors;
    }
    
    function startIDO() public onlyOwner(){
        require(index == 0 );
        startInvest = true;
        index = index + 1;
        emit start(msg.sender, true);
    }
    
    function stopIDO() public onlyOwner(){
        require(index > 0 );
        startInvest = false;
        index = 0;
        emit start(msg.sender, false);
    }
    
    function emergencyWithdraw(address _contract) public onlyOwner() {
        IERC20(_contract).safeTransfer(msg.sender, IERC20(_contract).balanceOf(address(this))); 
    }
    
    function _startClaim() public onlyOwner() {
        startClaim = true;
        startInvest = false;
        emit start(msg.sender, true);
    }
    function stopClaim() public onlyOwner() {
        startClaim = false;
        emit start(msg.sender, false);
    }
    
    function claim() public {
       require(startInvest == false);
       require(startClaim == true);
       require(userExist[msg.sender] == true);
       uint256 _amount = invested[msg.sender] * tokenPrice;
       _claim(_amount);
       userExist[msg.sender] = false;
       invested[msg.sender]  = 0;
    }
    
    function invest(uint256 _amount) public {
        require(startInvest == true);
        require(startClaim == false);
        uint256 max = raisedFund + _amount;
        uint8 dec = IERC20(inputToken).decimals();
        uint256 amount = _amount/10**dec;
        require(hardCap >= max, "hardCap Achieved. Investment not accepted");
        uint256 min = invested[msg.sender] + _amount;
        require(min <= maxInvest);
        if(userExist[msg.sender] == false) {
            userExist[msg.sender] == true;
            investors.push(msg.sender);
        }
        invested[msg.sender].add(_amount);
        raisedFund.add(_amount);
        _investing(_amount);
    }
    
    function proggress(address _users) public view returns (uint256) {
        uint256 progress = maxInvest - invested[_users];
        return progress;
    }

}