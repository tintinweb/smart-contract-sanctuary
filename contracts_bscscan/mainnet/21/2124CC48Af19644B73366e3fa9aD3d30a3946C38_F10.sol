/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _presaleAddress;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event PresaleAddressUpdated(address indexed previousAddress, address indexed newAddress);

    constructor() {
        _transferOwnership(_msgSender());
        _updatePresaleAddress(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function presaleAddress() public view virtual returns (address) {
        return _presaleAddress;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlySender() {
        require(presaleAddress() == _msgSender(), "Ownable: caller is not authorized");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function updatePresaleAddress(address newAddress) public virtual onlyOwner {
        require(newAddress != address(0), "Ownable: new owner is the zero address");
        _updatePresaleAddress(newAddress);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _updatePresaleAddress(address newAddress) internal virtual {
        address oldAddress = _presaleAddress;
        _presaleAddress = newAddress;
        emit PresaleAddressUpdated(oldAddress, newAddress);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract F10 is Ownable, IBEP20 {

    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "F10";
    string private constant _symbol = "F10";
    uint8 private constant _decimals = 9;

    uint256 public lockPeriod = 60 days;
    uint256 public _maxTxAmount = 11000000*10**9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 110000000*10**9;
    uint256 public _rTotal = (MAX.sub( (MAX.mod(_tTotal))));

    uint256 private _tFeeTotal;
    uint256 private _taxFee = 2;
    uint256 private _liqidityFee = 2;
    uint256 private _burnFee = 2;
    uint256 private _gameFee = 2;
    uint256 private _donationFee = 2;

    address public _liqidityAddress;
    address public _burnAddress;
    address public _gameAddress;
    address public _donationAddress;

    address[] private _excluded;

    mapping(address => uint256) public _rOwned;
    mapping(address => uint256) public _tOwned;
    mapping(address => uint256) public _lockedTime;
    mapping(address => mapping(address => uint256)) public _allowances;

    mapping(address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcluded;

    event TaxFeeUpdated(uint256 lastFee, uint256 newFee);
    event LiquidityFeeUpdated(uint256 lastFee, uint256 newFee);
    event BurnFeeUpdated(uint256 lastFee, uint256 newFee);
    event GameFeeUpdated(uint256 lastFee, uint256 newFee);
    event DonationFeeUpdated(uint256 lastFee, uint256 newFee);

    event ExcludedFromFee(address userAddress);
    event IncludedInFee(address userAddress);

    event ExcludedFromReward(address userAddress);
    event IncludedInReward(address userAddress);

    event LiquidityAddressUpdated(address oldAdd, address newAdd);
    event BurnAddressUpdated(address oldAdd, address newAdd);
    event GameAddressUpdated(address oldAdd, address newAdd);
    event DonationAddressUpdated(address oldAdd, address newAdd);

    event MaxTxAmountUpdated(uint256 lastAmount, uint256 newAmount);
    event PresaleTransfer(address indexed from, address indexed to, uint256 value);

    constructor(address liqAdd, address burnAdd, address gameAdd, address donationAdd) {
        _liqidityAddress = liqAdd;
        _burnAddress = burnAdd;
        _gameAddress = gameAdd;
        _donationAddress = donationAdd;

        emit LiquidityAddressUpdated(address(0), _liqidityAddress);
        emit BurnAddressUpdated(address(0), _burnAddress);
        emit GameAddressUpdated(address(0), _gameAddress);
        emit DonationAddressUpdated(address(0), _donationAddress);

        _rOwned[_msgSender()] = _tTotal.mul(_getRate());

        excludeFromFee(owner());
        excludeFromFee(_burnAddress);
        excludeFromFee(address(this));
        excludeFromReward(owner());
        excludeFromReward(_burnAddress);

        emit Transfer(address(0), _msgSender(), _tTotal);

    }

    function getAllFee() external view returns(uint256, uint256, uint256, uint256, uint256){
        return (_taxFee, _liqidityFee, _donationFee, _burnFee, _gameFee );
    }

    function updateTaxFee(uint256 newFee) external onlyOwner() returns(bool){
        uint256 oldFee = _taxFee;
        _taxFee = newFee;
        emit TaxFeeUpdated(oldFee, _taxFee);
        return true;
    }

    function updateLiquidityFee(uint256 newFee) external onlyOwner() returns(bool){
        uint256 oldFee = _liqidityFee;
        _liqidityFee = newFee;
        emit LiquidityFeeUpdated(oldFee, _liqidityFee);
        return true;
    }

    function updateBurnFee(uint256 newFee) external onlyOwner() returns(bool){
        uint256 oldFee = _burnFee;
        _burnFee = newFee;
        emit BurnFeeUpdated(oldFee, _burnFee);
        return true;
    }

    function updateGameFee(uint256 newFee) external onlyOwner() returns(bool){
        uint256 oldFee = _gameFee;
        _gameFee = newFee;
        emit GameFeeUpdated(oldFee, _gameFee);
        return true;
    }

    function updateDonationFee(uint256 newFee) external onlyOwner() returns(bool){
        uint256 oldFee = _donationFee;
        _donationFee = newFee;
        emit DonationFeeUpdated(oldFee, _donationFee);
        return true;
    }

    function updateBurnAdd(address newAdd) external onlyOwner() returns(bool){
        address oldAdd = _burnAddress;
        _burnAddress = newAdd;
        includedInFee(oldAdd);
        excludeFromFee(newAdd);
        emit BurnAddressUpdated(oldAdd, _burnAddress);
        return true;
    }

    function updateLiquidityAdd(address newAdd) external onlyOwner() returns(bool){
        address oldAdd = _liqidityAddress;
        _liqidityAddress = newAdd;
        includedInFee(oldAdd);
        excludeFromFee(newAdd);
        emit LiquidityAddressUpdated(oldAdd, _liqidityAddress);
        return true;
    }

    function updateGameAdd(address  newAdd) external onlyOwner() returns(bool){
        address oldAdd = _gameAddress;
        _gameAddress = newAdd;
        includedInFee(oldAdd);
        excludeFromFee(newAdd);
        emit GameAddressUpdated(oldAdd, _gameAddress);
        return true;
    }

    function updateDonationAdd(address newAdd) external onlyOwner() returns(bool){
        address oldAdd = _donationAddress;
        _donationAddress = newAdd;
        includedInFee(oldAdd);
        excludeFromFee(newAdd);
        emit DonationAddressUpdated(oldAdd, _donationAddress);
        return true;
    }

    function excludeFromFee(address userAddress) public onlyOwner() returns(bool){
        _isExcludedFromFee[userAddress] = true;
        emit ExcludedFromFee(userAddress);
        return true;
    }

    function includedInFee(address userAddress) public onlyOwner() returns(bool){
        _isExcludedFromFee[userAddress] = false;
        emit IncludedInFee(userAddress);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromReward(address account) public onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludedFromReward(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                emit IncludedInReward(account);
                break;
            }
        }
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function presaleSend(address recipient, uint256 amount) public onlySender() returns (bool) {

        require(recipient != address(0), "BEP20: transfer to the zero address");

        _lockedTime[recipient] = block.timestamp;

        _tokenTransfer(_msgSender(), recipient, amount, false);

        emit PresaleTransfer(presaleAddress(), recipient, amount);

        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liqidityFee == 0 && _donationFee == 0 && _gameFee == 0 && _burnFee == 0) return;
        _taxFee = 0;
        _liqidityFee = 0;
        _donationFee = 0;
        _burnFee = 0;
        _gameFee = 0;
    }

    function restoreAllFee(uint256 tax, uint256 liq, uint256 donation, uint256 burn, uint256 game) private {
        _taxFee = tax;
        _liqidityFee = liq;
        _donationFee = donation;
        _burnFee = burn;
        _gameFee = game;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(_lockedTime[from] > 0){
            require(block.timestamp >= _lockedTime[from].add(lockPeriod), "Wait for Presale Lockup");
        }

        if(from != owner() && to != owner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 tax = _taxFee;
        uint256 liq = _liqidityFee;
        uint256 donation =  _donationFee;
        uint256 burn = _burnFee;
        uint256 game = _gameFee;

        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee(tax, liq, donation, burn, game);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {

        (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tDonation,
            uint256 tBurn,
            uint256 tGame,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tLiquidity, tDonation, tBurn, tGame);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeDonation(tDonation);
        _takeBurn(tBurn);
        _takeGame(tGame);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
         (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tDonation,
            uint256 tBurn,
            uint256 tGame,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tLiquidity, tDonation, tBurn, tGame);


        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeDonation(tDonation);
        _takeBurn(tBurn);
        _takeGame(tGame);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
         (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tDonation,
            uint256 tBurn,
            uint256 tGame,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tLiquidity, tDonation, tBurn, tGame);


        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeDonation(tDonation);
        _takeBurn(tBurn);
        _takeGame(tGame);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tDonation,
            uint256 tBurn,
            uint256 tGame,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tLiquidity, tDonation, tBurn, tGame);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);
        _takeDonation(tDonation);
        _takeBurn(tBurn);
        _takeGame(tGame);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function setMaxTxAmount(uint256 newAmount) external onlyOwner returns (bool){
        emit MaxTxAmountUpdated(_maxTxAmount, newAmount);
        _maxTxAmount = newAmount;
        return true;
    }

    function updateLockPeriod(uint256 newPeriod) external onlyOwner returns(bool){
        lockPeriod = newPeriod;
        return true;
    }

    function manualLockUpdate(address recipient, uint256 newPeriod) external onlyOwner returns(bool){
        _lockedTime[recipient] = newPeriod;
        return true;
    }

    function _takeDonation(uint256 tDonation) private {
        uint256 currentRate = _getRate();
        uint256 rDonation = tDonation.mul(currentRate);
        _rOwned[_donationAddress] = _rOwned[_donationAddress].add(rDonation);
        if(_isExcluded[_donationAddress])
            _tOwned[_donationAddress] = _tOwned[_donationAddress].add(tDonation);
    }

    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rBurn);
        if(_isExcluded[_burnAddress])
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tBurn);
    }

    function _takeGame(uint256 tGame) private {
        uint256 currentRate = _getRate();
        uint256 rGame = tGame.mul(currentRate);
        _rOwned[_gameAddress] = _rOwned[_gameAddress].add(rGame);
        if(_isExcluded[_gameAddress])
            _tOwned[_gameAddress] = _tOwned[_gameAddress].add(tGame);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);

        _rOwned[_liqidityAddress] = _rOwned[_liqidityAddress].add(rLiquidity);

        if(_isExcluded[_liqidityAddress])
            _tOwned[_liqidityAddress] = _tOwned[_liqidityAddress].add(tLiquidity);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getTValues(
        uint256 tAmount
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_liqidityFee).div(100);
        uint256 tDonation = tAmount.mul(_donationFee).div(100);
        uint256 tBurn = tAmount.mul(_burnFee).div(100);
        uint256 tGame = tAmount.mul(_gameFee).div(100);

        uint256 tTotalFees = tFee.add(tLiquidity).add(tDonation).add(tBurn).add(tGame);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        return (tFee, tLiquidity, tDonation, tBurn, tGame, tTransferAmount);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tDonation,
        uint256 tBurn,
        uint256 tGame
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDonation = tDonation.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rGame = tGame.mul(currentRate);

        uint256 totalFees = rFee.add(rLiquidity).add(rDonation).add(rBurn).add(rGame);
        uint256 rTransferAmount = rAmount.sub(totalFees);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

}