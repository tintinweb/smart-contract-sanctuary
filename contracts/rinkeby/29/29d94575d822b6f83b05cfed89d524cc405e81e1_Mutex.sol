/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

contract Mutex {
    uint public test = 7;
    
    bool public locked;
    event CheckerFirst(bool check);
    event CheckerSecond(bool check);
    event CheckerThird(bool check);
    event CheckerFourth(bool check);
    event CheckerFifth(bool check);
    event CheckerSixth(bool check);
    event CheckerSeventh(bool check);
    
    modifier noReentrancy() {
        require(
            !locked,
            "Reentrant call."
        );
        emit CheckerFirst(locked);
        locked = true;
        emit CheckerSecond(locked);

        _;
        emit CheckerThird(locked);
        locked = false;
        emit CheckerFourth(locked);
    }

    /// This function is protected by a mutex, which means that
    /// reentrant calls from within `msg.sender.call` cannot call `f` again.
    /// The `return 7` statement assigns 7 to the return value but still
    /// executes the statement `locked = false` in the modifier.
    function f() public noReentrancy returns (uint) {
        emit CheckerFifth(locked);
        (bool success,) = msg.sender.call("");
        require(success);
        emit CheckerSixth(locked);
        return verify();
    }
    
    function verify() public returns (uint) {
        emit CheckerSeventh(locked);
        return test;
    }
}