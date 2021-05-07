/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts\interfaces\IPubgNFT.sol

pragma solidity 0.6.6;

interface IPubgNFT {
    // function getOwner() external view override returns (address);
    function getMaxSupply(uint256 _typeId) external view returns (uint256);
    function getCurrentSupply(uint256 _typeId) external view returns (uint256);
    function batchMint(address[] calldata _to, uint256[] calldata _tokenId) external returns (bool);
    function setTokenURI(uint256 _tokenId, string calldata _tokenURIHash) external returns (bool);
    function getTokenURI(uint256 _tokenId) external view returns (string memory);
    function batchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _typeId) external returns (bool);
}

// File: contracts\interfaces\IKAP_721.sol

pragma solidity 0.6.6;

interface IKAP_721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts\PubgNFT.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;



// import "./interfaces/IAdmin.sol";
// import "./interfaces/IKYC.sol";

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract PubgNFT is IPubgNFT, IKAP_721 {
    using SafeMath for uint256;
    using Address for address;

    address owner = msg.sender;
    string public name = "PubgTOKEN";
    string public symbol = "PTK";
    uint256 public totalSupply;

    // IAdmin public admin;
    // IKYC public kyc;

    modifier onlySuperAdmin() {
        // require(admin.isSuperAdmin(msg.sender), "Restricted only super admin");
        _;
    }

    modifier onlyAdmin() {
        // require(admin.isAdmin(msg.sender), "Restricted only admin");
        _;
    }

    // constructor(address _admin, address _kyc) public {
    //     admin = IAdmin(_admin);
    //     kyc = IKYC(_kyc);
    // }

    // function getOwner() external view override returns (address) {
    //     return address(admin);
    // }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    mapping(address => uint256) private tokenBalances;
    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => address) private tokenApprovals;
    mapping(uint256 => string) private tokenURI;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    mapping(uint256 => uint256) private maxSupply;
    mapping(uint256 => uint256) private recentSupply;
    mapping(address => mapping(uint256 => uint256[])) public cardHolder;

    // bool public isActivatedOnlyKycAddress;

    // function setNewAdminAndKYC(address _admin, address _kyc) external onlySuperAdmin {
    //     admin = IAdmin(_admin);
    //     kyc = IKYC(_kyc);
    // }

    // function changeName(string memory _newName) public onlySuperAdmin {
    //     name = _newName;
    // }

    // function changeSymbol(string memory _newSymbol) public onlySuperAdmin {
    //     symbol = _newSymbol;
    // }

    // function activateOnlyKycAddress() external onlySuperAdmin {
    //     isActivatedOnlyKycAddress = true;
    // }

    function getMaxSupply(uint256 _typeId) external view override returns (uint256) {
        return maxSupply[_typeId];
    }

    function getCurrentSupply(uint256 _typeId) external view override returns (uint256) {
        return recentSupply[_typeId];
    }

    function batchMint(address[] calldata _to, uint256[] calldata _tokenId)
        external
        onlyAdmin
        override
        returns (bool)
    {
        for (uint32 i = 0; i < _to.length; i++) {
            _mint(_to[i], _tokenId[i]);
        }
    }

    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        uint256 _typeId = _tokenId.sub(_tokenId.mod(524288));
        tokenOwners[_tokenId] = _to;
        tokenBalances[_to] = tokenBalances[_to].add(1);
        cardHolder[_to][_typeId].push(_tokenId);
        recentSupply[_typeId] = recentSupply[_typeId].add(1);
        totalSupply = totalSupply.add(1);
        return true;
    }

    function setTokenURI(uint256 _tokenId, string calldata _tokenURIHash)
        external
        override
        returns (bool)
    {
        tokenURI[_tokenId] = _tokenURIHash;
        return true;
    }

    function getTokenURI(uint256 _tokenId)
        external
        view
        override
        returns (string memory)
    {
        uint256 _typeId = _tokenId.sub(_tokenId.mod(524288));
        return tokenURI[_typeId];
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "Address 0x00");
        return tokenBalances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return tokenOwners[_tokenId];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public override {
        require(!(_to.isContract()), "Address is contract");
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        require(tokenOwners[_tokenId] == _from, "_form is not owner");
        require(
            _from == msg.sender ||
                tokenApprovals[_tokenId] == msg.sender ||
                operatorApprovals[_from][msg.sender],
            "Don't have permission to send card"
        );
        require(_to != address(0));
        tokenOwners[_tokenId] = _to;
        tokenBalances[_to] = tokenBalances[_to].add(1);
        tokenBalances[_from] = tokenBalances[_from].sub(1);
        emit Transfer(_from, _to, _tokenId);
    }

    function batchTransferFrom(
        address[] calldata _from,
        address[] calldata _to,
        uint256[] calldata _typeId
    ) external onlySuperAdmin override returns (bool) {
        if (_from.length != _to.length && _to.length != _typeId.length) {
            return false;
        }

        for (uint32 i = 0; i < _to.length; i++) {
            // if (isActivatedOnlyKycAddress == true) {
            //     if (
            //         kyc.kycsLevel(_from[i]) <= 1 || kyc.kycsLevel(_to[i]) <= 1
            //     ) {
            //         continue;
            //     }
            // }
            _transferFromInternal(_from[i], _to[i], _typeId[i]);
        }
        return true;
    }

    function _transferFromInternal(
        address _from,
        address _to,
        uint256 _typeId
    ) internal {
        // require(_to != address(0));
        require(cardHolder[_from][_typeId].length > 0);
        uint256 _tokenId = cardHolder[_from][_typeId][cardHolder[_from][_typeId].length-1];
        tokenOwners[_tokenId] = _to;
        delete cardHolder[_from][_typeId][cardHolder[_from][_typeId].length-1];
        cardHolder[_to][_typeId].push(_tokenId);
        tokenBalances[_to] = tokenBalances[_to].add(1);
        tokenBalances[_from] = tokenBalances[_from].sub(1);
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        require(tokenOwners[_tokenId] == msg.sender, "You are not owner");
        tokenApprovals[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) external override {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view override returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }
}