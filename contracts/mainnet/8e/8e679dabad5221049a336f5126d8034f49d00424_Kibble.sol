// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';

import { ERC20 } from './open-zeppelin/ERC20.sol';
import { IFTPAntiBot } from './interfaces/IFTPAntiBot.sol';

import { KibbleAccessControl } from './KibbleAccessControl.sol';
import { KibbleBase } from './KibbleBase.sol';

import { IUniswapV2Router02 } from './interfaces/IUniswapV2Router.sol';
import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';

//
//                                               `````
//                                       `.-/+oosssssssoo+/:.`
//                                   `:+syyso++/////////++osyyso:.
//                                .+yhs+/:::::::::::::::::::://oshy+.
//                             `/yhs/:::::://///////////////:::::/+ohy/`
//                           `+hy+:::://///++osso++++++++oo++////:::/+yh+.
//                          /dh+:::/++/+osyhhhhhs+/////+yhhhyyo++++/::/+yh+`
//                        .yms::/oo+++syhhhhhhhhs+////+yhhhhhhhhys++++/:/ohy-
//                       :dd+::oyo++++hhhhhhhhhhs+///+yhhhhhhhhhhho+++o+//+yh/
//                      /mh/:/ys+++//+hhhhhhhhhhs++++yhhhhhhhhhhhs+/++oso///sd+
//                     /mh::+ys++////+hhhhhhhhhhs+++yhhhhhhhhhhhs+////+oss+//sd+
//                    -dd/:+ys++/////+hhhhhhhhhhy++yhhhhhhhhhhhs+//////+osy+//yd:
//                    ym+:/yy+o//////+hhhhhhhhhhyoyhhhhhhhhhhhs+////////+sys+/+hh`
//                   :my::oh/o///////+hhhhhhhhhhyyhhhhhhhhhhho+//////////osho//sd+
//                   ym+:/ys++///////+hhhhhhhhhhhhhhhhhhhhhho+////////////syy+/+hh
//                  `dm::+d+o////////+hhhhhhhhhhhhhhhhhhhhho+/////////////ssh+//hd.
//                  .md::oh/o////////+hhhhhhhhhhhhhhhhhhhho+//////////////oyho//ym-
//                  .mh::oh/o////////+hhhhhhhhhhhhhhhhhhhho+//////ydho////oyho//ym:
//                  .dd::od/o////////+hhhhhhhhhhhhhhhhhhhhho+////+mmms////osh+//ym.
//                   hm/:/hoo////////+hhhhhhhhhhhhhhhhhhhhhhs+////+o+/////ssy+/+hh`
//                   /ms::sh/o///////+hhhhhhhhhhhhhhhhhhhhhhhs+//////////+sho//sdo
//                   `hm/:/yo++//////+hhhhhhhhhhyshhhhhhhhhhhhs+/////////ssy+/+hd.
//                    :mh::+h+++/////+hhhhhhhhhhy+ohhhhhhhhhhhhs+///////osy+//sd+
//                     oms::oho++////+hhhhhhhhhhy++oyhhhhhhhhhhhy+////+osy+//ohs
//                     `oms::+yo++///+hhhhhhhhhhs+++oyhhhhhhhhhhhy+//+oss+//ohs`
//                       omy/:/ss+++/+hhhhhhhhhhs+//+oyhhhhhhhhhhhy++oo+///oho`
//                        :dd+::+ss++oyhhhhhhhhhs+////+yhhhhhhhhhyo+o+///+sh/
//                         .sdy/::+oo++osyhhhhhhs+/////+yhhhhyyo+++/:://oys.
//                           -ydy/::::///++osyyys//////++sso++///::://+yy:
//                             -ods/::::::::///////////////::::::://oys-
//                               `/syo//:::::-------------::::///oys/`
//                                  `:+sss+/:::::::::::::///+osso:`
//                                      `.:+oooosoooooooooo+:-`
//                                            `````.`````
//
/// @notice Kibble the main utility token of the Sanshu eco-system.
contract Kibble is KibbleBase {
  using SafeMath for uint256;
  /// erc20 meta
  string internal constant NAME = 'Kibble Token';
  string internal constant SYMBOL = 'KIBBLE';
  uint8 internal constant DECIMALS = 18;
  uint256 internal constant MIN_TOTAL_SUPPLY = 250 * 10**6 * 10**18;

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );

  bytes32 public DOMAIN_SEPARATOR =
  keccak256(
    abi.encode(
      EIP712_DOMAIN,
      keccak256(bytes(NAME)),
      keccak256(EIP712_REVISION),
      block.chainid,
      address(this)
    )
  );

  /// max supply
  uint256 public maxSupply = 0;

  /// anti-bot state
  IFTPAntiBot private antiBot;
  bool public antiBotEnabled = false;

  /// uniswap state
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  /// track pair addresses so that transfers can be subject to
  /// fees for swaps
  mapping(address => bool) public tokenPairs;

  /// track sell contracts
  mapping(address => bool) public sellContracts;

  /// fee state
  bool public feeEnabled = false;
  uint256 public feeResetCooldown = 1 days;
  address public redistributionPolicyAddress;
  mapping(address => bool) public excluded;
  mapping(address => uint256) private _firstSell;
  mapping(address => uint256) private _sellCount;
  uint256 private _taxFee = 5;
  uint256 private _feeMultiplier = 5;

  /// governance state
  mapping(address => uint256) public _nonces;
  mapping(address => uint256) internal _votingCheckpointsCounts;
  mapping(address => address) internal _votingDelegates;
  mapping(address => mapping(uint256 => Checkpoint)) public votingCheckpoints;
  mapping(address => mapping(uint256 => Checkpoint))
    internal _propositionPowerCheckpoints;
  mapping(address => uint256) internal _propositionPowerCheckpointsCounts;
  mapping(address => address) internal _propositionPowerDelegates;

  // events
  event LogTokenPair(address pair, bool included);
  event LogSellContracts(address targetAddress, bool included);
  event LogExcluded(address targetAddress, bool included);

  /// @notice main constructor for token
  /// @param _antiBotAddress address for anti-bot protection https://antibot.fairtokenproject.com/
  /// @param _uniswapRouterAddress address for uniswap router
  constructor(address _antiBotAddress, address _uniswapRouterAddress)
    ERC20(NAME, SYMBOL)
  {
    /// set up antiBot
    IFTPAntiBot _antiBot = IFTPAntiBot(_antiBotAddress);
    antiBot = _antiBot;

    /// initiate new pair for KIBBLE/WETH
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      _uniswapRouterAddress
    );
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setTrackedPair(_uniswapV2Pair, true);
    _setSellContracts(_uniswapRouterAddress, true);
  }

  /// @notice sets max supply
  /// @param _amount The amount that is max supply
  function setMaxSupply(uint256 _amount) external virtual onlyOwner {
    require(_amount > _totalSupply, "Kibble: current supply is greater than inputed amount");
    require(maxSupply == 0, "Kibble: cannot set max supply again");
    maxSupply = _amount;
  }

  /// @notice mints an amount to an account only can be ran by minter
  /// @param _recipient The address to mint to
  /// @param _amount The amount to mint
  function mint(address _recipient, uint256 _amount)
    external
    virtual
    onlyMinter
  {
    require(
      maxSupply == 0 || maxSupply > _totalSupply,
      'Kibble: Max supply reached'
    );
    uint256 safeAmount = maxSupply == 0 || _amount + _totalSupply <= maxSupply
      ? _amount
      : maxSupply - _totalSupply;

    _mint(_recipient, safeAmount);
  }

  /// @notice burns an amount to an account only can be ran by burner
  /// @param _sender The address to burn from
  /// @param _amount The amount to burn
  function burn(address _sender, uint256 _amount) external virtual onlyBurner {
    _burn(_sender, _amount);
  }

  /// @notice implements the permit function
  /// @param _owner the owner of the funds
  /// @param _spender the _spender
  /// @param _value the amount
  /// @param _deadline the deadline timestamp, type(uint256).max for no deadline
  /// @param _v signature param
  /// @param _r signature param
  /// @param _s signature param
  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    require(_owner != address(0), 'Kibble: owner invalid');
    require(block.timestamp <= _deadline, 'Kibble: invalid deadline');
    uint256 currentValidNonce = _nonces[_owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(
            PERMIT_TYPEHASH,
            _owner,
            _spender,
            _value,
            currentValidNonce,
            _deadline
          )
        )
      )
    );

    require(
      _owner == ecrecover(digest, _v, _r, _s),
      'Kibble: invalid signature'
    );
    _nonces[_owner] = currentValidNonce.add(1);
    _approve(_owner, _spender, _value);
  }

  /// @notice Delegates power from signatory to `delegatee`
  /// @param _delegatee The address to delegate votes to
  /// @param _power the power of delegation
  /// @param _nonce The contract state required to match the signature
  /// @param _expiry The time at which to expire the signature
  /// @param _v The recovery byte of the signature
  /// @param _r Half of the ECDSA signature pair
  /// @param _s Half of the ECDSA signature pair
  function delegateByPowerBySig(
    address _delegatee,
    DelegationPower _power,
    uint256 _nonce,
    uint256 _expiry,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    bytes32 structHash = keccak256(
      abi.encode(
        DELEGATE_BY_POWER_TYPEHASH,
        _delegatee,
        uint256(_power),
        _nonce,
        _expiry
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash)
    );
    address signatory = ecrecover(digest, _v, _r, _s);
    require(
      signatory != address(0),
      'Kibble: delegateByPowerBySig: invalid signature'
    );
    require(
      _nonce == _nonces[signatory]++,
      'Kibble: delegateByPowerBySig: invalid nonce'
    );
    require(
      block.timestamp <= _expiry,
      'Kibble: delegateByPowerBySig: invalid expiration'
    );
    _delegateByPower(signatory, _delegatee, _power);
  }

  /// @notice Delegates power from signatory to `_delegatee`
  /// @param _delegatee The address to delegate votes to
  /// @param _nonce The contract state required to match the signature
  /// @param _expiry The time at which to expire the signature
  /// @param _v The recovery byte of the signature
  /// @param _r Half of the ECDSA signature pair
  /// @param _s Half of the ECDSA signature pair
  function delegateBySig(
    address _delegatee,
    uint256 _nonce,
    uint256 _expiry,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_TYPEHASH, _delegatee, _nonce, _expiry)
    );
    bytes32 digest = keccak256(
      abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, structHash)
    );
    address signatory = ecrecover(digest, _v, _r, _s);
    require(
      signatory != address(0),
      'Kibble: delegateByPowerBySig: invalid signature'
    );
    require(
      _nonce == _nonces[signatory]++,
      'Kibble: delegateByPowerBySig: invalid nonce'
    );
    require(
      block.timestamp <= _expiry,
      'Kibble: delegateByPowerBySig: invalid expiration'
    );

    _delegateByPower(signatory, _delegatee, DelegationPower.Voting);
    _delegateByPower(signatory, _delegatee, DelegationPower.Proposition);
  }

  /// @notice transfers tokens to recipient
  /// @param _recipient who the tokens are going to
  /// @param _amount amount of tokens
  function transfer(address _recipient, uint256 _amount)
    public
    virtual
    override
    returns (bool success_)
  {
    require(_recipient != address(0), 'Kibble: transfer to the zero address');

    address sender = _msgSender();

    if (_amount == 0) {
      super._transfer(sender, _recipient, 0);
      return false;
    }

    if (antiBotEnabled) {
      if (tokenPairs[_recipient]) {
        require(
          !antiBot.scanAddress(sender, _recipient, tx.origin),
          'Kibble: no bots allowed'
        );
      }
    }

    uint256 amountMinusFees = _removeFees(sender, _recipient, _amount);

    _transfer(sender, _recipient, amountMinusFees);

    _resetFee();

    success_ = true;
  }

  /// @notice transfers tokens from sender to recipient
  /// @param _sender who the tokens are from
  /// @param _recipient who the tokens are going to
  /// @param _amount amount of tokens
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public virtual override returns (bool success_) {
    require(_sender != address(0), 'Kibble: transfer from the zero address');
    require(_recipient != address(0), 'Kibble: transfer to the zero address');

    if (_amount == 0) {
      _transfer(_sender, _recipient, 0);
      return false;
    }

    if (antiBotEnabled) {
      if (tokenPairs[_sender]) {
        require(
          !antiBot.scanAddress(_recipient, _sender, tx.origin),
          'Kibble: no bots allowed'
        );
      }
      if (tokenPairs[_recipient]) {
        require(
          !antiBot.scanAddress(_sender, _recipient, tx.origin),
          'Kibble: no bots allowed'
        );
      }
    }

    uint256 amountMinusFees = _removeFees(_sender, _recipient, _amount);

    _transfer(_sender, _recipient, amountMinusFees);

    _resetFee();

    success_ = true;
  }

  /// @notice sets new redistribution address
  /// @param _address address for redistribution policy
  function setRedistributionPolicyAddress(address _address) external onlyOwner {
    require(_address != address(0), 'Kibble: address cannot be zero address');
    require(_isContract(_address), 'Kibble: address has to be a contract');

    if (redistributionPolicyAddress != address(0)) {
      delete excluded[redistributionPolicyAddress];
    }

    redistributionPolicyAddress = _address;
    _setExcluded(_address, true);
  }

  /// @notice enable fees to be sent to redistribution policy
  function enableFees() external onlyOwner {
    require(
      redistributionPolicyAddress != address(0),
      'Kibble: redistribution policy not set'
    );
    require(!feeEnabled, 'Kibble: fee already enabled');
    feeEnabled = true;
  }

  /// @notice disable fees to be sent to redistribution policy
  function disableFees() external onlyOwner {
    require(feeEnabled, 'Kibble: fee already disabled');
    feeEnabled = false;
  }

  /// @notice set a new tax fee
  /// @param _fee the new fee
  function setTaxFee(uint256 _fee) external onlyOwner {
    _taxFee = _fee;
  }

  /// @notice set a new fee multiplier
  /// @param _multiplier the new multiplier
  function setFeeMultiplier(uint256 _multiplier) external onlyOwner {
    _feeMultiplier = _multiplier;
  }

  /// @notice set cool down for fee reset
  /// @param _cooldown cool down in days
  function setFeeResetCooldown(uint256 _cooldown) external onlyOwner {
    feeResetCooldown = _cooldown;
  }

  /// @notice set a pair to be included/excluded into antibot
  /// @param _pair the pair address
  /// @param _included if the pair is included or not
  function setTrackedPair(address _pair, bool _included) external onlyOwner {
    require(_pair != uniswapV2Pair, 'Kibble: og weth pair cannot be updated');
    require(_isContract(_pair), 'Kibble: address has to be a contract');

    _setTrackedPair(_pair, _included);
  }

  /// @notice set contract address to include in fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function setSellContracts(address _targetAddress, bool _included)
    external
    onlyOwner
  {
    require(
      _isContract(_targetAddress),
      'Kibble: address has to be a contract'
    );
    _setSellContracts(_targetAddress, _included);
  }

  /// @notice set contract address to excluded from fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function setExcluded(address _targetAddress, bool _included)
    external
    onlyOwner
  {
    _setExcluded(_targetAddress, _included);
  }

  /// @notice calculate fees for given user and send to redis
  /// @param _sender the amount of tokens being transferred
  /// @param _recipient the amount of tokens being transferred
  /// @param _amount the amount of tokens being transferred
  function _removeFees(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal returns (uint256 amount_) {
    if (!_includedInFee(_sender, _recipient)) return _amount;

    _calcFee(_sender);
    uint256 fee = _amount.mul(_taxFee).div(100);

    _balances[redistributionPolicyAddress] = _balances[
      redistributionPolicyAddress
    ]
    .add(fee);

    amount_ = _amount.sub(fee);

    emit Transfer(_sender, redistributionPolicyAddress, fee);
  }

  /// @notice choose fee percentage and update reset time and tx counts
  /// @param _sender the amount of tokens being transferred
  function _calcFee(address _sender) internal {
    if (_firstSell[_sender] + feeResetCooldown < block.timestamp) {
      _sellCount[_sender] = 0;
    }

    if (_sellCount[_sender] == 0) {
      _firstSell[_sender] = block.timestamp;
    }

    if (_sellCount[_sender] < 4) {
      _sellCount[_sender]++;
    }

    _taxFee = _sellCount[_sender].mul(_feeMultiplier);
  }

  /// @notice Writes a checkpoint before any operation involving transfer of value: _transfer, _mint and _burn
  /// - On _transfer, it writes checkpoints for both "from" and "to"
  /// - On _mint, only for _recipient
  /// - On _burn, only for _sender
  /// @param _sender the from address
  /// @param _recipient the to address
  /// @param _amount the amount to transfer
  function _beforeTokenTransfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal override {
    address votingFromDelegatee = _getDelegatee(_sender, _votingDelegates);
    address votingToDelegatee = _getDelegatee(_recipient, _votingDelegates);
    uint256 fee = 0;

    if (_includedInFee(_sender, _recipient)) {
      fee = _amount.mul(_taxFee).div(100);
    }

    _moveDelegatesByPower(
      votingFromDelegatee,
      votingToDelegatee,
      _amount.add(fee),
      DelegationPower.Voting
    );

    address propPowerFromDelegatee = _getDelegatee(
      _sender,
      _propositionPowerDelegates
    );
    address propPowerToDelegatee = _getDelegatee(
      _recipient,
      _propositionPowerDelegates
    );

    _moveDelegatesByPower(
      propPowerFromDelegatee,
      propPowerToDelegatee,
      _amount.add(fee),
      DelegationPower.Proposition
    );
  }

  /// @notice get delegation data by power
  /// @param _power the power querying by from
  function _getDelegationDataByPower(DelegationPower _power)
    internal
    view
    override
    returns (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints_,
      mapping(address => uint256) storage checkpointsCount_,
      mapping(address => address) storage delegates_
    )
  {
    if (_power == DelegationPower.Voting) {
      checkpoints_ = votingCheckpoints;
      checkpointsCount_ = _votingCheckpointsCounts;
      delegates_ = _votingDelegates;
    } else {
      checkpoints_ = _propositionPowerCheckpoints;
      checkpointsCount_ = _propositionPowerCheckpointsCounts;
      delegates_ = _propositionPowerDelegates;
    }
  }

  /// @notice set a pair to be included/excluded into fees
  /// @param _pair the pair address
  /// @param _included if the pair is included or not
  function _setTrackedPair(address _pair, bool _included) internal {
    require(
      tokenPairs[_pair] != _included,
      'Kibble: pair is already tracked with included state'
    );

    tokenPairs[_pair] = _included;
    emit LogTokenPair(_pair, _included);
  }

  /// @notice set an address for selling contracts
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function _setSellContracts(address _targetAddress, bool _included) internal {
    require(
      sellContracts[_targetAddress] != _included,
      'Kibble: This address is already tracked with included state'
    );

    sellContracts[_targetAddress] = _included;
    emit LogSellContracts(_targetAddress, _included);
  }

  /// @notice set an address to be excluded from fees
  /// @param _targetAddress the address
  /// @param _included if the pair is included or not
  function _setExcluded(address _targetAddress, bool _included) internal {
    require(
      excluded[_targetAddress] != _included,
      'Kibble: This address is already tracked with included state'
    );

    excluded[_targetAddress] = _included;
    emit LogExcluded(_targetAddress, _included);
  }

  /// @notice reset the fee
  function _resetFee() private {
    _taxFee = 5;
  }

  /// @notice check to included from fees
  /// @param _sender the amount of tokens being transferred
  /// @param _recipient the amount of tokens being transferred
  function _includedInFee(address _sender, address _recipient)
    private
    view
    returns (bool included_)
  {
    included_ =
      feeEnabled &&
      (sellContracts[_recipient] || tokenPairs[_recipient]) &&
      !excluded[_sender];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';

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
contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 internal _totalSupply;

  string internal _name;
  string internal _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
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
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
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
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      'ERC20: transfer amount exceeds allowance'
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

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
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      'ERC20: decreased allowance below zero'
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
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
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
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
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
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
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

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
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFTPAntiBot {
  function scanAddress(
    address _address,
    address _safeAddress,
    address _origin
  ) external returns (bool);

  function registerBlock(address _recipient, address _sender) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { AccessControl } from '@openzeppelin/contracts/access/AccessControl.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract KibbleAccessControl is AccessControl, Ownable {
  /// @notice role based events
  event BurnerAdded(address burner);
  event MinterAdded(address minter);

  /// @notice set minter role, ie staking contracts
  bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

  /// @notice set minter role, ie staking contracts
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  /// @notice onlyBurner modifier
  modifier onlyBurner() {
    require(
      hasRole(BURNER_ROLE, msg.sender),
      'KibbleAccessControl: Only burner'
    );
    _;
  }

  /// @notice setup a burner role can only be set by dev
  /// @param _burner burner address
  function setupBurner(address _burner) external onlyOwner {
    require(
      _isContract(_burner),
      'KibbleAccessControl: Burner can only be a contract'
    );
    _setupRole(BURNER_ROLE, _burner);

    emit BurnerAdded(_burner);
  }

  /// @notice onlyMinter modifier
  modifier onlyMinter() {
    require(
      hasRole(MINTER_ROLE, msg.sender),
      'KibbleAccessControl: Only minter'
    );
    _;
  }

  /// @notice setup minter role can only be set by dev
  /// @param _minter minter address
  function setupMinter(address _minter) external onlyOwner {
    require(
      _isContract(_minter),
      'KibbleAccessControl: Minter can only be a contract'
    );
    _setupRole(MINTER_ROLE, _minter);

    emit MinterAdded(_minter);
  }

  /// @notice Check if an address is a contract
  function _isContract(address _addr) internal view returns (bool isContract_) {
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    isContract_ = size > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';

import { KibbleAccessControl } from './KibbleAccessControl.sol';
import { ERC20 } from './open-zeppelin/ERC20.sol';

abstract contract KibbleBase is ERC20, KibbleAccessControl {
  using SafeMath for uint256;
  bytes32 public constant DELEGATE_BY_POWER_TYPEHASH =
    keccak256(
      'DelegateByPower(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
    );

  bytes32 public constant DELEGATE_TYPEHASH =
    keccak256('Delegate(address delegatee,uint256 nonce,uint256 expiry)');

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint128 blockNumber;
    uint256 votes;
  }

  /// @notice Enum of powers delegate can have
  enum DelegationPower {
    Proposition,
    Voting
  }

  /// @notice emitted when a user delegates to another
  /// @param _delegator the delegator
  /// @param _delegatee the delegatee
  /// @param _power power querying
  event DelegateChanged(
    address indexed _delegator,
    address indexed _delegatee,
    DelegationPower _power
  );

  /// @notice emitted when an action changes the delegated power of a user
  /// @param _user the user which delegated power has changed
  /// @param _amount the amount of delegated power for the user
  /// @param _power power querying
  event DelegatedPowerChanged(
    address indexed _user,
    uint256 _amount,
    DelegationPower _power
  );

  /// @notice grant single delegation power to delegatee
  /// @param _delegatee giving power to
  /// @param _power the power being given
  function delegateByPower(address _delegatee, DelegationPower _power)
    external
  {
    _delegateByPower(msg.sender, _delegatee, _power);
  }

  /// @notice grant delegation power to delegatee
  /// @param _delegatee giving power to
  function delegate(address _delegatee) external {
    _delegateByPower(msg.sender, _delegatee, DelegationPower.Proposition);
    _delegateByPower(msg.sender, _delegatee, DelegationPower.Voting);
  }

  /// @notice returns the delegatee of an user by power
  /// @param _delegator the address of the delegator
  /// @param _power power querying
  function getDelegateeByPower(address _delegator, DelegationPower _power)
    external
    view
    returns (address)
  {
    (
      ,
      ,
      mapping(address => address) storage delegates
    ) = _getDelegationDataByPower(_power);

    return _getDelegatee(_delegator, delegates);
  }

  /// @notice gets the current delegated power of a user. The current power is the
  /// power delegated at the time of the last checkpoint
  /// @param _user the user
  /// @param _power power querying
  function getPowerCurrent(address _user, DelegationPower _power)
    external
    view
    returns (uint256 currentPower_)
  {
    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    currentPower_ = _searchByBlockNumber(
      checkpoints,
      checkpointsCounts,
      _user,
      block.number
    );
  }

  /// @notice queries the delegated power of a user at a certain block
  /// @param _user the user
  /// @param _blockNumber the block number querying by
  /// @param _power the power querying by
  function getPowerAtBlock(
    address _user,
    uint256 _blockNumber,
    DelegationPower _power
  ) external view returns (uint256 powerAtBlock_) {
    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    powerAtBlock_ = _searchByBlockNumber(
      checkpoints,
      checkpointsCounts,
      _user,
      _blockNumber
    );
  }

  /// @notice delegates the specific power to a delegate
  /// @param _delegator the user which delegated power has changed
  /// @param _delegatee the user which delegated power has changed
  /// @param _power the power being given
  function _delegateByPower(
    address _delegator,
    address _delegatee,
    DelegationPower _power
  ) internal {
    require(
      _delegatee != address(0),
      'KibbleBase: _delegateByPower: invalid delegate'
    );

    (
      ,
      ,
      mapping(address => address) storage delegates
    ) = _getDelegationDataByPower(_power);

    uint256 delegatorBalance = balanceOf(_delegator);

    address previousDelegatee = _getDelegatee(_delegator, delegates);

    delegates[_delegator] = _delegatee;

    _moveDelegatesByPower(
      previousDelegatee,
      _delegatee,
      delegatorBalance,
      _power
    );
    emit DelegateChanged(_delegator, _delegatee, _power);
  }

  /// @notice reassigns delegation to another user
  /// @param _from the user from which delegated power is moved
  /// @param _to the user that will receive the delegated power
  /// @param _amount the amount of delegated power to be moved
  /// @param _power the power being reassigned
  function _moveDelegatesByPower(
    address _from,
    address _to,
    uint256 _amount,
    DelegationPower _power
  ) internal {
    if (_from == _to) {
      return;
    }

    (
      mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
      mapping(address => uint256) storage checkpointsCounts,

    ) = _getDelegationDataByPower(_power);

    if (_from != address(0)) {
      uint256 previous = 0;
      uint256 fromCheckpointsCount = checkpointsCounts[_from];

      if (fromCheckpointsCount != 0) {
        previous = checkpoints[_from][fromCheckpointsCount - 1].votes;
      } else {
        previous = balanceOf(_from);
      }
      uint256 newVal = previous.sub(_amount);

      _writeCheckpoint(checkpoints, checkpointsCounts, _from, uint128(newVal));

      emit DelegatedPowerChanged(_from, newVal, _power);
    }
    if (_to != address(0)) {
      uint256 previous = 0;
      uint256 toCheckpointsCount = checkpointsCounts[_to];
      if (toCheckpointsCount != 0) {
        previous = checkpoints[_to][toCheckpointsCount - 1].votes;
      } else {
        previous = balanceOf(_to);
      }

      uint256 newVal = previous.add(_amount);

      _writeCheckpoint(checkpoints, checkpointsCounts, _to, uint128(newVal));

      emit DelegatedPowerChanged(_to, newVal, _power);
    }
  }

  /// @notice searches a checkpoint by block number. Uses binary search.
  /// @param _checkpoints the checkpoints mapping
  /// @param _checkpointsCounts the number of checkpoints
  /// @param _user the user for which the checkpoint is being searched
  /// @param _blockNumber the block number being searched
  function _searchByBlockNumber(
    mapping(address => mapping(uint256 => Checkpoint)) storage _checkpoints,
    mapping(address => uint256) storage _checkpointsCounts,
    address _user,
    uint256 _blockNumber
  ) internal view returns (uint256 checkpoint_) {
    require(
      _blockNumber <= block.number,
      'KibbleBase: _searchByBlockNumber: invalid block number'
    );

    uint256 checkpointsCount = _checkpointsCounts[_user];

    if (checkpointsCount == 0) {
      return balanceOf(_user);
    }

    // First check most recent balance
    if (_checkpoints[_user][checkpointsCount - 1].blockNumber <= _blockNumber) {
      return _checkpoints[_user][checkpointsCount - 1].votes;
    }

    // Next check implicit zero balance
    if (_checkpoints[_user][0].blockNumber > _blockNumber) {
      return 0;
    }

    uint256 lower = 0;
    uint256 upper = checkpointsCount - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory checkpoint = _checkpoints[_user][center];
      if (checkpoint.blockNumber == _blockNumber) {
        return checkpoint.votes;
      } else if (checkpoint.blockNumber < _blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }

    checkpoint_ = _checkpoints[_user][lower].votes;
  }

  /// @notice get delegation data by power
  /// @param _power the power querying by from
  function _getDelegationDataByPower(DelegationPower _power)
    internal
    view
    virtual
    returns (
      mapping(address => mapping(uint256 => Checkpoint)) storage, //checkpoint
      mapping(address => uint256) storage, //checkpoints count
      mapping(address => address) storage //delegatees list
    );

  /// @notice Writes a checkpoint for an owner of tokens
  /// @param _checkpoints the checkpoints mapping
  /// @param _checkpointsCounts the number of checkpoints
  /// @param _owner The owner of the tokens
  /// @param _value The value after the operation
  function _writeCheckpoint(
    mapping(address => mapping(uint256 => Checkpoint)) storage _checkpoints,
    mapping(address => uint256) storage _checkpointsCounts,
    address _owner,
    uint128 _value
  ) internal {
    uint128 currentBlock = uint128(block.number);

    uint256 ownerCheckpointsCount = _checkpointsCounts[_owner];
    mapping(uint256 => Checkpoint) storage checkpointsOwner = _checkpoints[
      _owner
    ];

    // Doing multiple operations in the same block
    if (
      ownerCheckpointsCount != 0 &&
      checkpointsOwner[ownerCheckpointsCount - 1].blockNumber == currentBlock
    ) {
      checkpointsOwner[ownerCheckpointsCount - 1].votes = _value;
    } else {
      checkpointsOwner[ownerCheckpointsCount] = Checkpoint(
        currentBlock,
        _value
      );
      _checkpointsCounts[_owner] = ownerCheckpointsCount + 1;
    }
  }

  /// @notice returns the user delegatee. If a user never performed any delegation,
  /// his delegated address will be 0x0. In that case we simply return the user itself
  /// @param _delegator the address of the user for which return the delegatee
  /// @param _delegates the array of delegates for a particular type of delegation
  function _getDelegatee(
    address _delegator,
    mapping(address => address) storage _delegates
  ) internal view returns (address delegtee_) {
    address previousDelegatee = _delegates[_delegator];

    delegtee_ = previousDelegatee == address(0)
      ? _delegator
      : previousDelegatee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

