// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IOracle } from "./interfaces/IOracle.sol";

contract VesqOracle is IOracle {
  IOracle public orcle;
  uint256 constant PRICISION = 1E9;
  constructor (address orcl_) {
    orcle = IOracle(orcl_);
    assert(orcle.query() != 0);
  }

  function token() public view override returns(address ) {
    return orcle.token();
  }

  function query() public view override returns (uint256){
    uint256 price = orcle.query();
    return price/PRICISION;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IOracle {
	function token() external view returns (address token_);

	function query() external view returns (uint256 price_);
}