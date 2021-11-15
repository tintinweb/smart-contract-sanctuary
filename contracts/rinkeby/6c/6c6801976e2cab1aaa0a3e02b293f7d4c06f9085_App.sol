pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

/// @title ERC-721 Non-Fungible Token Standard
       /// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
       ///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
       interface ERC721 /* is ERC165 */ {
           /// @dev This emits when ownership of any NFT changes by any mechanism.
           ///  This event emits when NFTs are created (`from` == 0) and destroyed
           ///  (`to` == 0). Exception: during contract creation, any number of NFTs
           ///  may be created and assigned without emitting Transfer. At the time of
           ///  any transfer, the approved address for that NFT (if any) is reset to none.
           event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

           /// @dev This emits when the approved address for an NFT is changed or
           ///  reaffirmed. The zero address indicates there is no approved address.
           ///  When a Transfer event emits, this also indicates that the approved
           ///  address for that NFT (if any) is reset to none.
           event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

           /// @dev This emits when an operator is enabled or disabled for an owner.
           ///  The operator can manage all NFTs of the owner.
           event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

           /// @notice Count all NFTs assigned to an owner
           /// @dev NFTs assigned to the zero address are considered invalid, and this
           ///  function throws for queries about the zero address.
           /// @param _owner An address for whom to query the balance
           /// @return The number of NFTs owned by `_owner`, possibly zero
           function balanceOf(address _owner) external view returns (uint256);

           /// @notice Find the owner of an NFT
           /// @dev NFTs assigned to zero address are considered invalid, and queries
           ///  about them do throw.
           /// @param _tokenId The identifier for an NFT
           /// @return The address of the owner of the NFT
           function ownerOf(uint256 _tokenId) external view returns (address);

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
           ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
           ///  `onERC721Received` on `_to` and throws if the return value is not
           ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           /// @param data Additional data with no specified format, sent in call to `_to`
           function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev This works identically to the other function with an extra data parameter,
           ///  except this function just sets data to ""
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
           ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
           ///  THEY MAY BE PERMANENTLY LOST
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Set or reaffirm the approved address for an NFT
           /// @dev The zero address indicates there is no approved address.
           /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
           ///  operator of the current owner.
           /// @param _approved The new approved NFT controller
           /// @param _tokenId The NFT to approve
           function approve(address _approved, uint256 _tokenId) external payable;

           /// @notice Enable or disable approval for a third party ("operator") to manage
           ///  all of `msg.sender`'s assets.
           /// @dev Emits the ApprovalForAll event. The contract MUST allow
           ///  multiple operators per owner.
           /// @param _operator Address to add to the set of authorized operators.
           /// @param _approved True if the operator is approved, false to revoke approval
           function setApprovalForAll(address _operator, bool _approved) external;

           /// @notice Get the approved address for a single NFT
           /// @dev Throws if `_tokenId` is not a valid NFT
           /// @param _tokenId The NFT to find the approved address for
           /// @return The approved address for this NFT, or the zero address if there is none
           function getApproved(uint256 _tokenId) external view returns (address);

           /// @notice Query if an address is an authorized operator for another address
           /// @param _owner The address that owns the NFTs
           /// @param _operator The address that acts on behalf of the owner
           /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
           function isApprovedForAll(address _owner, address _operator) external view returns (bool);
       }

       interface ERC165 {
           /// @notice Query if a contract implements an interface
           /// @param interfaceID The interface identifier, as specified in ERC-165
           /// @dev Interface identification is specified in ERC-165. This function
           ///  uses less than 30,000 gas.
           /// @return `true` if the contract implements `interfaceID` and
           ///  `interfaceID` is not 0xffffffff, `false` otherwise
           function supportsInterface(bytes4 interfaceID) external view returns (bool);
       }

       interface ERC721TokenReceiver {
           /// @notice Handle the receipt of an NFT
           /// @dev The ERC721 smart contract calls this function on the
           /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
           /// of other than the magic value MUST result in the transaction being reverted.
           /// @notice The contract address is always the message sender.
           /// @param _operator The address which called `safeTransferFrom` function
           /// @param _from The address which previously owned the token
           /// @param _tokenId The NFT identifier which is being transferred
           /// @param _data Additional data with no specified format
           /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
           /// unless throwing
           function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
        }
contract Sales_contract {
    uint256 timestamp;
    address sender;
    address Token;
    uint256 tokenId;
    uint256 Price;
    uint256 Expiration;

    constructor(
        address _Token,
        uint256 _tokenId,
        uint256 _Price,
        uint256 _Expiration
    ) {
        sender = tx.origin;
        timestamp = block.timestamp;
        Token = _Token;
        tokenId = _tokenId;
        Price = _Price;
        Expiration = _Expiration;
    }

    function getall()
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (timestamp, sender, Token, tokenId, Price, Expiration);
    }

    function get_timestamp() public view returns (uint256) {
        return timestamp;
    }

    function get_sender() public view returns (address) {
        return sender;
    }

    function get_Token() public view returns (address) {
        return Token;
    }

    function get_tokenId() public view returns (uint256) {
        return tokenId;
    }

    function get_Price() public view returns (uint256) {
        return Price;
    }

    function get_Expiration() public view returns (uint256) {
        return Expiration;
    }
}


