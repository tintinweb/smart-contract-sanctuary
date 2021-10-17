pragma solidity ^0.8.0;

import "./New_ERC1155Mintable.sol";
import "./IMedia.sol";
import "./IMarket.sol";
import "./ERC721MinterCreator.sol";

contract Media is IMedia {
    address private _ERC1155Address;
    address private _marketAddress;
    address private _ERC721Address;

    uint256 private _tokenCounter;

    // TokenHash => tokenID
    mapping(bytes32 => uint256) private _tokenHashToTokenID;

    // tokenID => Owner
    mapping(uint256 => address) nftToOwners;

    // tokenID => Creator
    mapping(uint256 => address) nftToCreators;

    // tokenID => Token
    mapping(uint256 => Token) tokenIDToToken;

    modifier whenTokenExist(uint256 _tokenID) {
        require(
            tokenIDToToken[_tokenID]._creator != address(0),
            "Media: The Token Doesn't Exist!"
        );
        _;
    }

    constructor(
        address _ERC1155,
        address _ERC721,
        address _market
    ) {
        require(_ERC1155 != address(0), "Media: Invalid Address!");
        require(_ERC721 != address(0), "Media: Invalid Address!");
        require(_market != address(0), "Media: Invalid Address!");

        _ERC1155Address = _ERC1155;
        _ERC721Address = _ERC721;
        _marketAddress = _market;
    }

    event TokenCounter(uint256);

    function mintToken(
        bool _isFungible,
        string calldata uri,
        string calldata title,
        uint256 totalSupply,
        uint8 royaltyPoints,
        address[] memory collaborators,
        uint8[] calldata percentages
    ) external payable override returns (uint256) {
        require(msg.value != 0, "Media: No Commission Amount Provided!");

        // Calculate hash of the Token
        bytes32 tokenHash = keccak256(
            abi.encodePacked(uri, title, totalSupply)
        );

        // Check if Token with same data exists
        require(
            _tokenHashToTokenID[tokenHash] == 0,
            "Media: Token With Same Data Already Exist!"
        );

        _tokenCounter++;

        // Store the hash
        _tokenHashToTokenID[tokenHash] = _tokenCounter;

        if (_isFungible) {
            ERC1155Mintable(_ERC1155Address).mint(
                _tokenCounter,
                msg.sender,
                totalSupply
            );
        } else {
            ERC721Create(_ERC721Address).mint(_tokenCounter, msg.sender);

            nftToOwners[_tokenCounter] = msg.sender;
        }

        nftToCreators[_tokenCounter] = msg.sender;

        Token memory newToken = Token(
            _tokenCounter,
            msg.sender,
            msg.sender,
            uri,
            title,
            _isFungible
        );

        if (_isFungible) {
            newToken._currentOwner = address(0);
        }

        IMarket.Collaborators memory newTokenColab = IMarket.Collaborators(
            collaborators,
            percentages
        );

        IMarket(_marketAddress).setCollaborators(_tokenCounter, newTokenColab);
        IMarket(_marketAddress).setRoyaltyPoints(_tokenCounter, royaltyPoints);

        tokenIDToToken[_tokenCounter] = newToken;

        // Transfer the admin commission
        payable(_marketAddress).transfer(msg.value);
        // Set Admin Points
        IMarket(_marketAddress).addAdminCommission(msg.value);

        emit MintToken(
            _isFungible,
            uri,
            title,
            totalSupply,
            royaltyPoints,
            collaborators,
            percentages
        );

        emit TokenCounter(_tokenCounter);

        return _tokenCounter;
    }

    /**
     * @notice This method is used to Get Token of _tokenID
     *
     * @param _tokenID TokenID of the Token to get
     *
     * @return Token The Token
     */
    function getToken(uint256 _tokenID)
        public
        view
        override
        whenTokenExist(_tokenID)
        returns (Token memory)
    {
        return tokenIDToToken[_tokenID];
    }

    function getTotalNumberOfNFT() external view returns (uint256) {
        return _tokenCounter;
    }

    function bid(
        uint256 _tokenID,
        uint256 _amount,
        address _owner
    ) external payable override whenTokenExist(_tokenID) returns (bool) {
        require(msg.value != 0, "Media: You Can't Bid With 0 Amount!");
        require(
            tokenIDToToken[_tokenID]._currentOwner != msg.sender,
            "Media: The Token Owner Can't Bid!"
        );
        require(
            msg.sender != _owner,
            "Media: You Cannot Bid For Your Own Token!"
        );

        Token memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Mintable(_ERC1155Address).balanceOf(_owner, _tokenID) >=
                    _amount,
                "Media: The Owner Does Not Have That Much Tokens!"
            );
        } else {
            require(_amount == 1, "Media: Only 1 Token Is Available");
            require(
                nftToOwners[_tokenID] == _owner,
                "Media: Invalid Owner Provided!"
            );
        }

        payable(_marketAddress).transfer(msg.value);
        // amount, tokenOwner
        IMarket(_marketAddress).bid(
            _tokenID,
            msg.sender,
            msg.value,
            _amount,
            _owner
        );

        return true;
    }

    function cancelBid(uint256 _tokenID, address _owner)
        external
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        IMarket(_marketAddress).cancelBid(_tokenID, msg.sender, _owner);
        return true;
    }

    function rejectBid(uint256 _tokenID, address _bidder)
        external
        override
        whenTokenExist(_tokenID)
        returns (bool)
    {
        Token memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Mintable(_ERC1155Address).balanceOf(
                    msg.sender,
                    _tokenID
                ) >= 0,
                "Media: Only Owner Can Reject Bid!"
            );
        } else {
            require(
                nftToOwners[_tokenID] == msg.sender,
                "Media: Only Owner Can Reject Bid!"
            );
        }
        // require(msg.sender == nftToOwners[_tokenID], "Media: Only Owner Can Reject Bid!");
        IMarket(_marketAddress).cancelBid(_tokenID, _bidder, msg.sender);
        return true;
    }

    function acceptBid(
        uint256 _tokenID,
        address _bidder,
        uint256 _amount
    ) external override whenTokenExist(_tokenID) returns (bool) {
        Token memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Mintable(_ERC1155Address).balanceOf(
                    msg.sender,
                    _tokenID
                ) >= _amount,
                "Media: You Don't have The Tokens!"
            );
        } else {
            require(
                nftToOwners[_tokenID] == msg.sender,
                "Media: Only Owner Can Accept Bid!"
            );
        }
        IMarket(_marketAddress).acceptBid(
            _tokenID,
            msg.sender,
            _bidder,
            _amount
        );

        _transfer(_tokenID, msg.sender, _bidder, _amount);

        nftToOwners[_tokenID] = _bidder;
        return true;
    }

    function setAdminAddress(address _adminAddress) external returns (bool) {
        IMarket(_marketAddress).setAdminAddress(_adminAddress);
        return true;
    }

    function getAdminCommissionPercentage() external view returns (uint256) {
        return IMarket(_marketAddress).getCommissionPercentage();
    }

    function setCommissionPecentage(uint8 _newCommissionPercentage)
        external
        returns (bool)
    {
        require(
            msg.sender == IMarket(_marketAddress).getAdminAddress(),
            "Media: Only Admin Can Set Commission Percentage!"
        );
        require(
            _newCommissionPercentage > 0,
            "Media: Invalid Commission Percentage"
        );
        require(
            _newCommissionPercentage <= 100,
            "Media: Commission Percentage Must Be Less Than 100!"
        );

        IMarket(_marketAddress).setCommissionPecentage(
            _newCommissionPercentage
        );
        return true;
    }

    function buyNow(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    ) external payable override whenTokenExist(_tokenID) returns (bool) {
        require(msg.value != 0, "Media: You Can't Buy Token With 0 Amount!");
        require(_owner != _recipient, "Media: You Can't Buy Your Token!");
        require(
            tokenIDToToken[_tokenID]._currentOwner != _recipient,
            "Media: The Token Owner Can't Buy!"
        );

        Token memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Mintable(_ERC1155Address).balanceOf(_owner, _tokenID) >=
                    _amount,
                "Media: The Owner Does Not Have That Much Tokens!"
            );
        } else {
            require(_amount == 1, "Media: Only 1 Token Is Available");
            require(
                nftToOwners[_tokenID] == _owner,
                "Media: Invalid Owner Provided!"
            );
        }

        payable(_marketAddress).transfer(msg.value);

        _transfer(_tokenID, _owner, _recipient, _amount);

        IMarket(_marketAddress).divideMoney(_tokenID, _owner, msg.value);

        return true;
    }

    /**
     * @dev See {IMedia}
     */
    function transfer(
        uint256 _tokenID,
        address _recipient,
        uint256 _amount
    ) external override whenTokenExist(_tokenID) returns (bool) {
        Token memory token = tokenIDToToken[_tokenID];
        if (token._isFungible) {
            require(
                ERC1155Mintable(_ERC1155Address).balanceOf(
                    msg.sender,
                    _tokenID
                ) >= _amount,
                "Media: You Don't have The Tokens!"
            );
        } else {
            require(
                nftToOwners[_tokenID] == msg.sender,
                "Media: Only Owner Can Transfer!"
            );
        }

        _transfer(_tokenID, msg.sender, _recipient, _amount);
        return true;
    }

    function _transfer(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    ) internal {
        if (tokenIDToToken[_tokenID]._isFungible) {
            ERC1155Mintable(_ERC1155Address).transferFrom(
                _owner,
                _recipient,
                _tokenID,
                _amount,
                msg.sender
            );
        } else {
            ERC721Create(_ERC721Address).TransferFrom(
                _owner,
                _recipient,
                _tokenID,
                msg.sender
            );
            tokenIDToToken[_tokenID]._currentOwner = _recipient;
            nftToOwners[_tokenID] = _recipient;
        }

        emit Transfer(_tokenID, _owner, _recipient, _amount);
    }

    /**
     * @notice This method is used to redeem points
     *
     * @param _amount Amount of points to redeem
     *
     * @return bool Transaction status
     */
    function redeemPoints(uint256 _amount) external override returns (bool) {
        require(_amount > 0, "Media: Cannot Redeem 0 Amount");
        IMarket(_marketAddress).redeemPoints(msg.sender, _amount);
        return true;
    }

    /**
     * @dev See {IMedia}
     */
    function getUsersRedeemablePoints()
        external
        view
        override
        returns (uint256)
    {
        return IMarket(_marketAddress).getUsersRedeemablePoints(msg.sender);
    }
}

