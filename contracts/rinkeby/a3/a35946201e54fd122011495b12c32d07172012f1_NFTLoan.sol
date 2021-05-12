/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity >=0.6.0 <0.8.0;

contract NFTLoan{
    // Events
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    //
    string internal nftName;

    // Attaches the NFT id to a particular address
    mapping(uint256 => address) internal ownerId;

    // Creates a counter for how many NFTokens an account has
    //
    // NOTE ----- Might not need this - We can create another NFT inside
    // another mapping. This should happen on minting.
    mapping(address => uint256) private ownerToNFTokenCount;

    
    mapping(address => string) private ownerNonce;
    // Attaches the NFT id to a string for the name
    //
    // NOTE --- No need to attach it to a string ID
    mapping(uint256 => string) internal idToUri;

    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0));
        require(ownerId[_tokenId] == address(0));

        _addNFToken(_to, _tokenId);

        // Changed address of event to this
        emit Transfer(address(this), _to, _tokenId);
    }
    
    function _mintNonce(address _to, uint256 _nonceId) internal virtual {
        require(_to != address(0));
        require(ownerId[_nonceId] == address(0));
        
        emit Transfer(address(this), _to, _nonceId);
    }

    function _addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(ownerId[_tokenId] == address(0));

        // Next step would be encrypt the information
        // Create a struct inside the mapping or a different mapping
        // where we could store the data
        ownerId[_tokenId] = _to;
        ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to] + 1;
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
        require(ownerId[_tokenId] == _from);
        ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
        delete ownerId[_tokenId];
    }

    // Testing
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function _getOwnerNFTCount(address _owner)
        internal
        view
        virtual
        returns (uint256)
    {
        return ownerToNFTokenCount[_owner];
    }

    // Testing
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = ownerId[_tokenId];
        require(_owner != address(0));
    }

    // Might have to get rid off -- We are accessing the NFT using just wallet address
    function _setTokenUri(uint256 _tokenId, string memory _uri)
        internal
        validNFToken(_tokenId)
    {
        idToUri[_tokenId] = _uri;
        nftName = _uri;
    }

    // Looks good -- Only needs to be accessed by the Oracle after validation goes through
    modifier validNFToken(uint256 _tokenId) {
        require(ownerId[_tokenId] != address(0));
        _;
    }

    //testing
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = ownerId[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = ownerId[_tokenId];
        require(tokenOwner == msg.sender);
        _;
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = ownerId[_tokenId];
        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    // Mint is can be the entry point where we check if the Oracle
    // gave this wallet a greenlight and is ready to create the NFT
    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri
    ) public {
        _mint(_to, _tokenId);
        //_mintNonce(_to, _nonceId);
        _setTokenUri(_tokenId, _uri);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        _safeTransferFrom(_from, _to, _tokenId);
    }
 
 
    // ------------------------ Future development ----------------------------
    // Encrypted data
    // Minting two NFTs -- Encrypted data and key do decrypt it
    // If user defaults on loan - Both NFTs is automatically transfered to Oracle
    //
    // Thoughts
    // Loans will have a signature generated on loan application - This signature could
    // be used to link the NFT to the user - It could perhaps be generated on the NFT first
    // and then given to treasure as the key to generate the loan with.
    //
    // Making a payment on loan will connect to the NFT and update the latest loan Status
    // NFT will handle striking system, colleting strikes on missed payments.
}