// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A transfer gate (GatedERC20) for use with RootKit tokens

It:
    Allows customization of tax and burn rates
    Allows transfer to/from approved UniswapV2 pools
    Disallows transfer to/from non-approved UniswapV2 pools
    Allows transfer to/from anywhere else
    Allows for free transfers if permission granted
    Allows for unrestricted transfers if permission granted
    Provides a safe and tax-free liquidity adding function
*/

import "./Owned.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./RootKit.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGate.sol";

struct RootKitTransferGateParameters
{
    address dev;
    uint16 stakeRate; // 10000 = 100%
    uint16 burnRate; // 10000 = 100%
    uint16 devRate;  // 10000 = 100%
    address stake;
}

contract RootKitTransferGate is TokensRecoverable, ITransferGate
{   
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum AddressState
    {
        Unknown,
        NotPool,
        DisallowedPool,
        AllowedPool
    }

    RootKitTransferGateParameters public parameters;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    RootKit immutable rootKit;

    mapping (address => AddressState) public addressStates;
    IERC20[] public allowedPoolTokens;
    
    bool public unrestricted;
    mapping (address => bool) public unrestrictedControllers;
    mapping (address => bool) public feeControllers;
    mapping (address => bool) public freeParticipant;

    mapping (address => uint256) public liquiditySupply;
    address public mustUpdate; 

    uint8 public sellStakeRateMultiplier;
    address public taxedPool;

    uint16 public dumpTaxStartRate; 
    uint256 public dumpTaxDurationInSeconds;
    uint256 public dumpTaxEndTimestamp;

    constructor(RootKit _rootKit, address _taxedPool, IUniswapV2Router02 _uniswapV2Router)
    {
        rootKit = _rootKit;
        taxedPool = _taxedPool;
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
    }

    function allowedPoolTokensCount() public view returns (uint256) { return allowedPoolTokens.length; }

    function setUnrestrictedController(address unrestrictedController, bool allow) public ownerOnly()
    {
        unrestrictedControllers[unrestrictedController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        freeParticipant[participant] = free;
    }

    function setFeeControllers(address feeController, bool allow) public ownerOnly()
    {
        feeControllers[feeController] = allow;
    }

    function setUnrestricted(bool _unrestricted) public
    {
        require (unrestrictedControllers[msg.sender], "Not an unrestricted controller");
        unrestricted = _unrestricted;
    }

    function setParameters(address _dev, address _stake, uint16 _stakeRate, uint16 _burnRate, uint16 _devRate) public ownerOnly()
    {
        require (_stakeRate <= 10000 && _burnRate <= 10000 && _devRate <= 10000 && _stakeRate + _burnRate + _devRate <= 10000, "> 100%");
        require (_dev != address(0) && _stake != address(0));
        require (_stakeRate <= 500 && _burnRate <= 500 && _devRate <= 10, "Sanity");
        
        RootKitTransferGateParameters memory _parameters;
        _parameters.dev = _dev;
        _parameters.stakeRate = _stakeRate;
        _parameters.burnRate = _burnRate;
        _parameters.devRate = _devRate;
        _parameters.stake = _stake;
        parameters = _parameters;
    }

    function setSellStakeRateMultiplier(uint8 multiplier) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (multiplier > 0 && multiplier <= 20 , "Must be between 1 and 20"); // protecting everyone from Ponzo
        
        sellStakeRateMultiplier = multiplier;
    }

    function setDumpTax(uint16 startTaxRate, uint256 durationInSeconds) public
    {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (startTaxRate <= 1000, "Dump tax rate should be less than or equal to 10%");  // protecting everyone from Ponzo

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

    function allowPool(IERC20 token) public ownerOnly()
    {
        address pool = uniswapV2Factory.getPair(address(rootKit), address(token));
        if (pool == address(0)) {
            pool = uniswapV2Factory.createPair(address(rootKit), address(token));
        }
        AddressState state = addressStates[pool];
        require (state != AddressState.AllowedPool, "Already allowed");
        addressStates[pool] = AddressState.AllowedPool;
        allowedPoolTokens.push(token);
        liquiditySupply[pool] = IERC20(pool).totalSupply();
    }

    function safeAddLiquidity(IERC20 token, uint256 tokenAmount, uint256 rootKitAmount, uint256 minTokenAmount, uint256 minRootKitAmount, address to, uint256 deadline) public
        returns (uint256 rootKitUsed, uint256 tokenUsed, uint256 liquidity)
    {
        address pool = uniswapV2Factory.getPair(address(rootKit), address(token));
        require (pool != address(0) && addressStates[pool] == AddressState.AllowedPool, "Pool not approved");
        require (!unrestricted);
        unrestricted = true;

        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        rootKit.transferFrom(msg.sender, address(this), rootKitAmount);
        rootKit.approve(address(uniswapV2Router), rootKitAmount);
        token.safeApprove(address(uniswapV2Router), tokenAmount);
        (rootKitUsed, tokenUsed, liquidity) = uniswapV2Router.addLiquidity(address(rootKit), address(token), rootKitAmount, tokenAmount, minRootKitAmount, minTokenAmount, to, deadline);
        liquiditySupply[pool] = IERC20(pool).totalSupply();
        if (mustUpdate == pool) {
            mustUpdate = address(0);
        }

        if (rootKitUsed < rootKitAmount) {
            rootKit.transfer(msg.sender, rootKitAmount - rootKitUsed);
        }
        tokenBalance = token.balanceOf(address(this)).sub(tokenBalance); // we do it this way in case there's a burn
        if (tokenBalance > 0) {
            token.safeTransfer(msg.sender, tokenBalance);
        }
        
        unrestricted = false;
    }

    function handleTransfer(address, address from, address to, uint256 amount) external override
        returns (uint256 burn, TransferGateTarget[] memory targets)
    {
        {
            address mustUpdateAddress = mustUpdate;
            if (mustUpdateAddress != address(0)) {
                mustUpdate = address(0);
                uint256 newSupply = IERC20(mustUpdateAddress).totalSupply();
                uint256 oldSupply = liquiditySupply[mustUpdateAddress];
                if (newSupply != oldSupply) {
                    liquiditySupply[mustUpdateAddress] = unrestricted ? newSupply : (newSupply > oldSupply ? newSupply : oldSupply);
                }
            }
        }
        {
            AddressState fromState = addressStates[from];
            AddressState toState = addressStates[to];
            if (fromState != AddressState.AllowedPool && toState != AddressState.AllowedPool) {
                if (fromState == AddressState.Unknown) { fromState = detectState(from); }
                if (toState == AddressState.Unknown) { toState = detectState(to); }
                require (unrestricted || (fromState != AddressState.DisallowedPool && toState != AddressState.DisallowedPool), "Pool not approved");
            }
            if (toState == AddressState.AllowedPool) {
                mustUpdate = to;
            }
            if (fromState == AddressState.AllowedPool) {
                if (unrestricted) {
                    liquiditySupply[from] = IERC20(from).totalSupply();
                }
                require (IERC20(from).totalSupply() >= liquiditySupply[from], "Cannot remove liquidity");            
            }
        }
        if (unrestricted || freeParticipant[from] || freeParticipant[to]) {
            return (0, new TransferGateTarget[](0));
        }
        RootKitTransferGateParameters memory params = parameters;
        burn = amount * params.burnRate / 10000;

        if (to == address(taxedPool))
        {
            burn = burn + amount * getDumpTax() / 10000;
        }

        targets = new TransferGateTarget[]((params.devRate > 0 ? 1 : 0) + (params.stakeRate > 0 ? 1 : 0));
        uint256 index = 0;
        if (params.stakeRate > 0) {
            targets[index].destination = params.stake;
            targets[index++].amount = to == address(taxedPool) 
                ? amount * params.stakeRate * sellStakeRateMultiplier / 10000  
                : amount * params.stakeRate / 10000;
        }
        if (params.devRate > 0) {
            targets[index].destination = params.dev;
            targets[index].amount = amount * params.devRate / 10000;
        }
    }

    function setAddressState(address a, AddressState state) public ownerOnly()
    {
        addressStates[a] = state;
    }

    function detectState(address a) public returns (AddressState state) 
    {
        state = AddressState.NotPool;
        if (a.isContract()) {
            try this.throwAddressState(a)
            {
                assert(false);
            }
            catch Error(string memory result) {
                // if (bytes(result).length == 1) {
                //     state = AddressState.NotPool;
                // }
                if (bytes(result).length == 2) {
                    state = AddressState.DisallowedPool;
                }
            }
            catch {
            }
        }
        addressStates[a] = state;
        return state;
    }
    
    // Not intended for external consumption
    // Always throws
    // We want to call functions to probe for things, but don't want to open ourselves up to
    // possible state-changes
    // So we return a value by reverting with a message
    function throwAddressState(address a) external view
    {
        try IUniswapV2Pair(a).factory() returns (address factory)
        {
            // don't care if it's some crappy alt-amm
            if (factory == address(uniswapV2Factory)) {
                // these checks for token0/token1 are just for additional
                // certainty that we're interacting with a uniswap pair
                try IUniswapV2Pair(a).token0() returns (address token0)
                {
                    if (token0 == address(rootKit)) {
                        revert("22");
                    }
                    try IUniswapV2Pair(a).token1() returns (address token1)
                    {
                        if (token1 == address(rootKit)) {
                            revert("22");
                        }                        
                    }
                    catch { 
                    }                    
                }
                catch { 
                }
            }
        }
        catch {             
        }
        revert("1");
    }
}