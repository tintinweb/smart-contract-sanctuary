pragma solidity ^0.4.23;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "Overflow - Multiplication");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Underflow - Subtraction");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "Overflow - Addition");
    return c;
  }
}

library Contract {

  using SafeMath for uint;

  // Modifiers: //

  // Runs two functions before and after a function -
  modifier conditions(function () pure first, function () pure last) {
    first();
    _;
    last();
  }

  bytes32 internal constant EXEC_PERMISSIONS = keccak256(&#39;script_exec_permissions&#39;);

  // Sets up contract execution - reads execution id and sender from storage and
  // places in memory, creating getters. Calling this function should be the first
  // action an application does as part of execution, as it sets up memory for
  // execution. Additionally, application functions in the main file should be
  // external, so that memory is not touched prior to calling this function.
  // The 3rd slot allocated will hold a pointer to a storage buffer, which will
  // be reverted to abstract storage to store data, emit events, and forward
  // wei on behalf of the application.
  function authorize(address _script_exec) internal view {
    // Initialize memory
    initialize();

    // Check that the sender is authorized as a script exec contract for this exec id
    bytes32 perms = EXEC_PERMISSIONS;
    bool authorized;
    assembly {
      // Place the script exec address at 0, and the exec permissions seed after it
      mstore(0, _script_exec)
      mstore(0x20, perms)
      // Hash the resulting 0x34 bytes, and place back into memory at 0
      mstore(0, keccak256(0x0c, 0x34))
      // Place the exec id after the hash -
      mstore(0x20, mload(0x80))
      // Hash the previous hash with the execution id, and check the result
      authorized := sload(keccak256(0, 0x40))
    }
    if (!authorized)
      revert("Sender is not authorized as a script exec address");
  }

  // Sets up contract execution when initializing an instance of the application
  // First, reads execution id and sender from storage (execution id should be 0xDEAD),
  // then places them in memory, creating getters. Calling this function should be the first
  // action an application does as part of execution, as it sets up memory for
  // execution. Additionally, application functions in the main file should be
  // external, so that memory is not touched prior to calling this function.
  // The 3rd slot allocated will hold a pointer to a storage buffer, which will
  // be reverted to abstract storage to store data, emit events, and forward
  // wei on behalf of the application.
  function initialize() internal view {
    // No memory should have been allocated yet - expect the free memory pointer
    // to point to 0x80 - and throw if it does not
    require(freeMem() == 0x80, "Memory allocated prior to execution");
    // Next, set up memory for execution
    assembly {
      mstore(0x80, sload(0))     // Execution id, read from storage
      mstore(0xa0, sload(1))     // Original sender address, read from storage
      mstore(0xc0, 0)            // Pointer to storage buffer
      mstore(0xe0, 0)            // Bytes4 value of the current action requestor being used
      mstore(0x100, 0)           // Enum representing the next type of function to be called (when pushing to buffer)
      mstore(0x120, 0)           // Number of storage slots written to in buffer
      mstore(0x140, 0)           // Number of events pushed to buffer
      mstore(0x160, 0)           // Number of payment destinations pushed to buffer

      // Update free memory pointer -
      mstore(0x40, 0x180)
    }
    // Ensure that the sender and execution id returned from storage are expected values -
    assert(execID() != bytes32(0) && sender() != address(0));
  }

  // Calls the passed-in function, performing a memory state check before and after the check
  // is executed.
  function checks(function () view _check) conditions(validState, validState) internal view {
    _check();
  }

  // Calls the passed-in function, performing a memory state check before and after the check
  // is executed.
  function checks(function () pure _check) conditions(validState, validState) internal pure {
    _check();
  }

  // Ensures execution completed successfully, and reverts the created storage buffer
  // back to the sender.
  function commit() conditions(validState, none) internal pure {
    // Check value of storage buffer pointer - should be at least 0x180
    bytes32 ptr = buffPtr();
    require(ptr >= 0x180, "Invalid buffer pointer");

    assembly {
      // Get the size of the buffer
      let size := mload(add(0x20, ptr))
      mstore(ptr, 0x20) // Place dynamic data offset before buffer
      // Revert to storage
      revert(ptr, add(0x40, size))
    }
  }

  // Helpers: //

  // Checks to ensure the application was correctly executed -
  function validState() private pure {
    if (freeMem() < 0x180)
      revert(&#39;Expected Contract.execute()&#39;);

    if (buffPtr() != 0 && buffPtr() < 0x180)
      revert(&#39;Invalid buffer pointer&#39;);

    assert(execID() != bytes32(0) && sender() != address(0));
  }

  // Returns a pointer to the execution storage buffer -
  function buffPtr() private pure returns (bytes32 ptr) {
    assembly { ptr := mload(0xc0) }
  }

  // Returns the location pointed to by the free memory pointer -
  function freeMem() private pure returns (bytes32 ptr) {
    assembly { ptr := mload(0x40) }
  }

  // Returns the current storage action
  function currentAction() private pure returns (bytes4 action) {
    if (buffPtr() == bytes32(0))
      return bytes4(0);

    assembly { action := mload(0xe0) }
  }

  // If the current action is not storing, reverts
  function isStoring() private pure {
    if (currentAction() != STORES)
      revert(&#39;Invalid current action - expected STORES&#39;);
  }

  // If the current action is not emitting, reverts
  function isEmitting() private pure {
    if (currentAction() != EMITS)
      revert(&#39;Invalid current action - expected EMITS&#39;);
  }

  // If the current action is not paying, reverts
  function isPaying() private pure {
    if (currentAction() != PAYS)
      revert(&#39;Invalid current action - expected PAYS&#39;);
  }

  // Initializes a storage buffer in memory -
  function startBuffer() private pure {
    assembly {
      // Get a pointer to free memory, and place at 0xc0 (storage buffer pointer)
      let ptr := msize()
      mstore(0xc0, ptr)
      // Clear bytes at pointer -
      mstore(ptr, 0)            // temp ptr
      mstore(add(0x20, ptr), 0) // buffer length
      // Update free memory pointer -
      mstore(0x40, add(0x40, ptr))
      // Set expected next function to &#39;NONE&#39; -
      mstore(0x100, 1)
    }
  }

  // Checks whether or not it is valid to create a STORES action request -
  function validStoreBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not &#39;storing&#39;, and that the buffer has not already
    // completed a STORES action -
    if (stored() != 0 || currentAction() == STORES)
      revert(&#39;Duplicate request - stores&#39;);
  }

  // Checks whether or not it is valid to create an EMITS action request -
  function validEmitBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not &#39;emitting&#39;, and that the buffer has not already
    // completed an EMITS action -
    if (emitted() != 0 || currentAction() == EMITS)
      revert(&#39;Duplicate request - emits&#39;);
  }

  // Checks whether or not it is valid to create a PAYS action request -
  function validPayBuff() private pure {
    // Get pointer to current buffer - if zero, create a new buffer -
    if (buffPtr() == bytes32(0))
      startBuffer();

    // Ensure that the current action is not &#39;paying&#39;, and that the buffer has not already
    // completed an PAYS action -
    if (paid() != 0 || currentAction() == PAYS)
      revert(&#39;Duplicate request - pays&#39;);
  }

  // Placeholder function when no pre or post condition for a function is needed
  function none() private pure { }

  // Runtime getters: //

  // Returns the execution id from memory -
  function execID() internal pure returns (bytes32 exec_id) {
    assembly { exec_id := mload(0x80) }
    require(exec_id != bytes32(0), "Execution id overwritten, or not read");
  }

  // Returns the original sender from memory -
  function sender() internal pure returns (address addr) {
    assembly { addr := mload(0xa0) }
    require(addr != address(0), "Sender address overwritten, or not read");
  }

  // Reading from storage: //

  // Reads from storage, resolving the passed-in location to its true location in storage
  // by hashing with the exec id. Returns the data read from that location
  function read(bytes32 _location) internal view returns (bytes32 data) {
    data = keccak256(_location, execID());
    assembly { data := sload(data) }
  }

  // Storing data, emitting events, and forwarding payments: //

  bytes4 internal constant EMITS = bytes4(keccak256(&#39;Emit((bytes32[],bytes)[])&#39;));
  bytes4 internal constant STORES = bytes4(keccak256(&#39;Store(bytes32[])&#39;));
  bytes4 internal constant PAYS = bytes4(keccak256(&#39;Pay(bytes32[])&#39;));
  bytes4 internal constant THROWS = bytes4(keccak256(&#39;Error(string)&#39;));

  // Function enums -
  enum NextFunction {
    INVALID, NONE, STORE_DEST, VAL_SET, VAL_INC, VAL_DEC, EMIT_LOG, PAY_DEST, PAY_AMT
  }

  // Checks that a call pushing a storage destination to the buffer is expected and valid
  function validStoreDest() private pure {
    // Ensure that the next function expected pushes a storage destination -
    if (expected() != NextFunction.STORE_DEST)
      revert(&#39;Unexpected function order - expected storage destination to be pushed&#39;);

    // Ensure that the current buffer is pushing STORES actions -
    isStoring();
  }

  // Checks that a call pushing a storage value to the buffer is expected and valid
  function validStoreVal() private pure {
    // Ensure that the next function expected pushes a storage value -
    if (
      expected() != NextFunction.VAL_SET &&
      expected() != NextFunction.VAL_INC &&
      expected() != NextFunction.VAL_DEC
    ) revert(&#39;Unexpected function order - expected storage value to be pushed&#39;);

    // Ensure that the current buffer is pushing STORES actions -
    isStoring();
  }

  // Checks that a call pushing a payment destination to the buffer is expected and valid
  function validPayDest() private pure {
    // Ensure that the next function expected pushes a payment destination -
    if (expected() != NextFunction.PAY_DEST)
      revert(&#39;Unexpected function order - expected payment destination to be pushed&#39;);

    // Ensure that the current buffer is pushing PAYS actions -
    isPaying();
  }

  // Checks that a call pushing a payment amount to the buffer is expected and valid
  function validPayAmt() private pure {
    // Ensure that the next function expected pushes a payment amount -
    if (expected() != NextFunction.PAY_AMT)
      revert(&#39;Unexpected function order - expected payment amount to be pushed&#39;);

    // Ensure that the current buffer is pushing PAYS actions -
    isPaying();
  }

  // Checks that a call pushing an event to the buffer is expected and valid
  function validEvent() private pure {
    // Ensure that the next function expected pushes an event -
    if (expected() != NextFunction.EMIT_LOG)
      revert(&#39;Unexpected function order - expected event to be pushed&#39;);

    // Ensure that the current buffer is pushing EMITS actions -
    isEmitting();
  }

  // Begins creating a storage buffer - values and locations pushed will be committed
  // to storage at the end of execution
  function storing() conditions(validStoreBuff, isStoring) internal pure {
    bytes4 action_req = STORES;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the &#39;current action&#39; slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      // Push &#39;0&#39; to the end of the 4 bytes just pushed - this will be the length of the STORES action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (STORES) -
      mstore(0xe0, action_req)
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Sets a passed in location to a value passed in via &#39;to&#39;
  function set(bytes32 _field) conditions(validStoreDest, validStoreVal) internal pure returns (bytes32) {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_SET
      mstore(0x100, 3)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
    }
    // Update free memory pointer
    setFreeMem();
    return _field;
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32, bytes32 _val) conditions(validStoreVal, validStoreDest) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _val)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, uint _val) internal pure {
    to(_field, bytes32(_val));
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, address _val) internal pure {
    to(_field, bytes32(_val));
  }

  // Sets a previously-passed-in destination in storage to the value
  function to(bytes32 _field, bool _val) internal pure {
    to(
      _field,
      _val ? bytes32(1) : bytes32(0)
    );
  }

  function increase(bytes32 _field) conditions(validStoreDest, validStoreVal) internal view returns (bytes32 val) {
    // Read value stored at the location in storage -
    val = keccak256(_field, execID());
    assembly {
      val := sload(val)
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_INC
      mstore(0x100, 4)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
    }
    // Update free memory pointer
    setFreeMem();
    return val;
  }

  function decrease(bytes32 _field) conditions(validStoreDest, validStoreVal) internal view returns (bytes32 val) {
    // Read value stored at the location in storage -
    val = keccak256(_field, execID());
    assembly {
      val := sload(val)
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _field)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - VAL_DEC
      mstore(0x100, 5)
      // Increment STORES action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of storage slots pushed to -
      mstore(0x120, add(1, mload(0x120)))
    }
    // Update free memory pointer
    setFreeMem();
    return val;
  }

  function by(bytes32 _val, uint _amt) conditions(validStoreVal, validStoreDest) internal pure {
    // Check the expected function type - if it is VAL_INC, perform safe-add on the value
    // If it is VAL_DEC, perform safe-sub on the value
    if (expected() == NextFunction.VAL_INC)
      _amt = _amt.add(uint(_val));
    else if (expected() == NextFunction.VAL_DEC)
      _amt = uint(_val).sub(_amt);
    else
      revert(&#39;Expected VAL_INC or VAL_DEC&#39;);

    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amt)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Decreases the value at some field by a maximum amount, and sets it to 0 if there will be underflow
  function byMaximum(bytes32 _val, uint _amt) conditions(validStoreVal, validStoreDest) internal pure {
    // Check the expected function type - if it is VAL_DEC, set the new amount to the difference of
    // _val and _amt, to a minimum of 0
    if (expected() == NextFunction.VAL_DEC) {
      if (_amt >= uint(_val))
        _amt = 0;
      else
        _amt = uint(_val).sub(_amt);
    } else {
      revert(&#39;Expected VAL_DEC&#39;);
    }

    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push storage value to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amt)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - STORE_DEST
      mstore(0x100, 2)
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Begins creating an event log buffer - topics and data pushed will be emitted by
  // storage at the end of execution
  function emitting() conditions(validEmitBuff, isEmitting) internal pure {
    bytes4 action_req = EMITS;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the &#39;current action&#39; slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      // Push &#39;0&#39; to the end of the 4 bytes just pushed - this will be the length of the EMITS action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (EMITS) -
      mstore(0xe0, action_req)
      // Set the expected next function - EMIT_LOG
      mstore(0x100, 6)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  function log(bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 0 to the end of the buffer - event will have 0 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 0)
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x40, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x40 plus the original length
        mstore(ptr, add(0x40, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x40, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0x60, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0x60 plus the original length
        mstore(ptr, add(0x60, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  function log(bytes32[1] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 1 to the end of the buffer - event will have 1 topic
      mstore(add(0x20, add(ptr, mload(ptr))), 1)
      // Push topic to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x60, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x60 plus the original length
        mstore(ptr, add(0x60, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x60, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0x80, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0x80 plus the original length
        mstore(ptr, add(0x80, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  function log(bytes32[2] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 2 to the end of the buffer - event will have 2 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 2)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0x80, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0x80 plus the original length
        mstore(ptr, add(0x80, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0x80, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xa0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xa0 plus the original length
        mstore(ptr, add(0xa0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  function log(bytes32[3] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 3 to the end of the buffer - event will have 3 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 3)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      mstore(add(0x80, add(ptr, mload(ptr))), mload(add(0x40, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0xa0, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0xa0 plus the original length
        mstore(ptr, add(0xa0, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0xa0, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xc0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xc0 plus the original length
        mstore(ptr, add(0xc0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  function log(bytes32[4] memory _topics, bytes32 _data) conditions(validEvent, validEvent) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push 4 to the end of the buffer - event will have 4 topics
      mstore(add(0x20, add(ptr, mload(ptr))), 4)
      // Push topics to end of buffer
      mstore(add(0x40, add(ptr, mload(ptr))), mload(_topics))
      mstore(add(0x60, add(ptr, mload(ptr))), mload(add(0x20, _topics)))
      mstore(add(0x80, add(ptr, mload(ptr))), mload(add(0x40, _topics)))
      mstore(add(0xa0, add(ptr, mload(ptr))), mload(add(0x60, _topics)))
      // If _data is zero, set data size to 0 in buffer and push -
      if eq(_data, 0) {
        mstore(add(0xc0, add(ptr, mload(ptr))), 0)
        // Increment buffer length - 0xc0 plus the original length
        mstore(ptr, add(0xc0, mload(ptr)))
      }
      // If _data is not zero, set size to 0x20 and push to buffer -
      if iszero(eq(_data, 0)) {
        // Push data size (0x20) to the end of the buffer
        mstore(add(0xc0, add(ptr, mload(ptr))), 0x20)
        // Push data to the end of the buffer
        mstore(add(0xe0, add(ptr, mload(ptr))), _data)
        // Increment buffer length - 0xe0 plus the original length
        mstore(ptr, add(0xe0, mload(ptr)))
      }
      // Increment EMITS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of events pushed to buffer -
      mstore(0x140, add(1, mload(0x140)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Begins creating a storage buffer - destinations entered will be forwarded wei
  // before the end of execution
  function paying() conditions(validPayBuff, isPaying) internal pure {
    bytes4 action_req = PAYS;
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push requestor to the end of buffer, as well as to the &#39;current action&#39; slot -
      mstore(add(0x20, add(ptr, mload(ptr))), action_req)
      // Push &#39;0&#39; to the end of the 4 bytes just pushed - this will be the length of the PAYS action
      mstore(add(0x24, add(ptr, mload(ptr))), 0)
      // Increment buffer length - 0x24 plus the previous length
      mstore(ptr, add(0x24, mload(ptr)))
      // Set the current action being executed (PAYS) -
      mstore(0xe0, action_req)
      // Set the expected next function - PAY_AMT
      mstore(0x100, 8)
      // Set a pointer to the length of the current request within the buffer
      mstore(sub(ptr, 0x20), add(ptr, mload(ptr)))
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Pushes an amount of wei to forward to the buffer
  function pay(uint _amount) conditions(validPayAmt, validPayDest) internal pure returns (uint) {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push payment amount to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _amount)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - PAY_DEST
      mstore(0x100, 7)
      // Increment PAYS action length -
      mstore(
        mload(sub(ptr, 0x20)),
        add(1, mload(mload(sub(ptr, 0x20))))
      )
      // Update number of payment destinations to be pushed to -
      mstore(0x160, add(1, mload(0x160)))
    }
    // Update free memory pointer
    setFreeMem();
    return _amount;
  }

  // Push an address to forward wei to, to the buffer
  function toAcc(uint, address _dest) conditions(validPayDest, validPayAmt) internal pure {
    assembly {
      // Get pointer to buffer length -
      let ptr := add(0x20, mload(0xc0))
      // Push payment destination to the end of the buffer -
      mstore(add(0x20, add(ptr, mload(ptr))), _dest)
      // Increment buffer length - 0x20 plus the previous length
      mstore(ptr, add(0x20, mload(ptr)))
      // Set the expected next function - PAY_AMT
      mstore(0x100, 8)
    }
    // Update free memory pointer
    setFreeMem();
  }

  // Sets the free memory pointer to point beyond all accessed memory
  function setFreeMem() private pure {
    assembly { mstore(0x40, msize) }
  }

  // Returns the enum representing the next expected function to be called -
  function expected() private pure returns (NextFunction next) {
    assembly { next := mload(0x100) }
  }

  // Returns the number of events pushed to the storage buffer -
  function emitted() internal pure returns (uint num_emitted) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number emitted from buffer -
    assembly { num_emitted := mload(0x140) }
  }

  // Returns the number of storage slots pushed to the storage buffer -
  function stored() internal pure returns (uint num_stored) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number stored from buffer -
    assembly { num_stored := mload(0x120) }
  }

  // Returns the number of payment destinations and amounts pushed to the storage buffer -
  function paid() internal pure returns (uint num_paid) {
    if (buffPtr() == bytes32(0))
      return 0;

    // Load number paid from buffer -
    assembly { num_paid := mload(0x160) }
  }
}

library ArrayUtils {

  function toBytes4Arr(bytes32[] memory _arr) internal pure returns (bytes4[] memory _conv) {
    assembly { _conv := _arr }
  }

  function toAddressArr(bytes32[] memory _arr) internal pure returns (address[] memory _conv) {
    assembly { _conv := _arr }
  }

  function toUintArr(bytes32[] memory _arr) internal pure returns (uint[] memory _conv) {
    assembly { _conv := _arr }
  }
}

interface GetterInterface {
  function read(bytes32 exec_id, bytes32 location) external view returns (bytes32 data);
  function readMulti(bytes32 exec_id, bytes32[] locations) external view returns (bytes32[] data);
}

library MintedCappedIdx {

  using Contract for *;
  using SafeMath for uint;
  using ArrayUtils for bytes32[];

  bytes32 internal constant EXEC_PERMISSIONS = keccak256(&#39;script_exec_permissions&#39;);

  // Returns the storage location of a script execution address&#39;s permissions -
  function execPermissions(address _exec) internal pure returns (bytes32)
    { return keccak256(_exec, EXEC_PERMISSIONS); }

  /// SALE ///

  // Storage location of crowdsale admin address
  function admin() internal pure returns (bytes32)
    { return keccak256(&#39;sale_admin&#39;); }

  // Whether the crowdsale and token are configured, and the sale is ready to run
  function isConfigured() internal pure returns (bytes32)
    { return keccak256("sale_is_configured"); }

  // Whether or not the crowdsale is post-purchase
  function isFinished() internal pure returns (bytes32)
    { return keccak256("sale_is_completed"); }

  // Storage location of the crowdsale&#39;s start time
  function startTime() internal pure returns (bytes32)
    { return keccak256("sale_start_time"); }

  // Storage location of the amount of time the crowdsale will take, accounting for all tiers
  function totalDuration() internal pure returns (bytes32)
    { return keccak256("sale_total_duration"); }

  // Storage location of the amount of tokens sold in the crowdsale so far. Does not include reserved tokens
  function tokensSold() internal pure returns (bytes32)
    { return keccak256("sale_tokens_sold"); }

  // Stores the amount of unique contributors so far in this crowdsale
  function contributors() internal pure returns (bytes32)
    { return keccak256("sale_contributors"); }

  // Maps addresses to a boolean indicating whether or not this address has contributed
  function hasContributed(address _purchaser) internal pure returns (bytes32)
    { return keccak256(_purchaser, contributors()); }

  /// TIERS ///

  // Stores the number of tiers in the sale
  function saleTierList() internal pure returns (bytes32)
    { return keccak256("sale_tier_list"); }

  // Stores the name of the tier
  function tierName(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "name", saleTierList()); }

  // Stores the number of tokens that will be sold in the tier
  function tierCap(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "cap", saleTierList()); }

  // Stores the price of a token (1 * 10^decimals units), in wei
  function tierPrice(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "price", saleTierList()); }

  // Stores the minimum number of tokens a user must purchase for a given tier
  function tierMin(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "minimum", saleTierList()); }

  // Stores the duration of a tier
  function tierDuration(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "duration", saleTierList()); }

  // Whether or not the tier&#39;s duration is modifiable (before it has begin)
  function tierModifiable(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "mod_stat", saleTierList()); }

  // Returns the storage location of the tier&#39;s whitelist status
  function tierWhitelisted(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "wl_stat", saleTierList()); }

  // Storage location of the index of the current tier. If zero, no tier is currently active
  function currentTier() internal pure returns (bytes32)
    { return keccak256("sale_current_tier"); }

  // Storage location of the end time of the current tier. Purchase attempts beyond this time will update the current tier (if another is available)
  function currentEndsAt() internal pure returns (bytes32)
    { return keccak256("current_tier_ends_at"); }

  // Storage location of the total number of tokens remaining for purchase in the current tier
  function currentTokensRemaining() internal pure returns (bytes32)
    { return keccak256("current_tier_tokens_remaining"); }

  /// FUNDS ///

  // Storage location of team funds wallet
  function wallet() internal pure returns (bytes32)
    { return keccak256("sale_destination_wallet"); }

  // Storage location of amount of wei raised during the crowdsale, total
  function totalWeiRaised() internal pure returns (bytes32)
    { return keccak256("sale_tot_wei_raised"); }

  /// WHITELIST ///

  // Stores a tier&#39;s whitelist
  function tierWhitelist(uint _idx) internal pure returns (bytes32)
    { return keccak256(_idx, "tier_whitelists"); }

  // Stores a spender&#39;s minimum token purchase amount for a given whitelisted tier
  function whitelistMinTok(uint _idx, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "min_tok", tierWhitelist(_idx)); }

  // Stores a spender&#39;s maximum number of tokens allowed to be purchased
  function whitelistMaxTok(uint _idx, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "max_tok", tierWhitelist(_idx)); }

  /// TOKEN ///

  // Storage location for token name
  function tokenName() internal pure returns (bytes32)
    { return keccak256("token_name"); }

  // Storage location for token ticker symbol
  function tokenSymbol() internal pure returns (bytes32)
    { return keccak256("token_symbol"); }

  // Storage location for token decimals
  function tokenDecimals() internal pure returns (bytes32)
    { return keccak256("token_decimals"); }

  // Storage location for token totalSupply
  function tokenTotalSupply() internal pure returns (bytes32)
    { return keccak256("token_total_supply"); }

  // Storage seed for user balances mapping
  bytes32 internal constant TOKEN_BALANCES = keccak256("token_balances");

  function balances(address _owner) internal pure returns (bytes32)
    { return keccak256(_owner, TOKEN_BALANCES); }

  // Storage seed for user allowances mapping
  bytes32 internal constant TOKEN_ALLOWANCES = keccak256("token_allowances");

  function allowed(address _owner, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, keccak256(_owner, TOKEN_ALLOWANCES)); }

  // Storage seed for token &#39;transfer agent&#39; status for any address
  // Transfer agents can transfer tokens, even if the crowdsale has not yet been finalized
  bytes32 internal constant TOKEN_TRANSFER_AGENTS = keccak256("token_transfer_agents");

  function transferAgents(address _agent) internal pure returns (bytes32)
    { return keccak256(_agent, TOKEN_TRANSFER_AGENTS); }

  // Whether or not the token is unlocked for transfers
  function tokensUnlocked() internal pure returns (bytes32)
    { return keccak256(&#39;sale_tokens_unlocked&#39;); }

  /// RESERVED TOKENS ///

  // Stores the number of addresses for which tokens are reserved
  function reservedDestinations() internal pure returns (bytes32)
    { return keccak256("reserved_token_dest_list"); }

  // Stores the index of an address in the reservedDestinations list (1-indexed)
  function destIndex(address _destination) internal pure returns (bytes32)
    { return keccak256(_destination, "index", reservedDestinations()); }

  // Stores the number of tokens reserved for a destination
  function destTokens(address _destination) internal pure returns (bytes32)
    { return keccak256(_destination, "numtokens", reservedDestinations()); }

  // Stores the number of percent of tokens sold reserved for a destination
  function destPercent(address _destination) internal pure returns (bytes32)
    { return keccak256(_destination, "numpercent", reservedDestinations()); }

  // Stores the number of decimals in the previous percentage (2 are added by default)
  function destPrecision(address _destination) internal pure returns (bytes32)
    { return keccak256(_destination, "precision", reservedDestinations()); }

  /*
  Creates a crowdsale with initial conditions. The admin should now initialize the crowdsale&#39;s token, as well
  as any additional tiers of the crowdsale that will exist, followed by finalizing the initialization of the crowdsale.

  @param _team_wallet: The team funds wallet, where crowdsale purchases are forwarded
  @param _start_time: The start time of the initial tier of the crowdsale
  @param _initial_tier_name: The name of the initial tier of the crowdsale
  @param _initial_tier_price: The price of each token purchased in wei, for the initial crowdsale tier
  @param _initial_tier_duration: The duration of the initial tier of the crowdsale
  @param _initial_tier_token_sell_cap: The maximum number of tokens that can be sold during the initial tier
  @param _initial_tier_min_purchase: The minimum number of tokens that must be purchased by a user in the initial tier
  @param _initial_tier_is_whitelisted: Whether the initial tier of the crowdsale requires an address be whitelisted for successful purchase
  @param _initial_tier_duration_is_modifiable: Whether the initial tier of the crowdsale has a modifiable duration
  @param _admin: A privileged address which is able to complete the crowdsale initialization process
  */
  function init(
    address _team_wallet,
    uint _start_time,
    bytes32 _initial_tier_name,
    uint _initial_tier_price,
    uint _initial_tier_duration,
    uint _initial_tier_token_sell_cap,
    uint _initial_tier_min_purchase,
    bool _initial_tier_is_whitelisted,
    bool _initial_tier_duration_is_modifiable,
    address _admin
  ) external view {
    // Begin execution - we are initializing an instance of this application
    Contract.initialize();

    // Ensure valid input
    if (
      _team_wallet == 0
      || _initial_tier_price == 0
      || _start_time < now
      || _start_time + _initial_tier_duration <= _start_time
      || _initial_tier_token_sell_cap == 0
      || _admin == address(0)
    ) revert(&#39;improper initialization&#39;);

    // Set up STORES action requests -
    Contract.storing();
    // Authorize sender as an executor for this instance -
    Contract.set(execPermissions(msg.sender)).to(true);
    // Store admin address, team wallet, initial tier duration, and sale start time
    Contract.set(admin()).to(_admin);
    Contract.set(wallet()).to(_team_wallet);
    Contract.set(totalDuration()).to(_initial_tier_duration);
    Contract.set(startTime()).to(_start_time);
    // Store initial crowdsale tier list length and initial tier information
    Contract.set(saleTierList()).to(uint(1));
    // Tier name
    Contract.set(tierName(uint(0))).to(_initial_tier_name);
    // Tier token sell cap
    Contract.set(tierCap(uint(0))).to(_initial_tier_token_sell_cap);
    // Tier purchase price
    Contract.set(tierPrice(uint(0))).to(_initial_tier_price);
    // Tier active duration
    Contract.set(tierDuration(uint(0))).to(_initial_tier_duration);
    // Tier minimum purchase size
    Contract.set(tierMin(uint(0))).to(_initial_tier_min_purchase);
    // Whether this tier&#39;s duration is modifiable prior to its start time
    Contract.set(tierModifiable(uint(0))).to(_initial_tier_duration_is_modifiable);
    // Whether this tier requires an address be whitelisted to complete token purchase
    Contract.set(tierWhitelisted(uint(0))).to(_initial_tier_is_whitelisted);

    // Store current crowdsale tier (offset by 1)
    Contract.set(currentTier()).to(uint(1));
    // Store current tier end time
    Contract.set(currentEndsAt()).to(_initial_tier_duration.add(_start_time));
    // Store current tier tokens remaining
    Contract.set(currentTokensRemaining()).to(_initial_tier_token_sell_cap);

    Contract.commit();
  }

  /// CROWDSALE GETTERS ///

  // Returns the address of the admin of the crowdsale
  function getAdmin(address _storage, bytes32 _exec_id) external view returns (address)
    { return address(GetterInterface(_storage).read(_exec_id, admin())); }

  /*
  Returns basic information on a sale

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @return wei_raised: The amount of wei raised in the crowdsale so far
  @return team_wallet: The address to which funds are forwarded during this crowdsale
  @return is_initialized: Whether or not the crowdsale has been completely initialized by the admin
  @return is_finalized: Whether or not the crowdsale has been completely finalized by the admin
  */
  function getCrowdsaleInfo(address _storage, bytes32 _exec_id) external view
  returns (uint wei_raised, address team_wallet, bool is_initialized, bool is_finalized) {

    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory arr_indices = new bytes32[](4);

    arr_indices[0] = totalWeiRaised();
    arr_indices[1] = wallet();
    arr_indices[2] = isConfigured();
    arr_indices[3] = isFinished();

    bytes32[] memory read_values = target.readMulti(_exec_id, arr_indices);

    // Get returned data -
    wei_raised = uint(read_values[0]);
    team_wallet = address(read_values[1]);
    is_initialized = (read_values[2] == 0 ? false : true);
    is_finalized = (read_values[3] == 0 ? false : true);
  }

  /*
  Returns true if all tiers have been completely sold out

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @return is_crowdsale_full: Whether or not the total number of tokens to sell in the crowdsale has been reached
  @return max_sellable: The total number of tokens that can be sold in the crowdsale
  */
  function isCrowdsaleFull(address _storage, bytes32 _exec_id) external view returns (bool is_crowdsale_full, uint max_sellable) {
    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory initial_arr = new bytes32[](2);
    // Push crowdsale tier list length and total tokens sold storage locations to buffer
    initial_arr[0] = saleTierList();
    initial_arr[1] = tokensSold();
    // Read from storage
    uint[] memory read_values = target.readMulti(_exec_id, initial_arr).toUintArr();

    // Get number of tiers and tokens sold
    uint num_tiers = read_values[0];
    uint _tokens_sold = read_values[1];

    bytes32[] memory arr_indices = new bytes32[](num_tiers);
    // Loop through tier cap locations, and add each to the calldata buffer
    for (uint i = 0; i < num_tiers; i++)
      arr_indices[i] = tierCap(i);

    // Read from storage
    read_values = target.readMulti(_exec_id, arr_indices).toUintArr();
    // Ensure correct return length
    assert(read_values.length == num_tiers);

    // Loop through returned values, and get the sum of all tier token sell caps
    for (i = 0; i < read_values.length; i++)
      max_sellable += read_values[i];

    // Get return value
    is_crowdsale_full = (_tokens_sold >= max_sellable ? true : false);
  }

  // Returns the number of unique contributors to a crowdsale
  function getCrowdsaleUniqueBuyers(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, contributors())); }

  /*
  Returns the start and end time of the crowdsale

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @return start_time: The start time of the first tier of a crowdsale
  @return end_time: The time at which the crowdsale ends
  */
  function getCrowdsaleStartAndEndTimes(address _storage, bytes32 _exec_id) external view returns (uint start_time, uint end_time) {
    bytes32[] memory arr_indices = new bytes32[](2);
    arr_indices[0] = startTime();
    arr_indices[1] = totalDuration();

    // Read from storage
    uint[] memory read_values = GetterInterface(_storage).readMulti(_exec_id, arr_indices).toUintArr();

    // Get return values
    start_time = read_values[0];
    end_time = start_time + read_values[1];
  }

  /*
  Returns information on the current crowdsale tier

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @return tier_name: The name of the current tier
  @return tier_index: The current tier&#39;s index in the crowdsale_tiers() list
  @return tier_ends_at: The time at which purcahses for the current tier are forcibly locked
  @return tier_tokens_remaining: The amount of tokens remaining to be purchased in the current tier
  @return tier_price: The price of each token purchased this tier, in wei
  @return tier_min: The minimum amount of tokens that much be purchased by an investor this tier
  @return duration_is_modifiable: Whether the crowdsale admin can update the duration of this tier before it starts
  @return is_whitelisted: Whether an address must be whitelisted to participate in this tier
  */
  function getCurrentTierInfo(address _storage, bytes32 _exec_id) external view
  returns (bytes32 tier_name, uint tier_index, uint tier_ends_at, uint tier_tokens_remaining, uint tier_price, uint tier_min, bool duration_is_modifiable, bool is_whitelisted) {

    bytes32[] memory initial_arr = new bytes32[](4);
    // Push current tier expiration time, current tier index, and current tier tokens remaining storage locations to calldata buffer
    initial_arr[0] = currentEndsAt();
    initial_arr[1] = currentTier();
    initial_arr[2] = currentTokensRemaining();
    initial_arr[3] = saleTierList();
    // Read from storage and store return in buffer
    uint[] memory read_values = GetterInterface(_storage).readMulti(_exec_id, initial_arr).toUintArr();
    // Ensure correct return length
    assert(read_values.length == 4);

    // If the returned index was 0, current tier does not exist: return now
    if (read_values[1] == 0)
      return;

    // Get returned values -
    tier_ends_at = read_values[0];
    // Indices are stored as 1 + (actual index), to avoid conflicts with a default 0 value
    tier_index = read_values[1] - 1;
    tier_tokens_remaining = read_values[2];
    uint num_tiers = read_values[3];
    bool updated_tier;

    // If it is beyond the tier&#39;s end time, loop through tiers until the current one is found
    while (now >= tier_ends_at && ++tier_index < num_tiers) {
      tier_ends_at += uint(GetterInterface(_storage).read(_exec_id, tierDuration(tier_index)));
      updated_tier = true;
    }

    // If we have passed the last tier, return default values
    if (tier_index >= num_tiers)
      return (0, 0, 0, 0, 0, 0, false, false);

    initial_arr = new bytes32[](6);
    initial_arr[0] = tierName(tier_index);
    initial_arr[1] = tierPrice(tier_index);
    initial_arr[2] = tierModifiable(tier_index);
    initial_arr[3] = tierWhitelisted(tier_index);
    initial_arr[4] = tierMin(tier_index);
    initial_arr[5] = tierCap(tier_index);

    // Read from storage and get return values
    read_values = GetterInterface(_storage).readMulti(_exec_id, initial_arr).toUintArr();

    // Ensure correct return length
    assert(read_values.length == 6);

    tier_name = bytes32(read_values[0]);
    tier_price = read_values[1];
    duration_is_modifiable = (read_values[2] == 0 ? false : true);
    is_whitelisted = (read_values[3] == 0 ? false : true);
    tier_min = read_values[4];
    if (updated_tier)
      tier_tokens_remaining = read_values[5];
  }

  /*
  Returns information on a given tier

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @param _index: The index of the tier in the crowdsale tier list. Input index should be like a normal array index (lowest index: 0)
  @return tier_name: The name of the returned tier
  @return tier_sell_cap: The amount of tokens designated to be sold during this tier
  @return tier_price: The price of each token in wei for this tier
  @return tier_min: The minimum amount of tokens that much be purchased by an investor this tier
  @return tier_duration: The duration of the given tier
  @return duration_is_modifiable: Whether the crowdsale admin can change the duration of this tier prior to its start time
  @return is_whitelisted: Whether an address must be whitelisted to participate in this tier
  */
  function getCrowdsaleTier(address _storage, bytes32 _exec_id, uint _index) external view
  returns (bytes32 tier_name, uint tier_sell_cap, uint tier_price, uint tier_min, uint tier_duration, bool duration_is_modifiable, bool is_whitelisted) {
    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory arr_indices = new bytes32[](7);
    // Push tier name, sell cap, duration, and modifiable status storage locations to buffer
    arr_indices[0] = tierName(_index);
    arr_indices[1] = tierCap(_index);
    arr_indices[2] = tierPrice(_index);
    arr_indices[3] = tierDuration(_index);
    arr_indices[4] = tierModifiable(_index);
    arr_indices[5] = tierWhitelisted(_index);
    arr_indices[6] = tierMin(_index);
    // Read from storage and store return in buffer
    bytes32[] memory read_values = target.readMulti(_exec_id, arr_indices);
    // Ensure correct return length
    assert(read_values.length == 7);

    // Get returned values -
    tier_name = read_values[0];
    tier_sell_cap = uint(read_values[1]);
    tier_price = uint(read_values[2]);
    tier_duration = uint(read_values[3]);
    duration_is_modifiable = (read_values[4] == 0 ? false : true);
    is_whitelisted = (read_values[5] == 0 ? false : true);
    tier_min = uint(read_values[6]);
  }

  /*
  Returns the maximum amount of wei to raise, as well as the total amount of tokens that can be sold

  @param _storage: The storage address of the crowdsale application
  @param _exec_id: The execution id of the application
  @return wei_raise_cap: The maximum amount of wei to raise
  @return total_sell_cap: The maximum amount of tokens to sell
  */
  function getCrowdsaleMaxRaise(address _storage, bytes32 _exec_id) external view returns (uint wei_raise_cap, uint total_sell_cap) {
    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory arr_indices = new bytes32[](3);
    // Push crowdsale tier list length, token decimals, and token name storage locations to buffer
    arr_indices[0] = saleTierList();
    arr_indices[1] = tokenDecimals();
    arr_indices[2] = tokenName();

    // Read from storage
    uint[] memory read_values = target.readMulti(_exec_id, arr_indices).toUintArr();
    // Ensure correct return length
    assert(read_values.length == 3);

    // Get number of crowdsale tiers
    uint num_tiers = read_values[0];
    // Get number of token decimals
    uint num_decimals = read_values[1];

    // If the token has not been set, return
    if (read_values[2] == 0)
      return (0, 0);

    // Overwrite previous buffer - push exec id, data read offset, and read size to buffer
    bytes32[] memory last_arr = new bytes32[](2 * num_tiers);
    // Loop through tiers and get sell cap and purchase price for each tier
    for (uint i = 0; i < 2 * num_tiers; i += 2) {
      last_arr[i] = tierCap(i / 2);
      last_arr[i + 1] = tierPrice(i / 2);
    }

    // Read from storage
    read_values = target.readMulti(_exec_id, last_arr).toUintArr();
    // Ensure correct return length
    assert(read_values.length == 2 * num_tiers);

    // Loop through and get wei raise cap and token sell cap
    for (i = 0; i < read_values.length; i+=2) {
      total_sell_cap += read_values[i];
      // Increase maximum wei able to be raised - (tier token sell cap) * (tier price in wei) / (10 ^ decimals)
      wei_raise_cap += (read_values[i] * read_values[i + 1]) / (10 ** num_decimals);
    }
  }

  /*
  Returns a list of the named tiers of the crowdsale

  @param _storage: The storage address of the crowdsale application
  @param _exec_id: The execution id of the application
  @return crowdsale_tiers: A list of each tier of the crowdsale
  */
  function getCrowdsaleTierList(address _storage, bytes32 _exec_id) external view returns (bytes32[] memory crowdsale_tiers) {
    GetterInterface target = GetterInterface(_storage);
    // Read from storage and get list length
    uint list_length = uint(target.read(_exec_id, saleTierList()));

    bytes32[] memory arr_indices = new bytes32[](list_length);
    // Loop over each tier name list location and add to buffer
    for (uint i = 0; i < list_length; i++)
      arr_indices[i] = tierName(i);

    // Read from storage and return
    crowdsale_tiers = target.readMulti(_exec_id, arr_indices);
  }

  /*
  Loops through all tiers and their durations, and returns the passed-in index&#39;s start and end dates

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @param _index: The index of the tier in the crowdsale tier list. Input index should be like a normal array index (lowest index: 0)
  @return tier_start: The time when the given tier starts
  @return tier_end: The time at which the given tier ends
  */
  function getTierStartAndEndDates(address _storage, bytes32 _exec_id, uint _index) external view returns (uint tier_start, uint tier_end) {
    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory arr_indices = new bytes32[](3 + _index);

    // Add crowdsale tier list length and crowdsale start time to buffer
    arr_indices[0] = saleTierList();
    arr_indices[1] = startTime();

    for (uint i = 0; i <= _index; i++)
      arr_indices[2 + i] = tierDuration(i);

    // Read from storage and store return in buffer
    uint[] memory read_values = target.readMulti(_exec_id, arr_indices).toUintArr();
    // Ensure correct return length
    assert(read_values.length == 3 + _index);

    // Check that the passed-in index is within the range of the tier list
    if (read_values[0] <= _index)
      return (0, 0);

    // Get returned start time, then loop through each returned duration and get the start time for the tier
    tier_start = read_values[1];
    for (i = 0; i < _index; i++)
      tier_start += read_values[2 + i];

    // Get the tier end time - start time plus the duration of the tier, the last read value in the list
    tier_end = tier_start + read_values[read_values.length - 1];
  }

  // Returns the number of tokens sold so far this crowdsale
  function getTokensSold(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokensSold())); }

  /*
  Returns whitelist information for a given buyer

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @param _tier_index: The index of the tier about which the whitelist information will be pulled
  @param _buyer: The address of the user whose whitelist status will be returned
  @return minimum_purchase_amt: The minimum ammount of tokens the buyer must purchase
  @return max_tokens_remaining: The maximum amount of tokens able to be purchased by the user in this tier
  */
  function getWhitelistStatus(address _storage, bytes32 _exec_id, uint _tier_index, address _buyer) external view
  returns (uint minimum_purchase_amt, uint max_tokens_remaining) {
    GetterInterface target = GetterInterface(_storage);

    bytes32[] memory arr_indices = new bytes32[](2);
    // Push whitelist minimum contribution location to buffer
    arr_indices[0] = whitelistMinTok(_tier_index, _buyer);
    // Push whitlist maximum spend amount remaining location to buffer
    arr_indices[1] = whitelistMaxTok(_tier_index, _buyer);

    // Read from storage and return
    uint[] memory read_values = target.readMulti(_exec_id, arr_indices).toUintArr();
    // Ensure correct return length
    assert(read_values.length == 2);

    minimum_purchase_amt = read_values[0];
    max_tokens_remaining = read_values[1];
  }

  /*
  Returns the list of whitelisted buyers for a given tier

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @param _tier_index: The index of the tier about which the whitelist information will be pulled
  @return num_whitelisted: The length of the tier&#39;s whitelist array
  @return whitelist: The tier&#39;s whitelisted addresses
  */
  function getTierWhitelist(address _storage, bytes32 _exec_id, uint _tier_index) external view returns (uint num_whitelisted, address[] memory whitelist) {
    // Read from storage and get returned tier whitelist length
    num_whitelisted = uint(GetterInterface(_storage).read(_exec_id, tierWhitelist(_tier_index)));

    // If there are no whitelisted addresses, return
    if (num_whitelisted == 0)
      return;

    bytes32[] memory arr_indices = new bytes32[](num_whitelisted);
    // Loop through the number of whitelisted addresses, and push each to the calldata buffer to be read from storage
    for (uint i = 0; i < num_whitelisted; i++)
      arr_indices[i] = bytes32(32 + (32 * i) + uint(tierWhitelist(_tier_index)));

    // Read from storage and return
    whitelist = GetterInterface(_storage).readMulti(_exec_id, arr_indices).toAddressArr();
  }

  /// TOKEN GETTERS ///

  // Returns the token balance of an address
  function balanceOf(address _storage, bytes32 _exec_id, address _owner) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, balances(_owner))); }

  // Returns the amount of tokens a spender may spend on an owner&#39;s behalf
  function allowance(address _storage, bytes32 _exec_id, address _owner, address _spender) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, allowed(_owner, _spender))); }

  // Returns the number of display decimals for a token
  function decimals(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokenDecimals())); }

  // Returns the total token supply
  function totalSupply(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokenTotalSupply())); }

  // Returns the token&#39;s name
  function name(address _storage, bytes32 _exec_id) external view returns (bytes32)
    { return GetterInterface(_storage).read(_exec_id, tokenName()); }

  // Returns token&#39;s symbol
  function symbol(address _storage, bytes32 _exec_id) external view returns (bytes32)
    { return GetterInterface(_storage).read(_exec_id, tokenSymbol()); }

  /*
  Returns general information on a token - name, symbol, decimals, and total supply

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under which storage for this instance is located
  @return token_name: The name of the token
  @return token_symbol: The token ticker symbol
  @return token_decimals: The display decimals for the token
  @return total_supply: The total supply of the token
  */
  function getTokenInfo(address _storage, bytes32 _exec_id) external view
  returns (bytes32 token_name, bytes32 token_symbol, uint token_decimals, uint total_supply) {
    //Set up bytes32 array to hold storage seeds
    bytes32[] memory seed_arr = new bytes32[](4);

    //Assign locations of array to respective seeds
    seed_arr[0] = tokenName();
    seed_arr[1] = tokenSymbol();
    seed_arr[2] = tokenDecimals();
    seed_arr[3] = tokenTotalSupply();

    //Read and return values from storage
    bytes32[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr);

    //Assign values to return params
    token_name = values_arr[0];
    token_symbol = values_arr[1];
    token_decimals = uint(values_arr[2]);
    total_supply = uint(values_arr[3]);
  }

  // Returns whether or not an address is a transfer agent, meaning they can transfer tokens before the crowdsale is finished
  function getTransferAgentStatus(address _storage, bytes32 _exec_id, address _agent) external view returns (bool)
    { return GetterInterface(_storage).read(_exec_id, transferAgents(_agent)) != 0 ? true : false; }

  /*
  Returns information on a reserved token address (the crowdsale admin can set reserved tokens for addresses before initializing the crowdsale)

  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under storage for this app instance is located
  @return num_destinations: The length of the crowdsale&#39;s reserved token destination array
  @return reserved_destinations: A list of the addresses which have reserved tokens or percents
  */
  function getReservedTokenDestinationList(address _storage, bytes32 _exec_id) external view
  returns (uint num_destinations, address[] reserved_destinations) {
    // Read reserved destination list length from storage
    num_destinations = uint(GetterInterface(_storage).read(_exec_id, reservedDestinations()));

    // If num_destinations is 0, return now
    if (num_destinations == 0)
      return (num_destinations, reserved_destinations);

    /// Loop through each list in storage, and get each address -

    bytes32[] memory arr_indices = new bytes32[](num_destinations);
    // Add each destination index location to calldata
    for (uint i = 1; i <= num_destinations; i++)
      arr_indices[i - 1] = bytes32((32 * i) + uint(reservedDestinations()));

    // Read from storage, and return data to buffer
    reserved_destinations = GetterInterface(_storage).readMulti(_exec_id, arr_indices).toAddressArr();
  }

  /*
  Returns information on a reserved token address (the crowdsale admin can set reserved tokens for addresses before initializing the crowdsale)
  @param _storage: The address where application storage is located
  @param _exec_id: The application execution id under storage for this app instance is located
  @param _destination: The address about which reserved token information will be pulled
  @return destination_list_index: The index in the reserved token destination list where this address is found, plus 1. If zero, destination has no reserved tokens
  @return num_tokens: The number of tokens reserved for this address
  @return num_percent: The percent of tokens sold during the crowdsale reserved for this address
  @return percent_decimals: The number of decimals in the above percent reserved - used to calculate with precision
  */
  function getReservedDestinationInfo(address _storage, bytes32 _exec_id, address _destination) external view
  returns (uint destination_list_index, uint num_tokens, uint num_percent, uint percent_decimals) {
    bytes32[] memory arr_indices = new bytes32[](4);
    arr_indices[0] = destIndex(_destination);
    arr_indices[1] = destTokens(_destination);
    arr_indices[2] = destPercent(_destination);
    arr_indices[3] = destPrecision(_destination);

    // Read from storage, and return data to buffer
    bytes32[] memory read_values = GetterInterface(_storage).readMulti(_exec_id, arr_indices);

    // Get returned values -
    destination_list_index = uint(read_values[0]);
    // If the returned list index for the destination is 0, destination is not in list
    if (destination_list_index == 0)
      return;
    destination_list_index--;
    num_tokens = uint(read_values[1]);
    num_percent = uint(read_values[2]);
    percent_decimals = uint(read_values[3]);
  }
}