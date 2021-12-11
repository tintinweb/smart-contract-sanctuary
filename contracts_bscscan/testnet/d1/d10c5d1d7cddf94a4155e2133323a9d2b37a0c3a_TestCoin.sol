/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

/**
::::::::::: :::::::::: :::::::: ::::::::::: ::::::::   ::::::::  :::::::::  :::::::::: 
    :+:     :+:       :+:    :+:    :+:    :+:    :+: :+:    :+: :+:    :+: :+:        
    +:+     +:+       +:+           +:+    +:+        +:+    +:+ +:+    +:+ +:+        
    +#+     +#++:++#  +#++:++#++    +#+    +#+        +#+    +:+ +#+    +:+ +#++:++#   
    +#+     +#+              +#+    +#+    +#+        +#+    +#+ +#+    +#+ +#+        
    #+#     #+#       #+#    #+#    #+#    #+#    #+# #+#    #+# #+#    #+# #+#        
    ###     ########## ########     ###     ########   ########  #########  ########## 
                                  ░                                         
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract TestCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
   

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private ItsActivedFees;
    mapping (address => bool) private _isExcludedFromWhale;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;
    

    address[] private _excluded;
    address[] private add_fees;

    bool private swapping;
    bool public takeFee = false;
    bool public enableFeeSwap = false;
  

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 100000000 * 10**3 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public _maxWalletToken = 4000000 * 10**18; //4% Supply 4M
    uint256 public swapTokensAtAmount = 1000000000 * 10**18; //1% Supply 1B 



    address payable public devAddress = payable(0xc13F1D2417c7ee86baA8EE4328e2EbE5F0642Cee);
    address payable public teamAddress = payable(0x6efeA836E4F969fFf6b3d067d50C326ce6f0c99c);
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    string private constant _name = "TestCoin";
    string private constant _symbol = "CoinCTest";


    struct feeRatesStruct {
      uint256 rfi;
      uint256 development;
      uint256 team;
      uint256 liquidity;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 20,
      development: 10,
      team: 70,
      liquidity: 10
    });

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 development;
        uint256 team;
        uint256 liquidity;
    }
    TotFeesPaidStruct private totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rDevelopment;
      uint256 rTeam;
      uint256 rLiquidity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tDevelopment;
      uint256 tTeam;
      uint256 tLiquidity;
    }

    event FeesChanged();
    event SetEnableFeeSwap(bool true_false);
    event ManualSwap(uint256 percent_Of_Tokens_To_Process);
    event UpdatedRouter(address oldRouter, address newRouter);

    event SwapAndLiquify(
        uint256 tokensSwapped,      
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    
    );

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address routerAddress) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _rOwned[owner()] = _rTotal;
        ItsActivedFees[owner()] = false;
        ItsActivedFees[devAddress] = false;
        ItsActivedFees[teamAddress] = false;

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        valuesFromGetValues memory s = _getValues(tAmount, true);
        _rOwned[sender] = _rOwned[sender].sub(s.rAmount);
        _rTotal = _rTotal.sub(s.rAmount);
        totFeesPaid.rfi += tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function setEnableFeeSwap(bool true_false) external onlyOwner{
          
        if(true_false == true){
           includeOnFees(pair); 
        }
        if (true_false == false){
           removeOnFees(pair);
        } 
        enableFeeSwap = true_false;  
        emit SetEnableFeeSwap(true_false);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    //Internal includes and removes Fees 
    function includeOnFees(address account) private  {
        ItsActivedFees[account] = true;
    }

    function removeOnFees(address account) private  {
        ItsActivedFees[account] = false;
    }

    function includeAddressInFees(address account) external onlyOwner {
        add_fees.push(account);
        ItsActivedFees[account] = true;
    }

    function includeMultiplesAddressInFees(address[] calldata _address ) external onlyOwner {
        for (uint i=0; i<_address.length; i++) {
               add_fees.push(_address[i]);
               ItsActivedFees[_address[i]] = true;
        }
    }

    function removeAddressFromFee(address account) external onlyOwner {
        for (uint i=0; i<add_fees.length; i++) {
            if(account == add_fees[i]){
                delete add_fees[i];
            }
         }
         ItsActivedFees[account] = false;
    }

    function isActivedFromFee(address account) external view returns(bool) {
        return ItsActivedFees[account];
    }

    function setFeeRates(uint256 _rfi, uint256 _liquidity, uint256 _dev, uint256 _team) external onlyOwner {
        feeRates.rfi = _rfi;
        feeRates.liquidity = _liquidity;
        feeRates.development = _dev;
        feeRates.team = _team;
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeDevelopment(uint256 rDevelopment, uint256 tDevelopment) private {
        totFeesPaid.development +=tDevelopment;
        if(_isExcluded[address(this)]){
             _tOwned[address(this)]+=tDevelopment;
        }
        _rOwned[address(this)] +=rDevelopment;

    }
    
    function _takeTeam(uint256 rTeam, uint256 tTeam) private {
        totFeesPaid.team +=tTeam;
        if(_isExcluded[address(this)]){
             _tOwned[address(this)]+=tTeam;
        }
        _rOwned[address(this)] +=rTeam;

    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;

        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }

    function _getValues(uint256 tAmount, bool _takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, _takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rDevelopment, to_return.rTeam, to_return.rLiquidity) = _getRValues(to_return, tAmount, _takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool _takeFee) private view returns (valuesFromGetValues memory s) {

        if(!_takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        else{
            s.tRfi = tAmount*feeRates.rfi/1000;
            s.tDevelopment = tAmount*feeRates.development/1000;
            s.tTeam = tAmount*feeRates.team/1000;
            s.tLiquidity = tAmount*feeRates.liquidity/1000;
            s.tTransferAmount = tAmount - s.tRfi -s.tDevelopment -s.tTeam - s.tLiquidity;
        }
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool _takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rDevelopment, uint256 rTeam, uint256 rLiquidity) {
        rAmount = tAmount*currentRate;

        if(!_takeFee) {
          return(rAmount, rAmount, 0,0,0,0);
        }
        rRfi = s.tRfi*currentRate;
        rDevelopment = s.tDevelopment*currentRate;
        rTeam = s.tTeam*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rTransferAmount =  rAmount-rRfi-rDevelopment-rTeam-rLiquidity;
        return (rAmount, rTransferAmount, rRfi,rDevelopment,rTeam,rLiquidity);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getAllAddressActivedFees() external view returns(address[] memory) {
     return add_fees;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBot[from] && !_isBot[to], "Fuck you Bots");

        takeFee = false;

        if(ItsActivedFees[msg.sender] == true){
          takeFee = true;
         }
        if (from == pair && ItsActivedFees[pair] == true){
          takeFee = true;
         }
        if (to == pair && ItsActivedFees[pair] == true){
          takeFee = true;
        }
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if(canSwap && from != pair && to != pair){
            swapAndLiquify(swapTokensAtAmount);
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function manualSwap (uint256 percent_Of_Tokens_To_Process) external onlyOwner {
        // Do not trigger if already in swap
        if (percent_Of_Tokens_To_Process > 100){percent_Of_Tokens_To_Process == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract*percent_Of_Tokens_To_Process/100;
        swapAndLiquify(sendTokens);
        emit ManualSwap(percent_Of_Tokens_To_Process);
    }
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool _takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, _takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        _reflectRfi(s.rRfi, s.tRfi);
        _takeDevelopment(s.rDevelopment,s.tDevelopment);
        _takeTeam(s.rTeam,s.tTeam);
        _takeLiquidity(s.rLiquidity,s.tLiquidity);
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity + s.tDevelopment + s.tTeam);

    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

      // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
    }
    
    /*
    #dev, swapAndLiquify is responsible for taking the exact percentage of each 
    fee and distributing BNB that were swapped, the remainder remaining in the contract.
    */
    function swapAndLiquify(uint256 tokens) private lockTheSwap{
        uint256 denominator= (feeRates.liquidity + feeRates.development + feeRates.team) * 2;
        uint256 tokensToAddLiquidityWith = tokens * feeRates.liquidity / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - feeRates.liquidity);
        uint256 bnbToAddLiquidityWith = unitBalance * feeRates.liquidity;

        if(bnbToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to DevelopmentWallet
        uint256 developmentAmt = unitBalance * 2 * feeRates.development;
        if(developmentAmt > 0){
          payable(devAddress).transfer(developmentAmt);
        }
        
        // Send BNB to teamAddress
        uint256 teamAmt = unitBalance * 2 * feeRates.team;
        if(teamAmt > 0){
          payable(teamAddress).transfer(teamAmt);
        }

        emit SwapAndLiquify(denominator,bnbToAddLiquidityWith, tokensToAddLiquidityWith);
        
    }    

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }
    
    function setMaxWalletTokend(uint256 _maxToken) external onlyOwner {
        _maxWalletToken = _maxToken;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function setAntibot(address account, bool _bot) external onlyOwner{
        require(_isBot[account] != _bot, 'Value already set');
        _isBot[account] = _bot;
    }

    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

    /// @dev Update router address in case of pancakeswap migration
    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(router));
        IRouter _newRouter = IRouter(newRouter);
        address get_pair = IFactory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            pair = IFactory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pair = get_pair;
        }
        router = _newRouter;
    }

    receive() external payable{
    }
}