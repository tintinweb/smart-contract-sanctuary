/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**
 * CookieFinance
 * App:             https://cookiebake.finance
 * Medium:          https://medium.com/@cookiefinance    
 * Twitter:         https://twitter.com/cookiedefi 
 * Telegram:        https://t.me/cookiedefi 
 * Announcements:   https://t.me/cookiefinance
 * GitHub:          https://github.com/cookiedefi
 */
 
pragma solidity 0.8.0;

// SPDX-License-Identifier: UNLICENSED

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ChipsStaking {
    function depositFor(address player, uint256 amount) external;
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface CookieGovernance {
    function pullCollateral(uint256 amount) external returns (uint256 compensation);
    function compensationAvailable(address farm) external view returns (uint256);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ChipsLPStaking is Ownable {
    using SafeMath for uint256;
    
    ERC20  public chips;
    ERC20  public chipsLP;
    ChipsStaking chipsStaking;
    CookieGovernance governance;

    mapping(address => uint256) public balances;
    mapping(address => int256) payoutsTo;

    uint256 public totalDeposits;
    uint256 profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    uint256 public chipsPerEpoch;
    uint256 public payoutEndTime;
    uint256 public lastDripTime;
    
    constructor( ERC20 _chips, ERC20 _chipsLP, ChipsStaking _chipsStaking, CookieGovernance _governance) {
        chips = _chips;
        chipsStaking = _chipsStaking;
        chipsLP = _chipsLP;
        governance = _governance;
        chips.approve(address(chipsStaking), 2 ** 255);
    }

    function deposit(uint256 amount) external {
        require(chipsLP.balanceOf(msg.sender) >= amount, "ChipsLPStaking :: deposit : insufficient balance to deposit");
        require(chipsLP.allowance(msg.sender, address(this)) >= amount, "ChipsLPStaking :: deposit : insufficient allowance to deposit");
        dripChips();
        chipsLP.transferFrom(msg.sender, address(this), amount);
        totalDeposits += amount;
        balances[msg.sender] += amount;
        payoutsTo[msg.sender] += (int256) (profitPerShare * amount);
    }
    
    function depositFor(address player, uint256 amount) external {
        require(chipsLP.balanceOf(msg.sender) >= amount, "ChipsLPStaking :: depositFor : insufficient balance to deposit");
        require(chipsLP.allowance(msg.sender, address(this)) >= amount, "ChipsLPStaking :: depositFor : insufficient balance to deposit");
        dripChips();
        chipsLP.transferFrom(msg.sender, address(this), amount);
        totalDeposits += amount;
        balances[player] += amount;
        payoutsTo[player] += (int256) (profitPerShare * amount);
    }

    function cashout(uint256 amount) external {
        require(amount > 0, "ChipsLPStaking :: cashout : amount must be greater than zero");
        address recipient = msg.sender;
        claimYield();
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        payoutsTo[recipient] -= (int256) (profitPerShare * amount);
        chipsLP.transfer(recipient, amount);
    }

    function claimYield() public {
        dripChips();
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        payoutsTo[recipient] += (int256) (dividends * magnitude);
        chips.transfer(recipient, dividends);
    }
    
    function depositYield() external {
        dripChips();
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        
        if (dividends > 0) {
            payoutsTo[recipient] += (int256) (dividends * magnitude);
            chipsStaking.depositFor(recipient, dividends);
        }
    }
    
    function setWeeksRewards(uint256 amount) external {
        require(msg.sender == address(governance));
        dripChips();
        uint256 remainder;
        if (block.timestamp < payoutEndTime) {
            remainder = chipsPerEpoch * (payoutEndTime - block.timestamp);
        }
        chipsPerEpoch = (amount + remainder) / 7 days;
        payoutEndTime = block.timestamp + 7 days;
    }
    
    function dripChips() internal {
        uint256 divs;
        if (block.timestamp < payoutEndTime) {
            divs = chipsPerEpoch * (block.timestamp - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        lastDripTime = block.timestamp;

        if (divs > 0) {
            profitPerShare += divs * magnitude / totalDeposits;
        }
    }
    
    function upgradeChipsStaking(address stakingContract) external onlyOwner {
        chipsStaking = ChipsStaking(stakingContract);
        chips.approve(stakingContract, 2 ** 255);
    }

    function dividendsOf(address farmer) view public returns (uint256) {
        uint256 totalProfitPerShare = profitPerShare;
        uint256 divs;
        if (block.timestamp < payoutEndTime) {
            divs = chipsPerEpoch * (block.timestamp - lastDripTime);
        } else if (lastDripTime < payoutEndTime) {
            divs = chipsPerEpoch * (payoutEndTime - lastDripTime);
        }
        
        if (divs > 0) {
            totalProfitPerShare += divs * magnitude / totalDeposits;
        }
        return (uint256) ((int256)(totalProfitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
}

/**
 *
 *   /$$$$$$                      /$$       /$$                 /$$$$$$$$ /$$                                                  
 *  /$$__  $$                    | $$      |__/                | $$_____/|__/                                                  
 * | $$  \__/  /$$$$$$   /$$$$$$ | $$   /$$ /$$  /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
 * | $$       /$$__  $$ /$$__  $$| $$  /$$/| $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
 * | $$      | $$  \ $$| $$  \ $$| $$$$$$/ | $$| $$$$$$$$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 * | $$    $$| $$  | $$| $$  | $$| $$_  $$ | $$| $$_____/      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
 * |  $$$$$$/|  $$$$$$/|  $$$$$$/| $$ \  $$| $$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
 *  \______/  \______/  \______/ |__/  \__/|__/ \_______/      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
 * 
 * 
 *                                             https://www.cookiedefi.com
 */