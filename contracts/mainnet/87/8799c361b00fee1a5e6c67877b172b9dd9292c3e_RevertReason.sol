pragma solidity 0.4.25;

contract RevertReason {
    
    ErrorReporter public error;
    
    constructor(address _error) public {
        require(_error != address(0x0));
        error = ErrorReporter(_error);
    }
    
    function shouldRevert(bool yes) public {
        if (yes) {
            error.report("Shit it reverted!");
        }
    }
    
    function shouldRevertWithReturn(bool yes) public returns (uint256) {
        if (yes) {
            error.report("Shit it reverted!");
        }
        return 42;
    }
    
    function shouldRevertPure(bool yes) public view returns (uint256) {
        if (yes) {
            error.report("Shit it reverted!");
        }
        return 42;
    }
}


contract ErrorReporter {
    function report(string reason) public pure {
        revert(reason);
    }
}