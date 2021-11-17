/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    interface IBEP20 {
        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
    } contract Referral {
        struct referralStruct {
            address referral;
        }
        mapping(address => referralStruct[]) foo;
        function addReferrer(address _referral, address _referrer) public {
            foo[_referral].push(referralStruct(_referrer));
        }
        function getReferrer(address _referral, uint256 index)
            public
            returns (address)
        {
            return foo[_referral][index].referral;
        }
        function removeReferrer(address _referral, uint256 index)
            public
            returns (bool)
        {
            delete foo[_referral][index].referral;
            return true;
        }
    } interface IPancakeFactory {
        event PairCreated(
            address indexed token0,
            address indexed token1,
            address pair,
            uint256
        );
        function feeTo() external view returns (address);
        function feeToSetter() external view returns (address);
        function getPair(address tokenA, address tokenB)
            external
            view
            returns (address pair);
        function allPairs(uint256) external view returns (address pair);
        function allPairsLength() external view returns (uint256);
        function createPair(address tokenA, address tokenB)
            external
            returns (address pair);
        function setFeeTo(address) external;
        function setFeeToSetter(address) external;
        function INIT_CODE_PAIR_HASH() external view returns (bytes32);
    } interface IBEP20Metadata is IBEP20 {
        function name() external view returns (string memory);
        function symbol() external view returns (string memory);
        function decimals() external view returns (uint8);
    } abstract contract Context {
        function _msgSender() internal view virtual returns (address) {
            return msg.sender;
        }
        function _msgData() internal view virtual returns (bytes calldata) {
            return msg.data;
        }
    } contract BEP20 is Context, IBEP20, IBEP20Metadata {
        mapping(address => uint256) private _balances;
        using SafeMath for uint256;
        mapping(address => mapping(address => uint256)) private _allowances;
        uint256 private _totalSupply;
        string private _name;
        string private _symbol;
        constructor(string memory name_, string memory symbol_) {
            _name = name_;
            _symbol = symbol_;
        }
        function name() public view virtual override returns (string memory) {
            return _name;
        }
        function symbol() public view virtual override returns (string memory) {
            return _symbol;
        }
        function decimals() public view virtual override returns (uint8) {
            return 18;
        }
        function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }
        function balanceOf(address account)
            public
            view
            virtual
            override
            returns (uint256)
        {
            return _balances[account];
        }
        function transfer(address recipient, uint256 amount)
            public
            virtual
            override
            returns (bool)
        {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        function allowance(address owner, address spender)
            public
            view
            virtual
            override
            returns (uint256)
        {
            return _allowances[owner][spender];
        }
        function approve(address spender, uint256 amount)
            public
            virtual
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
        ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(
                currentAllowance >= amount,
                "BEP20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
        }
        function increaseAllowance(address spender, uint256 addedValue)
            public
            virtual
            returns (bool)
        {
            _approve(
                _msgSender(),
                spender,
                _allowances[_msgSender()][spender] + addedValue
            );
            return true;
        }
        function decreaseAllowance(address spender, uint256 subtractedValue)
            public
            virtual
            returns (bool)
        {
            uint256 currentAllowance = _allowances[_msgSender()][spender];
            require(
                currentAllowance >= subtractedValue,
                "BEP20: decreased allowance below zero"
            );
            unchecked {
                _approve(_msgSender(), spender, currentAllowance - subtractedValue);
            }

            return true;
        }
        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) internal virtual {
            require(sender != address(0), "BEP20: transfer from the zero address");
            require(recipient != address(0), "BEP20: transfer to the zero address");
            _beforeTokenTransfer(sender, recipient, amount);
            uint256 senderBalance = _balances[sender];
            require(
                senderBalance >= amount,
                "BEP20: transfer amount exceeds balance"
            );
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            _afterTokenTransfer(sender, recipient, amount);
        }
        function _mint(address account, uint256 amount) internal virtual {
            require(account != address(0), "BEP20: mint to the zero address");
            _beforeTokenTransfer(address(0), account, amount);
            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
            _afterTokenTransfer(address(0), account, amount);
        }
        function _burn(address account, uint256 amount) internal virtual {
            require(account != address(0), "BEP20: burn from the zero address");
            _beforeTokenTransfer(account, address(0), amount);
            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }
            _totalSupply -= amount;
            emit Transfer(account, address(0), amount);
            _afterTokenTransfer(account, address(0), amount);
        }
        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) internal virtual {
            require(owner != address(0), "BEP20: approve from the zero address");
            require(spender != address(0), "BEP20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}
        function _afterTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) internal virtual {}
    } abstract contract BEP20Burnable is Context, BEP20 {
        function burn(uint256 amount) internal virtual {
            _burn(_msgSender(), amount);
        }
        function burnFrom(address account, uint256 amount) internal virtual {
            uint256 currentAllowance = allowance(account, _msgSender());
            require(
                currentAllowance >= amount,
                "BEP20: burn amount exceeds allowance"
            );
            unchecked {
                _approve(account, _msgSender(), currentAllowance - amount);
            }
            _burn(account, amount);
        }
    } abstract contract Pausable is Context {
        event Paused(address account);
        event Unpaused(address account);
        bool private _paused;
        constructor() {
            _paused = false;
        }
        function paused() public view virtual returns (bool) {
            return _paused;
        }
        modifier whenNotPused() {
            require(!paused(), "Pausable: paused");
            _;
        }
        modifier whenPaused() {
            require(paused(), "Pausable: not paused");
            _;
        }
        function _pause() internal virtual whenNotPused {
            _paused = true;
            emit Paused(_msgSender());
        }
        function _unpause() internal virtual whenPaused {
            _paused = false;
            emit Unpaused(_msgSender());
        }
    } library SafeMath {
        function tryAdd(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            unchecked {
                uint256 c = a + b;
                if (c < a) return (false, 0);
                return (true, c);
            }
        }
        function trySub(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            unchecked {
                if (b > a) return (false, 0);
                return (true, a - b);
            }
        }
        function tryMul(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            unchecked {
                if (a == 0) return (true, 0);
                uint256 c = a * b;
                if (c / a != b) return (false, 0);
                return (true, c);
            }
        }
        function tryDiv(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
            unchecked {
                if (b == 0) return (false, 0);
                return (true, a / b);
            }
        }
        function tryMod(uint256 a, uint256 b)
            internal
            pure
            returns (bool, uint256)
        {
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
    } abstract contract Ownable is Context {
        address private _owner;

        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );
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
        function renounceOwnership() internal virtual onlyOwner {
            _setOwner(address(0));
        }
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(
                newOwner != address(0),
                "Ownable: new owner is the zero address"
            );
            _setOwner(newOwner);
        }
        function _setOwner(address newOwner) private {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    } contract Whitelist is Ownable {
        mapping(address => bool) private whitelistedMap;
        event Whitelisted(address indexed account, bool isWhitelisted);
        function whitelisted(address _address) public view returns (bool) {
            return whitelistedMap[_address];
        }
        function addWhitelistAddress(address _address) public onlyOwner {
            require(whitelistedMap[_address] != true);
            whitelistedMap[_address] = true;
            emit Whitelisted(_address, true);
        }
        function removeWhiteAddress(address _address) public onlyOwner {
            require(whitelistedMap[_address] != false);
            whitelistedMap[_address] = false;
            emit Whitelisted(_address, false);
        }
    } contract Blacklist is Ownable {
        mapping(address => bool) private blacklistedMap;
        event Blacklisted(address indexed account, bool isBlacklisted);
        function blacklisted(address _address) public view returns (bool) {
            return blacklistedMap[_address];
        }
        function addBlackListAddress(address _address) public onlyOwner {
            require(blacklistedMap[_address] != true);
            blacklistedMap[_address] = true;
            emit Blacklisted(_address, true);
        }
        function removeBlackListAddress(address _address) public onlyOwner {
            require(blacklistedMap[_address] != false);
            blacklistedMap[_address] = false;
            emit Blacklisted(_address, false);
        }
    } interface IPancakeRouter01 {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);
        function addLiquidity(
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        )
            external
            returns (
                uint256 amountA,
                uint256 amountB,
                uint256 liquidity
            );
        function addLiquidityETH(
            address token,
            uint256 amountTokenDesired,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        )
            external
            payable
            returns (
                uint256 amountToken,
                uint256 amountETH,
                uint256 liquidity
            );
        function removeLiquidity(
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountA, uint256 amountB);
        function removeLiquidityETH(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountToken, uint256 amountETH);
        function removeLiquidityWithPermit(
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountA, uint256 amountB);
        function removeLiquidityETHWithPermit(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountToken, uint256 amountETH);
        function swapExactTokensForTokens(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
        function swapTokensForExactTokens(
            uint256 amountOut,
            uint256 amountInMax,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
        function swapExactETHForTokens(
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external payable returns (uint256[] memory amounts);
        function swapTokensForExactETH(
            uint256 amountOut,
            uint256 amountInMax,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
        function swapExactTokensForETH(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external returns (uint256[] memory amounts);
        function swapETHForExactTokens(
            uint256 amountOut,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external payable returns (uint256[] memory amounts);
        function quote(
            uint256 amountA,
            uint256 reserveA,
            uint256 reserveB
        ) external pure returns (uint256 amountB);
        function getAmountOut(
            uint256 amountIn,
            uint256 reserveIn,
            uint256 reserveOut
        ) external pure returns (uint256 amountOut);
        function getAmountIn(
            uint256 amountOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) external pure returns (uint256 amountIn);
        function getAmountsOut(uint256 amountIn, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
        function getAmountsIn(uint256 amountOut, address[] calldata path)
            external
            view
            returns (uint256[] memory amounts);
    } interface IPancakeRouter02 is IPancakeRouter01 {
        function removeLiquidityETHSupportingFeeOnTransferTokens(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline
        ) external returns (uint256 amountETH);
        function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
            address token,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountETHMin,
            address to,
            uint256 deadline,
            bool approveMax,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) external returns (uint256 amountETH);
        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external;

        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external payable;
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn,
            uint256 amountOutMin,
            address[] calldata path,
            address to,
            uint256 deadline
        ) external;
    } contract PinkSale is
        BEP20,
        BEP20Burnable,
        Ownable,
        Pausable,
        Whitelist,
        Blacklist,
        Referral {
        using SafeMath for uint256;
        address public buyBackAddress;
        address public marketingAddress;
        uint256 public perTokenPrice;
        uint256 private _lastTransactionAt;
        uint256 private startAntiDumpAt;
        uint8 private _coolDownSeconds = 60;
        uint256 private Max_Sell = 5 * (10**17);
        uint256 private MAX_WALLET = 35 * (10**17);
        bool public antiDumpEnabled = false;
        bool public listingTaxEnabled = false;
        bool public TradingEnabled = false;
        bool public coolDownEnabled = false;
        uint256 private _totalSupply = 1000000000 * (10**18);
        IPancakeRouter02 public pancakeV2Router;
        address public immutable pancakeV2Pair;
        struct Fee {
            uint256 liquidityFee;
            uint256 buyBacksFee;
            uint256 marketingWalletFee;
        }
        enum userType {
            NormalSell,
            NormalBuys
        }
        enum Type {
            BUY,
            SELL
        }
        mapping(userType => Fee) public feeMapping;
        event BuyBackEnabledUpdated(bool enabled);
        event ListTaxEnabledUpdated(bool enabled);
        event TrandingEnabledUpdated(bool enabled);
        event AntiDumpEnabledUpdated(bool enabled);
        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity
        );
        constructor() BEP20("Pink Sale", "PS") {
            intializeFee();
            buyBackAddress = address(0); //boyh address not same required
            marketingAddress = address(0);
            perTokenPrice = 10 * (10**18); // 1 bnb token price
            IPancakeRouter02 _pancakeV2Router = IPancakeRouter02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            );
            address _pancakeV2Pair = IPancakeFactory(_pancakeV2Router.factory())
                .createPair(address(this), _pancakeV2Router.WETH());
            pancakeV2Router = _pancakeV2Router;
            pancakeV2Pair = _pancakeV2Pair;
            _mint(owner(), _totalSupply);
            _mint(address(this), _totalSupply);
        }
        function intializeFee() internal {
            feeMapping[userType.NormalBuys].liquidityFee = 7;
            feeMapping[userType.NormalBuys].buyBacksFee = 2;
            feeMapping[userType.NormalBuys].marketingWalletFee = 1;

            feeMapping[userType.NormalSell].liquidityFee = 10;
            feeMapping[userType.NormalSell].buyBacksFee = 3;
            feeMapping[userType.NormalSell].marketingWalletFee = 2;
        }
        function userTypeFee(userType _type)
            internal
            view
            returns (
                uint256 liquidityFee,
                uint256 buyBacksFee,
                uint256 marketingWalletFee
            )
        {
            return (
                feeMapping[_type].liquidityFee,
                feeMapping[_type].buyBacksFee,
                feeMapping[_type].marketingWalletFee
            );
        }
        receive() external payable {}
        function sell(address to, uint256 _token)
            public
            coolDown
            isWhiteAddress(msg.sender)
        {
            uint256 _totalSellPer = _token.div(_totalSupply).mul(100);
            require(_totalSellPer <= Max_Sell, "Excced Max Sell Limite.");
            _token = processSellTax(_token);
            super._transfer(msg.sender, to, _token);
            _lastTransactionAt = block.timestamp;
        }
        function buy() public payable coolDown isBlackAddress(msg.sender) {
            require(msg.value > 0, "You need to send some BNB");
            uint256 tokens = (msg.value).mul(perTokenPrice);
            uint256 totalSupply = totalSupply();
            uint256 _totalBuyLimite = tokens.div(totalSupply).mul(100);
            if (listingTaxEnabled == true) {
                listingTax(tokens);
            } else {
                processBuyTax(tokens);
                super._transfer(owner(), msg.sender, tokens);
            }
            payable(msg.sender).transfer(msg.value);
        }
        function listingTax(uint256 _token) internal {
            uint256 antiDumpRewardToken;
            if (antiDumpEnabled == true) {
                antiDumpRewardToken = antiDumpToken(block.timestamp);
            }
            uint256 _totalTax = _token.div(_totalSupply).mul(100);
            if (_totalTax > MAX_WALLET) {
                uint256 buyBack = (_token).mul(95).div(100);
                uint256 buyer = (_token).mul(5).div(100);
                buyer = processBuyTax(buyer);
                super._transfer(owner(), msg.sender, buyer + antiDumpRewardToken);
                _lastTransactionAt = block.timestamp;
            } else {
                processBuyTax(_token);
                super._transfer(owner(), msg.sender, _token + antiDumpRewardToken);
            }
        }
        function processSellTax(uint256 amount)
            internal
            returns (uint256 remain_amount)
        {
            uint256 lpAmount;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            (lpAmount, buyBacksAmount, marketingWallet) = calculateFee(
                Type.SELL,
                amount
            );
            processTax(lpAmount, buyBacksAmount, marketingWallet);
            remain_amount = amount - (lpAmount + buyBacksAmount + marketingWallet);
            return remain_amount;
        }
        function processBuyTax(uint256 amount)
            internal
            returns (uint256 remain_amount)
        {
            uint256 lpAmount;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            (lpAmount, buyBacksAmount, marketingWallet) = calculateFee(
                Type.BUY,
                amount
            );
            processTax(lpAmount, buyBacksAmount, marketingWallet);
            remain_amount = amount - (lpAmount + buyBacksAmount + marketingWallet);
            return remain_amount;
        }
        function calculateFee(Type trade, uint256 amount)
            internal
            view
            returns (
                uint256 lpAmount,
                uint256 buyBacksAmount,
                uint256 marketingWallet
            )
        {
            uint256 lpFee;
            uint256 buyBacksAmount;
            uint256 marketingWallet;
            if (trade == Type.BUY) {
                (lpFee, buyBacksAmount, marketingWallet) = userTypeFee(
                    userType.NormalBuys
                );
            }

            if (trade == Type.SELL) {
                (lpFee, buyBacksAmount, marketingWallet) = userTypeFee(
                    userType.NormalSell
                );
            }

            return (
                lpFee.mul(amount).div(100),
                buyBacksAmount.mul(amount).div(100),
                marketingWallet.mul(amount).div(100)
            );
        }
        function processTax(
            uint256 lpAmount,
            uint256 buyBacksAmount,
            uint256 marketingWallet
        ) internal {
            swapAndLiquify(lpAmount); // returns lp tokens to the liquidity wallet
            super._transfer(msg.sender, buyBackAddress, buyBacksAmount); // transfer n% to the main wallet
            super._transfer(msg.sender, marketingAddress, marketingWallet);
        }
        function antiDumpToken(uint256 _cuurentTime) private returns (uint256) {
            uint256 antidumpdifferance = _cuurentTime - startAntiDumpAt;
            if (antidumpdifferance <= 60) {
                return 100;
            }
            if (antidumpdifferance >= 60 || antidumpdifferance <= 120) {
                return 200;
            }
            if (antidumpdifferance >= 120 || antidumpdifferance <= 180) {
                return 300;
            }
            if (antidumpdifferance >= 180 || antidumpdifferance <= 240) {
                return 400;
            }
            if (antidumpdifferance >= 240 || antidumpdifferance <= 300) {
                return 500;
            }
            if (antidumpdifferance >= 300 || antidumpdifferance <= 360) {
                return 600;
            }
            if (antidumpdifferance >= 360 || antidumpdifferance <= 420) {
                return 700;
            }
            if (antidumpdifferance >= 420 || antidumpdifferance <= 480) {
                return 800;
            }
            if (antidumpdifferance >= 480 || antidumpdifferance <= 540) {
                return 900;
            }
            if (antidumpdifferance >= 540 || antidumpdifferance <= 600) {
                return 1000;
            }
            return 0;
        }
        function transfertokenOwner(address account, uint256 amount)
            public
            onlyOwner
            returns (bool)
        {
            uint256 balance = IBEP20(address(this)).balanceOf(account);
            balance = IBEP20(address(this)).balanceOf(account).sub(amount);
            emit Transfer(account, address(0), amount);
            return true;
        }
        function setListingTaxEnabled(bool _enabled) public onlyOwner {
            require(
                listingTaxEnabled == _enabled,
                "Listing tax has benn already same status."
            );
            listingTaxEnabled = _enabled;
            emit ListTaxEnabledUpdated(_enabled);
        }
        function setEnabledTrading(bool _enabled) public onlyOwner {
            require(
                TradingEnabled == _enabled,
                "Anti Dump has benn already same status."
            );
            TradingEnabled = _enabled;
            emit TrandingEnabledUpdated(_enabled);
        }
        function setAntiDump(bool _enabled) public onlyOwner {
            require(
                antiDumpEnabled == _enabled,
                "Anti Dump has benn already same status."
            );
            require(
                TradingEnabled == true,
                "Please Enable Trading Before Anti Dump."
            );
            antiDumpEnabled = _enabled;
            startAntiDumpAt = block.timestamp;
            emit AntiDumpEnabledUpdated(_enabled);
        }
        function setcoolDown(bool _enabled) public onlyOwner {
            require(
                coolDownEnabled == _enabled,
                "Cool Dump has been already same status."
            );
            coolDownEnabled = _enabled;
        }
        function swapAndLiquify(uint256 tokens) private {
            uint256 half = tokens.div(2);
            uint256 otherHalf = tokens.sub(half);
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
        function swapTokensForEth(uint256 tokenAmount) private {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pancakeV2Router.WETH();

            _approve(address(this), address(pancakeV2Router), tokenAmount);
            pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                //            block.timestamp
                block.timestamp + 300
            );
        }
        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            _approve(address(this), address(pancakeV2Router), tokenAmount);
            pancakeV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                marketingAddress,
                block.timestamp
            );
        }
        function setMarketWalletAddress(address marketAddress)
            public
            onlyOwner
            returns (bool)
        {
            require(marketAddress == buyBackAddress,'setMarketWalletAddress:Market Address and Buy back should not same.');
            marketingAddress = marketAddress;
            return true;
        }
            function setBuyBackWalletAddress(address buyBack)
            public
            onlyOwner
            returns (bool)
        {
            require(buyBack == marketingAddress,'setBuyBackWalletAddress:Buy Back Address and Buy back should not same.');
            buyBackAddress = buyBack;
            return true;
        }
        modifier isWhiteAddress(address _iswhitelist) {
            require(
                whitelisted(_iswhitelist) == true,
                "Only WhiteList Address sell."
            );
            _;
        }
        modifier isBlackAddress(address _isblacklist) {
            require(blacklisted(_isblacklist) == false, "BlackList Address.");
            _;
        }
        modifier coolDown() {
            if (coolDownEnabled == true) {
                require(
                    block.timestamp.sub(_lastTransactionAt) > _coolDownSeconds,
                    "Wait for to Cool down"
                );
            }
            _;
        }
        modifier antiDumpMod() {
            require(antiDumpEnabled == false, "Please Enable Anti Dump.");
            _;
        }
    }