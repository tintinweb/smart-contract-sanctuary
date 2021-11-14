pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

//用户数据结构
struct UsersInfo {
    uint32 endpoint;
    uint32 num;
    uint64 blocktime;
    uint128 tickets;
}

library SquidWarsLib {
    function getFee(uint256 amount,uint _bonusFee,uint _tipFee)
        public
        pure
        returns (
            uint256 fee_,
            uint256 tip_,
            uint256 amount_
        )
    {
        fee_ = (amount * _bonusFee) / 1000;
        tip_ = (amount * _tipFee) / 1000;
        amount_ -= fee_ + tip_;
    }

    function getWithdrawFee(uint256 amount,uint finishtime)
        public
        view
        returns (uint256 fee_, uint256 amount_)
    {
        uint256 r = (block.timestamp + finishtime) / 86400;
        if (r > 25) {
            r = 25;
        }
        amount_ = (amount * (r + 75)) / 100;
        fee_ = amount - amount_;
    }

    function hashUsersInfo(
        address tokenId,UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenId,
                    info.endpoint,
                    info.num,
                    info.blocktime,
                    info.tickets,
                    address(this)
                )
            );
    }

    function hashToSign(address tokenId, uint32 endpoint_, uint32 num, uint64 blocktime, uint128 tickets ) public view returns (bytes32) {
        UsersInfo memory info = UsersInfo(endpoint_, num, blocktime, tickets);
        return hashUsersInfo(tokenId,info);
    }

    function hashToVerify(address tokenId,
        UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashUsersInfo(tokenId,info)
                )
            );
    }

    function verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        return signer == ecrecover(hash, v, r, s);
    }
}