pragma solidity ^0.8.0;

import "./ERC1155.sol";

contract ERC1155Mintable is ERC1155 {
    address private _mediaContract;

    modifier onlyMediaCaller {
        require(
            msg.sender == _mediaContract,
            "ERC1155Mintable: Unauthorized Access!"
        );
        _;
    }

    function configureMedia(address _mediaContractAddress) external {
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Mintable: Invalid Media Contract Address!"
        );
        require(
            _mediaContract == address(0),
            "ERC1155Mintable: Media Contract Alredy Configured!"
        );

        _mediaContract = _mediaContractAddress;
    }

    function mint(
        uint256 _tokenID,
        address _owner,
        uint256 totalSupply
    ) external onlyMediaCaller {
        balances[_tokenID][_owner] = totalSupply;
    }

    /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer from
     * @param _to Address of the Token receiver
     * @param _tokenID TokenID of the Token to transfer
     * @param _amount Amount of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount,
        address _msgSender
    ) external onlyMediaCaller returns (bool) {
        require(_to != address(0x0), "ERC1155Mintable: _to must be non-zero.");

        // require(
        //     _from == _msgSender || operatorApproval[_from][_msgSender] == true,
        //     "ERC1155Mintable: Need operator approval for 3rd party transfers."
        // );

        safeTransferFrom(_from, _to, _tokenID, _amount, "");

        return true;
    }
}

