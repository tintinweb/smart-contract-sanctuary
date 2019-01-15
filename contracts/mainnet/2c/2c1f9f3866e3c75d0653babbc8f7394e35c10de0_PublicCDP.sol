// Resolver to Wipe & Coll any CDP
pragma solidity 0.4.24;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Assertion Failed");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Assertion Failed");
        uint256 c = a / b;
        return c;
    }

}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface AddressRegistry {
    function getAddr(string name) external view returns(address);
}

interface MakerCDP {
    function join(uint wad) external; // Join PETH
    function lock(bytes32 cup, uint wad) external;
    function wipe(bytes32 cup, uint wad) external;
    function per() external view returns (uint ray);
}

interface PriceInterface {
    function peek() external view returns (bytes32, bool);
}

interface WETHFace {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface InstaKyber {
    function executeTrade(
        address src,
        address dest,
        uint srcAmt,
        uint minConversionRate,
        uint maxDestAmt
    ) external payable returns (uint destAmt);

    function getExpectedPrice(
        address src,
        address dest,
        uint srcAmt
    ) external view returns (uint, uint);
}


contract Registry {

    address public addressRegistry;
    modifier onlyAdmin() {
        require(
            msg.sender == getAddress("admin"),
            "Permission Denied"
        );
        _;
    }
    
    function getAddress(string name) internal view returns(address) {
        AddressRegistry addrReg = AddressRegistry(addressRegistry);
        return addrReg.getAddr(name);
    }

}


contract Helper is Registry {

    using SafeMath for uint;
    using SafeMath for uint256;

    address public cdpAddr;
    address public eth;
    address public weth;
    address public peth;
    address public mkr;
    address public dai;
    address public kyber;

    function pethPEReth(uint ethNum) public view returns (uint rPETH) {
        MakerCDP loanMaster = MakerCDP(cdpAddr);
        rPETH = (ethNum.mul(10 ** 27)).div(loanMaster.per());
    }

}


contract Lock is Helper {

    event LockedETH(uint cdpNum, address lockedBy, uint lockETH, uint lockPETH);

    function lockETH(uint cdpNum) public payable {
        MakerCDP loanMaster = MakerCDP(cdpAddr);
        WETHFace wethTkn = WETHFace(weth);
        wethTkn.deposit.value(msg.value)(); // ETH to WETH
        uint pethToLock = pethPEReth(msg.value);
        loanMaster.join(pethToLock); // WETH to PETH
        loanMaster.lock(bytes32(cdpNum), pethToLock); // PETH to CDP
        emit LockedETH(
            cdpNum, msg.sender, msg.value, pethToLock
        );
    }

}


contract Wipe is Lock {

    event WipedDAI(uint cdpNum, address wipedBy, uint daiWipe, uint mkrCharged);

    function wipeDAI(uint cdpNum, uint daiWipe) public payable {
        IERC20 daiTkn = IERC20(dai);
        IERC20 mkrTkn = IERC20(mkr);

        uint contractMKR = mkrTkn.balanceOf(address(this)); // contract MKR balance before wiping
        daiTkn.transferFrom(msg.sender, address(this), daiWipe); // get DAI to pay the debt
        MakerCDP loanMaster = MakerCDP(cdpAddr);
        loanMaster.wipe(bytes32(cdpNum), daiWipe); // wipe DAI
        uint mkrCharged = contractMKR - mkrTkn.balanceOf(address(this)); // MKR fee = before wiping bal - after wiping bal

        // claiming paid MKR back
        if (msg.value > 0) { // Interacting with Kyber to swap ETH with MKR
            swapETHMKR(
                mkrCharged, msg.value
            );
        } else { // take MKR directly from address
            mkrTkn.transferFrom(msg.sender, address(this), mkrCharged); // user paying MKR fees
        }

        emit WipedDAI(
            cdpNum, msg.sender, daiWipe, mkrCharged
        );
    }

    function swapETHMKR(
        uint mkrCharged,
        uint ethQty
    ) internal 
    {
        InstaKyber instak = InstaKyber(kyber);
        uint minRate;
        (, minRate) = instak.getExpectedPrice(eth, mkr, ethQty);
        uint mkrBought = instak.executeTrade.value(ethQty)(
            eth, mkr, ethQty, minRate, mkrCharged
        );
        require(mkrCharged == mkrBought, "ETH not sufficient to cover the MKR fees.");
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

}


contract ApproveTkn is Wipe {

    function approveERC20() public {
        IERC20 wethTkn = IERC20(weth);
        wethTkn.approve(cdpAddr, 2**256 - 1);
        IERC20 pethTkn = IERC20(peth);
        pethTkn.approve(cdpAddr, 2**256 - 1);
        IERC20 mkrTkn = IERC20(mkr);
        mkrTkn.approve(cdpAddr, 2**256 - 1);
        IERC20 daiTkn = IERC20(dai);
        daiTkn.approve(cdpAddr, 2**256 - 1);
    }

}


contract PublicCDP is ApproveTkn {

    event MKRCollected(uint amount);

    constructor(address rAddr) public {
        addressRegistry = rAddr;
        cdpAddr = getAddress("cdp");
        eth = getAddress("eth");
        weth = getAddress("weth");
        peth = getAddress("peth");
        mkr = getAddress("mkr");
        dai = getAddress("dai");
        kyber = getAddress("InstaKyber");
        approveERC20();
    }

    function () public payable {}

    // collecting MKR token kept as balance to pay fees
    function collectMKR(uint amount) public onlyAdmin {
        IERC20 mkrTkn = IERC20(mkr);
        mkrTkn.transfer(msg.sender, amount);
        emit MKRCollected(amount);
    }

}