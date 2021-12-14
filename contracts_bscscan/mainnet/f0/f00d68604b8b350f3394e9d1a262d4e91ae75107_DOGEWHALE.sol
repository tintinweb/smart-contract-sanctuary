/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT

/*
                                 ::.                   .:
                               :++==+=.             :=+==+-
                              -+-::::-+-         .-=-::::-+=
                             :+-:::::::-=       -=:::-:::::++
                             ==::::::::::=    .-:::--::::::-+-    Telegram: https://t.me/dogewhale_community
                            :+----------------:::--:::::--::++
                        ::--:::::::::::::::::::---::::::--::-+.                                                                  .:==-
                     :--::::::::::::::::::::::---:::::::---::+=.                                                               :++=-=+.
                   :-:::::::::::::::::::::::::::--::::::---::+===.                                                           .=+-:-=+=
                 .-:::::::::::::::::::::::::::::::::::----:::=-::==                                                          ++::--++
                :::..  ...:::::::::::::::::::::::::::::::::::=-:::-=-             wow                                       =+::--=+:            .-=
               :::.       .::::::::::::::::::::::::::::::::::--:::::-+-                                                     +=::--=+.         .-+=++
              ::::.....    .::::::::::::::::::::::::::::::::::::::::::-+:                                                  :+-::--=+-     .:=+=-::+=
              :::::=##=--. .::::::::::::::::::::::::::::::::::::::::::::-+-                     so amaze                   :+-:::--=+===++==-::::=+.
             :::::+*=*@*:==:::::::::::::::::::::::::::::::::::::::::::::::-==:                                              +=::::::::::::::::::-+-
            .::::[email protected][email protected]@* .*:::::::::::::::::::::::::::::::::::::::::::::::::-==-:.                                         -+:::::::::::::::::-+=
           .::::[email protected]@@@@@*  ==:::::::::::::::::::::::::::::::::::::::::::::::::::--====-:..                            ..::-=++-:::::::::::::::=+-
            .::::-=%@@@#.:=+:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::--=======-------------===========---:::::::::::::::-=++-.
  :-:        .::::::=*++=-:::::::::::::.   .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-++==:.
 +##*-        ::::::::::::::::::::::..       :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::++
 *@##=        .::::::::::::::::::..          .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-+:
 :###=..      .::::::::::::....               :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::+=
  -#*:....::---::::::......                   .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::=+.
   -...::::....:::::::.                       .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-+-
   :*+-:.      .:==:  .::...                  .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::++
    -#%#+:::-=*+=:.         ..                .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::=+.
     -+++++=-:...                             .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::=+.
      -.......                                ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::++.
       :...                                 .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::++.
       ..                                  .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-+=
        :.                                .:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-+=
         -.                             .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::=+-
          :.                             .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::++.
           ::                              .::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::=+-
            :-                               ..:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::-++.
              -.                                ...:::::::::::::::::::::::::::--::::::::::::::::::::::::::::::::::..:=+:
               :-                                    ....:::::::::::::::-=+++====++=-:::::::::::::::::::::::::... .=+-
                 ::                                         .....:::::=+=-:::::::::=++-:::::::::::::::::....    .=+-
                   ::                                               :++::::::::::::::=+=:::.........          :=+:
                     --                                            .+=::::::::::::::::-+=                  .-+=.
                       --.                                         ++::::::::::::::::::-+:               :=+-.
                         :-:.                                     -+-:::::::::::::::::::+=           .:=+-.
                            :--:                                  +=::::::::::::::::::::=+        .-=+-.
                               .---:.                            .+-::::::::::::::::::::=+    .:-+=:.
                                   .:----:..                     .+-::::::::::::::::::::=+.:-==-.
                                         .::-----:::...           +-::::::::::::::::::::=+-:.
                                                  ..::---======---+=::::::::::::::::::::+-
                                                           -:::---=+::::::::::::::::::::+.
                                                           :=::----+-::::::::::::::::::==
                                                            -=:::---+::::::::::::::::::+.
                                                             :+-:::-==::::::::::::::::=.
                                                               -+===+==::::::::::::::=.
                                                                 .:.  :-::::::::::::=.
                                                                        ::::::::::-:
                                                                          .::::::.

                                                            a DOGEWHALE, so much rare

                                                             A DOGE ALLIANCE MEMBER

by DEFI LABS */

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

