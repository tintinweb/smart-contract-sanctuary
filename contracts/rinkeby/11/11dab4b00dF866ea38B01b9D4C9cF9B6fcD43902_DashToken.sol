// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
//import "./ERC20Token.sol";

contract DashToken is ERC1155{  //ERC20Token

    uint256 public constant DST = 0;
    
    constructor() ERC1155("https://native.token/token/{id}.json") {
        _mint(msg.sender, DST, 10**18, "");
        tokenDetails[DST].tokenId = DST;
        tokenDetails[DST].totalTokens = 10**18;
        tokenDetails[DST].isNFT = false;
    }
    
    
    struct Property {
        uint256 propertyId;
        uint256 propertyPrice;
        uint256 investmentPortion;
        uint256 rentAmount;
        bool ispropertyKYC;
        uint256 balance;       //balanceOf a particular user can be found using the erc1155 function
    }
    
    // struct Owner {
    //     uint256 userId;
    //     uint256[] properties;
    //     uint256 balance;
    // }
    
    // Can assign minter and pauser roles and admin roles to the deployer
    
    struct User {
        uint256 userId;
        address user;
        bool issuerKYC;
        bool hasProperty;
        bool isOwner;                           //Check if it has samesignificance as hasProperty
        uint256[] properties;
        // uint256 balance;
    }

    struct Token {
        uint256 tokenId;
        uint256 totalTokens;
        bool isNFT;
    }
    
    mapping(uint256 => mapping(uint256 => Property)) propertywiseInvestment;    //userid => propertyid => balance
    mapping(uint256 => mapping(address => uint256)) balances;
    //mapping(uint256 => bool) _hasProperty;
    //mapping(uint256 => bool) _ispropertyKYC;
    //mapping(uint256 => bool) _issuerKYC;
    mapping(uint256 => User) userDetails;
    mapping(uint256 => Property) propertyDetails;
    mapping(uint256 => Token) tokenDetails;
    mapping(uint256 => uint256) propertyOwner;
    
    modifier hasProperty(uint256 userId) {
        require(userDetails[userId].hasProperty);
        _;
    }
    
    modifier issuerKYC(uint256 userId) {
        require(userDetails[userId].issuerKYC);
        _;
    }
    
    modifier ispropertyKYC(uint256 propertyId) {
        require(propertyDetails[propertyId].ispropertyKYC);
        _;
    }
    
    function addUser(uint256 _userId, address _user) public {
        userDetails[_userId].userId = _userId;
        userDetails[_userId].user = _user;
        userDetails[_userId].issuerKYC = true;
        userDetails[_userId].hasProperty = false;
    }
    
    
    function addProperty(uint256 _userId, uint256 _propertyId, uint256 _propertyPrice,
            uint256 _rentAmount) public issuerKYC(_userId) {
        
        propertyDetails[_propertyId].propertyId = _propertyId;
        propertyDetails[_propertyId].propertyPrice = _propertyPrice;
        propertyDetails[_propertyId].rentAmount = _rentAmount;
        propertyDetails[_propertyId].ispropertyKYC = true;
        propertyOwner[_propertyId] = userDetails[_userId].userId;
        userDetails[_userId].isOwner = true;
        userDetails[_userId].hasProperty = true;
        userDetails[_userId].properties.push(_propertyId);
        uint256 _tokenId = _propertyId;
        tokenDetails[_tokenId].tokenId = _tokenId;
        tokenDetails[_tokenId].totalTokens = 1;
        tokenDetails[_tokenId].isNFT = true;
        _mint(userDetails[_userId].user, tokenDetails[_tokenId].tokenId, tokenDetails[_tokenId].totalTokens, "");        //As of now the tokenId for the property is same as propertyId
        balances[_tokenId][userDetails[_userId].user] = 1; 
        
        // Use the mint function for ERC1155 
    }
    //generate id which is random so dont have to get it as an input in some of the functions
    
    function listProperty(uint256 _userId, uint256 _propertyId, uint256 _investmentPortion) public hasProperty(_userId) ispropertyKYC(_propertyId){
            uint256 _tokenId = _propertyId;
            require(tokenDetails[_tokenId].isNFT); 
            propertyDetails[_propertyId].investmentPortion = _investmentPortion;
        
    }
    
    function getUserDetails(uint256 _userId) public view returns(uint256 , address , bool, bool) {
        return(userDetails[_userId].userId, userDetails[_userId].user, userDetails[_userId].issuerKYC, userDetails[_userId].hasProperty);
    }
    
    function getPropertyDetails(uint256 _propertyId) public view returns(uint256, uint256, uint256, uint256, bool) {
        return(propertyDetails[_propertyId].propertyId, propertyDetails[_propertyId].propertyPrice, 
                    propertyDetails[_propertyId].investmentPortion, propertyDetails[_propertyId].rentAmount, propertyDetails[_propertyId].ispropertyKYC);
    }
    
    function invest(uint256 _investoruserId, uint256 _tokenId, uint256 _propertyId, uint256 _amount) public issuerKYC(_investoruserId) ispropertyKYC(_propertyId){ 
        uint256 _owneruserId = propertyOwner[_propertyId];
        propertywiseInvestment[_owneruserId][_propertyId].balance = _amount;
        safeTransferFrom(userDetails[_investoruserId].user, userDetails[_owneruserId].user, _tokenId, _amount, "");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./IERC1155.sol";
//import "./IERC1155Receiver.sol";


contract ERC1155 is IERC1155{                       //IERC1155Receiver 
    //using Address for address;
    
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;
    
    
    constructor(string memory uri_) {
        _setURI(uri_);
    }
    
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function isContract(address account) external view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }


    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    function _safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        //_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function _safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        //_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    
    function _mint( address account, uint256 id, uint256 amount, bytes memory data ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        //_doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }
    
    function _beforeTokenTransfer( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    // function _doSafeTransferAcceptanceCheck( address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
    //     if (isContract(to)) {
    //         try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
    //             if (response != IERC1155Receiver.onERC1155Received.selector) {
    //                 revert("ERC1155: ERC1155Receiver rejected tokens");
    //             }
    //         } catch Error(string memory reason) {
    //             revert(reason);
    //         } catch {
    //             revert("ERC1155: transfer to non ERC1155Receiver implementer");
    //         }
    //     }
    // }

    // function _doSafeBatchTransferAcceptanceCheck( address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
    //     if (isContract(to)) {
    //         try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
    //             bytes4 response
    //         ) {
    //             if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
    //                 revert("ERC1155: ERC1155Receiver rejected tokens");
    //             }
    //         } catch Error(string memory reason) {
    //             revert(reason);
    //         } catch {
    //             revert("ERC1155: transfer to non ERC1155Receiver implementer");
    //         }
    //     }
    // }
    
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    
    event TransferBatch( address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);
    
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    
    function safeBatchTransferFrom( address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

