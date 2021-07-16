//SourceUnit: EverToken.sol

// SPDX-License-Identifier: UNLICENSED
/*
https://everin.one/
*/
pragma solidity >=0.5.8 <=0.5.14;



contract Context {

    constructor() internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}


contract ERC20 is Context, IERC20 {
    
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => bool) internal _whitelist;
    bool internal _liquidityCreationPeriod;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _liquidityCreationPeriod=true;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_liquidityCreationPeriod==false || _whitelist[recipient]==true,
        "token purchase is not available during the liquidity creation period");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() internal {
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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

    function () external payable;
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address token_addr) external returns (uint256);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256);
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address exchange_addr) external returns (uint256);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_trx_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address exchange_addr) external returns (uint256);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_trx_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256);
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
    function tokenAddress() external view returns (address);
    function factoryAddress() external view returns (address);
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}


contract EverToken is ERC20, Ownable {
    using SafeMath for uint256;

    event Burned(address indexed burner, uint256 burnAmount);
    event MintedReward(address indexed minter, uint256 mintAmount);

    IJustswapExchange public swapExchange;
    address public spendingAndPromotion;
    address public developer;
    

    constructor(
        address _developer,
        address _spendingAndPromotion,
        uint256 _forJustSwapAmount
    ) public ERC20("EverToken", "EVER", 18) {
        spendingAndPromotion = _spendingAndPromotion;
        developer = _developer;
        _mint(msg.sender, _forJustSwapAmount);
    }
    

    function initWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = true;
        }
    }

    function mintReward(uint256 _amount) external onlyOwner {
        uint256 amountForDeveloper = _amount.div(100); //1%
        uint256 amountForTeam = amountForDeveloper.mul(9); //9%
        _mint(address(owner()), _amount);
        _mint(developer, amountForDeveloper);
        _mint(spendingAndPromotion, amountForTeam);
        emit MintedReward(
            owner(),
            _amount.add(amountForDeveloper).add(amountForTeam)
        );
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    function openJustswapExchange(address payable _swapExchange) external onlyOwner {
        require(address(swapExchange) == address(0));
        swapExchange = IJustswapExchange(_swapExchange);
        _liquidityCreationPeriod=false;
    }

    /**
     * @notice external price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTokensCanBeBought(uint256 trx_sold)
        external
        view
        returns (uint256)
    {
        if (address(swapExchange) == address(0)) {
            return 0;
        }
        return swapExchange.getTrxToTokenInputPrice(trx_sold);
    }

    /**
     * @notice external price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTRXneededToBuy(uint256 tokens_bought)
        external
        view
        returns (uint256)
    {
        if (address(swapExchange) == address(0)) {
            return 0;
        }
        return swapExchange.getTrxToTokenOutputPrice(tokens_bought);
    }

    /**
     * @notice external price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTRXcanBeBought(uint256 tokens_sold)
        external
        view
        returns (uint256)
    {
        if (address(swapExchange) == address(0)) {
            return 0;
        }
        return swapExchange.getTokenToTrxInputPrice(tokens_sold);
    }

    /**
     * @notice external price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokensNeededToBuy(uint256 trx_bought)
        external
        view
        returns (uint256)
    {
        if (address(swapExchange) == address(0)) {
            return 0;
        }
        return swapExchange.getTokenToTrxOutputPrice(trx_bought);
    }
}