interface IUniswap {
    //Router
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    //Factory
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    //LP
    function sync() external;
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

interface DogeAlliance {
    function award(address account) external returns (bool);
    function muchOferings(address addy, uint256 amount) external returns (bool);
}

interface ICargoBay {
    function SwapToBNB(address reserveManager) external returns (uint256);
    function addLiquidity(address whichLP) external returns (bool);
    function SwapToDOGEs(address doge2get) external returns (bool);
}

contract DOGEWHALE is Initializable {
    //variables
    string public Telegram;
    mapping(uint256 => mapping(address => uint256)) private _balances;  //_balances[round][address] = current balance
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private _balanceAt; //_balanceAt[round][snapshotNumber][address] = balance at snap
    mapping(uint256 => uint256) private _totalSupplyAt;                 //_totalSupply[snapshotNumber]
    mapping(address => bool) private _passlist;
    mapping(address => bool) private dedicatedContract;                 //is it a dedicated/specialized/periphery contract? kanban/marketing/distro
    mapping(address => mapping (uint256 => bool)) public isCheckpointClaimed; // address[checkpointNumber] = true/false
    mapping(uint256 => mapping (uint256 => uint256)) public dogeAsset2Claim; // dogeAsset[numOfDogeAsset][snapshot] = specific doge

    //voting variables
    uint256 public votingSnapshotNumber;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public _voteBalanceAt; //_voteBalanceAt[round][votingSnapshotNumber][address] = balance at snap
    mapping(uint256 => uint256) public _voteTotalSupplyAt;                 //_voteTotalSupply[votingSnapshotNumber]

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    string public Web;
    address private _owner;

    address public cargoBay;
    address public factory;
    address public router;

    uint256 public round;
    uint256 public snapshotNumber;

    uint256 public dogeTurn;
    uint256 public nDoges;
    address[10] public DogeAssets;

    uint256 public LPturn;
    uint256 public nLPs;
    address[10] public dogewhaleLPs;
    uint256 public LPburnAmount;
    uint256 public burnRate;
    uint256 public burnClock;
    uint256 public pct4LP;

    uint256 public ATH;
    uint256 public Drawdown;
    uint256 public painThreshold;
    uint256 public nTrades;
    uint256 public priceTracker;

    uint256 public saleMode;
    uint256 public cargoBayThreshold;
    bool public cargoBayReady;
    bool public reserveChecks;
    uint256 public maxReserve;
    uint256[24] public reserveCheckpoint; //maximum slots allow for maxReserve ceiling to be increased to a max of $104Bn, vote required
    uint256 public conclusionTime;

    uint256 public buytax;
    uint256 public selltax;
    uint256 public transfertax;

    uint256 public treat;
    uint256 public dogeAllianceRewards;
    uint256 public checkpointClaimPct;

    bool public panicOverride;

    address public wBNBbUSD_LP;
    address public busd;
    address public allianz;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _walletOwner, address indexed _spenderAddy, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Snapshot(uint256 _id);
    event VotingSnapshot(uint256 _id);
    event ReserveManaged(address indexed _reservemanager);
    event ClaimedCheckpoint(address indexed _whoClaimed, uint256 _whichCheckpoint);
    event priceOnTransfer(uint256 indexed _price);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function init(address _cargobay, address _factory, address _router, address _wBNBbUSD_LP, address _dogeallianz, address _busd) external initializer {
        _name = "DOGEWHALE";
        _symbol = "DOGEWHALE";
        Telegram = "https://t.me/dogewhale_community";
        Web = "https://dogewhale.eth";                              //official homepage (decentralized web)
        _owner = msg.sender;

        cargoBay = _cargobay;                                       //temporary reserve
        factory = _factory;                                         //pancakeswap factory
        router = _router;                                           //pancakeswap router
        wBNBbUSD_LP = _wBNBbUSD_LP;                                 //binance busd cakeswap LP
        allianz = _dogeallianz;
        busd = _busd;

        DogeAssets[1] = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43; //bsc dogecoin binance pegged
        nDoges = 1;                                                 //number of doges to be aquired
        dogeTurn = 1;                                               //doge asset turn for aquisition

        dogewhaleLPs[1] = address(0); //CHECK THIS!!!
        nLPs = 1;                                                   //number of LPs - dogewhale
        LPturn = 1;                                                 //LP turn for liquidity addition
        pct4LP = 20;                                                //20% of cargoBay goes to LP

        priceTracker = 0;                                           //priceTracker
        nTrades = 0;
        ATH = 0;                                                    //all time high
        Drawdown = 0;                                               //drawdown from ATH
        painThreshold = 50;                                         //retracement % from the ATH where selling gets taxed higher
        round = 1;                                                  //fight!
        snapshotNumber = 1;                                         //current snapshot / number of snapshots
        saleMode = 1;                                               //1 = Init, 2 = Sale, 3 = Normal, 4 = Hodl, 11 = CycleEnd/Halt
        cargoBayThreshold = 1000;                                   //$1000 swapper threshold value for managing cargoBay

        treat = 20;                                                 //$20 reward for managing reserve
        dogeAllianceRewards = 0;                                    //divider for DogeAlliance rewards, default: 100

        burnRate = 43200;                                           //period until next burn from LP, default=43200, 12hrs
        burnClock = block.timestamp + burnRate;                     //deployment + 12hrs
        LPburnAmount = 100*10**12;                                  //percentage of the LP to be burned, default: 0.0001%

        maxReserve = 12500*2**18;                                   //reserve amount where cycle ends, default 12500*2**18 = $3.2Bn
        reserveCheckpoint[1] = 12500;                               //first reserve checkpoint, default: 12500 = $12500
        cargoBayReady = false;                                      //switch for then the cargoBay is ready to be managed by community
        checkpointClaimPct = 10*10**16;                             //10%/holders available to claim at checkpoints
        panicOverride = false;                                      //when true, it taxes sellers beyond certain levels
        conclusionTime = 0;                                         //conclusion time of the grand cycle
        setSaleMode(1);                                             //initialize buy, sell, transfer tax
        _totalSupplyAt[0] = 1*10**30; //**33                        //establishing initial supply
        _mint(_owner, _totalSupplyAt[0]);                           //creation of new supply
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // BASIC VIEW FUNCTIONS  =======================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function owner() public view virtual returns (address) {
        return _owner;
    }

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
        return _balances[round][_account];
    }

