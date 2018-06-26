pragma solidity ^0.4.21;

contract FlightManager {

  constructor(bytes32 _flightID, address _admin, uint256 _ticketPrice, uint256 _numSeats) public {
    assembly {
      // Memory address 0x40 holds the next available memory location.
      mstore(0x40, 0x60)
  
      init()
      function init() {
        codecopy(0x0, sub(codesize, 128), 32)
        let _flightID := mload(0)
        codecopy(0x0, sub(codesize, 96), 32)
        let _admin := mload(0)
        codecopy(0x0, sub(codesize, 64), 32)
        let _ticketPrice := mload(0)
        codecopy(0x0, sub(codesize, 32), 32)
        let _numSeats := mload(0)
        let _caller := caller()
        sstore(add(0, 7), 0)
        sstore(add(0, 6), 0)
        sstore(add(0, 8), 0)
        FlightInformation_init_String_Int(add(0, 0), 0, _flightID, _numSeats)
        sstore(add(0, 3), _admin)
        sstore(add(0, 4), _ticketPrice)
        sstore(add(0, 5), _numSeats)
      }
      function Flint$Global_send_Address_$inoutWei(_address, _value, _value$isMem)  {
        let _w := flint$allocateMemory(32)
        Wei_init_$inoutWei(_w, 1, _value, _value$isMem)
        flint$send(Wei_getRawValue(_w, 1), _address)
      }
      
      function Flint$Global_fatalError()  {
        flint$fatalError()
      }
      
      function Flint$Global_assert_Bool(_condition)  {
        switch eq(_condition, 0)
        case 1 {
          Flint$Global_fatalError()
        }
        
      }
      
      function Wei_init_Int(_flintSelf, _flintSelf$isMem, _unsafeRawValue)  {
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _unsafeRawValue, _flintSelf$isMem)
      }
      
      function Wei_init_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, _amount)  {
        switch lt(Wei_getRawValue(_source, _source$isMem), _amount)
        case 1 {
          Flint$Global_fatalError()
        }
        
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _amount), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _amount, _flintSelf$isMem)
      }
      
      function Wei_init_$inoutWei(_flintSelf, _flintSelf$isMem, _source, _source$isMem)  {
        let _value := Wei_getRawValue(_source, _source$isMem)
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _value), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _value, _flintSelf$isMem)
      }
      
      function Wei_transfer_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, _amount)  {
        switch lt(Wei_getRawValue(_source, _source$isMem), _amount)
        case 1 {
          Flint$Global_fatalError()
        }
        
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _amount), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), flint$add(flint$load(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flintSelf$isMem), _amount), _flintSelf$isMem)
      }
      
      function Wei_transfer_$inoutWei(_flintSelf, _flintSelf$isMem, _source, _source$isMem)  {
        Wei_transfer_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, Wei_getRawValue(_source, _source$isMem))
      }
      
      function Wei_getRawValue(_flintSelf, _flintSelf$isMem) -> ret {
        ret := flint$load(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flintSelf$isMem)
      }
      
      function FlightInformation_init_String_Int(_flintSelf, _flintSelf$isMem, _flightID, _numTotalSeats)  {
        flint$store(flint$computeOffset(_flintSelf, 1, _flintSelf$isMem), 0, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), 0, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flightID, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), _numTotalSeats, _flintSelf$isMem)
      }
      
      function FlightInformation_cancelFlight(_flintSelf, _flintSelf$isMem)  {
        flint$store(flint$computeOffset(_flintSelf, 1, _flintSelf$isMem), 0, _flintSelf$isMem)
      }
      
      function FlightInformation_getNumTotalSeat(_flintSelf, _flintSelf$isMem) -> ret {
        ret := flint$load(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), _flintSelf$isMem)
      }
      function flint$selector() -> ret {
        ret := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }
      
      function flint$decodeAsAddress(offset) -> ret {
        ret := flint$decodeAsUInt(offset)
      }
      
      function flint$decodeAsUInt(offset) -> ret {
        ret := calldataload(add(4, mul(offset, 0x20)))
      }
      
      function flint$store(ptr, val, mem) {
        switch iszero(mem)
        case 0 {
          mstore(ptr, val)
        }
        default {
          sstore(ptr, val)
        }
      }
      
      function flint$load(ptr, mem) -> ret {
        switch iszero(mem)
        case 0 {
          ret := mload(ptr)
        }
        default {
          ret := sload(ptr)
        }
      }
      
      function flint$computeOffset(base, offset, mem) -> ret {
        switch iszero(mem)
        case 0 {
          ret := add(base, mul(offset, 32))
        }
        default {
          ret := add(base, offset)
        }
      }
      
      function flint$allocateMemory(size) -> ret {
        ret := mload(0x40)
        mstore(0x40, add(ret, size))
      }
      
      function flint$isValidCallerCapability(_address) -> ret {
        ret := eq(_address, caller())
      }
      
      function flint$isCallerCapabilityInArray(arrayOffset) -> ret {
        let size := sload(arrayOffset)
        let found := 0
        let _caller := caller()
        let arrayStart := flint$add(arrayOffset, 1)
        for { let i := 0 } and(lt(i, size), iszero(found)) { i := add(i, 1) } {
          if eq(sload(flint$storageArrayOffset(arrayOffset, i)), _caller) {
            found := 1
          }
        }
        ret := found
      }
      
      function flint$return32Bytes(v) {
        mstore(0, v)
        return(0, 0x20)
      }
      
      function flint$isInvalidSubscriptExpression(index, arraySize) -> ret {
        ret := or(iszero(arraySize), or(lt(index, 0), gt(index, flint$sub(arraySize, 1))))
      }
      
      function flint$storageArrayOffset(arrayOffset, index) -> ret {
        let arraySize := sload(arrayOffset)
      
        switch eq(arraySize, index)
        case 0 {
          if flint$isInvalidSubscriptExpression(index, arraySize) { revert(0, 0) }
        }
        default {
          sstore(arrayOffset, flint$add(arraySize, 1))
        }
      
        ret := flint$storageDictionaryOffsetForKey(arrayOffset, index)
      }
      
      function flint$storageFixedSizeArrayOffset(arrayOffset, index, arraySize) -> ret {
        if flint$isInvalidSubscriptExpression(index, arraySize) { revert(0, 0) }
        ret := flint$add(arrayOffset, index)
      }
      
      function flint$storageDictionaryOffsetForKey(dictionaryOffset, key) -> ret {
        mstore(0, key)
        mstore(32, dictionaryOffset)
        ret := sha3(0, 64)
      }
      
      function flint$send(_value, _address) {
        let ret := call(gas(), _address, _value, 0, 0, 0, 0)
      
        if iszero(ret) {
          revert(0, 0)
        }
      }
      
      function flint$fatalError() {
        revert(0, 0)
      }
      
      function flint$add(a, b) -> ret {
        let c := add(a, b)
      
        if lt(c, a) { revert(0, 0) }
        ret := c
      }
      
      function flint$sub(a, b) -> ret {
        if gt(b, a) { revert(0, 0) }
      
        ret := sub(a, b)
      }
      
      function flint$mul(a, b) -> ret {
        switch iszero(a)
        case 1 {
          ret := 0
        }
        default {
          let c := mul(a, b)
          if iszero(eq(div(c, a), b)) { revert(0, 0) }
          ret := c
        }
      }
      
      function flint$div(a, b) -> ret {
        if eq(b, 0) { revert(0, 0) }
        ret := div(a, b)
      }
    }
  }

  function () public payable {
    assembly {
      // Memory address 0x40 holds the next available memory location.
      mstore(0x40, 0x60)

      switch flint$selector()
      
      case 0xa6f2ae3a /* buy() */ {
        
        buy()
      }
      
      case 0x32b4d74c /* getNumRemainingSeats() */ {
        
        flint$return32Bytes(getNumRemainingSeats())
      }
      
      case 0x09aa69c2 /* cancelFlight() */ {
        let _flintCallerCheck := 0
        _flintCallerCheck := add(_flintCallerCheck, flint$isValidCallerCapability(sload(3)))
        if eq(_flintCallerCheck, 0) { revert(0, 0) }
        
        cancelFlight()
      }
      
      case 0x15981650 /* setTicketPrice(uint256) */ {
        let _flintCallerCheck := 0
        _flintCallerCheck := add(_flintCallerCheck, flint$isValidCallerCapability(sload(3)))
        if eq(_flintCallerCheck, 0) { revert(0, 0) }
        
        setTicketPrice(flint$decodeAsUInt(0))
      }
      
      case 0x54ddd5d6 /* retrieveRefund() */ {
        let _flintCallerCheck := 0
        _flintCallerCheck := add(_flintCallerCheck, flint$isCallerCapabilityInArray(6))
        if eq(_flintCallerCheck, 0) { revert(0, 0) }
        
        retrieveRefund()
      }
      
      default {
        revert(0, 0)
      }

      // User-defined functions

      function buy()  {
        let _caller := caller()
        let _value := flint$allocateMemory(32)
        Wei_init_Int(_value, 1, callvalue())
        let _amountGiven := Wei_getRawValue(_value, 1)
        Flint$Global_assert_Bool(eq(_amountGiven, sload(add(0, 4))))
        Flint$Global_assert_Bool(gt(sload(add(0, 5)), 0))
        Flint$Global_assert_Bool(eq(sload(add(0, 1)), 0))
        Wei_transfer_$inoutWei(flint$storageDictionaryOffsetForKey(8, _caller), 0, _value, 1)
        sstore(flint$storageArrayOffset(6, sload(add(0, 7))), _caller)
        sstore(add(0, 7), flint$add(sload(add(0, 7)), 1))
        sstore(add(0, 5), flint$sub(sload(add(0, 5)), 1))
      }
      
      function getNumRemainingSeats() -> ret {
        let _caller := caller()
        ret := sload(add(0, 5))
      }
      
      function cancelFlight()  {
        FlightInformation_cancelFlight(add(0, 0), 0)
      }
      
      function setTicketPrice(_ticketPrice)  {
        sstore(add(0, 4), _ticketPrice)
      }
      
      function retrieveRefund()  {
        let _passenger := caller()
        Flint$Global_assert_Bool(sload(add(0, 1)))
        refund(_passenger)
      }
      
      function refund(_passenger)  {
        let _refund := flint$allocateMemory(32)
        Wei_init_$inoutWei(_refund, 1, flint$storageDictionaryOffsetForKey(8, _passenger), 0)
        sstore(add(0, 5), flint$add(sload(add(0, 5)), 1))
        Flint$Global_send_Address_$inoutWei(_passenger, _refund, 1)
      }

      // Struct functions

      function Flint$Global_send_Address_$inoutWei(_address, _value, _value$isMem)  {
        let _w := flint$allocateMemory(32)
        Wei_init_$inoutWei(_w, 1, _value, _value$isMem)
        flint$send(Wei_getRawValue(_w, 1), _address)
      }
      
      function Flint$Global_fatalError()  {
        flint$fatalError()
      }
      
      function Flint$Global_assert_Bool(_condition)  {
        switch eq(_condition, 0)
        case 1 {
          Flint$Global_fatalError()
        }
        
      }
      
      function Wei_init_Int(_flintSelf, _flintSelf$isMem, _unsafeRawValue)  {
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _unsafeRawValue, _flintSelf$isMem)
      }
      
      function Wei_init_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, _amount)  {
        switch lt(Wei_getRawValue(_source, _source$isMem), _amount)
        case 1 {
          Flint$Global_fatalError()
        }
        
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _amount), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _amount, _flintSelf$isMem)
      }
      
      function Wei_init_$inoutWei(_flintSelf, _flintSelf$isMem, _source, _source$isMem)  {
        let _value := Wei_getRawValue(_source, _source$isMem)
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _value), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _value, _flintSelf$isMem)
      }
      
      function Wei_transfer_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, _amount)  {
        switch lt(Wei_getRawValue(_source, _source$isMem), _amount)
        case 1 {
          Flint$Global_fatalError()
        }
        
        flint$store(flint$computeOffset(_source, 0, _source$isMem), flint$sub(flint$load(flint$computeOffset(_source, 0, _source$isMem), _source$isMem), _amount), _source$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), flint$add(flint$load(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flintSelf$isMem), _amount), _flintSelf$isMem)
      }
      
      function Wei_transfer_$inoutWei(_flintSelf, _flintSelf$isMem, _source, _source$isMem)  {
        Wei_transfer_$inoutWei_Int(_flintSelf, _flintSelf$isMem, _source, _source$isMem, Wei_getRawValue(_source, _source$isMem))
      }
      
      function Wei_getRawValue(_flintSelf, _flintSelf$isMem) -> ret {
        ret := flint$load(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flintSelf$isMem)
      }
      
      function FlightInformation_init_String_Int(_flintSelf, _flintSelf$isMem, _flightID, _numTotalSeats)  {
        flint$store(flint$computeOffset(_flintSelf, 1, _flintSelf$isMem), 0, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), 0, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 0, _flintSelf$isMem), _flightID, _flintSelf$isMem)
        flint$store(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), _numTotalSeats, _flintSelf$isMem)
      }
      
      function FlightInformation_cancelFlight(_flintSelf, _flintSelf$isMem)  {
        flint$store(flint$computeOffset(_flintSelf, 1, _flintSelf$isMem), 0, _flintSelf$isMem)
      }
      
      function FlightInformation_getNumTotalSeat(_flintSelf, _flintSelf$isMem) -> ret {
        ret := flint$load(flint$computeOffset(_flintSelf, 2, _flintSelf$isMem), _flintSelf$isMem)
      }

      // Flint runtime

      function flint$selector() -> ret {
        ret := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }
      
      function flint$decodeAsAddress(offset) -> ret {
        ret := flint$decodeAsUInt(offset)
      }
      
      function flint$decodeAsUInt(offset) -> ret {
        ret := calldataload(add(4, mul(offset, 0x20)))
      }
      
      function flint$store(ptr, val, mem) {
        switch iszero(mem)
        case 0 {
          mstore(ptr, val)
        }
        default {
          sstore(ptr, val)
        }
      }
      
      function flint$load(ptr, mem) -> ret {
        switch iszero(mem)
        case 0 {
          ret := mload(ptr)
        }
        default {
          ret := sload(ptr)
        }
      }
      
      function flint$computeOffset(base, offset, mem) -> ret {
        switch iszero(mem)
        case 0 {
          ret := add(base, mul(offset, 32))
        }
        default {
          ret := add(base, offset)
        }
      }
      
      function flint$allocateMemory(size) -> ret {
        ret := mload(0x40)
        mstore(0x40, add(ret, size))
      }
      
      function flint$isValidCallerCapability(_address) -> ret {
        ret := eq(_address, caller())
      }
      
      function flint$isCallerCapabilityInArray(arrayOffset) -> ret {
        let size := sload(arrayOffset)
        let found := 0
        let _caller := caller()
        let arrayStart := flint$add(arrayOffset, 1)
        for { let i := 0 } and(lt(i, size), iszero(found)) { i := add(i, 1) } {
          if eq(sload(flint$storageArrayOffset(arrayOffset, i)), _caller) {
            found := 1
          }
        }
        ret := found
      }
      
      function flint$return32Bytes(v) {
        mstore(0, v)
        return(0, 0x20)
      }
      
      function flint$isInvalidSubscriptExpression(index, arraySize) -> ret {
        ret := or(iszero(arraySize), or(lt(index, 0), gt(index, flint$sub(arraySize, 1))))
      }
      
      function flint$storageArrayOffset(arrayOffset, index) -> ret {
        let arraySize := sload(arrayOffset)
      
        switch eq(arraySize, index)
        case 0 {
          if flint$isInvalidSubscriptExpression(index, arraySize) { revert(0, 0) }
        }
        default {
          sstore(arrayOffset, flint$add(arraySize, 1))
        }
      
        ret := flint$storageDictionaryOffsetForKey(arrayOffset, index)
      }
      
      function flint$storageFixedSizeArrayOffset(arrayOffset, index, arraySize) -> ret {
        if flint$isInvalidSubscriptExpression(index, arraySize) { revert(0, 0) }
        ret := flint$add(arrayOffset, index)
      }
      
      function flint$storageDictionaryOffsetForKey(dictionaryOffset, key) -> ret {
        mstore(0, key)
        mstore(32, dictionaryOffset)
        ret := sha3(0, 64)
      }
      
      function flint$send(_value, _address) {
        let ret := call(gas(), _address, _value, 0, 0, 0, 0)
      
        if iszero(ret) {
          revert(0, 0)
        }
      }
      
      function flint$fatalError() {
        revert(0, 0)
      }
      
      function flint$add(a, b) -> ret {
        let c := add(a, b)
      
        if lt(c, a) { revert(0, 0) }
        ret := c
      }
      
      function flint$sub(a, b) -> ret {
        if gt(b, a) { revert(0, 0) }
      
        ret := sub(a, b)
      }
      
      function flint$mul(a, b) -> ret {
        switch iszero(a)
        case 1 {
          ret := 0
        }
        default {
          let c := mul(a, b)
          if iszero(eq(div(c, a), b)) { revert(0, 0) }
          ret := c
        }
      }
      
      function flint$div(a, b) -> ret {
        if eq(b, 0) { revert(0, 0) }
        ret := div(a, b)
      }
    }
  }
}
interface _InterfaceFlightManager {
  
  function buy() payable external;
  function getNumRemainingSeats() view external returns (uint256 ret);
  function cancelFlight() external;
  function setTicketPrice(uint256 _ticketPrice) external;
  function retrieveRefund() external;
  
}