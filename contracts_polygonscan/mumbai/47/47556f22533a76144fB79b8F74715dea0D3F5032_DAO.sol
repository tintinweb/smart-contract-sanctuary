// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ============================ TEST_1.0.6 ==============================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

/**
 * @dev this contract is source of every types of variables used by LOTT.LINK Ecosystem
 * and also executes changes that the LOTT.LINK Governance decides.
 */

contract DAO {

    /**
    * @dev DAOInit eternal address on MATIC MUMBAI testnet.
    */
    address immutable DAOInit = 0x245cAa689Fa16ab50DF4e8ab48555715877F79fF;

    /**
     * @dev Restrict access to the Governance of LOTT.LINK Ecosystem.
     */
    modifier onlyGov() {
        (bool success, bytes memory data) = DAOInit.staticcall(abi.encodeWithSignature("gov()"));
        require(success && msg.sender == abi.decode(data, (address)));
        _;
    }

    /**
    * @dev holding valid addresses.
    */
    mapping (bytes32 => mapping(address => bool)) whiteLists;

    /**
    * @dev holding one-to-one assignments.
    */
    mapping (bytes32 => bool) varsBoolean;
    mapping (bytes32 => uint256) varsUint256;
    mapping (bytes32 => address) varsAddress;
    mapping (bytes32 => string) varsString;
    mapping (bytes32 => bytes) varsBytes;


    /**
    * @dev emits when an address has been added to or omited from a whiteList.
    */
    event Set(bytes32 tag, address addr, bool validity);

    /**
    * @dev emits when a one-to-one variable assignes or removes.
    */
    event Set(bytes32 tag, bool data);
    event Set(bytes32 tag, uint256 data);
    event Set(bytes32 tag, address data);
    event Set(bytes32 tag, string data);
    event Set(bytes32 tag, bytes data);

    /**
    * @dev emits when DAO calls a `contractAddr` successfully.
    */
    event Call(address contractAddr, bytes inputData, bytes callBackData);


    /**
    * @dev returns true if `addr` is valid in the whiteList.
    */
    function check(bytes32 tag, address addr) external view returns(bool validity) {
        return whiteLists[tag][addr];
    }


    /**
    * @dev returns any `data` assigned to a `tag`.
    */
    function getBoolean(bytes32 tag) external view returns(bool data) {
        return varsBoolean[tag];
    }
    function getUint256(bytes32 tag) external view returns(uint256 data) {
        return varsUint256[tag];
    }
    function getAddress(bytes32 tag) external view returns(address data) {
        return varsAddress[tag];
    }
    function getString(bytes32 tag) external view returns(string memory data) {
        return varsString[tag];
    }
    function getBytes(bytes32 tag) external view returns(bytes memory data) {
        return varsBytes[tag];
    }



    /**
    * @dev add the `addr` to or remove it from the whiteList marked as `tag`.(decided by the governance).
    */
    function set(bytes32 tag, address addr, bool validity)
        external
        onlyGov 
    {
        whiteLists[tag][addr] = validity;
        emit Set(tag, addr, validity);
    }

    /**
    * @dev assign `data` to a `tag` decided by the governance.
    */
    function set(bytes32 tag, bool data) external onlyGov {
        varsBoolean[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, uint256 data) external onlyGov {
        varsUint256[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, address data) external onlyGov {
        varsAddress[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, string memory data) external onlyGov {
        varsString[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, bytes memory data) external onlyGov {
        varsBytes[tag] = data;
        emit Set(tag, data);
    }


    /**
    * @dev call any data to any smart contract decided by the gov.
    */
    function call(address contractAddr, bytes memory inputData)
        external
        onlyGov
        returns(bytes memory callBackData) 
    {
        (bool success, bytes memory _callBackData) = contractAddr.call(inputData);
        require(success, "call failed.");
        emit Call(contractAddr, inputData, _callBackData);
        return _callBackData;
    }
}