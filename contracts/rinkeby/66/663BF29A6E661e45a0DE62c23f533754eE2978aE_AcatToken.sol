/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Fomo {
    using SafeMath for uint256;
    uint256 private gameReward;
    uint256 private timeLeft;
    uint256 private stepJoinToken = 10000000 * 10 ** 9;
    
    uint256 gameRewardRate = 50;
    uint256 private rankMax = 5;
    mapping(uint256 => uint256) rewardRate;

    uint256 private drawTotal;
    
    struct gameRankStuck {
        address rankAddr;
        uint256 joinTime;
    }
    mapping(uint256 => gameRankStuck[]) private gameRanks;
    
    constructor() public {
        rewardRate[0] = 50;
        rewardRate[1] = 25;
        rewardRate[2] = 13;
        rewardRate[3] = 6;
        rewardRate[4] = 6;
     }

    // show how many token the Jack pot has
    function fomoGetJackpot() public view returns(uint256){
        return gameReward;
    }

    function fomoAddToken(uint256 _token) internal {
        gameReward = gameReward.add(_token);
    }

    function retSetfomoToken(uint256 _token) internal {
        gameReward = _token;
    }
    
    function getFomoRankInfo(uint256 num) public view returns(address,uint256,uint256){
        if(gameRanks[drawTotal].length == 0){
            return (address(0), 0, 0);
        }
        
        uint256 len = gameRanks[drawTotal].length - 1;
        if(len >= num){
            uint256 rewardToken = gameReward.mul(gameRewardRate).div(100);
            return (
                gameRanks[drawTotal][num].rankAddr, 
                gameRanks[drawTotal][num].joinTime,
                rewardToken.mul(rewardRate[num]).div(100)
            );
        }
        return (address(0), 0, 0);
    }    

    function fomoSetTopAccount(address addr, uint256 _token) internal {
        if(_token < stepJoinToken){
            return;
        }
        
        resetTimeLeft();
        
        gameRankStuck memory newStuck;
        newStuck.rankAddr = addr;
        newStuck.joinTime = block.timestamp;
        
        //none
        if(gameRanks[drawTotal].length == 0){
            gameRanks[drawTotal].push(newStuck);
            return;
        }
        
        gameRanks[drawTotal].push(newStuck);
        uint256 len = gameRanks[drawTotal].length;
        
        for(uint256 i = 0; i < len; i++){
            for (uint256 j = i + 1; j < len; j++){
                if (gameRanks[drawTotal][j].joinTime > gameRanks[drawTotal][i].joinTime){
                    gameRankStuck memory oldStuck = gameRanks[drawTotal][i];
                    gameRanks[drawTotal][i] = gameRanks[drawTotal][j];
                    gameRanks[drawTotal][j] = oldStuck;
                }
            }
        }        
        
        if(gameRanks[drawTotal].length > rankMax){
            for(uint256 i = 0; i < gameRanks[drawTotal].length; i++){
                if(i >= rankMax){
                    gameRanks[drawTotal].pop();
                }
            }
        }
    }

    function fomoTimeLeft() public view returns(uint256){
        return timeLeft;
    }

    function setFomoTimeLeft(uint256 t) internal returns(uint256){
        timeLeft = t;
        return timeLeft;
    }

    function resetTimeLeft() internal {
        timeLeft = block.timestamp + 3600;
    }
    
    function fomoRankLength(bool isForce) internal view returns(uint256){
        if(isForce){
            return gameRanks[drawTotal].length;
        }
        
        if(timeLeft > 0 && block.timestamp > timeLeft){
            return gameRanks[drawTotal].length;    
        }
        return 0;
    }

    //this info we will show at the website
    function getFomoInfo() public view returns(uint256,uint256,uint256,uint256){
        return (
            drawTotal,
            fomoGetJackpot(),
            timeLeft,
            stepJoinToken
        );
    }
    
    function fomoNextDrawInit() internal {
        uint256 tmp = gameReward.mul(gameRewardRate).div(100);
        gameReward = gameReward.sub(tmp);
        timeLeft = 0;
        drawTotal++;
    }
}

