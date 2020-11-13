pragma solidity 0.5.17;

import "../lib/ICHI.sol";
import {VELOTokenInterface as IVELO} from "../token/VELOTokenInterface.sol";

contract VELOFeeCharger {

  ICHI public constant chi = ICHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
  IVELO public velo;

  uint256 public govFactor;
  address public gov;
  address public beneficiary;

  uint256 public max_gas_block;
  uint256 public min_gas_tx;
  uint256 public gov_fee_factor;

  uint256 public last_block_number;
  uint256 public chi_fee_remaining;

  function setMaxGasBlock(uint256 value) public {
    max_gas_block = value;
  }

  function setMinGasTx(uint256 value) public {
    min_gas_tx = value;
  }

  function setGovFeeFactor(uint256 value) public {
    gov_fee_factor = value;
  }

  modifier onlyGov() {
    require(msg.sender == gov, "!gov");
    _;
  }

  constructor(address velo_) public {
    velo	   = IVELO(velo_);

    // government levers
    gov            = msg.sender;
    gov_fee_factor = 1 * 10**18;
    max_gas_block  = 135 * 10**18;
    min_gas_tx     = 2 * 10**18;

    // tracking amount of chi charged
    // in a block.
    last_block_number = 0;
    chi_fee_remaining = 0;

  }

  function setGov(address newGov) external onlyGov {
    gov = newGov;
  }

  function setGovFactor(uint256 factor) external onlyGov {
    govFactor = factor;
  }

  function setBeneficiary(address beneficiary_) external onlyGov {
    beneficiary = beneficiary_;
  }

  function chargeFee(uint256 fEMA, uint256 sEMA, uint256 totalSupply, uint256 _amount) public {
    uint256 chi_fee = 
      calc_fee_gas(max_gas_block, min_gas_tx, sEMA, _amount, totalSupply, gov_fee_factor);

    // count total amount of chi charges within a block. If the current
    // chi_fee charged in a block overflows the max_gas_block it will be
    // discounted to exactly max_gas_block
    if(last_block_number == block.number) {
      // protect against overflow
      if (chi_fee_remaining < chi_fee) {
	chi_fee = chi_fee_remaining;
      }
      chi_fee_remaining = chi_fee_remaining - chi_fee;
    } else {
      last_block_number = block.number;
      // the chi_fee can be maximal max_gas_block, limited
      // in the calc_fee_gas function. So no safe math needed
      // here.
      chi_fee_remaining = max_gas_block - chi_fee;
    }

    // velo token will only allow max_gas_block to be charged
    // we will not charge for transactions exceeding the max_gas_block
    // as we do not want transactions to fail because of the minting.
    if (chi_fee > 0 && beneficiary != address(0x0)) {
      // chi.mint needs tokens as a unit
      chi.mint(chi_fee / 10**18);
      chi.transfer(beneficiary, chi.balanceOf(address(this)));
    }
  }

  function calc_fee_ratio_discrete(
    uint256 ema1_vt,
    uint256 ema2_vt,
    uint256 tx_size,
    uint256 total_supply,
    uint256 _gov_fee_factor
  ) internal pure returns (uint256) {
    uint256 tx_discount_factor = ema2_vt;

    uint256 tx_fee_ratio = 10 * 10**18;

    if(tx_size <= total_supply / 596) {
      tx_fee_ratio = 6;
    } else if(tx_size <= total_supply / 369) {
      tx_fee_ratio = 9;
    } else if(tx_size <= total_supply / 228) {
      tx_fee_ratio = 15;
    } else if(tx_size <= total_supply / 141) {
      tx_fee_ratio = 23;
    } else if(tx_size <= total_supply / 87) {
      tx_fee_ratio = 37;
    } else if(tx_size <= total_supply / 54) {
      tx_fee_ratio = 55;
    } else if(tx_size <= total_supply / 33) {
      tx_fee_ratio = 76;
    } else if(tx_size <= total_supply / 21) {
      tx_fee_ratio = 92;
    } else if(tx_size <= total_supply / 13) {
      tx_fee_ratio = 98;
    } else if(tx_size <= total_supply / 6) {
      tx_fee_ratio = 99;
    } else {
      tx_fee_ratio = 100;
    }

    return ((tx_fee_ratio * tx_discount_factor / 100) * _gov_fee_factor)
    / 10**18;
  }

  // NOTE: we return and unscaled integer between roughly
  //       8 and 135 to approximate the gas fee for the
  //       velocity transaction
  function calc_fee_gas(
    uint256 max_gas_block,
    uint256 min_gas_tx,
    uint256 ema_long,
    uint256 tx_size,
    uint256 total_supply,
    uint256 _gov_fee_factor
  ) public pure returns (uint256) {
    uint256 max_gas_chi_per_block = max_gas_block;
    uint256 min_gas_chi_fee_per_tx = min_gas_tx;

    uint256 tx_fee_ratio_disc =
      calc_fee_ratio_discrete(0, ema_long, tx_size, total_supply, _gov_fee_factor);

    uint256 tx_fee_chi_disc =
      max_gas_chi_per_block * tx_fee_ratio_disc / 100 / 10**18;

    if ( tx_fee_chi_disc < min_gas_chi_fee_per_tx ) {
      tx_fee_chi_disc = min_gas_chi_fee_per_tx;
    }

    return tx_fee_chi_disc;
  }
}
