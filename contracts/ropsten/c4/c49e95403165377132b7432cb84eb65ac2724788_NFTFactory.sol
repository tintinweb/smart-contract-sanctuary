/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
// @dev uint256 type conversion and counter library.
library UINT256 {
        /**
          * @dev Converts uint256 to string.
          */
        function toString(uint256 _value) internal pure returns (string memory) {
                // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
                if (_value == 0) {
                        return "0";
                }
                uint256 temp = _value;
                uint256 digits;

                while (temp != 0) {
                        digits++;
                        temp /= 10;
                }
                bytes memory buffer = new bytes(digits);
                while (_value != 0) {
                        digits -= 1;
                        buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
                        _value /= 10;
                }
                return string(buffer);
        }
}
// @dev Group of granted address.
abstract contract AdminGroup {
        using UINT256 for uint256;
        mapping(address => uint256) private _admin;
        uint256 private _baseAdmin = 1;
        uint256 private _superAdmin = 2;
        bytes32 private _secret;
        event AddAdmin(address indexed _user, uint256 _role);
        event RemoveAdmin(address indexed _user, uint256 _role);
        event TransferAdmin(address indexed _from, address indexed _to, uint256 _role);

        /**
          * @dev Set super admin for the group.
          *
          * @param _user is address of the user will be asigned to roles group.
          *
          * Requirements:
          *
          * - `_user` must be `false` or never be granted.
          */
        function superAdmin(address _user) internal {
                require(!isAdmin(_user), "Error: this address already granted.");
                _admin[_user] = _superAdmin;
                emit AddAdmin(_user, _superAdmin);
        }
        // @dev Check if given address was granted.
        function isAdmin(address _user) internal view returns (bool) {
                uint256 role = getRole(_user);
                return role == _baseAdmin || role == _superAdmin;
        }
        // @dev Get current roles of the user.
        function getRole(address _user) internal view returns (uint256) {
                return _admin[_user];
        }
        /**
          * @dev Modifier that check if transactor has required roles.
          * @param _role is the level ove required roles.
          *
          * Requirements:
          *
          * - `_role` should be available.
          * - if `role` is base admin, super admin should be granted.
          */
        modifier roleGroup(uint256 _role) {
                if(_role != _baseAdmin || _role != _superAdmin) {
                        revert(
                                string(
                                        abi.encodePacked(
                                                "Error: unsupported roles ",
                                                _role.toString(),
                                                " use ",
                                                _baseAdmin.toString(),
                                                " for base admin or ",
                                                _superAdmin.toString(),
                                                " for super admin instead."
                                        )
                                )
                        );
                }
                if (_role == _baseAdmin) {
                        require(isAdmin(msg.sender), "Error: min base admin roles needed.");
                } else {
                        require(getRole(msg.sender) == _role, "Error: super admin roles needed.");
                }
                _;
        }
        /**
          * @dev Add new user to the roles group.
          *
          * @param _user is the address of the user will be asigned to roles group.
          * @param _role is the roles will be asigned to user.
          *
          * Requirements:
          *
          * - `_user` should never be asigned to roles group.
          * - `_role` should be avaikable.
          * - transactor should have super admin roles.
          */
        function grant(address _user, uint256 _role) public roleGroup(2) {
                if (_role != _baseAdmin || _role != _superAdmin) {
                        revert(string(
                                abi.encodePacked(
                                        "Error: unsupported roles, use ",
                                        _baseAdmin,
                                        " for base admin or ",
                                        _superAdmin,
                                        " for super admin instead."
                                )
                        ));
                }
                require(_user != address(0), "Error: assigning role to zero address.");
                require(!isAdmin(_user), "Error: user already granted.");
                _admin[_user] = _role;
                emit AddAdmin(_user, _role);
        }
        /**
          * @dev Remove specific user from role group.
          *
          * @param _user the target address will be removed from roles.
          */
        function deny(address _user) public roleGroup(2) {
                if (isAdmin(_user)) {
                        uint256 role = getRole(_user);
                        delete _admin[_user];
                        emit RemoveAdmin(_user, role);
                }
        }
        /**
          * @dev Transfer roles from current admin to `_to`.
          *
          * @param _to is the address for new admin.
          *
          * Requirements:
          *
          * - transactor should be assigned as admin group.
          * - `_to` should not part of admin group.
          * - `_to` cannot be same address with transactor.
          * - `_to` cannot be zero address.
          */
        function transferRole(address _to) public roleGroup(1) {
                require(_to != address(0), "Error: transaction to zero address.");
                require(_to != msg.sender, "Error: transactor and destination are same.");
                require(!isAdmin(_to), "Error: already assigned to roles.");
                uint256 role = _admin[msg.sender];
                _admin[_to] = role;
                delete _admin[msg.sender];
                emit TransferAdmin(msg.sender, _to, role);
        }
        /**
          * @dev Set new secret keys.
          *
          * @param _key is string for new _secret
          *
          * Requirements:
          *
          * - `_key` cannot be empty.
          */
        function setKey(string memory _key) internal {
                require(bytes(_key).length > 0, "Error: key cannot be empty.");
                _secret = keccak256(abi.encodePacked(_key));
        }
        /**
          * @dev Check if transactor was using right secret / password.
          *
          * @param _key string of key.
          *
          * Requirements:
          *
          * - `_secret` should not empty.
          */
        modifier Auth(string memory _key) {
                require(bytes(_key).length > 0, "Error: secret key should not empty.");
                require(keccak256(abi.encodePacked(_key)) == _secret, "Error: wrong secret key.");
                _;
        }
}
// @dev uint256 type conversion and counter library.
library UINT256Libs {
        struct u256 {
                uint256 _value;
        }
        bytes16 private constant HEX_SYMBOL = "0123456789abcdef";
        // @dev Get current u256 value.
        function val(u256 storage count) internal view returns (uint256) {
                return count._value;
        }
        // @dev Increment u256._value by 1.
        function inc(u256 storage count) internal {
                count._value += 1;
        }
        /**
          * @dev Decrement u256._value by 1.
          *
          * Requirements:
          *
          * - `u256._value` should be greater than 0.
          */
        function dec(u256 storage count) internal {
                require(count._value > 0, "Error: decrement overflow.");
                count._value -= 1;
        }
        // @dev Reset u256._value.
        function nil(u256 storage count) internal {
                count._value = 0;
        }
}
interface IENFT {

