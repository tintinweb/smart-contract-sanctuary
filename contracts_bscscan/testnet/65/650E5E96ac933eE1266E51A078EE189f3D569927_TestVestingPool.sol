// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;


/**
 * @title ZamzamVestingPool
 * @author Wibson Development Team <[email protected]>
 * @notice This contract models a pool of tokens to be distributed among beneficiaries
 * with different lock-up and vesting conditions. There is no need to know the
 * beneficiaries in advance, since the contract allows to add them as time goes by.
 * @dev There is only one method to add a beneficiary. By doing this, not only
 * both modes (lock-up and vesting) can be achieved, but they can also be combined
 * as suitable. Moreover, total funds and distributed tokens are controlled to
 * avoid refills done by transferring tokens through the ERC20.
 */
import './Claimable.sol';
import './TokenVesting.sol';
import './SafeERC20.sol';
import './SafeMath.sol';
contract TestVestingPool is Claimable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

  // ERC20 token being held
  ERC20Basic public token;

  // Maximum amount of tokens to be distributed
  uint256 public totalFunds;

  // Tokens already distributed
  uint256 public distributedTokens;

  // List of beneficiaries added to the pool
  address[] public beneficiaries;

  // Mapping of beneficiary to TokenVesting contracts addresses
  mapping(address => address[]) public beneficiaryDistributionContracts;

  // Tracks the distribution contracts created by this contract.
  mapping(address => bool) private distributionContracts;

  event BeneficiaryAdded(
    address indexed beneficiary,
    address vesting,
    uint256 amount
  );

  modifier validAddress(address _addr) {
    require(_addr != address(0));
    require(_addr != address(this));
    _;
  }

  /**
   * @notice Contract constructor.
   * @param _token instance of an ERC20 token.
   * @param _totalFunds Maximum amount of tokens to be distributed among
   *        beneficiaries.
   */
  constructor(
    ERC20Basic _token,
    uint256 _totalFunds
  ) public validAddress(_token) {
    require(_totalFunds > 0);

    token = _token;
    totalFunds = _totalFunds;
    distributedTokens = 0;
  }

  /**
   * @notice Assigns a token release point to a beneficiary. A beneficiary can have
   *         many token release points.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _amount amount of tokens to be released
   * @return address for the new TokenVesting contract instance.
   */
  function addBeneficiary(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _amount
  ) public onlyOwner validAddress(_beneficiary) returns (address) {
    require(_beneficiary != owner);
    require(_amount > 0);
    require(_duration >= _cliff);

    // Check there are sufficient funds and actual token balance.
    require(SafeMath.sub(totalFunds, distributedTokens) >= _amount);
    require(token.balanceOf(address(this)) >= _amount);

    if (!beneficiaryExists(_beneficiary)) {
      beneficiaries.push(_beneficiary);
    }

    // Bookkepping of distributed tokens
    distributedTokens = distributedTokens.add(_amount);

    address tokenVesting = new TokenVesting(
      _beneficiary,
      _start,
      _cliff,
      _duration,
      false // TokenVesting cannot be revoked
    );

    // Bookkeeping of distributions contracts per beneficiary
    beneficiaryDistributionContracts[_beneficiary].push(tokenVesting);
    distributionContracts[tokenVesting] = true;

    // Assign the tokens to the beneficiary
    token.safeTransfer(tokenVesting, _amount);

    emit BeneficiaryAdded(_beneficiary, tokenVesting, _amount);
    return tokenVesting;
  }

  /**
   * @notice Gets an array of all the distribution contracts for a given beneficiary.
   * @param _beneficiary address of the beneficiary to whom tokens will be transferred.
   * @return List of TokenVesting addresses.
   */
  function getDistributionContracts(
    address _beneficiary
  ) public view validAddress(_beneficiary) returns (address[]) {
    return beneficiaryDistributionContracts[_beneficiary];
  }

  /**
   * @notice Checks if a beneficiary was added to the pool at least once.
   * @param _beneficiary address of the beneficiary to whom tokens will be transferred.
   * @return true if beneficiary exists, false otherwise.
   */
  function beneficiaryExists(
    address _beneficiary
  ) internal view returns (bool) {
    return beneficiaryDistributionContracts[_beneficiary].length > 0;
  }
}