/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

//SPDX-License-Identifier : MIT

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
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

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract interfaceIDO is Initializable, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint public minInvest =0;
    IERC20 public outputToken;
    uint256 public totalSupply;
    IERC20 public inputToken;
    mapping (address => bool) public existingUser;
    mapping (address => uint256) public userInvested;
    address[] public investors;
    uint public maxInvest = 0;
    uint public idoTarget;
    uint public tokenPrice;
    uint public raisedFund;
    uint8 public idoIndex;
    
    function initialize( address _token ) public initializer{
        inputToken = IERC20(_token);
    }
    
   
    function _invest(uint256 _amount) internal {
        uint256 amount = _amount * 10**18;
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), amount);
    }
    
    function _claim(uint256 _amount) internal {
        IERC20(outputToken).safeTransfer(msg.sender, _amount);
    }
    
    function _safeTransfer(address _contract, address _sender, address _recipient, uint256 _amount) internal {
        IERC20 tokens = IERC20(_contract);
        tokens.safeTransferFrom(_sender, _recipient, _amount);
    }

    
    event Invested(address indexed user, uint256 amount);
}
pragma solidity  ^0.6.1;
// SPDX-License-Identifier: Unlicensed

contract IDO is interfaceIDO{
    bool public claimEnabled = false;
    bool public investEnabled = false;
    
    function setIDO(address _inputToken, address _outputToken, uint256 _tokenPrice, uint256 _maxInvest, uint256 _minInvest) public onlyOwner() {
        
        require (_tokenPrice > 0, "Price can't zero");
        totalSupply = IERC20(_outputToken).balanceOf(address(this));
        
        inputToken = IERC20(_inputToken);
        outputToken = IERC20(_outputToken);
        tokenPrice = _tokenPrice;
        uint256 _totalSupply = outputToken.balanceOf(address(this));
        idoTarget = _totalSupply / tokenPrice;
        require (idoTarget > maxInvest);
        maxInvest = _maxInvest;
        minInvest = _minInvest;
    }
    
    function resetIDO() public onlyOwner() {
        for( uint256 i=0; i < investors.length; i++ ){
            if(existingUser[investors[i]] == true ){
                existingUser[investors[i]] = false;
                userInvested[investors[i]] = 0;
                }
         }
        totalSupply = 0;
        maxInvest = 0;
        idoTarget = 0;
        raisedFund = 0;
        inputToken = IERC20(address(0));
        outputToken = IERC20(address(0));
        tokenPrice = 0;
        claimEnabled = false;
        investEnabled = false;
        idoIndex = 0;
        delete investors;
    }
    
    function startIDO() external onlyOwner() {
        require( idoIndex == 0 );
        investEnabled = true;
        idoIndex = idoIndex + 1;
    }
    
    function stopIDO() external onlyOwner() {
        require( idoIndex != 0 );
        investEnabled = false;
        idoIndex = 0;
    }
    
    function emergencyWithdraw(address _contract) external onlyOwner() {
        IERC20 tokens = IERC20(_contract);
        tokens.transfer(msg.sender, tokens.balanceOf(address(this)));
    }
    
    function enableClaim() external onlyOwner() {
        claimEnabled = true;
        investEnabled = false;
    }
    
    function stopClaim() external onlyOwner() {
        claimEnabled = false;
        investEnabled = false;
    }
    
    function editMaxInvest(uint256 _amount) external onlyOwner() {
        maxInvest = _amount;
    }
    
    function claim() public {
        require(investEnabled == false, "claim isn't start");
        require(claimEnabled == true, "claim isn't start");
        require(existingUser[msg.sender] == true, "you allready claimed");
        uint256 _amount = userInvested[msg.sender] * tokenPrice;
        _claim(_amount);
        existingUser[msg.sender] = false;
        userInvested[msg.sender] = 0;
    }
    
    function investing(uint256 _amount) public {
        require(investEnabled == true);
        require(claimEnabled == false);
        require(idoTarget >= raisedFund + _amount, "Target Achieved, Investment not accepted");
        require(_amount > minInvest );
        uint256 check = userInvested[msg.sender] + _amount;
        require(check <= maxInvest, "failed transfer, max investment reached");
        if(existingUser[msg.sender] == false){
            existingUser[msg.sender] = true;
            investors.push(msg.sender);
        }
        userInvested[msg.sender] += _amount;
        raisedFund = raisedFund + _amount;
        _invest(_amount);
        emit Invested(msg.sender, _amount);
    }
    
    function progressUser(address _user) public view returns (uint256) {
        uint256 progress = maxInvest - userInvested[_user];
        return progress;
    }
}