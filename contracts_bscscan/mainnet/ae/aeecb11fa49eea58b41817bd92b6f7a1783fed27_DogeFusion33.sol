/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT
/*

                                                                                              :==-::...
                                                                                            -*+===------:
                                                                                           :---==---------:
                                                                                        .---::::-==----::---:
                                                                                      :--:::::::::-=---::::---:
                                                                                   .:--:::::::::::::---::::::--:.
                                                                                 :--::::::::::::::::::---:::::---:
                                                                              .:--::::::::::::::::::::::--::::::---:
                                                                            .--:::::::::::::::::::::::::::--:::::---:
                                                                         .:--::::::::::::::::::::::-==::::::----::----:
                                                                       .--:::::::::::::::::::::::-:--+=::::::-=--------:
                                                                     :--:::::::::::::::::::::::-===::-=:::::::-=---------
                                                                  .:--:::::::::::::::::::::::-=:--+=:-::::::::::-====---=-
                                                                :--::::::::::::::::::::::::++=+=:=-::::::::::::::-========
                                                             .:--:::::::::::-::::::::::-==--+-==::::::::::::::::::-=+=====
                                                           :--::::::::::::-:::::::::::-+:-+-=-::::::::::::::::::----=*++++
                                                        .:--:::::::::::--:::::::::::==-+=-=::::::::::::::::::-----==+*##=.
              .=====-:      :-===-.      -====-.   -===+*+++--++++++++--+++-:::++*=::+*+#*+=:::=+++:::-=+***+=--=+*##.:  ==-   :====:    :====:
              %@@##%@@%  .+%@#*#@@@-  -#@%**#@@@  [email protected]@%#####+:[email protected]@%####*:*@@#:::*@@%=+%@%**%@@+:-%@@=:-#@@%#%@@@*++%@@@+  *@@= -%@+-%@@: -%@+-%@@:
             [email protected]@*  :@@@ :@@%:   %@@= *@@+  ..-:. :%@@#++++-:[email protected]@@*+++-:[email protected]@@-:[email protected]@@-=#@@@#**=--:#@@*:[email protected]@%=---%@@#[email protected]@@@@:[email protected]@*    .=*@#-    .=*@#-
            :@@%.  *@@[email protected]@@:   [email protected]@% [email protected]@#  #@@@@+-#@@%####*--%@@%###*::%@@*=:=%@@+:--+*#@@@@+:[email protected]@%[email protected]@@=-==*@@% [email protected]@%[email protected]@%%@@.    [email protected]@%.    -+%@%.
           .%@@+:-#@@= [email protected]@@=::[email protected]@#. #@@#:.:[email protected]@#[email protected]@@+====--*@@#::::::[email protected]@@#+*#@@*:+%%%[email protected]@%[email protected]@@[email protected]@@*+*#@@*. %@@: *@@@@= =+*  :@@# =+*. :%@#
           *%%%%%#*=    =#@@@%#+.   .*%@@@%%*+--%%%%%%%%%-=%%%-::::::+#%@@@@%*-::-#%@@@%#+-:#%%*---*%@@@%#+.  =%%+   %%%*  =%@@%%*-  -%@@%%*-
                                      -==--::::::::::----:::::::::==:=+=----:::::::::-::::::-----==++=.
                                     ===---:::::::-----::::::::::+--=-==-:::::::::::::::::----===++-
                                     +==----::::----:::::::::-==-+=-+-:::::::::::::::::-----==++=:
                                     +#=-----:----::::::::::==:=+:---::::::::::::::::----===++-
                                     =#*=-------::::::::-===-+===:::::::::::::::::-----==++=:
                                      ##*+---:::::::::::+=:+=---::::::::::::::::----===++-
                                      .***+--:::::::::::-+=+-::::::::::::::::-----==+++:
                                        +***=-:::::::::::--::::::::::::::::-----==++-.
                                         -***+-:::::::::::::::::::::::::-----===++:
                                          .+***=-::::-::::::::::::::::-----==+*=.
                                            -***+=------:::::::::::-----===++:
                                              +#**+=------:::::::-----==++=.
                                               :*##*+=------:::----===++-
                                                 -#%##+=====-----==++=:
                                                   -#@%%*========++-
                                                     :+%@@#+++++++.
                                                        .:-===++:

                        DOGEFUSION33 - The Energy Source of Doge Alliance for Inter-Galactic Missions
    by DeFi LABS                                        v1.1
*/

pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

interface iWBNB{
    function deposit() external payable;
}

