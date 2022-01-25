/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/proxy/Base.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Base {
    constructor () public {

    }

    //0x20 - length
    //0x53c6eaee8696e4c5200d3d231b29cc6a40b3893a5ae1536b0ac08212ffada877
    bytes constant notFoundMark = abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("404-method-not-found")))))));


    //return the payload of returnData, stripe the leading length
    function returnAsm(bool isRevert, bytes memory returnData) pure internal {
        assembly{
            let length := mload(returnData)
            switch isRevert
            case 0x00{
                return (add(returnData, 0x20), length)
            }
            default{
                revert (add(returnData, 0x20), length)
            }
        }
    }

    modifier nonPayable(){
        require(msg.value == 0, "nonPayable");
        _;
    }

}


// File contracts/proxy/SlotData.sol



contract SlotData {

    constructor() public {}

    // for map,  key could be 0x00, but value can't be 0x00;
    // if value == 0x00, it mean the key doesn't has any value
    function sysMapSet(bytes32 mappingSlot, bytes32 key, bytes32 value) internal returns (uint256 length){
        length = sysMapLen(mappingSlot);
        bytes32 elementOffset = sysCalcMapOffset(mappingSlot, key);
        bytes32 storedValue = sysLoadSlotData(elementOffset);
        if (value == storedValue) {
            //if value == 0 & storedValue == 0
            //if value == storedValue != 0
            //needn't set same value;
        } else if (value == bytes32(0x00)) {
            //storedValue != 0
            //deleting value
            sysSaveSlotData(elementOffset, value);
            length--;
            sysSaveSlotData(mappingSlot, bytes32(length));
        } else if (storedValue == bytes32(0x00)) {
            //value != 0
            //adding new value
            sysSaveSlotData(elementOffset, value);
            length++;
            sysSaveSlotData(mappingSlot, bytes32(length));
        } else {
            //value != storedValue & value != 0 & storedValue !=0
            //updating
            sysSaveSlotData(elementOffset, value);
        }
        return length;
    }

    function sysMapGet(bytes32 mappingSlot, bytes32 key) internal view returns (bytes32){
        bytes32 elementOffset = sysCalcMapOffset(mappingSlot, key);
        return sysLoadSlotData(elementOffset);
    }

    function sysMapLen(bytes32 mappingSlot) internal view returns (uint256){
        return uint256(sysLoadSlotData(mappingSlot));
    }

    function sysLoadSlotData(bytes32 slot) internal view returns (bytes32){
        //ask a stack position
        bytes32 ret;
        assembly{
            ret := sload(slot)
        }
        return ret;
    }

    function sysSaveSlotData(bytes32 slot, bytes32 data) internal {
        assembly{
            sstore(slot, data)
        }
    }

    function sysCalcMapOffset(bytes32 mappingSlot, bytes32 key) internal pure returns (bytes32){
        return bytes32(keccak256(abi.encodePacked(key, mappingSlot)));
    }

    function sysCalcSlot(bytes memory name) public pure returns (bytes32){
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(name))))));
    }

    function calcNewSlot(bytes32 slot, string memory name) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(slot, name))))));
    }
}


// File contracts/proxy/EnhancedMap.sol



//this is just a normal mapping, but which holds size and you can specify slot
/*
both key and value shouldn't be 0x00
the key must be unique, the value would be whatever

slot
  key --- value
    a --- 1
    b --- 2
    c --- 3
    c --- 4   X   not allowed
    d --- 3
    e --- 0   X   not allowed
    0 --- 9   X   not allowed

*/
contract EnhancedMap is SlotData {

    constructor() public {}

    //set value to 0x00 to delete
    function sysEnhancedMapSet(bytes32 slot, bytes32 key, bytes32 value) internal {
        require(key != bytes32(0x00), "sysEnhancedMapSet, notEmptyKey");
        sysMapSet(slot, key, value);
    }

    function sysEnhancedMapAdd(bytes32 slot, bytes32 key, bytes32 value) internal {
        require(key != bytes32(0x00), "sysEnhancedMapAdd, notEmptyKey");
        require(value != bytes32(0x00), "EnhancedMap add, the value shouldn't be empty");
        require(sysMapGet(slot, key) == bytes32(0x00), "EnhancedMap, the key already has value, can't add duplicate key");
        sysMapSet(slot, key, value);
    }

    function sysEnhancedMapDel(bytes32 slot, bytes32 key) internal {
        require(key != bytes32(0x00), "sysEnhancedMapDel, notEmptyKey");
        require(sysMapGet(slot, key) != bytes32(0x00), "sysEnhancedMapDel, the key doesn't has value, can't delete empty key");
        sysMapSet(slot, key, bytes32(0x00));
    }

    function sysEnhancedMapReplace(bytes32 slot, bytes32 key, bytes32 value) public {
        require(key != bytes32(0x00), "sysEnhancedMapReplace, notEmptyKey");
        require(value != bytes32(0x00), "EnhancedMap replace, the value shouldn't be empty");
        require(sysMapGet(slot, key) != bytes32(0x00), "EnhancedMap, the key doesn't has value, can't replace it");
        sysMapSet(slot, key, value);
    }

    function sysEnhancedMapGet(bytes32 slot, bytes32 key) internal view returns (bytes32){
        require(key != bytes32(0x00), "sysEnhancedMapGet, notEmptyKey");
        return sysMapGet(slot, key);
    }

    function sysEnhancedMapSize(bytes32 slot) internal view returns (uint256){
        return sysMapLen(slot);
    }

}


