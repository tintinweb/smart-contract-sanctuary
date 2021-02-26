/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: UNLICENSED
//   _    _ _   _                __ _                            
//  | |  (_) | | |              / _(_)                           
//  | | ___| |_| |_ ___ _ __   | |_ _ _ __   __ _ _ __   ___ ___ 
//  | |/ / | __| __/ _ \ '_ \  |  _| | '_ \ / _` | '_ \ / __/ _ \
//  |   <| | |_| ||  __/ | | |_| | | | | | | (_| | | | | (_|  __/
//  |_|\_\_|\__|\__\___|_| |_(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//
//  KittenSwap Lending v0
//
//  https://www.KittenSwap.org/
//
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require (c >= a, "!!add");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require (b <= a, "!!sub");
        uint256 c = a - b;
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require (b <= a, errorMessage);
        uint c = a - b;
        return c;
    }    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require (c / a == b, "!!mul");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require (b > 0, "!!div");
        uint256 c = a / b;
        return c;
    }
}

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

////////////////////////////////////////////////////////////////////////////////

interface LIQUID_TOKEN {
    function totalSupply (  ) external view returns ( uint256 );
    function getTokenReserve (  ) external view returns ( uint256 );
    function getEthReserve (  ) external view returns ( uint256 );
    
    function balanceOf ( address account ) external view returns ( uint256 );
    function transfer ( address recipient, uint256 amount ) external returns ( bool );
    function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );    
    
    function buyToken ( uint256 minTokenAmt, uint256 expireTimestamp ) external payable;    
    function sellToken ( uint256 tokenAmt, uint256 minEthAmt, uint256 expireTimestamp ) external;
}

////////////////////////////////////////////////////////////////////////////////

