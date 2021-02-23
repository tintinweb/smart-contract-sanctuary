/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

//   _    _ _   _                __ _                            
//  | |  (_) | | |              / _(_)                           
//  | | ___| |_| |_ ___ _ __   | |_ _ _ __   __ _ _ __   ___ ___ 
//  | |/ / | __| __/ _ \ '_ \  |  _| | '_ \ / _` | '_ \ / __/ _ \
//  |   <| | |_| ||  __/ | | |_| | | | | | | (_| | | | | (_|  __/
//  |_|\_\_|\__|\__\___|_| |_(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//
//  LIQUID : a token with deep floor liquidity & ever-rising floor price
//
//  https://www.KittenSwap.org
//
//  https://www.Kitten.finance
//
pragma solidity ^0.5.17;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
}

////////////////////////////////////////////////////////////////////////////////

contract LIQUID is ERC20Detailed 
{
    address public DEPLOYER = 0xD8d71629950cE53d7E9F94619b09058D9D9f5866;
    uint public constant INITIAL_EthReserve = 2100 * (10 ** 18);
    uint public constant INITIAL_TokenReserve = 21000 * (10 ** 18);
    
    ////////////////////////////////////////////////////////////////////////////////
    
    using SafeMath for uint;
    
    uint public MARKET_OPEN_STAGE = 0; // 0: closed; 1: open;
    
    uint public MARKET_BUY_ETH_LIMIT = (10 ** 18) / 1000; // 0: ignore; x: limit purchase amt;
    
    address public MARKET_WHITELIST_TOKEN = address(0);
    uint public MARKET_WHITELIST_TOKEN_BP = 10 * 10000; // 0: ignore; x: require y TOKEN to hold [x * y / 10000] LIQUID
    
    uint public MARKET_WHITELIST_BASE_AMT = 10 * (10 ** 18); // can always own some LIQUID

    ////////////////////////////////////////////////////////////////////////////////
    
    uint public gTransferBurnBP = 60;
    uint public gSellBurnBP = 60;
    uint public gSellTreasuryBP = 0;
    
    // special BurnBP for some addresses
    mapping (address => uint) public gTransferFromBurnBP;
    mapping (address => uint) public gTransferToBurnBP;
    
    ////////////////////////////////////////////////////////////////////////////////
    
    uint public gContractCheckBuyLevel = 3; // 0: no check; 1: methodA; 2: methodB; 3: both;
    uint public gContractCheckSellLevel = 3; // 0: no check; 1: methodA; 2: methodB; 3: both;
    
    mapping (address => uint) public gContractWhitelist; // 0: disableALL; 1: disableBUY; 2: disableSELL; 3: allowALL;
    
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    ////////////////////////////////////////////////////////////////////////////////

    address constant tokenFactoryAddr = 0x1111111111111111111111111111111111111111;
    
    address public govAddr;
    
    address public treasuryAddr;
    uint public treasuryAmtTotal = 0;

    constructor () public ERC20Detailed("LIQUID", "LIQUID", 18) {
        if (msg.sender == DEPLOYER) {
            govAddr = msg.sender;
            treasuryAddr = msg.sender;
            _mint(tokenFactoryAddr, INITIAL_TokenReserve);
        }        
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
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        //------------------------------------------------------------------------------

        // 0         ===> default BurnBP
        // 1 ~ 10000 ===> customized BurnBP
        // >10000    ===> zero BurnBP
        
        uint fromBurnBP = gTransferFromBurnBP[sender];
        if (fromBurnBP == 0)
            fromBurnBP = gTransferBurnBP;
        else if (fromBurnBP > 10000)
            fromBurnBP = 0;

        uint toBurnBP = gTransferToBurnBP[recipient];
        if (toBurnBP == 0)
            toBurnBP = gTransferBurnBP;
        else if (toBurnBP > 10000)
            toBurnBP = 0;

        uint BurnBP = fromBurnBP; // BurnBP = min(fromBurnBP, toBurnBP)
        if (BurnBP > toBurnBP)
            BurnBP = toBurnBP;
        
        if (BurnBP > 0) {
            uint burnAmt = amount.mul(BurnBP).div(10000);
            _burn(recipient, burnAmt);
        }
    }
    function _transferRawNoBurn(address sender, address recipient, uint amount) internal {
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
        
        if (amount == 0) return;
        if (_balances[account] == 0) return;

        if (account != tokenFactoryAddr) {

            _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
            emit Transfer(account, address(0), amount);

            //------------------------------------------------------------------------------
            // AutoBoost : because totalSupply is reduced, we can burn tokenReserve to boost price
            // Check our Medium on https://www.Kitten.finance for details
            //------------------------------------------------------------------------------
            
            uint TokenReserve = _balances[tokenFactoryAddr];
            
            if (_totalSupply > TokenReserve) { // shall always satisfy
                uint extraBurn = TokenReserve.mul(amount).div(_totalSupply.sub(TokenReserve));
                _balances[tokenFactoryAddr] = TokenReserve.sub(extraBurn);
                emit Transfer(tokenFactoryAddr, address(0), extraBurn);
                
                _totalSupply = _totalSupply.sub(amount).sub(extraBurn);
            } else {
                _totalSupply = _totalSupply.sub(amount);
            }
        }
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }    
    
    ////////////////////////////////////////////////////////////////////////////////

    function getEthReserve() public view returns (uint) {
        return INITIAL_EthReserve.add(address(this).balance).sub(treasuryAmtTotal);
    }

    function getTokenReserve() public view returns (uint) {
        return _balances[tokenFactoryAddr];
    }
    
    event BuyToken(address indexed user, uint tokenAmt, uint ethAmt);
    event SellToken(address indexed user, uint tokenAmt, uint ethAmt);

    function buyToken(uint minTokenAmt, uint expireTimestamp) external payable 
    {
        address user = msg.sender;

        if (gContractWhitelist[user] < 2) { // 0: disableALL; 1: disableBUY; 2: disableSELL; 3: allowALL;
            if (gContractCheckBuyLevel % 2 == 1) require(!isContract(user), '!human'); // 0: no check; 1: methodA; 2: methodB; 3: both;
            if (gContractCheckBuyLevel >= 2) require(user == tx.origin, '!human');     // 0: no check; 1: methodA; 2: methodB; 3: both;
        }

        require ((MARKET_OPEN_STAGE > 0) || (user == govAddr), '!market'); // govAddr can test contract before market open
        require (msg.value > 0, '!eth');
        require (minTokenAmt > 0, '!minToken');
        require ((expireTimestamp == 0) || (block.timestamp <= expireTimestamp), '!expire');
        require ((MARKET_BUY_ETH_LIMIT == 0) || (msg.value <= MARKET_BUY_ETH_LIMIT), '!ethLimit');
        
        //------------------------------------------------------------------------------
        
        uint newEthReserve = INITIAL_EthReserve.add(address(this).balance).sub(treasuryAmtTotal);
        uint oldEthReserve = newEthReserve.sub(msg.value);

        uint oldTokenReserve = _balances[tokenFactoryAddr];
        uint newTokenReserve = (oldEthReserve.mul(oldTokenReserve).add(newEthReserve / 2)).div(newEthReserve);
        
        uint outTokenAmt = oldTokenReserve.sub(newTokenReserve);
        require (outTokenAmt > 0, '!outToken');
        require (outTokenAmt >= minTokenAmt, "KittenSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        
        if ((MARKET_WHITELIST_TOKEN_BP > 0) && (MARKET_WHITELIST_TOKEN != address(0))) 
        {
            uint amtWhitelistToken = IERC20(MARKET_WHITELIST_TOKEN).balanceOf(user);
            uint amtLimit = amtWhitelistToken.mul(MARKET_WHITELIST_TOKEN_BP).div(10000);
            
            if (amtLimit < MARKET_WHITELIST_BASE_AMT) {
                amtLimit = MARKET_WHITELIST_BASE_AMT;
            }
            
            require (_balances[user].add(outTokenAmt) <= amtLimit, '!need-more-whitelist-token');
        }

        _transferRawNoBurn(tokenFactoryAddr, user, outTokenAmt);

        //------------------------------------------------------------------------------
        
        emit BuyToken(user, outTokenAmt, msg.value);
    }
    
    event LOG(uint step);
    
    function sellToken(uint tokenAmt, uint minEthAmt, uint expireTimestamp) external 
    {
        address payable user = msg.sender;

        if (gContractWhitelist[user] % 2 == 0) { // 0: disableALL; 1: disableBUY; 2: disableSELL; 3: allowALL;
            if (gContractCheckSellLevel % 2 == 1) require(!isContract(user), '!human'); // 0: no check; 1: methodA; 2: methodB; 3: both;
            if (gContractCheckSellLevel >= 2) require(user == tx.origin, '!human');     // 0: no check; 1: methodA; 2: methodB; 3: both;
        }

        require (tokenAmt > 0, '!token');
        require (minEthAmt > 0, '!minEth');
        require ((expireTimestamp == 0) || (block.timestamp <= expireTimestamp), '!expire');
        
        uint burnAmt = tokenAmt.mul(gSellBurnBP).div(10000);
        _burn(user, burnAmt);
        uint tokenAmtAfterBurn = tokenAmt.sub(burnAmt);

        //------------------------------------------------------------------------------

        uint oldEthReserve = INITIAL_EthReserve.add(address(this).balance).sub(treasuryAmtTotal);
        uint oldTokenReserve = _balances[tokenFactoryAddr];

        uint newTokenReserve = oldTokenReserve.add(tokenAmtAfterBurn);
        uint newEthReserve = (oldEthReserve.mul(oldTokenReserve).add(newTokenReserve / 2)).div(newTokenReserve);
        
        uint outEthAmt = oldEthReserve.sub(newEthReserve);
        require (outEthAmt > 0, '!outEth');
        require (outEthAmt >= minEthAmt, "KittenSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        _transferRawNoBurn(user, tokenFactoryAddr, tokenAmtAfterBurn);

        //------------------------------------------------------------------------------

        if (gSellTreasuryBP > 0) 
        {
            uint treasuryAmt = outEthAmt.mul(gSellTreasuryBP).div(10000);
            treasuryAmtTotal = treasuryAmtTotal.add(treasuryAmt);
            user.transfer(outEthAmt.sub(treasuryAmt));
        } 
        else
        {
            user.transfer(outEthAmt);
        }
        
        emit SellToken(user, tokenAmt, outEthAmt);
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    modifier govOnly() 
    {
    	require(msg.sender == govAddr, "!gov");
    	_;
    }
    
    function govTransferAddr(address newAddr) external govOnly 
    {
    	require(newAddr != address(0), "!addr");
    	govAddr = newAddr;
    }
    
    function govOpenMarket() external govOnly
    {
        MARKET_OPEN_STAGE = 1;
    }

    function govSetTreasury(address newAddr) external govOnly
    {
    	require(newAddr != address(0), "!addr");
    	treasuryAddr = newAddr;
    }    
    
    function govSetBurn(uint transferBurnBP, uint sellBurnBP, uint sellTreasuryBP) external govOnly
    {
        require (transferBurnBP <= 60);
        require (sellBurnBP <= 60);
        require (sellTreasuryBP <= 30);
        require (sellTreasuryBP <= sellBurnBP);
        require (sellBurnBP.add(sellTreasuryBP) <= 60);
        
        gTransferBurnBP = transferBurnBP;
        gSellBurnBP = sellBurnBP;
        gSellTreasuryBP = sellTreasuryBP;
    }
    
    function govSetBurnForAddress(address addr, uint transferFromBurnBP, uint transferToBurnBP) external govOnly
    {
        // 0         ===> default BurnBP
        // 1 ~ 10000 ===> customized BurnBP
        // 10001     ===> zero BurnBP
        require (transferFromBurnBP <= 10001);
        require (transferToBurnBP <= 10001);
        
        gTransferFromBurnBP[addr] = transferFromBurnBP;
        gTransferToBurnBP[addr] = transferToBurnBP;
    }

    function govSetContractCheckLevel(uint buyLevel, uint sellLevel) external govOnly
    {
        gContractCheckBuyLevel = buyLevel;
        gContractCheckSellLevel = sellLevel;
    }
    function govSetContractWhiteList(address addr, uint state) external govOnly
    {
        gContractWhitelist[addr] = state;
    }
    
    function govSetBuyLimit(uint new_MARKET_BUY_ETH_LIMIT) external govOnly 
    {
        MARKET_BUY_ETH_LIMIT = new_MARKET_BUY_ETH_LIMIT;
    }

    function govSetWhitelistToken(address new_MARKET_WHITELIST_TOKEN, uint new_MARKET_WHITELIST_TOKEN_BP) external govOnly 
    {
        MARKET_WHITELIST_TOKEN = new_MARKET_WHITELIST_TOKEN;
        MARKET_WHITELIST_TOKEN_BP = new_MARKET_WHITELIST_TOKEN_BP;
    }
    
    function govSetWhitelistBaseAmt(uint new_MARKET_WHITELIST_BASE_AMT) external govOnly 
    {
        MARKET_WHITELIST_BASE_AMT = new_MARKET_WHITELIST_BASE_AMT;
    }    
    
    ////////////////////////////////////////////////////////////////////////////////

    modifier treasuryOnly() 
    {
    	require(msg.sender == treasuryAddr, "!treasury");
    	_;
    }    
    
    function treasurySend(uint amt) external treasuryOnly
    {
        require(amt <= treasuryAmtTotal);

        treasuryAmtTotal = treasuryAmtTotal.sub(amt);
        
        address payable _treasuryAddr = address(uint160(treasuryAddr));
        _treasuryAddr.transfer(amt);
    }
}