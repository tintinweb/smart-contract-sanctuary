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

library ConfigureSale {

  using Contract for *;
  using SafeMath for uint;

  // event CrowdsaleTokenInit(bytes32 indexed exec_id, bytes32 indexed name, bytes32 indexed symbol, uint decimals)
  bytes32 private constant INIT_CROWDSALE_TOK_SIG = keccak256("CrowdsaleTokenInit(bytes32,bytes32,bytes32,uint256)");

  // event GlobalMinUpdate(bytes32 indexed exec_id, uint current_token_purchase_min)
  bytes32 private constant GLOBAL_MIN_UPDATE = keccak256("GlobalMinUpdate(bytes32,uint256)");

  // event CrowdsaleTimeUpdated(bytes32 indexed exec_id)
  bytes32 internal constant CROWDSALE_TIME_UPDATED = keccak256("CrowdsaleTimeUpdated(bytes32)");

  function TOKEN_INIT(bytes32 _exec_id, bytes32 _name, bytes32 _symbol) private pure returns (bytes32[4] memory)
    { return [INIT_CROWDSALE_TOK_SIG, _exec_id, _name, _symbol]; }

  function MIN_UPDATE(bytes32 _exec_id) private pure returns (bytes32[2] memory)
    { return [GLOBAL_MIN_UPDATE, _exec_id]; }

  function TIME_UPDATE(bytes32 _exec_id) private pure returns (bytes32[2] memory)
    { return [CROWDSALE_TIME_UPDATED, _exec_id]; }

  // Checks input and then creates storage buffer to configure sale token
  function initCrowdsaleToken(bytes32 _name, bytes32 _symbol, uint _decimals) internal pure {
  	// Ensure valid input
    if (_name == 0 || _symbol == 0 || _decimals > 18)
      revert("Improper token initialization");

    // Begin storing values
    Contract.storing();
    // Store token name, symbol, and decimals
    Contract.set(Admin.tokenName()).to(_name);
    Contract.set(Admin.tokenSymbol()).to(_symbol);
    Contract.set(Admin.tokenDecimals()).to(_decimals);
    // Finish storing and being logging events
    Contract.emitting();
    // Log initCrowdsaleToken event
    Contract.log(
      TOKEN_INIT(Contract.execID(), _name, _symbol), bytes32(_decimals)
    );
  }

  // Checks input and then creates storage buffer to update minimum
  function updateGlobalMinContribution(uint _new_min) internal pure {
  	//Begin storing value
  	Contract.storing();
  	// Store new minimum
  	Contract.set(Admin.globalMinPurchaseAmt()).to(_new_min);
  	// Finish storing begin logging event
  	Contract.emitting();
  	// Log updateGlobalMinContribution event
  	Contract.log(
  	  MIN_UPDATE(Contract.execID()), bytes32(_new_min)
  	);
  }

  // Checks input and creates storage buffer to update sale whitelist
  function whitelistMulti(
    address[] _to_whitelist, uint[] _min_token_purchase, uint[] _max_token_purchase
  ) internal view {
    //Ensure valid input
    if (
      _to_whitelist.length != _min_token_purchase.length ||
      _to_whitelist.length != _max_token_purchase.length ||
      _to_whitelist.length == 0
    ) revert("Mismatched input lengths");

    // Get whitelist length
    uint sale_whitelist_len = uint(Contract.read(Admin.saleWhitelist()));

    // Begin storing values
    Contract.storing();
    // For loop to update all inputted address in whitelist
    for (uint i = 0; i < _to_whitelist.length; i++) {
      // Ensure maximum token purchase is at least equal to minimum token purchase -
      require(_max_token_purchase[i] >= _min_token_purchase[i], "Invalid whitelist entry");

      // Get storage location for address[i]
      Contract.set(Admin.whitelistMinTok(_to_whitelist[i])).to(_min_token_purchase[i]);
      Contract.set(Admin.whitelistMaxTok(_to_whitelist[i])).to(_max_token_purchase[i]);

      // If the whitelist address does not currently exist in storage, push them to the
      // sale&#39;s whitelist array
      if (
        Contract.read(Admin.whitelistMinTok(_to_whitelist[i])) == 0 &&
        Contract.read(Admin.whitelistMaxTok(_to_whitelist[i])) == 0
      ) {
        Contract.set(
          bytes32(32 + (32 * sale_whitelist_len) + uint(Admin.saleWhitelist()))
        ).to(_to_whitelist[i]);
        // Increment whitelist length
        sale_whitelist_len++;
      }
    }
    // Store new whitelist length
    Contract.set(Admin.saleWhitelist()).to(sale_whitelist_len);
  }

  // Checks input and creates storage buffer to set crowdsale start time and duration
  function setCrowdsaleStartandDuration(uint _start_time, uint _duration) internal view {
    //Ensure valid input
    if (_start_time <= now || _duration == 0)
      revert("Invalid start time or duration");

    // Begin storing values
    Contract.storing();
    // Store new start_time
    Contract.set(Admin.startTime()).to(_start_time);
    // Store new duration
    Contract.set(Admin.totalDuration()).to(_duration);

    Contract.emitting();
    // Log CrowdsaleTimeUpdated event
    Contract.log(TIME_UPDATE(Contract.execID()), bytes32(0));
  }
}