interface iRouter {
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    //Factory
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface iTools {
    function bnbPrice() external view returns (uint256 BNBUSDprice);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract DogeFusion33 is Initializable {
    //ERC20 Stuff
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address payable public deployer;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address private router_apeswap;
    address private router_pancake;

    //mixture
    address private wbnb;
    address private doge;
    address private shib;
    address private floki;
    address private dogeally;

    //wells
    address private doge_lp_addy;
    address private shib_lp_addy;
    address private floki_lp_addy;
    address private wbnbdogeally_lp_addy;

    uint256 private slippage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Stats(uint256 dogefusion33_price, uint256 mixture_value, uint256 mixtureValueBySupply, uint256 marketCap);

    function init() external payable initializer {
        deployer = payable(msg.sender);
        _name = "DogeFusion33";
        _symbol = "DF33";

        router_apeswap = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
        router_pancake = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

        doge = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;      // decimals 8     slippage -> 2
        shib = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;      // decimals 18    slippage -> 2
        floki = 0x2B3F34e9D4b127797CE6244Ea341a83733ddd6E4;     // decimals 9     slippage -> 4 + 2
        dogeally = 0x05822195B28613b0F8A484313d3bE7B357C53A4a;  // decimals 18    slippage -> 2%

        doge_lp_addy = 0xac109C8025F272414fd9e2faA805a583708A017f;          // pancakeswap
        shib_lp_addy = 0xC0AFB6078981629F7eAe4f2ae93b6DBEA9D7a7e9;          // apeswap
        floki_lp_addy = 0xb372ea0debCc8235C2374929028284973e4f5E26;         // pancakeswap
        wbnbdogeally_lp_addy = 0x04Df78093e2b66A0387F8c052C8d344D84ca49aF;  // apeswap
        slippage = 2*10**16;                                                // slippage = 2%
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // VIEW FUNCTIONS  =============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view virtual returns (uint256) {
        return _balances[_account];
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // USER FUNCTIONS  =============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function makeDogeFusion33FromMixture() public payable returns (bool) {
        require(msg.value != 0, "No zero amount");
        iWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).deposit{value: msg.value}();
        uint256 wbnb4LP = IERC20(wbnb).balanceOf(address(this)) / 4;

        IERC20(wbnb).approve(router_apeswap, IERC20(wbnb).balanceOf(address(this)));
        IERC20(wbnb).approve(router_pancake, IERC20(wbnb).balanceOf(address(this)));

        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = dogeally;

        //dogeally swap
        uint256 wbnb_LP_balance = IERC20(wbnb).balanceOf(wbnbdogeally_lp_addy);
        uint256 dogeally_LP_balance = IERC20(dogeally).balanceOf(wbnbdogeally_lp_addy);
        uint256 amountOutinDoge = iRouter(router_apeswap).getAmountOut(wbnb4LP, wbnb_LP_balance, dogeally_LP_balance);
        uint256 dogeallyMinAmount = amountOutinDoge - _pct(amountOutinDoge, slippage);
        uint256 wbnbMinAmount = wbnb4LP - _pct(wbnb4LP, slippage);
        iRouter(router_apeswap).swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnb4LP, dogeallyMinAmount, path, address(this), block.timestamp+60);

        //shib swap
        path[1] = shib;
        wbnb_LP_balance = IERC20(wbnb).balanceOf(shib_lp_addy);
        uint256 shib_LP_balance = IERC20(shib).balanceOf(shib_lp_addy);
        amountOutinDoge = iRouter(router_apeswap).getAmountOut(wbnb4LP, wbnb_LP_balance, shib_LP_balance);
        uint256 shibMinAmount = amountOutinDoge - _pct(amountOutinDoge, slippage);
        wbnbMinAmount = wbnb4LP - _pct(wbnb4LP, slippage);
        iRouter(router_apeswap).swapExactTokensForTokens(wbnb4LP, shibMinAmount, path, address(this), block.timestamp+60);

        //doge swap
        path[1] = doge;
        wbnb_LP_balance = IERC20(wbnb).balanceOf(doge_lp_addy);
        uint256 doge_LP_balance = IERC20(doge).balanceOf(doge_lp_addy);
        amountOutinDoge = iRouter(router_pancake).getAmountOut(wbnb4LP, wbnb_LP_balance, doge_LP_balance);
        uint256 dogeMinAmount = amountOutinDoge - _pct(amountOutinDoge, slippage);
        wbnbMinAmount = wbnb4LP - _pct(wbnb4LP, slippage);
        iRouter(router_pancake).swapExactTokensForTokens(wbnb4LP, dogeMinAmount, path, address(this), block.timestamp+60);

        //floki swap
        path[1] = floki;
        wbnb4LP = IERC20(wbnb).balanceOf(address(this));
        wbnb_LP_balance = IERC20(wbnb).balanceOf(floki_lp_addy);
        uint256 floki_LP_balance = IERC20(floki).balanceOf(floki_lp_addy);
        amountOutinDoge = iRouter(router_pancake).getAmountOut(wbnb4LP, wbnb_LP_balance, floki_LP_balance);
        uint256 flokiMinAmount = amountOutinDoge - _pct(amountOutinDoge, slippage*3);
        wbnbMinAmount = wbnb4LP - _pct(wbnb4LP, slippage*3);
        iRouter(router_pancake).swapExactTokensForTokensSupportingFeeOnTransferTokens(wbnb4LP, flokiMinAmount, path, address(this), block.timestamp+60);

        //Notes: Adding ********* to the DOGEFUSION33 mixture might make for a moar powerful formula capable of multi-metaverse travelling. Testing.

        emit Stats(dogefusion33Price(), mixtureValueTotal(), mixtureValueBySupply(), marketCap());
        _mint(_msgSender(), msg.value);
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // ERC20 FUNCTIONS  ============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////
    // DEPLOYER FUNCTIONS  =========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    // set int for slippage for swaps. Example: 1 = 1% slippage
    function setSlippage(uint256 _slippage) public virtual returns (bool) {
        require (msg.sender == deployer, "Unable");
        slippage = _slippage*10**16;
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // UTILS FUNCTIONS  ============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // MATH FUNCTIONS  =============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function _pct(uint _value, uint _percentageOf) internal virtual returns (uint256 res) {
        res = (_value * _percentageOf) / 10 ** 18;
    }

    function _pctofwhole(uint256 _portion, uint256 _ofWhole) internal virtual returns (uint256 res) {
        res = _portion * 10 ** 18 / _ofWhole;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // INTERNAL ORACLES  ===========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    // BNB Price in BUSD (w/o basis)
    function bnbPrice() public view returns (uint256) {
        return iTools(0x43adC41cf63666EBB1938B11256f0ea3f16e6932).bnbPrice();
    }

    //dogefusion33 Price in BUSD
    function dogefusion33Price() public view returns (uint256 dogefusion33_price) {
        address tLP = iRouter(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73).getPair(wbnb, address(this)); //call to pancakeswap factory
        uint256 wbnbReserve = IERC20(wbnb).balanceOf(tLP);
        uint256 dogefusion33Reserve = _balances[tLP];
        dogefusion33_price = ((wbnbReserve*10**18) / dogefusion33Reserve) * bnbPrice();
    }

    //Mixture Value in BUSD
    function mixtureValueTotal() public view returns (uint256) {
        uint256 mixtureVal = 0;
        uint256 bnbprice = bnbPrice();
        //compound De
        uint256 wbnbReserve = IERC20(wbnb).balanceOf(doge_lp_addy);
        uint256 dogeReserve = IERC20(doge).balanceOf(doge_lp_addy);
        uint8 dogeDecimolz = IERC20(doge).decimals();
        uint256 whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbprice;
        mixtureVal += IERC20(doge).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);
        //compound Sb
        wbnbReserve = IERC20(wbnb).balanceOf(shib_lp_addy);
        dogeReserve = IERC20(shib).balanceOf(shib_lp_addy);
        dogeDecimolz = IERC20(shib).decimals();
        whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbprice;
        mixtureVal += IERC20(shib).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);
        //compound Fi
        wbnbReserve = IERC20(wbnb).balanceOf(floki_lp_addy);
        dogeReserve = IERC20(floki).balanceOf(floki_lp_addy);
        dogeDecimolz = IERC20(floki).decimals();
        whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbprice;
        mixtureVal += IERC20(floki).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);
        //compound De
        wbnbReserve = IERC20(wbnb).balanceOf(wbnbdogeally_lp_addy);
        dogeReserve = IERC20(dogeally).balanceOf(wbnbdogeally_lp_addy);
        dogeDecimolz = IERC20(dogeally).decimals();
        whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbprice;
        mixtureVal += IERC20(dogeally).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);

        return mixtureVal;
    }

    //Mixture Value for Available Dogefusion33 Supply
    function mixtureValueBySupply() public view returns (uint256) {
      return mixtureValueTotal() / totalSupply();
    }

    //marketcap of dogefusion33 in busdReserve
    function marketCap() public view returns (uint256 mcap) {
        mcap = totalSupply() * dogefusion33Price() / 10**36;
    }
}

// v1.1 changes => market metrics calculations via internal oracles and registers via event after refining dogefusion33