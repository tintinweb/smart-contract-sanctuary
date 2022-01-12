/**
 *Submitted for verification at FtmScan.com on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function decimals() external view returns(uint8);
}

interface IFlashloanReceiver {
    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external;
}

interface ICTokenFlashloan {
    function flashLoan(
        address receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface SpiritRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external;
}

interface BAMMInterface {
    function swap(uint lusdAmount, IERC20 returnToken, uint minReturn, address payable dest) external returns(uint);
    function LUSD() external view returns(address);
    function collaterals(uint i) external view returns(address);
}

interface CurveInterface {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns(uint);
}

contract CreamArb {
    IERC20 constant public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    SpiritRouter constant public ROUTER = SpiritRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);
    CurveInterface constant public CURVE = CurveInterface(0x27E611FD27b276ACbd5Ffd632E5eAEBEC9761E40);
    IERC20 constant public DAI = IERC20(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E);
    IERC20 constant public USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);

    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external returns(bytes32) {
        IERC20(underlying).approve(initiator, amount + fee);

        (BAMMInterface bamm, address[] memory path, IERC20 dest) = abi.decode(params, (BAMMInterface, address[], IERC20));
        // swap on the bamm
        IERC20(underlying).approve(address(bamm), amount);
        uint destAmount = bamm.swap(amount, dest, 1, address(this));

        dest.approve(address(ROUTER), destAmount);
        if(dest != USDC) {
            ROUTER.swapExactTokensForTokens(destAmount, 1, path, address(this), now);
        }

        if(underlying == address(DAI)) {
            uint usdcAmount = USDC.balanceOf(address(this));
            USDC.approve(address(CURVE), usdcAmount);
            CURVE.exchange(1, 0, usdcAmount, 1);
        }        

        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function arb(BAMMInterface bamm, uint srcAmount, address dest) public {
        IERC20 src = IERC20(bamm.LUSD());

        ICTokenFlashloan creamToken;
        if(src == DAI) {
            creamToken = ICTokenFlashloan(0x04c762a5dF2Fa02FE868F25359E0C259fB811CfE);
        }
        else if(src == USDC) {
            creamToken = ICTokenFlashloan(0x328A7b4d538A2b3942653a9983fdA3C12c571141);
        }
        else revert("arb: unsupported src");

        address[] memory path = new address[](3);
        path[0] = dest;
        path[1] = address(WFTM);
        path[2] = address(USDC);

        bytes memory data = abi.encode(bamm, path, dest);
        creamToken.flashLoan(address(this), address(creamToken), srcAmount, data);

        src.transfer(msg.sender, src.balanceOf(address(this)));
    }

    // revert on failure
    function checkProfitableArb(uint usdQty, uint minProfit, BAMMInterface bamm, address dest) external returns(bool){
        IERC20 src = IERC20(bamm.LUSD());
        uint balanceBefore = src.balanceOf(address(this));
        this.arb(bamm, usdQty, dest);
        uint balanceAfter = src.balanceOf(address(this));
        require((balanceAfter - balanceBefore) >= minProfit, "min profit was not reached");

        return true;
    }    

    fallback() payable external {

    }
}

contract BFantomKeeper {
    CreamArb public arb;
    uint maxUsdQty = 100000e18; // = 100k usd;
    uint minUsdQty = 1e16; // 1 cent
    uint minProfitInBps = 0; // = 100;

    address public admin;
    address[] public bamms;
    mapping(address => address[]) bammTokens; // bamm => array of underlying

    event KeepOperation(bool succ);


    constructor(CreamArb _arb) public {
        arb = _arb;
        admin = msg.sender;        
    }

    function findSmallestQty() public returns(uint, address, address) {
        for(uint i = 0 ; i < bamms.length ; i++) {
            address bamm = bamms[i];
            address[] memory dests = bammTokens[bamm];
            IERC20 src = IERC20(BAMMInterface(bamm).LUSD());
            uint decimals = src.decimals();
            uint factor = 10 ** decimals;

            for(uint qty = maxUsdQty ; qty > minUsdQty ; qty = qty / 10) {
                uint normalizedQty = qty * factor / 1e18;
                uint minProfit = normalizedQty * minProfitInBps / 10000;
                for(uint d = 0 ; d < dests.length ; d++) {
                    try arb.checkProfitableArb(normalizedQty, minProfit, BAMMInterface(bamm), dests[d]) returns(bool /*retVal*/) {
                        return (normalizedQty, bamm, dests[d]);
                    } catch {

                    }
                }
            }
        }

        return (0, address(0), address(0));
    }

    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory performData) {
        (uint qty, address bamm, address dest) = findSmallestQty();

        upkeepNeeded = qty > 0;
        performData = abi.encode(qty, bamm, dest);
    }
    
    function performUpkeep(bytes calldata performData) external {
        (uint qty, address bamm, address dest) = abi.decode(performData, (uint, address, address));
        require(qty > 0, "0 qty");

        arb.arb(BAMMInterface(bamm), qty, dest);
        
        emit KeepOperation(true);        
    }

    function performUpkeepSafe(bytes calldata performData) external {
        try this.performUpkeep(performData) {
            emit KeepOperation(true);
        }
        catch {
            emit KeepOperation(false);
        }
    }

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        (bool upkeepNeeded, bytes memory performData) = this.checkUpkeep(bytes(""));
        canExec = upkeepNeeded;

        execPayload = abi.encodeWithSelector(
            BFantomKeeper.doer.selector,
            performData
        );
    }

    function doer(bytes calldata performData) external {
        this.performUpkeepSafe(performData);
    }    

    receive() external payable {}

    // admin stuff
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "!admin");
        admin = newAdmin;
    }

    function setArb(CreamArb _arb) external {
        require(msg.sender == admin, "!admin");
        arb = _arb;
    }

    function setMaxQty(uint newVal) external {
        require(msg.sender == admin, "!admin");
        maxUsdQty = newVal;
    }

    function setMinQty(uint newVal) external {
        require(msg.sender == admin, "!admin");
        minUsdQty = newVal;        
    }
    
    function setMinProfit(uint newVal) external {
        require(msg.sender == admin, "!admin");
        minProfitInBps = newVal;        
    }

    function addBamm(address newBamm) external {
        require(msg.sender == admin, "!admin");        
        bamms.push(newBamm);

        for(uint i = 0 ; true ; i++) {
            try BAMMInterface(newBamm).collaterals(i) returns(address collat) {
                bammTokens[newBamm].push(collat);
            }
            catch {
                break;
            }
        }
    }

    function removeBamm(address bamm) external {
        require(msg.sender == admin, "!admin");
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(bamms[i] == bamm) {
                bamms[i] = bamms[bamms.length - 1];
                bamms.pop();

                return;
            }
        }

        revert("bamm does not exist");
    }

    function withdrawToken(IERC20 token, address to, uint qty) external {
        require(msg.sender == admin, "!admin");
        token.transfer(to, qty);
    }
}