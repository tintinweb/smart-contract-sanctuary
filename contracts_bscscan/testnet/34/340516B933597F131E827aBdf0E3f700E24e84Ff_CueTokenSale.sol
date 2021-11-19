/**
 *Submitted for verification at Etherscan.io on 2021-01-11
*/

/**
 * Compiled with 0.6.6+commit.6c089d02
*/

// Partial License: MIT

pragma solidity ^0.6.0;

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


// Partial License: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Partial License: MIT

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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
}


// Partial License: MIT

pragma solidity ^0.6.0;

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


pragma solidity 0.6.6;



contract CueTokenSale is Ownable {
    using SafeMath for uint256;
    IERC20 public cue;
    uint256 constant BP = 10000;
    bool    public started;
    uint256 public price;
    uint256 public cap;
    uint256 public ends;
    uint256 public maxEnds;
    bool    public paused;
    uint256 public minimum;
    uint256 public maximum;
    uint256 public totalOwed;
    uint256 public weiRaised;

    mapping(address => uint256) public claimable;

    constructor (address addr) public { cue = IERC20(addr); }
    function pause(bool _paused)            public onlyOwner { paused = _paused;}
    function setPrice(uint256 _price)       public onlyOwner { price = _price; }
    function setMinimum(uint256 _minimum)   public onlyOwner { minimum = _minimum; }
    function setMaximum(uint256 _maximum)   public onlyOwner { maximum = _maximum; }
    function setCap(uint256 _cap)           public onlyOwner { cap = _cap; }
    function setEnds(uint256 _ends)   public onlyOwner {
        require(_ends <= maxEnds, "end date is capped");
        ends = _ends;
    }
    
    function unlock() public onlyOwner { ends = 0; paused = true; }

    function withdrawETH(address payable _addr, uint256 amount) public onlyOwner {
        _addr.transfer(amount);
    }

    function withdrawETHOwner(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }

    function withdrawUnsold(address _addr, uint256 amount) public onlyOwner {
        require(amount <= cue.balanceOf(address(this)).sub(totalOwed), "insufficient balance");
        cue.transfer(_addr, amount);
    }

    // start the presale
    function startPresale(uint256 _maxEnds, uint256 _ends) public onlyOwner {
        require(!started, "already started!");
        require(price > 0, "set price first!");
        require(minimum > 0, "set minimum first!");
        require(maximum > minimum, "set maximum first!");
        require(_maxEnds > _ends, "end date first!");
        require(cap > 0, "set a cap first");

        started = true;
        paused = false;
        maxEnds = _maxEnds;
        ends = _ends;
    }

    // the amount of cue purchased
    function calculateAmountPurchased(uint256 _value) public view returns (uint256) {
        return _value.mul(BP).div(price).mul(1e18).div(BP);
    }

    // claim your purchased tokens
    function claim() public {
        //solium-disable-next-line
        require(block.timestamp > ends, "presale has not yet ended");
        require(claimable[msg.sender] > 0, "nothing to claim");

        uint256 amount = claimable[msg.sender];

        // update user and stats
        claimable[msg.sender] = 0;
        totalOwed = totalOwed.sub(amount);

        // send owed tokens
        require(cue.transfer(msg.sender, amount), "failed to claim");
    }

    // purchase tokens
    function buy() public payable {
        //solium-disable-next-line
        require(!paused, "presale is paused");
        require(msg.value >= minimum, "amount too small");
        require(weiRaised.add(msg.value) < cap, "cap hit"); 

        uint256 amount = calculateAmountPurchased(msg.value);
        require(totalOwed.add(amount) <= cue.balanceOf(address(this)), "sold out");
        require(claimable[msg.sender].add(msg.value) <= maximum, "maximum purchase cap hit");

        // update user and stats:
        claimable[msg.sender] = claimable[msg.sender].add(amount);
        totalOwed = totalOwed.add(amount);
        weiRaised = weiRaised.add(msg.value);
    }

    fallback() external payable { buy(); }
    receive() external payable { buy(); }
}