contract AcatToken is Context, IERC20, Ownable, Fomo {
    using SafeMath for uint256;
    using Address for address;

    uint8 private _decimals = 9;
    string private _name = "Angora Cat";
    string private _symbol = "AGCAT";

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000000 * 10 ** uint256(_decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private maxBuyToken = 10000100 * 10 ** uint256(_decimals);

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public _tOwned;
    mapping (address => uint256) public _rOwned;

    mapping (address => bool) public _isExcludedFromFee;

    mapping (address => bool) public _isExcluded;
    address[] private _excluded;

    uint256 public _tFeeTotal;

    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _burnFee = 2;
    uint256 public _fomoFee = 3;
    uint256 public _termFee = 2;

    address private termAddress = 0x7ccA9De724E3e8646b13C3Ed82C18049601D8a7F;

    mapping(address => bool) public whiteAddress;
    mapping(address => bool) private whiteAddressBuy;
    mapping(address => bool) private adminAddress;
    uint256 startTime = 1624017600;//2021-06-18 20:00:00

    uint256 public accountId;
    mapping(address => bool) accountAddrMapId;

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[termAddress] = true;
        adminAddress[_msgSender()] = true;
        setExcludeFromReward(_msgSender());
        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        register(_msgSender());
        register(recipient);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //admin address allow all the action
        if(adminAddress[from] || adminAddress[to]){
            standerTransfer(from, to, amount);
            return;
        }

        //check the opening time
        require(block.timestamp >= startTime, "It's not time yet");
        uint256 _time = block.timestamp - startTime;

        fomoGameDraw();
        if(_isExcluded[from] && !_isExcluded[to]){
            fomoSetTopAccount(to, amount);
        }

        // > 30 miniutes, freedom to buy
        if(_time > 1800){
            standerTransfer(from, to, amount);
            return;
        }
        openingFiveToTen(from, to, amount);
    }

    //open 5 ~ 10 minute
    function openingFiveToTen(address from, address _to, uint256 _value) internal {
        require(maxBuyToken >= _value, "reach the max buy token");
        standerTransfer(from, _to, _value);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        tAmount = _sumCostAmount(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _sumCostAmount(uint256 tAmount) internal returns(uint256){
        if(_taxFee == 0) {
            return tAmount;
        }
        
        //burn
        uint256 burnAmount = tAmount.mul(_burnFee).div(100);
        emit Transfer(msg.sender, address(0), burnAmount);
        
        //term
        uint256 termAmount = tAmount.mul(_termFee).div(100);
        (,uint256 rTransferAmount,,,) = _getValues(termAmount);
        _rOwned[termAddress] = _rOwned[termAddress].add(rTransferAmount);
        
        //fomo
        uint256 fomoAmount = tAmount.mul(_fomoFee).div(100);
        (,rTransferAmount,,,) = _getValues(fomoAmount);
        fomoAddToken(rTransferAmount);
        return tAmount.sub(burnAmount).sub(termAmount).sub(fomoAmount);
    }

    //user seller token
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        tAmount = _sumCostAmount(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        //seller logic origin
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //user buy token
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        tAmount = _sumCostAmount(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        tAmount = _sumCostAmount(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function standerTransfer(address sender, address recipient, uint256 amount) private {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient] || whiteAddress[sender] || whiteAddress[recipient]){
            removeAllFee();
        }
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {//user buy token
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {//user seller token
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {//user transfer token
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {//exp create pool
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        restoreAllFee();
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function removeAllFee() private {
        if(_taxFee == 0) {
            return;
        }
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]){
            return _tOwned[account];
        }
        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() public view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply){
                return (_rTotal, _tTotal);
            }
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)){
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    function setWhiteAddress(address _addr) public onlyOwner {
        whiteAddress[_addr] = true;
    }

    function setExcludedFromFee(address _addr) public onlyOwner {
        _isExcludedFromFee[_addr] = true;
    }

    function setStartTime(uint256 t) public onlyOwner returns(bool success){
        startTime = t;
        return true;
    }

    //force to game draw
    function forceFomoGameDraw() public onlyOwner {
        uint256 len = fomoRankLength(true);
        _fomoGameDraw(len);
    }
    
    function _fomoGameDraw(uint256 len) internal {
        if(len == 0) {
            return;
        }
        
        for(uint256 i = 0; i < len; i++){
            (address _account,,uint256 token) = getFomoRankInfo(i);
            if(_account != address(0) && token > 0){
                _rOwned[_account] = _rOwned[_account].add(token);
            }
        }
        fomoNextDrawInit();
    }
    
    function fomoGameDraw() internal {
        uint256 len = fomoRankLength(false);
        _fomoGameDraw(len);
    }

    //just for test
    function airDrop(address[] memory addrArray, uint256 token) public onlyOwner returns(bool success){
        for(uint256 i = 0; i < addrArray.length; i++){
            transfer(addrArray[i], token);
        }
        return true;
    }

    function register(address addr) internal {
        if(!accountAddrMapId[addr]){
            accountAddrMapId[addr] = true;
            accountId++;
        }
    }

    function setExcludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
}