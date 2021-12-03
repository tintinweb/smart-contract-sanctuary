/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
/*
                                                             .:::.
                                                         .-----:-+:
                                     ..::::::::::..    :-::::-:::==
               .:::::..       .:-----:::::::::::::::-----:--:::::==
              -+--::------::---:::::::::::..   .::::::::::.....::==
              ==:::::::::::--:::::::::::.       ::::::::::  ..  :+:
              -=:::::::--::::::::::::::: .::::::::::::::::::::-:-+.
              .+:::::::---::::::::::::::::::-==--:::::::::::=. .=-
               --:::::-:::::::::::::::::::-+:-+=-::::::::::[email protected]*%* +:
                =:::::::::::::::::::::::::* #*-%@=:::::::::*@*%%-+::
                 +:::::::::::::::::::::::-*.%@%@@=-:::::...:=+==:::.:  .....
                =::::::::::::::::....::----==*++=-::...:-=++=-:.::..:-:   ....
               =-::::::::::::::......:::::-----:::.. .*##%###%#:.:-:::-...
              =-::::::::::::::.     .-=..::---==:.   .+#@@%#@@#:.-:-*+-::::.
             :=:::::::::::::::      .-##+-:::::::::...:=*####*:...:*#:.     ...
             +-::::::::::::::.  .......=*##+=-::.........:-*::--=*#*: .
            :=:::::::::::::::.          .:-+##%%%%#########%%%[email protected]*-.  .
            =-::::::::::::::::.             .-*%@@@+*@@@@@@@@%%%+.   .                     .
            +::::::::::::::::::.             .:*%@@@%#**#%%%***%=.   .                    -==-
            +::::::::::::::::::::.            .:*%@%***********%+.  ..                    =::-=.
           .+:::::::::::::::::::::.            .:+#%###****###%*:    .                   =-::::=-
           .+::::::::::::::::::::::.             .:-=+*****+=-:.    .                   --::::::=-
           :+::::::::::::::::::::::::.               ..         .:--:.                 :=:::::::-+
           .+:::::::::::::::::::::::::.          .:::..... .....-=---==                +::::::::-=
            +::::::::::::::::::::::::::.....    .--:.::-::.... --::::-+               .+:::::::-=-
            +-::::::::::::::::::::::::::       .--:.:-.==:.....=-:::::+-.              +::::::::-+::..
            ==::::::::::::::::::::::::::      .--:....:.......=-:::::::-=+-            =-:::::::::::--===-.
            :+::::::::::::::::::::::::::     :--:............--:::::::::::+:           .=:::::::::::::::::==.
             +-:::::::::::::::::-------=-:  :---.............==:::::::::-==         .::=:-::::::::::::::::::=:
             :+::::::::::::::::::::::::::-===========-:.......:==========-..  ..:::-:::::::::::::::::::::::::+.
              =-:::::::::::::::::::::::::::::::::::::-+:.................:           .:::::::===--:::::::::::==
              .+-:::::::::::::::::::::::::::::::::::::+:..................:.          :::::::+-:::---=======--:
               .+-::::::::::::::::::::::::::::::::::-+-.........=+==++-:....:.        .:::::+-
                .+-::::::::::::-:::::::::::::::::::==:..........+=....:-+=:.::::.     .::::+-
                  ==::::::::::::---:::::::::::::-==:............=+-....:-+=+-...::::..:::-+:
                   :+=:::::::::::::--====---=====:......:........=+=-=++-...-=......::--=+:
                     -+-::::::::::::::::::::=----=.......-......:-++++:......:+=-:.........::::::::-:
                       -+-:::::::::::::::::::=----=.......=..:=++=:.-++:..:-+=-=:..................-=
                         :==-::::::::::::::::-=----=......-++=-:.....:++=++-....-.................--=.
                           .-+=:::::::::::::::------=...:--:=-......:=++++......:................---=
                              .-==-::::::::::::=-----=:......==:.:=++=:.=+=....................:---=:
                                 .:===-:::::::::------=-.....:=++=-......=+-..................:-----
                                      :-====----:==-----=..:::..-+=:......++:................------
                                            ..::---=-----=-.......-+=-....-+=..............:----=-
                                                    -=-----=........:=+=--++:............:-----=.
                                                      ------=-.........:--:............:-----=:
                                                       .=-----=-..................::------=-:
                                                         :=-----==---------------------=-:
                                                           -=---------------------=--:.
                                                             -=--------==----:::.
                                                               .....

                                        DOGEWHALE DISTRO CONTRACT
by DeFi LABS

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

interface iTools {
    function bnbPrice() external view returns (uint256 BNBUSDprice);
}

interface iWBNB{
    function deposit() external payable;
}

interface iRouter {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
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

contract DOGEWHALE_DISTRIBUTION is Initializable {
    address payable public controller;                  // manager

    bool public status;                                 // status of deposits, is it live? = true, false
    uint256 public deadline;                            // deadline by which no more bnb can be accepted
    uint256 public totalPacked;                         // total amount of bnb sent to this contract
    bool public release;                                // can release tokens?
    mapping (address => uint256) private _amountSent;   // how much bnb sent to this contract via the reserveDOGEWHALE()
    mapping (address => bool) public hasClaimed;        // has the address claimed the tokens?
    mapping (address => bool) public hasClaimedDrop;    // has the address claimed the drop?
    mapping (address => uint256) public dropAmounts;    // dlabs community drop amounts

    address public assetContractAddress;                // address of the asset to release [dogewhale]
    uint256 public packedSupply;                        // supply of release token
    uint256 public dlabsSupply;                         // supply for dlabs community holders
    uint256 public dlabsVesting;                        // vesting period for dlabs community holders

    //variables for liquidity vesting option
    address public router;
    address public wbnb;
    address public dogeally;
    address public dogefusion33;
    address public wbnbdogeally_lp_addy;
    uint256 public slippage;
    mapping(address => uint256) public vestedLP;
    uint256 public LP_bonus;
    uint256 public dogefusion33_bonus;

    event reservedTokensWithBonus(address indexed _address, uint256 _howMuch, uint256 _bonus);
    event reservedTokens(address indexed _address, uint256 _howMuch);
    event gotTokens(address indexed _address, uint256 _howMuch);

    function init() external payable initializer {
        controller = payable(msg.sender);
        deadline = 1640304000;                                              // temp deadline, initialization
        status = true;                                                      // is live
        release = false;
        assetContractAddress = 0x43adC41cf63666EBB1938B11256f0ea3f16e6932;  // dogewhale address

        //variables for liquidity vesting option
        router = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;    // apeswap router
        wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        dogeally = 0x05822195B28613b0F8A484313d3bE7B357C53A4a;
        dogefusion33 = 0x4704048eBD36CcB87e1e7c037c3D5B2FfBE16842;
        wbnbdogeally_lp_addy = 0x04Df78093e2b66A0387F8c052C8d344D84ca49aF;
        slippage = 2*10**16;                    // slippage = 2%
        LP_bonus = 10*10**16;                   // lp providers reward, default: 10%
        dogefusion33_bonus = 3*10**16;          // dogefusion33 bonus, default: 3%

        packedSupply = 300000000000*10**18;     // supply available
        dlabsSupply = 2*10**28;                 // dlabs community supply, indicative
        dlabsVesting = 0;                       // dlabs vesting, activated post conclusion
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // VIEW FUNCTIONS  =============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function isLive() public view returns (bool) {
        return status;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function contractBalanceinBUSD() public view returns (uint256) {
        return (contractBalance()*iTools(0x43adC41cf63666EBB1938B11256f0ea3f16e6932).bnbPrice())/10**18;
    }

    function userBNB(address _useraddress) public view returns (uint256) {
        return _amountSent[_useraddress];
    }

    function userShare(address _useraddress) public view returns (uint256) {
        return _amountSent[_useraddress]*10**18 / totalPacked;  // totalPacked is the total amount of bnb sent + bonus
    }

    function userTokensToReceive(address _useraddress) public view returns (uint256) {
        return (packedSupply * userShare(_useraddress)) / 10 ** 18;
    }

    function hasEnoughDF33(address _useraddress) public view returns (bool) {
        if (IERC20(dogefusion33).balanceOf(_useraddress) >= 33*10**16) {
            return true;
        } else {
            return false;
        }
    }

    function hasEnoughDogeAlliance(address _address, uint256 _howMuchBnb) public view returns (bool) {
        uint256 dogeallyRequired = iRouter(router).getAmountOut(_howMuchBnb/2, IERC20(wbnb).balanceOf(wbnbdogeally_lp_addy), IERC20(dogeally).balanceOf(wbnbdogeally_lp_addy));
        if (IERC20(dogeally).balanceOf(_address) >= dogeallyRequired) {
            return true;
        } else {
            return false;
        }
    }

    function web() public pure returns (string memory) {
        return "Telegram: https://t.me/dogewhale_community";
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // USER FUNCTIONS  =============================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function reserveDOGEWHALE() public payable returns (bool) {
        require (block.timestamp < deadline, "Unable");
        require (status == true, "Unable");
        uint256 bal = IERC20(dogefusion33).balanceOf(msg.sender);
        if (bal >= 33*10**16) {
            _amountSent[msg.sender] += msg.value + _pct(msg.value, dogefusion33_bonus);
            totalPacked += msg.value + _pct(msg.value, dogefusion33_bonus);
            emit reservedTokensWithBonus(msg.sender, msg.value, msg.value + _pct(msg.value, dogefusion33_bonus));
        } else {
            _amountSent[msg.sender] += msg.value;
            totalPacked += msg.value;
            emit reservedTokens(msg.sender, msg.value);
        }
        return true;
    }

    function reserveDOGEWHALEforLiquidity() public payable returns (bool) {
        require (block.timestamp < deadline, "Unable");
        require (status == true, "Unable");

        uint256 wbnb4LP = msg.value / 2;

        // swaps half the bnb for wbnb
        iWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).deposit{value: wbnb4LP}();

        // check the wBNB balance of Doge Alliance LP
        uint256 wbnb_LP_balance = IERC20(wbnb).balanceOf(wbnbdogeally_lp_addy);
        // check the DOGEALLY balance of Doge Alliance LP
        uint256 dogeally_LP_balance = IERC20(dogeally).balanceOf(wbnbdogeally_lp_addy);

        //check if sender has enough Doge Alliance and proceed with LP amount calculations
        uint256 amountOutinDogeAlly = iRouter(router).getAmountOut(wbnb4LP, wbnb_LP_balance, dogeally_LP_balance);
        require (IERC20(dogeally).balanceOf(msg.sender) >= amountOutinDogeAlly, "Not enough Doge Alliance");
        uint256 dogeallyMinAmount = amountOutinDogeAlly - _pct(amountOutinDogeAlly, slippage);
        uint256 wbnbMinAmount = wbnb4LP - _pct(wbnb4LP, slippage);

        //transfer Doge Alliance - requires approval DogeAlliance.approve(address(this), amountOutinDogeAlly)
        IERC20(dogeally).transferFrom(msg.sender, address(this), amountOutinDogeAlly);

        // approve ERC20s for LP addition to DogeAlliance
        IERC20(wbnb).approve(router, IERC20(wbnb).balanceOf(address(this)));
        IERC20(dogeally).approve(router, amountOutinDogeAlly);

        // add liquidity to Doge Alliance
        iRouter(router).addLiquidity(wbnb, dogeally, wbnb4LP, amountOutinDogeAlly, wbnbMinAmount, dogeallyMinAmount, 0xea8e300e4140fc75B36F82878269e9bd88dD1597, block.timestamp+60);

        // register distro balances
        uint256 bal = IERC20(dogefusion33).balanceOf(msg.sender);
        if (bal >= 33*10**16) {
            _amountSent[msg.sender] += msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus + dogefusion33_bonus);
            totalPacked += msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus + dogefusion33_bonus);
            emit reservedTokensWithBonus(msg.sender, msg.value, msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus + dogefusion33_bonus));
        } else {
            _amountSent[msg.sender] += msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus);
            totalPacked += msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus);
            emit reservedTokensWithBonus(msg.sender, msg.value, msg.value + wbnb4LP + _pct((msg.value + wbnb4LP), LP_bonus));
        }
        return true;
    }

    function claimDOGEWHALE() public virtual returns (bool) {
        require(release == true, "Not yet");
        require(status == false, "Not yet");
        require(hasClaimed[msg.sender] == false, "Unable to claim");

        uint256 howMuch = _pct(packedSupply, userShare(msg.sender));
        IERC20(assetContractAddress).transfer(msg.sender, howMuch);

        hasClaimed[msg.sender] = true;
        emit gotTokens(msg.sender, howMuch);
        return true;
    }

    function claimDrop() public virtual returns (bool) {
        require(dlabsVesting != 0 && dlabsVesting < block.timestamp, "Not the time yet");
        require(status == false, "Not yet");
        require(hasClaimedDrop[msg.sender] == false, "Unable to claim");

        IERC20(assetContractAddress).transfer(msg.sender, dropAmounts[msg.sender]);
        emit gotTokens(msg.sender, dropAmounts[msg.sender]);
        dropAmounts[msg.sender] = 0;

        hasClaimedDrop[msg.sender] = true;
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // CONTROLLER FUNCTIONS  =======================================================================>
    /////////////////////////////////////////////////////////////////////////////////////////////////
    function conclude() public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        uint amount = address(this).balance;
        (bool success,) = controller.call{value: amount}("");
        require(success, "Failed to send Ether");
        packedSupply = IERC20(assetContractAddress).balanceOf(address(this));
        status = false;
        dlabsVesting = block.timestamp + 9204100; // 3 and half months past conclusion
        return true;
    }

    // activates distribution transfers
    function activateRelease() public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        release = true;
        return true;
    }

    // alter the deadline for a set date
    function adjustDeadline(uint256 _deadline) public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        deadline = _deadline;
        return true;
    }

    // alter deadline to now + arg minutes
    function setDeadline(uint256 _minutes) public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        deadline = block.timestamp + (60*_minutes);
        return true;
    }

    // set int for slippage on the liquidity vesting option. Example: 1 = 1% slippage
    function setSlippage(uint256 _slippage) public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        slippage = _slippage*10**16;
        return true;
    }

    // set dlabs amounts for vested drop
    function setDrops(address[] memory _addresses, uint256[] memory _amounts) public virtual returns (bool) {
        require (msg.sender == controller, "Unable");
        for (uint256 i = 0; i < _addresses.length; i++) {
            dropAmounts[_addresses[i]] = _amounts[i];
        }
        return true;
    }

    // transfer any extra dogewhale to dogewhale contract
    function tidyUp() public virtual returns (bool) {
        require(msg.sender == controller, "unable");
        require(release == true, "unable");
        IERC20(assetContractAddress).transfer(assetContractAddress, IERC20(assetContractAddress).balanceOf(address(this)));
        return true;
    }

    // updates state on proxy upgrade
    function updateState() public virtual returns (bool) {
        require (msg.sender == controller, "unable");
        dogefusion33_bonus = 3*10**16;          // dogefusion33 bonus, default: 3%
        dlabsSupply = 2*10**28;                 // dlabs community supply, indicative
        return true;
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
}