pragma solidity ^0.8.0;

interface IMedia {
    struct Token {
        uint256 _tokenID;
        address _creator;
        address _currentOwner;
        string _uri;
        string _title;
        bool _isFungible;
    }

    event MintToken(
        bool _isFungible,
        string uri,
        string title,
        uint256 totalSupply,
        uint8 royaltyPoints,
        address[] collaborators,
        uint8[] percentages
    );

    event Transfer(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    );

    /**
     * @notice This method is used to Mint a new Token
     *
     * @return uint256 Token Id of the Minted Token
     */
    function mintToken(
        bool _isFungible,
        string calldata uri,
        string calldata title,
        uint256 totalSupply,
        uint8 royaltyPoints,
        address[] calldata collaborators,
        uint8[] calldata percentages
    ) external payable returns (uint256);

    /**
     * @notice This method is used to get details of the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to get details of
     *
     * @return Token Structure of the Token
     */
    function getToken(uint256 _tokenID) external view returns (Token memory);

    /**
     * @notice This method is used to bid for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to Bid for
     *
     * @return bool Transaction status
     */
    function bid(
        uint256 _tokenID,
        uint256 _amount,
        address _owner
    ) external payable returns (bool);

    /**
     * @notice This method is used to cancel bid for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to cancel Bid for
     *
     * @return bool Transaction status
     */
    function cancelBid(uint256 _tokenID, address _owner)
        external
        returns (bool);

