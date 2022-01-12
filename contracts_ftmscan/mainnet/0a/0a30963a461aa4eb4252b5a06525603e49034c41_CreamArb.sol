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

contract CreamArb {
    IERC20 constant public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    SpiritRouter constant public ROUTER = SpiritRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);


    function onFlashLoan(address initiator, address underlying, uint amount, uint fee, bytes calldata params) external returns(bytes32) {
        IERC20(underlying).approve(initiator, amount + fee);

        (BAMMInterface bamm, address[] memory path, IERC20 dest) = abi.decode(params, (BAMMInterface, address[], IERC20));
        // swap on the bamm
        IERC20(underlying).approve(address(bamm), amount);
        uint destAmount = bamm.swap(amount, dest, 1, address(this));

        dest.approve(address(ROUTER), destAmount);
        ROUTER.swapExactTokensForTokens(destAmount, 1, path, address(this), now);

        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function arb(BAMMInterface bamm, ICTokenFlashloan creamToken, uint srcAmount, address dest) public {
        IERC20 src = IERC20(bamm.LUSD());
        
        address[] memory path = new address[](3);
        path[0] = dest;
        path[1] = address(WFTM);
        path[2] = address(src);

        bytes memory data = abi.encode(bamm, path, dest);
        creamToken.flashLoan(address(this), address(creamToken), srcAmount, data);

        src.transfer(msg.sender, src.balanceOf(address(this)));
    }

    // revert on failure
    function checkProfitableArb(uint usdQty, uint minProfit, BAMMInterface bamm, ICTokenFlashloan creamToken, address dest) external returns(bool){
        IERC20 src = IERC20(bamm.LUSD());
        uint balanceBefore = src.balanceOf(address(this));
        this.arb(bamm, creamToken, usdQty, dest);
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
    mapping(address => address) creamTokens; // bamm => cream
    mapping(address => address[]) bammTokens; // bamm => array of underlying

    event KeepOperation(bool succ);


    constructor(CreamArb _arb) public {
        arb = _arb;
        admin = msg.sender;        
    }

    function findSmallestQty() public returns(uint, address, address, address) {
        for(uint i = 0 ; i < bamms.length ; i++) {
            address bamm = bamms[i];
            address[] memory dests = bammTokens[bamm];
            IERC20 src = IERC20(BAMMInterface(bamm).LUSD());
            uint decimals = src.decimals();
            uint factor = 10 ** decimals;
            ICTokenFlashloan cream = ICTokenFlashloan(creamTokens[bamm]);

            for(uint qty = maxUsdQty ; qty > minUsdQty ; qty = qty / 2) {
                uint normalizedQty = qty * factor / 1e18;
                uint minProfit = normalizedQty * minProfitInBps / 10000;
                for(uint d = 0 ; d < dests.length ; d++) {
                    try arb.checkProfitableArb(normalizedQty, minProfit, BAMMInterface(bamm), cream, dests[d]) returns(bool /*retVal*/) {
                        return (normalizedQty, bamm, dests[d], address(cream));
                    } catch {

                    }
                }
            }
        }

        return (0, address(0), address(0), address(0));
    }

    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory performData) {
        (uint qty, address bamm, address dest, address cream) = findSmallestQty();

        upkeepNeeded = qty > 0;
        performData = abi.encode(qty, bamm, dest, cream);
    }
    
    function performUpkeep(bytes calldata performData) external {
        (uint qty, address bamm, address dest, address cream) = abi.decode(performData, (uint, address, address, address));
        require(qty > 0, "0 qty");

        arb.arb(BAMMInterface(bamm), ICTokenFlashloan(cream), qty, dest);
        
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

    function addBamm(address newBamm, address creamToken) external {
        require(msg.sender == admin, "!admin");        
        bamms.push(newBamm);

        creamTokens[newBamm] = creamToken;

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