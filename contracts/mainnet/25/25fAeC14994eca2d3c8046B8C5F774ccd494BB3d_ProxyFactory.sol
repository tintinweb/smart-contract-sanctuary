// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

contract ProxyFactory {
    /// @dev See comment below for explanation of the proxy INIT_CODE
    bytes private constant INIT_CODE =
        hex'604080600a3d393df3fe'
        hex'7300000000000000000000000000000000000000003d36602557'
        hex'3d3d3d3d34865af1603156'
        hex'5b363d3d373d3d363d855af4'
        hex'5b3d82803e603c573d81fd5b3d81f3';
    /// @dev The main address that the deployed proxies will forward to.
    address payable public immutable mainAddress;

    constructor(address payable addr) public {
        require(addr != address(0), '0x0 is an invalid address');
        mainAddress = addr;
    }

    /**
     * @dev This deploys an extremely minimalist proxy contract with the
     * mainAddress embedded within.
     * Note: The bytecode is explained in comments below this contract.
     * @return dst The new contract address.
     */
    function deployNewInstance(bytes32 salt) external returns (address dst) {
        // copy init code into memory
        // and immutable ExchangeDeposit address onto stack
        bytes memory initCodeMem = INIT_CODE;
        address payable addrStack = mainAddress;
        assembly {
            // Get the position of the start of init code
            let pos := add(initCodeMem, 0x20)
            // grab the first 32 bytes
            let first32 := mload(pos)
            // shift the address bytes 8 bits left
            let addrBytesShifted := shl(8, addrStack)
            // bitwise OR them and add the address into the init code memory
            mstore(pos, or(first32, addrBytesShifted))
            // create the contract
            dst := create2(
                0, // Send no value to the contract
                pos, // Deploy code starts at pos
                74, // Deploy + runtime code is 74 bytes
                salt // 32 byte salt
            )
            // revert if failed
            if eq(dst, 0) {
                revert(0, 0)
            }
        }
    }
}

