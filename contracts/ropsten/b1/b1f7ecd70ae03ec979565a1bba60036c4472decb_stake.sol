/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeCast {

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
    
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

contract Initializable {

  bool private initialized;

  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  function isConstructor() private view returns (bool) {
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract ContextUpgradeSafe is Initializable {

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }

}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

contract stake is ERC20UpgradeSafe, OwnableUpgradeSafe {
    
    using SafeCast for int256;
    using SafeMath for uint256;
    using Address for address;
    

    uint256 public _TotalPresaleEth;
    
    uint256 public rID;
    bool public allowPublicInvestment = false; 
    mapping(address => uint256[]) public pID; 
    mapping(address => bool) public whitelistAddresses; 
    mapping(address => uint256) public investments; // total WEI invested per address (1ETH = 1e18WEI)
    mapping(uint256 => Round) public round_;
    mapping(address => uint256) public ethWithdrawn;
    mapping(address => bool) public addressPresent;
    mapping(address => bool) public claimed;
    uint256 public jackpot;
    uint256 public remainingJackpot;
    uint256 public totalRewardPerBond;
    uint256 public totalShareUntilRd;
    uint256 public totalEtherInRds;
    uint256 public timer = now + 7 days;
    

    struct Round {
        address plyr; // pID of player in lead
        uint256 xBonds; // keys
        uint256 eth; // total eth in
        uint256 potPerBonds; // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 currentRdShare; // eth to pot (during round) / final amount paid to winner (after round ends)
    }

    function startPublicPresale() public onlyOwner {
    allowPublicInvestment = true;
  }

  function addWhitelistAddresses(address[] calldata _whitelistAddresses) external onlyOwner {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
      whitelistAddresses[_whitelistAddresses[i]] = true;
    }
  }

    modifier eligibleForPresale() {
    require(whitelistAddresses[_msgSender()] || allowPublicInvestment, "Your address is not whitelisted for either presale, or the public presale hasn't started yet.");
    _;
  }

    receive() external payable  {
     //   require(!endSale, "PreSale Ended");
        require(msg.value >= 0.01 ether);
        require(now < timer);
        timer = now + 10 minutes;

        // address payable entryFEE = address(uint160(owner()));
        // entryFEE.transfer(msg.value.div(10));
        // uint256 jackPotAllot = msg.value.mul(40).div(100);
        // jackpot = jackpot.add(jackPotAllot);
        // uint256 _xbondEther = msg.value.sub(jackPotAllot).sub(msg.value.div(10));
        // _getBonds(msg.sender, _xbondEther);
        _getBonds(msg.sender, msg.value);
        
    }

    function getDust() external onlyOwner() {
        require(now > timer + 30 days);
         address payable a = address(uint160(owner()));
         a.transfer(address(this).balance);
    } 

    function _getBonds(address recipient, uint256 _eth) internal virtual {
        addressPresent[recipient]  = true;
        rID++;
        uint256 bonds = (_bonds(totalEtherInRds.add(_eth))).sub(totalShareUntilRd);
        totalEtherInRds = totalEtherInRds.add(_eth);
        totalShareUntilRd = totalShareUntilRd.add(bonds);
        uint256 currRd = _eth.div(totalShareUntilRd);
        totalRewardPerBond = totalRewardPerBond.add(currRd);

        round_[rID].plyr = recipient;
        round_[rID].xBonds = bonds;
        round_[rID].eth = _eth;
        round_[rID].potPerBonds = totalRewardPerBond;
        round_[rID].currentRdShare = currRd;

        pID[recipient].push(rID);    
    }

    function earningByID (uint256 roundID) internal view returns (uint256) {
        require(roundID < rID && roundID > 0);
        uint256 rewardTillBond = round_[roundID].potPerBonds;
        uint256 thisReward = round_[roundID].currentRdShare;
        uint256 netRewardPerBond = (totalRewardPerBond.add(thisReward)).sub(rewardTillBond);
        uint256 earning = netRewardPerBond.mul(round_[roundID].xBonds);
        return earning;
    }

    function earningByAddress (address rec) internal view returns (uint256) {
        uint256[] memory pIDs = pID[rec];
        uint256 totalEarn;
        for (uint256 i = 0; i < pIDs.length; i++) {
           uint256 r = pIDs[i];
           uint256 earningThis = earningByID(r);
           totalEarn = totalEarn.add(earningThis);
        }
        return totalEarn;
    }

    function claimReward () external {
        require(addressPresent[msg.sender]);
        uint256[] memory pIDs = pID[msg.sender];
        require((pIDs.length) > 0);
        uint256 TotalReward = earningByAddress(msg.sender);
        require(TotalReward > 0);
        uint256 ethW = ethWithdrawn[msg.sender];
        uint256 ethToSend = TotalReward.sub(ethW);
        require(0 < ethToSend && ethToSend <= TotalReward);
        ethWithdrawn[msg.sender] = ethWithdrawn[msg.sender].add(ethToSend);
        msg.sender.transfer(ethToSend);
    }

    function checkJackpotID () internal view returns (uint256) {
        uint256 rep;
        uint256 j=0;
        uint256 i=10;
        while (i>1) {
            uint256 k = rID - j;
            if(round_[k].plyr == msg.sender) {
                rep++;
            }
            j++;
            i--;
        }
        return rep;
    }

    function claimJackpot () external {
        require(now > timer + 24 hours);
        require(!claimed[msg.sender]);
        uint256 r = checkJackpotID();
        require(r > 0 && r <= 10); 
        uint256 amountToClaim = ((jackpot.mul(10)).div(100)).mul(r);
        require(amountToClaim < jackpot);
        remainingJackpot = jackpot.sub(amountToClaim);
        require(remainingJackpot > 0);
        claimed[msg.sender] == true;
        msg.sender.transfer(amountToClaim);
    }

    function earningByIDExt (uint256 roundID) external view returns (uint256) {
        uint256 earning = earningByID(roundID);
        return earning;
    }

    function earningByAddressExt (address rec) external view returns (uint256) {
        uint256 totalEarn = earningByAddress(rec);
        return totalEarn;
    }

    function _bonds(uint256 _eth) internal pure returns (uint256) {
        return
            ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000))
                            .add(5624988281256103515625000000000000000000000000000000000000000000))
                        .sqrt())
                    .sub(74999921875000000000000000000000)).div(156250000000000000000000000);
    }

}