    /**
     * @notice This method is used to Reject bid for the Token with ID _tokenID and Bid of bidder with address _bidder
     *
     * @param _tokenID TokenID of the Token to Reject Bid for
     * @param _bidder Address of the Bidder to Reject Bid of
     *
     * @return bool Transaction status
     */
    function rejectBid(uint256 _tokenID, address _bidder)
        external
        returns (bool);

    /**
     * @notice This method is used to Accept the bid for the Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to Accept Bid For
     * @param _bidder Address of the Bidder
     * @param _amount Number of tokens to be transferred to the Bidder - in case of ERC1155 Token
     *
     * @return bool Transaction status
     */
    function acceptBid(
        uint256 _tokenID,
        address _bidder,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice This method is used to Buy Token with ID _tokenID
     *
     * @param _tokenID TokenID of the Token to Buy
     * @param _owner Address of the Owner of the Token
     * @param _recipient Address of the recipient
     * @param _amount Number of tokens to be transferred to the recipient - in case of ERC1155 Token
     *
     * @return bool Transaction status
     */
    function buyNow(
        uint256 _tokenID,
        address _owner,
        address _recipient,
        uint256 _amount
    ) external payable returns (bool);

    /**
     * @notice This method is used to Transfer Token
     *
     * @dev This method is used when Owner Wants to directly transfer Token
     *
     * @param _tokenID Token ID of the Token To Transfer
     * @param _recipient Receiver of the Token
     * @param _amount Number of Tokens To Transfer, In Case of ERC1155 Token
     *
     * @return bool Transaction status
     */
    function transfer(
        uint256 _tokenID,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice This method is used to Redeem points
     *
     * @param _amount Amount Points to Redeem
     *
     * @return bool Transaction status
     */
    function redeemPoints(uint256 _amount) external returns (bool);

    /**
     * @notice This Method is used to get Redeemable Points of the caller
     *
     * @return uint Redeemable Points
     */
    function getUsersRedeemablePoints() external view returns (uint256);
}

pragma solidity ^0.8.0;

interface IMarket {
    struct Collaborators {
        address[] _collaborators;
        uint8[] _percentages;
    }

    event Bid(uint256 tokenID, address bidder, uint256 bidAmount);
    event CancelBid(uint256 tokenID, address bidder);
    event AcceptBid(
        uint256 tokenID,
        address owner,
        uint256 amount,
        address bidder,
        uint256 bidAmount
    );
    event Redeem(address userAddress, uint256 points);

    /**
     * @notice This method is used to set Collaborators to the Token
     * @param _tokenID TokenID of the Token to Set Collaborators
     * @param _collaborators Struct of Collaborators to set
     */
    function setCollaborators(
        uint256 _tokenID,
        Collaborators calldata _collaborators
    ) external;

    /**
     * @notice tHis method is used to set Royalty Points for the token
     * @param _tokenID Token ID of the token to set
     * @param _royaltyPoints Points to set
     */
    function setRoyaltyPoints(uint256 _tokenID, uint8 _royaltyPoints) external;

    /**
     * @notice this function is used to place a Bid on token
     *
     * @param _tokenID Token ID of the Token to place Bid on
     * @param _bidder Address of the Bidder
     * @param _bidAmount Amount of the Bid
     *
     * @return bool Stransaction Status
     */
    function bid(
        uint256 _tokenID,
        address _bidder,
        uint256 _bidAmount,
        uint256 _amount,
        address _tokenOwner
    ) external returns (bool);

    /**
     * @notice this function is used to Accept Bid
     *
     * @param _tokenID TokenID of the Token
     * @param _owner Address of the Owner of the Token
     * @param _bidder Address of the Bidder
     * @param _amount Bid Amount
     *
     * @return bool Transaction status
     */
    function acceptBid(
        uint256 _tokenID,
        address _owner,
        address _bidder,
        uint256 _amount
    ) external returns (bool);

    /**
     * @notice This function is used to Cancel Bid
     * @dev This methos is also used to Reject Bid
     *
     * @param _tokenID Token ID of the Token to cancel bid for
     * @param _bidder Address of the Bidder to cancel bid of
     *
     * @return bool Transaction status
     */
    function cancelBid(
        uint256 _tokenID,
        address _bidder,
        address _owner
    ) external returns (bool);

    /**
     * @notice This method is used to Divide the selling amount among Owner, Creator and Collaborators
     *
     * @param _tokenID Token ID of the Token sold
     * @param _owner Address of the Owner of the Token
     * @param _amountToDivide Amount to divide -  Selling amount of the Token
     *
     * @return bool Transaction status
     */
    function divideMoney(
        uint256 _tokenID,
        address _owner,
        uint256 _amountToDivide
    ) external returns (bool);

    /**
     * @notice This Method is used to set Commission percentage of The Admin
     *
     * @param _commissionPercentage New Commission Percentage To set
     *
     * @return bool Transaction status
     */
    function setCommissionPecentage(uint8 _commissionPercentage)
        external
        returns (bool);

    /**
     * @notice This Method is used to set Admin's Address
     *
     * @param _newAdminAddress Admin's Address To set
     *
     * @return bool Transaction status
     */
    function setAdminAddress(address _newAdminAddress) external returns (bool);

    /**
     * @notice This method is used to get Admin's Commission Percentage
     *
     * @return uint8 Commission Percentage
     */
    function getCommissionPercentage() external view returns (uint8);

    /**
     * @notice This method is used to get Admin's Address
     *
     * @return address Admin's Address
     */
    function getAdminAddress() external view returns (address);

    /**
     * @notice This method is used to give admin Commission while Minting new token
     *
     * @param _amount Commission Amount
     *
     * @return bool Transaction status
     */
    function addAdminCommission(uint256 _amount) external returns (bool);

    /**
     * @notice This method is used to Redeem Points
     *
     * @param _userAddress Address of the User to Redeem Points of
     * @param _amount Amount of points to redeem
     *
     * @return bool Transaction status
     */
    function redeemPoints(address _userAddress, uint256 _amount)
        external
        returns (bool);

    /**
     * @notice This method is used to get User's Redeemable Points
     *
     * @param _userAddress Address of the User to get Points of
     *
     * @return uint Redeemable Points
     */
    function getUsersRedeemablePoints(address _userAddress)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract ERC721Create is ERC721 {
    address private _mediaContract;

    modifier onlyMediaCaller {
        require(
            msg.sender == _mediaContract,
            "ERC721Create: Unauthorized Access!"
        );
        _;
    }

    function configureMedia(address _mediaContractAddress) external {
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Mintable: Invalid Media Contract Address!"
        );
        require(
            _mediaContract == address(0),
            "ERC1155Mintable: Media Contract Alredy Configured!"
        );

        _mediaContract = _mediaContractAddress;
    }

    // tokenId => Owner
    mapping(uint256 => address) nftToOwners;

    // tokenID => Creator
    mapping(uint256 => address) nftToCreators;

    uint256 private tokenCounter;

    constructor() ERC721("", "") {}

    /* 
    @notice This function is used fot minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the '_tokenID' and 
     the respective NFT details.
    */
    function mint(uint256 _tokenID, address _creator)
        external
        onlyMediaCaller
        returns (bool)
    {
        nftToOwners[_tokenID] = _creator;
        nftToCreators[_tokenID] = _creator;

        _safeMint(_creator, _tokenID);

        return true;
    }

    /*
    @notice This function will transfer the Token 
     from the caller's address to the recipient address
    @dev Called the ERC721'_transfer' function to transfer 
     tokens from 'msg.sender'
    */
    function transfer(address _recipient, uint256 _tokenID)
        public
        onlyMediaCaller
        returns (bool)
    {
        require(_tokenID > 0, "ERC721Create: Token Id should be non-zero");
        transferFrom(msg.sender, _recipient, _tokenID); // ERC721 transferFrom function called
        nftToOwners[_tokenID] = _recipient;
        return true;
    }

    /*
    @notice This function will transfer from the sender account
     to the recipient account but the caller have the allowence 
     to send the Token.
    @dev check the allowence limit for msg.sender before sending
     the token
    */
    function TransferFrom(
        address _sender,
        address _recipient,
        uint256 _tokenID,
        address _msgSender
    ) public onlyMediaCaller returns (bool) {
        require(_tokenID > 0, "ERC721Create: Token Id should be non-zero");
        // require(
        //     _isApprovedOrOwner(_msgSender, _tokenID),
        //     "ERC721Create: transfer caller is neither owner nor approved"
        // );

        safeTransferFrom(_sender, _recipient, _tokenID); // ERC721 safeTransferFrom function called

        nftToOwners[_tokenID] = _recipient;
        return true;
    }
}

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Common.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, CommonConstants {
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping(address => mapping(address => bool)) internal operatorApproval;

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override
        returns (bool)
    {
        if (
            _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }

        return false;
    }

    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

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
        bytes memory _data
    ) public override {
        // require(_to != address(0x0), "_to must be non-zero.");
        // require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to] = _value.add(balances[_id][_to]);

        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _id,
                _value,
                _data
            );
        }
    }

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
    ) external override {
        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(
            _ids.length == _values.length,
            "_ids and _values array length must match."
        );
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids,
                _values,
                _data
            );
        }
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorApproval[_owner][_operator];
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(
            ERC1155TokenReceiver(_to).onERC1155Received(
                _operator,
                _from,
                _id,
                _value,
                _data
            ) == ERC1155_ACCEPTED,
            "contract returned an unknown value from onERC1155Received"
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(
            ERC1155TokenReceiver(_to).onERC1155BatchReceived(
                _operator,
                _from,
                _ids,
                _values,
                _data
            ) == ERC1155_BATCH_ACCEPTED,
            "contract returned an unknown value from onERC1155BatchReceived"
        );
    }
}

pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity ^0.8.0;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

pragma solidity ^0.8.0;

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
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
        The `_operator` argument MUST be msg.sender.
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
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
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
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
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
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

pragma solidity ^0.8.0;

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override
        returns (bool)
    {
        if (
            _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }

        return false;
    }

    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return interfaceId == type(IERC721).interfaceId
    //         || interfaceId == type(IERC721Metadata).interfaceId;
    // }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is ERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC721.sol';

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}