    function balanceOfAt(address _account, uint256 _snapshotNumber) public view virtual returns (uint256) {
        return _balanceAt[round][_snapshotNumber][_account];
    }

    function totalSupplyAt(uint256 _snapshotNumber) public view virtual returns (uint256) {
        return _totalSupplyAt[_snapshotNumber];
    }

    function passList(address _account) public view virtual returns (bool) {
        return _passlist[_account];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // MANAGING FUNCTIONS ==========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function setTreat(uint256 _howMuchDollarinos) public virtual onlyOwner returns (bool) {
        treat = _howMuchDollarinos;
        return true;
    }

    function setPainLevel(uint256 _howMuchPain) public virtual onlyOwner returns (bool) {
        painThreshold = _howMuchPain;
        return true;
    }

    function setDogeAllianceInterop(uint256 _whatRewardDivider) public virtual onlyOwner returns (bool) {
        dogeAllianceRewards = _whatRewardDivider;
        return true;
    }

    function setCargoBayThreshold(uint256 _howMuchCargoBayDollarino) public virtual onlyOwner returns (bool) {
        cargoBayThreshold = _howMuchCargoBayDollarino;
        return true;
    }

    function togglePanicOverride() public virtual onlyOwner returns (bool) {
        if (panicOverride == true) {
            panicOverride = false;
        } else {
            panicOverride = true;
        }
        return true;
    }