/*
    // PROXY CONTRACT EXPLANATION

    // DEPLOY CODE (will not be returned by web3.eth.getCode())
    // STORE CONTRACT CODE IN MEMORY, THEN RETURN IT
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    00  |  6040  |  PUSH1 0x40       |  0x40                                |
    02  |  80    |  DUP1             |  0x40 0x40                           |
    03  |  600a  |  PUSH1 0x0a       |  0x0a 0x40 0x40                      |
    05  |  3d    |  RETURNDATASIZE   |  0x0 0x0a 0x40 0x40                  |
    06  |  39    |  CODECOPY         |  0x40                                |
    07  |  3d    |  RETURNDATASIZE   |  0x0 0x40                            |
    08  |  f3    |  RETURN           |                                      |

    09  |  fe    |  INVALID          |                                      |

    // START CONTRACT CODE

    // Push the ExchangeDeposit address on the stack for DUPing later
    // Also pushing a 0x0 for DUPing later. (saves runtime AND deploy gas)
    // Then use the calldata size as the decider for whether to jump or not
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    00  |  73... |  PUSH20 ...       |  {ADDR}                              |
    15  |  3d    |  RETURNDATASIZE   |  0x0 {ADDR}                          |
    16  |  36    |  CALLDATASIZE     |  CDS 0x0 {ADDR}                      |
    17  |  6025  |  PUSH1 0x25       |  0x25 CDS 0x0 {ADDR}                 |
    19  |  57    |  JUMPI            |  0x0 {ADDR}                          |

    // If msg.data length === 0, CALL into address
    // This way, the proxy contract address becomes msg.sender and we can use
    // msg.sender in the Deposit Event
    // This also gives us access to our ExchangeDeposit storage (for forwarding address)
    POS | OPCODE |  OPCODE TEXT      |  STACK                                       |
    1A  |  3d    |  RETURNDATASIZE   |  0x0 0x0 {ADDR}                              |
    1B  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 {ADDR}                          |
    1C  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 0x0 {ADDR}                      |
    1D  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 0x0 0x0 {ADDR}                  |
    1E  |  34    |  CALLVALUE        |  VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR}            |
    1F  |  86    |  DUP7             |  {ADDR} VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR}     |
    20  |  5a    |  GAS              |  GAS {ADDR} VALUE 0x0 0x0 0x0 0x0 0x0 {ADDR} |
    21  |  f1    |  CALL             |  {RES} 0x0 {ADDR}                            |
    22  |  6031  |  PUSH1 0x31       |  0x31 {RES} 0x0 {ADDR}                       |
    24  |  56    |  JUMP             |  {RES} 0x0 {ADDR}                            |

    // If msg.data length > 0, DELEGATECALL into address
    // This will allow us to call gatherErc20 using the context of the proxy
    // address itself.
    POS | OPCODE |  OPCODE TEXT      |  STACK                                 |
    25  |  5b    |  JUMPDEST         |  0x0 {ADDR}                            |
    26  |  36    |  CALLDATASIZE     |  CDS 0x0 {ADDR}                        |
    27  |  3d    |  RETURNDATASIZE   |  0x0 CDS 0x0 {ADDR}                    |
    28  |  3d    |  RETURNDATASIZE   |  0x0 0x0 CDS 0x0 {ADDR}                |
    29  |  37    |  CALLDATACOPY     |  0x0 {ADDR}                            |
    2A  |  3d    |  RETURNDATASIZE   |  0x0 0x0 {ADDR}                        |
    2B  |  3d    |  RETURNDATASIZE   |  0x0 0x0 0x0 {ADDR}                    |
    2C  |  36    |  CALLDATASIZE     |  CDS 0x0 0x0 0x0 {ADDR}                |
    2D  |  3d    |  RETURNDATASIZE   |  0x0 CDS 0x0 0x0 0x0 {ADDR}            |
    2E  |  85    |  DUP6             |  {ADDR} 0x0 CDS 0x0 0x0 0x0 {ADDR}     |
    2F  |  5a    |  GAS              |  GAS {ADDR} 0x0 CDS 0x0 0x0 0x0 {ADDR} |
    30  |  f4    |  DELEGATECALL     |  {RES} 0x0 {ADDR}                      |

    // We take the result of the call, load in the returndata,
    // If call result == 0, failure, revert
    // else success, return
    POS | OPCODE |  OPCODE TEXT      |  STACK                               |
    31  |  5b    |  JUMPDEST         |  {RES} 0x0 {ADDR}                    |
    32  |  3d    |  RETURNDATASIZE   |  RDS {RES} 0x0 {ADDR}                |
    33  |  82    |  DUP3             |  0x0 RDS {RES} 0x0 {ADDR}            |
    34  |  80    |  DUP1             |  0x0 0x0 RDS {RES} 0x0 {ADDR}        |
    35  |  3e    |  RETURNDATACOPY   |  {RES} 0x0 {ADDR}                    |
    36  |  603c  |  PUSH1 0x3c       |  0x3c {RES} 0x0 {ADDR}               |
    38  |  57    |  JUMPI            |  0x0 {ADDR}                          |
    39  |  3d    |  RETURNDATASIZE   |  RDS 0x0 {ADDR}                      |
    3A  |  81    |  DUP2             |  0x0 RDS 0x0 {ADDR}                  |
    3B  |  fd    |  REVERT           |  0x0 {ADDR}                          |
    3C  |  5b    |  JUMPDEST         |  0x0 {ADDR}                          |
    3D  |  3d    |  RETURNDATASIZE   |  RDS 0x0 {ADDR}                      |
    3E  |  81    |  DUP2             |  0x0 RDS 0x0 {ADDR}                  |
    3F  |  f3    |  RETURN           |  0x0 {ADDR}                          |
*/