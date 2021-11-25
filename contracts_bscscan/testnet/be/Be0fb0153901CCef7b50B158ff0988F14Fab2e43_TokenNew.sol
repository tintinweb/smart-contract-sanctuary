//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.4;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // The account hash of 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for non-contract addresses,
        // so-called Externally Owned Account (EOA)
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

contract TokenNew is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "TokenNew";
    string private _symbol = "TKNN";
    uint8 private _decimals = 9;

    struct tokenHolders {
        address[] addresses;
        mapping(address => uint256) valuesBefore;
        mapping(address => uint256) valuesAfterGross;
        mapping(address => uint256) valuesAfterNet;
        mapping(address => uint256) amountToTrasfer;
        mapping(address => uint256) valuesReflections;
        mapping(address => uint256) valuesReflectionsAccumulated;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
        mapping(address => bool) updated;
        mapping(address => uint) lastSellTransferTime;
        mapping(address => uint) claimTime;
    }
    tokenHolders private tokenHolder;

    mapping (address => uint256) private _reflectionBalance;
    mapping (address => uint256) private _tokenBalance;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tokenTotal = 100_000_000_000e9; // TOTAL AMOUNT : 100.000.000.000 tokens
    uint256 private _reflectionTotal = (MAX - (MAX % _tokenTotal));
    uint256 private _tokenCirculatingTotal = 100_000_000_000e9; // totale crcolante espresso come somma dei balance degli holders esclusi i token in liquidity
    uint256 private _tokenNoSellTotal = 100_000_000_000e9; // totale dei token posseduti da holders che non hanno mai venduto

    mapping(address => bool) private _blacklisted; // non può usare più la funzione _transfer quindi non può ne vendere ne comprare
    mapping (address => bool) private _isExcludedFromTaxFee;
    mapping (address => bool) private _isExcludedFromForBuyFee;
    mapping (address => bool) private _isExcludedFromAntiSellFee;
    mapping (address => bool) private _isExcludedFromReward; // esclusione dal reward
    address[] private _excludedFromReward;
    address[] private _tokenHolders;
    uint256 _refrectionsToContract;

    bool private _autoMode = false; // allo start disattiva il calcolo della Anti Sell fee tramite Oracolo
    uint256 private _antiSellFeeFromOracle = 5; // variable% taxation in BNB to avoid Sells
    uint256 private _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;

    uint256 private _taxFee = 5; // 5% redistribuition
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _forBuyFee = 5; // 5% forBuy fee divisa tra NFT Fee pari al 2% e Marketing Fee pari al 3%
    uint256 private _previousForBuyFee = _forBuyFee;

    uint256 private _taxfeeTotal;
    uint256 private _buybackTotal;

    bool private _tradingIsEnabled = true;
    bool private _isDistribuitionInWethEnabled = true;
    bool private _inSwapAndLiquify;

    uint256 private _maxTxAmount = 200_000_000e9; // Max transferrable in one transaction (0,2% of _tokenTotal)
    uint256 private _minTokensBeforeSwap = 200_000e9; // una volta accumulati questi token li bende e fa lo swap
    // trasformandoli in BNB mandandoli nel wallet buyBack, dovrebbe causare un crollo dello 0,04% della curva del prezzo

    address private _antiDipAddress = 0xFebCfaAFF11edA4Ba94C9788c28567e2FEA6237C; ///
    address private _marketingAddress = 0xFebCfaAFF11edA4Ba94C9788c28567e2FEA6237C; ///
    address private _forBuyAddress = address(this); // For Buy address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _antiSellAddress = address(this); // Anti Sell address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _nftContractAddress = 0xBfbEbbe212768Cd9C3ECb1cd766d9f02F4dd84ba; // indirizzo del contratto Polygon NFT
    
    uint256 private _marketingWalletPercent = 16;
    uint256 private _nftWalletPercent = 8;
    uint256 private _antiDipToReflectToHoldersWalletPercent = 15;
    uint256 private _taxFeeWalletPercent = 16;
    uint256 private _antiDipWalletPercent = 45;
    
    uint private _startBlockClaim;
    uint private _periodFromStartBlockClaim;
    uint256 private _balanceNeededClaim;

    address public RouterPancakeSwapV2Mainnet = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public RouterPancakeSwapV2Testnet = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    modifier onlyNftContarctOwner() {
        require(_msgSender() == _nftContractAddress, "caller is not the owner ok NFT contract");
        _;
    }

    constructor ()  {
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(RouterPancakeSwapV2Testnet);
        //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        //uniswapV2Router = _uniswapV2Router;

        _reflectionBalance[_msgSender()] = _reflectionTotal;

        // inerisce l'owner tra gli holders
        tokenHolder.inserted[_msgSender()] = true;
        tokenHolder.updated[_msgSender()] = true;
        tokenHolder.valuesBefore[_msgSender()] = _tokenTotal;
        tokenHolder.valuesAfterGross[_msgSender()] = _tokenTotal;
        tokenHolder.valuesAfterNet[_msgSender()] = _tokenTotal;
        tokenHolder.amountToTrasfer[_msgSender()] = 0;
        tokenHolder.valuesReflections[_msgSender()] = 0;
        tokenHolder.valuesReflectionsAccumulated[_msgSender()] = 0;
        tokenHolder.indexOf[_msgSender()] = tokenHolder.addresses.length;
        tokenHolder.lastSellTransferTime[_msgSender()] = 0;
        tokenHolder.claimTime[_msgSender()] = 0;
        tokenHolder.addresses.push(_msgSender());
        
        // inerisce address(this), cioè il contratto, tra gli holders
        tokenHolder.inserted[address(this)] = true;
        tokenHolder.updated[address(this)] = true;
        tokenHolder.valuesBefore[address(this)] = 0;
        tokenHolder.valuesAfterGross[address(this)] = 0;
        tokenHolder.valuesAfterNet[address(this)] = 0;
        tokenHolder.amountToTrasfer[address(this)] = 0;
        tokenHolder.valuesReflections[address(this)] = 0;
        tokenHolder.valuesReflectionsAccumulated[address(this)] = 0;
        tokenHolder.indexOf[address(this)] = tokenHolder.addresses.length;
        tokenHolder.lastSellTransferTime[address(this)] = 0;
        tokenHolder.claimTime[address(this)] = 0;
        tokenHolder.addresses.push(address(this));

        //exclude owner and this contract from taxFee
        _isExcludedFromTaxFee[owner()] = true;
        _isExcludedFromTaxFee[address(this)] = true;
        //_isExcludedFromTaxFee[_forBuyAddress] = true;
        //_isExcludedFromTaxFee[_antiSellAddress] = true;

        //exclude owner and this contract from forBuyFee
        _isExcludedFromForBuyFee[owner()] = true;
        _isExcludedFromForBuyFee[address(this)] = true;
        //_isExcludedFromForBuyFee[_forBuyAddress] = true;
        //_isExcludedFromForBuyFee[_antiSellAddress] = true;

        //exclude owner and this contract from Anti Sell fee
        _isExcludedFromAntiSellFee[owner()] = true;
        _isExcludedFromAntiSellFee[address(this)] = true;
        //_isExcludedFromAntiSellFee[_forBuyAddress] = true;
        //_isExcludedFromAntiSellFee[_antiSellAddress] = true;

        //exclude il pair uniswap dal reward
        _isExcludedFromReward[uniswapV2Pair] = true;
        _excludedFromReward.push(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: mint to the zero address");
        _tokenTotal = _tokenTotal.add(_amount);
         if (_isExcludedFromReward[_account]) {
           _tokenBalance[_account].add(_amount);
         }
         else
         {
            _reflectionBalance[_account].add(_amount);
         }
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: burn from the zero address");
        require(_tokenTotal >= _amount, "BEP20: total supply must be >= amout");
        _tokenTotal = _tokenTotal.sub(_amount);
         if (_isExcludedFromReward[_account]) {
              require(_tokenBalance[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _tokenBalance[_account].sub(_amount);
         }
         else
         {
              require(_reflectionBalance[_account] >= _amount, "BEP20: the balance of account must be >= of amount");
             _reflectionBalance[_account].sub(_amount);
         }
        emit Transfer(_account, address(0), _amount);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function get_AntiDipAddress() external view returns (address) {
        return _antiDipAddress;
    }
    
    function get_MarketingAddress() external view returns (address) {
        return _marketingAddress;
    }

    function get_ContractAddress() external view returns (address) {
        return address(this);
    }

    function get_TaxFee() external view returns (uint256) {
        return _taxFee;
    }

    function get_ForBuyFee() external view returns (uint256) {
        return _forBuyFee;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenTotal;
    }

    function get_maxTXAmountPerTransfer() external view returns (uint256) {
        return _maxTxAmount;
    }

    function get_AntiSellAutoFromOracle() external view returns (bool) {
        return _autoMode;
    }

    function get_antiSellFeeFromOracle() external view returns (uint256) {
        return _antiSellFeeFromOracle;
    }

    function set_antiSellFeeFromOracle(uint256 antiSellFeeFromOracle) external onlyOwner returns (uint256) {
        _antiSellFeeFromOracle = antiSellFeeFromOracle;
        return _antiSellFeeFromOracle;
    }
    
    function get_marketingWalletPercent() external view returns (uint256) {
        return _marketingWalletPercent;
    }
    
    function get_nftWalletPercent() external view returns (uint256) {
        return _nftWalletPercent;
    }
    
    function get_antiDipToReflectToHoldersWalletPercent() external view returns (uint256) {
        return _antiDipToReflectToHoldersWalletPercent;
    }
    
    function get_taxFeeWalletPercent() external view returns (uint256) {
        return _taxFeeWalletPercent;
    }
    
    function get_antiDipWalletPercent() external view returns (uint256) {
        return _antiDipWalletPercent;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function set_PresaleParameters (
      uint256 _MaxTXPerThousand,
      //address payable _newForBuyAddress,
      //address payable _newAntiSellAddress,
      address payable _newAntiDipAddress,
      address payable _newMarketingAddress,
      address _newNftContractAddress,
      bool _antiSellAutoFromOracle

    ) external onlyOwner {
        removeTaxFee();
        removeForBuyFee();
        removeAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a false
        set_MaxTxPerThousand(_MaxTXPerThousand);
        set_TradingIsEnabled(false);
        set_DistribuitionInWethEnabled(false);
        changeAntiDipAddress(_newAntiDipAddress);
        changeMarketingAddress(_newMarketingAddress);
        changeNftContractAddress(_newNftContractAddress);
    }

    function set_PancakeSwapParameters (
      uint256 _MaxTXPerThousand,
      bool _antiSellAutoFromOracle,
      bool _enableTrading,
      bool _enableDistribuitionInWeth,
      uint256 _marketingWalletPerc,
      uint256 _nftWalletPerc,
      uint256 _antiDipToReflectToHoldersWalletPerc,
      uint256 _taxFeeWalletPerc,
      uint256 _antiDipWalletPerc

    ) external onlyOwner {
        restoreTaxFee();
        restoreForBuyFee();
        restoreAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a true
        set_MaxTxPerThousand(_MaxTXPerThousand);
        set_TradingIsEnabled(_enableTrading); // mettere a true se si vuole tradare
        set_DistribuitionInWethEnabled(_enableDistribuitionInWeth); // mettere a true se si vuole swappare ed inviare reflections
        changeMarketingWalletPercent(_marketingWalletPerc); // impostare a 16 per avere 16% del contenuto del wallet antidip
        changeNftWalletPercent(_nftWalletPerc); // impostare a 8 per avere 8% del contenuto del wallet antidip
        changeAntiDipToReflectToHoldersWalletPercent(_antiDipToReflectToHoldersWalletPerc); // impostare a 15 per avere 15% del contenuto del wallet antidip
        changeTaxFeeWalletPercent(_taxFeeWalletPerc); // impostare a 16 per avere 16% del contenuto del wallet antidip
        changeAntiDipWalletPercent(_antiDipWalletPerc); // impostare a 45 per avere 45% del contenuto del wallet antidip
    }

    function randomNumber() public view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BNB20: transfer amount exceeds allowance"));
        _transfer2(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BNB20: decreased allowance below zero"));
        return true;
    }
    
    function isBlackListed(address account) public view returns (bool) {
        return _blacklisted[account];
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function calculateTotalTaxFee() external view returns (uint256) {
        return _taxfeeTotal;
    }

    function calculateTotalBuyBack() external view returns (uint256) {
        return _buybackTotal;
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns(uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return reflectionAmount.div(currentRate);
    }
    
    function reflectionFromToken(uint256 tokenAmount) public view returns(uint256) {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        uint256 currentRate =  _getRate();
        return tokenAmount.mul(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(_reflectionBalance[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tokenBalance[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromTaxFee(address account) external onlyOwner {
        _isExcludedFromTaxFee[account] = true;
    }

    function includeInTaxFee (address account) external onlyOwner {
        _isExcludedFromTaxFee[account] = false;
    }

    function excludeFromForBuyFee(address account) external onlyOwner {
        _isExcludedFromForBuyFee[account] = true;
    }

    function includeInForBuyFee (address account) external onlyOwner {
        _isExcludedFromForBuyFee[account] = false;
    }

    function excludeFromAntiSellFee(address account) external onlyOwner {
        _isExcludedFromAntiSellFee[account] = true;
    }

    function includeInAntiSellFee(address account) external onlyOwner {
        _isExcludedFromAntiSellFee[account] = false;
    }

    function includeInBlacklist(address account) external onlyOwner {
        _blacklisted[account] = true;
    }

    function excludeFromBlacklist(address account) external onlyOwner {
        _blacklisted[account] = false;
    }

    function set_FeePercent(uint256 taxFee, uint256 forBuyFee) public onlyOwner {
        _taxFee = taxFee;
        _forBuyFee = forBuyFee;
    }

    function set_AntiSellAutoFromOracle(bool autoMode) public onlyOwner {
        _autoMode = autoMode;
    }

    function set_MaxTxPerThousand(uint256 maxTxThousand) public onlyOwner { // expressed in per thousand and not in percent
        _maxTxAmount = _tokenTotal.mul(maxTxThousand).div(10**3);
    }

    function changeAntiDipAddress(address payable _newaddress) public onlyOwner {
        _antiDipAddress = _newaddress;
    }
    
    function changeMarketingAddress(address payable _newaddress) public onlyOwner {
        _marketingAddress = _newaddress;
    }

    function changeNftContractAddress(address _newaddress) public onlyOwner {
        _nftContractAddress = _newaddress;
    }
    
    function changeMarketingWalletPercent(uint256  _newpercent) public onlyOwner {
        _marketingWalletPercent = _newpercent;
    }
    
    function changeNftWalletPercent(uint256  _newpercent) public onlyOwner {
        _nftWalletPercent = _newpercent;
    }
    
    function changeAntiDipToReflectToHoldersWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipToReflectToHoldersWalletPercent = _newpercent;
    }
    
    function changeTaxFeeWalletPercent(uint256  _newpercent) public onlyOwner {
        _taxFeeWalletPercent = _newpercent;
    }
    
    function changeAntiDipWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipWalletPercent = _newpercent;
    }
    
    function set_MinTokensBeforeSwap(uint256 amount) external onlyOwner {
        _minTokensBeforeSwap = amount;
    }

    function _updateTaxFeeTotal(uint256 rFee, uint256 tFee) private {
        _reflectionTotal = _reflectionTotal.sub(rFee);
        _taxfeeTotal = _taxfeeTotal.add(tFee);
    }
    
    function set_WalletsPercent(
        uint256 _marketingWallPercent,
        uint256 _nftWallPercent,
        uint256 _antiDipToReflectToHoldersWallPercent,
        uint256 _taxFeeWallPercent,
        uint256 _antiDipWallPercent
        ) external onlyOwner {
            
        _marketingWalletPercent = _marketingWallPercent;
        _nftWalletPercent = _nftWallPercent;
        _antiDipToReflectToHoldersWalletPercent = _antiDipToReflectToHoldersWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _antiDipWalletPercent = _antiDipWallPercent;
    }
    
    function _updateBuyBackTotal(uint256 tForBuy, uint256 tAntiSell) private {
        _buybackTotal = _buybackTotal.add(tForBuy).add(tAntiSell);
    }
    
    function set_TradingIsEnabled(bool enabled) public onlyOwner {
        _tradingIsEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function get_radingIsEnabled() external view returns (bool) {
        return _tradingIsEnabled;
    }
    
    function set_DistribuitionInWethEnabled(bool enabled) public onlyOwner {
        _isDistribuitionInWethEnabled = enabled;
    }

    function get_DistribuitionInWethEnabled() external view returns (bool) {
        return _isDistribuitionInWethEnabled;
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni di get per il transfer ////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tForBuy = calculateForBuyFee(tAmount);
        uint256 tAntiSell = calculateAntiSellFee(tAmount);
        uint256 totaltFees = tFee.add(tForBuy).add(tAntiSell);
        uint256 tTransferAmount = tAmount.sub(totaltFees);
        return (tTransferAmount, tForBuy, tAntiSell, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tForBuy, uint256 tAntiSell, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 reflectionAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rForBuy = tForBuy.mul(currentRate);
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        uint256 totalrFees = rFee.add(rForBuy).add(rAntiSell);
        uint256 rTransferAmount = reflectionAmount.sub(totalrFees);
        return (reflectionAmount, rTransferAmount, rFee);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni di get per il transferfrom ////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getTValues2(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee2(tAmount);
        uint256 tForBuy = calculateForBuyFee2(tAmount);
        uint256 tAntiSell = calculateAntiSellFee2(tAmount);
        uint256 totaltFees = tFee.add(tForBuy).add(tAntiSell);
        uint256 tTransferAmount = tAmount.sub(totaltFees);
        return (tTransferAmount, tForBuy, tAntiSell, tFee);
    }

    function _getRValues2(uint256 tAmount, uint256 tFee, uint256 tForBuy, uint256 tAntiSell, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 reflectionAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rForBuy = tForBuy.mul(currentRate);
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        uint256 totalrFees = rFee.add(rForBuy).add(rAntiSell);
        uint256 rTransferAmount = reflectionAmount.sub(totalrFees);
        return (reflectionAmount, rTransferAmount, rFee);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// funzioni di get comuni //////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _tokenTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_reflectionBalance[_excludedFromReward[i]] > rSupply || _tokenBalance[_excludedFromReward[i]] > tSupply) return (_reflectionTotal, _tokenTotal);
            rSupply = rSupply.sub(_reflectionBalance[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tokenBalance[_excludedFromReward[i]]);
        }
        if (rSupply < _reflectionTotal.div(_tokenTotal)) return (_reflectionTotal, _tokenTotal);
        return (rSupply, tSupply);
    }

    function _takeForBuy(uint256 tForBuy) private {
        uint256 currentRate =  _getRate();
        uint256 rForBuy = tForBuy.mul(currentRate);
        _reflectionBalance[_forBuyAddress] = _reflectionBalance[_forBuyAddress].add(rForBuy);
        if(_isExcludedFromReward[_forBuyAddress])
            _tokenBalance[_forBuyAddress] = _tokenBalance[_forBuyAddress].add(tForBuy);
    }

    function _takeAntiSell(uint256 tAntiSell) private {
        uint256 currentRate =  _getRate();
        uint256 rAntiSell = tAntiSell.mul(currentRate);
        _reflectionBalance[_antiSellAddress] = _reflectionBalance[_antiSellAddress].add(rAntiSell);
        if(_isExcludedFromReward[_antiSellAddress])
            _tokenBalance[_antiSellAddress] = _tokenBalance[_antiSellAddress].add(tAntiSell);
    }
//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transfer /////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee(uint256 _amount) private pure returns (uint256) {
        return _amount.mul(0).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transferfrom /////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_antiSellFeeFromOracle).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////

    function removeTaxFee() private {
        if(_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function removeForBuyFee() private {
        if(_forBuyFee == 0) return;
        _previousForBuyFee = _forBuyFee;
        _forBuyFee = 0;
    }

    function removeAntiSellFee() private {
        if(_antiSellFeeFromOracle == 0) return;
        _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;
        _antiSellFeeFromOracle = 0;
    }

    function restoreTaxFee() private {
        _taxFee = _previousTaxFee;
    }

    function restoreForBuyFee() private {
        _forBuyFee = _previousForBuyFee;
    }

    function restoreAntiSellFee() private {
        _antiSellFeeFromOracle = _previousAntiSellFeeFromOracle;
    }

    function isExcludedFromTaxFee(address account) external view returns(bool) {
        return _isExcludedFromTaxFee[account];
    }

    function isExcludedFromForBuyFee(address account) external view returns(bool) {
        return _isExcludedFromForBuyFee[account];
    }

    function isExcludedFromAntiSellFee(address account) external view returns(bool) {
        return _isExcludedFromAntiSellFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BNB20: approve from the zero address");
        require(spender != address(0), "BNB20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// funzione di transfer per il transferfrom ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

    function _transfer2(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BNB20: transfer from the zero address");
        require(to != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(!_blacklisted[from], "this account is Black listed!");

        //indicates if fee should be deducted from transferfrom
        bool takeAntiSellFee = true;

        if(_isExcludedFromAntiSellFee[from] || _isExcludedFromAntiSellFee[to]){
            takeAntiSellFee = false;
        }
        //transfer amount, it will take antiSell fee
        _tokenTransfer2(from,to,amount,takeAntiSellFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer2(address sender, address recipient, uint256 amount, bool takeAntiSellFee) private {
        if(!takeAntiSellFee)
            removeAntiSellFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded2(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded2(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard2(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded2(sender, recipient, amount);
        } else {
            _transferStandard2(sender, recipient, amount);
        }
        if(!takeAntiSellFee)
            restoreAntiSellFee();
    }

    function _transferStandard2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded2(address sender, address recipient, uint256 tAmount) private {
        uint lastselltime = block.timestamp;
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues2(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues2(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        set_LastSellTransferTimeFromAddressTokenHolder(lastselltime,recipient);
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// funzione di transfer per il transfer ///////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BNB20: transfer from the zero address");
        require(to != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(!_blacklisted[from], "this account is Black listed!");

        //indicates if and wich fees should be deducted from transfer
        bool takeTaxFee = true;
        bool takeForBuyFee = true;

        if(_isExcludedFromTaxFee[from] || _isExcludedFromTaxFee[to]){
            takeTaxFee = false;
        }
        if(_isExcludedFromForBuyFee[from] || _isExcludedFromForBuyFee[to]){
            takeForBuyFee = false;
        }
        //transfer amount, it will take redistribuition fee, antiSell fee, forBuy fee
        _tokenTransfer(from,to,amount,takeTaxFee,takeForBuyFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeTaxFee, bool takeForBuyFee) private {
        if(!takeTaxFee) removeTaxFee();
        if(!takeForBuyFee) removeForBuyFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeTaxFee) restoreTaxFee();
        if(!takeForBuyFee) restoreForBuyFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tForBuy, uint256 tAntiSell, uint256 tFee) = _getTValues(tAmount);
        (uint256 reflectionAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tForBuy, tAntiSell, _getRate());
        _tokenBalance[sender] = _tokenBalance[sender].sub(tAmount);
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(reflectionAmount);
        _tokenBalance[recipient] = _tokenBalance[recipient].add(tTransferAmount);
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(rTransferAmount);
        _takeForBuy(tForBuy);
        _takeAntiSell(tAntiSell);
        _updateTaxFeeTotal(rFee, tFee);
        _updateBuyBackTotal(tForBuy, tAntiSell);
        _updateSenderTokenHolderValues(sender, tAmount);
        _updateRecipientTokenHolderValues(recipient,tAmount,tForBuy,tAntiSell,tFee);
        _updateContractTokenHolderValues(tAmount,tForBuy,tAntiSell);
        _updateOthersTokenHolderValues(tAmount);
        _exchangeBeforeAfterTokenHolderValues();
        _resetUpdatedTokenHolder(); // resetta a false tutti i valori del campo updated del mapping dei tokenholders
        //_updateDistributeAllinWETH(sender);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per loswap dei token in BNB e la distribuzione ai vari wallet del team //////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _updateDistributeAllinWETH(address sender) internal virtual {
      uint256 constractBal=balanceOf(address(this));
      bool overMinTokenBalance = constractBal >= _minTokensBeforeSwap;
      if (!_inSwapAndLiquify && overMinTokenBalance && sender != uniswapV2Pair && _tradingIsEnabled) {
        if (_isDistribuitionInWethEnabled) _distributeInWETH(constractBal);
      }
    }
    
    function _swapTokensForWeth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _distributeInWETH(uint256 amount) private lockTheSwap {
        _swapTokensForWeth(amount);
        uint256 amountToTranfer = address(this).balance;
        uint256 amountMarketingToTranfer = amountToTranfer.mul(16).div(100); // _marketingWalletPercent = 16;
        uint256 amountNftToTranfer = amountToTranfer.mul(8).div(100); // _nftWalletPercent = 8;
        uint256 amountAntiDipToReflectToHoldersAddressToTranfer = amountToTranfer.mul(15).div(100); // _zntiDipToReflectToHoldersWalletPercent = 15; // sarebbe il 25% del totale rimasto nel wallert antidip che risulta 60%
        uint256 amountTaxFeeToTranfer = amountToTranfer.mul(16).div(100); // _taxFeeWalletPercent = 16;
        uint256 amountAntiDipToTranfer = amountToTranfer.sub(amountMarketingToTranfer).sub(amountNftToTranfer).sub(amountAntiDipToReflectToHoldersAddressToTranfer).sub(amountTaxFeeToTranfer); // _antiDipWalletPercent = 45; rimane il 60% dell'intero ammontare
       
        _distributeToAllHolders(amountTaxFeeToTranfer);
        _distributeToNftHolders(amountNftToTranfer);
        _distributeToNoSellHolders(amountAntiDipToReflectToHoldersAddressToTranfer);
        _distributeToAntiDip(amountAntiDipToTranfer);
        _distributeToMarketing(amountMarketingToTranfer);
    }
    
    function _distributeToAllHolders(uint256 tokenAmount) private {
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        uint256 amountToSend;
        
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            amountToSend = balanceOf(keyAddress).div(_tokenCirculatingTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders
            if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
        }
    }
    
    function _distributeToNftHolders(uint256 tokenAmount) private {
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        uint256 amountToSend;
        uint256 nftPercentageMax;
        uint256 tempTokenCirculatingTotal;
        uint256 tempBalance;
        
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            nftPercentageMax = _readNFTPercentageMax(keyAddress);
            tempBalance = balanceOf(keyAddress).add(balanceOf(keyAddress).mul(nftPercentageMax).div(100));
            tempTokenCirculatingTotal = _tokenCirculatingTotal.sub(balanceOf(keyAddress)).add(tempBalance);
            amountToSend = tempBalance.div(tempTokenCirculatingTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders che ha NFT nel wallet aggiungendo ai suoi token una porzione % data dalla carta
        }
        if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
    }
    
    function _readNFTPercentageMax(address addr) private pure returns (uint256) {
        uint256 NFTPercentageMax;
        
        // leggere la struttura dati mappata presente nel contratto NFT passando come parametro l'address
        if (addr==0x62AA208d3Edacb6AEDf3A32693f618947A522b17) {
            NFTPercentageMax = 80; // tra tutte le NFTPercentage prendi la NFTPercentageMax;
        }
        return NFTPercentageMax;
    }
    
    function _distributeToNoSellHolders(uint256 tokenAmount) private {
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        uint256 amountToSend;
        uint lastselltime;
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            lastselltime = tokenHolder.lastSellTransferTime[keyAddress];
            if (lastselltime == 0) {// non ha mai venduto
                amountToSend = balanceOf(keyAddress).div(_tokenNoSellTotal).mul(tokenAmount); // calcola la porzione da inviare ad ogni holders
                if (!_isExcludedFromReward[keyAddress]) payable(keyAddress).transfer(amountToSend);
            }
        }
    }
    
    function _distributeToAntiDip(uint256 tokenAmount) private {
        payable(_antiDipAddress).transfer(tokenAmount);
    }
    
    function _distributeToMarketing(uint256 tokenAmount) private {
        payable(_marketingAddress).transfer(tokenAmount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////// funzioni del mapping TokenHolder /////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    
    function get_ValueBeforeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesBefore[addr];
    }
    
    function get_ValueAfterGrossFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesAfterGross[addr];
    }
    
    function get_ValueAfterNetFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesAfterNet[addr];
    }
    
    function get_ValueReflectionsFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesReflections[addr];
    }
    
    function get_ValueReflectionsAccumulatedFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesReflectionsAccumulated[addr];
    }
    
    function get_AmountToTransferFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.amountToTrasfer[addr];
    }
    
    function get_ReflectionsFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.valuesReflections[addr];
    }
    
    function get_LastSellTransferTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.lastSellTransferTime[addr];
    }

    function set_LastSellTransferTimeFromAddressTokenHolder(uint lastselltime,address addr) private {
        tokenHolder.lastSellTransferTime[addr] = lastselltime;
    }
    
    function get_ClaimTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return tokenHolder.claimTime[addr];
    }

    function get_IndexFromAddressTokenHolder(address addr) public view returns (int) {
        if(!tokenHolder.inserted[addr]) {
            return -1;
        }
        return int(tokenHolder.indexOf[addr]);
    }

    function get_AddressFromIndexTokenHolder(uint index) public view returns (address) {
        return tokenHolder.addresses[index];
    }
    
    function get_UpdatedFromIndexTokenHolder(uint index) public view returns (bool) {
        address keyAddress = tokenHolder.addresses[index];
        return tokenHolder.updated[keyAddress];
    }

    function get_SizeTokenHolder() public view returns (uint) {
        return tokenHolder.addresses.length;
    }

    function set_AllValuesTokenHolder(
        address addr,
        uint256 valbefore,
        uint256 valaftergross,
        uint256 valafternet,
        uint256 amounttotransfer,
        uint256 valreflections,
        uint256 valreflectionsaccumulated,
        bool updated
        ) private {
            
        if (tokenHolder.inserted[addr]) {
            tokenHolder.valuesBefore[addr] = valbefore;
            tokenHolder.valuesAfterGross[addr] = valaftergross;
            tokenHolder.valuesAfterNet[addr] = valafternet;
            tokenHolder.amountToTrasfer[addr] = amounttotransfer;
            tokenHolder.valuesReflections[addr] = valreflections;
            tokenHolder.valuesReflectionsAccumulated[addr] = valreflectionsaccumulated;
            tokenHolder.updated[addr] = updated;
        } else {
            tokenHolder.inserted[addr] = true;
            tokenHolder.valuesBefore[addr] = valbefore;
            tokenHolder.valuesAfterGross[addr] = valaftergross;
            tokenHolder.valuesAfterNet[addr] = valafternet;
            tokenHolder.amountToTrasfer[addr] = amounttotransfer;
            tokenHolder.valuesReflections[addr] = valreflections;
            tokenHolder.valuesReflectionsAccumulated[addr] = valreflectionsaccumulated;
            tokenHolder.indexOf[addr] = tokenHolder.addresses.length;
            tokenHolder.updated[addr] = updated;
            tokenHolder.addresses.push(addr);
        }
    }

    function _removeAddressTokenHolder(address addr) private {
        if (!tokenHolder.inserted[addr]) {
            return;
        }

        delete tokenHolder.inserted[addr];
        delete tokenHolder.valuesBefore[addr];
        delete tokenHolder.valuesAfterGross[addr];
        delete tokenHolder.valuesAfterNet[addr];
        delete tokenHolder.amountToTrasfer[addr];
        delete tokenHolder.valuesReflections[addr];
        delete tokenHolder.valuesReflectionsAccumulated[addr];
        delete tokenHolder.updated[addr];
        delete tokenHolder.lastSellTransferTime[addr];
        delete tokenHolder.claimTime[addr];

        uint index = tokenHolder.indexOf[addr];
        uint lastIndex = tokenHolder.addresses.length - 1;
        address LastAddress = tokenHolder.addresses[lastIndex];

        tokenHolder.indexOf[LastAddress] = index;
        delete tokenHolder.indexOf[addr];

        tokenHolder.addresses[index] = LastAddress;
        tokenHolder.addresses.pop();
    }
    
    function _resetUpdatedTokenHolder() private {
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            tokenHolder.updated[keyAddress] = false;
        }
    }
    /////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per aggiornamento dei dati dei token holders /////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////


    function _updateSenderTokenHolderValues (
        address sender,
        uint256 tAmount
        ) private {
        
        // setta i valori del sender
        uint256 ValueBefore_sender = get_ValueBeforeFromAddressTokenHolder(sender);
        uint256 valuesReflections_sender = get_ValueReflectionsFromAddressTokenHolder(sender);
        uint256 balanceOf_sender = balanceOf(sender);
        uint256 ValueAfterNet_sender = ValueBefore_sender.sub(tAmount);
        
        set_AllValuesTokenHolder(
            sender, // sender
            ValueBefore_sender, // before
            balanceOf_sender, // afterGross
            ValueAfterNet_sender, // afterNet
            tAmount, // amount
            balanceOf_sender.sub(ValueAfterNet_sender), // reflections
            valuesReflections_sender.add(balanceOf_sender.sub(ValueAfterNet_sender)), // reflections accumulated
            true); 
    } 
    
    function _updateRecipientTokenHolderValues (
        address recipient,
        uint256 tAmount,
        uint256 tForBuy,
        uint256 tAntiSell,
        uint256 tFee
        ) private {
            
        // setta i valori del recipient
        uint256 ValueBefore_recipient = get_ValueBeforeFromAddressTokenHolder(recipient);
        uint256 valuesReflections_recipient = get_ValueReflectionsFromAddressTokenHolder(recipient);
        uint256 balanceOf_recipient = balanceOf(recipient);
        uint256 fees_recipient = tFee.add(tAntiSell).add(tForBuy);
        uint256 ValueAfterNet_recipient = ValueBefore_recipient.add(tAmount).sub(fees_recipient);
        
        set_AllValuesTokenHolder(
            recipient,
            ValueBefore_recipient,
            balanceOf_recipient,
            ValueAfterNet_recipient,
            tAmount,
            balanceOf_recipient.sub(ValueAfterNet_recipient), // reflections
            valuesReflections_recipient.add(balanceOf_recipient.sub(ValueAfterNet_recipient)), // reflections accumulated
            true); 
    }
    
    function _updateContractTokenHolderValues (
        uint256 tAmount,
        uint256 tForBuy,
        uint256 tAntiSell
        ) private {
            
        // setta i valori del contratto
        uint256 ValueBefore_contract = get_ValueBeforeFromAddressTokenHolder(address(this));
        uint256 balanceOf_contract = balanceOf(address(this));
        uint256 fees_contract = tAntiSell.add(tForBuy);
        uint256 valuesReflections_contract = get_ValueReflectionsFromAddressTokenHolder(address(this));
        uint256 ValueAfterNet_contract = ValueBefore_contract.add(fees_contract);
        
        if (fees_contract > 0) {
            set_AllValuesTokenHolder(
                address(this),
                ValueBefore_contract,
                balanceOf_contract,
                ValueAfterNet_contract,
                tAmount,
                balanceOf_contract.sub(ValueAfterNet_contract), // reflections
                valuesReflections_contract.add(balanceOf_contract.sub(ValueAfterNet_contract)), // reflections accumulated
                true); 
        }
    }
    
    function _updateOthersTokenHolderValues (
        uint256 tAmount
        ) private {
            
        // setta i valori di tutti gli altri holder non updated
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        uint256 ValueBefore_other;
        uint256 valuesReflections_other;
        uint256 balanceOf_other;
        
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            if(!tokenHolder.updated[keyAddress]) {
                ValueBefore_other = get_ValueBeforeFromAddressTokenHolder(keyAddress);
                valuesReflections_other = get_ValueReflectionsFromAddressTokenHolder(keyAddress);
                balanceOf_other = balanceOf(keyAddress);
                set_AllValuesTokenHolder(
                    keyAddress, // holder address
                    ValueBefore_other, // before
                    balanceOf_other, // afterGross
                    ValueBefore_other, // afterNet
                    tAmount, // amount
                    balanceOf_other.sub(ValueBefore_other), // reflections
                    valuesReflections_other.add(balanceOf_other.sub(ValueBefore_other)), // reflections accumulated
                    true); 
            }
        }
    }
    
    function _exchangeBeforeAfterTokenHolderValues (
        )  private {
        
        // scambia alla fine dell'operazione transfer il before con afterNet
        uint256 lastIndex = tokenHolder.addresses.length - 1;
        address keyAddress;
        uint256 ValueAfterNet;
        uint256 totalReflections = 0;
        _tokenCirculatingTotal = 0;
        _tokenNoSellTotal = 0;
        
        for (uint256 i = 0; i <= lastIndex ; i++) {
            keyAddress = tokenHolder.addresses[i];
            if(tokenHolder.updated[keyAddress]) {
                ValueAfterNet = get_ValueAfterNetFromAddressTokenHolder(keyAddress);
                tokenHolder.valuesBefore[keyAddress] = ValueAfterNet;
                _reBalance(keyAddress);
                totalReflections = totalReflections.add(get_ValueReflectionsFromAddressTokenHolder(keyAddress));
                
                // Calcola il totale dei token ciorcolanti posseduti dagli holders e degli holders che non hanno mai venduto
                _tokenCirculatingTotal = _tokenCirculatingTotal + balanceOf(keyAddress); // totale crcolante espresso come somma dei balance degli holders esclusi i token in liquidity
                if (tokenHolder.lastSellTransferTime[keyAddress] == 0) _tokenNoSellTotal = _tokenNoSellTotal + balanceOf(keyAddress); // totale dei token posseduti da holders che non hanno mai venduto
                // if (ValueAfterNet == 0) _removeAddressTokenHolder(keyAddress); // rimuove lìindirizzo dagli holders
                
            }
        }
        _reBalanceContract(totalReflections);
    }
   
    function _reBalance (address account
        )  private {
        
        // riporta il balance degli account al valore senza interessi AfterNet
        uint256 ValueAfterNet = get_ValueAfterNetFromAddressTokenHolder(account);
        if (_isExcludedFromReward[account]) _tokenBalance[account]=ValueAfterNet;
        else _reflectionBalance[account] = reflectionFromToken(ValueAfterNet);
    }
    
    function _reBalanceContract (uint256 totalReflections
        )  private {
        // assegna al contratto le reflections calcolate nell'ultima operazione di transfer o transferfrom, in tale calcolo deve 
        // comprendere anche le sue di reflection perchè nell'array _reflectionBalance non c'era alcuna reflection fino a questo momento neanche quelle del contratto.
        // Quindi nel balance del contratto saranno assorbite le seguenti voci:
        // somma delle refelctionAccoumulated da tutti gli holders (contratto compreso) + fees totali pagate solo al contratto (fromBuyFee + antiSellFee) 
        if (_isExcludedFromReward[address(this)]) _tokenBalance[address(this)]=_tokenBalance[address(this)].add(totalReflections);
        else _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(reflectionFromToken(totalReflections));
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni da usare per il claim NFT /////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    
    function set_startBlockClaim(uint timeBlock) external onlyOwner {
        _startBlockClaim = timeBlock;
    }

    function get_startBlockClaim() external view returns (uint) {
        return _startBlockClaim;
    }
    
    function set_periodFromStartBlockClaim(uint periodBlock) external onlyOwner {
        _periodFromStartBlockClaim = periodBlock;
    }

    function get_periodFromStartBlockClaim() external view returns (uint) {
        return _periodFromStartBlockClaim;
    }
    
    function set_balanceNeededClaim(uint256 balanceNeeded) external onlyOwner {
        _balanceNeededClaim = balanceNeeded;
    }

    function get_balanceNeededClaim() external view returns (uint256) {
        return _balanceNeededClaim;
    }
    
    function set_claimTime(uint timeBlock, address addr) external onlyNftContarctOwner() {
        tokenHolder.claimTime[addr] = timeBlock;
    }

    function get_claimTime(address addr) external view returns (uint) {
        uint _claimTime = tokenHolder.claimTime[addr];
        return _claimTime;
    }

    // verificala condizione 1 del claim ovvero se il saldo del balance è sufficiente
    function get_claimCheck1(address addr) external view returns (uint256, bool) {
        uint256 balanceNeeded = _balanceNeededClaim;
        bool _check = false;
        if (balanceOf(addr) >= balanceNeeded) _check = true;
        else _check = false;
        return (balanceOf(addr), _check);
    }

    // verificala condizione 2 del claim ovvero se è passato un certo periodo (circa una settimana) dalla data di listing
    function get_claimCheck2() external view returns (uint, bool) {
        bool _check = false;
        uint _now = block.timestamp;
        uint _timePassedFromStart = _now.sub(_startBlockClaim);
        if (_timePassedFromStart >= _periodFromStartBlockClaim) _check = true;
        else _check = false;
        return (_timePassedFromStart, _check);
    }

    // verificala condizione 3 del claim ovvero se non si è mai venduto fino a quel momento
    function get_claimCheck3(address addr) external view returns (bool) {
        bool _check = false;
        uint _lastselltransaction = tokenHolder.lastSellTransferTime[addr];
        if (_lastselltransaction == 0) _check = true;
        else _check = false;
        return (_check);
    }

    // verificala condizione 4 del claim ovvero se non si è mai fatto un claim
    function get_claimCheck4(address addr) external view returns (bool) {
        bool _check = false;
        uint _claimTime = tokenHolder.claimTime[addr];
        if (_claimTime == 0) _check = true;
        else _check = false;
        return (_check);
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    receive() external payable {}
}