contract KittenETHv0 is ERC20Detailed
{
    using SafeMath for uint;
    
    address public constant LIQUID_ADDR = 0xC618D56b6D606E59c6B87Af724AB5a91eb40D1cb;
    uint public MIGRATION_TIMESTAMP = 0;               // for migration
    uint public MIGRATION_LIQUIDATION_WAIT = 14 days;  // gov can liquidate forgotten loans some days after migration starts
    uint public FLASH_LOAN_BP = 10;                    // in terms of basis points
    
    ////////////////////////////////////////////////////////////////////////////////
    
    LIQUID_TOKEN private constant LIQUID = LIQUID_TOKEN(LIQUID_ADDR);
    address public govAddr;
        
    constructor () public ERC20Detailed("KittenETHv0", "KittenETHv0", 18) {
        govAddr = msg.sender;
    }
    
    modifier govOnly() {
    	require (msg.sender == govAddr, "!gov");
    	_;
    }
    
    function govTransferAddr(address newAddr) external govOnly {
    	require (newAddr != address(0), "!addr");
    	govAddr = newAddr;
    }
    
    function govSetMIGRATION_TIMESTAMP(uint $MIGRATION_TIMESTAMP) external govOnly {
        require ($MIGRATION_TIMESTAMP > block.timestamp);
    	MIGRATION_TIMESTAMP = $MIGRATION_TIMESTAMP;
    }
    
    function govSetFLASH_LOAN_BP(uint $FLASH_LOAN_BP) external govOnly {
        require (FLASH_LOAN_BP <= 60);
    	FLASH_LOAN_BP = $FLASH_LOAN_BP;
    }    
    
    ////////////////////////////////////////////////////////////////////////////////
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require (sender != address(0), "ERC20: transfer from the zero address");
        require (recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    //------------------------------------------------------------------------------
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) internal {
        require (owner != address(0), "ERC20: approve from the zero address");
        require (spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    //------------------------------------------------------------------------------
    
    function _mint(address account, uint amount) internal {
        require (account != address(0), "ERC20: mint to the zero address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require (account != address(0), "ERC20: burn from the zero address");
        
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }
    
    ////////////////////////////////////////////////////////////////////////////////

    uint constant PRICE_SCALE = 10 ** 10;
    function getLiqEthFloorPriceScaled() internal view returns (uint)
    {
        uint AMM_PRODUCT = (LIQUID.getTokenReserve()).mul(LIQUID.getEthReserve());
        uint TOTAL_SUPPLY = LIQUID.totalSupply();

        return PRICE_SCALE.mul(AMM_PRODUCT).div(TOTAL_SUPPLY).div(TOTAL_SUPPLY);
    }
    
    ////////////////////////////////////////////////////////////////////////////////

    event LOCK_ETH(address indexed user, uint ethAmt, uint kethAmt);
    event UNLOCK_ETH(address indexed user, uint ethAmt, uint kethAmt);
    
    function getContractValueInEth() public view returns (uint)
    {
        uint ethValue = (address(this).balance);
        
        uint liqValue = (LIQUID.balanceOf(address(this))).mul(getLiqEthFloorPriceScaled()) / (PRICE_SCALE);
        
        return ethValue.add(liqValue);
    }

    function lockEth() external payable // lock ETH for lending, and mint KittenEth
    {
        //-------- receive ETH from user --------
        address user = msg.sender;
        uint ethInAmt = msg.value;
        require (ethInAmt > 0, '!ethInAmt');
        
        //-------- compute KittenETH mint amt --------
        uint kethMintAmt = 0;
        if (_totalSupply == 0) { 
            kethMintAmt = ethInAmt; // initial price: 1 kETH = 1 ETH
        }
        else {                
            kethMintAmt = ethInAmt.mul(_totalSupply).div(getContractValueInEth().sub(ethInAmt));
        }
        
        //-------- mint KittenETH to user --------
        _mint(user, kethMintAmt);
        emit LOCK_ETH(user, ethInAmt, kethMintAmt);
    }
    
    function unlockEth(uint kethBurnAmt) external // unlock ETH, and burn KittenEth
    {
        require (kethBurnAmt > 0, '!kethBurnAmt');
        address payable user = msg.sender;

        //-------- compute ETH out amt --------
        uint ethOutAmt = kethBurnAmt.mul(getContractValueInEth()).div(_totalSupply);
        require (address(this).balance >= ethOutAmt, '!ethInContract');

        //-------- burn KittenETH from user --------
        _burn(user, kethBurnAmt);
        
        //-------- send ETH to user --------
        user.transfer(ethOutAmt);
        emit UNLOCK_ETH(user, ethOutAmt, kethBurnAmt);
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    mapping (address => uint) public liqLocked;
    
    event LOCK_LIQ(address indexed user, uint liqAmt, uint ethAmt);
    event UNLOCK_LIQ(address indexed user, uint liqAmt, uint ethAmt);    
    
    function lockLiq(uint liqInAmt) external // lock LIQUID to borrow ETH
    {
        require (liqInAmt > 0, '!liqInAmt');
        require (block.timestamp < MIGRATION_TIMESTAMP, '!migration'); // can't lock after migration starts
        address payable user = msg.sender;

        //-------- compute ETH out amt --------
        uint ethOutAmt = liqInAmt.mul(getLiqEthFloorPriceScaled()) / (PRICE_SCALE);
        require (address(this).balance >= ethOutAmt, '!ethInContract');

        //--------  send LIQUID to contract --------
        LIQUID.transferFrom(user, address(this), liqInAmt); 
        liqLocked[user] = liqLocked[user].add(liqInAmt);
        
        //-------- send ETH to user --------
        user.transfer(ethOutAmt);
        emit LOCK_LIQ(user, liqInAmt, ethOutAmt);
    }
    
    function unlockLiq() external payable // payback ETH to unlock LIQUID
    {
        //-------- receive ETH from user --------
        uint ethInAmt = msg.value;
        require (ethInAmt > 0, '!ethInAmt');
        uint ethReturnAmt = 0;
        address payable user = msg.sender;

        //-------- compute LIQUID out amt --------
        uint LiqEthFloorPriceScaled = getLiqEthFloorPriceScaled();

        uint liqOutAmt = ethInAmt.mul(PRICE_SCALE).div(LiqEthFloorPriceScaled);
        if (liqOutAmt > liqLocked[user])
        {
            liqOutAmt = liqLocked[user];
            ethReturnAmt = ethInAmt.sub(
                    liqOutAmt.mul(LiqEthFloorPriceScaled) / (PRICE_SCALE)
                );
        }
        
        //--------  send LIQUID to user --------
        liqLocked[user] = liqLocked[user].sub(liqOutAmt);
        LIQUID.transfer(user, liqOutAmt);
        
        //-------- return extra ETH to user --------
        if (ethReturnAmt > 10 ** 8) { // ignore dust
            user.transfer(ethReturnAmt);
        }
        emit UNLOCK_LIQ(user, liqOutAmt, ethInAmt.sub(ethReturnAmt));
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    receive() external payable { // receive ETH (from selling LIQUID)
        require(msg.sender == LIQUID_ADDR, '!sender');
    }

    function flashUnlockLiqAndSell(address payable user, uint liqUnlockAmt, uint liqSellAmt, uint liqSellMinEthAmt, uint liqSellExpireTimestamp) external payable
    {
        require (
            (user == msg.sender) 
            || // gov can liquidate forgotten loans some days after migration starts
            ((block.timestamp.sub(MIGRATION_LIQUIDATION_WAIT) > MIGRATION_TIMESTAMP) && (govAddr == msg.sender))
        , '!user');
        
        if (liqUnlockAmt > liqLocked[user])
            liqUnlockAmt = liqLocked[user];
        if (liqSellAmt > liqUnlockAmt)
            liqSellAmt = liqUnlockAmt;

        //-------- receive ETH from user --------
        uint ethInAmt = msg.value;
        
        //-------- compute ETH required for unlocking LIQUID --------
        uint ethBorrowAmt = 0;
        uint ethOutAmt = 0;
        
        uint ethRequiredForUnlock = liqUnlockAmt.mul(getLiqEthFloorPriceScaled()) / (PRICE_SCALE);
        if (ethRequiredForUnlock > ethInAmt) {
            ethBorrowAmt = (ethRequiredForUnlock - ethInAmt).mul(10000 + FLASH_LOAN_BP) / 10000; // add FLASH_LOAN_BP fee
        } else {
            ethOutAmt = ethInAmt - ethRequiredForUnlock;
        }

        //-------- sell LIQUID --------
        uint liqLoss = 0;
        uint ethGain = 0;
        if (liqSellAmt > 0)
        {
            uint liqBefore = LIQUID.balanceOf(address(this));
            uint ethBefore = address(this).balance;
            
            LIQUID.sellToken(liqSellAmt, liqSellMinEthAmt, liqSellExpireTimestamp); // sell LIQUID
    
            liqLoss = liqBefore.sub(LIQUID.balanceOf(address(this)), '!liqLoss'); // now contract has less LIQUID
            ethGain = (address(this).balance).sub(ethBefore, '!ethGain'); // now contract has more ETH            
        }
        
        //-------- payback flash-loan (if occured) --------
        if (ethBorrowAmt > 0) { // ethOutAmt = 0
            ethOutAmt = ethGain.sub(ethBorrowAmt, '!ethBorrowAmt'); // will throw if not enough
        } else { // ethBorrowAmt = 0
            ethOutAmt = ethOutAmt.add(ethGain);
        }

        //-------- unlock LIQUID --------
        liqLocked[user] = liqLocked[user].sub(liqUnlockAmt, '!liqUnlockAmt');
        
        //-------- send LIQUID to user --------
        if (liqUnlockAmt > liqLoss) {
            LIQUID.transfer(user, liqUnlockAmt - liqLoss);
        }
        //-------- send ETH to user --------
        if (ethOutAmt > 10 ** 8) { // ignore dust
            user.transfer(ethOutAmt);
        }
        
        emit UNLOCK_LIQ(user, liqUnlockAmt, ethRequiredForUnlock);
    }
    
    function flashBuyLiqAndLock(uint ethBorrowAmt, uint liqLockAmt, uint liqBuyMinAmt, uint liqBuyExpireTimestamp) external payable
    {
        require (block.timestamp < MIGRATION_TIMESTAMP, '!migration'); // can't lock after migration starts        
        address payable user = msg.sender;
        
        //-------- receive ETH from user --------
        uint ethInAmt = msg.value;
        
        //-------- buy LIQUID --------
        uint liqGain = 0;
        uint ethLoss = 0;
        {
            uint liqBefore = LIQUID.balanceOf(address(this));
            uint ethBefore = address(this).balance;
            
            //-------- borrow flash-loan --------
            uint ethTotalInAmt = ethInAmt.add(ethBorrowAmt);
            
            require (ethBefore >= ethTotalInAmt, '!ethInContract');
            LIQUID.buyToken {value: ethTotalInAmt} (liqBuyMinAmt, liqBuyExpireTimestamp); // buy LIQUID
    
            liqGain = (LIQUID.balanceOf(address(this))).sub(liqBefore, '!liqGain'); // now contract has more LIQUID
            ethLoss = ethBefore.sub(address(this).balance, '!ethLoss'); // now contract has less ETH            
        }
        
        //-------- compute ETH gain from locking LIQUID --------
        if (liqLockAmt > liqGain) {
            liqLockAmt = liqGain;
        }
        uint ethLockOutAmt = liqLockAmt.mul(getLiqEthFloorPriceScaled()) / (PRICE_SCALE);
        
        //-------- payback flash-loan --------
        uint ethOutAmt = ethInAmt.add(ethLockOutAmt).sub(ethLoss, '!ethLockOutAmt'); // will throw if not enough
        ethOutAmt = ethOutAmt.sub(ethBorrowAmt.mul(FLASH_LOAN_BP) / 10000, '!ethBorrowAmt');

        //-------- lock LIQUID --------
        liqLocked[user] = liqLocked[user].add(liqLockAmt);
        
        //-------- send LIQUID to user --------
        if (liqGain > liqLockAmt) {
            LIQUID.transfer(user, liqGain - liqLockAmt);
        }
        //-------- send ETH to user --------
        if (ethOutAmt > 10 ** 8) { // ignore dust
            require (address(this).balance >= ethOutAmt, '!ethOutAmt');
            user.transfer(ethOutAmt);
        }
        
        emit LOCK_LIQ(user, liqLockAmt, ethLockOutAmt);
    }
}