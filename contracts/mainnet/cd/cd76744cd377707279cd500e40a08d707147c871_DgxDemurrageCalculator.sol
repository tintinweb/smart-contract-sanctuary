pragma solidity ^0.4.19;

contract TokenInformation {
  function showDemurrageConfigs() public constant returns (uint256 _base, uint256 _rate, address _collector, bool _no_demurrage_fee);
}

/// @title Digix Gold Token Demurrage Calculator
/// @author Digix Holdings Pte Ltd
/// @notice This contract is meant to be used by exchanges/other parties who want to calculate the DGX demurrage fees, provided an initial balance and the days elapsed
contract DgxDemurrageCalculator {
  address public TOKEN_ADDRESS;
  address public TOKEN_INFORMATION_ADDRESS;

  function token_information() internal view returns (TokenInformation _token_information) {
    _token_information = TokenInformation(TOKEN_INFORMATION_ADDRESS);
  }

  function DgxDemurrageCalculator(address _token_address, address _token_information_address) public {
    TOKEN_ADDRESS = _token_address;
    TOKEN_INFORMATION_ADDRESS = _token_information_address;
  }

  function calculateDemurrage(uint256 _initial_balance, uint256 _days_elapsed)
           public
           view
           returns (uint256 _demurrage_fees, bool _no_demurrage_fees)
  {
    uint256 _base;
    uint256 _rate;
    (_base, _rate,,_no_demurrage_fees) = token_information().showDemurrageConfigs();
    _demurrage_fees = (_initial_balance * _days_elapsed * _rate) / _base;
  }
}