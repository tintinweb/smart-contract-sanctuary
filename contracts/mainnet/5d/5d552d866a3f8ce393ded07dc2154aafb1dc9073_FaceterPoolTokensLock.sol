pragma solidity 0.4.19;

contract ERC20Interface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract FaceterPoolTokensLock {
    address constant RECEIVER = 0x4365e5d6e48bb0a4db93555363aad7989caa9b05;
    ERC20Interface constant FaceterToken = ERC20Interface(0x1ccaa0f2a7210d76e1fdec740d5f323e2e1b1672);
    uint8 public unlockStep;

    function unlock() public returns(bool) {
        uint unlockAmount = 0;
        // Jan 1, 2019
        if (unlockStep == 0 && now >= 1546300800) {
            unlockAmount = FaceterToken.balanceOf(this);
        }
        if (unlockAmount == 0) {
            return false;
        }
        unlockStep++;
        require(FaceterToken.transfer(RECEIVER, unlockAmount));
        return true;
    }

    function () public {
        unlock();
    }

    function recoverTokens(ERC20Interface _token) public returns(bool) {
        // Don&#39;t allow recovering Faceter Token till the end of lock.
        if (_token == FaceterToken && now < 1546300800 && unlockStep != 1) {
            return false;
        }
        return _token.transfer(RECEIVER, _token.balanceOf(this));
    }
}