// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

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
import "./RootedToken.sol";
import "./IPancakeRouter02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGate.sol";
import "./FreeParticipantRegistry.sol";
import "./BlackListRegistry.sol";
import "./IPancakeFactory.sol";

contract RootedTransferGate is TokensRecoverable, ITransferGate {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IPancakeRouter02 internal immutable pancakeRouter;
    RootedToken internal immutable rootedToken;

    bool public unrestricted;
    mapping(address => bool) public unrestrictedControllers;
    mapping(address => bool) public feeControllers;
    mapping(address => uint16) public poolsTaxRates;
    mapping(address => bool) public distributors;
    mapping(address => bool) private _isSniper;

    IPancakePair public mainPool;
    FreeParticipantRegistry public freeParticipantRegistry;
    BlackListRegistry public blackListRegistry;
    IPancakeFactory factory;

    bool public tradingOpened;
    address public override feeSplitter;
    uint16 public feesRate;

    uint16 public dumpTaxStartRate;
    uint256 public dumpTaxDurationInSeconds;
    uint256 public dumpTaxEndTimestamp;

    address[] private _confirmedSnipers;

    uint256 buyLimit = 125000000000000000000000;
    uint256 endLimit;
    uint256 public launchTime;
    
    IERC20 baseToken;
    address elite;

    modifier onlyDistributors() {
        require(
            msg.sender == owner || distributors[msg.sender],
            "Distributors required"
        );
        _;
    }

    constructor(
        RootedToken _rootedToken,
        IPancakeRouter02 _pancakeRouter,
        IPancakeFactory _factory,
        IERC20 _baseToken
    ) {
        rootedToken = _rootedToken;
        pancakeRouter = _pancakeRouter;
        tradingOpened = true;
        factory = _factory;
        baseToken = _baseToken;
    }

    function toggleTrading(bool _tradingOpened) external ownerOnly {
        tradingOpened = _tradingOpened;
    }

    function checkLimitTime() private view returns (bool) {
        if (endLimit - block.timestamp > 0) {
            return false; //limit still in affect
        }
        return true;
    }

    function startTradeLimit(uint256 timeInSeconds) public ownerOnly {
        endLimit = block.timestamp + timeInSeconds;
    }

    function setDistributor(address _distributor) public ownerOnly {
        distributors[_distributor] = true;
    }

    function setLaunchTime(uint256 _launchTime) public onlyDistributors {
        launchTime = _launchTime;
    }

    function setFactory(
        IPancakeFactory _factory
    ) public ownerOnly {
        factory = _factory;
    }

    function setUnrestrictedController(
        address unrestrictedController,
        bool allow
    ) public ownerOnly {
        unrestrictedControllers[unrestrictedController] = allow;
    }

    function setFeeControllers(address feeController, bool allow)
        public
        ownerOnly
    {
        feeControllers[feeController] = allow;
    }

    function setFreeParticipantController(
        address freeParticipantController,
        bool allow
    ) public ownerOnly {
        freeParticipantRegistry.setFreeParticipantController(
            freeParticipantController,
            allow
        );
    }

    function setFreeParticipant(address participant, bool free) public {
        require(
            msg.sender == owner ||
                freeParticipantRegistry.freeParticipantControllers(msg.sender),
            "Not an owner or free participant controller"
        );
        freeParticipantRegistry.setFreeParticipant(participant, free);
    }

    function setFeeSplitter(address _feeSplitter) public ownerOnly {
        feeSplitter = _feeSplitter;
    }

    function setUnrestricted(bool _unrestricted) public {
        require(
            unrestrictedControllers[msg.sender],
            "Not an unrestricted controller"
        );
        unrestricted = _unrestricted;
        rootedToken.setLiquidityLock(mainPool, !_unrestricted);
    }

    function setFreeParticipantRegistry(
        FreeParticipantRegistry _freeParticipantRegistry
    ) public ownerOnly {
        freeParticipantRegistry = _freeParticipantRegistry;
    }

    function setBlackListRegistry(BlackListRegistry _blackListRegistry)
        public
        ownerOnly
    {
        blackListRegistry = _blackListRegistry;
    }

    function setMainPool(IPancakePair _mainPool) public ownerOnly {
        mainPool = _mainPool;
    }

    function setPoolTaxRate(address pool, uint16 taxRate) public ownerOnly {
        require(
            taxRate <= 10000,
            "Fee rate must be less than or equal to 100%"
        );
        poolsTaxRates[pool] = taxRate;
    }

    function setDumpTax(uint16 startTaxRate, uint256 durationInSeconds) public {
        require(
            feeControllers[msg.sender] || msg.sender == owner,
            "Not an owner or fee controller"
        );
        require(
            startTaxRate <= 10000,
            "Dump tax rate must be less than or equal to 100%"
        );

        dumpTaxStartRate = startTaxRate;
        dumpTaxDurationInSeconds = durationInSeconds;
        dumpTaxEndTimestamp = block.timestamp + durationInSeconds;
    }

    function getDumpTax() public view returns (uint256) {
        if (block.timestamp >= dumpTaxEndTimestamp) {
            return 0;
        }

        return
            (dumpTaxStartRate *
                (dumpTaxEndTimestamp - block.timestamp) *
                1e18) /
            dumpTaxDurationInSeconds /
            1e18;
    }

    function getPairAddress() private view returns (address) {
        return factory.getPair(address(rootedToken), address(baseToken));
    }

    function getElitePairAddress() private view returns (address) {
        return factory.getPair(address(elite), address(rootedToken));
    }

    function setFees(uint16 _feesRate) public {
        require(
            feeControllers[msg.sender] || msg.sender == owner,
            "Not an owner or fee controller"
        );
        require(
            _feesRate <= 10000,
            "Fee rate must be less than or equal to 100%"
        );
        feesRate = _feesRate;
    }

    function setElite(address _elite) public ownerOnly {
        elite = _elite;
    }

    function handleTransfer(
        address,
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (uint256) {
        require(tradingOpened || msg.sender == owner || freeParticipantRegistry.freeParticipant(from) || freeParticipantRegistry.freeParticipant(to), "Trading not open");
        require(!_isSniper[to], "You have no power here!");
        require(!_isSniper[msg.sender], "You have no power here!");

        if (
            unrestricted ||
            freeParticipantRegistry.freeParticipant(from) ||
            freeParticipantRegistry.freeParticipant(to)
        ) {
            return 0;
        }
        if (
            blackListRegistry.blackList(from) || blackListRegistry.blackList(to)
        ) {
            return amount;
        }

        uint16 poolTaxRate = poolsTaxRates[to];

        if (poolTaxRate > feesRate) {
            uint256 totalTax = getDumpTax() + poolTaxRate;
            return totalTax >= 10000 ? amount : (amount * totalTax) / 10000;
        }

        //check the max buy cooldown time
        bool limitInAffect = checkLimitTime();
        if (!limitInAffect) {
            if (!distributors[msg.sender]) {
                if (
                    to != getPairAddress() &&
                    to != getElitePairAddress()
                ) {
                    uint256 totalAmount = rootedToken.transfersReceived(to);
                    require(
                        totalAmount <= buyLimit,
                        "Total Amount already received until time limit over."
                    );
                }
            }
        }

        // check for snipers
        if (
            to != getElitePairAddress() &&
            !distributors[msg.sender] &&
            to != address(pancakeRouter) &&
            !distributors[to]
        ) {
            //antibot
            if (block.timestamp == launchTime) {
                _isSniper[to] = true;
                _confirmedSnipers.push(to);
            }
        }
        return (amount * feesRate) / 10000;
    }

    function isRemovedSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function _removeSniper(address account) public ownerOnly {
        require(
            account != 0x10ED43C718714eb63d5aA57B78B54704E256024E,
            "We can not blacklist Uniswap"
        );
        require(!_isSniper[account], "Account is already blacklisted");
        _isSniper[account] = true;
        _confirmedSnipers.push(account);
    }

    function _amnestySniper(address account) public ownerOnly {
        require(_isSniper[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
            if (_confirmedSnipers[i] == account) {
                _confirmedSnipers[i] = _confirmedSnipers[
                    _confirmedSnipers.length - 1
                ];
                _isSniper[account] = false;
                _confirmedSnipers.pop();
                break;
            }
        }
    }
}