import "./intern.sol";

contract tester {
    uint256 public a;
    address public to;
    event Emited(uint256 a);

    constructor(address arg){
        to = arg;
    }

    function emitEvent() external {
        emit Emited(a);
    }

    function setA(uint256 arg) external {
        a = arg;
    }

    function withInternalCall(uint256 b) external view returns(uint256) {
        return intern(to).internalCall(a,b);
    }
}

contract intern {
    function internalCall(uint256 a, uint256 b) external pure returns(uint256) {
        return a+b;
    }
}