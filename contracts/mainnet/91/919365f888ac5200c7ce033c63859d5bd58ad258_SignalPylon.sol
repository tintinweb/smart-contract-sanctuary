pragma solidity ^0.4.15;

contract Token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

/***************************************************************************\
 *   SignalPylon: Signal capturing contract
 *
 *   Allows token signaling without sub-token generation or transferal
 *   The final signal scoring is determined outside the contract and
 *   outside the blockchain (by the admin/user interested in the data)
 *   and can be parsed/post-processed however is contextually appropriate.
\***************************************************************************/

contract SignalPylon {
    /*************\
     *  Storage  *
    \*************/
    address public token;                       // The address of the signal token
    mapping (uint => Signal) public signals;    // Signals captured from users/voters
    uint public signalCount;                    // Total count of signals (index)

    /*************\
     *  Structs  *
     *****************************************************************\
     *  Signal (vote)
     *  @dev Represents a particular vote or signal captured/cast
     *       at a specific blockheight. Note: signaling uses the
     *       entire available token balance of the caller&#39;s account.
    \*****************************************************************/
    struct Signal {
        address signaler;
        bytes32 register;
        uint value;
    }

    /************\
     *  Events  *
    \************/
    event SignalOutput(address signaler, bytes32 register, uint value);

    /*********************\
     *  Public functions
     *********************\
     *  @dev Constructor
    \*********************/
    function SignalPylon(address _token) public {
        token = _token;
    }

    /***********************************************\
     *  @dev User-callable signaling function
     *  @param _register Register which is signaled
    \***********************************************/
    function sendSignal(bytes32 _register) public {
        uint signalValue = Token(token).balanceOf(msg.sender);
        require(signalValue > 0);

        // Append to signal list
        signals[signalCount] = Signal({
            signaler: msg.sender,
            register: _register,
            value: signalValue
        });

        // Update signal count index
        signalCount += 1;

        // Emit SignalOutput event
        emit SignalOutput(msg.sender, _register, signalValue);
    }
}