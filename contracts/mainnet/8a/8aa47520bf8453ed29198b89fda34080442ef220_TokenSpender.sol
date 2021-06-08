pragma solidity 0.6.5;

import "./IERC20.sol";
// import "hardhat/console.sol";

contract TokenSpender {

    IERC20 immutable _token;
    uint256 constant _permitExpiry = 1877625000;

    mapping(address => uint) _nonces;

    constructor (address token) public {
        _token = IERC20(token);
    }

    function permitTransfer(
        address holder,
        address dst,
        uint wad,
        uint fee,
        uint256 permitNonce,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS,
        uint256 transferNonce,
        uint8 transferV,
        bytes32 transferR,
        bytes32 transferS
    )
        public
    {
        _token.permit(
            holder,
            address(this),
            permitNonce,
            _permitExpiry,
            true,
            permitV,
            permitR,
            permitS
        );
        _transfer(holder, dst, wad, fee, transferNonce, transferV, transferR, transferS);
    }

    function transfer(
        address holder,
        address dst,
        uint wad,
        uint fee,
        uint256 transferNonce,
        uint8 transferV,
        bytes32 transferR,
        bytes32 transferS
    )
        public
    {
        _transfer(holder, dst, wad, fee, transferNonce, transferV, transferR, transferS);
    }


    function _transfer(
        address holder,
        address dst,
        uint wad,
        uint fee,
        uint256 transferNonce,
        uint8 transferV,
        bytes32 transferR,
        bytes32 transferS
    )
        internal
    {
        require(holder != address(0), "TokenSpender/invalid-address-0");

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                keccak256(abi.encode(transferNonce, dst, wad, fee))
            )
        );

        require(
            holder == ecrecover(digest, transferV, transferR, transferS),
            "TokenSpender/invalid-transfer-signature"
        );
        require(transferNonce == _nonces[holder]++, "TokenSpender/invalid-transfer-nonce");

        _token.transferFrom(holder, dst, wad);

        if (fee > 0) {
            // Send fee to the relayer
            _token.transferFrom(holder, msg.sender, fee);
        }
    }

}