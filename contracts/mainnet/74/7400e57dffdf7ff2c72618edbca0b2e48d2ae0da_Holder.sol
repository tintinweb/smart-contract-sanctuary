/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts/token/ERC1155/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File contracts/Interface.sol

pragma solidity ^0.8.0;

/* is ERC165 */
interface ERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface ERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

// File contracts/StakeContract.sol

pragma solidity 0.8.0;

contract Holder is ERC1155Holder {
    ERC1155 nft_contract;
    ERC20 metagold_contract;

    address public owner;

    uint256 tokenYields = 10;
    uint256 yieldTime = 1 days;
    uint256 stakingTime = 365 * 5 days;
    uint256 stakingStart;

    mapping(uint256 => address) public stakers;
    mapping(uint256 => uint256) public staking_time;

    modifier tokenIdWhiteList(uint256[] memory tokenIds) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 _tokenId = tokenIds[i];
            require(
                _tokenId <=
                    13816368292405329361516153857659306852598365020171615076828770453862700023809 &&
                    _tokenId >=
                    13816368292405329361516153857659306852598365020171615076828769351052537364481,
                "Invalid token Id"
            );
        }
        _;
    }

    modifier isStakingAlive() {
        require(
            stakingTime + stakingStart > block.timestamp,
            "Staking time ended"
        );
        _;
    }

    modifier isStakingEnded() {
        require(
            stakingTime + stakingStart <= block.timestamp,
            "Staking time not ended"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        address _metagold_contract,
        address _nft_contractAddress,
        address _owner
    ) {
        metagold_contract = ERC20(_metagold_contract);
        nft_contract = ERC1155(_nft_contractAddress);
        stakingStart = block.timestamp;

        owner = _owner;
    }

    function stake(uint256[] memory tokenIds, uint256[] memory tokenValues)
        external
        isStakingAlive
        tokenIdWhiteList(tokenIds)
        returns (bool)
    {
        require(
            nft_contract.isApprovedForAll(msg.sender, address(this)),
            "Opeartaor was not approved"
        );

        // user must own the nfts
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nft_contract.balanceOf(msg.sender, tokenIds[i]) == 1,
                "User must own the NFT"
            );
        }

        nft_contract.safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokenIds,
            tokenValues,
            ""
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            stakers[tokenIds[i]] = msg.sender;
            staking_time[tokenIds[i]] = block.timestamp;
        }

        return true;
    }

    function unstake(uint256[] memory tokenIds, uint256[] memory tokenValues)
        external
        returns (bool)
    {
        // unstake logic
        uint256 _tokenYield;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakers[tokenIds[i]] == msg.sender,
                "User didn't stake the contract"
            );
            _tokenYield += CalculateYield(tokenIds[i]);
            stakers[tokenIds[i]] = address(0);
            staking_time[tokenIds[i]] = 0;
        }

        nft_contract.safeBatchTransferFrom(
            address(this),
            msg.sender,
            tokenIds,
            tokenValues,
            ""
        );

        // user gets rewards
        require(metagold_contract.transfer(msg.sender, _tokenYield), "failed");

        return true;
    }

    function claimRewrad(uint256[] memory tokenIds) external returns (bool) {
        // unstake logic
        uint256 _tokenYield;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakers[tokenIds[i]] == msg.sender,
                "User didn't stake the contract"
            );
            _tokenYield += CalculateYield(tokenIds[i]);
            staking_time[tokenIds[i]] = block.timestamp;
        }

        metagold_contract.transfer(msg.sender, _tokenYield);

        return true;
    }

    function CalculateYield(uint256 tokenId) public view returns (uint256) {
        require(
            stakers[tokenId] == msg.sender,
            "User haven't staked the token"
        );
        uint256 timeStaked;
        if (block.timestamp <= stakingTime + stakingStart) {
            // staking time is valid
            timeStaked = block.timestamp - staking_time[tokenId];
        } else {
            // staking time ended
            timeStaked = stakingTime + stakingStart - staking_time[tokenId];
        }
        uint256 yield = (timeStaked / yieldTime) * tokenYields;
        return yield * 1 ether;
    }

    function SafeNFTWithdraw(
        uint256[] memory tokenIds,
        uint256[] memory tokenValues
    ) external returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                stakers[tokenIds[i]] == msg.sender,
                "User didn't stake the contract"
            );
            stakers[tokenIds[i]] = address(0);
            staking_time[tokenIds[i]] = 0;
        }

        nft_contract.safeBatchTransferFrom(
            address(this),
            msg.sender,
            tokenIds,
            tokenValues,
            ""
        );

        return true;
    }

    function postStakeWithdraw() external onlyOwner isStakingEnded {
        uint256 remaning = metagold_contract.balanceOf(address(this));
        require(metagold_contract.transfer(msg.sender, remaning));
    }

    function changeAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0));
        owner = _newAdmin;
    }
}