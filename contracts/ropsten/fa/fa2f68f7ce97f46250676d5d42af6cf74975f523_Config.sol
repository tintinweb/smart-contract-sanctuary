pragma solidity 0.4.24;

/*
    Stores config data of forwarder so it will be same for all proxies.
*/
contract Config {
    address internal owner;

    function getConfig(bytes32 slot) public view returns (bytes32 res) {
        assembly {
            res := sload(slot)
        }
    }

    function getAddress(bytes32 slot) public view returns(address res)  {
        assembly {
            res := sload(slot)
        }
    }

    function getUint(bytes32 slot) public view returns(uint256 res) {
        assembly {
            res := sload(slot)
        }
    }

    function addConfig(bytes32 slot, bytes32 value) public {
        require (msg.sender == owner);
        require (slot != 0x0);  // Don&#39;t allow to set owner using addConfig function to avoid not intendet behaviour.
        assembly {
            sstore(slot, value)
        }
    }

    /* Function allows to set new owner.
       During first call (when owner is not yet set) anyone can set it. Later only current owner can set new one.
     */
    function setOwner(address _owner) public {
        require (msg.sender == owner || owner == address(0x0));
        owner = _owner;
    }
}