/**
 *Submitted for verification at snowtrace.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract AdminContract {
  struct TokenFactors {
    uint16 borrowFactor;
    uint16 collateralFactor;
    uint16 liqIncentive;
  }

  struct CreditLimit {
    address user;
    address token;
    uint limit;
  }

  function initialize(
    address _stable,
    address _oracle,
    address _governor,
    uint _mintFeeBps,
    uint _burnFeeBps,
    string memory _baseSymbol
  ) external {}

  function initialize(
    address _stable,
    address _router,
    address _governor
  ) external {}

  function initialize(
    address _stable,
    address _router,
    address _governor,
    address _lendingPool
  ) external {}

  function initialize(address _oracle, uint _feeBps) external {}

  function setPendingGovernor(address _nextPendingGovernor) external {}

  function acceptGovernor() external {}

  function setFeeWorker(address _feeWorker) external {}

  function setXWorker(address _xWorker) external {}

  function setFees(uint _mintFeeBps, uint _burnFeeBps) external {}

  function withdrawFee(uint _amount) external {}

  function setWhitelistXBanks(address[] calldata _xBanks, bool[] calldata _statuses) external {}

  function createLL(uint _ll) external {}

  function createSS(uint _ss) external {}

  function setPrimarySources(
    address _token,
    uint _maxPriceDeviation,
    address[] memory _sources
  ) external {}

  function setMultiPrimarySources(
    address[] memory _tokens,
    uint[] memory _maxPriceDeviationList,
    address[][] memory _allSources
  ) external {}

  function setSymbols(address[] memory _tokens, string[] memory _syms) external {}

  function setRef(address _ref) external {}

  function setMaxDelayTimes(address[] calldata _tokens, uint[] calldata _maxDelays) external {}

  function setRefETHUSD(address _refETHUSD) external {}

  function setRefsETH(address[] calldata _tokens, address[] calldata _refs) external {}

  function setRefsUSD(address[] calldata _tokens, address[] calldata _refs) external {}

  function setRoute(address[] calldata _tokens, address[] calldata _targets) external {}

  function setRedirects(address[] calldata _routes, address[] calldata _newRoutes) external {}

  function unsetTokenFactors(address[] memory _tokens) external {}

  function setTokenFactors(address[] memory _tokens, TokenFactors[] memory _tokenFactors)
    external
  {}

  function setWhitelistERC1155(address[] memory _tokens, bool _ok) external {}

  function setWhitelistLPTokens(address[] calldata _lpTokens, bool[] calldata _statuses) external {}

  function setAllowContractCalls(bool _ok) external {}

  function setWhitelistSpells(address[] calldata _spells, bool[] calldata _statuses) external {}

  function setWhitelistTokens(address[] calldata _tokens, bool[] calldata _statuses) external {}

  function setWhitelistUsers(address[] calldata _users, bool[] calldata _statuses) external {}

  function setWorker(address _worker) external {}

  function setBankStatus(uint _bankStatus) external {}

  function addBank(address token, address cToken) external {}

  function setOracle(address _oracle) external {}

  function setFeeBps(uint _feeBps) external {}

  function withdrawReserve(address token, uint amount) external {}

  function setCreditLimits(CreditLimit[] calldata _creditLimits) external {}
}