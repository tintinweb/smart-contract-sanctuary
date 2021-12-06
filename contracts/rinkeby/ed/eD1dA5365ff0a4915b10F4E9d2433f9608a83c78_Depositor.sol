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
    uint184 constant DEFAULT_ID = 0xe73798b6029EA3B2c51D09a50B53CA8012FeEB05bDa35A;
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
        _;
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
        payment.wad = 0;
        require(payment.version == VERSION, "version");
        require(sequencer.verifySequencer(payment.relayerId), "valid relayer");
        require(payable(msg.sender).send(payment.wad), "send");
    }
}



contract Depositor is Payable {
    constructor(ISequencer _sequencer, uint184 _id) {
        sequencer = _sequencer;
        payment.relayerId = _id;
        payment.version = VERSION;
    }

    mapping (address=>uint256) public balances;

    function deposit() public payable Payable {
        balances[msg.sender] += msg.value;
    }
}