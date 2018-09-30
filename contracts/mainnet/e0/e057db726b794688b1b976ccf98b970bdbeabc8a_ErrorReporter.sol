pragma solidity 0.4.25;

contract RevertReason {
    
    ErrorReporter error;
    
    constructor(address _error) public {
        error = ErrorReporter(_error);
    }
    
    function shouldRevert(bool yes) public {
        if (yes) {
            error.report("Shit it reverted!");
        }
    }
    
    function shouldRevertWithReturn(bool yes) public returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
    
    function shouldRevertPure(bool yes) public pure returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
}


contract ErrorReporter {
    function report(string reason) public pure {
        revert(reason);
    }
}