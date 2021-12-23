// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "./libs.sol";


/// @title MultiToken
/// @notice ERC1155 token contract with the support of secondary fees.
contract MultiCollection is Ownable, SignerRole, ERC1155Base {
    using BytesLibrary for bytes32;
    using SafeMath for uint256;
    using StringLibrary for string;
    /// @notice Tokens name;
    string public name;
    /// @notice Tokens symbol.
    string public symbol;

    /// @notice The contract constructor.
    /// @param _name - The value for the `name`.
    /// @param _symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    /// @param signer - The address of the initial signer.
    constructor(string memory _name, string memory _symbol, string memory contractURI, string memory tokenURIPrefix, address signer) ERC1155Base(contractURI, tokenURIPrefix) {
        name = _name;
        symbol = _symbol;

        _addSigner(signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    /// @notice This function can be called by the contract owner and it adds an address as a new signer.
    ///         The signer will authorize token minting by signing token ids.
    /// @param account - The address of a new signer.
    function addSigner(address account) public override onlyOwner {
        _addSigner(account);
    }

    /// @notice This function can be called by the contract owner and it removes an address from signers pool.
    /// @param account - The address of a signer to remove.
    function removeSigner(address account) public onlyOwner {
        _removeSigner(account);
    }

    /// @notice The function for token minting. It creates a new token.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param id - The id of a new token (`tokenId`).
    /// @param v - v parameter of the ECDSA signature.
    /// @param r - r parameter of the ECDSA signature.
    /// @param s - s parameter of the ECDSA signature.
    /// @param fees - An array of the secondary fees for this token.
    /// @param supply - The supply amount for the token.
    /// @param uri - The URI suffix for the token. The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 id, uint8 v, bytes32 r, bytes32 s, Fee[] memory fees, uint256 supply, string memory uri) public {
        require(isSigner(prepareMessage(id, this).recover(v, r, s)), "signer should sign tokenId");
        _mint(id, fees, supply, uri);
    }
    
    function prepareMessage(uint256 _id, MultiCollection _contAddr) private pure returns (string memory) {
        return keccak256(abi.encode(_id, address(_contAddr))).toString();
    }
}

/**
 * @title MultiUserToken
 * @dev Only owner can mint tokens.
 */
contract MultiUserCollection is MultiCollection {
    uint public maxTokenId;
    /// @notice Token minting event.
    event CreateERC1155_v1(address indexed creator, string name, string symbol);

    /// @notice The contract constructor.
    /// @param name - The value for the `name`.
    /// @param symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    constructor(string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix) MultiCollection(name, symbol, contractURI, tokenURIPrefix, address(this)) {
        emit CreateERC1155_v1(msg.sender, name, symbol);
    }

    /// @notice The function for token minting. It creates a new token. Can be called only by the contract owner.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param id - The id of a new token (`tokenId`).
    /// @param fees - An array of the secondary fees for this token.
    /// @param supply - The supply amount for the token.
    /// @param uri - The URI suffix for the token. The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 id, Fee[] memory fees, uint256 supply, string memory uri) onlyOwner public {
        _mint(id, fees, supply, uri);
        if (id > maxTokenId)
            maxTokenId = id;
    }
}

contract InoMultiCollection is MultiCollection{
    using BytesLibrary for bytes32;
    using SafeMath for uint256;
    using Address for address;
    
    constructor(string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix) 
    MultiCollection(name, symbol, contractURI, tokenURIPrefix, address(this) ) {}
    
    
    struct Contribution{
        address owner;
        uint copies;
    }

    // @notice [Only for Contract Owner and Ino Wrapper Contract]
    // The function performs minting of token Id in the `amount = accounts.length`. 
    // After the minting 1 token will be sent to each of the `accounts`.  
    // The creator of this token will be `creator`, not `msg.sender`.  
    // @param _id - The id of a new token (`tokenId`)
    // @param creator - address of the token creator
    // @param accounts - addresses of the token Co-owners
    // @param creatorRoyalty - fee for the token creator
    // @param uri - the same as in the usual mint()
    function mintIno(
        uint256 _id,
        address payable creator, 
        Contribution[] memory contributions, 
        uint256 royalty,
        string memory uri) public
        {
        require(isSigner(msg.sender), "Unavailable address of the sender");
        Fee[] memory _fees = new Fee[](contributions.length + 1);
        uint _feeForEachAccount = royalty.div(_fees.length);
        uint supply = 0;
        
        for(uint _contrId = 0; _contrId < _fees.length - 1; _contrId++){
            supply = supply.add(contributions[_contrId].copies);
            _fees[_contrId] = Fee(payable(contributions[_contrId].owner), _feeForEachAccount);
        }
        _fees[_fees.length-1] = Fee(creator, _feeForEachAccount);

        _mintINO(_id, _fees, supply, uri);
        
        safeTransferFromINO(creator, contributions, _id, bytes(""));
    }


    function _mintINO(uint256 id, Fee[] memory fees, uint256 supply, string memory uri) private {
        _mintFromCreator(id, fees, supply, uri);
    }
    
    function prepareMessage(uint256 _id, InoMultiCollection _contAddr) private pure returns (string memory) {
        return keccak256(abi.encode(_id, address(_contAddr))).toString();
    }

    /// @notice Creates a new token type and assings _initialSupply to minter
    function _mintFromCreator(uint256 _id, Fee[] memory _fees, uint256 _supply, string memory _uri) private {
        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");

        address creator = _fees[_fees.length-1].recipient;
        creators[_id] = creator;

        address[] memory recipients = new address[](_fees.length);
        uint[] memory bps = new uint[](_fees.length);
        for (uint i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "Fee recipient should be present");
            fees[_id].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }

        balances[_id][creator] = _supply;
        _setTokenURI(_id, _uri);

        // Transfer event with mint semantic
        emit TransferSingle(creator, address(0x0), creator, _id, _supply);
        emit URI(_uri, _id);
    }

    
    // @notice The method for transfering token to array of recipients
    // @param _from - The address of token creator
    // @param _recipients - The array of recipient addresses
    // @param _id - The Id of the token
    // @param _value - The count of token to transfer. Value will be the same for each of the `recipients`
    // @param _data - Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFromINO(address _from, Contribution[] memory contributions, uint256 _id, bytes memory _data) public {
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true 
            || isSigner(msg.sender), 
            "Need operator approval for 3rd party transfers.");
        
        for(uint i; i < contributions.length; i++) {
            address _to = contributions[i].owner;
            uint _value = contributions[i].copies;
            require(_to != address(0x0), "_to must be non-zero.");
            
            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = balances[_id][_to].add(_value);
    
            // MUST emit event
            emit TransferSingle(msg.sender, _from, _to, _id, _value);
    
            // Now that the balance is updated and the event was emitted,
            // call onERC1155Received if the destination is a contract.
            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
            }
        }
    }
}