library ManageTokens {

  using Contract for *;
  using SafeMath for uint;

  // event TransferAgentStatusUpdate(bytes32 indexed exec_id, address indexed agent, bool current_status)
  bytes32 internal constant TRANSFER_AGENT_STATUS = keccak256(&#39;TransferAgentStatusUpdate(bytes32,address,bool)&#39;);

  // Returns the topics for a transfer agent status update event -
  function AGENT_STATUS(bytes32 _exec_id, address _agent) private pure returns (bytes32[3] memory)
    { return [TRANSFER_AGENT_STATUS, _exec_id, bytes32(_agent)]; }

  // Checks input and then creates storage buffer for transfer agent updating
  function setTransferAgentStatus(address _agent, bool _is_agent) internal pure {
    // Ensure valid input
    if (_agent == 0)
      revert(&#39;invalid transfer agent&#39;);

    Contract.storing();

    // Store new transfer agent status
    Contract.set(Admin.transferAgents(_agent)).to(_is_agent);
  	// Finish storing and begin logging events
  	Contract.emitting();
    // Add TransferAgentStatusUpdate signature and topics
    Contract.log(
      AGENT_STATUS(Contract.execID(), _agent), _is_agent ? bytes32(1) : bytes32(0)
    );
  }
}

library ManageSale {

  using Contract for *;
  using SafeMath for uint;

  // event CrowdsaleConfigured(bytes32 indexed exec_id, bytes32 indexed token_name, uint start_time);
  bytes32 internal constant CROWDSALE_CONFIGURED = keccak256("CrowdsaleConfigured(bytes32,bytes32,uint256)");

  // event CrowdsaleFinalized(bytes32 indexed exec_id);
  bytes32 internal constant CROWDSALE_FINALIZED = keccak256("CrowdsaleFinalized(bytes32)");

  // Returns the topics for a crowdsale configuration event
  function CONFIGURE(bytes32 _exec_id, bytes32 _name) private pure returns (bytes32[3] memory)
    { return [CROWDSALE_CONFIGURED, _exec_id, _name]; }

  // Returns the topics for a crowdsale finalization event
  function FINALIZE(bytes32 _exec_id) private pure returns (bytes32[2] memory)
    { return [CROWDSALE_FINALIZED, _exec_id]; }

  // Checks input and then creates storage buffer for sale initialization
  function initializeCrowdsale() internal view {
  	bytes32 token_name = Contract.read(Admin.tokenName());
    uint start_time = uint(Contract.read(Admin.startTime()));

  	// Check to make sure that the token name is not zero and that the start time has not passed
    if (start_time < now)
      revert(&#39;crowdsale already started&#39;);
    if (token_name == 0)
      revert(&#39;token not init&#39;);

  	// Begin storing values
  	Contract.storing();
    // Store updated crowdsale configuration status
    Contract.set(Admin.isConfigured()).to(true);

    // Set up EMITS action requests -
    Contract.emitting();
    // Add CROWDSALE_INITIALIZED signature and topics
    Contract.log(CONFIGURE(Contract.execID(), token_name), bytes32(start_time));
  }

  // Checks input and then creates storage buffer for sale finalization
  function finalizeCrowdsale() internal view {
    // Ensure sale has been configured -
    if (Contract.read(Admin.isConfigured()) == 0)
      revert(&#39;crowdsale has not been configured&#39;);

    // Get team wallet and unsold tokens remaining -
    address team_wallet = address(Contract.read(Admin.wallet()));
    uint num_remaining = uint(Contract.read(Admin.tokensRemaining()));

    Contract.storing();

    // Store updated crowdsale finalization status
    Contract.set(Admin.isFinished()).to(true);

    // If the unsold tokens are to be burnt, decrease the tokens remaining and total supply
    // Otherwise, send the unsold tokens to the team wallet
    if (Contract.read(Admin.burnExcess()) == 0)
      Contract.increase(Admin.balances(team_wallet)).by(num_remaining); // sent to team
    else
      Contract.decrease(Admin.tokenTotalSupply()).by(num_remaining); // burn unsold

    // Set tokens remaining to 0
    Contract.decrease(Admin.tokensRemaining()).by(num_remaining);

    // Set up EMITS action requests -
    Contract.emitting();

    // Add CROWDSALE_FINALIZED signature and topics
    Contract.log(FINALIZE(Contract.execID()), bytes32(0));
  }
}

library Admin {

  using Contract for *;

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

  // Whether the unsold tokens will be burnt on finalization, or be sent to the team wallet
  function burnExcess() internal pure returns (bytes32)
    { return keccak256("burn_excess_unsold"); }

  // Storage location of team funds wallet
  function wallet() internal pure returns (bytes32)
    { return keccak256("sale_destination_wallet"); }

  // Returns the storage location of number of tokens remaining in crowdsale
  function tokensRemaining() internal pure returns (bytes32)
    { return keccak256("sale_tokens_remaining"); }

  // Storage location of the crowdsale&#39;s start time
  function startTime() internal pure returns (bytes32)
    { return keccak256("sale_start_time"); }

  // Storage location of the amount of time the crowdsale will take, accounting for all tiers
  function totalDuration() internal pure returns (bytes32)
    { return keccak256("sale_total_duration"); }

  // Storage location of the minimum amount of tokens allowed to be purchased
  function globalMinPurchaseAmt() internal pure returns (bytes32)
    { return keccak256("sale_min_purchase_amt"); }

  /// WHITELIST ///

  // Stores the sale&#39;s whitelist
  function saleWhitelist() internal pure returns (bytes32)
    { return keccak256("sale_whitelist"); }

  // Stores a spender&#39;s maximum number of tokens allowed to be purchased
  function whitelistMaxTok(address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "max_tok", saleWhitelist()); }

  // Stores a spender&#39;s minimum token purchase amount
  function whitelistMinTok(address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "min_tok", saleWhitelist()); }

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

  // Storage seed for token &#39;transfer agent&#39; status for any address
  // Transfer agents can transfer tokens, even if the crowdsale has not yet been finalized
  bytes32 internal constant TOKEN_TRANSFER_AGENTS = keccak256("token_transfer_agents");

  function transferAgents(address _agent) internal pure returns (bytes32)
    { return keccak256(_agent, TOKEN_TRANSFER_AGENTS); }

  /// CHECKS ///

  // Ensure that the sender is the sale admin
  function onlyAdmin() internal view {
    if (address(Contract.read(admin())) != Contract.sender())
      revert(&#39;sender is not admin&#39;);
  }

  // Ensures that the sender is the admin address, and the sale is not initialized
  function onlyAdminAndNotInit() internal view {
    onlyAdmin();

    if (Contract.read(isConfigured()) != 0)
      revert(&#39;sale has already been initialized&#39;);
  }

  // Ensures that the sender is the admin address, and the sale is not finalized
  function onlyAdminAndNotFinal() internal view {
    onlyAdmin();

    if (Contract.read(isFinished()) != 0)
      revert(&#39;sale has already been finalized&#39;);
  }

  // Ensures the pending state change will only store
  function onlyStores() internal pure {
    if (Contract.paid() != 0 || Contract.emitted() != 0)
      revert(&#39;expected only storage&#39;);

    if (Contract.stored() == 0)
      revert(&#39;expected storage&#39;);
  }

  // Ensures both storage and events have been pushed to the buffer
  function emitAndStore() internal pure {
    if (Contract.emitted() == 0 || Contract.stored() == 0)
      revert(&#39;invalid state change&#39;);
  }

  /// FUNCTIONS ///

  /*
  Allows the admin to update the global minimum number of tokens to purchase

  @param _new_minimum: The new minimum number of tokens that must be purchased
  */
  function updateGlobalMinContribution(uint _new_minimum) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the admin and the sale is not initialized
    Contract.checks(onlyAdmin);
    // Execute function -
    ConfigureSale.updateGlobalMinContribution(_new_minimum);
    // Ensures state change will affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Allows the admin to whitelist addresses for the sale

  @param _to_whitelist: An array of addresses that will be whitelisted
  @param _min_token_purchase: Each address&#39; minimum purchase amount
  @param _max_token_purchase: Each address&#39; maximum token purchase amount
  */
  function whitelistMulti(
    address[] _to_whitelist, uint[] _min_token_purchase, uint[] _max_token_purchase
  ) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin -
    Contract.checks(onlyAdmin);
    // Execute function -
    ConfigureSale.whitelistMulti(_to_whitelist, _min_token_purchase, _max_token_purchase);
    // Ensures state change will only affect storage -
    Contract.checks(onlyStores);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Initializes the token to be sold during the crowdsale -

  @param _name: The name of the token to be sold
  @param _symbol: The symbol of the token to be sold
  @param _decimals: The number of decimals the token will have
  */
  function initCrowdsaleToken(bytes32 _name, bytes32 _symbol, uint _decimals) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and the sale is not initialized -
    Contract.checks(onlyAdminAndNotInit);
    // Execute decreaseApproval function -
    ConfigureSale.initCrowdsaleToken(_name, _symbol, _decimals);
    // Ensures state change will affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Allows the sale admin to set the sale start time and duration (if it has not started yet)
  The admin must not have finalized the configuration process (i.e. called initializeCrowdsale)

  @param _start_time: The time at which the sale will start
  @param _duration: The amount of time for which the sale will be active
  */
  function setCrowdsaleStartandDuration(uint _start_time, uint _duration) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and the sale is not initialized -
    Contract.checks(onlyAdminAndNotInit);
    // Execute decreaseApproval function -
    ConfigureSale.setCrowdsaleStartandDuration(_start_time, _duration);
    // Ensures state change will affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  /*
  Sets the status of an account as a transfer agent. Transfer agents are allowed to transfer tokens at any time

  @param _agent: The address whose status will be updated
  @param _is_agent: Whether or not the agent is a transfer agent
  */
  function setTransferAgentStatus(address _agent, bool _is_agent) external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin -
    Contract.checks(onlyAdmin);
    // Execute decreaseApproval function -
    ManageTokens.setTransferAgentStatus(_agent, _is_agent);
    // Ensures state change will affect storage and log events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  // Allows the admin to initialize a crowdsale, marking it configured
  function initializeCrowdsale() external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and the sale is not initialized -
    Contract.checks(onlyAdminAndNotInit);
    // Execute function -
    ManageSale.initializeCrowdsale();
    // Ensures state change will affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }

  // Allows the admin to finalize a crowdsale, marking it completed
  function finalizeCrowdsale() external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sender is the sale admin and that the sale is not finalized -
    Contract.checks(onlyAdminAndNotFinal);
    // Execute function -
    ManageSale.finalizeCrowdsale();
    // Ensures state change will affect storage and events -
    Contract.checks(emitAndStore);
    // Commit state changes to storage -
    Contract.commit();
  }
}