pragma solidity = 0.5 .16;

import './UnifiERC20.sol';
import './interfaces.sol';


contract UnifiPair is IUnifiPair, UnifiERC20 {
    using SafeMath
    for uint;
    using UQ112x112
    for uint224;
    struct pairData {
        uint balance0;
        uint balance1;
        uint fees;
        uint token0Fees;
        uint token1Fees;
        IUnifiController iUC;
        uint upFees;

    }

    string public symbol;
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant APPROVE = bytes4(keccak256(bytes('approve(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    address public WBNB;
    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Unifi: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Unifi: TRANSFER_FAILED');
    }

    function _safeApprove(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(APPROVE, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Unifi: APPROVE_FAILED');
    }



    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function() external payable {

    }
    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _wbnb) external {
        require(msg.sender == factory, 'Unifi: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        WBNB = _wbnb;
        if(_token0 == _wbnb && _token1 != _wbnb){
            symbol =  string(abi.encodePacked("u",IERC20(token1).symbol()));
        }else if (_token1 == _wbnb && _token0 != _wbnb){
            symbol =  string(abi.encodePacked("u",IERC20(token0).symbol()));
        }else{
            symbol =  string(abi.encodePacked("u",IERC20(token1).symbol(), "_", IERC20(token0).symbol()));            
        }
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Unifi: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }



    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns(uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            IUnifiController(((IUnifiFactory(factory).feeController()))).claimUP(to, to, liquidity, true, false, false);

        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
            IUnifiController(((IUnifiFactory(factory).feeController()))).claimUP(to, to, liquidity, true, false, false);

        }
        require(liquidity > 0, 'Unifi: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        // 
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }


    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns(uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Unifi: INSUFFICIENT_LIQUIDITY_BURNED');
        IUnifiController((IUnifiFactory(factory).feeController())).claimUP(to, to, liquidity, true, false, false);

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function claimUP(address _user) external lock returns(uint) {
        IUnifiController(IUnifiFactory(factory).feeController()).claimUP(_user, _user, 0, false, false, true);
    }

    function getPairFee() external view returns(uint) {

        address controllerAddress = (IUnifiFactory(factory).feeController());
        uint fees = IUnifiController(controllerAddress).getPairFee(address(this));
        return fees;

    }

    function transfer(address to, uint value) external returns(bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        this.claimUP(from);
        this.claimUP(to);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Unifi: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Unifi: INSUFFICIENT_LIQUIDITY');

        pairData memory pd;
        pd.iUC = IUnifiController((IUnifiFactory(factory).feeController()));
        require(pd.iUC.poolPaused(address(this)) == false, 'Unifi: Contract is on pause');
        pd.fees = pd.iUC.getPairFee(address(this));


        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Unifi: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0 && !pd.iUC.isDisableFlashLoan(address(this))) IUnifiCallee(to).unifiCall(msg.sender, amount0Out, amount1Out, data);
            pd.balance0 = IERC20(_token0).balanceOf(address(this));
            pd.balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = pd.balance0 > _reserve0 - amount0Out ? pd.balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = pd.balance1 > _reserve1 - amount1Out ? pd.balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Unifi: INSUFFICIENT_INPUT_AMOUNT'); { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = pd.balance0.mul(1000).sub(amount0In.mul(pd.fees));
        uint balance1Adjusted = pd.balance1.mul(1000).sub(amount1In.mul(pd.fees));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2), 'Unifi: K');


        }
        uint fees = 0;
        if (pd.iUC.UPMintable(address(this))) {
            pd.token0Fees = amount0In.mul(pd.fees).div(1000);
            pd.token1Fees = amount1In.mul(pd.fees).div(1000);
            if (token0 == WBNB || token1 ==WBNB) {
                if (pd.token0Fees  > 0) {
                    if (token0 != WBNB) {
                        //perform a swap quote
                        fees = quote(pd.token0Fees, pd.balance0, pd.balance1);
                        pd.upFees = pd.upFees.add(fees);
                        pd.balance1 = pd.balance1.sub(fees);
                    } else {
                        pd.upFees = pd.upFees.add(pd.token0Fees);
                        pd.balance0 = pd.balance0.sub(pd.token0Fees);
                    }
                }
                if (pd.token1Fees  > 0) {
                    if (token1 != WBNB) {
                        fees = quote(pd.token1Fees , pd.balance1, pd.balance0);
                        pd.upFees = pd.upFees.add(fees);
                        pd.balance0 = pd.balance0.sub(fees);
                    } else {
                        pd.upFees = pd.upFees.add(pd.token1Fees);
                        pd.balance1 = pd.balance1.sub(pd.token1Fees);
                    }

                }
                if (pd.upFees > 0) {

                    IWETH(WBNB).withdraw(pd.upFees);
                    pd.iUC.mintUP.value(address(this).balance)(address(this));

                }

            } else { //pair isnt WBNB

                // get the path
                // get the addres[0] to know which coin we need to change to
                address[] memory pathToTrade = IUnifiController(address(pd.iUC)).pathToTrade(address(this));
                if (pathToTrade.length > 0 && pathToTrade[pathToTrade.length - 1] == WBNB) {
                    if (amount0In.mul(pd.fees) > 0) {
                        if (token0 != pathToTrade[0] && pathToTrade[0] == token1) {
                            //perform a swap quote
                            fees = quote(pd.token0Fees, pd.balance0, pd.balance1);
                            pd.upFees = pd.upFees.add(fees);
                            pd.balance1 = pd.balance1.sub(fees);
                        } else { //straight away perform trade
                            pd.upFees = pd.upFees.add(pd.token0Fees);//when will this happen?
                            pd.balance0 = pd.balance0.sub(pd.token0Fees);
                        }
                    }
                    if (amount1In.mul(pd.fees) > 0) {
                        if (token1 != pathToTrade[0] && pathToTrade[0] == token0) {
                            fees = quote(pd.token1Fees, pd.balance1, pd.balance0);
                            pd.upFees = pd.upFees.add(fees);
                            pd.balance0 = pd.balance0.sub(fees);
                        } else { //straight away perform trade
                            pd.upFees = pd.upFees.add(pd.token1Fees);
                            pd.balance1 = pd.balance1.sub(pd.token1Fees);
                        }
                    }
                    if (pd.upFees > 0) {
                        _safeApprove(pathToTrade[0], IUnifiFactory(factory).router(), pd.upFees);
                        IUnifiRouter(IUnifiFactory(factory).router()).swapExactTokensForETH(pd.upFees, 1, pathToTrade, address(pd.iUC), (block.timestamp).add(18000)); //get the WBNB back
                        pd.iUC.mintUP.value(0)(address(this));
                    }
                }
            }

        }
        pd.balance0 = IERC20(token0).balanceOf(address(this));
        pd.balance1 = IERC20(token1).balanceOf(address(this));
        _update(pd.balance0, pd.balance1, _reserve0, _reserve1); //balance is wrong

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
         IUnifiController iUC = IUnifiController((IUnifiFactory(factory).feeController()));
         if(iUC.admin(msg.sender)){
            address _token0 = token0; // gas savings
            address _token1 = token1; // gas savings
            _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
            _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
         }
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns(uint amountB) {
        require(amountA > 0, 'UnifiLibrary Pair: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UnifiLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
    // if fee is on, mint liquidity equivalent to 8/25 of the growth in sqrt(k)

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns(bool feeOn) {
        address feeTo = IUnifiFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings

        IUnifiController ufc = IUnifiController((IUnifiFactory(factory).feeController()));

        if (feeOn && ufc.UPMintable(address(this)) == false) {
            (uint numeratorConfig, uint denominatorConfig) = ufc.getMintFeeConfig(address(this));
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(numeratorConfig);
                    uint denominator = rootK.mul(denominatorConfig).add(rootKLast.mul(numeratorConfig));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }


}