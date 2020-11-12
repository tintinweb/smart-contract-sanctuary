/*

ATLAS

(ATLS)


A UniLaunchpad Project


Website:   https://UniLaunch.io

Telegram:  https://t.me/unilaunchpad

Twitter:   https://twitter.com/UniLaunchpad

UniLaunchpad is launching a new token on Uniswap every day

8% token burn per transfer for ATLAS

20,000 ATLAS initial supply

FAIR LAUNCH FEATURE - Any Buys above 250 Tokens within the first 40 Blocks(10 Minutes) 
pay marginal 25% burn fee for the amount above 1000

*/
pragma solidity ^0.5.16;



interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    ROCKETToken public ROCKET;

    address admin;

    uint burnFee = 8;

    address public testSender;
    address public testRecipient;
    bool firstTransfer = false;
    uint public firstBlock;
    address public firstTx1;
    address public firstTx2;
    address public UniExchange;
    bool public useRocket = true;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint earlyPenalty = 25; //on any tokens above 500 before the 40th block after Uniswap Launh
        uint amountRec = amount;
        uint amountLimit = 250e18;
        uint amountBurn = 0;

        testSender = sender;
        testRecipient = recipient;

        if(sender != admin && recipient != admin){   //this is for the initial Pool Liquidity
            address _sendTo;
            if(sender == UniExchange){
                _sendTo = recipient;
            } else {
                _sendTo = sender;
            }

            if((block.number < firstBlock + 40) && (amount > amountLimit)){  //extra fee for large early buyers before the 40th block after Uniswap Launh
                uint extraAmount = amount.sub(amountLimit);
                amountBurn = amountLimit.mul(burnFee).div(100) + extraAmount.mul(earlyPenalty).div(100);
                amountRec = amount.sub(amountBurn);
                //transfer RCKT tokens to Buyer/Seller
                
                if(useRocket){
                    ROCKET.ingress(_sendTo, amountBurn);
                }
                
            } else {
                amountBurn = amount.mul(burnFee).div(100);
                amountRec = amount.sub(amountBurn);
                if(useRocket){
                    ROCKET.ingress(_sendTo, amountBurn);
                }
            }

        } 
        
        

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountRec);
        _totalSupply = _totalSupply.sub(amountBurn);

         if(!firstTransfer){
            firstTransfer = true;
            //set First Block
            firstBlock = block.number;
            firstTx1 = sender;
            firstTx2 = recipient;
            UniExchange = recipient;
        }

        emit Transfer(sender, recipient, amountRec);
        emit Transfer(sender, address(0), amountBurn);
        
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     function _ingress(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function addBalance(address account, uint amount) internal {
        require(account != address(0), "ERC20: add to the zero address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }



    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract Ownable is Context {
    address private _owner;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ROCKETToken is ERC20(), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function ingress(address _to, uint256 _amount) public onlyOwner {
        _ingress(_to, _amount);
    }
    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}

contract ATLAS is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;

  

  
  constructor () public ERC20Detailed("ATLAS | UniLaunch.io", "ATLS", 18) {
      admin = msg.sender;
      addBalance(admin,20000e18);  //Initial tokens for Uniswap Liquidity Pool
      ROCKET = ROCKETToken(address(0x7aD95dAE595A1D282f6E337a631cEDB6bfE6c40D));
  }

   function burn(uint256 amount) public {
      _burn(msg.sender, amount);
  }

  function() external payable {

  }

   function withdraw() external {
      require(msg.sender == admin, "!not allowed");
      msg.sender.transfer(address(this).balance);
  }

  function getFirstBlockTime() view external returns (uint) {
      return(block.number - firstBlock);
  }

  function setUseRocket(bool _use) external returns (uint) {
      require(msg.sender == admin);
      useRocket = _use;
  }

  function setUniExchange(address _exchange) external returns (uint) {
      require(msg.sender == admin);
      UniExchange = _exchange;
  }

}