// File contracts/proxy/EnhancedUniqueIndexMap.sol



//once you input a value, it will auto generate an index for that
//index starts from 1, 0 means this value doesn't exist
//the value must be unique, and can't be 0x00
//the index must be unique, and can't be 0x00
/*

slot
value --- index
    a --- 1
    b --- 2
    c --- 3
    c --- 4   X   not allowed
    d --- 3   X   not allowed
    e --- 0   X   not allowed

indexSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(slot))))));
index --- value
    1 --- a
    2 --- b
    3 --- c
    3 --- d   X   not allowed

*/

contract EnhancedUniqueIndexMap is SlotData {

    constructor() public {}

    // slot : value => index
    function sysUniqueIndexMapAdd(bytes32 slot, bytes32 value) internal {

        require(value != bytes32(0x00));

        bytes32 indexSlot = calcIndexSlot(slot);

        uint256 index = uint256(sysMapGet(slot, value));
        require(index == 0, "sysUniqueIndexMapAdd, value already exist");

        uint256 last = sysUniqueIndexMapSize(slot);
        last ++;
        sysMapSet(slot, value, bytes32(last));
        sysMapSet(indexSlot, bytes32(last), value);
    }

    function sysUniqueIndexMapDel(bytes32 slot, bytes32 value) internal {

        //require(value != bytes32(0x00), "sysUniqueIndexMapDel, value must not be 0x00");

        bytes32 indexSlot = calcIndexSlot(slot);

        uint256 index = uint256(sysMapGet(slot, value));
        require(index != 0, "sysUniqueIndexMapDel, value doesn't exist");

        uint256 lastIndex = sysUniqueIndexMapSize(slot);
        require(lastIndex > 0, "sysUniqueIndexMapDel, lastIndex must be large than 0, this must not happen");
        if (index != lastIndex) {

            bytes32 lastValue = sysMapGet(indexSlot, bytes32(lastIndex));
            //move the last to the current place
            //this would be faster than move all elements forward after the deleting one, but not stable(the sequence will change)
            sysMapSet(slot, lastValue, bytes32(index));
            sysMapSet(indexSlot, bytes32(index), lastValue);
        }
        sysMapSet(slot, value, bytes32(0x00));
        sysMapSet(indexSlot, bytes32(lastIndex), bytes32(0x00));
    }

    function sysUniqueIndexMapDelArrange(bytes32 slot, bytes32 value) internal {

        require(value != bytes32(0x00), "sysUniqueIndexMapDelArrange, value must not be 0x00");

        bytes32 indexSlot = calcIndexSlot(slot);

        uint256 index = uint256(sysMapGet(slot, value));
        require(index != 0, "sysUniqueIndexMapDelArrange, value doesn't exist");

        uint256 lastIndex = (sysUniqueIndexMapSize(slot));
        require(lastIndex > 0, "sysUniqueIndexMapDelArrange, lastIndex must be large than 0, this must not happen");

        sysMapSet(slot, value, bytes32(0x00));

        while (index < lastIndex) {

            bytes32 nextValue = sysMapGet(indexSlot, bytes32(index + 1));
            sysMapSet(indexSlot, bytes32(index), nextValue);
            sysMapSet(slot, nextValue, bytes32(index));

            index ++;
        }

        sysMapSet(indexSlot, bytes32(lastIndex), bytes32(0x00));
    }

    function sysUniqueIndexMapReplace(bytes32 slot, bytes32 oldValue, bytes32 newValue) internal {
        require(oldValue != bytes32(0x00), "sysUniqueIndexMapReplace, oldValue must not be 0x00");
        require(newValue != bytes32(0x00), "sysUniqueIndexMapReplace, newValue must not be 0x00");

        bytes32 indexSlot = calcIndexSlot(slot);

        uint256 index = uint256(sysMapGet(slot, oldValue));
        require(index != 0, "sysUniqueIndexMapDel, oldValue doesn't exists");
        require(uint256(sysMapGet(slot, newValue)) == 0, "sysUniqueIndexMapDel, newValue already exists");

        sysMapSet(slot, oldValue, bytes32(0x00));
        sysMapSet(slot, newValue, bytes32(index));
        sysMapSet(indexSlot, bytes32(index), newValue);
    }

    //============================view & pure============================

    function sysUniqueIndexMapSize(bytes32 slot) internal view returns (uint256){
        return sysMapLen(slot);
    }

    //returns index, 0 mean not exist
    function sysUniqueIndexMapGetIndex(bytes32 slot, bytes32 value) internal view returns (uint256){
        return uint256(sysMapGet(slot, value));
    }

    function sysUniqueIndexMapGetValue(bytes32 slot, uint256 index) internal view returns (bytes32){
        bytes32 indexSlot = calcIndexSlot(slot);
        return sysMapGet(indexSlot, bytes32(index));
    }

    // index => value
    function calcIndexSlot(bytes32 slot) internal pure returns (bytes32){
        return calcNewSlot(slot, "index");
    }
}


