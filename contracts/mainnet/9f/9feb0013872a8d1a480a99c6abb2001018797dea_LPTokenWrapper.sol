/**
 *Submitted for verification at Etherscan.io on 2021-12-02
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
      uint256 size;
      assembly {size := extcodesize(account)}
      return size > 0;
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
    uint256 public _totalFee;//累计
    uint256 public _totalStakeTimes;//累计
    uint256 public _totalOut;//累计
    mapping(address => uint256) private _balances;

    bool public _bStart =  false;
    bool public _bOutStart =  false;
    uint256 public _MaxTranferAmount =  1000*10**18;
    uint256 public _Fee =  1*10**18;

    //跨链代币地址
    IERC20 public _lpToken;

    mapping (address => bool) private _Is_WhiteContractArr;
    address[] private _WhiteContractArr;

    event Staked(address indexed from, address indexed to, uint256 value);
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
        require(amount>=_Fee,  "Transfer amount must be greater than fee");
        require(amount<=_MaxTranferAmount,  "Transfer amount must be littler than MaxTranferAmount");
        _lpToken.safeTransferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _totalStakeTimes =_totalStakeTimes.add(1);
        emit Staked(msg.sender, affCode, amount);
    }

    //设置质押币
    function setLp_token(address LP_token) public  onlyOwner {
        _lpToken = IERC20(LP_token);
    }
    // 开始合约
    function startReward(bool bStart,bool bOutStart) external onlyOwner{
        _bStart = bStart;
        _bOutStart = bOutStart;
    }

    modifier checkOutStart() {
        require(_bOutStart, "not out start");
        _;
    }

    //转移代币
    function transferEToken(address toaddr,uint256 amount) external checkOutStart onlyGovernance{
        require(amount<=_MaxTranferAmount,  "Transfer amount must be littler than MaxTranferAmount");
        if(amount>=_Fee) {
            amount = amount.sub(_Fee);
            _totalFee = _totalFee.add(_Fee);
        }
        _lpToken.safeTransfer(toaddr,amount);
        _totalOut = _totalOut.add(amount);
    }
    function setTranferMaxFeeAmount(uint256 tMaxTranferAmount,uint256 tFee) external onlyOwner{
        _MaxTranferAmount = tMaxTranferAmount;
        _Fee = tFee;
    }
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