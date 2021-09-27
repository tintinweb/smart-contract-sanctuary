import "./Pairerc20.sol";
import "./IMy_pair.sol";
import './IERC20.sol';
pragma solidity =0.5.16;
//配对合约
contract My_pair is Pairerc20,IMy_pair{
    uint256 swap_n0;
    uint256 swap_n1;
    constructor(address _token0,address _token1) public {
        factory = msg.sender;
        swapFee =3;//手续费
        token0 =_token0;
        token1 =_token1;
    }
    using SafeMath  for uint;
    using SafeMath  for uint112;
    address public factory;
    address public token0;
    address public token1;
    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint public swapFee;
    uint private unlocked = 1;
    //防重入攻击
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    //转出代币操作
    bytes4 private constant k_truansfer = bytes4(keccak256(bytes('transfer(address,uint256)')));
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(k_truansfer, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
    //转入代币操作
    bytes4 private constant k_TransferFrom = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    function _safeTransferFrom(address token,address sender, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(k_TransferFrom, sender, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferFrom_FAILED');
    }
    //获取流动性池币量
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    //加入流动性矿池
    function mint(uint112 t0_amount,uint112 t1_amount) public lock {
        address to = msg.sender;
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        //账号余额/授权额度是否够,
        require(IERC20(_token0).balanceOf(to)>=t0_amount, 'un enough token0');
        require(IERC20(_token1).balanceOf(to)>=t1_amount, 'un enough token1');
        require(IERC20(_token0).allowance(to,address(this))>=t0_amount, 'un approve enough token0');
        require(IERC20(_token1).allowance(to,address(this))>=t1_amount, 'un approve enough token1');
        uint256 _totalSupply = totalSupply;
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        if(_totalSupply==0){
            //如果矿池没有流动性,则创建.
            require(t0_amount!=0||t1_amount!=0,"pair uncreat,Please send two coins to create pair");
            _safeTransferFrom(_token0,to,address(this),t0_amount);
            _safeTransferFrom(_token1,to,address(this),t1_amount);
            _update(t0_amount,t1_amount);
            //初始化流动性代币等于两种代币的和.
            _totalSupply = t0_amount.add(t1_amount);
            _mint(to,_totalSupply);
            return;
        }else{
            _safeTransferFrom(_token0,to,address(this),t0_amount);
            _safeTransferFrom(_token1,to,address(this),t1_amount);
            //新加入矿池获得的流动性代币量等于
            //代币0除于两倍流动性矿池里代币0的数量再乘于总发布的流动性币.(代币1同理)
            _mint(to,t0_amount.div(_reserve0.mul(2)).add(t1_amount.div(_reserve1.mul(2))).mul(_totalSupply));
            _update(_reserve0.add(t0_amount),_reserve1.add(t1_amount));
        }
    }
    //退出流动性挖矿
    function burn()public lock returns (address to,uint amount0, uint amount1){
        to =msg.sender;
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint balance_pair = balanceOf[to];
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        //计算退出可得代币.
        amount0 = balance0.mul(balance_pair).div(_totalSupply);
        amount1 = balance1.mul(balance_pair).div(_totalSupply);
        _burn(to,balance_pair);
        _safeTransfer(_token0,to,amount0);
        _safeTransfer(_token1,to,amount1);
        _update(_reserve0.sub(amount0),_reserve1.sub(amount1));
    }
    //进行交换(自动做市)一次调用只能填其中一种币.
    event e_sli(uint256 sli);
    function swap(uint112 amount0In, uint112 amount1In,uint256 sli) external lock {
        address to = msg.sender;
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        (uint112 _reserve0, uint112 _reserve1) = getReserves(); // gas savings
        uint tran_amount;
        require(sli<1000,"sli error");
        if(amount0In>0){
            require(amount1In==0,"only can send one currency");
            //可转币量
            tran_amount = In_to_Out(amount0In,_reserve0,_reserve1,swapFee);
            uint256 sli_amount = amount0In*_reserve1/_reserve0*(1000-sli)/1000;
            require(sli_amount<tran_amount,"out of sli");
            _safeTransferFrom(_token0,to,address(this),amount0In);
            _safeTransfer(_token1,to,tran_amount);
            _update(_reserve0.add(amount0In),_reserve1.sub(tran_amount));
            swap_n0 += amount0In;
            swap_n1 += tran_amount;
            emit e_sli(sli_amount);
        }else{
            require(amount1In>0,"only can send one currency");
            tran_amount = In_to_Out(amount1In,_reserve1,_reserve0,swapFee);
            uint256 sli_amount = amount1In*_reserve0/_reserve1*(1000-sli)/1000;
            require(sli_amount<tran_amount,"out of sli");
            _safeTransferFrom(_token1,to,address(this),amount1In);
            _safeTransfer(_token0,to,tran_amount);
            _update(_reserve0.sub(tran_amount),_reserve0.add(amount1In));
            swap_n1 += amount1In;
            swap_n0 += tran_amount;
            emit e_sli(sli_amount);
        }
        emit Sync(reserve0, reserve1,swap_n0,swap_n1,block.timestamp);
    }
    //输入交换的币量,池币量,另一种币的池币量,手续费
    function In_to_Out(uint256 amountIn, uint112 _reserve0, uint112 _reserve1,uint256 _swapFee)public pure returns(uint256 amountOut){
        amountOut =  _reserve1.sub(_reserve0.mul(_reserve1).div(_reserve0.add(amountIn))).mul(100).div(100+_swapFee);
    }
    //更新流动池
    event Sync(uint112 reserve0, uint112 reserve1,uint256 swap_n0,uint256 swap_n1,uint256 time);
    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1,swap_n0,swap_n1,block.timestamp);
    }
    //刷新流动池
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }
}