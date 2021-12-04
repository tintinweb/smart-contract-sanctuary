// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A transfer gate (GatedERC20) for use with upTokens

It:
    Allows customization of tax and burn rates
    Allows transfer to/from approved pools
    Disallows transfer to/from non-approved pools
    Allows transfer to/from anywhere else
    Allows for free transfers if permission granted
    Allows for unrestricted transfers if permission granted
    Allows for a pool to have an extra tax
    Allows for a temporary declining tax
*/

import "./Address.sol";
import "./IPancakeFactory.sol";
import "./IERC20.sol";
import "./IPancakePair.sol";
import "./ILiquidityLockedERC20.sol";
import "./IPancakeRouter02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGate.sol";

contract RootedTransferGate is TokensRecoverable, ITransferGate
{   
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IPancakeRouter02 immutable internal pancakeRouter;
    IPancakeFactory immutable internal pancakeFactory;
    ILiquidityLockedERC20 immutable internal rootedToken;

    bool public unrestricted;
    mapping (address => bool) public unrestrictedControllers;
    mapping (address => bool) public feeControllers;
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipant;
    mapping (address => uint16) public poolsTaxRates;

    address public override feeSplitter;
    uint16 public feesRate;
    IPancakePair public mainPool;
   
    uint16 public dumpTaxStartRate; 
    uint256 public dumpTaxDurationInSeconds;
    uint256 public dumpTaxEndTimestamp;

    constructor(ILiquidityLockedERC20 _rootedToken, IPancakeRouter02 _pancakeRouter)
    {
        rootedToken = _rootedToken;
        pancakeRouter = _pancakeRouter;
        pancakeFactory = IPancakeFactory(_pancakeRouter.factory());
    }

    function setUnrestrictedController(address unrestrictedController, bool allow) public ownerOnly()
    {
        unrestrictedControllers[unrestrictedController] = allow;
    }

    function setFreeParticipantController(address freeParticipantController, bool allow) public ownerOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFeeControllers(address feeController, bool allow) public ownerOnly()
    {
        feeControllers[feeController] = allow;
    }

    function setFeeSplitter(address _feeSplitter) public ownerOnly()
    {
        feeSplitter = _feeSplitter;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (msg.sender == owner || freeParticipantControllers[msg.sender], "Not an owner or free participant controller");
        freeParticipant[participant] = free;
    }

    function setUnrestricted(bool _unrestricted) public
    {
        require (unrestrictedControllers[msg.sender], "Not an unrestricted controller");
        unrestricted = _unrestricted;
        rootedToken.setLiquidityLock(mainPool, !_unrestricted);
    }    

    function setMainPool(IPancakePair _mainPool) public ownerOnly()
    {
        mainPool = _mainPool;
    }

     function setPoolTaxRate(address pool, uint16 taxRate) public ownerOnly()
    {
        require (taxRate <= 10000, "Fee rate must be less than or equal to 100%");
        poolsTaxRates[pool] = taxRate;        
    }

    function setDumpTax(uint16 startTaxRate, uint256 durationInSeconds) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (startTaxRate <= 10000, "Dump tax rate must be less than or equal to 100%");

        dumpTaxStartRate = startTaxRate;
        dumpTaxDurationInSeconds = durationInSeconds;
        dumpTaxEndTimestamp = block.timestamp + durationInSeconds;
    }

    function getDumpTax() public view returns (uint256)
    {
        if (block.timestamp >= dumpTaxEndTimestamp) 
        {
            return 0;
        }       
        
        return dumpTaxStartRate*(dumpTaxEndTimestamp - block.timestamp)*1e18/dumpTaxDurationInSeconds/1e18;
    }

    function setFees(uint16 _feesRate) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (_feesRate <= 10000, "Fee rate must be less than or equal to 100%");
        feesRate = _feesRate;
    }

    function handleTransfer(address, address from, address to, uint256 amount) public virtual override returns (uint256)
    {
        if (unrestricted || freeParticipant[from] || freeParticipant[to]) 
        {
            return 0;
        }

        uint16 poolTaxRate = poolsTaxRates[to];

        if (poolTaxRate > feesRate) 
        {
            uint256 totalTax = getDumpTax() + poolTaxRate;
            return totalTax >= 10000 ? amount : amount * totalTax / 10000;
        }

        return amount * feesRate / 10000;
    }   
}