/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
/*

888b    888                           888                 8888888b.                    
8888b   888                           888                 888   Y88b                   
88888b  888                           888                 888    888                   
888Y88b 888  8888b.  888d888 888  888 888888 .d88b.       888   d88P 888  888 88888b.  
888 Y88b888     "88b 888P"   888  888 888   d88""88b      8888888P"  888  888 888 "88b 
888  Y88888 .d888888 888     888  888 888   888  888      888 T88b   888  888 888  888 
888   Y8888 888  888 888     Y88b 888 Y88b. Y88..88P      888  T88b  Y88b 888 888  888 
888    Y888 "Y888888 888      "Y88888  "Y888 "Y88P"       888   T88b  "Y88888 888  888 
                                                                                      

Naruto Run is one piece of a larger Metaverse of tokens to come.

100% LP Tokens Burnt
40% of Supply Burnt
No Team Tokens
Continuous Marketing & Calls
Giveaways for token holders

Telegram:
https://t.me/NarutoRunToken

Website:
https://www.narutoruntoken.com
 */

abstract contract Context {

    function _msgSender() internal virtual view returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal virtual view returns (bytes memory) {

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691

        return msg.data;
    }

}


interface IERC20 {

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



    /**

     * @dev Moves `amount` tokens from `sender` to `recipient` using the

     * allowance mechanism. `amount` is then deducted from the caller's

     * allowance.

     *

     * Returns a boolean value indicating whether the operation succeeded.

     *

     * Emits a {Transfer} event.

     */

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

 function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

     function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {

        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );

        return _functionCallWithValue(target, data, value, errorMessage);
    }



    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
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
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    constructor() internal {
        address msgSender = _msgSender();
        _owner =msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
     function owner() public view returns (address) {
        return _owner;
    }



    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }



    /**

     * @dev Leaves the contract without owner. It will not be possible to call

     * `onlyOwner` functions anymore. Can only be called by the current owner.

     *

     * NOTE: Renouncing ownership will leave the contract without an owner,

     * thereby removing any functionality that is only available to the owner.

     */

    function renounceOwnership() public virtual onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(

            newOwner != address(0),

            "Ownable: new owner is the zero address"

        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}





interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}



interface IUniswapV2Pair {

    function sync() external;

}



