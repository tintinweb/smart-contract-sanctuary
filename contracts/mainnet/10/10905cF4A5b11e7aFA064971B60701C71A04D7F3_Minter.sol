// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }	
}

contract Ownable is Context {
    address private _owner;
    address public admin;
    address public dev;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == _owner);
        _;
    }
    
    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == _owner);
        _;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


abstract contract ContractConn{

    function transfer(address _to, uint256 _value) virtual public;
    function balanceOf(address who) virtual public view returns (uint256);
}

contract Minter is Ownable {

    using SafeMath for uint256;
    uint256 public userMinted = 0;   
    uint256 public minHandlingFee = 5;
    uint256 public minHandlingFeeNew;
    uint256 public handlingFeeRate = 4;
    uint256 public handlingFeeRateNew;
    uint256 public changeFeeWaitTime = 12000;
    uint256 public changeFeeTime;
	bool    public needChangeFee = false;
    uint256 public handlingFeeCollect;
    uint256 public minedAmount;
    address public collector = address(0);
    
    ContractConn public zild;    

    mapping(address => uint256) public user_minter_amount;
    mapping(address => uint256) public user_minter_netincome;
    mapping(address => uint256) public user_minter_fee;
    
    event MinterRevenue(uint256 total,address indexed who,uint256 amount, uint256 handlingfee,uint256 netincome,uint256 userTotal);
    event SetCollector(address indexed collector,uint256 time);
    event CollectHandlingFee(uint256 amount,uint256 handlingFeeCollect,uint256 now);
    event SetHandlingFee(uint256 fee,uint256 rate,address indexed who,uint256 time);
    event EffectHandlingFee(uint256 fee,uint256 rate,address indexed who,uint256 time);
    
    constructor(address _token) public {
        zild = ContractConn(_token);
    }

    function generate(uint256 amount) public onlyOwner returns(bool){
        require(amount > 0, "minter：generate amount error");
        require(amount <= zild.balanceOf(address(this)), "minter：insufficient balance generates more mines");
        minedAmount = minedAmount.add(amount);
        return true;
    } 
    
    function minter(address _to, uint256 amount) public onlyDev returns(bool){
        require(amount > minHandlingFee.mul(10 ** 18).div(100), "minter：withdrawal amount must be greater than the minimum handling fee");
        require(amount <= minedAmount,"minter：Not so many mined token");
        uint256 handlingfee = amount.mul(handlingFeeRate).div(1000);
        if (handlingfee < minHandlingFee.mul(10 ** 18).div(100)) handlingfee = minHandlingFee.mul(10 ** 18).div(100);
        zild.transfer(_to,amount.sub(handlingfee));
        minedAmount = minedAmount.sub(amount);
        userMinted = userMinted.add(amount);
        user_minter_amount[_to] = user_minter_amount[_to].add(amount);
        user_minter_netincome[_to] = user_minter_netincome[_to].add(amount.sub(handlingfee));
        user_minter_fee[_to] = user_minter_fee[_to].add(handlingfee);
        handlingFeeCollect = handlingFeeCollect.add(handlingfee);
        emit MinterRevenue(userMinted,_to,amount,handlingfee,amount.sub(handlingfee),user_minter_amount[_to]);
        return true;
    } 

    function setCollector(address _collector) public onlyAdmin {
        require(_collector != address(0), "Minter: collector is the zero address");
        collector = _collector;
        emit SetCollector(_collector,now);
    }
    
    function collectHandlingFee(uint256 amount) public onlyAdmin returns(bool){
        require(amount > 0, "minter：collect amount error");
        require(amount <= handlingFeeCollect, "minter：withdrawal amount exceeds collector balance");
        zild.transfer(collector,amount);
        handlingFeeCollect = handlingFeeCollect.sub(amount);
        emit CollectHandlingFee(amount,handlingFeeCollect,now);
        return true;
    }     

    function setHandlingFee(uint256 _fee,uint256 _rate) public onlyAdmin {
        require(_fee > 0 || _rate > 0,"Minter: New handling fee rate must be greater than 0"); 
		minHandlingFeeNew = _fee;
        handlingFeeRateNew = _rate;
        changeFeeTime = block.number;
        needChangeFee = true;
        emit SetHandlingFee(_fee,_rate,msg.sender,now);
    }
    
    function effectblockchange() public onlyAdmin {
        require(needChangeFee,"Minter: No new handling fee rate are set");
        uint256 currentTime = block.number;
        uint256 effectTime = changeFeeTime.add(changeFeeWaitTime);
        if (currentTime < effectTime) return;
        minHandlingFee = minHandlingFeeNew;
        handlingFeeRate = handlingFeeRateNew;
        needChangeFee = false;
        emit EffectHandlingFee(minHandlingFee,handlingFeeRate,msg.sender,now);
    } 
}