    function setWeb(string memory _weblol, string memory _telegram) public virtual onlyOwner returns (bool) {
        Web = _weblol;
        Telegram = _telegram;
        return true;
    }

    function setBurnSettings(uint256 _burnCycleTimestamp, uint256 _burnPercentage) public virtual onlyOwner returns (bool) {
        burnRate = _burnCycleTimestamp; //period until next burn
        LPburnAmount = _burnPercentage;
        return true;
    }

    function addremoveDogeAsset(uint256 _dogeNum, address _dogeAddress, uint256 _numOfDoges) public virtual onlyOwner returns (bool) {
        DogeAssets[_dogeNum] = _dogeAddress;
        nDoges = _numOfDoges;
        dogeTurn = 1;
        return true;
    }

    function addremoveLP(uint256 _LPNum, address _LPAddress, uint256 _numOfLPs) public virtual onlyOwner returns (bool) {
        dogewhaleLPs[_LPNum] = _LPAddress;
        nLPs = _numOfLPs;
        LPturn = 1;
        return true;
    }

    function TogglePasslist (address _account) public virtual onlyOwner returns (bool) {
        require (_account != address(0), "Zero address passlist not permited");
        if (passList(_account) == false) {
            _passlist[_account] = true;
        } else {
            _passlist[_account] = false;
        }
        return true;
    }

    function ToggleReserveChecks () public virtual onlyOwner returns (bool) {
        if (reserveChecks == false) {
            reserveChecks = true;
        } else {
            reserveChecks = false;
        }
        return true;
    }

    function ToggleDedicatedContract (address _account) public virtual onlyOwner returns (bool) {
        require (_account != address(0), "Zero address passlist not permited");
        if (dedicatedContract[_account] == false) {
            dedicatedContract[_account] = true;
        } else {
            dedicatedContract[_account] = false;
        }
        return true;
    }

    function setPct4LP(uint256 _pctForLiquidity) public virtual onlyOwner returns(bool) { // without basis, default: 20 = 20%
        pct4LP = _pctForLiquidity;
        return true;
    }

    function setSaleMode(uint256 _mode) public virtual onlyOwner returns (bool) {
        require (_msgSender() != address(0), "much zero addy");
        require (saleMode != 0, "zero");
        saleMode = _mode;
        if (saleMode == 1 || saleMode == 11) {
            // presale rules, no tax
            selltax = 0;
            buytax = 0;
            transfertax = 0;
        } else if (saleMode == 2) {
            // sale mode tokenomics (volume booster incentive)
            selltax = 100*10**14;
            buytax = 100*10**14;
            transfertax = 0;
        } else if (saleMode == 3) {
            // normal tokenomics
            selltax = 300*10**14;
            buytax = 125*10**14;
            transfertax = 100*10**14;
        } else if (saleMode == 4) {
            // hodl incentive
            selltax = 500*10**14;
            buytax = 100*10**14;
            transfertax = 100*10**14;
        } else {
            // default
            selltax = 300*10**14;
            buytax = 125*10**14;
            transfertax = 100*10**14;
        }
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // STANDARD FUNCTIONS ==========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function allowance(address _walletOwner, address _spenderAddy) public view virtual returns (uint256) {
        return _allowances[_walletOwner][_spenderAddy];
    }

