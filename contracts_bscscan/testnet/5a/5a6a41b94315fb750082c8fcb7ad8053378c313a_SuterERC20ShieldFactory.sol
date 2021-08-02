// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SuterERC20.sol";

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

contract SuterERC20ShieldFactory {
  using Address for address;
  // The default fee is 1 ETH
  uint256 public fee = 1 ether;
  address payable public feeTo;
  address public feeToSetter;
  // address  _transfer = address(0x4f619759Faa3D78e199271334BBAd5474A64aDFC);
  // address _burn = address(0xF6551A07361e14dEEcA94B3Dcfe4dDDFeF8bd2d6);
  address public transfer;
  address public burn;
  // key is token contract address, value is suter shield contract address
  mapping(address => address) public getPool;
  mapping(address => address) public getCoin;
  address[] public allPools;
  address [] public allCoins;

  event PoolCreated(address indexed token0, address indexed pool, uint);

  constructor(address payable _feeTo, address _feeToSetter, address _transfer, address _burn) public {
    transfer = _transfer;
    burn = _burn;
    feeTo = _feeTo;
    feeToSetter = _feeToSetter;
  }

  function allPoolsLength() external view returns (uint) {
    return allPools.length;
  }

  function setFee(uint256 _fee) external {
    require(msg.sender == feeToSetter, 'SuterShieldFactory: FORBIDDEN');
    fee = _fee;
  }

  function setFeeTo(address payable _feeTo) external {
    require(msg.sender == feeToSetter, 'SuterShieldFactory: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter, 'SuterShieldFactory: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }

  function setTransfer(address _transfer) external{
    require(msg.sender == feeToSetter, 'SuterShieldFactory: FORBIDDEN');
    transfer = _transfer;
  }

  function setBurn(address _burn) external {
    burn = _burn;
  }

  function createPool(address token, uint256 unit) payable external returns (address pool) {
    require(token != address(0), 'SuterShieldFactory: ZERO_ADDRESS');
    require(address(token).isContract(), "SuterShieldFactory: call to non-contract");
    require(getPool[token] == address(0), 'SuterShieldFactory: This pool already exists.');
    require(msg.value >= fee, "Not enough fee to create the pool.");
    feeTo.transfer(fee);
    bytes memory bytecode = type(SuterERC20).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token));
    assembly {
      pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    SuterERC20(pool).initialize(token, unit, transfer, burn, feeTo);
    getPool[token] = pool;
    getCoin[pool] = token;
    allPools.push(pool);
    allCoins.push(token);
    emit PoolCreated(token, pool, allPools.length);
  }

  function initPool(address token, address pool) external {
    require(msg.sender == feeToSetter, 'SuterShieldFactory: FORBIDDEN');
    require(getPool[token] == address(0), 'SuterShieldFactory: This pool already exists.');
    getPool[token] = pool;
    getCoin[pool] = token;
    allPools.push(pool);
    allCoins.push(token);
  }
}