contract App {
    address[] Sales_list;
    uint256 Sales_list_length;
    
    function transfer(address nftContractAddress, uint256 nftTokenId, address seller, address owner) public{
          ERC721(nftContractAddress).safeTransferFrom(seller, owner, nftTokenId);
    }


    function get_Sales_list_length() public view returns (uint256) {
        return Sales_list_length;
    }

    struct Sales_getter {
        uint256 timestamp;
        address sender;
        address Token;
        uint256 tokenId;
        uint256 Price;
        uint256 Expiration;
    }

    function get_Sales_N(uint256 index)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return Sales_contract(Sales_list[index]).getall();
    }

    function get_first_Sales_N(uint256 count, uint256 offset)
        public
        view
        returns (Sales_getter[] memory)
    {
        Sales_getter[] memory getters = new Sales_getter[](count);
        for (uint256 i = offset; i < count; i++) {
            Sales_contract mySales = Sales_contract(Sales_list[i + offset]);
            getters[i - offset].timestamp = mySales.get_timestamp();
            getters[i - offset].sender = mySales.get_sender();
            getters[i - offset].Token = mySales.get_Token();
            getters[i - offset].tokenId = mySales.get_tokenId();
            getters[i - offset].Price = mySales.get_Price();
            getters[i - offset].Expiration = mySales.get_Expiration();
        }
        return getters;
    }

    function get_last_Sales_N(uint256 count, uint256 offset)
        public
        view
        returns (Sales_getter[] memory)
    {
        Sales_getter[] memory getters = new Sales_getter[](count);
        for (uint256 i = 0; i < count; i++) {
            Sales_contract mySales =
                Sales_contract(Sales_list[Sales_list_length - i - offset - 1]);
            getters[i].timestamp = mySales.get_timestamp();
            getters[i].sender = mySales.get_sender();
            getters[i].Token = mySales.get_Token();
            getters[i].tokenId = mySales.get_tokenId();
            getters[i].Price = mySales.get_Price();
            getters[i].Expiration = mySales.get_Expiration();
        }
        return getters;
    }

    function get_Sales_user_length(address user) public view returns (uint256) {
        return user_map[user].Sales_list_length;
    }

    function get_Sales_user_N(address user, uint256 index)
        public
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return Sales_contract(user_map[user].Sales_list[index]).getall();
    }

    function get_last_Sales_user_N(
        address user,
        uint256 count,
        uint256 offset
    ) public view returns (Sales_getter[] memory) {
        Sales_getter[] memory getters = new Sales_getter[](count);
        for (uint256 i = offset; i < count; i++) {
            getters[i - offset].timestamp = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_timestamp();
            getters[i - offset].sender = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_sender();
            getters[i - offset].Token = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_Token();
            getters[i - offset].tokenId = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_tokenId();
            getters[i - offset].Price = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_Price();
            getters[i - offset].Expiration = Sales_contract(
                user_map[user].Sales_list[i + offset]
            )
                .get_Expiration();
        }
        return getters;
    }

    struct UserInfo {
        address owner;
        bool exists;
        address[] Sales_list;
        uint256 Sales_list_length;
    }
    mapping(address => UserInfo) public user_map;
    address[] UserInfoList;
    uint256 UserInfoListLength;

    event NewSales(address sender);

    function new_Sales(
        address Token,
        uint256 tokenId,
        uint256 Price,
        uint256 Expiration
    ) public returns (address) {
        address mynew =
            address(
                new Sales_contract({
                    _Token: Token,
                    _tokenId: tokenId,
                    _Price: Price,
                    _Expiration: Expiration
                })
            );
        if (!user_map[tx.origin].exists) {
            user_map[tx.origin] = create_user_on_new_Sales(mynew);
        }
        user_map[tx.origin].Sales_list.push(mynew);

        user_map[tx.origin].Sales_list_length += 1;

        Sales_list.push(mynew);
        Sales_list_length += 1;

        emit NewSales(tx.origin);

        return mynew;
    }

    function create_user_on_new_Sales(address addr)
        private
        returns (UserInfo memory)
    {
        address[] memory Sales_list;
        UserInfoList.push(addr);
        return
            UserInfo({
                exists: true,
                owner: addr,
                Sales_list: Sales_list,
                Sales_list_length: 0
            });
    }
}

