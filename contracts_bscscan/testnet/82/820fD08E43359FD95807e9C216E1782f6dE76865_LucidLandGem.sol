// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";



    contract LucidLandGem is Context, IERC20, Ownable {
        using SafeMath for uint256;
        using Address for address;
        
        mapping (address => mapping(address => uint256)) private _allowances;
        mapping (address => bool) public _isBlacklisted;
        mapping (address => bool) public _isCommunity;
        mapping (address => uint256) private _rOwned;
        mapping (address => bool) private _isExcluded;

        address payable constant private _marketingWalletAddress = payable(0x0534474C7D2E7023196c5d5c769cCEc8FcB239BD);
        address payable constant private  _devWalletAddress = payable(0xBd25a03B27CD302CD3681bA3274a36F3Aafc84f7);
        string constant private _name = "LucidLandGem";
        string constant private _symbol = "LLG";
        uint256 constant private _decimals = 18;
        uint256 constant private _totalsupply = 10**8 * 10**18;
        uint256 private _maxWalletToken = 5000000 * 10**18;
        uint256 public _liquidityFee = 3;
        uint256 public _previousLiquidityFee;
        uint256 public _devFee = 3;
        uint256 public _prevDevFee;
        uint256 public _marketingFee = 4;
        uint256 public _prevMarketingFee;
        bool private _presaleActive = true;
        uint256 public deadBlocks = 6;
        uint256 public launchedAt = 0;
        bool public tradingOpen = false;
        uint256 public botFee = 99;

        
        constructor() {
            
            _rOwned[owner()]  = _totalsupply;
            _isExcluded[owner()] = true;
            _isExcluded[address(this)] = true;
            _isExcluded[address(0x000000000000000000000000000000000000dEaD)] = true;
            _isExcluded[address(0x0534474C7D2E7023196c5d5c769cCEc8FcB239BD)] = true;
            _isExcluded[address(0xBd25a03B27CD302CD3681bA3274a36F3Aafc84f7)] = true;
            
            emit Transfer(address(0), owner(), _totalsupply); 
        }
        
        function name() public pure returns (string memory){
            return _name;
        }
        
        function symbol() public pure returns (string memory){
            return _symbol;
        }
        
        function decimals() public pure returns (uint256){
            return _decimals;
        }
        
        function balanceOf(address account) public view override returns (uint256) {
            return _rOwned[account];
        }
        
        function totalSupply() public pure override returns (uint256){
            return _totalsupply;
        }        
        
        
        function transfer(address recipient, uint256 amount) public override returns(bool){
            _transfer(_msgSender(),recipient, amount);
            return true;
        }
        
        function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
            _transfer(sender,recipient,amount);
            
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
            }
        }
        
        function allowance(address owner, address spender) public view override returns(uint256) {
            return _allowances[owner][spender];
        }
        
        function approve(address spender, uint256 amount) public override returns(bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }
        
        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        
        
        function _transfer(address from, address to, uint256 amount) private {
            
            if(to != owner() && to != address(this) &&  to != _marketingWalletAddress && to != _devWalletAddress){
                uint256 heldBalance = balanceOf(to);
                require(heldBalance + amount <= _maxWalletToken, "Transfer amount Exceeds limit");
            }
            
            require(tradingOpen,"Trading not open yet");
            require(!_isBlacklisted[from] && !_isBlacklisted[to], "This address is Blacklisted");
            require(from !=address(0), "transfer from zero adress");
            require(to !=address(0), "transfer to zero adress");
            require(amount > 0, "Transfer Amount Should be greater than 0");
            
            if(launchedAt + deadBlocks > block.number){
                _transferBeforePermitted(from,to,amount);
            }
            else{
                _tokenTransfer(from,to,amount);
                
            }
            
        }
        function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
            uint256 tMarketing = calculateMarketing(tAmount);
            uint256 tDev = calculateDev(tAmount);
            uint256 tTransferAmount = tAmount.sub(tMarketing).sub(tDev);
            return (tTransferAmount, tMarketing, tDev);
        }
        
        function _getSValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
            uint256 sMarketing = calculateMarketing(tAmount);
            uint256 sDev = calculateDev(tAmount);
            uint256 sLiquidity = calculateLiquidity(tAmount);
            uint256 sTransferAmount = tAmount.add(sMarketing).add(sDev).add(sLiquidity);
            return (sTransferAmount, sMarketing, sDev, sLiquidity);
        }
        
        // get fee Before Permitted : Anti-Sniping
        function _getFValues(uint256 tAmount) private view returns (uint256, uint256) {
            uint256 sLiquidity = _getF(tAmount);
            uint256 sTransferAmount = tAmount.sub(sLiquidity);
            return (sTransferAmount, sLiquidity);
        }
        
        function deductFee(uint256 _sMarketing, uint256 _sDev, uint256 _sLiquidity ) private{
            _takeDev(_sDev);
            _takeMarketing(_sMarketing);
            _takeLiquidity(_sLiquidity);
        }


        function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "To/from address is blacklisted!");
        
            if(_presaleActive){
                _transferBothExcluded(sender,recipient,amount);
            }
            else{
        
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
            }
        
        }
        
        
        function _transferBeforePermitted(address sender, address recipient, uint256 tAmount) private
        {
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "To/from address is blacklisted!");
            (uint256 sTransferAmount, uint256 sLiquidity) = _getFValues(tAmount);
            
            
            _rOwned[sender] = _rOwned[sender].sub(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(sTransferAmount);
            _takeLiquidity(sLiquidity);
            emit Transfer(sender, recipient, tAmount);
        }
        
        

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {
         
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "To/from address is blacklisted!");
            (uint256 sTransferAmount, uint256 sMarketing, uint256 sDev, uint256 sLiquidity) = _getSValues(tAmount);
            deductFee(sMarketing, sDev, sLiquidity);
            (uint256 tTransferAmount, uint256 tMarketing,  uint256 tDev) = _getTValues(tAmount);
        
            _rOwned[sender] = _rOwned[sender].sub(sTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount);
            _takeDev(tDev);
            _takeMarketing(tMarketing);
            
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
            
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "To/from address is blacklisted!");
            (uint256 sTransferAmount, uint256 sMarketing, uint256 sDev, uint256 sLiquidity) = _getSValues(tAmount);
            deductFee(sMarketing, sDev, sLiquidity);
        
            _rOwned[sender] = _rOwned[sender].sub(sTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(tAmount);           
            emit Transfer(sender, recipient, tAmount);
        }

        function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
    
       
            require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "To/from address is blacklisted!");
            (uint256 tTransferAmount, uint256 tMarketing,  uint256 tDev) = _getTValues(tAmount);
       
            _rOwned[sender] = _rOwned[sender].sub(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(tTransferAmount);   
            _takeDev(tDev);
            _takeMarketing(tMarketing);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
       
            _rOwned[sender] = _rOwned[sender].sub(tAmount);
            _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        
            emit Transfer(sender, recipient, tAmount);
        }
        
        function _transferCommunity(address[] calldata addresses, uint256 amount) external onlyOwner{
            
            for(uint256 i; i < addresses.length; i++){
                transfer(addresses[i],amount);
            }
        }
        
        
        // Take FEE
        function _takeLiquidity(uint256 amount) private {
            _rOwned[owner()] = _rOwned[owner()].add(amount);
        }
    
        function _takeMarketing(uint256 amount) private {
            _rOwned[_marketingWalletAddress] = _rOwned[_marketingWalletAddress].add(amount);
        }
        
        function _takeDev(uint256 amount) private {
            _rOwned[_devWalletAddress] = _rOwned[_devWalletAddress].add(amount);
        }
        
        
            
        // Block List For Bot / Users  
        function addToBlackList(address[] calldata addresses) external onlyOwner {
            for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = true;
            }
        }
        
        function addToCommuinty(address[] calldata addresses) external onlyOwner {
            for(uint256 i; i < addresses.length; i++){
                _isCommunity[addresses[i]] = true;
            }
        }
        
        function addToExcluded(address[] calldata addresses) external onlyOwner {
            for(uint256 i; i < addresses.length; i++){
                _isExcluded[addresses[i]] = true;
            }
        }
        
        function ispreSaleActive() public view returns (bool) {
            return _presaleActive;
        }
        
        function setpreSaleActive(bool active) external onlyOwner {
            _presaleActive = active;
        }
        
        // Remove Address from BlackList
        function removeFromBlackList(address account) external onlyOwner {
            _isBlacklisted[account] = false;
        }
        
        function removeFromCommuinty(address account) external onlyOwner {
            _isCommunity[account] = false;
        }
    
        //settting the maximum permitted wallet holding (percent of total supply)
        function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
            
            require(maxWallPercent > 5,"Cannot Set Value Less than 5%");
            _maxWalletToken = _totalsupply.mul(maxWallPercent).div(
                10**2
            );
        }
    
        //settting the maximum permitted wallet holding (in tokens)
        function setMaxWalletTokens() external onlyOwner() {
            _maxWalletToken = 10**9 * 10**18;
        }
        
        // FEE Section
        // Calclulation Of FEE
        function calculateLiquidity(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_liquidityFee).div(10**2);
        }
        
        function calculateMarketing(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_marketingFee).div(10**2);
        }
        
        function calculateDev(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_devFee).div(10**2);
        }
        
        // Fee if Buy Before Permitted ; Anti-Sniping
        function _getF(uint256 _amount) private view returns (uint256){
            return _amount.mul(botFee).div(100);
        }
        
        function removeAllFee() external onlyOwner {
            _removeAllFee();
        }
        
        function restoreAllFee() external onlyOwner {
            _restoreAllFee();
        }
        
        function _removeAllFee() private {
            if(_devFee == 0 && _marketingFee == 0 && _liquidityFee == 0) return;
        
            _prevDevFee = _devFee;
            _prevMarketingFee = _marketingFee;
            _previousLiquidityFee = _liquidityFee;
        
            _devFee = 0;
            _marketingFee = 0;
            _liquidityFee = 0;
        }
    
        function _restoreAllFee() private {
            _devFee = _prevDevFee;
            _marketingFee = _prevMarketingFee;
            _liquidityFee = _previousLiquidityFee;
        }
        
        function tradingStatus(bool _status, uint256 _deadBlocks) public onlyOwner {
            tradingOpen = _status;
            if(tradingOpen && launchedAt == 0){
                launchedAt = block.number;
                deadBlocks = _deadBlocks;
            }
        }
        
        function _getLatestBlock() internal view returns(uint256){
            return block.number;
        }
        
    }