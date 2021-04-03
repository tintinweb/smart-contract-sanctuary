// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./TurboHatchery.sol";
import "./TurboShareTokenFactory.sol";
import "../libraries/Ownable.sol";
import "../augur-para/FeePot.sol";

contract HatcheryRegistry is Ownable {
    using SafeMathUint256 for uint256;

    IERC20DynamicSymbol public reputationToken;
    address[] public hatcheries;
    // collateral => hatchery
    mapping(address => TurboHatchery) public getHatchery;

    event NewHatchery(address id, address indexed collateral, address shareTokenFactory, address feePot);

    constructor(address _owner, IERC20DynamicSymbol _reputationToken) {
        owner = _owner;
        reputationToken = _reputationToken;
    }

    function createHatchery(IERC20 _collateral) public onlyOwner returns (TurboHatchery) {
        require(getHatchery[address(_collateral)] == TurboHatchery(0), "Only one hatchery per collateral");
        TurboShareTokenFactory _shareTokenFactory = new TurboShareTokenFactory();
        FeePot _feePot = new FeePot(_collateral, reputationToken);
        TurboHatchery _hatchery = new TurboHatchery(ITurboShareTokenFactory(address(_shareTokenFactory)), _feePot);
        _shareTokenFactory.initialize(_hatchery);
        hatcheries.push(address(_hatchery));
        getHatchery[address(_collateral)] = _hatchery;
        emit NewHatchery(address(_hatchery), address(_collateral), address(_shareTokenFactory), address(_feePot));
        return _hatchery;
    }

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ITurboShareToken.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20.sol";
import "../augur-para/IFeePot.sol";
import "./ITurboShareTokenFactory.sol";
import "./IArbiter.sol";
import "./ITurboHatchery.sol";

contract TurboHatchery is ITurboHatchery {
    using SafeMathUint256 for uint256;

    uint256 private constant MIN_OUTCOMES = 2; // Does not Include Invalid
    uint256 private constant MAX_OUTCOMES = 7; // Does not Include Invalid
    uint256 private constant MAX_FEE = 2 * 10**16; // 2%
    address private constant NULL_ADDRESS = address(0);
    uint256 private constant MAX_UINT = 2**256 - 1;

    Turbo[] internal _turbos;
    ITurboShareTokenFactory internal _tokenFactory;
    IFeePot internal _feePot;
    IERC20 internal _collateral;

    constructor(ITurboShareTokenFactory tokenFactory_, IFeePot feePot_) {
        _tokenFactory = tokenFactory_;
        _feePot = feePot_;
        _collateral = _feePot.collateral();
        _collateral.approve(address(_feePot), MAX_UINT);
    }

    function turbos(uint256 _turboId) external view override returns (HasTurboStruct.Turbo memory) {
        return _turbos[_turboId];
    }

    function tokenFactory() public view virtual override returns (ITurboShareTokenFactory) {
        return _tokenFactory;
    }

    function feePot() public view virtual override returns (IFeePot) {
        return _feePot;
    }

    function collateral() public view virtual override returns (IERC20) {
        return _collateral;
    }

    function getTurboLength() external view override returns (uint256) {
        return _turbos.length;
    }

    function createTurbo(
        uint256 _index,
        uint256 _creatorFee,
        string[] memory _outcomeSymbols,
        bytes32[] memory _outcomeNames,
        uint256 _numTicks,
        IArbiter _arbiter,
        bytes memory _arbiterConfiguration
    ) public override returns (uint256) {
        require(_numTicks.isMultipleOf(2), "TurboHatchery.createTurbo: numTicks must be multiple of 2");
        require(_numTicks >= _outcomeSymbols.length, "TurboHatchery.createTurbo: numTicks lower than numOutcomes");
        require(
            MIN_OUTCOMES <= _outcomeSymbols.length && _outcomeSymbols.length <= MAX_OUTCOMES,
            "TurboHatchery.createTurbo: Number of outcomes is not acceptable"
        );
        require(
            _outcomeSymbols.length == _outcomeNames.length,
            "TurboHatchery.createTurbo: outcome names and outcome symbols differ in length"
        );
        require(_creatorFee <= MAX_FEE, "TurboHatchery.createTurbo: market creator fee too high");
        uint256 _id = _turbos.length;
        {
            _turbos.push(
                Turbo(
                    msg.sender,
                    _creatorFee,
                    _numTicks,
                    _arbiter,
                    _tokenFactory.createShareTokens(_outcomeNames, _outcomeSymbols),
                    0
                )
            );
        }
        _arbiter.onTurboCreated(_id, _outcomeSymbols, _outcomeNames, _numTicks, _arbiterConfiguration);
        emit TurboCreated(
            _id,
            _creatorFee,
            _outcomeSymbols,
            _outcomeNames,
            _numTicks,
            _arbiter,
            _arbiterConfiguration,
            _index
        );
        return _id;
    }

    function getShareTokens(uint256 _id) external view override returns (ITurboShareToken[] memory) {
        return _turbos[_id].shareTokens;
    }

    function mintCompleteSets(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) public override returns (bool) {
        uint256 _numTicks = _turbos[_id].numTicks;
        uint256 _cost = _amount.mul(_numTicks);
        _collateral.transferFrom(msg.sender, address(this), _cost);
        for (uint256 _i = 0; _i < _turbos[_id].shareTokens.length; _i++) {
            _turbos[_id].shareTokens[_i].trustedMint(_receiver, _amount);
        }
        emit CompleteSetsMinted(_id, _amount, _receiver);
        return true;
    }

    function burnCompleteSets(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) public override returns (bool) {
        for (uint256 _i = 0; _i < _turbos[_id].shareTokens.length; _i++) {
            _turbos[_id].shareTokens[_i].trustedBurn(msg.sender, _amount);
        }
        uint256 _numTicks = _turbos[_id].numTicks;
        payout(_id, _receiver, _amount.mul(_numTicks), false, false);
        emit CompleteSetsBurned(_id, _amount, msg.sender);
        return true;
    }

    function claimWinnings(uint256 _id) public override returns (bool) {
        // We expect this to revert or return an empty array if the turbo is not resolved
        uint256[] memory _winningPayout = _turbos[_id].arbiter.getTurboResolution(_id);
        require(_winningPayout.length > 0, "market not resolved");
        uint256 _winningBalance = 0;
        for (uint256 _i = 0; _i < _turbos[_id].shareTokens.length; _i++) {
            _winningBalance = _winningBalance.add(
                _turbos[_id].shareTokens[_i].trustedBurnAll(msg.sender) * _winningPayout[_i]
            );
        }
        payout(_id, msg.sender, _winningBalance, true, _winningPayout[0] != 0);
        emit Claim(_id);
        return true;
    }

    function payout(
        uint256 _id,
        address _payee,
        uint256 _payout,
        bool _finalized,
        bool _invalid
    ) private {
        uint256 _creatorFee = _turbos[_id].creatorFee.mul(_payout) / 10**18;

        if (_finalized) {
            if (_invalid) {
                _feePot.depositFees(_creatorFee + _turbos[_id].creatorFees);
                _turbos[_id].creatorFees = 0;
            } else {
                _collateral.transfer(_turbos[_id].creator, _creatorFee);
            }
        } else {
            _turbos[_id].creatorFees = _turbos[_id].creatorFees.add(_creatorFee);
        }

        _collateral.transfer(_payee, _payout.sub(_creatorFee));
    }

    function withdrawCreatorFees(uint256 _id) external override returns (bool) {
        // We expect this to revert if the turbo is not resolved
        uint256[] memory _winningPayout = _turbos[_id].arbiter.getTurboResolution(_id);
        require(_winningPayout.length > 0, "market not resolved");
        require(_winningPayout[0] == 0, "Can only withdraw creator fees from a valid market");

        _collateral.transfer(_turbos[_id].creator, _turbos[_id].creatorFees);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/Initializable.sol";
import "./ITurboShareToken.sol";
import "./TurboShareToken.sol";
import "./ITurboHatchery.sol";

contract TurboShareTokenFactory is Initializable {
    string public constant INVALID_SYMBOL = "INVALID";
    bytes32 public constant INVALID_NAME = "INVALID SHARE";

    ITurboHatchery public hatchery;

    function initialize(ITurboHatchery _hatchery) public beforeInitialized returns (bool) {
        endInitialization();
        hatchery = _hatchery;
        return true;
    }

    function createShareTokens(bytes32[] calldata _names, string[] calldata _symbols)
        external
        returns (ITurboShareToken[] memory)
    {
        require(msg.sender == address(hatchery), "Only hatchery may create new share tokens");
        uint256 _numOutcomes = _names.length + 1;
        ITurboShareToken[] memory _tokens = new ITurboShareToken[](_numOutcomes);
        _tokens[0] = new TurboShareToken(INVALID_SYMBOL, INVALID_NAME, hatchery);
        for (uint256 _i = 1; _i < _numOutcomes; _i++) {
            _tokens[_i] = new TurboShareToken(_symbols[_i - 1], _names[_i - 1], hatchery);
        }
        return _tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IOwnable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable is IOwnable {
    address internal owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view override returns (address) {
        return owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public override onlyOwner returns (bool) {
        require(_newOwner != address(0));
        onTransferOwnership(owner, _newOwner);
        owner = _newOwner;
        return true;
    }

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onTransferOwnership(address, address) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../libraries/SafeMathUint256.sol";
import "../libraries/VariableSupplyToken.sol";
import "../libraries/IERC20.sol";
import "./IFeePot.sol";
import "../libraries/IERC20DynamicSymbol.sol";

contract FeePot is VariableSupplyToken, IFeePot {
    using SafeMathUint256 for uint256;

    uint256 internal constant magnitude = 2**128;

    IERC20 public override collateral;
    IERC20DynamicSymbol public override reputationToken;

    uint256 public magnifiedFeesPerShare;

    mapping(address => uint256) public magnifiedFeesCorrections;
    mapping(address => uint256) public storedFees;

    uint256 public feeReserve;

    constructor(IERC20 _collateral, IERC20DynamicSymbol _reputationToken) {
        collateral = _collateral;
        reputationToken = _reputationToken;

        require(_collateral != IERC20(0));
    }

    function symbol() public view returns (string memory) {
        return string(abi.encodePacked("S_", reputationToken.symbol()));
    }

    function depositFees(uint256 _amount) public override returns (bool) {
        collateral.transferFrom(msg.sender, address(this), _amount);
        uint256 _totalSupply = _totalSupply; // after collateral.transferFrom to prevent reentrancy causing stale totalSupply
        if (_totalSupply == 0) {
            feeReserve = feeReserve.add(_amount);
            return true;
        }
        if (feeReserve > 0) {
            _amount = _amount.add(feeReserve);
            feeReserve = 0;
        }
        magnifiedFeesPerShare = magnifiedFeesPerShare.add((_amount).mul(magnitude) / _totalSupply);
        return true;
    }

    function withdrawableFeesOf(address _owner) public view override returns (uint256) {
        return earnedFeesOf(_owner).add(storedFees[_owner]);
    }

    function earnedFeesOf(address _owner) public view returns (uint256) {
        uint256 _ownerBalance = balanceOf(_owner);
        uint256 _magnifiedFees = magnifiedFeesPerShare.mul(_ownerBalance);
        return _magnifiedFees.sub(magnifiedFeesCorrections[_owner]) / magnitude;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        storedFees[_from] = storedFees[_from].add(earnedFeesOf(_from));
        super._transfer(_from, _to, _amount);

        magnifiedFeesCorrections[_from] = magnifiedFeesPerShare.mul(balanceOf(_from));
        magnifiedFeesCorrections[_to] = magnifiedFeesCorrections[_to].add(magnifiedFeesPerShare.mul(_amount));
    }

    function stake(uint256 _amount) external returns (bool) {
        reputationToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesCorrections[msg.sender].add(
            magnifiedFeesPerShare.mul(_amount)
        );
        return true;
    }

    function exit(uint256 _amount) external returns (bool) {
        redeemInternal(msg.sender);
        _burn(msg.sender, _amount);
        reputationToken.transfer(msg.sender, _amount);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeem() public override returns (bool) {
        redeemInternal(msg.sender);
        magnifiedFeesCorrections[msg.sender] = magnifiedFeesPerShare.mul(balanceOf(msg.sender));
        return true;
    }

    function redeemInternal(address _account) internal {
        uint256 _withdrawableFees = withdrawableFeesOf(_account);
        if (_withdrawableFees > 0) {
            storedFees[_account] = 0;
            collateral.transfer(_account, _withdrawableFees);
        }
    }

    function onTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../libraries/IERC20.sol";

interface ITurboShareToken is IERC20 {
    function trustedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function trustedMint(address _target, uint256 _amount) external;

    function trustedBurn(address _target, uint256 _amount) external;

    function trustedBurnAll(address _target) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @title SafeMathUint256
 * @dev Uint256 math operations with safety checks that throw on error
 */
library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function subS(
        uint256 a,
        uint256 b,
        string memory message
    ) internal pure returns (uint256) {
        require(b <= a, message);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../libraries/IERC20.sol";
import "../libraries/IERC20DynamicSymbol.sol";

interface IFeePot is IERC20 {
    function depositFees(uint256 _amount) external returns (bool);

    function withdrawableFeesOf(address _owner) external view returns (uint256);

    function redeem() external returns (bool);

    function collateral() external view returns (IERC20);

    function reputationToken() external view returns (IERC20DynamicSymbol);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ITurboShareToken.sol";

interface ITurboShareTokenFactory {
    function createShareTokens(bytes32[] calldata _names, string[] calldata _symbols)
        external
        returns (ITurboShareToken[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IArbiter {
    function onTurboCreated(
        uint256 _id,
        string[] memory _outcomeSymbols,
        bytes32[] memory _outcomeNames,
        uint256 _numTicks,
        bytes memory _arbiterConfiguration
    ) external;

    function getTurboResolution(uint256 _id) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ITurboShareToken.sol";
import "../libraries/Initializable.sol";
import "../libraries/SafeMathUint256.sol";
import "../libraries/IERC20.sol";
import "../augur-para/IFeePot.sol";
import "./ITurboShareTokenFactory.sol";
import "./IArbiter.sol";

interface HasTurboStruct {
    struct Turbo {
        address creator;
        uint256 creatorFee;
        uint256 numTicks;
        IArbiter arbiter;
        ITurboShareToken[] shareTokens;
        uint256 creatorFees;
    }
}

interface ITurboHatchery is HasTurboStruct {
    event TurboCreated(
        uint256 id,
        uint256 creatorFee,
        string[] outcomeSymbols,
        bytes32[] outcomeNames,
        uint256 numTicks,
        IArbiter arbiter,
        bytes arbiterConfiguration,
        uint256 indexed index
    );
    event CompleteSetsMinted(uint256 turboId, uint256 amount, address target);
    event CompleteSetsBurned(uint256 turboId, uint256 amount, address target);
    event Claim(uint256 turboId);

    function turbos(uint256 _turboId) external view returns (HasTurboStruct.Turbo memory);

    function tokenFactory() external view returns (ITurboShareTokenFactory);

    function feePot() external view returns (IFeePot);

    function collateral() external view returns (IERC20);

    function createTurbo(
        uint256 _index,
        uint256 _creatorFee,
        string[] memory _outcomeSymbols,
        bytes32[] memory _outcomeNames,
        uint256 _numTicks,
        IArbiter _arbiter,
        bytes memory _arbiterConfiguration
    ) external returns (uint256);

    function getShareTokens(uint256 _id) external view returns (ITurboShareToken[] memory);

    function mintCompleteSets(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external returns (bool);

    function burnCompleteSets(
        uint256 _id,
        uint256 _amount,
        address _receiver
    ) external returns (bool);

    function claimWinnings(uint256 _id) external returns (bool);

    function withdrawCreatorFees(uint256 _id) external returns (bool);

    function getTurboLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";

interface IERC20DynamicSymbol is IERC20 {
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Initializable {
    bool private initialized = false;

    modifier beforeInitialized {
        require(!initialized);
        _;
    }

    function endInitialization() internal beforeInitialized {
        initialized = true;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ITurboShareToken.sol";
import "../libraries/VariableSupplyToken.sol";
import "./ITurboHatchery.sol";
import "../libraries/Ownable.sol";

contract TurboShareToken is ITurboShareToken, VariableSupplyToken, Ownable {
    bytes32 public name;
    string public symbol;

    constructor(
        string memory _symbol,
        bytes32 _name,
        ITurboHatchery _hatchery
    ) {
        symbol = _symbol;
        name = _name;
        owner = address(_hatchery);
    }

    function trustedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        _transfer(_from, _to, _amount);
    }

    function trustedMint(address _target, uint256 _amount) external override onlyOwner {
        mint(_target, _amount);
    }

    function trustedBurn(address _target, uint256 _amount) external override onlyOwner {
        burn(_target, _amount);
    }

    function trustedBurnAll(address _target) external override onlyOwner returns (uint256) {
        uint256 _balance = balanceOf(_target);
        burn(_target, _balance);
        return _balance;
    }

    function onTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override {}

    function onTransferOwnership(address, address) internal override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMathUint256.sol";
import "./ERC20.sol";

/**
 * @title Variable Supply Token
 * @notice A Standard Token wrapper which adds the ability to internally burn and mint tokens
 */
abstract contract VariableSupplyToken is ERC20 {
    using SafeMathUint256 for uint256;

    function mint(address _target, uint256 _amount) internal returns (bool) {
        _mint(_target, _amount);
        onMint(_target, _amount);
        return true;
    }

    function burn(address _target, uint256 _amount) internal returns (bool) {
        _burn(_target, _amount);
        onBurn(_target, _amount);
        return true;
    }

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onMint(address, uint256) internal {}

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onBurn(address, uint256) internal {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeMathUint256.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
abstract contract ERC20 is IERC20 {
    using SafeMathUint256 for uint256;

    uint256 internal _totalSupply;

    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowances;

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address _account) public view virtual override returns (uint256) {
        return balances[_account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender].sub(_amount));
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
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
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
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].sub(_subtractedValue));
        return true;
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
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        balances[_sender] = balances[_sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
        onTokenTransfer(_sender, _recipient, _amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address _account, uint256 _amount) internal {
        _burn(_account, _amount);
        _approve(_account, msg.sender, allowances[_account][msg.sender].sub(_amount));
    }

    // Subclasses of this token generally want to send additional logs through the centralized Augur log emitter contract
    function onTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IOwnable {
    function getOwner() external view returns (address);

    function transferOwnership(address _newOwner) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}