        function mintCustom(address _to, string memory uri_, string memory secret_) external returns (uint256);
        function getCurrentId(string memory secret_) external view returns (uint256);

}
contract NFTFactory is AdminGroup {
        using UINT256Libs for UINT256Libs.u256;
        mapping(uint256 => string) private _uriOf;
        mapping(uint256 => address) public creatorOf;
        mapping(uint256 => uint256) private _donateOf;

        UINT256Libs.u256 private _uriCount;
        uint256 private _uriIndex;
        string private secretKey;
        bool public isAcceptDonations;
        bool public isPublicMint;
        uint256 public totalDonations;
        uint256 public totalNFTMinted;
        uint256 public nftCreationCost;
        IENFT private nft;
        address private csAddress;
        constructor(address nftAddress, string memory key_) {
                superAdmin(msg.sender);
                nft = IENFT(nftAddress);
                csAddress = nftAddress;
                secretKey = key_;
        }
        // add new nft metadata uri.
        function addURI(string memory uri_) public virtual {
                _uriCount.inc();
                _uriOf[_uriCount.val()] = uri_;
        }
        // get total uri.
        function totalURI() public view virtual returns (uint256) {
                return _uriCount.val();
        }
        // set uri index.
        function setURIIndex(uint256 index_) public roleGroup(1) {
                _uriIndex = index_;
        }
        // set nft creation cost.
        function setNFTCreationCost(uint256 cost_) public roleGroup(1) {
                nftCreationCost = cost_;
        }
        // set accept donations.
        function setAcceptDonations(bool value_) public roleGroup(1) {
                isAcceptDonations = value_;
        }
        // set public mint.
        function setPublicMint(bool value_) public roleGroup(1) {
                isPublicMint = value_;
        }
        // create new nft.
        function createNFT(string memory uri_) public virtual returns (address, uint256) {
                require(isPublicMint, "Error: not allowed.");
                (address Address, uint256 id) = _mint(msg.sender, uri_);
                creatorOf[id] = msg.sender;
                return (Address, id);
        }
        // create new nft by paying to this address.
        function payNFT(string memory uri_) public payable returns (address, uint256) {
                require(msg.value >= nftCreationCost, "Error: not allowed.");
                (address Address, uint256 id) = _mint(msg.sender, uri_);
                creatorOf[id] = msg.sender;
                return (Address, id);
        }
        function _mint(address _to, string memory uri_) internal virtual returns (address, uint256) {
                uint256 id = nft.mintCustom(_to, uri_, secretKey);
                totalNFTMinted += 1;
                return (csAddress, id);
        }
        function donate() public payable returns (address, uint256) {
                require(isAcceptDonations, "Error: currently not accept donations.");
                (address Address, uint256 id) = _mint(msg.sender, _uriOf[_uriIndex]);
                totalDonations += msg.value;
                _donateOf[id] = msg.value;
                return (Address, id);
        }
        function donateOf(uint256 tokenId_) public view roleGroup(1) returns (uint256) {
                return _donateOf[tokenId_];
        }
        receive() external payable {
                if (isAcceptDonations) {
                        (address Address, uint256 id) = _mint(msg.sender, _uriOf[_uriIndex]);
                        _donateOf[id] = msg.value;
                }
                totalDonations += msg.value;
        }
        function withdrawl() public roleGroup(1) {
                payable(msg.sender).transfer(address(this).balance);
        }
}