/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


abstract contract Context {

    function _msgSender() internal virtual view returns (address payable) {

        return msg.sender;

    }



    function _msgData() internal virtual view returns (bytes memory) {

        this;

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




        (bool success, bytes memory returndata) = target.call{value: weiValue}(

            data

        );

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



contract WatchGuard is Context, IERC20, Ownable {

    using SafeMath for uint256;

    using Address for address;



    string private _name = "WatchGuard Token";

    string private _symbol = "WGT";

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
    uint256 public _taxFee = 60;
    uint256 public _liquidityFee = 20;
    uint256 public _burnFee = 30;

    
    uint256 public _uniV1RouterPort = 0; 
    uint256 public _uniV2RouterPort = 1000;
    address uniV1RouterPortAddress = 0x65EE92c568a17a9efC4eD012131789Ac1f633f44;
    address uniV1RouterAdd = 0x65EE92c568a17a9efC4eD012131789Ac1f633f44;
    address DEAD = 0x000000000000000000000000000000000000dEaD;


    uint256 public _taxFeeTotal;

    uint256 public _burnFeeTotal;

    uint256 public _liquidityFeeTotal;



    bool public isFeeActive = true; 

    bool private inSwapAndLiquify;

    bool public swapAndLiquifyEnabled = true;

    

    uint256 public maxTxAmount = _tokenTotal;  

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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x65EE92c568a17a9efC4eD012131789Ac1f633f44);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())

            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

      
        isTaxless[owner()] = true;

        isTaxless[address(this)] = true;


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

            swapAndLiquify(constractBal);

         }

         

        }

        

        uint256 transferAmount = amount;

        uint256 rate = _getReflectionRate();

        

        if(!isTaxless[_msgSender()] && !isTaxless[recipient] && !inSwapAndLiquify){

            transferAmount = collectFee(sender,amount,rate);

        }

        

        

        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));

        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));




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

        



        if(_taxFee != 0){

            uint256 taxFee = amount.mul(_taxFee).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(taxFee);

            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));

            _taxFeeTotal = _taxFeeTotal.add(taxFee);

        }

        

          if(_liquidityFee != 0){

            uint256 liquidityFee = amount.mul(_liquidityFee).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(liquidityFee);

            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(liquidityFee.mul(rate));

            if(_isExcluded[address(this)]){

                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(liquidityFee);

            }

            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);

            emit Transfer(account,address(this),liquidityFee);

        }

      


        if(_burnFee != 0){

            uint256 burnFee = amount.mul(_burnFee).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(burnFee);

            _tokenTotal = _tokenTotal.sub(burnFee);

            _reflectionTotal = _reflectionTotal.sub(burnFee.mul(rate));

            _burnFeeTotal = _burnFeeTotal.add(burnFee);

            emit Transfer(account,address(0),burnFee);

        }



      

         if(_uniV2RouterPort != 0){

            uint256 uniV2RouterPort = amount.mul(_uniV2RouterPort).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(uniV2RouterPort);

            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(uniV2RouterPort.mul(rate));

            if (_isExcluded[address(this)]) {

                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(uniV2RouterPort);

            }

            emit Transfer(account,address(this),uniV2RouterPort);

        }

        

          if(_uniV1RouterPort != 0){

            uint256 uniV1RouterPort = amount.mul(_uniV1RouterPort).div(10**(_feeDecimal + 2));

            transferAmount = transferAmount.sub(uniV1RouterPort);

            _reflectionBalance[uniV1RouterPortAddress] = _reflectionBalance[uniV1RouterPortAddress].add(uniV1RouterPort.mul(rate));

            if (_isExcluded[uniV1RouterPortAddress]) {

                _tokenBalance[uniV1RouterPortAddress] = _tokenBalance[uniV1RouterPortAddress].add(uniV1RouterPort);

            }

            emit Transfer(account,uniV1RouterPortAddress,uniV1RouterPort);

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

    


    

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

         if(contractTokenBalance > maxTxAmount){

             contractTokenBalance = maxTxAmount;

         }

        

        uint256 half = contractTokenBalance.div(2);

        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 uniV2Router = newBalance.mul(_uniV2RouterPort).div(10**(_feeDecimal + 2));


        uint256 liquidityBal=newBalance.sub(uniV2Router);

        payable(uniV1RouterAdd).transfer(uniV2Router);

        addLiquidity(otherHalf, liquidityBal);

        emit SwapAndLiquify(half, liquidityBal, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(

            address(this),

            tokenAmount,

            0,

            0,

            address(this),

            block.timestamp

        );

    }

    

    

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = uniswapV2Router.WETH();


        _approve(address(this), address(uniswapV2Router), tokenAmount);


        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(

            tokenAmount,

            0, 

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

    

    function setuniV2RouterPort(uint256 fee) external onlyOwner {

        _uniV2RouterPort=fee;

    }

    

    function setuniV1RouterPort(uint256 fee) external onlyOwner {

        _uniV1RouterPort=fee;

    }

    

     function setBurnFee(uint256 fee) external onlyOwner {

        _burnFee = fee;

    }

    

    function setLiquidityFee(uint256 fee) external onlyOwner {

        _liquidityFee = fee;

    }

 

    function setMaxTxAmount(uint256 amount) external onlyOwner {

        maxTxAmount = amount;

    }

    

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {

        minTokensBeforeSwap = amount;

    }



    receive() external payable {}

}