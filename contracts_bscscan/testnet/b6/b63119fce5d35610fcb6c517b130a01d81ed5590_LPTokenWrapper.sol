/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() internal {
        address msgSender =msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
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
contract Governance is Ownable {
    address public _governance;
    constructor() public {
        _governance = msg.sender;
    }
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }
    function setGovernance(address governance)  public  onlyOwner{
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

contract LPTokenWrapper is Governance {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public _totalSupply;//累计
    uint256 public _totalOut;//累计
    mapping(address => uint256) private _balances;

    bool public _bStart =  false;
    //跨链代币地址
    IERC20 public _lpToken = IERC20(0x233Bd6a5E2420521b350Fa1E88c56319236E98fA);

    mapping (address => bool) private _Is_WhiteContractArr;
    address[] private _WhiteContractArr;

    event Staked(address indexed from, address indexed to, uint256 value);
    //查询累计总量
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    //查询单个地址跨链的总量
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function isWhiteContract(address account) public view returns (bool) {
        if(!account.isContract()) return true;
        return _Is_WhiteContractArr[account];
    }
    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteContractArr.length;
    }
    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteContractArr.length, "no ith White Adress");
        return _WhiteContractArr[ith];
    }
    modifier checkStart() {
        require(_bStart, "not start");
        _;
    }
    //质押
    function stake(uint256 amount, address  affCode) public checkStart{
        require(isWhiteContract(msg.sender), "Contract not in white list!");
        require(amount>0,  "Transfer amount must be greater than zero");
        _lpToken.safeTransferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Staked(msg.sender, affCode, amount);
    }

    //设置质押币
    function setLp_token(address LP_token) public  onlyOwner {
        _lpToken = IERC20(LP_token);
    }
    // 开始合约
    function startReward(bool bStart) external onlyOwner{
        _bStart = bStart;
    }
    //转移代币
    function transferEToken(address toaddr,uint256 amount) external onlyGovernance{
        _lpToken.safeTransfer(toaddr,amount);
        _totalOut = _totalOut.add(amount);
    }
    //转移代币-owner 操作
    function transferETokenOwner(address toaddr,uint256 amount) external onlyOwner{
        _lpToken.safeTransfer(toaddr,amount);
    }
    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteContractArr[account], "Account is already White list");
        require(account.isContract(), "not Contract Adress");
        _Is_WhiteContractArr[account] = true;
        _WhiteContractArr.push(account);
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteContractArr[account], "Account is already out White list");
        for (uint256 i = 0; i < _WhiteContractArr.length; i++){
            if (_WhiteContractArr[i] == account){
                _WhiteContractArr[i] = _WhiteContractArr[_WhiteContractArr.length - 1];
                _WhiteContractArr.pop();
                _Is_WhiteContractArr[account] = false;
                break;
            }
        }
    }
}