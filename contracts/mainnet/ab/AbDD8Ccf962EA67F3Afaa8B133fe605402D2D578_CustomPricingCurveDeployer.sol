// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../ModuleBase.sol";
import "../../governance/IGovernance.sol";
import "../../initializable/CustomPricingCurve.sol";

contract CustomPricingCurveDeployer is IModule, ModuleBase
{
    string public constant override name = type(CustomPricingCurveDeployer).name;

    // bytes32 public constant CURVE_TEMPLATE_CUSTOM_PRICING = bytes32(uint256(keccak256("CURVE_TEMPLATE_CUSTOM_PRICING")) - 1);
    bytes32 public constant CURVE_TEMPLATE_CUSTOM_PRICING = 0x015ac18e18061bd4ed0d69c024a10bd206e68a8c90479081e4e55738eb8d069d;

    event NewBondingCurve(ShardedWallet indexed wallet_, address indexed curve_);

    modifier isAllowed(ShardedWallet wallet) {
        require(wallet.owner() == address(0));
        _;
    }

    constructor(address walletTemplate) ModuleBase(walletTemplate) {}

    function createCurve(
        ShardedWallet wallet,
        uint256 fractionsToProvide_,
        address recipient_, // owner of timelocked liquidity
        address sourceOfFractions_, // wallet to transfer fractions from
        uint256 k_,
        uint256 x_,
        uint256 liquidityTimelock_
    ) public payable
    isAllowed(wallet)
    onlyShardedWallet(wallet) 
    returns (address curve) {
        // only sharded wallet OR one owning 100% fraction supply can create custom pricing curve
        require(msg.sender == address(wallet) || wallet.balanceOf(msg.sender) == wallet.totalSupply());
        IGovernance governance = wallet.governance();
        address template = address(uint160(governance.getConfig(address(wallet), CURVE_TEMPLATE_CUSTOM_PRICING)));
        if (template != address(0)) {
            curve = Clones.cloneDeterministic(template, bytes32(uint256(uint160(address(wallet)))));
            {
                CustomPricingCurve(curve).initialize{value: msg.value}(
                    fractionsToProvide_,
                    address(wallet),
                    recipient_,
                    sourceOfFractions_,
                    k_,
                    x_,
                    liquidityTimelock_
                );
            }
            
            emit NewBondingCurve(wallet, curve);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../wallet/ShardedWallet.sol";
import "./IModule.sol";

abstract contract ModuleBase is IModule
{
    address immutable public walletTemplate;

    constructor(address walletTemplate_)
    {
        walletTemplate = walletTemplate_;
    }

    modifier onlyShardedWallet(ShardedWallet wallet)
    {
        require(isClone(walletTemplate, address(wallet)));
        _;
    }

    modifier onlyAuthorized(ShardedWallet wallet, address user)
    {
        require(wallet.governance().isAuthorized(address(wallet), user));
        _;
    }

    modifier onlyOwner(ShardedWallet wallet, address user)
    {
        require(wallet.owner() == user);
        _;
    }

    function isClone(address target, address query)
    internal view returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernance
{
    function isModule(address, address) external view returns (bool);
    function isAuthorized(address, address) external view returns (bool);
    function getModule(address, bytes4) external view returns (address);
    function getConfig(address, bytes32) external view returns (uint256);
    function getNiftexWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC20.sol";
import "../wallet/ShardedWallet.sol";
import "../governance/IGovernance.sol";
import "../interface/IERC1363Receiver.sol";
import "../interface/IERC1363Spender.sol";

contract LiquidityToken is ERC20 {
    address public controler;

    modifier onlyControler() {
        require(msg.sender == controler);
        _;
    }

    constructor() {
        controler = address(0xdead);
    }

    function initialize(address controler_, string memory name_, string memory symbol_) public {
        require(controler == address(0));
        controler = controler_;
        _initialize(name_, symbol_);
    }

    function controllerTransfer(address sender, address recipient, uint256 amount) public onlyControler {
        _transfer(sender, recipient, amount);
    }

    function controllerMint(address account, uint256 amount) public onlyControler {
        _mint(account, amount);
    }

    function controllerBurn(address account, uint256 amount) public onlyControler {
        _burn(account, amount);
    }
}

// used by CustomPricingCurveDeployer.sol
contract CustomPricingCurve is IERC1363Spender {
    struct CurveCoordinates {
        uint256 x;
        uint256 k;
    }

    struct Asset {
        uint256 underlyingSupply;
        uint256 feeToNiftex;
        uint256 feeToArtist;
    }

    LiquidityToken immutable internal _template;

    // bytes32 public constant PCT_FEE_SUPPLIERS = bytes32(uint256(keccak256("PCT_FEE_SUPPLIERS")) - 1);
    bytes32 public constant PCT_FEE_SUPPLIERS  = 0xe4f5729eb40e38b5a39dfb36d76ead9f9bc286f06852595980c5078f1af7e8c9;
    // bytes32 public constant PCT_FEE_ARTIST    = bytes32(uint256(keccak256("PCT_FEE_ARTIST")) - 1);
    bytes32 public constant PCT_FEE_ARTIST     = 0xdd0618e2e2a17ff193a933618181c8f8909dc169e9707cce1921893a88739ca0;
    // bytes32 public constant PCT_FEE_NIFTEX    = bytes32(uint256(keccak256("PCT_FEE_NIFTEX")) - 1);
    bytes32 public constant PCT_FEE_NIFTEX     = 0xcfb1dd89e6f4506eca597e7558fbcfe22dbc7e0b9f2b3956e121d0e344d6f7aa;

    LiquidityToken   public   etherLPToken;
    LiquidityToken   public   shardLPToken;
    CurveCoordinates public   curve;
    Asset            internal _etherLPExtra;
    Asset            internal _shardLPExtra;
    address          public   wallet;
    address          public   recipient;
    uint256          public   deadline;

    event Initialized(address wallet);
    event ShardsBought(address indexed account, uint256 amount, uint256 cost);
    event ShardsSold(address indexed account, uint256 amount, uint256 payout);
    event ShardsSupplied(address indexed provider, uint256 amount);
    event EtherSupplied(address indexed provider, uint256 amount);
    event ShardsWithdrawn(address indexed provider, uint256 payout, uint256 shards, uint256 amountLPToken);
    event EtherWithdrawn(address indexed provider, uint256 value, uint256 payout, uint256 amountLPToken);
    event KUpdated(uint256 newK, uint256 newX);

    constructor() {
        _template = new LiquidityToken();
        wallet = address(0xdead);
    }

    function initialize(
        uint256 supply,
        address wallet_,
        address recipient_,
        address sourceOfFractions_,
        uint256 k_,
        uint256 x_,
        uint256 liquidityTimelock_
    )
    public payable
    {
        require(wallet == address(0));
        string memory name_   = ShardedWallet(payable(wallet_)).name();
        string memory symbol_ = ShardedWallet(payable(wallet_)).symbol();

        etherLPToken = LiquidityToken(Clones.clone(address(_template)));
        shardLPToken = LiquidityToken(Clones.clone(address(_template)));
        etherLPToken.initialize(address(this), string(abi.encodePacked(name_, "-EtherLP")), string(abi.encodePacked(symbol_, "-ELP")));
        shardLPToken.initialize(address(this), string(abi.encodePacked(name_, "-ShardLP")), string(abi.encodePacked(symbol_, "-SLP")));

        wallet    = wallet_;
        recipient = recipient_;
        deadline  = block.timestamp + liquidityTimelock_;
        emit Initialized(wallet_);

        // transfer assets
        if (supply > 0) {
            require(ShardedWallet(payable(wallet_)).transferFrom(sourceOfFractions_, address(this), supply));
        }

        {
            // setup curve
            curve.x = x_;
            curve.k = k_;
        }

        address mintTo = liquidityTimelock_ == 0 ? recipient_ : address(this);
        // mint liquidity
        etherLPToken.controllerMint(mintTo, msg.value);
        shardLPToken.controllerMint(mintTo, supply);
        _etherLPExtra.underlyingSupply = msg.value;
        _shardLPExtra.underlyingSupply = supply;
        emit EtherSupplied(mintTo, msg.value);
        emit ShardsSupplied(mintTo, supply);
    }

    function buyShards(uint256 amount, uint256 maxCost) public payable {
        uint256 cost = _buyShards(msg.sender, amount, maxCost);

        require(cost <= msg.value);
        if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

    function sellShards(uint256 amount, uint256 minPayout) public {
        require(ShardedWallet(payable(wallet)).transferFrom(msg.sender, address(this), amount));
        _sellShards(msg.sender, amount, minPayout);
    }

    function supplyEther() public payable {
        _supplyEther(msg.sender, msg.value);
    }

    function supplyShards(uint256 amount) public {
        require(ShardedWallet(payable(wallet)).transferFrom(msg.sender, address(this), amount));
        _supplyShards(msg.sender, amount);
    }

    function onApprovalReceived(address owner, uint256 amount, bytes calldata data) public override returns (bytes4) {
        require(msg.sender == wallet);
        require(ShardedWallet(payable(wallet)).transferFrom(owner, address(this), amount));

        bytes4 selector = abi.decode(data, (bytes4));
        if (selector == this.sellShards.selector) {
            (,uint256 minPayout) = abi.decode(data, (bytes4, uint256));
            _sellShards(owner, amount, minPayout);
        } else if (selector == this.supplyShards.selector) {
            _supplyShards(owner, amount);
        } else {
            revert("invalid selector in onApprovalReceived data");
        }

        return this.onApprovalReceived.selector;
    }

    function _buyShards(address buyer, uint256 amount, uint256 maxCost) internal returns (uint256) {
        IGovernance governance = ShardedWallet(payable(wallet)).governance();
        address     owner      = ShardedWallet(payable(wallet)).owner();
        address     artist     = ShardedWallet(payable(wallet)).artistWallet();

        // pause if someone else reclaimed the ownership of shardedWallet
        require(owner == address(0) || governance.isModule(wallet, owner));

        // compute fees
        uint256[3] memory fees;
        fees[0] =                            governance.getConfig(wallet, PCT_FEE_SUPPLIERS);
        fees[1] =                            governance.getConfig(wallet, PCT_FEE_NIFTEX);
        fees[2] = artist == address(0) ? 0 : governance.getConfig(wallet, PCT_FEE_ARTIST);

        uint256 amountWithFee = amount * (10**18 + fees[0] + fees[1] + fees[2]) / 10**18;

        // check curve update
        uint256 newX = curve.x - amountWithFee;
        uint256 newY = curve.k / newX;
        require(newX > 0 && newY > 0);

        // check cost
        uint256 cost = newY - curve.k / curve.x;
        require(cost <= maxCost);

        // consistency check
        require(ShardedWallet(payable(wallet)).balanceOf(address(this)) - _shardLPExtra.feeToNiftex - _shardLPExtra.feeToArtist >= amount * (10**18 + fees[1] + fees[2]) / 10**18);

        // update curve
        curve.x = curve.x - amount * (10**18 + fees[1] + fees[2]) / 10**18;

        // update LP supply
        _shardLPExtra.underlyingSupply += amount * fees[0] / 10**18;
        _shardLPExtra.feeToNiftex      += amount * fees[1] / 10**18;
        _shardLPExtra.feeToArtist      += amount * fees[2] / 10**18;

        // transfer
        ShardedWallet(payable(wallet)).transfer(buyer, amount);

        emit ShardsBought(buyer, amount, cost);
        return cost;
    }

    function _sellShards(address seller, uint256 amount, uint256 minPayout) internal returns (uint256) {
        IGovernance governance = ShardedWallet(payable(wallet)).governance();
        address     owner      = ShardedWallet(payable(wallet)).owner();
        address     artist     = ShardedWallet(payable(wallet)).artistWallet();

        // pause if someone else reclaimed the ownership of shardedWallet
        require(owner == address(0) || governance.isModule(wallet, owner));

        // compute fees
        uint256[3] memory fees;
        fees[0] =                            governance.getConfig(wallet, PCT_FEE_SUPPLIERS);
        fees[1] =                            governance.getConfig(wallet, PCT_FEE_NIFTEX);
        fees[2] = artist == address(0) ? 0 : governance.getConfig(wallet, PCT_FEE_ARTIST);

        uint256 newX = curve.x + amount;
        uint256 newY = curve.k / newX;
        require(newX > 0 && newY > 0);

        // check payout
        uint256 payout = curve.k / curve.x - newY;
        require(payout <= address(this).balance - _etherLPExtra.feeToNiftex - _etherLPExtra.feeToArtist);
        uint256 value = payout * (10**18 - fees[0] - fees[1] - fees[2]) / 10**18;
        require(value >= minPayout);

        // update curve
        curve.x = newX;

        // update LP supply
        _etherLPExtra.underlyingSupply += payout * fees[0] / 10**18;
        _etherLPExtra.feeToNiftex      += payout * fees[1] / 10**18;
        _etherLPExtra.feeToArtist      += payout * fees[2] / 10**18;

        // transfer
        Address.sendValue(payable(seller), value);

        emit ShardsSold(seller, amount, value);
        return value;
    }

    function _supplyEther(address supplier, uint256 amount) internal {
        etherLPToken.controllerMint(supplier, calcNewEthLPTokensToIssue(amount));
        _etherLPExtra.underlyingSupply += amount;

        emit EtherSupplied(supplier, amount);
    }


    function _supplyShards(address supplier, uint256 amount) internal {
        shardLPToken.controllerMint(supplier, calcNewShardLPTokensToIssue(amount));
        _shardLPExtra.underlyingSupply += amount;

        emit ShardsSupplied(supplier, amount);
    }

    function calcNewShardLPTokensToIssue(uint256 amount) public view returns (uint256) {
        uint256 pool = _shardLPExtra.underlyingSupply;
        if (pool == 0) { return amount; }
        uint256 proportion = amount * 10**18 / (pool + amount);
        return proportion * shardLPToken.totalSupply() / (10**18 - proportion);
    }

    function calcNewEthLPTokensToIssue(uint256 amount) public view returns (uint256) {
        uint256 pool = _etherLPExtra.underlyingSupply;
        if (pool == 0) { return amount; }
        uint256 proportion = amount * 10**18 / (pool + amount);
        return proportion * etherLPToken.totalSupply() / (10**18 - proportion);
    }

    function calcShardsForEthSuppliers() public view returns (uint256) {
        uint256 balance = ShardedWallet(payable(wallet)).balanceOf(address(this)) - _shardLPExtra.feeToNiftex - _shardLPExtra.feeToArtist;
        return balance < _shardLPExtra.underlyingSupply ? 0 : balance - _shardLPExtra.underlyingSupply;
    }

    function calcEthForShardSuppliers() public view returns (uint256) {
        uint256 balance = address(this).balance - _etherLPExtra.feeToNiftex - _etherLPExtra.feeToArtist;
        return balance < _etherLPExtra.underlyingSupply ? 0 : balance - _etherLPExtra.underlyingSupply;
    }

    function withdrawSuppliedEther(uint256 amount) external returns (uint256, uint256) {
        require(amount > 0);

        uint256 etherLPTokenSupply = etherLPToken.totalSupply();

        uint256 balance = address(this).balance - _etherLPExtra.feeToNiftex - _etherLPExtra.feeToArtist;

        uint256 value = (balance <= _etherLPExtra.underlyingSupply)
        ? balance * amount / etherLPTokenSupply
        : _etherLPExtra.underlyingSupply * amount / etherLPTokenSupply;

        uint256 payout = calcShardsForEthSuppliers() * amount / etherLPTokenSupply;

        // update balances
        _etherLPExtra.underlyingSupply *= etherLPTokenSupply - amount;
        _etherLPExtra.underlyingSupply /= etherLPTokenSupply;
        etherLPToken.controllerBurn(msg.sender, amount);

        // transfer
        Address.sendValue(payable(msg.sender), value);
        if (payout > 0) {
            ShardedWallet(payable(wallet)).transfer(msg.sender, payout);
        }

        emit EtherWithdrawn(msg.sender, value, payout, amount);

        return (value, payout);
    }

    function withdrawSuppliedShards(uint256 amount) external returns (uint256, uint256) {
        require(amount > 0);

        uint256 shardLPTokenSupply = shardLPToken.totalSupply();

        uint256 balance = ShardedWallet(payable(wallet)).balanceOf(address(this)) - _shardLPExtra.feeToNiftex - _shardLPExtra.feeToArtist;

        uint256 shards = (balance <= _shardLPExtra.underlyingSupply)
        ? balance * amount / shardLPTokenSupply
        : _shardLPExtra.underlyingSupply * amount / shardLPTokenSupply;

        uint256 payout = calcEthForShardSuppliers() * amount / shardLPTokenSupply;

        // update balances
        _shardLPExtra.underlyingSupply *= shardLPTokenSupply - amount;
        _shardLPExtra.underlyingSupply /= shardLPTokenSupply;
        shardLPToken.controllerBurn(msg.sender, amount);

        // transfer
        ShardedWallet(payable(wallet)).transfer(msg.sender, shards);
        if (payout > 0) {
            Address.sendValue(payable(msg.sender), payout);
        }

        emit ShardsWithdrawn(msg.sender, payout, shards, amount);

        return (payout, shards);
    }

    function withdrawNiftexOrArtistFees(address to) public {
        uint256 etherFees = 0;
        uint256 shardFees = 0;

        if (msg.sender == ShardedWallet(payable(wallet)).artistWallet()) {
            etherFees += _etherLPExtra.feeToArtist;
            shardFees += _shardLPExtra.feeToArtist;
            delete _etherLPExtra.feeToArtist;
            delete _shardLPExtra.feeToArtist;
        }

        if (msg.sender == ShardedWallet(payable(wallet)).governance().getNiftexWallet()) {
            etherFees += _etherLPExtra.feeToNiftex;
            shardFees += _shardLPExtra.feeToNiftex;
            delete _etherLPExtra.feeToNiftex;
            delete _shardLPExtra.feeToNiftex;
        }

        Address.sendValue(payable(to), etherFees);
        ShardedWallet(payable(wallet)).transfer(to, shardFees);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function updateK(uint256 newK_) public {
        require(msg.sender == wallet);
        curve.x = curve.x * sqrt(newK_ * 10**12 / curve.k) / 10**6;
        curve.k = newK_;
        assert(curve.k > 0);
        assert(curve.x > 0);
        emit KUpdated(curve.k, curve.x);
    }

    function updateKAndX(uint256 newK_, uint256 newX_) public {
        ShardedWallet sw = ShardedWallet(payable(wallet));
        uint256 effectiveShardBal = sw.balanceOf(msg.sender) + shardLPToken.balanceOf(msg.sender) * sw.balanceOf(address(this)) / shardLPToken.totalSupply();
        require(effectiveShardBal == sw.totalSupply());
        curve.x = newX_;
        curve.k = newK_;
        assert(curve.k > 0);
        assert(curve.x > 0);
        emit KUpdated(curve.k, curve.x);
    }

    function transferTimelockLiquidity() public {
        require(deadline < block.timestamp);
        etherLPToken.controllerTransfer(address(this), recipient, getEthLPTokens(address(this)));
        shardLPToken.controllerTransfer(address(this), recipient, getShardLPTokens(address(this)));
    }

    function getEthLPTokens(address owner) public view returns (uint256) {
        return etherLPToken.balanceOf(owner);
    }

    function getShardLPTokens(address owner) public view returns (uint256) {
        return shardLPToken.balanceOf(owner);
    }

    function transferEthLPTokens(address to, uint256 amount) public {
        etherLPToken.controllerTransfer(msg.sender, to, amount);
    }

    function transferShardLPTokens(address to, uint256 amount) public {
        shardLPToken.controllerTransfer(msg.sender, to, amount);
    }

    function getCurrentPrice() external view returns (uint256) {
        return curve.k * 10**18 / curve.x / curve.x;
    }

    function getEthSuppliers() external view returns (uint256, uint256, uint256, uint256) {
        return (_etherLPExtra.underlyingSupply, etherLPToken.totalSupply(), _etherLPExtra.feeToNiftex, _etherLPExtra.feeToArtist);
    }

    function getShardSuppliers() external view returns (uint256, uint256, uint256, uint256) {
        return (_shardLPExtra.underlyingSupply, shardLPToken.totalSupply(), _shardLPExtra.feeToNiftex, _shardLPExtra.feeToArtist);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../governance/IGovernance.sol";
import "../initializable/Ownable.sol";
import "../initializable/ERC20.sol";
import "../initializable/ERC1363.sol";

contract ShardedWallet is Ownable, ERC20, ERC1363Approve
{
    // bytes32 public constant ALLOW_GOVERNANCE_UPGRADE = bytes32(uint256(keccak256("ALLOW_GOVERNANCE_UPGRADE")) - 1);
    bytes32 public constant ALLOW_GOVERNANCE_UPGRADE = 0xedde61aea0459bc05d70dd3441790ccfb6c17980a380201b00eca6f9ef50452a;

    IGovernance public governance;
    address public artistWallet;

    event Received(address indexed sender, uint256 value, bytes data);
    event Execute(address indexed to, uint256 value, bytes data);
    event ModuleExecute(address indexed module, address indexed to, uint256 value, bytes data);
    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event ArtistUpdated(address indexed oldArtist, address indexed newArtist);

    modifier onlyModule()
    {
        require(_isModule(msg.sender), "Access restricted to modules");
        _;
    }

    /*************************************************************************
     *                       Contructor and fallbacks                        *
     *************************************************************************/
    constructor()
    {
        governance = IGovernance(address(0xdead));
    }

    receive()
    external payable
    {
        emit Received(msg.sender, msg.value, bytes(""));
    }

    fallback()
    external payable
    {
        address module = governance.getModule(address(this), msg.sig);
        if (module != address(0) && _isModule(module))
        {
            (bool success, /*bytes memory returndata*/) = module.staticcall(msg.data);
            // returning bytes in fallback is not supported until solidity 0.8.0
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                switch success
                case 0 { revert(0, returndatasize()) }
                default { return (0, returndatasize()) }
            }
        }
        else
        {
            emit Received(msg.sender, msg.value, msg.data);
        }
    }

    /*************************************************************************
     *                            Initialization                             *
     *************************************************************************/
    function initialize(
        address         governance_,
        address         minter_,
        string calldata name_,
        string calldata symbol_,
        address         artistWallet_
    )
    external
    {
        require(address(governance) == address(0));

        governance = IGovernance(governance_);
        Ownable._setOwner(minter_);
        ERC20._initialize(name_, symbol_);
        artistWallet = artistWallet_;

        emit GovernanceUpdated(address(0), governance_);
    }

    function _isModule(address module)
    internal view returns (bool)
    {
        return governance.isModule(address(this), module);
    }

    /*************************************************************************
     *                          Owner interactions                           *
     *************************************************************************/
    function execute(address to, uint256 value, bytes calldata data)
    external onlyOwner()
    {
        Address.functionCallWithValue(to, data, value);
        emit Execute(to, value, data);
    }

    function retrieve(address newOwner)
    external
    {
        ERC20._burn(msg.sender, Math.max(ERC20.totalSupply(), 1));
        Ownable._setOwner(newOwner);
    }

    /*************************************************************************
     *                          Module interactions                          *
     *************************************************************************/
    function moduleExecute(address to, uint256 value, bytes calldata data)
    external onlyModule()
    {
        if (Address.isContract(to))
        {
            Address.functionCallWithValue(to, data, value);
        }
        else
        {
            Address.sendValue(payable(to), value);
        }
        emit ModuleExecute(msg.sender, to, value, data);
    }

    function moduleMint(address to, uint256 value)
    external onlyModule()
    {
        ERC20._mint(to, value);
    }

    function moduleBurn(address from, uint256 value)
    external onlyModule()
    {
        ERC20._burn(from, value);
    }

    function moduleTransfer(address from, address to, uint256 value)
    external onlyModule()
    {
        ERC20._transfer(from, to, value);
    }

    function moduleTransferOwnership(address to)
    external onlyModule()
    {
        Ownable._setOwner(to);
    }

    function updateGovernance(address newGovernance)
    external onlyModule()
    {
        emit GovernanceUpdated(address(governance), newGovernance);

        require(governance.getConfig(address(this), ALLOW_GOVERNANCE_UPGRADE) > 0);
        require(Address.isContract(newGovernance));
        governance = IGovernance(newGovernance);
    }

    function updateArtistWallet(address newArtistWallet)
    external onlyModule()
    {
        emit ArtistUpdated(artistWallet, newArtistWallet);

        artistWallet = newArtistWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IModule
{
    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _setOwner(address owner_) internal {
        emit OwnershipTransferred(_owner, owner_);
        _owner = owner_;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    function _initialize(string memory name_, string memory symbol_) internal virtual {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../interface/IERC1363.sol";
import "../interface/IERC1363Receiver.sol";
import "../interface/IERC1363Spender.sol";

abstract contract ERC1363Transfer is ERC20, IERC1363Transfer {
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, bytes(""));
    }

    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transfer(to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), _msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 value) public override returns (bool) {
        return transferFromAndCall(from, to, value, bytes(""));
    }

    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transferFrom(from, to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), from, value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363Approve is ERC20, IERC1363Approve {
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, bytes(""));
    }

    function approveAndCall(address spender, uint256 value, bytes memory data) public override returns (bool) {
        require(approve(spender, value));
        try IERC1363Spender(spender).onApprovalReceived(_msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Spender(spender).onApprovalReceived.selector, "ERC1363: onApprovalReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onApprovalReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363 is ERC1363Transfer, ERC1363Approve {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1363Transfer {
    /*
    * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
    * 0x4bbee2df ===
    *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
    *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
    *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
    *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
    */

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);


    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);
}

interface IERC1363Approve {
  /*
   * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
   * 0xfb9ec8ce ===
   *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
   *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
   */
  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   */
  function approveAndCall(address spender, uint256 value) external returns (bool);

  /**
   * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
   * and then call `onApprovalReceived` on spender.
   * @param spender address The address which will spend the funds
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format, sent in call to `spender`
   */
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

interface IERC1363 is IERC1363Transfer, IERC1363Approve {
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1363Receiver interface
 * @dev Interface for any contract that wants to support `transferAndCall` or `transferFromAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Receiver {
  /*
   * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
   * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
   */

  /**
   * @notice Handle the receipt of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
   * @param from address The address which are token transferred from
   * @param value uint256 The amount of tokens transferred
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
   *  unless throwing
   */
  function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1363Spender interface
 * @dev Interface for any contract that wants to support `approveAndCall`
 *  from ERC1363 token contracts.
 */
interface IERC1363Spender {
  /*
   * Note: the ERC-165 identifier for this interface is 0.8.04a2d0.
   * 0.8.04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
   */

  /**
   * @notice Handle the approval of ERC1363 tokens
   * @dev Any ERC1363 smart contract calls this function on the recipient
   * after an `approve`. This function MAY throw to revert and reject the
   * approval. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the token contract address is always the message sender.
   * @param owner address The address which called `approveAndCall` function
   * @param value uint256 The amount of tokens to be spent
   * @param data bytes Additional data with no specified format
   * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
   *  unless throwing
   */
  function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}

