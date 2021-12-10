pragma solidity 0.5.8;

import "./Token_v1.sol";
import "./Wiper.sol";

contract Token_v2 is Token_v1, Wiper {

    event Wipe(address indexed addr, uint256 amount);
    event WiperChanged(address indexed oldWiper, address indexed newWiper, address indexed sender);

    // only admin can change wiper
    function changeWiper(address _account) public onlyAdmin whenNotPaused isNotZeroAddress(_account) {
        address old = wiper;
        wiper = _account;
        emit WiperChanged(old, wiper, msg.sender);
    }

    // wipe balance of prohibited address
    function wipe(address _account) public whenNotPaused onlyWiper onlyProhibited(_account) {
        uint256 _balance = balanceOf(_account);
        _burn(_account, _balance);
        emit Wipe(_account, _balance);
    }
}