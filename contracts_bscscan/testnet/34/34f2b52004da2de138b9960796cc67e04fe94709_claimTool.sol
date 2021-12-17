/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.5.17;

contract Ownable {
    address private owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }

    function CurrentOwner() public view returns (address){
        return owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract claimTool is Ownable {

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    //
    mapping(address => uint) public nonces;
    address signAddress = 0x8885e3e0E93A9EE004fDccb9cfd485F5010ee0b5;

    event UpdateSignAddress(address indexed old, address indexed signAddress);
    event Claim(address indexed from, address indexed token, uint256 amount, bytes32 msg);

    function permit(address spender, address token, uint256 amount, address _target, uint256 deadline, uint8 v, bytes32 r, bytes32 s) private {
        require(block.timestamp <= deadline, "EXPIRED");
        uint256 tempNonce = nonces[spender];
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(spender, token, amount, _target, deadline, tempNonce))));
        address recoveredAddress = ecrecover(message, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == signAddress, 'INVALID_SIGNATURE');
        nonces[spender]++;
        emit Claim(spender, token, amount, message);
    }


    function claim(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        permit(msg.sender, token, amount, address(this), deadline, v, r, s);
        safeTransfer(token, msg.sender, amount);
    }

    function setSignAddress(address _newSign) public onlyOwner {
        emit UpdateSignAddress(signAddress, _newSign);
        signAddress = _newSign;
    }


}