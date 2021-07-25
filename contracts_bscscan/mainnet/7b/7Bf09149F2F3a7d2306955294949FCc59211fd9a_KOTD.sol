/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.0;

/* KOTD:
* rfi 2%
* burn 1%
* marketing 3%
* capture the flag 1%
* TopDog 3%
* 
* amount to capture the flag: at least 2.5M tokens
*
* to become topDog: buy more than previous topDog
* topDog's reign lasts 4 hours, after that BurnAddress becomes TopDog temporarily
* if topDog does a transfer he loses his topDog status
*
* antiwhale:
* max amount per buy/sell: 1% of initial supply (10M tokens)
*/


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




//"ETH" symb is used for better uniswap-core integration
//uniswap is use due to their better repo management

contract KOTD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => automatedMarketMakerPairsStruct) public automatedMarketMakerPairs;

    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10* 10**9 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public _maxTxAmount = _tTotal/100;


    address public marketingAddress;
    address private BURNADDR = 0x000000000000000000000000000000000000dEaD;

    address public flagHolder;

    uint256 public flagChangeTarget = 25* 10**5 * 10**_decimals; //buy at least 2.5M tokens to capture the flag


    string private constant _name = "KOTD";
    string private constant _symbol = "KOTD";
    
    struct automatedMarketMakerPairsStruct{
        bool isPair;
        uint256 supply;
    }
    
    struct feeRatesStruct {
      uint256 rfi;
      uint256 burn;
      uint256 marketing;
      uint256 captureTheFlag;
      uint256 topDog;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {rfi: 2,         //autoreflection rate, in %
      burn: 1,   //burn fee in %
      marketing: 3,  //marketing fee in %
      captureTheFlag: 1, //capture the flag fee in %
      topDog: 3 //Top dog fee %
    });

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 burn;
        uint256 marketing;
        uint256 captureTheFlag;
        uint256 topDog;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct TopDogData{
        address topDogAddr;
        uint256 topDogAmount;
        uint256 topDogSince;
    }

    TopDogData public topDog;
    
    struct Top10Dog {
        address addr;
        uint balance;
    }
    
    Top10Dog[10] public top10Dogs;

    uint256 topDogLimitSeconds;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rBurn;
      uint256 rMarketing;
      uint256 rCaptureTheFlag;
      uint256 rTopDog;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tBurn;
      uint256 tMarketing;
      uint256 tCaptureTheFlag;
      uint256 tTopDog;
    }

    event FeesChanged();
    event TopDog(address indexed account, uint256 time);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event FlagStolen(address newFlagHolder, address oldFlagHolder);
    event UpdatedMarketingWallet(address oldWallet, address newWallet);
    event UpdatedFlagChangeTarget(uint256 oldTarget, uint256 newTarget);
    

    constructor () {
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        marketingAddress= owner();
        _isExcludedFromFee[marketingAddress]=true;
        flagHolder=BURNADDR;
        _isExcluded[BURNADDR]=true;
        _excluded.push(BURNADDR);
        _isExcludedFromMaxTx[owner()]= true;
        topDogLimitSeconds=4*1 hours;
        topDog.topDogAddr = BURNADDR;
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

     function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[pair].isPair = value;
        if(value)
        {
        uint256 lpSupply = getCurrentLPSupply(pair);
 automatedMarketMakerPairs[pair].supply = lpSupply;
 }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) public onlyOwner() {
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


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMaxTx(address account) external onlyOwner {
        _isExcludedFromMaxTx[account] = true;
    }

    function includeFromMaxTx(address account) external onlyOwner {
        _isExcludedFromMaxTx[account] = false;
    }

    function isExcludedFromMaxTx(address account) external view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setFeeRates(uint256 _rfi, uint256 _burn, uint256 _marketing, uint256 _captureTheFlag, uint256 _topDog) public onlyOwner {
      feeRates.rfi = _rfi;
      feeRates.burn = _burn;
      feeRates.marketing = _marketing;
      feeRates.captureTheFlag = _captureTheFlag;
      feeRates.topDog = _topDog;
      emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn +=tBurn;
        _tTotal -=tBurn;
        _rTotal -=rBurn;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;

        if(_isExcluded[marketingAddress])
        {
            _tOwned[marketingAddress]+=tMarketing;
        }
        _rOwned[marketingAddress] +=rMarketing;
    }

    function _takeCaptureTheFlag(uint256 rFlag, uint256 tFlag) private {
        totFeesPaid.captureTheFlag +=tFlag;

        if(_isExcluded[flagHolder])
        {
            _tOwned[flagHolder]+=tFlag;
        }
        _rOwned[flagHolder] +=rFlag;
    }

    function _takeTopDog(uint256 rTopDog, uint256 tTopDog) private {
        totFeesPaid.topDog +=tTopDog;

        if(_isExcluded[topDog.topDogAddr])
        {
            _tOwned[topDog.topDogAddr]+=tTopDog;
        }
        _rOwned[topDog.topDogAddr] +=rTopDog;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi,to_return.rBurn, to_return.rMarketing, to_return.rCaptureTheFlag, to_return.rTopDog) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*feeRates.rfi/100;
        s.tBurn = tAmount*feeRates.burn/100;
        s.tMarketing = tAmount*feeRates.marketing/100;
        s.tCaptureTheFlag = tAmount*feeRates.captureTheFlag/100;
        s.tTopDog = tAmount*feeRates.topDog/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tBurn-s.tMarketing-s.tCaptureTheFlag-s.tTopDog;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rBurn,uint256 rMarketing, uint256 rCaptureTheFlag, uint256 rTopDog) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rBurn = s.tBurn*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rCaptureTheFlag = s.tCaptureTheFlag*currentRate;
        rTopDog = s.tTopDog*currentRate;
        rTransferAmount =  rAmount-rRfi-rBurn-rMarketing-rCaptureTheFlag-rTopDog;
        return (rAmount, rTransferAmount, rRfi,rBurn,rMarketing,rCaptureTheFlag, rTopDog);
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        if(!_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }
    
    function getCurrentLPSupply(address pair) public view returns(uint256) {
        return IERC20(pair).totalSupply();
    }
    
    function getTop10Dogs(address addr, uint currentValue) private {
        uint i = 0;
        for(i; i < top10Dogs.length; i++) {
            if(top10Dogs[i].balance < currentValue) {
                break;
            }
        }
        for(uint j = top10Dogs.length - 1; j > i; j--) {
            top10Dogs[j].balance = top10Dogs[j - 1].balance;
            top10Dogs[j].addr = top10Dogs[j - 1].addr;
        }
        top10Dogs[i].balance = currentValue;
        top10Dogs[i].addr = addr;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if(automatedMarketMakerPairs[sender].isPair)
        {   
            uint256 pairSupply = getCurrentLPSupply(sender);
            if(pairSupply < automatedMarketMakerPairs[sender].supply){ //user is removing liquidity
                automatedMarketMakerPairs[sender].supply = pairSupply;
            }
            else
            { //user is buying
                if(tAmount>=flagChangeTarget && recipient != flagHolder)
                {
                    emit FlagStolen(recipient,flagHolder);
                    flagHolder = recipient;
                }
    
                if(tAmount >= topDog.topDogAmount) {
                    topDog.topDogAddr = recipient;
                    topDog.topDogAmount = tAmount;
                    topDog.topDogSince = block.timestamp;
                    getTop10Dogs(recipient, tAmount);
                    emit TopDog(recipient, topDog.topDogSince);
                }
            }
        }
        
        if(automatedMarketMakerPairs[recipient].isPair)
        {
          uint256 pairSupply = getCurrentLPSupply(recipient);
            if(pairSupply > automatedMarketMakerPairs[recipient].supply){ //user is adding liquidity
                automatedMarketMakerPairs[recipient].supply = pairSupply;
            }
        }

        // top dog can be dethroned after time limit or if they transfer OR sell
        if(sender == topDog.topDogAddr || block.timestamp > topDog.topDogSince + topDogLimitSeconds) {
            topDog.topDogAddr = BURNADDR;
            topDog.topDogAmount = 0;
            emit TopDog(BURNADDR, block.timestamp);
        }

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        _reflectRfi(s.rRfi, s.tRfi);
        _takeBurn(s.rBurn,s.tBurn);
        _takeMarketing(s.rMarketing,s.tMarketing);
        _takeCaptureTheFlag(s.rCaptureTheFlag, s.tCaptureTheFlag);
        _takeTopDog(s.rTopDog, s.tTopDog);
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(0), s.tBurn);
        emit Transfer(sender, marketingAddress, s.tMarketing);
        emit Transfer(sender, flagHolder, s.tCaptureTheFlag);
        emit Transfer(sender, topDog.topDogAddr, s.tTopDog);
    }
    
    function updateMarketingWallet(address newWallet) external onlyOwner{
        require(marketingAddress != newWallet ,'Wallet already set');
        emit UpdatedMarketingWallet(marketingAddress, newWallet);
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
        _isExcludedFromMaxTx[marketingAddress];
    }
    
    function updateFlagChangeTarget(uint256 newTarget) external onlyOwner{
        require(newTarget <= (_tTotal * 20 / 100), 'New target must be less then 20% of total supply');
        emit UpdatedFlagChangeTarget(flagChangeTarget, newTarget);
        flagChangeTarget = newTarget * 10**_decimals;
    }
}