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
 * and also executes changes in other contracts that the LOTT.LINK Governance decides.
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
     * @dev holding one-to-one assignments.
     */
    mapping(bytes32 => bool) bytes32ToBool;
    mapping(bytes32 => uint) bytes32ToUint;
    mapping(bytes32 => int) bytes32ToInt;
    mapping(bytes32 => address) bytes32ToAddress;
    mapping(bytes32 => string) bytes32ToString;
    mapping(bytes32 => bytes) bytes32ToBytes;


    /**
     * @dev emits when a one-to-one variable is assigned or removed.
     */
    event Set(bytes32 tag, bool data);
    event Set(bytes32 tag, uint data);
    event Set(bytes32 tag, int data);
    event Set(bytes32 tag, address data);
    event Set(bytes32 tag, string data);
    event Set(bytes32 tag, bytes data);

    /**
     * @dev emits when DAO calls a `contractAddr` successfully.
     */
    event Call(address contractAddr, bytes inputData, bytes callBackData);


    /**
     * @dev returns any `data` assigned to a `tag`.
     */
    function getBool(bytes32 tag) external view returns(bool data) {
        return bytes32ToBool[tag];
    }
    function getUint(bytes32 tag) external view returns(uint data) {
        return bytes32ToUint[tag];
    }
    function getInt(bytes32 tag) external view returns(int data) {
        return bytes32ToInt[tag];
    }
    function getAddress(bytes32 tag) external view returns(address data) {
        return bytes32ToAddress[tag];
    }
    function getString(bytes32 tag) external view returns(string memory data) {
        return bytes32ToString[tag];
    }
    function getBytes(bytes32 tag) external view returns(bytes memory data) {
        return bytes32ToBytes[tag];
    }


    /**
     * @dev assign `data` to a `tag` decided by the governance.
     */
    function set(bytes32 tag, bool data) external onlyGov {
        bytes32ToBool[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, uint data) external onlyGov {
        bytes32ToUint[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, int data) external onlyGov {
        bytes32ToInt[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, address data) external onlyGov {
        bytes32ToAddress[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, string memory data) external onlyGov {
        bytes32ToString[tag] = data;
        emit Set(tag, data);
    }
    function set(bytes32 tag, bytes memory data) external onlyGov {
        bytes32ToBytes[tag] = data;
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