// File contracts/proxy/Proxy.sol





contract Proxy is Base, EnhancedMap, EnhancedUniqueIndexMap {
    constructor (address admin) public {
        require(admin != address(0));
        sysSaveSlotData(adminSlot, bytes32(uint256(admin)));
        sysSaveSlotData(userSigZeroSlot, bytes32(uint256(0)));
        sysSaveSlotData(outOfServiceSlot, bytes32(uint256(0)));
        sysSaveSlotData(revertMessageSlot, bytes32(uint256(1)));
        //sysSetDelegateFallback(address(0));
        sysSaveSlotData(transparentSlot, bytes32(uint256(1)));

    }

    bytes32 constant adminSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("adminSlot"))))));

    bytes32 constant revertMessageSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("revertMessageSlot"))))));

    bytes32 constant outOfServiceSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("outOfServiceSlot"))))));

    //address <===>  index EnhancedUniqueIndexMap
    //0x2f80e9a12a11b80d2130b8e7dfc3bb1a6c04d0d87cc5c7ea711d9a261a1e0764
    bytes32 constant delegatesSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("delegatesSlot"))))));

    //bytes4 abi ===> address, both not 0x00
    //0xba67a9e2b7b43c3c9db634d1c7bcdd060aa7869f4601d292a20f2eedaf0c2b1c
    bytes32 constant userAbiSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("userAbiSlot"))))));

    bytes32 constant userAbiSearchSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("userAbiSearchSlot"))))));

    //0xe2bb2e16cbb16a10fab839b4a5c3820d63a910f4ea675e7821846c4b2d3041dc
    bytes32 constant userSigZeroSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("userSigZeroSlot"))))));

    bytes32 constant transparentSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("transparentSlot"))))));


    event DelegateSet(address delegate, bool activated);
    event AbiSet(bytes4 abi, address delegate, bytes32 slot);
    event PrintBytes(bytes data);
    //===================================================================================

    //
    function sysCountDelegate() public view returns (uint256){
        return sysUniqueIndexMapSize(delegatesSlot);
    }

    function sysGetDelegateAddress(uint256 index) public view returns (address){
        return address(uint256(sysUniqueIndexMapGetValue(delegatesSlot, index)));
    }

    function sysGetDelegateIndex(address addr) public view returns (uint256) {
        return uint256(sysUniqueIndexMapGetIndex(delegatesSlot, bytes32(uint256(addr))));
    }

    function sysGetDelegateAddresses() public view returns (address[] memory){
        uint256 count = sysCountDelegate();
        address[] memory delegates = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            delegates[i] = sysGetDelegateAddress(i + 1);
        }
        return delegates;
    }

    //add delegates on current version
    function sysAddDelegates(address[] memory _inputs) public onlyAdmin {
        for (uint256 i = 0; i < _inputs.length; i ++) {
            sysUniqueIndexMapAdd(delegatesSlot, bytes32(uint256(_inputs[i])));
            emit DelegateSet(_inputs[i], true);
        }
    }

    //delete delegates
    //be careful, if you delete a delegate, the index will change
    function sysDelDelegates(address[] memory _inputs) public onlyAdmin {
        for (uint256 i = 0; i < _inputs.length; i ++) {

            //travers all abis to delete those abis mapped to the given address
            uint256 j;
            uint256 k;
            /*bytes4[] memory toDeleteSelectors = new bytes4[](count + 1);
            uint256 pivot = 0;*/
            uint256 count = sysCountSelectors();

            /*for (j = 0; j < count; j ++) {
                bytes4 selector;
                address delegate;
                (selector, delegate) = sysGetUserSelectorAndDelegateByIndex(j + 1);
                if (delegate == _inputs[i]) {
                    toDeleteSelectors[pivot] = selector;
                    pivot++;
                }
            }
            pivot = 0;
            while (toDeleteSelectors[pivot] != bytes4(0x00)) {
                sysSetUserSelectorAndDelegate(toDeleteSelectors[pivot], address(0));
                pivot++;
            }*/
            k = 1;
            for (j = 0; j < count; j++) {
                bytes4 selector;
                address delegate;
                (selector, delegate) = sysGetSelectorAndDelegateByIndex(k);
                if (delegate == _inputs[i]) {
                    sysSetSelectorAndDelegate(selector, address(0));
                }
                else {
                    k++;
                }
            }

            if (sysGetSigZero() == _inputs[i]) {
                sysSetSigZero(address(0x00));
            }

            sysUniqueIndexMapDelArrange(delegatesSlot, bytes32(uint256(_inputs[i])));
            emit DelegateSet(_inputs[i], false);
        }
    }

    //add and delete delegates
    function sysReplaceDelegates(address[] memory _delegatesToDel, address[] memory _delegatesToAdd) public onlyAdmin {
        require(_delegatesToDel.length == _delegatesToAdd.length, "sysReplaceDelegates, length does not match");
        for (uint256 i = 0; i < _delegatesToDel.length; i ++) {
            sysUniqueIndexMapReplace(delegatesSlot, bytes32(uint256(_delegatesToDel[i])), bytes32(uint256(_delegatesToAdd[i])));
            emit DelegateSet(_delegatesToDel[i], false);
            emit DelegateSet(_delegatesToAdd[i], true);
        }
    }

    //=============================================

    function sysGetSigZero() public view returns (address){
        return address(uint256(sysLoadSlotData(userSigZeroSlot)));
    }

    function sysSetSigZero(address _input) public onlyAdmin {
        sysSaveSlotData(userSigZeroSlot, bytes32(uint256(_input)));
    }

    function sysGetAdmin() public view returns (address){
        return address(uint256(sysLoadSlotData(adminSlot)));
    }

    function sysSetAdmin(address _input) external onlyAdmin {
        sysSaveSlotData(adminSlot, bytes32(uint256(_input)));
    }

    function sysGetRevertMessage() public view returns (uint256){
        return uint256(sysLoadSlotData(revertMessageSlot));
    }

    function sysSetRevertMessage(uint256 _input) external onlyAdmin {
        sysSaveSlotData(revertMessageSlot, bytes32(_input));
    }

    function sysGetOutOfService() public view returns (uint256){
        return uint256(sysLoadSlotData(outOfServiceSlot));
    }

    function sysSetOutOfService(uint256 _input) external onlyAdmin {
        sysSaveSlotData(outOfServiceSlot, bytes32(_input));
    }

    function sysGetTransparent() public view returns (uint256){
        return uint256(sysLoadSlotData(transparentSlot));
    }

    function sysSetTransparent(uint256 _input) public onlyAdmin {
        sysSaveSlotData(transparentSlot, bytes32(_input));
    }

    //=============================================

    //abi and delegates should not be 0x00 in mapping;
    //set delegate to 0x00 for delete the entry
    function sysSetSelectorsAndDelegates(bytes4[] memory selectors, address[] memory delegates) public onlyAdmin {
        require(selectors.length == delegates.length, "sysSetUserSelectorsAndDelegates, length does not matchs");
        for (uint256 i = 0; i < selectors.length; i ++) {
            sysSetSelectorAndDelegate(selectors[i], delegates[i]);
        }
    }

    function sysSetSelectorAndDelegate(bytes4 selector, address delegate) public {

        require(selector != bytes4(0x00), "sysSetSelectorAndDelegate, selector should not be selector");
        //require(delegates[i] != address(0x00));
        address oldDelegate = address(uint256(sysEnhancedMapGet(userAbiSlot, bytes32(selector))));
        if (oldDelegate == delegate) {
            //if oldDelegate == 0 & delegate == 0
            //if oldDelegate == delegate != 0
            //do nothing here
        }
        if (oldDelegate == address(0x00)) {
            //delegate != 0
            //adding new value
            sysEnhancedMapAdd(userAbiSlot, bytes32(selector), bytes32(uint256(delegate)));
            sysUniqueIndexMapAdd(userAbiSearchSlot, bytes32(selector));
        }
        if (delegate == address(0x00)) {
            //oldDelegate != 0
            //deleting new value
            sysEnhancedMapDel(userAbiSlot, bytes32(selector));
            sysUniqueIndexMapDel(userAbiSearchSlot, bytes32(selector));

        } else {
            //oldDelegate != delegate & oldDelegate != 0 & delegate !=0
            //updating
            sysEnhancedMapReplace(userAbiSlot, bytes32(selector), bytes32(uint256(delegate)));
        }


    }

    function sysGetDelegateBySelector(bytes4 selector) public view returns (address){
        return address(uint256(sysEnhancedMapGet(userAbiSlot, bytes32(selector))));
    }

    function sysCountSelectors() public view returns (uint256){
        return sysEnhancedMapSize(userAbiSlot);
    }

    function sysGetSelector(uint256 index) public view returns (bytes4){
        bytes4 selector = bytes4(sysUniqueIndexMapGetValue(userAbiSearchSlot, index));
        return selector;
    }

    function sysGetSelectorAndDelegateByIndex(uint256 index) public view returns (bytes4, address){
        bytes4 selector = sysGetSelector(index);
        address delegate = sysGetDelegateBySelector(selector);
        return (selector, delegate);
    }

    function sysGetSelectorsAndDelegates() public view returns (bytes4[] memory selectors, address[] memory delegates){
        uint256 count = sysCountSelectors();
        selectors = new bytes4[](count);
        delegates = new address[](count);
        for (uint256 i = 0; i < count; i ++) {
            (selectors[i], delegates[i]) = sysGetSelectorAndDelegateByIndex(i + 1);
        }
    }

    function sysClearSelectorsAndDelegates() public {
        uint256 count = sysCountSelectors();
        for (uint256 i = 0; i < count; i ++) {
            bytes4 selector;
            address delegate;
            //always delete the first, after 'count' times, it will clear all
            (selector, delegate) = sysGetSelectorAndDelegateByIndex(1);
            sysSetSelectorAndDelegate(selector, address(0x00));
        }
    }

    //=====================internal functions=====================

    receive() payable external {
        process();
    }

    fallback() payable external {
        process();
    }


    //since low-level address.delegateCall is available in solidity,
    //we don't need to write assembly
    function process() internal outOfService {

        if (msg.sender == sysGetAdmin() && sysGetTransparent() == 1) {
            revert("admin cann't call normal function in Transparent mode");
        }

        /*
        the default transfer will set data to empty,
        so that the msg.data.length = 0 and msg.sig = bytes4(0x00000000),

        however some one can manually set msg.sig to 0x00000000 and tails more man-made data,
        so here we have to forward all msg.data to delegates
        */
        address targetDelegate;

        //for look-up table
        /*        if (msg.sig == bytes4(0x00000000)) {
                    targetDelegate = sysGetUserSigZero();
                    if (targetDelegate != address(0x00)) {
                        delegateCallExt(targetDelegate, msg.data);
                    }

                    targetDelegate = sysGetSystemSigZero();
                    if (targetDelegate != address(0x00)) {
                        delegateCallExt(targetDelegate, msg.data);
                    }
                } else {
                    targetDelegate = sysGetUserDelegate(msg.sig);
                    if (targetDelegate != address(0x00)) {
                        delegateCallExt(targetDelegate, msg.data);
                    }

                    //check system abi look-up table
                    targetDelegate = sysGetSystemDelegate(msg.sig);
                    if (targetDelegate != address(0x00)) {
                        delegateCallExt(targetDelegate, msg.data);
                    }
                }*/

        if (msg.sig == bytes4(0x00000000)) {
            targetDelegate = sysGetSigZero();
            if (targetDelegate != address(0x00)) {
                delegateCallExt(targetDelegate, msg.data);
            }

        } else {
            targetDelegate = sysGetDelegateBySelector(msg.sig);
            if (targetDelegate != address(0x00)) {
                delegateCallExt(targetDelegate, msg.data);
            }

        }

        //goes here means this abi is not in the system abi look-up table
        discover();

        //hit here means not found selector
        if (sysGetRevertMessage() == 1) {
            revert(string(abi.encodePacked(sysPrintAddressToHex(address(this)), ", function selector not found : ", sysPrintBytes4ToHex(msg.sig))));
        } else {
            revert();
        }

    }

    function discover() internal {
        bool found = false;
        bool error;
        bytes memory returnData;
        address targetDelegate;
        uint256 len = sysCountDelegate();
        for (uint256 i = 0; i < len; i++) {
            targetDelegate = sysGetDelegateAddress(i + 1);
            (found, error, returnData) = redirect(targetDelegate, msg.data);


            if (found) {
                /*if (msg.sig == bytes4(0x00000000)) {
                    sysSetSystemSigZero(targetDelegate);
                } else {
                    sysSetSystemSelectorAndDelegate(msg.sig, targetDelegate);
                }*/

                returnAsm(error, returnData);
            }
        }
    }

    function delegateCallExt(address targetDelegate, bytes memory callData) internal {
        bool found = false;
        bool error;
        bytes memory returnData;
        (found, error, returnData) = redirect(targetDelegate, callData);
        require(found, "delegateCallExt to a delegate in the map but finally not found, this shouldn't happen");
        returnAsm(error, returnData);
    }

    //since low-level ```<address>.delegatecall(bytes memory) returns (bool, bytes memory)``` can return returndata,
    //we use high-level solidity for better reading
    function redirect(address delegateTo, bytes memory callData) internal returns (bool found, bool error, bytes memory returnData){
        require(delegateTo != address(0), "delegateTo must not be 0x00");
        bool success;
        (success, returnData) = delegateTo.delegatecall(callData);
        if (success == true && keccak256(returnData) == keccak256(notFoundMark)) {
            //the delegate returns ```notFoundMark``` notFoundMark, which means invoke goes to wrong contract or function doesn't exist
            return (false, true, returnData);
        } else {
            return (true, !success, returnData);
        }

    }

    function sysPrintBytesToHex(bytes memory input) internal pure returns (string memory){
        bytes memory ret = new bytes(input.length * 2);
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < input.length; i++) {
            bytes32 t = bytes32(input[i]);
            bytes32 tt = t >> 31 * 8;
            uint256 b = uint256(tt);
            uint256 high = b / 0x10;
            uint256 low = b % 0x10;
            byte highAscii = alphabet[high];
            byte lowAscii = alphabet[low];
            ret[2 * i] = highAscii;
            ret[2 * i + 1] = lowAscii;
        }
        return string(ret);
    }

    function sysPrintAddressToHex(address input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintBytes4ToHex(bytes4 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintUint256ToHex(uint256 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    modifier onlyAdmin(){
        require(msg.sender == sysGetAdmin(), "only admin");
        _;
    }

    modifier outOfService(){
        if (sysGetOutOfService() == uint256(1)) {
            if (sysGetRevertMessage() == 1) {
                revert(string(abi.encodePacked("Proxy is out-of-service right now")));
            } else {
                revert();
            }
        }
        _;
    }

}



/*function() payable external {
    bytes32 notFound = notFoundMark;
    assembly {

        let ptr := mload(0x40)
        mstore(ptr, notFound)
        return (ptr, 32)
    }
}*/


/* bytes4 selector = msg.sig;

        uint256 size;
        uint256 ptr;
        bool result;
        //check if the shortcut hit
        address delegateTo = checkShortcut(selector);
        if (delegateTo != address(0x00)) {

            assembly{
                ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                result := delegatecall(gas, delegateTo, ptr, calldatasize, 0, 0)
                size := returndatasize
                returndatacopy(ptr, 0, size)
                switch result
                case 0 {revert(ptr, size)}
                default {return (ptr, size)}
            }
        }

        //no shortcut
        bytes32 notFound = notFoundMark;
        bool found = false;
        for (uint256 i = 0; i < delegates.length && !found; i ++) {
            delegateTo = delegates[i];
            assembly{
                result := delegatecall(gas, delegateTo, 0, 0, 0, 0)
                size := returndatasize
                returndatacopy(ptr, 0, size)
                mstore(0x40, add(ptr, size))//update free memory pointer
                found := 0x01 //assume we found the target function
                if and(and(eq(result, 0x01), eq(size, 0x20)), eq(mload(ptr), notFound)){
                //match the "notFound" mark
                    found := 0x00
                }
            }
            if (found) {
                emit FunctionFound(delegateTo);
                //add to shortcut, take effect only when the delegatecall returns 1 (not 0-revert)
                shortcut[selector] = delegateTo;


                //return data
                assembly{
                    switch result
                    case 0 {revert(ptr, size)}
                    default {return (ptr, size)}
                }
            }
        }
        //comes here for not found
        emit FunctionNotFound(selector);*/


// File @openzeppelin/contracts/introspection/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/erc165/CERC165Interface.sol


interface CERC165Interface is IERC165 {
    function supportsInterface(bytes4 interfaceId) override external view returns (bool);
}


// File contracts/erc165/CERC165Layout.sol


contract CERC165Layout {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) internal _supportedInterfaces;
}


// File contracts/erc165/CERC165LogicBase.sol



contract CERC165LogicBase is CERC165Layout {

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


// File contracts/erc165/CERC165Storage.sol


contract CERC165Storage is CERC165LogicBase {

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}


// File contracts/erc721/CERC721Layout.sol



contract CERC721Layout is CERC165Layout {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) internal _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap internal _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    // Base URI
    string internal _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
}


// File contracts/context/ContextLogicBase.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextLogicBase {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/erc721/CERC721LogicBase.sol




contract CERC721LogicBase is CERC165LogicBase, ContextLogicBase, CERC721Layout {

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

}


// File contracts/erc721/CERC721Storage.sol


contract CERC721Storage is CERC721LogicBase {

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
}


// File contracts/ownable/OwnableLayout.sol


abstract contract OwnableLayout {
    address internal _owner;

    mapping(address => bool) internal _associatedOperators;
}


// File contracts/ownable/OwnableStorage.sol


contract OwnableStorage is OwnableLayout {

    constructor (address owner) internal {
        _owner = owner;
    }
}


// File contracts/ownable/OwnableLogicBase.sol


contract OwnableLogicBase is OwnableLayout {
    //nothing to do here
}


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/nfts/CalendarType.sol


library CalendarType {

    struct Pair {
        uint256 min;
        uint256 max;
    }

}


// File contracts/nfts/CalendarLayout.sol





//keep the layout order
contract CalendarLayout is CERC721Layout, OwnableLayout {

    using SafeMath for uint256;

    uint256 constant MILLION = 1000000;

    uint256 internal _startTime;

    address internal _dev;

    uint256 internal _taxPerMillion;

    uint256 internal _startPrice;

    uint256 internal _bidPricePerMillion;

    mapping(uint256 => uint256) internal _lastPrice;

    mapping(uint256 => uint256) internal _calendarSkin;

    mapping(uint256 => bytes) internal _calendarName;

    mapping(uint256 => bytes) internal _calendarBlog;
}


// File contracts/nfts/CalendarLogicBase.sol




contract CalendarLogicBase is OwnableLogicBase, CERC721LogicBase, CalendarLayout {

}


// File contracts/nfts/CalendarStorage.sol





//don't change the layouts. notice that layout is behind storage
contract CalendarStorage is Proxy, OwnableStorage, CERC165Storage, CERC721Storage, CalendarLogicBase {

    constructor (
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 startTime_,
        uint256 startPrice_,
        uint256 bidPricePerMillion_,
        uint256 taxPerMillion_,
        address dev_
    ) public Proxy(msg.sender) OwnableStorage(msg.sender) CERC165Storage() CERC721Storage(name_, symbol_) {

        sysSetTransparent(0);

        _setBaseURI(baseURI_);
        _startTime = startTime_;
        _startPrice = startPrice_;
        _bidPricePerMillion = bidPricePerMillion_;
        _taxPerMillion = taxPerMillion_;
        require(dev_ != address(0), "dev should not be 0");
        _dev = dev_;

    }
}