pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../lib/SafeERC20.sol";
import "../lib/SafeMath.sol";
import {VELOTokenInterface as IVELO} from "../token/VELOTokenInterface.sol";
import { ABDKMath64x64 as fp } from "../lib/ABDKMath64x64.sol";

contract VELORebaser {
  using SafeMath for uint256;
  using fp for int128;

  uint256 public lastRebase;

  uint256 public REBASE_INTERVAL;
  uint256 public START_REBASE_AT;

  uint256 public constant C =  1618033988700000000;
  uint256 public constant K = 15000000000000000000;

  uint256 public constant Ls =   64410000000000000;  // 0.07613 Slow EMA
  uint256 public constant Lf =   76130000000000000;  // 0.06441 Fast EMA

  uint256 public sEMA;
  uint256 public fEMA;

  uint256 public velocity;

  uint256 public constant PRECISION = 10**18;

  address public VELO;

  /// @notice Governance address
  address public gov;

  // Stable ordering is not guaranteed.
  Transaction[] public transactions;

  // TODO rebase events

  struct Transaction {
    address destination;
    bytes data;
  }

  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  modifier onlyVELO() {
    require(msg.sender == VELO, "!velo");
    _;
  }

  constructor(
    address _VELO,
    uint256 _rebase_interval,
    uint256 _start_rebase_at
  ) public {
    VELO = _VELO;
    gov = msg.sender;
    REBASE_INTERVAL = _rebase_interval;
    START_REBASE_AT = _start_rebase_at;
  }

  function setGov(address newGov) external onlyGov {
    gov = newGov;
  }

  function addTransaction(address destination, bytes memory data) public onlyGov {
    transactions.push(Transaction({
      destination: destination,
      data: data
    }));
  }

  function removeTransaction(uint256 index) external onlyGov {
    transactions[index] = transactions[transactions.length];
    transactions.pop();
  }

  function registerVelocity(uint256 amount) external onlyVELO {
    velocity = velocity.add(amount);
  }

  // returns velocity in scaled units
  function getVelocity() external view returns (uint256) {
    return velocity;
  }

  function getRelativeVelocity() external view returns (uint256) {
    IVELO velo_token = IVELO(VELO);

    // calculate the Vt, an limit the ranges
    uint256 Vt = velocity.mul(100 * PRECISION).div(velo_token.totalSupply());
    if(Vt > 100 * PRECISION ) {
      Vt = 100 * PRECISION;
    }

    return Vt;
  }


  function calcEMA(uint256 Vt_1, uint256 Vt, uint256 L) private pure returns(uint256) {
    return  (Vt * L) / PRECISION  + ((PRECISION - L) * Vt_1) / PRECISION;
  }

  function rebase() public {
    require(block.timestamp >= START_REBASE_AT, "Rebase not allowed yet");
    require(block.timestamp - lastRebase >= REBASE_INTERVAL, "Rebase interval not exceeded");

    // NOTE: why do we need this to be an actiual person?
    require(msg.sender == tx.origin, "!eoa");

    IVELO velo_token = IVELO(VELO);

    // calculate the Vt, an limit the ranges
    uint256 Vt = this.getRelativeVelocity();

    fEMA = calcEMA(fEMA, Vt, Lf);
    sEMA = calcEMA(sEMA, Vt, Ls);

    uint256 scaling_modifier = calcFTFixed(fEMA, sEMA, C, K);

    scaling_modifier = PRECISION.mul(PRECISION).div(scaling_modifier);

    // scale our supply according to formula
    velo_token.rebase(scaling_modifier);

    lastRebase = block.timestamp;

    // reset the velocity so we can track
    // the velocity for the next epoch
    velocity = 0;

    _afterRebase();
  }

  function _afterRebase() internal {
    for(uint256 i = 0; i < transactions.length; i ++) {
      Transaction memory transaction = transactions[i];            
      // Failed transactions should be ignored
      transaction.destination.call(transaction.data);
    }
  }

  function toFP(int256 _value) public pure returns (int128) {
    return fp.fromInt(_value);
  }

  function toInt(int128 _value) public pure returns (int256) {
    return fp.muli(_value, int256(PRECISION));
  }

  function op_nv1t_plus_v2t_v(uint256 _v1t, uint256 _v2t) public pure returns (int128) {
    require(_v1t < 2**255 - 1, "_v1t must be smaller than max int256");
    require(_v2t < 2**255 - 1, "_v2t must be smaller than max int256");

    int128 MINUS_ONE = fp.fromInt(-1);

    int128 v1t = fp.divu(_v1t, PRECISION);
    int128 v2t = fp.divu(_v2t, PRECISION);

    return v1t.mul(MINUS_ONE).add(v2t);
  }

  function op_div_k_v(int128 _op_nv1t_plus_v2t_v, uint256 _k) public pure returns(int128) {
    require(_k < 2**255 - 1, "_k must be smaller than int256");

    int128 k = fp.divu(_k, PRECISION);

    return fp.div(_op_nv1t_plus_v2t_v, k);
  }

  function op_e_pow_v(int128 _op_div_k_v) public pure returns(int128) {
    return fp.exp(_op_div_k_v);
  }

  function op_one_plus_v(int128 _op_e_pow_v) public pure returns(int128) {
    return fp.fromUInt(1).add(_op_e_pow_v);
  }

  function op_div_v(int128 _op_one_plus_v) public pure returns(int128) {
    return fp.fromUInt(1).div(_op_one_plus_v);
  }

  //     let op_n_plus_v = -0.5_f64 + op_div_v;
  function op_n_plus_v(int128 _op_div_v) public pure returns(int128) {
    return fp.divi(1, -2).add(_op_div_v);
  }


  // let op_c_mul_v = c * op_n_plus_v;
  function op_c_mul_v(uint256 _c, int128 _op_n_plus_v) public pure returns(int128) {
    require(_c < 2**255 - 1, "_c must be smaller than max int256");
    int128 c = fp.divu(_c, PRECISION);

    return fp.mul(c, _op_n_plus_v);
  }

  //     let op_rt_v = 1_f64 + op_c_mul_v;
  function op_rt_v(int128 _op_c_mul_v) public pure returns(int128) {
    return fp.fromUInt(1).add(_op_c_mul_v);
  }


  function calcFTFixed(uint256 _v1t, uint256 _v2t, uint256 _c, uint256 _k) public pure returns (uint256) {
    int128 op_nv1t_plus_v2t_v_ = op_nv1t_plus_v2t_v(_v1t, _v2t);
    int128 op_div_k_v_ = op_div_k_v(op_nv1t_plus_v2t_v_, _k);
    int128 op_e_pow_v_ = op_e_pow_v(op_div_k_v_);
    int128 op_one_plus_v_ = op_one_plus_v(op_e_pow_v_);
    int128 op_div_v_ = op_div_v(op_one_plus_v_);
    int128 op_n_plus_v_ = op_n_plus_v(op_div_v_);
    int128 op_c_mul_v_ = op_c_mul_v(_c, op_n_plus_v_);
    int128 op_rt_v_ = op_rt_v(op_c_mul_v_);

    return fp.mulu(op_rt_v_, PRECISION);
  }

}
