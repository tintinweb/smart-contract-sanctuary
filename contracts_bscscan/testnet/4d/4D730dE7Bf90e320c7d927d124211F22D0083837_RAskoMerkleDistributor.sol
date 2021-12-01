// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RAskoMerkleDistributor {
    using Counters for Counters.Counter;
    Counters.Counter private _airdropIds;

    struct Airdrop {
        address owner;
        bytes32 merkleRoot;
        bool cancelable;
        uint256 tokenAmount;
        mapping(address => bool) collected;
    }

    IERC20 tokenContract;

    event StartAirdrop(uint256 airdropId);
    event AirdropTransfer(uint256 id, address addr, uint256 num);

    mapping(uint256 => Airdrop) public airdrops;

    constructor(IERC20 _tokenContract) {
        tokenContract = _tokenContract;
    }

    function startAirdrop(
        bytes32 _merkleRoot,
        bool _cancelable,
        uint256 _tokenAmount
    ) external {
        _airdropIds.increment();
        Airdrop storage newAirdrop = airdrops[_airdropIds.current()];
        newAirdrop.owner = msg.sender;
        newAirdrop.merkleRoot = _merkleRoot;
        newAirdrop.cancelable = _cancelable;
        newAirdrop.tokenAmount = _tokenAmount;

        tokenContract.transferFrom(msg.sender, address(this), _tokenAmount);
        emit StartAirdrop(_airdropIds.current());
    }

    function setRoot(uint256 _id, bytes32 _merkleRoot) external {
        require(
            msg.sender == airdrops[_id].owner,
            "Only owner of an airdrop can set root"
        );
        airdrops[_id].merkleRoot = _merkleRoot;
    }

    function checkCollected(uint256 _id, address _who)
        external
        view
        returns (bool)
    {
        return airdrops[_id].collected[_who];
    }

    function nextAirdropId() external view returns (uint256) {
        return _airdropIds.current() + 1;
    }

    function contractTokenBalance() external view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    function contractTokenBalanceById(uint256 _id)
        external
        view
        returns (uint256)
    {
        return airdrops[_id].tokenAmount;
    }

    function endAirdrop(uint256 _id) external returns (bool) {
        require(airdrops[_id].cancelable, "this presale is not cancelable");
        // only owner
        require(
            msg.sender == airdrops[_id].owner,
            "Only owner of an airdrop can end the airdrop"
        );
        require(airdrops[_id].tokenAmount > 0, "Airdrop has no balance left");
        uint256 transferAmount = airdrops[_id].tokenAmount;
        airdrops[_id].tokenAmount = 0;
        require(
            tokenContract.transferFrom(
                address(this),
                airdrops[_id].owner,
                transferAmount
            ),
            "Unable to transfer remaining balance"
        );
        return true;
    }

    function getTokens(
        uint256 _id,
        bytes32[] memory _proof,
        address _who,
        uint256 _amount
    ) external returns (bool success) {
        Airdrop storage airdrop = airdrops[_id];

        require(
            airdrop.collected[_who] != true,
            "User has already collected from this airdrop"
        );
        require(_amount > 0, "User must collect an amount greater than 0");
        require(
            airdrop.tokenAmount >= _amount,
            "The airdrop does not have enough balance for this withdrawal"
        );
        require(
            msg.sender == _who,
            "Only the recipient can receive for themselves"
        );

        if (
            !checkProof(_id, _proof, leafFromAddressAndNumTokens(_who, _amount))
        ) {
            require(false, "Invalid proof");
        }

        airdrop.tokenAmount = airdrop.tokenAmount - _amount;
        airdrop.collected[_who] = true;

        if (tokenContract.transfer(_who, _amount) == true) {
            emit AirdropTransfer(_id, _who, _amount);
            return true;
        }
        // throw if transfer fails, no need to spend gas
        require(false);
    }

    function getTokensFromMultiple(
        uint256[] memory _ids,
        bytes32[][] memory _proofs,
        address _who,
        uint256[] memory _amounts
    ) external returns (bool success) {
        uint256 totalAmount = 0;
        require(
            msg.sender == _who,
            "Only the recipient can receive for themselves"
        );
        for (uint256 i = 0; i < _ids.length; i++) {
            Airdrop storage airdrop = airdrops[_ids[i]];
            require(
                airdrop.collected[_who] != true,
                "User has already collected from this airdrop"
            );
            require(
                _amounts[i] > 0,
                "User must collect an amount greater than 0"
            );
            require(
                airdrop.tokenAmount >= _amounts[i],
                "The airdrop does not have enough balance for this withdrawal"
            );
            if (
                !checkProof(
                    _ids[0],
                    _proofs[0],
                    leafFromAddressAndNumTokens(_who, _amounts[0])
                )
            ) {
                require(false, "Invalid proof");
            }

            airdrop.tokenAmount = airdrop.tokenAmount - _amounts[i];
            airdrop.collected[_who] = true;
            totalAmount += _amounts[i];
            emit AirdropTransfer(_ids[i], _who, _amounts[i]);

        }
        if (tokenContract.transfer(_who, totalAmount) == true) {
            return true;
        }

        require(false, "Unable to transfer balance");
    }

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        uint256 x_int = uint256(uint160(address(x)));

        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(x_int / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uintToStr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            bstr[(k--) - 1] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }

    function leafFromAddressAndNumTokens(address _account, uint256 _amount)
        internal
        pure
        returns (bytes32)
    {
        string memory prefix = "0x";
        string memory space = " ";

        bytes memory leaf = abi.encodePacked(
            prefix,
            addressToAsciiString(_account),
            space,
            uintToStr(_amount)
        );

        return bytes32(sha256(leaf));
    }

    function checkProof(
        uint256 _id,
        bytes32[] memory _proof,
        bytes32 hash
    ) internal view returns (bool) {
        bytes32 el;
        bytes32 h = hash;

        for (
            uint256 i = 0;
            _proof.length != 0 && i <= _proof.length - 1;
            i += 1
        ) {
            el = _proof[i];

            if (h < el) {
                h = sha256(abi.encodePacked(h, el));
            } else {
                h = sha256(abi.encodePacked(el, h));
            }
        }

        return h == airdrops[_id].merkleRoot;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}