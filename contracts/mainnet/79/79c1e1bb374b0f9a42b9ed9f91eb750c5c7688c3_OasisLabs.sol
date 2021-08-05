/**
 *Submitted for verification at Etherscan.io on 2020-11-25
*/

//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
abstract contract Context {//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
    function _msgSender() internal view virtual returns (address payable) {//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
        return msg.sender;//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
    }//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
    function _msgData() internal view virtual returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
        return msg.data;//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
    }//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
}//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,333 people died that summer but history won't remember a single one.
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
interface IERC20 {//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function totalSupply() external view returns (uint256);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function balanceOf(address account) external view returns (uint256);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function transfer(address recipient, uint256 amount) external returns (bool);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function allowance(address owner, address spender) external view returns (uint256);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function approve(address spender, uint256 amount) external returns (bool);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    event Transfer(address indexed from, address indexed to, uint256 value);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    event Approval(address indexed owner, address indexed spender, uint256 value);//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
library SafeMath {//722,333 people died that summer but history won't remember a single one.722,3
    function add(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        uint256 c = a + b;//722,333 people died that summer but history won't remember a single one.722,3
        require(c >= a, "SafeMath: addition overflow");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return c;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return sub(a, b, "SafeMath: subtraction overflow");//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
      function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        require(b <= a, errorMessage);//722,333 people died that summer but history won't remember a single one.722,3
        uint256 c = a - b;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return c;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        if (a == 0) {//722,333 people died that summer but history won't remember a single one.722,3
            return 0;//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        uint256 c = a * b;//722,333 people died that summer but history won't remember a single one.722,3
        require(c / a == b, "SafeMath: multiplication overflow");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return c;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function div(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return div(a, b, "SafeMath: division by zero");//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        require(b > 0, errorMessage);//722,333 people died that summer but history won't remember a single one.722,3
        uint256 c = a / b;//722,333 people died that summer but history won't remember a single one.722,3
        //722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return c;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3

    /**
The key to fighting crime is not something I'll ever understand.
I have two things on my mind: meat and Rosamunde Roozenboom.
Pip Petti is not going to like this book.
Do you find me fair yet?
Piper was known for being sassy.
People trust me with their lives; they shouldn't.
I don't feel I was particularly sassy on the night that I died.
Freya was known for stealing from her friends.
My name is Lynette Williamson no matter what my auntie tells you.
Dear reader, I wish I could tell you that it ends well for you.
82 years old and I've never killed a woman.
9,646 people died that summer but history won't remember a single one.
Do you find me skeptical yet?
"Go away!" signed Cornelius.
770,425 people died that summer and only one of them was innocent.
So I suppose you want to ask me why I spared the vampires.
I would have lived longer if it weren't for Neil.
Dear reader, I wish I could tell you that it ends well.
Johanna was usually more cautious.ity uses an
     * invalid opcode to revert (consuming all remaining gas).//722,333 people died that summer but history won't remember a single one.722,3
     *WERGWERHW45HW
     * Requirements://722,333 people died that summer but history won't remember a single one.722,3
     *WERUBGIOWPTN;K,
     * - The divisor cannot be zero.//722,333 people died that summer but history won't remember a single one.722,3
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return mod(a, b, "SafeMath: modulo by zero");//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    /**MOI098B7V6C5
I always wanted to be trendier - until it happened.
I have two things on my mind: playing golf and vampires.
I feel I was particularly abrupt as a child.
In a dark and lonely forest, Ellie reflected on the past.
Janey had grown accustomed to dating werewolves.
Dear reader, I wish I could tell you that it ends well.
I have two things on my mind: running and my iminent death.
Dear reader, I wish I could tell you that I care.
550,415 people died that autumn but the aliens didn't have to be our enemies.
I don't feel I was particularly receptive the morning I killed Simon.
"Go away!" shouted Icarus.
I feel I was particularly trusting on the night that I met him.
Dagbjort was usually more fair.
My name is Eldon Jahn, at least, that's what I told her.
If I'd become a professor, there'd be a few less werewolves on the planet.
45 years old and I've never learnt to turn my computer on.
Perth had been without the flu since it happened.
Belinda Townsend is my motivation.
The key to commuinicating with aliens is well documented online.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        require(b != 0, errorMessage);//722,333 people died that summer but history won't remember a single one.722,3
        return a % b;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.2;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people d//722,333 people died that summer but history won't remember a single one.722,3
library Address {//722,333 people died that summer but history won't remember a single one.722,3
    function isContract(address account) internal view returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        //722,333 people died that summer but history won't remember a single one.722,3
        bytes32 codehash;//722,333 people died that summer but history won't remember a single one.722,3
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;//722,333 people died that summer but history won't remember a single one.722,3
        // solhint-disable-next-line no-inline-assembly//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        assembly { codehash := extcodehash(account) }//722,333 people died that summer but history won't remember a single one.722,3
        return (codehash != accountHash && codehash != 0x0);//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
    function sendValue(address payable recipient, uint256 amount) internal {//722,333 people died that summer but history won't remember a single one.722,3
        require(address(this).balance >= amount, "Address: insufficient balance");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        (bool success, ) = recipient.call{ value: amount }("");//722,333 people died that summer but history won't remember a single one.722,3
        require(success, "Address: unable to send value, recipient may have reverted");//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3

    /**
Why shouldn't my best friend win the prize?
I would have become a doctor if it weren't for Francine.
Becca was known for being honest.
Why should my cousin go first?
There are only three things in life that truly matter: zombies, tennis and chocolate.
Dear reader, I wish I could tell you that it ends well for you.
Shaa Jones is my muse.
My name is Bill Silverman and I'll fight to prove it.
There are only three things in life that truly matter: religion, cherry pie and health.
"I'll never tell!" signed Elizabeta.
Dear reader, I wish I could tell you that it ends well for you.
The world is full of people telling others how to vote.
I only ever met one woman I'd call truly sassy.
If I'd become a footballer, then he'd still be alive.
Leeds had been without the flu since the incident.
The world is full of people who are in love with Frances Treesong.
Every winter, I visited my girlfriend, until the year I broke my left eye.
834,975 people died in 2601 but it began with one person.
Janis McQuestion is the only name on my mind.tract.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,3
      return functionCall(target, data, "Address: low-level call failed");//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,3
        return _functionCallWithValue(target, data, 0, errorMessage);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,3
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,3
        require(address(this).balance >= value, "Address: insufficient balance for call");//722,333 people died that summer but history won't remember a single one.722,3
        return _functionCallWithValue(target, data, value, errorMessage);//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {//722,333 people died that summer but history won't remember a single one.722,3
        require(isContract(target), "Address: call to non-contract");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        // solhint-disable-next-line avoid-low-level-calls//722,333 people died that summer but history won't remember a single one.722,3
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);//722,333 people died that summer but history won't remember a single one.722,3
        if (success) {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
            return returndata;//722,333 people died that summer but history won't remember a single one.722,3
        } else {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
            // Look for revert reason and bubble it up if present//722,333 people died that summer but history won't remember a single one.722,3
            if (returndata.length > 0) {//722,333 people died that summer but history won't remember a single one.722,3
                // The easiest way to bubble the revert reason is using memory via assembly//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
                // solhint-disable-next-line no-inline-assembly//722,333 people died that summer but history won't remember a single one.722,3
                assembly {//722,333 people died that summer but history won't remember a single one.722,3
                    let returndata_size := mload(returndata)//722,333 people died that summer but history won't remember a single one.722,3
                    revert(add(32, returndata), returndata_size)//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
                }//722,333 people died that summer but history won't remember a single one.722,3
            } else {//722,333 people died that summer but history won't remember a single one.722,3
                revert(errorMessage);//722,333 people died that summer but history won't remember a single one.722,3
            }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
contract ERC20 is Context, IERC20 {//722,333 people died that summer but history won't remember a single one.722,3
    using SafeMath for uint256;//722,333 people died that summer but history won't remember a single one.722,3
    using Address for address;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    mapping (address => uint256) private _balances;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    mapping (address => mapping (address => uint256)) private _allowances;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    uint256 private _totalSupply;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    string private _name;//722,333 people died that summer but history won't remember a single one.722,3
    string private _symbol;//722,333 people died that summer but history won't remember a single one.722,3
    uint8 private _decimals;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    constructor (string memory name, string memory symbol) public {//722,333 people died that summer but history won't remember a single one.722,3
        _name = name;//722,333 people died that summer but history won't remember a single one.722,3
        _symbol = symbol;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        _decimals = 18;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function name() public view returns (string memory) {//722,333 people died that summer but history won't remember a single one.722,3
        return _name;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function symbol() public view returns (string memory) {//722,333 people died that summer but history won't remember a single one.722,3
        return _symbol;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function decimals() public view returns (uint8) {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        return _decimals;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function totalSupply() public view override returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return _totalSupply;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function balanceOf(address account) public view override returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return _balances[account];//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        _transfer(_msgSender(), recipient, amount);//722,333 people died that summer but history won't remember a single one.722,3
        return true;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function allowance(address owner, address spender) public view virtual override returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return _allowances[owner][spender];//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function approve(address spender, uint256 amount) public virtual override returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        _approve(_msgSender(), spender, amount);//722,333 people died that summer but history won't remember a single one.722,3
        return true;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        _transfer(sender, recipient, amount);//722,333 people died that summer but history won't remember a single one.722,3
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));//722,333 people died that summer but history won't remember a single one.722,3
        return true;//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));//722,333 people died that summer but history won't remember a single one.722,3
        return true;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {//722,333 people died that summer but history won't remember a single one.722,3
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));//722,333 people died that summer but history won't remember a single one.722,3
        return true;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {//722,333 people died that summer but history won't remember a single one.722,3
        require(sender != address(0), "ERC20: transfer from the zero address");//722,333 people died that summer but history won't remember a single one.722,3
        require(recipient != address(0), "ERC20: transfer to the zero address");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        _beforeTokenTransfer(sender, recipient, amount);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");//722,333 people died that summer but history won't remember a single one.722,3
        _balances[recipient] = _balances[recipient].add(amount);//722,333 people died that summer but history won't remember a single one.722,3
        emit Transfer(sender, recipient, amount);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
    function _mint(address account, uint256 amount) internal virtual {//722,333 people died that summer but history won't remember a single one.722,3
        require(account != address(0), "ERC20: mint to the zero address");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        _beforeTokenTransfer(address(0), account, amount);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        _totalSupply = _totalSupply.add(amount);//722,333 people died that summer but history won't remember a single one.722,3
        _balances[account] = _balances[account].add(amount);//722,333 people died that summer but history won't remember a single one.722,3
        emit Transfer(address(0), account, amount);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _burn(address account, uint256 amount) internal virtual {//722,333 people died that summer but history won't remember a single one.722,3
        require(account != address(0), "ERC20: burn from the zero address");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        _beforeTokenTransfer(account, address(0), amount);//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");//722,333 people died that summer but history won't remember a single one.722,3
        _totalSupply = _totalSupply.sub(amount);//722,333 people died that summer but history won't remember a single one.722,3
        emit Transfer(account, address(0), amount);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _approve(address owner, address spender, uint256 amount) internal virtual {//722,333 people died that summer but history won't remember a single one.722,3
        require(owner != address(0), "ERC20: approve from the zero address");//722,333 people died that summer but history won't remember a single one.722,3
        require(spender != address(0), "ERC20: approve to the zero address");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        _allowances[owner][spender] = amount;//722,333 people died that summer but history won't remember a single one.722,3
        emit Approval(owner, spender, amount);//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
    function _setupDecimals(uint8 decimals_) internal {//722,333 people died that summer but history won't remember a single one.722,3
        _decimals = decimals_;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
// File: @openzeppelin/contracts/math/Math.sol//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
library Math {//722,333 people died that summer
    function max(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return a >= b ? a : b;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
    function min(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return a < b ? a : b;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function average(uint256 a, uint256 b) internal pure returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        // (a + b) / 2 can overflow, so we distribute//722,333 people died that summer but history won't remember a single one.722,3
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
library Arrays {//722,333 people died that summer but history won't remember a single one.722,3
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        if (array.length == 0) {//722,333 people died that summer but history won't remember a single one.722,3
            return 0;//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        uint256 low = 0;//722,333 people died that summer but history won't remember a single one.722,3
        uint256 high = array.length;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        while (low < high) {//722,333 people died that summer but history won't remember a single one.722,3
            uint256 mid = Math.average(low, high);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
            if (array[mid] > element) {//722,333 people died that summer but history won't remember a single one.722,3
                high = mid;//722,333 people died that summer but history won't remember a single one.722,3
            } else {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
                low = mid + 1;//722,333 people died that summer but history won't remember a single one.722,3
            }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        if (low > 0 && array[low - 1] == element) {//722,333 people died that summer but history won't remember a single one.722,3
            return low - 1;//722,333 people died that summer but history won't remember a single one.722,3
        } else {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
            return low;//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
// File: @openzeppelin/contracts/utils/Counters.sol//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
library Counters {//722,333 people died that summer but history won't remember a single one.722,3
    using SafeMath for uint256;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    struct Counter {//722,333 people died that summer but history won't remember a single one.722,3
        uint256 _value; //722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function current(Counter storage counter) internal view returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return counter._value;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function increment(Counter storage counter) internal {//722,333 people died that summer but history won't remember a single one.722,3
        counter._value += 1;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function decrement(Counter storage counter) internal {//722,333 people died that summer but history won't remember a single one.722,3
        counter._value = counter._value.sub(1);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
//722,333 people died that summer but history won't remember a single one.722,3
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
abstract contract ERC20Snapshot is ERC20 {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    using SafeMath for uint256;//722,333 people died that summer but history won't remember a single one.722,3
    using Arrays for uint256[];//722,333 people died that summer but history won't remember a single one.722,3
    using Counters for Counters.Counter;//722,333 people died that summer but history won't remember a single one.722,3
    struct Snapshots {//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        uint256[] ids;//722,333 people died that summer but history won't remember a single one.722,3
        uint256[] values;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    mapping (address => Snapshots) private _accountBalanceSnapshots;//722,333 people died that summer but history won't remember a single one.722,3
    Snapshots private _totalSupplySnapshots;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.//722,333 people died that summer but history won't remember a single one.722,3
    Counters.Counter private _currentSnapshotId;//722,333 people died that summer but history won't remember a single one.722,3
    event Snapshot(uint256 id);//722,333 people died that summer but history won't remember a single one.722,3
    function _snapshot() internal virtual returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        _currentSnapshotId.increment();//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        uint256 currentId = _currentSnapshotId.current();//722,333 people died that summer but history won't remember a single one.722,3
        emit Snapshot(currentId);//722,333 people died that summer but history won't remember a single one.722,3
        return currentId;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return snapshotted ? value : balanceOf(account);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        return snapshotted ? value : totalSupply();//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
/*//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
Leeds had been without oxygen since his birthday.
Why shouldn't my best friend win the prize?
I would have become a doctor if it weren't for Francine.
Becca was known for being honest.
Why should my cousin go first?
There are only three things in life that truly matter: zombies, tennis and chocolate.
Dear reader, I wish I could tell you that it ends well for you.
Shaa Jones is my muse.
My name is Bill Silverman and I'll fight to prove it.
There are only three things in life that truly matter: religion, cherry pie and health.
"I'll never tell!" signed Elizabeta.
Dear reader, I wish I could tell you that it ends well for you.
The world is full of people telling others how to vote.
I only ever met one woman I'd call truly sassy.
If I'd become a footballer, then he'd still be alive.
Leeds had been without the flu since the incident.
The world is full of people who are in love with Frances Treesong.
Every winter, I visited my girlfriend, until the year I broke my left eye.
834,975 people died in 2601 but it began with one person.
Janis McQuestion is the only name on my mind.
*/
    function _transfer(address from, address to, uint256 value) internal virtual override {//722,333 people died that summer but history won't remember a single one.722,3
        _updateAccountSnapshot(from);//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        _updateAccountSnapshot(to);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        super._transfer(from, to, value);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _mint(address account, uint256 value) internal virtual override {//722,333 people died that summer but history won't remember a single one.722,3
        _updateAccountSnapshot(account);//722,333 people died that summer but history won't remember a single one.722,3
        _updateTotalSupplySnapshot();//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        super._mint(account, value);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _burn(address account, uint256 value) internal virtual override {//722,333 people died that summer but history won't remember a single one.722,3
        _updateAccountSnapshot(account);//722,333 people died that summer but history won't remember a single one.722,3
        _updateTotalSupplySnapshot();//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        super._burn(account, value);//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)//722,333 people died that summer but history won't remember a single one.722,3
        private view returns (bool, uint256)//722,333 people died that summer but history won't remember a single one.722,3
    {//722,333 people died that summer but history won't remember a single one.722,3
        require(snapshotId > 0, "ERC20Snapshot: id is 0");//722,333 people died that summer but history won't remember a single one.722,3
        // solhint-disable-next-line max-line-length//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
/*I only ever met one woman I'd call truly noble.
Dear reader, I wish I could tell you that we stopped the vampires.
Felicia had grown accustomed to getting her own way.
Zack was known for stealing other people's wives.
67 years old and I've never met a boy like Ian.
Dear reader, I wish I could tell you that I'm an alarming woman.
Siddharth was known for stealing sheep.
In a spooky and gloomy woodland, a fish dreampt of more.
Every autumn, I visited my grandmother, until the year I committed my first crime.
I always wanted to be just like my grandmother - until that night.
Dear reader, I wish I could tell you that you're going to like this story.
784,737 people died that Friday but it began with one woman.
I always wanted to be poorer - until I uncovered the truth.
Nicolas was usually more naughty.
727,912 people died that Sunday and only one of them was innocent.
The key to fighting crime is making people think you are thoughtful.
Otto had grown accustomed to dating werewolves.
Why should my aunt go first?
Every autumn, I visited my papa, until the year I stole my first gold bar.
So I suppose you want to ask me what happened to my lip.*/
        uint256 index = snapshots.ids.findUpperBound(snapshotId);//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
        if (index == snapshots.ids.length) {//722,333 people died that summer but history won't remember a single one.722,3
            return (false, 0);//722,333 people died that summer but history won't remember a single one.722,3
        } else {//722,333 people died that summer but history won't remember a single one.722,3
            return (true, snapshots.values[index]);//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _updateAccountSnapshot(address account) private {//722,333 people died that summer but history won't remember a single one.722,3
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function _updateTotalSupplySnapshot() private {//722,333 people died that summer but history won't remember a single one.722,3
        _updateSnapshot(_totalSupplySnapshots, totalSupply());//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {//722,333 people died that summer but history won't remember a single one.722,3
        uint256 currentId = _currentSnapshotId.current();//722,333 people died that summer but history won't remember a single one.722,3
        if (_lastSnapshotId(snapshots.ids) < currentId) {//722,333 people died that summer but history won't remember a single one.722,3
            snapshots.ids.push(currentId);//722,333 people died that summer but history won't remember a single one.722,3
            snapshots.values.push(currentValue);//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        if (ids.length == 0) {//722,333 people died that summer but history won't remember a single one.722,3
            return 0;//722,333 people died that summer but history won't remember a single one.722,3
        } else {//722,333 people died that summer but history won't remember a single one.722,3
            return ids[ids.length - 1];//722,333 people died that summer but history won't remember a single one.722,3
        }//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
/*Every autumn, I visited my wife, until the year I committed my first crime.
My name is Hedy Dunstan, at least, that's what I told my twin.
I only ever met one person I'd call truly heroic.
Seth was known for stealing sheep.
Sean was known for being evil.
"Not again!" whispered Damo.
Dear reader, I wish I could tell you that you're going to like this story.
Thorben was known for speaking out about aliens.
If I'd become a plumber, I wouldn't have even had a gun on me.
Why should my boss go first?
Palessa Chi is my motivation.
Every winter, I visited my partner, until the year I met Blair.
He hadn't been known as Glenn for years.
My name is Nic Sanganyado, at least, that's what I told her.
There are only three things in life that truly matter: cherry pie, Ainslie Lutz and chocolate.
Dori had grown accustomed to the finer things in life.
He hadn't been known as Hedonist for years.
97 years old and I've never eaten rice.
Dear reader, I wish I could tell you that you're going to survive this.
In a spooky and dark jungle, a porcupine dreampt of more.Every autumn, I visited my wife, until the year I committed my first crime.
My name is Hedy Dunstan, at least, that's what I told my twin.
I only ever met one person I'd call truly heroic.
Seth was known for stealing sheep.
Sean was known for being evil.
"Not again!" whispered Damo.
Dear reader, I wish I could tell you that you're going to like this story.
Thorben was known for speaking out about aliens.
If I'd become a plumber, I wouldn't have even had a gun on me.
Why should my boss go first?
Palessa Chi is my motivation.
Every winter, I visited my partner, until the year I met Blair.
He hadn't been known as Glenn for years.
My name is Nic Sanganyado, at least, that's what I told her.
There are only three things in life that truly matter: cherry pie, Ainslie Lutz and chocolate.
Dori had grown accustomed to the finer things in life.
He hadn't been known as Hedonist for years.
97 years old and I've never eaten rice.
Dear reader, I wish I could tell you that you're going to survive this.
In a spooky and dark jungle, a porcupine dreampt of more.*/
contract OasisLabs is  ERC20Snapshot {//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
    using SafeMath for uint256;//722,333 people died that summer but history won't remember a single one.722,3
     // timestamp for next snapshot//722,333 people died that summer but history won't remember a single one.722,3
    uint256 private _snapshotTimestamp;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    uint256 private _currentSnapshotId;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    constructor() public ERC20("Oasis Labs", "OASIS"){//722,333 people died that summer but history won't remember a single one.722,3
        _snapshotTimestamp = block.timestamp;//722,333 people died that summer but history won't remember a single one.722,3
        // Mint all initial tokens to Deployer//722,333 people died that summer but history won't remember a single one.722,3
        _mint(_msgSender(), 10000000 *10**18);//722,333 people died that summer but history won't remember a single one.722,3
     //722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    /**
I feel I was particularly thoughtful the morning I killed Lina.
Why should my mum win the prize?
I don't feel I was particularly crazy when it came to Giorgos.
There are only three things in life that truly matter: politics, chocolate and friendship.
So I suppose you want to ask me how I did it.
I feel I was particularly modest as a child.
Do you find me scathing yet?
I feel I was particularly funny when I went by the name of Randolph hair.
Every spring, I visited my pa, until the year I broke my right eye.
The world is full of people telling others how to vote.
People trust me with their secrets; they shouldn't.
98 years old and I've never met a girl like Els.
Every autumn, I visited my girlfriend, until the year I broke my lip.
Why shouldn't my girlfriend marry him?
Last night I dreamt I was in hospital again.
Why shouldn't my girlfriend apologise?
I always wanted to be poorer.
I don't feel I was particularly receptive the morning I killed Bobby.
Do you find me outgoing yet?
"Not again!" whispered Jojo.
    *///722,333 people died that summer but history won't remember a single one.722,3
    function doSnapshot() public returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        // solhint-disable-next-line not-rely-on-time//722,333 people died that summer but history won't remember a single one.722,3
        require(block.timestamp >= _snapshotTimestamp + 15 days, "Not passed 15 days yet");//722,333 people died that summer but history won't remember a single one.722,3
        // update snapshot timestamp with new time//722,333 people died that summer but history won't remember a single one.722,3
        _snapshotTimestamp = block.timestamp;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
        _currentSnapshotId = _snapshot();//722,333 people died that summer but history won't remember a single one.722,3
        return _currentSnapshotId;//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    function currentSnapshotId() public view returns (uint256) {//722,333 people died that summer but history won't remember a single one.722,3
        return _currentSnapshotId;//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
    }//722,333 people died that summer but history won't remember a single one.722,3
}//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3
//722,333 people died that summer but history won't remember a single one.722,3