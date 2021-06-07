pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted version of Uniswap Pair (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Pair.sol)

import './BJCashErc20.sol';
import './extensions/Curve.sol';
import './extensions/SafeMath.sol';
import './extensions/ReentrancyGuard.sol';

contract BJCash is BJCashErc20, ReentrancyGuard {
    using SafeMath for uint;
    using SafeMath for Rational;

    constructor(MonetaryPolicy _monetaryPolicy) BJCashErc20(_monetaryPolicy) {} 

    function mint(uint _mintedCash, address payable _to) external payable {
        _adjust({ _mintedCash: _mintedCash, _burnedCash: 0, _unlockCollateralValue: 0, _to: _to });
    }

    function burn(uint _unlockCollateralValue, address payable _to) external {
        uint _burnedCash = balanceOf[address(this)];
        _adjust({ _mintedCash: 0, _burnedCash: _burnedCash, _unlockCollateralValue: _unlockCollateralValue, _to: _to });
    }

    function _adjust(uint _mintedCash, uint _burnedCash, uint _unlockCollateralValue, address payable _to) nonReentrant private {
        require(_mintedCash > 0 || _unlockCollateralValue > 0, 'BJCash: INSUFFICIENT_OUTPUT_AMOUNT');

        address _owner = owner;
        uint _initialTotalCash = this.totalSupply();
        uint _lockedCollateralValue = msg.value;
        uint _initialCollateralPlusLockedCollateral = address(this).balance;
        bool _isSkim = _to == _owner;

        (uint _peerFee, uint _ownerFee) = monetaryPolicy.fees();

        require(_to != address(this), 'BJCash: INVALID_TO');
        if (_mintedCash > 0) {
            uint _ownerFeeAmount = _mintedCash.mul(_ownerFee) / 1 ether;
            _mint({ to: _to, value: _mintedCash.sub(_ownerFeeAmount) }); 
            if (_ownerFeeAmount > 0) {
                _mint({ to: _owner, value: _ownerFeeAmount });
            }
        }
        uint _peerBurnCashFeeValue = 0;
        if (_burnedCash > 0) {
            if (_isSkim) {
                _burn({ from: address(this), value: _burnedCash });
            } else {
                uint _ownerFeeAmount = _burnedCash.mul(_ownerFee) / 1 ether;
                uint _burnedCashWithoutOwnerFee = _burnedCash.sub(_ownerFeeAmount);
                _peerBurnCashFeeValue = _burnedCashWithoutOwnerFee.mul(_peerFee) / 1 ether;
                _burn({ from: address(this), value: _burnedCashWithoutOwnerFee });
                if (_ownerFeeAmount > 0) {
                    _transfer({ from: address(this), to: _owner, value: _ownerFeeAmount });
                }
            }
        }

        uint _finalTotalCash = this.totalSupply();

        uint _peerLockingFeeValue = _lockedCollateralValue.mul(_peerFee) / 1 ether;
        uint _finalCollateral = _initialCollateralPlusLockedCollateral.sub(_unlockCollateralValue);

        uint _initialCollateral = _initialCollateralPlusLockedCollateral.sub(_lockedCollateralValue);

        {
            Rational memory _c0 = Curve.C0({ _collateral: _initialCollateral, _totalSupply: _initialTotalCash });

            require(
                Curve.k({
                    _c0: _c0,
                    _cash: _finalTotalCash.add(_peerBurnCashFeeValue), 
                    _collateral: _finalCollateral.sub(_peerLockingFeeValue) 
                }).roundDown() >= _c0.mul(Curve.MAX_CASH_SUPPLY).roundUp(),
                'BJCash: K'
            );
        }

        if (_unlockCollateralValue > 0) { 
            (bool success, ) = _to.call{value: _unlockCollateralValue}('');
            require(success, 'BJCash: Transfer failed.');
        }
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted version of Uniswap ERC-20 (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)

import './interfaces/Erc20.sol';
import './interfaces/MonetaryPolicy.sol';
import './extensions/SafeMath.sol';
import './extensions/Ownable.sol';

contract BJCashErc20 is Erc20, Ownable {
    using SafeMath for uint;

    string public override constant name = 'BJ Cash';
    string public override constant symbol = 'BJ';
    uint8 public override constant decimals = 18;
    uint public override totalSupply;
    
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;
    
    event NewMonetaryPolicy(address monetaryPolicy);

    MonetaryPolicy public monetaryPolicy;
    function setMonetaryPolicy(MonetaryPolicy _monetaryPolicy) public onlyOwner {
        monetaryPolicy = _monetaryPolicy;
        emit NewMonetaryPolicy(address(monetaryPolicy));
    }

    constructor(MonetaryPolicy _monetaryPolicy) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        monetaryPolicy = _monetaryPolicy;
    }

    function _mint(address to, uint value) internal {
        require(monetaryPolicy.canMint({ to: to, value: value }), 'BJCash: NOT ALLOWED');
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(monetaryPolicy.canBurn({ from: from, value: value }), 'BJCash: NOT ALLOWED');
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        require(monetaryPolicy.canTransfer({ from: from, to: to, value: value }), 'BJCash: NOT ALLOWED');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) override public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) override external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) override public returns (bool) {
        if (allowance[from][msg.sender] != ~uint(0)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'BJCash: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'BJCash: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: GPL-3.0-or-later

interface Erc20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: GPL-3.0-or-later

/* The place where the blowing happens for everyone to see. */
interface MonetaryPolicy {
    function canMint(address to, uint value) external returns (bool);
    function canBurn(address from, uint value) external returns (bool);
    function canTransfer(address from, address to, uint value) external returns (bool);

    function fees() external returns (uint peerFee, uint ownerFee);
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

struct Rational {  
    uint nominator;
    uint denominator;
}
    
library SafeMath {
    using SafeMath for uint;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'BJCash: math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'BJCash: math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'BJCash: math-mul-overflow');
    }

    function add(Rational memory x, uint y) internal pure returns (Rational memory) {
        return Rational({
            nominator: x.nominator + x.denominator.mul(y), 
            denominator: x.denominator
        });
    }

    function mul(Rational memory x, uint y) internal pure returns (Rational memory) {
        return Rational({
            nominator: x.nominator.mul(y), 
            denominator: x.denominator
        });
    }

    function sub(uint x, Rational memory y) internal pure returns (Rational memory) {
        return Rational({
            nominator: y.denominator.mul(x).sub(y.nominator), 
            denominator: y.denominator
        });
    }

    function div(Rational memory x, uint y) internal pure returns (Rational memory) {
        return Rational({
            nominator: x.nominator,
            denominator: x.denominator.mul(y)
        });
    }

    function div(Rational memory x, Rational memory y) internal pure returns (Rational memory) {
        return Rational({
            nominator: x.nominator.mul(y.denominator),
            denominator: x.denominator.mul(y.nominator)
        });
    }

    function roundUp(Rational memory result) internal pure returns (uint z) {
        return divUp(result.nominator, result.denominator);
    }

    function divUp(uint x, uint y) internal pure returns (uint z) {
        uint res = x / y;
        if ((x % y) != 0) {
            res = res.add(1);
        }
        return res;
    }

    function roundDown(Rational memory result) internal pure returns (uint z) {
        return result.nominator / result.denominator;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity =0.8.4;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "BJCashOwnable: Not owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

import './../BJCash.sol';
import './SafeMath.sol';

library Curve {
    using SafeMath for uint;
    using SafeMath for Rational;

    // Initial exchange rate is 1 ETH is 100_000 BJCash.
    uint internal constant MAX_CASH_SUPPLY = 1_000_000_000 ether;

    // u in whitepaper
    function unmintedCashSupply(uint _cashSupply) internal pure returns (uint) {
        return MAX_CASH_SUPPLY.sub(_cashSupply);
    }
    function cashSupplyForUnmintedSupply(uint _unmintedSupply) internal pure returns (uint) {
        return MAX_CASH_SUPPLY.sub(_unmintedSupply);
    }

    // C0 in whitepaper
    function C0(uint _collateral, uint _totalSupply) internal pure returns (Rational memory) {
        if (_totalSupply == 0) {
            return Rational({ nominator: 10_000e18, denominator: 1});
        }
        return Rational({ 
            nominator: (MAX_CASH_SUPPLY.sub(_totalSupply)).mul(_collateral), 
            denominator: _totalSupply
        });
    }

    // vc in whitepaper
    function effectiveCollateral(uint _collateral, Rational memory _c0) internal pure returns (Rational memory) {
        return _c0.add(_collateral);
    }
    function actualCollateral(uint _collateral, Rational memory _c0) internal pure returns (Rational memory) {
        return _collateral.sub(_c0);
    }

    // k in whitepaper
    function k(Rational memory _c0, uint _cash, uint _collateral) internal pure returns (Rational memory) {
        return effectiveCollateral({ _collateral: _collateral, _c0: _c0 }).mul(
            unmintedCashSupply({ _cashSupply: _cash })
        );
    }

    function getSafeMintedValue(BJCash _bjCash, uint _lockedCollateralValue) internal returns (uint) {
        uint _totalSupply = _bjCash.totalSupply();
        uint _balance = address(_bjCash).balance;
        (uint _peerFee,) = _bjCash.monetaryPolicy().fees();

        Rational memory _c0 = C0({ _collateral: _balance, _totalSupply: _totalSupply });

        uint _collateralSubFee = _lockedCollateralValue.sub(_lockedCollateralValue.mul(_peerFee) / 1 ether);

        uint _unmintedCash = _c0.mul(MAX_CASH_SUPPLY).roundUp().divUp(
            effectiveCollateral({ _collateral: _balance.add(_collateralSubFee), _c0: _c0 }).roundDown()
        );
        uint safeValue = cashSupplyForUnmintedSupply(_unmintedCash).sub(_totalSupply);
        return safeValue;
    }

    function getSafeUnlockedCollateralValue(BJCash _bjCash, uint _burnedCash) internal returns (uint) {
        uint _totalSupply = _bjCash.totalSupply();
        uint _balance = address(_bjCash).balance;
        (uint _peerFee, uint _ownerFee) = _bjCash.monetaryPolicy().fees();
        Rational memory _c0 = C0({ _collateral: _balance, _totalSupply: _totalSupply });

        uint _ownerFeeAmount = _burnedCash.mul(_ownerFee) / 1 ether;
        uint _burnedCashWithoutOwnerFee = _burnedCash.sub(_ownerFeeAmount);
        uint _peerBurnCashFeeValue = _burnedCashWithoutOwnerFee.mul(_peerFee) / 1 ether;
        uint _burnValue = _burnedCashWithoutOwnerFee.sub(_peerBurnCashFeeValue);

        uint _collateral = _c0.mul(MAX_CASH_SUPPLY).roundUp().divUp(
            unmintedCashSupply(_totalSupply.sub(_burnValue))
        );
        return _balance.sub(actualCollateral({ _collateral: _collateral, _c0: _c0 }).roundUp());
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

import './BJCash.sol';
import './Dandelion.sol';
import './extensions/Curve.sol';
import './extensions/SafeMath.sol';

/* The place of infinite joy. */
contract HappyMeadow {
    using SafeMath for uint;
    using Curve for BJCash;

    BJCash public bjCash;
    Dandelion public dandelion;

    constructor(BJCash _bjCash, Dandelion _dandelion) {
        bjCash = _bjCash;
        dandelion = _dandelion;
    }

    function mint(uint _minMintedCash, address payable _to) external payable {
        BJCash _bjCash = bjCash;
        uint _collateralValue = msg.value;
        uint _mintedCash = _mintSafeCashValue({ 
            _bjCash: _bjCash, _collateralValue: _collateralValue, _minMintedCash: _minMintedCash });
        bjCash.mint{value: _collateralValue}({ _mintedCash: _mintedCash, _to: _to });
    }

    function blow(string calldata _reason, uint _minMintedCash, address payable _to) external payable {
        BJCash _bjCash = bjCash;
        uint _collateralValue = msg.value;
        uint _mintedCash = _mintSafeCashValue({ 
            _bjCash: _bjCash, _collateralValue: _collateralValue, _minMintedCash: _minMintedCash });
        dandelion.blow{value: _collateralValue}({ _reason: _reason, _mintedCash: _mintedCash, _to: _to });
    }

    function _mintSafeCashValue(BJCash _bjCash, uint _collateralValue, uint _minMintedCash) private returns (uint) {
        uint _mintedCash = _bjCash.getSafeMintedValue(_collateralValue);
        require(_mintedCash >= _minMintedCash, 'HappyMeadow: Seeds are too expensive this year');
        return _mintedCash;
    }

    function burn(uint _burnedCash, uint _minUnlockCollateralValue, address payable _to) external {
        address _from = msg.sender;
        BJCash _bjCash = bjCash;
        uint _unlockedCollateral = _burnSafeUnlockedCollateralValue({ 
            _bjCash: _bjCash, _burnedCash: _burnedCash, _minUnlockCollateralValue: _minUnlockCollateralValue 
        });
        bjCash.transferFrom({ from: _from, to: address(_bjCash), value: _burnedCash });
        bjCash.burn({ _unlockCollateralValue: _unlockedCollateral, _to: _to });
    }

    function approveAndBurn(uint _burnedCash, uint _minUnlockCollateralValue, address payable _to, 
        uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external {
        address _from = msg.sender;
        BJCash _bjCash = bjCash;
        uint _safeUnlockedCollateral = _burnSafeUnlockedCollateralValue({ 
            _bjCash: _bjCash,  _burnedCash: _burnedCash, _minUnlockCollateralValue: _minUnlockCollateralValue 
        });
        bjCash.permit({ owner: _from, spender: address(this), value: _burnedCash, deadline: _deadline, v: _v, r: _r, s: _s });
        bjCash.transferFrom({ from: _from, to: address(_bjCash), value: _burnedCash });
        bjCash.burn({ _unlockCollateralValue: _safeUnlockedCollateral, _to: _to });
    }

    function _burnSafeUnlockedCollateralValue(BJCash _bjCash, uint _burnedCash, uint _minUnlockCollateralValue) private returns (uint) {
        uint _safeUnlockedCollateral = _bjCash.getSafeUnlockedCollateralValue(_burnedCash);
        require(_safeUnlockedCollateral >= _minUnlockCollateralValue, 'HappyMeadow: Seeds are too cheap this year');
        return _safeUnlockedCollateral;
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

import './BJCash.sol';
import './extensions/SafeMath.sol';
import './interfaces/Blowable.sol';
import './interfaces/MonetaryPolicy.sol';

/* If you want to disable minting and to dispense the seeds you need to
  hold the Dandelion yourself and blow.
  How much you need to pay for the privilege depends on the blowing demand.
 */
contract Dandelion is Blowable, MonetaryPolicy {
    using SafeMath for uint;

    event Blow(string reason, uint collateral, uint cash, address indexed to);

    uint public constant MIN_COLLATERAL = 1 ether / 100;

    BJCash public bjCash;

    constructor(BJCash _bjCash) {
      bjCash = _bjCash;
    }

    uint public lastBlowTimestamp = 0; 
    uint public lastBlowCollateral = 0;

    function canMint(address to, uint) external override view returns (bool) {
      return block.timestamp.sub(lastBlowTimestamp) >= 10 minutes && (to == tx.origin || to == bjCash.owner());
    }

    function canBurn(address, uint) external override view returns (bool) {
      uint timeSinceBlow = block.timestamp.sub(lastBlowTimestamp);
      return timeSinceBlow < 10 minutes || timeSinceBlow >= 20 minutes;
    }

    function canTransfer(address, address to, uint) external override view returns (bool) {
      return to == address(bjCash);
    }

    function fees() external override pure returns (uint peerFee, uint ownerFee) {
      return (1 ether * 30 / 10000, 0);
    }

    function blow(string calldata _reason, uint _mintedCash, address payable _to) external override payable {
      uint timeSinceLastBlow = block.timestamp.sub(lastBlowTimestamp);
      require(timeSinceLastBlow > 0, 'Dandelion: I\'ve just been blown');
      uint requiredCollateral = 30 minutes * lastBlowCollateral / timeSinceLastBlow;
      if (requiredCollateral < MIN_COLLATERAL) {
        requiredCollateral = MIN_COLLATERAL;
      }

      uint _collateralValue = msg.value;
      require(_collateralValue >= requiredCollateral, 'Dandelion: I\'m a popular dandelion!');
      uint startCash = bjCash.balanceOf(_to);
      bjCash.mint{ value: _collateralValue }({ _mintedCash: _mintedCash, _to: _to });
      uint endCash = bjCash.balanceOf(_to);
      emit Blow({ reason: _reason, collateral: _collateralValue, cash: endCash.sub(startCash), to: _to });

      lastBlowCollateral = _collateralValue;
      lastBlowTimestamp = block.timestamp;
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

interface Blowable {
    function blow(string calldata _reason, uint _mintedCash, address payable _to) external payable;
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later

import '../BJCashErc20.sol';

contract TestErc20 is BJCashErc20 {
    constructor(uint _totalSupply, MonetaryPolicy _monetaryPolicy) BJCashErc20(_monetaryPolicy) {
        _mint(msg.sender, _totalSupply);
    }
}

pragma solidity =0.8.4;

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted version of Uniswap ERC-20 (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)

import '../interfaces/MonetaryPolicy.sol';

interface Mintable {
  function mint(uint _mintedCash, address payable _to) external payable;

  function burn(uint _unlockCollateralValue, address payable _to) external;
}

contract TestMonetaryPolicy is MonetaryPolicy {
  enum Method { None, Mint, Burn }

  bool public allowMint = true;
  bool public allowBurn = true;
  bool public allowTransfer = true;

  uint public peerFee = 0;
  uint public ownerFee = 0;

  Mintable public bjCash;
  Method public method;

  function setAllowMint(bool _allowMint) public {
    allowMint = _allowMint;
  }

  function setAllowBurn(bool _allowBurn) public {
    allowBurn = _allowBurn;
  }

  function setAllowTransfer(bool _allowTransfer) public {
    allowTransfer = _allowTransfer;
  }

  function setPeerFee(uint _peerFee) public {
    peerFee = _peerFee;
  }

  function setOwnerFee(uint _ownerFee) public {
    ownerFee = _ownerFee;
  }

  function setMethod(Method _method) public {
    method = _method;
  }

  function setBJCash(Mintable _bjCash) public {
    bjCash = _bjCash;
  }

  function _maybePerformCallJob() private {
    if (address(bjCash) != address(0x0)) {
      if (method == Method.Mint) {
        bjCash.mint(0, payable(0x0));
      } else if (method == Method.Burn) {
        bjCash.burn(0, payable(0x0));
      } else {
        require(false, 'Method not set');
      }
    }
  }
  
  function canMint(address, uint) external override returns (bool) {
    _maybePerformCallJob();
    return allowMint;
  }

  function canBurn(address, uint) external override returns (bool) {
    _maybePerformCallJob();
    return allowBurn;
  }

  function canTransfer(address, address , uint) external override returns (bool) {
    _maybePerformCallJob();
    return allowTransfer;
  }

  function fees() external override returns (uint _peerFee, uint _ownerFee) {
    _maybePerformCallJob();
    return (peerFee, ownerFee);
  }

  fallback() external payable {
    _maybePerformCallJob();
  }

  receive() external payable {
    _maybePerformCallJob();
  }
}

pragma solidity =0.8.4;

import "../../governance/Timelock.sol";

// SPDX-License-Identifier: BSD-3

contract TimelockHarness is Timelock {
    constructor(address admin_, uint delay_) Timelock(admin_, delay_) {
    }

    function harnessSetPendingAdmin(address pendingAdmin_) public {
        pendingAdmin = pendingAdmin_;
    }

    function harnessSetAdmin(address admin_) public {
        admin = admin_;
    }
}

pragma solidity ^0.8.0;

import "../extensions/SafeMath.sol";

// SPDX-License-Identifier: BSD-3

// https://raw.githubusercontent.com/compound-finance/compound-protocol/v2.8.1/contracts/Timelock.sol

contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    receive() external payable { 
        require(msg.value > 0, "Somebody is calling an non existing method.");
    }

    fallback() external payable { 
        require(msg.value > 0, "Somebody is calling an non existing method.");
    }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call {value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function multicall(
        address[] memory targets, 
        uint[] memory values, 
        string[] memory signatures, 
        bytes[] memory datas
    ) public payable {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        
        for (uint i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint value = values[i];
            string memory signature = signatures[i];

            bytes memory callData;

            if (bytes(signature).length == 0) {
                callData = datas[i];
            } else {
                callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), datas[i]);
            }

            (bool success,) = target.call {value: value}(callData);
            require(success, "Timelock::executeTransaction: Transaction execution reverted.");
        }
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "evmVersion": "istanbul",
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}