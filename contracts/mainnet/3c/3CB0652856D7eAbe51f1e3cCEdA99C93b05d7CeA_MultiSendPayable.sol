// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;


interface ISequencer {
  function verifySequencer(uint184 id) external returns(bool);
}


/*
 * @title payment support for sequencer
 */
abstract contract Payable {
    /*
     * constants
     */
    uint8 constant VERSION = 2;
    uint184 constant DEFAULT_ID = 0xe7379809afae029d38b76a330a1bdee84f6e03a4979359;
    struct Payment {
        uint184 relayerId;
        uint64 wad;
        uint8 version;
    }


    /*
     * storage
     */
    Payment payment;
    ISequencer sequencer;

    /*
     * functions
     */
    modifier Payable() {
        if (payment.version < VERSION) {
            payment.version = VERSION;
            payment.wad = 0;
            payment.relayerId = DEFAULT_ID;
        }

        uint used = gasleft();

        _;

        used = used - gasleft();
        unchecked {
            payment.wad += uint64(used * tx.gasprice);
        }
    }


    fallback () external Payable {
        assembly {
          mstore(0, sload(0))
          return(0, 32)
        }
    }


    /*
     * @notice verify relayer and claim reward
     */
    function claim() public {
        require(payment.version == VERSION, "version");
        require(sequencer.verifySequencer(payment.relayerId), "valid relayer");
        require(payable(msg.sender).send(payment.wad), "send");
        payment.wad = 0;
    }
}



/*
 * @title Multi Send - Allows to batch multiple transactions into one
 */
contract MultiSendPayable is Payable {
    constructor(ISequencer _sequencer, uint184 _id) {
        sequencer = _sequencer;
        payment.relayerId = _id;
        payment.version = VERSION;
    }

    /*
     * @notice Sends multiple transactions and reverts all if one fails.
     * @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
     *                     operation has to be uint8(0) in this version (=> 1 byte),
     *                     to as a address (=> 20 bytes),
     *                     value as a uint256 (=> 32 bytes),
     *                     data length as a uint256 (=> 32 bytes),
     *                     data as bytes.
     *                     see abi.encodePacked for more information on packed encoding
     */
    function multiSend(bytes memory transactions) public payable Payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                    case 0 {
                        success := call(gas(), to, value, data, dataLength, 0, 0)
                    }
                    case 1 {
                        success := delegatecall(gas(), to, data, dataLength, 0, 0)
                    }
                if eq(success, 0) {
                    revert(0, 0)
                }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }
}