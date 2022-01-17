/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract FighterBuyCoinManage is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    string private _name = "FighterBuyCoin";
    string private _symbol = "FBC";

    IERC20 public fbxToken;
    address public shareAddress;
    address public fundAddress;
    uint256 public distoryProportion=80;
    uint256 public shareProportion=10;
    uint256 public fundProportion=10;
    struct sBuyPropertys {
        uint256 id;
        address addr;
        uint256 buyAmount;
        uint256 time;
    }

    mapping(uint256 => sBuyPropertys) private _buyPropertys;
    mapping(address => uint256[]) private _buyIds;
    uint256 private _sumCount;
    
    mapping (address => uint256) private _balances;
    uint256 private _totalSupply;

    mapping (address => bool) private _Is_WhiteContractArr;
    address[] private _WhiteContractArr;

    event BuyCoins(address indexed user, uint256 amount,uint256 id);

    constructor(){
        fbxToken = IERC20(0xFD57aC98aA8E445C99bc2C41B23997573fAdf795);
        shareAddress=0xaC642c2B02dbe7991d94c8c6F572327745d659c1;
        fundAddress=0x75dCC20b49429ACF978e577eE5D0BEB1A79DB559;
    }
    
    /* ========== VIEWS ========== */
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
   function balanceOf(address account) external view  returns (uint256) {
        return _balances[account];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function sumCount() external view returns(uint256){
        return _sumCount;
    }

    //read info
    function buyInfo(uint256 iD) external view returns (
        uint256 id,
        address addr,
        uint256 buyAmount,
        uint256 time
        ) {
        require(iD <= _sumCount, "ForthBoxBuyCoin: exist num!");
        id = _buyPropertys[iD].id;
        addr = _buyPropertys[iD].addr;
        buyAmount = _buyPropertys[iD].buyAmount;
        time = _buyPropertys[iD].time;
        return (id,addr,buyAmount,time);
    }
    function buyNum(address addr) external view returns (uint256) {
        return _buyIds[addr].length;
    }
    function buyIthId(address addr,uint256 ith) external view returns (uint256) {
        require(ith < _buyIds[addr].length, "ForthBoxBuyCoin: not exist!");
        return _buyIds[addr][ith];
    }

    function buyInfos(uint256 fromId,uint256 toId) external view returns (
        uint256[] memory idArr,
        address[] memory addrArr,
        uint256[] memory buyAmountArr,
        uint256[] memory timeArr
        ) {
        require(toId <= _sumCount, "ForthBoxBuyCoin: exist num!");
        require(fromId <= toId, "ForthBoxBuyCoin: exist num!");
        idArr = new uint256[](toId-fromId+1);
        addrArr = new address[](toId-fromId+1);
        buyAmountArr = new uint256[](toId-fromId+1);
        timeArr = new uint256[](toId-fromId+1);
        uint256 i=0;
        for(uint256 ith=fromId; ith<=toId; ith++) {
            idArr[i] = _buyPropertys[ith].id;
            addrArr[i] = _buyPropertys[ith].addr;
            buyAmountArr[i] = _buyPropertys[ith].buyAmount;
            timeArr[i] = _buyPropertys[ith].time;
            i = i+1;
        }
        return (idArr,addrArr,buyAmountArr,timeArr);
    }
    
    function isWhiteContract(address account) public view returns (bool) {
        if(!account.isContract()) return true;
        return _Is_WhiteContractArr[account];
    }
    function getWhiteAccountNum() public view returns (uint256){
        return _WhiteContractArr.length;
    }
    function getWhiteAccountIth(uint256 ith) public view returns (address WhiteAddress){
        require(ith <_WhiteContractArr.length, "ForthBoxBuyCoin: not in White Adress");
        return _WhiteContractArr[ith];
    }
    //---write---//
    function buyCoin(uint256 amount,uint256 time) external nonReentrant{
        require(isWhiteContract(_msgSender()), "ForthBoxBuyCoin: Contract not in white list!");

        fbxToken.safeTransferFrom(_msgSender(),address(0),amount.mul(distoryProportion).div(100));
        fbxToken.safeTransferFrom(_msgSender(), shareAddress, amount.mul(shareProportion).div(100));
        fbxToken.safeTransferFrom(_msgSender(), fundAddress, amount.mul(fundProportion).div(100));

        _sumCount = _sumCount.add(1);
        _buyIds[_msgSender()].push(_sumCount);

        _buyPropertys[_sumCount].id = _sumCount;
        _buyPropertys[_sumCount].addr = _msgSender();
        _buyPropertys[_sumCount].buyAmount = amount;
        _buyPropertys[_sumCount].time = time;

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit BuyCoins(msg.sender, amount, _sumCount);
    }

    //---write onlyOwner---//
    function addWhiteAccount(address account) external onlyOwner{
        require(!_Is_WhiteContractArr[account], "ForthBoxBuyCoin:Account is already White list");
        require(account.isContract(), "ForthBoxBuyCoin: not Contract Adress");
        _Is_WhiteContractArr[account] = true;
        _WhiteContractArr.push(account);
    }
    function removeWhiteAccount(address account) external onlyOwner{
        require(_Is_WhiteContractArr[account], "ForthBoxBuyCoin:Account is already out White list");
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