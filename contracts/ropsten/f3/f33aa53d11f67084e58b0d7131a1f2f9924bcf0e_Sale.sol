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

library Purchase {

  using Contract for *;
  using SafeMath for uint;

  // event Purchase(bytes32 indexed exec_id, uint256 indexed current_rate, uint256 indexed current_time, uint256 tokens)
  bytes32 internal constant BUY_SIG = keccak256(&#39;Purchase(bytes32,uint256,uint256,uint256)&#39;);

  // Returns the event topics for a &#39;Purchase&#39; event -
  function PURCHASE(bytes32 _exec_id, uint _current_rate) private view returns (bytes32[4] memory)
    { return [BUY_SIG, _exec_id, bytes32(_current_rate), bytes32(now)]; }

  // Implements the logic to create the storage buffer for a Crowdsale Purchase
  function buy() internal view {
    bool sale_is_whitelisted = Contract.read(Sale.isWhitelisted()) != 0 ? true : false;
    bool sender_has_contributed = Contract.read(Sale.hasContributed(Contract.sender())) != 0 ? true : false;

    // Calculate current sale rate from start time, start and end rates, and duration
  	uint current_rate = getCurrentRate(
  	  uint(Contract.read(Sale.startTime())),
  	  uint(Contract.read(Sale.startRate())),
  	  uint(Contract.read(Sale.endRate())),
  	  uint(Contract.read(Sale.totalDuration()))
  	);

  	// If sender has already purchased tokens then change minimum contribution amount to 0;
  	uint min_contribution;
    // If the sale is whitelisted -
    if (sale_is_whitelisted && !sender_has_contributed)
      min_contribution = uint(Contract.read(Sale.whitelistMinTok(Contract.sender())));
    else if (!sale_is_whitelisted && !sender_has_contributed)
      min_contribution = uint(Contract.read(Sale.globalMinPurchaseAmt()));

  	// Get total amount of wei that can be spent and number of tokens purchased
  	uint spend_amount;
  	uint tokens_purchased;
  	(spend_amount, tokens_purchased) = getPurchaseInfo(
  	  uint(Contract.read(Sale.tokenDecimals())),
  	  current_rate,
  	  uint(Contract.read(Sale.tokensRemaining())),
  	  sale_is_whitelisted,
  	  uint(Contract.read(Sale.whitelistMaxTok(Contract.sender()))),
  	  min_contribution
  	);
    // Sanity checks -
    assert(spend_amount != 0 && spend_amount <= msg.value && tokens_purchased != 0);

    // Set up payment buffer -
    Contract.paying();
    // Forward spent wei to team wallet -
    Contract.pay(spend_amount).toAcc(address(Contract.read(Sale.wallet())));

    // Move buffer to storing values -
    Contract.storing();

  	// Update purchaser&#39;s token balance -
  	Contract.increase(Sale.balances(Contract.sender())).by(tokens_purchased);

  	// Update tokens remaining in sale -
  	Contract.decrease(Sale.tokensRemaining()).by(tokens_purchased);

    // Update total tokens sold -
    Contract.increase(Sale.tokensSold()).by(tokens_purchased);

  	// Update total wei raised -
  	Contract.increase(Sale.totalWeiRaised()).by(spend_amount);

    // If the sender had not previously contributed to the sale,
    // increase unique contributor count and mark the sender as having contributed
  	if (sender_has_contributed == false) {
  	  Contract.increase(Sale.contributors()).by(1);
  	  Contract.set(Sale.hasContributed(Contract.sender())).to(true);
  	}

    // If the sale is whitelisted, update the spender&#39;s whitelist information -
	  if (sale_is_whitelisted) {
	    Contract.set(Sale.whitelistMinTok(Contract.sender())).to(uint(0));
      Contract.decrease(Sale.whitelistMaxTok(Contract.sender())).by(tokens_purchased);
	  }

  	Contract.emitting();

  	// Add purchase signature and topics
  	Contract.log(
  	  PURCHASE(Contract.execID(), current_rate), bytes32(tokens_purchased)
  	);
  }

  // Calculate current purchase rate
  function getCurrentRate(uint _start_time,	uint _start_rate,	uint _end_rate,	uint _duration) internal view
  returns (uint current_rate) {
  	// If the sale has not yet started, set current rate to 0
  	if (now < _start_time) {
  	  current_rate = 0;
  	  return;
  	}

  	uint elapsed = now.sub(_start_time);
  	// If the sale duration is up, set current rate to 0
  	if (elapsed >= _duration) {
  	  current_rate = 0;
  	  return;
  	}

  	// Add precision to the time elapsed -
  	elapsed = elapsed.mul(10 ** 18);

  	// Temporary variable
  	uint temp_rate = _start_rate.sub(_end_rate).mul(elapsed).div(_duration);

    // Remove precision
  	temp_rate = temp_rate.div(10 ** 18);

  	// Current rate is start rate minus temp rate
  	current_rate = _start_rate.sub(temp_rate);
  }

  // Calculates amount to spend, amount left able to be spent, and number of tokens purchased
  function getPurchaseInfo(
  	uint _decimals, uint _current_rate, uint _tokens_remaining,
  	bool _sale_whitelisted,	uint _token_spend_remaining, uint _min_purchase_amount
  ) internal view returns (uint spend_amount, uint tokens_purchased) {
  	// Get amount of wei able to be spent, given the number of tokens remaining -
    if (msg.value.mul(10 ** _decimals).div(_current_rate) > _tokens_remaining)
      spend_amount = _current_rate.mul(_tokens_remaining).div(10 ** _decimals);
    else
      spend_amount = msg.value;

    // Get number of tokens able to be purchased with the amount spent -
    tokens_purchased = spend_amount.mul(10 ** _decimals).div(_current_rate);

    // If the sale is whitelisted, adjust purchase size so that it does not go over the user&#39;s max cap -
    if (_sale_whitelisted && tokens_purchased > _token_spend_remaining) {
      tokens_purchased = _token_spend_remaining;
      spend_amount = tokens_purchased.mul(_current_rate).div(10 ** _decimals);
    }

    // Ensure spend amount is valid -
    if (spend_amount == 0 || spend_amount > msg.value)
      revert("Invalid spend amount");

    // Ensure amount of tokens to purchase is not greater than the amount of tokens remaining in the sale -
    if (tokens_purchased > _tokens_remaining || tokens_purchased == 0)
      revert("Invalid purchase amount");

    // Ensure the number of tokens purchased meets the sender&#39;s minimum contribution requirement
    if (tokens_purchased < _min_purchase_amount)
      revert("Purchase is under minimum contribution amount");
  }
}

library Sale {

  using Contract for *;

  /// SALE ///

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

  // Returns the storage location of number of tokens remaining in crowdsale
  function tokensRemaining() internal pure returns (bytes32)
    { return keccak256("sale_tokens_remaining"); }

  // Returns the storage location of crowdsale&#39;s starting sale rate
  function startRate() internal pure returns (bytes32)
    { return keccak256("sale_start_rate"); }

  // Returns the storage location of crowdsale&#39;s ending sale rate
  function endRate() internal pure returns (bytes32)
    { return keccak256("sale_end_rate"); }

  // Storage location of the amount of tokens sold in the crowdsale so far
  function tokensSold() internal pure returns (bytes32)
    { return keccak256("sale_tokens_sold"); }

  // Storage location of the minimum amount of tokens allowed to be purchased
  function globalMinPurchaseAmt() internal pure returns (bytes32)
    { return keccak256("sale_min_purchase_amt"); }

  // Stores the amount of unique contributors so far in this crowdsale
  function contributors() internal pure returns (bytes32)
    { return keccak256("sale_contributors"); }

  // Maps addresses to a boolean indicating whether or not this address has contributed
  function hasContributed(address _purchaser) internal pure returns (bytes32)
    { return keccak256(_purchaser, contributors()); }

  /// FUNDS ///

  // Storage location of team funds wallet
  function wallet() internal pure returns (bytes32)
    { return keccak256("sale_destination_wallet"); }

  // Storage location of amount of wei raised during the crowdsale, total
  function totalWeiRaised() internal pure returns (bytes32)
    { return keccak256("sale_tot_wei_raised"); }

  /// WHITELIST ///

  // Whether or not the sale is whitelist-enabled
  function isWhitelisted() internal pure returns (bytes32)
    { return keccak256(&#39;sale_is_whitelisted&#39;); }

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

  // Storage location for token decimals
  function tokenDecimals() internal pure returns (bytes32)
    { return keccak256("token_decimals"); }

  // Storage seed for user balances mapping
  bytes32 internal constant TOKEN_BALANCES = keccak256("token_balances");

  function balances(address _owner) internal pure returns (bytes32)
    { return keccak256(_owner, TOKEN_BALANCES); }

  /// CHECKS ///

  // Ensures the sale has been configured, and that the sale has not finished
  function validState() internal view {
    // Ensure ETH was sent with the transaction
    if (msg.value == 0)
      revert(&#39;no wei sent&#39;);

    // Ensure the sale has started
    if (uint(Contract.read(startTime())) > now)
      revert(&#39;sale has not started&#39;);

    // Ensure the team wallet is correct
    if (Contract.read(wallet()) == 0)
  	  revert(&#39;invalid Crowdsale wallet&#39;);

    // Ensure the sale was configured
    if (Contract.read(isConfigured()) == 0)
      revert(&#39;sale not initialized&#39;);

    // Ensure the sale is not finished
    if (Contract.read(isFinished()) != 0)
      revert(&#39;sale already finalized&#39;);

    // Ensure the sale is not sold out
  	if (Contract.read(tokensRemaining()) == 0)
  	  revert(&#39;Crowdsale is sold out&#39;);

  	// Ensure the start and end rate were correctly set
  	if (Contract.read(startRate()) <= Contract.read(endRate()))
  	  revert("end sale rate is greater than starting sale rate");

  	// Ensure the sale is not over
  	if (now > uint(Contract.read(startTime())) + uint(Contract.read(totalDuration())))
  	  revert("the crowdsale is over");
  }

  // Ensures both storage and events have been pushed to the buffer
  function emitStoreAndPay() internal pure {
    if (Contract.emitted() == 0 || Contract.stored() == 0 || Contract.paid() != 1)
      revert(&#39;invalid state change&#39;);
  }

  /// FUNCTIONS ///

  // Allows the sender to purchase tokens -
  function buy() external view {
    // Begin execution - reads execution id and original sender address from storage
    Contract.authorize(msg.sender);
    // Check that the sale is initialized and not yet finalized -
    Contract.checks(validState);
    // Execute approval function -
    Purchase.buy();
    // Check for valid storage buffer
    Contract.checks(emitStoreAndPay);
    // Commit state changes to storage -
    Contract.commit();
  }
}