interface IUniswapV2Router01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(

        address tokenA,

        address tokenB,

        uint amountADesired,

        uint amountBDesired,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(

        address token,

        uint amountTokenDesired,

        uint amountTokenMin,

        uint amountETHMin,

        address to,

        uint deadline

    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}



interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(

      address token,

      uint liquidity,

      uint amountTokenMin,

      uint amountETHMin,

      address to,

      uint deadline

    ) external returns (uint amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external payable;

}



contract NarutoRun is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Naruto Run";
    string private _symbol = "Naruto_Run";
    uint8 private _decimals = 9;


    mapping(address => uint256) internal _reflectionBalance;

    mapping(address => uint256) internal _balanceLimit;

    mapping(address => uint256) internal _tokenBalance;

    mapping(address => mapping(address => uint256)) internal _allowances;

    

    mapping(address => uint256) public userLastBuy;



    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1_000_000_000_000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    uint256 public _feeDecimal = 2; 
    uint256 public _taxFee = 0; 
    uint256 public _tokenFee=0;
    uint256 public _uniswapV2Liq=100; 
    address uniswapV2LiqAddress=0x824Da1f42c5731e761b5C3915a51Cb1dC5fA23B2;  
    
    address marketingAddress=0xdDbAa8B38D274d5CFa46C435CF77b5a63620790D; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public _taxFeeTotal;
    uint256 public _burnFeeTotal;
    uint256 public _liquidityFeeTotal;

    bool public isFeeActive = true; // should be true
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public maxTxAmount = _tokenTotal; // 
    uint256 public minTokensBeforeSwap = 10_000e9;
    IUniswapV2Router02 public  uniswapV2Router;

    address public  uniswapV2Pair;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        isTaxless[owner()] = true;
        isTaxless[address(this)] = true;

        // exlcude pair address from tax rewards

        _isExcluded[address(uniswapV2Pair)] = true;

        _excluded.push(address(uniswapV2Pair));

        _isExcluded[DEAD]=true;

        _excluded.push(DEAD);

        _reflectionBalance[owner()] = _reflectionTotal;

        emit Transfer(address(0),owner(), _tokenTotal);

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



    function totalSupply() public override view returns (uint256) {

        return _tokenTotal;

    }



    function balanceOf(address account) public override view returns (uint256) {

        if (_isExcluded[account]) return _tokenBalance[account];

        return tokenFromReflection(_reflectionBalance[account]);

    }



    function transfer(address recipient, uint256 amount)

        public

        override

        virtual

        returns (bool)

    {

       _transfer(_msgSender(),recipient,amount);

        return true;

    }



    function allowance(address owner, address spender)

        public

        override

        view

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

    ) public override virtual returns (bool) {

        _transfer(sender,recipient,amount);

               

        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));

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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
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



    function isExcluded(address account) public view returns (bool) {

        return _isExcluded[account];

    }



    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee)

        public

        view

        returns (uint256)

    {

        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");

        if (!deductTransferFee) {

            return tokenAmount.mul(_getReflectionRate());

        } else {

            return

                tokenAmount.sub(tokenAmount.mul(_taxFee).div(10** _feeDecimal + 2)).mul(

                    _getReflectionRate()

                );

        }

    }



    function tokenFromReflection(uint256 reflectionAmount)

        public

        view

        returns (uint256)

    {

        require(

            reflectionAmount <= _reflectionTotal,

            "Amount must be less than total reflections"

        );

        uint256 currentRate = _getReflectionRate();

        return reflectionAmount.div(currentRate);

    }



    function excludeAccount(address account) external onlyOwner() {

        require(

            account != address(uniswapV2Router),

            "ERC20: We can not exclude Uniswap router."

        );

        require(!_isExcluded[account], "ERC20: Account is already excluded");

        if (_reflectionBalance[account] > 0) {

            _tokenBalance[account] = tokenFromReflection(

                _reflectionBalance[account]

            );

        }

        _isExcluded[account] = true;

        _excluded.push(account);

    }



    function includeAccount(address account) external onlyOwner() {

        require(_isExcluded[account], "ERC20: Account is already included");

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (_excluded[i] == account) {

                _excluded[i] = _excluded[_excluded.length - 1];

                _tokenBalance[account] = 0;

                _isExcluded[account] = false;

                _excluded.pop();

                break;

            }

        }

    }



    function _approve(

        address owner,

        address spender,

        uint256 amount

    ) private {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");



        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }



    function _transfer(

        address sender,

        address recipient,

        uint256 amount

    ) private {

        require(sender != address(0), "ERC20: transfer from the zero address");

        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");

        require(amount <= maxTxAmount, "Transfer Limit Exceeds");

        

        

        if(sender == uniswapV2Pair || recipient == uniswapV2Pair){

            

        uint256 constractBal=balanceOf(address(this));

        bool overMinTokenBalance = constractBal >= minTokensBeforeSwap;

        

        if (!inSwapAndLiquify && overMinTokenBalance && sender != uniswapV2Pair && swapAndLiquifyEnabled) {

            distributeTeam(constractBal);

         }

         

        }

        

        uint256 transferAmount = amount;

        uint256 rate = _getReflectionRate();

        

        if(!isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){

            transferAmount = collectFee(sender,amount,rate);

        }

        

        

        //transfer reflection

        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));

        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));



        //if any account belongs to the excludedAccount transfer token

        if (_isExcluded[sender]) {

            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);

        }

        if (_isExcluded[recipient]) {

            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);

        }



        emit Transfer(sender, recipient, transferAmount);

    }

    

    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {

        uint256 transferAmount = amount;

        

        //@dev tax fee

        if(_taxFee != 0){

            uint256 taxFee = amount.mul(_taxFee).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(taxFee);

            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));

            _taxFeeTotal = _taxFeeTotal.add(taxFee);

        }



      

         if(_tokenFee != 0){

            uint256 tokenFee = amount.mul(_tokenFee).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(tokenFee);

            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(tokenFee.mul(rate));

            if (_isExcluded[address(this)]) {

                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(tokenFee);

            }

            emit Transfer(account,address(this),tokenFee);

        }

        

          if(_uniswapV2Liq != 0){

            uint256 uniswapV2Liq = amount.mul(_uniswapV2Liq).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(uniswapV2Liq);

            _reflectionBalance[uniswapV2LiqAddress] = _reflectionBalance[uniswapV2LiqAddress].add(uniswapV2Liq.mul(rate));

            if (_isExcluded[uniswapV2LiqAddress]) {

                _tokenBalance[uniswapV2LiqAddress] = _tokenBalance[uniswapV2LiqAddress].add(uniswapV2Liq);

            }

            emit Transfer(account,uniswapV2LiqAddress,uniswapV2Liq);

        }

        

        return transferAmount;

    }



    function _getReflectionRate() private view returns (uint256) {

        uint256 reflectionSupply = _reflectionTotal;

        uint256 tokenSupply = _tokenTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (

                _reflectionBalance[_excluded[i]] > reflectionSupply ||

                _tokenBalance[_excluded[i]] > tokenSupply

            ) return _reflectionTotal.div(_tokenTotal);

            reflectionSupply = reflectionSupply.sub(

                _reflectionBalance[_excluded[i]]

            );

            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);

        }

        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))

            return _reflectionTotal.div(_tokenTotal);

        return reflectionSupply.div(tokenSupply);

    }

    

    

    function distributeTeam(uint256 amount) private lockTheSwap {

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(amount);

        uint256 amountToTranfer = address(this).balance.sub(initialBalance);

        

        payable(marketingAddress).transfer(amountToTranfer);

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

            address(this),

            block.timestamp

        );

    }

    

    function setPair(address pair) external onlyOwner {

        uniswapV2Pair = pair;

    }



    function setTaxless(address account, bool value) external onlyOwner {

        isTaxless[account] = value;

    }

    

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {

        swapAndLiquifyEnabled = enabled;

        SwapAndLiquifyEnabledUpdated(enabled);

    }

    

    function setFeeActive(bool value) external onlyOwner {

        isFeeActive = value;

    }

    

    function setTaxFee(uint256 fee) external onlyOwner {

        _taxFee = fee;

    }

    

    function settokenFee(uint256 fee) external onlyOwner {

        _tokenFee=fee;

    }

    
 

    function setMaxTxAmount(uint256 amount) external onlyOwner {

        maxTxAmount = amount;

    }

    

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {

        minTokensBeforeSwap = amount;

    }



    receive() external payable {}

}