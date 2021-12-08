// File: contracts/msvr.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is IERC20, IERC20Metadata {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    address internal devaddr;
    uint256 public maxSupply = 210000000000 * (10 ** decimals());

    mapping (address => bool) internal pardonFromList;
    mapping (address => bool) internal pardonToList;

    mapping (address => bool) white;

    event LogTransferFee(address from, uint256 wearAmount);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        if (pardonFromList[sender] == true || pardonFromList[recipient] == true || sender == address(0)) {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            _balances[devaddr] += amount / 10;
            _balances[recipient] += amount * 9 / 10;
            emit Transfer(sender, recipient, amount);
            emit LogTransferFee(sender, amount / 10);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract CSD is ERC20 {

    string _name = "CS:GO-DAO";
    string _symbol = "CSD";

    uint256 private ethBurn = 5 * 10 ** 15;

    uint256 private power0 = 1000;
    
    uint256 private power1 = 400;
    uint256 private power2 = 200;
    uint256 private power3 = 100;
    uint256 private power4 = 100;
    uint256 private power5 = 100;
    uint256 private power6 = 50;
    uint256 private power7 = 50;

    uint256 private sec9Rate = 125 * 125 * 10 ** 12;  // 1000 power 9second = 0.03125, 1000 power 1 hour = 12,500  1000 power 24 hour = 300,000
    uint256 private timeLast = 300; // 86400
    uint256 private backRate = 0;             // 10% coin to admin, when claim
    // uint256 private maxnum   = 21 * 10 ** 24;  // max 21 million
    uint256 private maxnum = 200 * 10 ** 27;  // max 200 billion
    uint256 private miners = 0;
    uint256 private minClaim = 100000;  // Each claim requires at least 300,000
    
    address private backAddr;
    
    // mapping (address => uint256[3]) private data;  // stime ctime unclaim
    mapping (address => uint256[4]) private data;  // stime ctime unclaim
    mapping (address => address[])  private team1; // user -> teams1
    mapping (address => address[])  private team2; // user -> teams2
    mapping (address => address[])  private team3; // user -> teams3
    mapping (address => address[])  private team4; // user -> teams4
    mapping (address => address[])  private team5; // user -> teams5
    mapping (address => address[])  private team6; // user -> teams6
    mapping (address => address[])  private team7; // user -> teams7
    mapping (address => address)    private boss;  // user -> boss
    mapping (address => bool)       private role;  // user -> true
    mapping (address => bool)       private mine;

    uint256 private teamNum_1 = 0;  // team1 number
    uint256 private teamNum_2 = 0;  // team2 number
    uint256 private teamNum_3 = 0;  // team3 number
    uint256 private teamNum_4 = 0;  // team4 number
    uint256 private teamNum_5 = 0;  // team5 number
    uint256 private teamNum_6 = 0;  // team6 number
    uint256 private teamNum_7 = 0;  // team7 number

    struct Rank {
      address addr;
      uint256 value;
    }

    Rank[] private rankingList; // Number of inviters ranking

    constructor() ERC20(_name, _symbol) {
        role[_msgSender()] = true;
        backAddr = _msgSender();
        devaddr = _msgSender();
        for (uint8 i = 0; i < 20; i++){
            // rankingList[i]=Rank(address(0),0);
            rankingList.push(Rank(address(0),0));
        }
    }

    function setPardonFromList(address _address, bool _pardon) public {
        require(hasRole(_msgSender()), "must have role");
        pardonFromList[_address] = _pardon;
    }

    function setPardonToList(address _address, bool _pardon) public {
        require(hasRole(_msgSender()), "must have role");
        pardonToList[_address] = _pardon;
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(_msgSender()), "must have role");
        _mint(to, amount);
    }
    
    function burn(address addr, uint256 amount) public {
        require(hasRole(_msgSender()), "must have role");
        _burn(addr, amount);
    }
    
    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }

    function setRole(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        role[addr] = val;
    }
    
    function setEthBurn(uint256 _ethBurn) public {
        require(hasRole(_msgSender()), "must have role");
        ethBurn = _ethBurn;
    }

    function setWhite(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        white[addr] = val;
    }
    
	function withdrawErc20(address conaddr, uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
        IERC20(conaddr).transfer(backAddr, amount);
	}
	
	function withdrawETH(uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
		payable(backAddr).transfer(amount);
	}
    
    function getTeam1(address addr) public view returns (address[] memory) {
        return team1[addr];
    }
    
    function getTeam2(address addr) public view returns (address[] memory) {
        return team2[addr];
    }
    
    function getTeam3(address addr) public view returns (address[] memory) {
        return team3[addr];
    }

    function getTeam4(address addr) public view returns (address[] memory) {
        return team4[addr];
    }

    function getTeam5(address addr) public view returns (address[] memory) {
        return team5[addr];
    }

    function getTeam6(address addr) public view returns (address[] memory) {
        return team6[addr];
    }

    function getTeam7(address addr) public view returns (address[] memory) {
        return team7[addr];
    }
    
    function getData(address addr) public view returns (uint256[28] memory, address, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim,half) = getClaim(addr, invite);
        uint256[28] memory arr = [ethBurn, power0, invite, power1, power2, power3, power4, power5, power6, power7,
            sec9Rate, data[addr][0], data[addr][1], team1[addr].length, team2[addr].length, team3[addr].length,
            team4[addr].length,team5[addr].length,team6[addr].length,team7[addr].length, 
            timeLast, backRate, totalSupply(), balanceOf(addr), claim, half, miners,minClaim];
        return (arr, boss[addr], backAddr);
    }
    
    function setData(uint256[] memory confs) public {
        require(hasRole(_msgSender()), "must have role");
        ethBurn  = confs[0];
        power0   = confs[1];
        power1   = confs[2];
        power2   = confs[3];
        sec9Rate = confs[4];
        timeLast = confs[5];
        backRate = confs[6];
        power3   = confs[7];
        power4   = confs[8];
        power5   = confs[9];
        power6   = confs[10];
        power7   = confs[11];
        minClaim = confs[12];
    }
    
    function setBack(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        backAddr   = addr;
        role[addr] = true;
    }
    
    function setDev(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        devaddr = addr;
    }
    
    function getClaim(address addr, uint256 invitePower) public view returns(uint256, uint256) {
        uint256 claimNum = data[addr][2];
        uint256 etime = data[addr][0] + timeLast;

        uint256 half = 1;
        if (totalSupply() < 50 * 10 ** 27) {
            half = 1;
        } else if (totalSupply() < 105 * 10 ** 27) {
            half = 2;
        } else if (totalSupply() < 157.5 * 10 ** 27) {
            half = 4;
        } else if (totalSupply() < 200 * 10 ** 27) {
            half = 8;
        } else if (totalSupply() < 210 * 10 ** 27) {
            half = 16;
        } else {
            return (0, 0);
        }

        // plus mining claim
        if (data[addr][0] > 0 && etime > data[addr][1]) {
            uint256 power = power0 + invitePower;
            if (etime > block.timestamp) {
                etime = block.timestamp;
            }
            claimNum += (etime - data[addr][1]) / 9 * power * sec9Rate / half;
        }

        return (claimNum, half);
    }
    
    function sumInvitePower(address addr) public view returns (uint256) {
        uint256 total = 0;
         total += power1 * team1[addr].length;
         total += power2 * team2[addr].length;
         total += power3 * team3[addr].length;
         total += power4 * team4[addr].length;
         total += power5 * team5[addr].length;
         total += power6 * team6[addr].length;
         total += power7 * team7[addr].length;
        return total;
    }
    
    function doStart(address invite) public payable {
        require(msg.value >= ethBurn);
        require(totalSupply() <= maxnum);
        
        payable(backAddr).transfer(msg.value);

        if (boss[_msgSender()] == address(0) && _msgSender() != invite && invite != address(0)) {
            boss[_msgSender()] = invite;
            team1[invite].push(_msgSender());

            address invite2 = boss[invite];
            if (invite2 != address(0)) {
                team2[invite2].push(_msgSender());
                
                invite2 = boss[invite2];
                if (invite2 != address(0)) {
                    team3[invite2].push(_msgSender());

                    invite2 = boss[invite2];
                    if (invite2 != address(0)) {
                        team4[invite2].push(_msgSender());

                        invite2 = boss[invite2];
                        if (invite2 != address(0)) {
                            team5[invite2].push(_msgSender());

                            invite2 = boss[invite2];
                            if (invite2 != address(0)) {
                                team6[invite2].push(_msgSender());

                                invite2 = boss[invite2];
                                if (invite2 != address(0)) {
                                    team7[invite2].push(_msgSender());
                                }
                            }
                        }
                    }
                }
            } 

            // rank sorting
            // 1. check min
            uint32 index_old = 19;
            uint32 index_new = 999;
            for (uint32 i =19; i>=0;i--){
                if (team1[invite].length <= rankingList[i].value) {
                    break;
                } else {
                    index_new = i;
                    if (rankingList[i].addr == invite) {
                        index_old = i;
                    }
                }
            }
            // 2. update ranking
            if (index_new < 999) {
                for (uint32 i =index_old;i>index_new;i--) {
                    rankingList[i].addr = rankingList[i-1].addr;
                    rankingList[i].value = rankingList[i-1].value;
                }
                rankingList[index_new].addr = invite;
                rankingList[index_new].value = team1[invite].length;
            }

        }
        
        if (data[_msgSender()][0] > 0) {
            uint256 claim;
            (claim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
            data[_msgSender()][2] = claim;
        }
        
        data[_msgSender()][0] = block.timestamp;
        data[_msgSender()][1] = block.timestamp;
        
        if (!mine[_msgSender()]) {
            mine[_msgSender()] = true;
            miners++;
        }
    }
    
    function doClaim() public {
        uint256 canClaim;
        (canClaim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
        canClaim += data[_msgSender()][3];
        require(canClaim >= 100000, "Not enough 100,000 CSD");
        require(totalSupply() + canClaim <= maxnum);
        
        if (canClaim > 0) {
            // _mint(backAddr, canClaim * backRate / 100);
            _mint(_msgSender(), canClaim);
            
            data[_msgSender()][1] = block.timestamp;
            data[_msgSender()][2] = 0;
            data[_msgSender()][3] = 0;
        }
    }

    function doRankingAward() public {
        for (uint32 i =0;i<rankingList.length;i++){
            if (i == 0) {
                // No.1 12 million
                data[rankingList[i].addr][3] += 12 * 10 ** 24; 
            } else if (i == 1) {
                // No.2 5 million
                data[rankingList[i].addr][3] += 5 * 10 ** 24; 
            } else if (i == 2){
                // No.3 2 million
                data[rankingList[i].addr][3] += 2 * 10 ** 24; 
            } else if (i >=3 && i <=9) {
                // No.4 ~ No.10 1 million
                data[rankingList[i].addr][3] += 1 * 10 ** 24; 
            } else {
                // No.11 ~ No.20 0.5 million
                data[rankingList[i].addr][3] += 0.5 * 10 ** 24; 
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}