    function approve(address _spender, uint256 _amount) public virtual returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), _spender, currentAllowance - _subtractedValue);
        return true;
    }

    function _approve(address _walletOwner, address _spenderAddy, uint256 _amountToSpend) internal virtual {
        require(_walletOwner != address(0), "ERC20: approve from the zero address");
        require(_spenderAddy != address(0), "ERC20: approve to the zero address");
        _allowances[_walletOwner][_spenderAddy] = _amountToSpend;
        emit Approval(_walletOwner, _spenderAddy, _amountToSpend);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // GOVERNANCE FUNCTIONS ========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function handoverToDAO(address COMMUNITY_DAO_CONTRACT) public virtual onlyOwner returns (bool) {
        require(COMMUNITY_DAO_CONTRACT != address(0), "not permited");
        address OP = _owner;
        _owner = COMMUNITY_DAO_CONTRACT;
        emit OwnershipTransferred(OP, _owner);
        return true;
    }

    function votingSnapshot() public virtual onlyOwner returns (bool) {
        _voteTotalSupplyAt[votingSnapshotNumber] = _totalSupply;
        emit VotingSnapshot(votingSnapshotNumber);
        votingSnapshotNumber += 1;
        return true;
    }

    function _snapshot() internal virtual {
        _totalSupplyAt[snapshotNumber] = _totalSupply;
        snapshotNumber += 1;
        emit Snapshot(snapshotNumber-1);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // RESERVE MANAGEMENT FUNCTIONS ================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function manageReserves() public virtual returns (bool) {
        require(saleMode != 0 || saleMode != 11, "inop");
        require(_msgSender() != address(0), "no zero addy");
        require(isContract(_msgSender()) == false, "no on-chain bots");
        require(cargoBayReady == true, "cargoBay still loading");

        if (reserveValue() >= cargoBayThreshold) {
            //swap to bnb
            ICargoBay(cargoBay).SwapToBNB(_msgSender());

            // lp swaps
            if (LPturn < nLPs) {
                ICargoBay(cargoBay).addLiquidity(dogewhaleLPs[LPturn]);
                LPturn += 1;
            } else if (LPturn == nLPs) {
                ICargoBay(cargoBay).addLiquidity(dogewhaleLPs[LPturn]);
                LPturn = 1;
            } else {
                LPturn = 1;
                ICargoBay(cargoBay).addLiquidity(dogewhaleLPs[LPturn]);
                LPturn += 1;
            }

            // swap to doges
            if (dogeTurn < nDoges) {
                ICargoBay(cargoBay).SwapToDOGEs(DogeAssets[dogeTurn]);
                dogeTurn += 1;
            } else if (dogeTurn == nDoges) {
                ICargoBay(cargoBay).SwapToDOGEs(DogeAssets[dogeTurn]);
                dogeTurn = 1;
            } else {
                dogeTurn = 1;
                ICargoBay(cargoBay).SwapToDOGEs(DogeAssets[dogeTurn]);
                dogeTurn += 1;
            }

            //TODO Staking
            cargoBayReady = false;
            CheckpointCheck();

        } else {
            if (block.timestamp > burnClock && nTrades > 33) {
                _burnLP();
                burnClock += burnRate;
                if (dogeAllianceRewards != 0) {
                    DogeAlliance(allianz).award(_msgSender());
                }
                cargoBayReady = false;
                CheckpointCheck();
            }
        }
        emit ReserveManaged(_msgSender());
        return true;
    }

    function CheckpointCheck() public virtual returns (bool) {
        require (saleMode != 11, "not during conclusion");
        uint256 value = DogeReserveValueTotal();
        if (value >= reserveCheckpoint[snapshotNumber]) {
            if (value >= maxReserve || totalSupply() <= 1000000*10**18) { //12 checkpoints to 100 mio or totalSupply 1M WhaleDoge
                _snapshot();
                uint n = 1;
                while (n <= nDoges) {
                    dogeAsset2Claim[n][snapshotNumber-1] = IERC20(DogeAssets[n]).balanceOf(address(this));
                    n += 1;
                }
                saleMode = 11;
                conclusionTime = block.timestamp;
                return true;
            } else {
                _snapshot();
                uint n = 1;
                while (n <= nDoges) {
                    dogeAsset2Claim[n][snapshotNumber-1] = IERC20(DogeAssets[n]).balanceOf(address(this));
                    n += 1;
                }
                reserveCheckpoint[snapshotNumber] = reserveCheckpoint[snapshotNumber-1]*2;
            }
        }
        return true;
    }

    function ClaimCheckpoint(uint256 whichCheckpoint) public virtual returns (bool) {
        require (saleMode != 11, "not during conclusion");
        require (whichCheckpoint != 0, "no snap available at 0");
        require (whichCheckpoint < snapshotNumber, "unable");
        require (isCheckpointClaimed[_msgSender()][whichCheckpoint] == false, "checkpoint has been claimed");
        uint256 share = _pctofwhole(balanceOfAt(_msgSender(), whichCheckpoint), totalSupplyAt(whichCheckpoint));
        uint256 n = 1;
        while (n <= nDoges) {
            uint256 withdrawableReserve = _pct(dogeAsset2Claim[n][whichCheckpoint], checkpointClaimPct);
            uint256 DogePayout = _pct(withdrawableReserve, share);
            if (DogePayout > 0) {
                IERC20(DogeAssets[n]).transfer(_msgSender(), DogePayout);
            }
            n += 1;
        }
        isCheckpointClaimed[_msgSender()][whichCheckpoint] = true;
        emit ClaimedCheckpoint(_msgSender(), whichCheckpoint);
        return true;
    }

    function claimReserves() public virtual returns (bool) {
        require (saleMode == 11);
        require (block.timestamp < conclusionTime+259200 && block.timestamp > conclusionTime && conclusionTime != 0, "not the time");
        require (isCheckpointClaimed[_msgSender()][snapshotNumber-1] == false, "reserve has been claimed");
        uint256 share = _pctofwhole(balanceOfAt(_msgSender(), snapshotNumber-1), totalSupplyAt(snapshotNumber-1));
        uint256 n = 1;
        while (n <= nDoges) {
            uint256 DogePayout = _pct(dogeAsset2Claim[n][snapshotNumber-1], share);
            if (DogePayout > 0) {
                IERC20(DogeAssets[n]).transfer(_msgSender(), DogePayout);
            }
            n += 1;
        }
        isCheckpointClaimed[_msgSender()][snapshotNumber-1] = true;
        /* emit claimedReserves(); */
        return true;
    }

    function reset() public virtual returns (bool) {
        require (saleMode == 11 && saleMode != 0, "only during conclusion");
        require (block.timestamp > conclusionTime+259200 && conclusionTime != 0, "not the time");

        //reset variables First
        snapshotNumber = 1;
        round += 1;
        _totalSupply = 0;
        saleMode = 3;
        LPburnAmount = 100*10**13; //percentage of the LP to be burned
        burnRate = 43200; //period of until next burn from LP - 12hrs
        burnClock = block.timestamp + burnRate*12; //6 days
        treat = 20; //$20 reward for managing reserve
        conclusionTime = 0;
        ATH = 0;
        Drawdown = 0;

        //splitting supply to the LPs
        uint256 split = _totalSupplyAt[0] / nLPs;
        uint256 n = 1;
        while (n <= nLPs) {
            _mint(dogewhaleLPs[n], split);
            /* IUniswap(dogewhaleLPs[n]).sync(); */
            n += 1;
        }
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // BURN MINT FUNCTIONS =========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "ERC20: mint to the zero address");
        _totalSupply += _amount;
        _balances[round][_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function _burn(address _address, uint256 _amount) internal virtual {
        require(_address != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[round][_address];
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
        _balances[round][_address] = accountBalance - _amount;
        _totalSupply -= _amount;
        emit Transfer(_address, address(0), _amount);
    }

    function _burnLP() internal virtual {
        require(nLPs != 0, "No LPs to burn.");
        if (saleMode != 0 || saleMode != 1 || saleMode != 11) {
            uint256 n = 1;
            while (n <= nLPs) {
                uint256 calculatedBurn = _pct(_balances[round][dogewhaleLPs[n]], LPburnAmount);
                _burn(dogewhaleLPs[n], calculatedBurn);
                IUniswap(dogewhaleLPs[n]).sync();
                n += 1;
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // CONTROL FUNCTIONS ===========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function isTherePanic() public virtual returns (uint256, uint256, uint256) {
        priceTracker = dogewhalePrice();
        emit priceOnTransfer(priceTracker);

        if (priceTracker >= ATH) {
            ATH = priceTracker;
        } else if (priceTracker < ATH) {
            Drawdown = _pctofwhole(priceTracker, ATH);
        } else if (priceTracker == 0) {
            return (buytax, selltax, transfertax);
        }

        if (priceTracker != 0) {
            if (Drawdown < painThreshold*10**16 && panicOverride == true) {
                return (500*10**13, 800*10**14, 125*10**14);    //  buy: 0.5%, sell: 8%, trasnfer: 1.25%
            } else {
                return (buytax, selltax, transfertax);
            }
        } else {
            return (buytax, selltax, transfertax);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // TRANSFER FUNCTIONS ==========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function transfer(address _to, uint256 _amount) public virtual returns (bool) {
        _transfer(_msgSender(), _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual returns (bool) {
        _transfer(_from, _to, _amount);
        uint256 currentAllowance = _allowances[_from][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        _approve(_from, _msgSender(), currentAllowance - _amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "ERC20: No zero value transfer allowed");
        require(balanceOf(sender) >= amount, "wow wat!? balance insufficient!");
        require(saleMode != 11, "no");

        // anti-bots on start
        if (isContract(_msgSender()) == true && saleMode == 1 && passList(_msgSender()) == false ) {
            revert();
        }

        if (saleMode == 1){
            _simpleTransfer(sender, recipient, amount);
        } else {
            (uint256 buy_cut, uint256 sell_cut, uint256 transfercut) = isTherePanic();

            if (passList(sender) == false && passList(recipient) == true) {
                //sell block
                uint256 rsv = _pct(amount, sell_cut);

                _simpleTransfer(sender, recipient, amount - rsv);
                _sendToReserve(sender, rsv);

            } else if (passList(sender) == true && passList(recipient) == false) {
                //buy block

                //added this block to prevent distribution/marketing/kanban (dedicatedcontracts) to take a fee on transfers
                if (dedicatedContract[sender] == true) {
                    _simpleTransfer(sender, recipient, amount);
                } else {
                    uint256 rsv = _pct(amount, buy_cut);

                    _simpleTransfer(sender, recipient, amount);
                    _sendToReserve(recipient, rsv);

                    if (dogeAllianceRewards != 0) {
                        uint256 rewerdlol = amount/dogeAllianceRewards;
                        if (rewerdlol != 0) {
                            DogeAlliance(allianz).muchOferings(recipient, amount/dogeAllianceRewards);
                        }
                    }
                }

            } else if (passList(sender) == false && passList(recipient) == false) {
                //transfer between wallats
                uint256 rsv = _pct(amount, transfercut);

                _simpleTransfer(sender, recipient, amount - rsv);
                _sendToReserve(sender, rsv);

            } else if (passList(sender) == true && passList(recipient) == true) {
                //transfer passlisted pairs
                _simpleTransfer(sender, recipient, amount);
            }
        }

        _voteBalanceAt[round][votingSnapshotNumber][sender] = _balances[round][sender];
        _voteBalanceAt[round][votingSnapshotNumber][recipient] = _balances[round][recipient];
        _balanceAt[round][snapshotNumber][sender] = _balances[round][sender];
        _balanceAt[round][snapshotNumber][recipient] = _balances[round][recipient];

        nTrades += 1;

        if (reserveChecks == true) {
            if (reserveValue() >= cargoBayThreshold || block.timestamp > burnClock && cargoBayReady == false) {
                cargoBayReady = true;
            }
            CheckpointCheck();
        }
    }

    function _simpleTransfer(address _from, address _to, uint256 _amount) internal virtual {
        _balances[round][_from] -= _amount;
        _balances[round][_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function _sendToReserve(address _from, uint256 _amount) internal virtual {
        _balances[round][_from] -= _amount;
        _balances[round][cargoBay] += _amount;
        emit Transfer(_from, cargoBay, _amount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // UTILITY FUNCTIONS ===========================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function _msgSender() internal virtual returns (address) {
        return msg.sender;
    }

    function isContract(address _account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }

    function _pct(uint _value, uint _percentageOf) internal virtual returns (uint256 res) {
        res = (_value * _percentageOf) / 10 ** 18;
    }

    function _pctofwhole(uint256 _portion, uint256 _ofWhole) internal virtual returns (uint256 res) {
        res = _portion * 10 ** 18 / _ofWhole;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // INTERNAL ORACLES ============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    // BNB Price in BUSD (w/ basis)
    function bnbPrice() public view returns (uint256 BNBUSDprice) {
        uint256 wbnbReserve = IERC20(IUniswap(router).WETH()).balanceOf(wBNBbUSD_LP);
        uint256 busdReserve = IERC20(busd).balanceOf(wBNBbUSD_LP);
        BNBUSDprice = busdReserve / wbnbReserve;
    }

    //WhaleDoge Price in BUSD
    function dogewhalePrice() public view returns (uint256 dogewhale_price) {
        address tLP = IUniswap(factory).getPair(IUniswap(router).WETH(), address(this));
        uint256 wbnbReserve = IERC20(IUniswap(router).WETH()).balanceOf(tLP);
        uint256 dogewhaleReserve = _balances[round][tLP];
        dogewhale_price = ((wbnbReserve*10**18) / dogewhaleReserve) * bnbPrice();
    }

    //CargoBay Value in BUSD
    function reserveValue() public view returns (uint256 reserveVal) {
        reserveVal = _balances[round][cargoBay] * dogewhalePrice() / 10**36;
    }

    //Reserve Value in BUSD
    function DogeReserveValue(uint256 whichDoge) public view returns (uint256, uint256) {
        address tLP = IUniswap(factory).getPair(IUniswap(router).WETH(), DogeAssets[whichDoge]);
        uint256 wbnbReserve = IERC20(IUniswap(router).WETH()).balanceOf(tLP);
        uint256 dogeReserve = IERC20(DogeAssets[whichDoge]).balanceOf(tLP);
        uint8 dogeDecimolz = IERC20(DogeAssets[whichDoge]).decimals();
        uint256 whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbPrice();
        uint256 reserveVal = IERC20(DogeAssets[whichDoge]).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);
        return (reserveVal, whichDogePrice); //returns price value of selected reserve in BUSD and then returns the price in BUSD of the asset
    }

    //Total Reserve Value in BUSD
    function DogeReserveValueTotal() public view returns (uint256) {
        uint256 count = 1;
        uint256 reserveVal = 0;
        while (count <= nDoges) {
            address tLP = IUniswap(factory).getPair(IUniswap(router).WETH(), DogeAssets[count]);
            uint256 wbnbReserve = IERC20(IUniswap(router).WETH()).balanceOf(tLP);
            uint256 dogeReserve = IERC20(DogeAssets[count]).balanceOf(tLP);
            uint8 dogeDecimolz = IERC20(DogeAssets[count]).decimals();
            uint256 whichDogePrice = ((wbnbReserve*10**dogeDecimolz) / dogeReserve) * bnbPrice();
            reserveVal += IERC20(DogeAssets[count]).balanceOf(address(this)) * whichDogePrice / 10 ** (18+dogeDecimolz);
            count += 1;
        }
        return reserveVal;
    }

    //MarketCap in BUSD
    function marketCap() public view returns (uint256 mcap) {
        mcap = totalSupply() * dogewhalePrice() / 10**36;
    }

}

/* changes:
- Custom whitelisting for specialized contracts (kanban, marketing, distro) so when the grace period ends, these contracts can still execute their functions without applying a tax on top
- Implemented a second snapshot, this one for weighted voting. This should be used later once we got the DAO (Doge Alliance Organization - A decentralized autonomous enterprise rolling [lol yes it's a DAO, but a doge DAO you feel me?] haha amaze)
- Introduced boolean variable for the checkpoint check block after a transaction. Better that way, uses less gas too.
*/