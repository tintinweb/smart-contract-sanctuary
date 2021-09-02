/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// /home/box/maker/HackToken/src/Hacktoken.sol
/// erc721.sol -- API for the ERC721 token standard

// See <https://github.com/ethereum/EIPs/issues/721>.

// This file likely does not meet the threshold of originality
// required for copyright to apply.  As a result, this is free and
// unencumbered software belonging to the public domain.

// SPDX-License-Identifier: NLPL
pragma solidity >=0.6.0;

interface ERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 nft) external view returns (string memory);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 idx) external view returns (uint256);
    function tokenOfOwnerByIndex(address guy, uint256 idx) external view returns (uint256);
}

interface ERC721Events {
    event Transfer(address indexed src, address indexed dst, uint256 nft);
    event Approval(address indexed src, address indexed guy, uint256 nft);
    event ApprovalForAll(address indexed guy, address indexed op, bool ok);
}

interface ERC721TokenReceiver {
    function onERC721Received(address op, address src, uint256 nft, bytes calldata what) external returns(bytes4);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165, ERC721Events, ERC721TokenReceiver {
    function balanceOf(address guy) external view returns (uint256);
    function ownerOf(uint256 nft) external view returns (address);
    function safeTransferFrom(address src, address dst, uint256 nft, bytes calldata what) external payable;
    function safeTransferFrom(address src, address dst, uint256 nft) external payable;
    function transferFrom(address src, address dst, uint256 nft) external payable;
    function approve(address guy, uint256 nft) external payable;
    function setApprovalForAll(address op, bool ok) external;
    function getApproved(uint256 nft) external returns (address);
    function isApprovedForAll(address guy, address op) external view returns (bool);
}
// License: GPL-3.0-or-later

/// deed.sol -- basic ERC721 implementation

// Copyright (C) 2020  Brian McMichael

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//pragma solidity >=0.6.0;

//import "erc721/erc721.sol";

contract DSDeed is ERC721, ERC721Enumerable, ERC721Metadata {

    bool                             public   stopped;
    mapping (address => uint)        public   wards;

    uint256                          private  _ids;

    string                           internal _name;
    string                           internal _symbol;

    mapping (uint256 => string)      internal _uris;

    mapping (bytes4 => bool)         internal _interfaces;

    uint256[]                        internal _allDeeds;
    mapping (address => uint256[])   internal _usrDeeds;
    mapping (uint256 => Deed)        internal _deeds;
    mapping (address => mapping (address => bool)) internal _operators;

    struct Deed {
        uint256      pos;
        uint256     upos;
        address      guy;
        address approved;
    }

    event Stop();
    event Start();
    event Rely(address indexed guy);
    event Deny(address indexed guy);

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _addInterface(0x80ac58cd); // ERC721
        _addInterface(0x5b5e139f); // ERC721Metadata
        _addInterface(0x780e9d63); // ERC721Enumerable
        wards[msg.sender] = 1;
    }

    modifier nod(uint256 nft) {
        require(
            _deeds[nft].guy == msg.sender ||
            _deeds[nft].approved == msg.sender ||
            _operators[_deeds[nft].guy][msg.sender],
            "ds-deed-insufficient-approval"
        );
        _;
    }

    modifier stoppable {
        require(!stopped, "ds-deed-is-stopped");
        _;
    }

    modifier auth {
        require(wards[msg.sender] == 1, "ds-deed-not-authorized");
        _;
    }

    function name() external override view returns (string memory) {
        return _name;
    }

    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 nft) external override view returns (string memory) {
        return _uris[nft];
    }

    function totalSupply() external override view returns (uint256) {
        return _allDeeds.length;
    }

    function tokenByIndex(uint256 idx) external override view returns (uint256) {
        return _allDeeds[idx];
    }

    function tokenOfOwnerByIndex(address guy, uint256 idx) external override view returns (uint256) {
        require(idx < balanceOf(guy), "ds-deed-index-out-of-bounds");
        return _usrDeeds[guy][idx];
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns(bytes4) {
        revert("ds-deed-does-not-accept-tokens");
    }

    function _isContract(address addr) private view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // EIP-1052
        assembly { codehash := extcodehash(addr) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function supportsInterface(bytes4 interfaceID) external override view returns (bool) {
        return _interfaces[interfaceID];
    }

    function _addInterface(bytes4 interfaceID) private {
        _interfaces[interfaceID] = true;
    }

    function balanceOf(address guy) public override view returns (uint256) {
        require(guy != address(0), "ds-deed-invalid-address");
        return _usrDeeds[guy].length;
    }

    function ownerOf(uint256 nft) external override view returns (address) {
        require(_deeds[nft].guy != address(0), "ds-deed-invalid-nft");
        return _deeds[nft].guy;
    }

    function safeTransferFrom(address src, address dst, uint256 nft, bytes calldata what) external override payable {
        _safeTransfer(src, dst, nft, what);
    }

    function safeTransferFrom(address src, address dst, uint256 nft) public override payable {
        _safeTransfer(src, dst, nft, "");
    }

    function push(address dst, uint256 nft) external {
        safeTransferFrom(msg.sender, dst, nft);
    }

    function pull(address src, uint256 nft) external {
        safeTransferFrom(src, msg.sender, nft);
    }

    function move(address src, address dst, uint256 nft) external {
        safeTransferFrom(src, dst, nft);
    }

    function _safeTransfer(address src, address dst, uint256 nft, bytes memory data) internal {
        transferFrom(src, dst, nft);
        if (_isContract(dst)) {
            bytes4 res = ERC721TokenReceiver(dst).onERC721Received(msg.sender, src, nft, data);
            require(res == this.onERC721Received.selector, "ds-deed-invalid-token-receiver");
        }
    }

    function transferFrom(address src, address dst, uint256 nft) public override payable stoppable nod(nft) {
        require(src == _deeds[nft].guy, "ds-deed-src-not-valid");
        require(dst != address(0) && dst != address(this), "ds-deed-unsafe-destination");
        require(_deeds[nft].guy != address(0), "ds-deed-invalid-nft");
        _upop(nft);
        _upush(dst, nft);
        _approve(address(0), nft);
        emit Transfer(src, dst, nft);
    }

    function mint(string memory uri) public returns (uint256) {
        return mint(msg.sender, uri);
    }

    function mint(address guy) public returns (uint256) {
        return mint(guy, "");
    }

    function mint(address guy, string memory uri) public auth stoppable returns (uint256 nft) {
        return _mint(guy, uri);
    }

    function _mint(address guy, string memory uri) internal returns (uint256 nft) {
        require(guy != address(0), "ds-deed-invalid-address");
        nft = _ids++;
        _allDeeds.push(nft);
        _deeds[nft] = Deed(
            _allDeeds[_allDeeds.length - 1],
            _usrDeeds[guy].length - 1,
            guy,
            address(0)
        );
        _upush(guy, nft);
        _uris[nft] = uri;
        emit Transfer(address(0), guy, nft);
    }

    function burn(uint256 nft) public auth stoppable {
        _burn(nft);
    }

    function _burn(uint256 nft) internal {
        address guy = _deeds[nft].guy;
        require(guy != address(0), "ds-deed-invalid-nft");

        uint256 _idx        = _deeds[nft].pos;
        uint256 _mov        = _allDeeds[_allDeeds.length - 1];
        _allDeeds[_idx]     = _mov;
        _deeds[_mov].pos    = _idx;
        _allDeeds.pop();    // Remove from All deed array
        _upop(nft);         // Remove from User deed array

        delete _deeds[nft]; // Remove from deed mapping

        emit Transfer(guy, address(0), nft);
    }

    function _upush(address guy, uint256 nft) internal {
        _deeds[nft].upos           = _usrDeeds[guy].length;
        _usrDeeds[guy].push(nft);
        _deeds[nft].guy            = guy;
    }

    function _upop(uint256 nft) internal {
        uint256[] storage _udds    = _usrDeeds[_deeds[nft].guy];
        uint256           _uidx    = _deeds[nft].upos;
        uint256           _move    = _udds[_udds.length - 1];
        _udds[_uidx]               = _move;
        _deeds[_move].upos         = _uidx;
        _udds.pop();
        _usrDeeds[_deeds[nft].guy] = _udds;
    }

    function approve(address guy, uint256 nft) external override payable stoppable nod(nft) {
        _approve(guy, nft);
    }

    function _approve(address guy, uint256 nft) internal {
        _deeds[nft].approved = guy;
        emit Approval(msg.sender, guy, nft);
    }

    function setApprovalForAll(address op, bool ok) external override stoppable {
        _operators[msg.sender][op] = ok;
        emit ApprovalForAll(msg.sender, op, ok);
    }

    function getApproved(uint256 nft) external override returns (address) {
        require(_deeds[nft].guy != address(0), "ds-deed-invalid-nft");
        return _deeds[nft].approved;
    }

    function isApprovedForAll(address guy, address op) external override view returns (bool) {
        return _operators[guy][op];
    }

    function stop() external auth {
        stopped = true;
        emit Stop();
    }

    function start() external auth {
        stopped = false;
        emit Start();
    }

    function rely(address guy) external auth {
        wards[guy] = 1;
        emit Rely(guy);
    }

    function deny(address guy) external auth {
        wards[guy] = 0;
        emit Deny(guy);
    }

    function setTokenUri(uint256 nft, string memory uri) public auth stoppable {
        _uris[nft] = uri;
    }
}
// License: GPL-3.0-or-later

/// Hacktoken.sol -- ERC721 implementation with redeemable prizes

// Copyright (C) 2020  Brian McMichael

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//pragma solidity ^0.6.11;

//import "ds-deed/deed.sol";

interface ChainLog {
    function getAddress(bytes32) external view returns (address);
}

interface Dai {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract Hacktoken is DSDeed {

    ChainLog public constant  CL = ChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    Dai      public immutable DAI;

    struct Winner {
        bool    valid;           // True if token is a prize winner
        bool    redeemed;        // True if prize has been redeemed
        uint192 badge;           // The identifier for the prize
    }
    mapping (uint256 => Winner)  public winners;  // TokenID => Winner data

    mapping (uint256 => uint256) public rewards;  // badge_code => reward amount

    event PrizeAdded(uint256 badge_code, uint256 prize_amount);
    event Redeemed(uint256 tokenId);

    constructor(string memory name, string memory symbol) public DSDeed(name, symbol) {
        DAI = Dai(CL.getAddress("MCD_DAI"));
    }

    /**
        @dev Sets the reward amount for a badge code
        @param badge_code   A number representing the badge class
        @param wad          The amount of Dai to pay a winner (1 Dai = 10**18)
    */
    function setWinnerParams(uint256 badge_code, uint256 wad) public auth {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        rewards[badge_code] = wad;
        emit PrizeAdded(badge_code, wad);
    }

    /**
        @dev Allows the owner of a token to redeem it for a prize
        @param token        The token id to redeem
    */
    function redeem(uint256 token) external {
        require(this.ownerOf(token) == msg.sender, "only-redeemable-by-owner");
        Winner memory prospect = winners[token];
        require(prospect.valid, "not-a-winner");
        require(!prospect.redeemed, "prize-has-been-redeemed");
        uint256 reward = rewards[prospect.badge];
        require(DAI.balanceOf(address(this)) >= reward, "insufficient-dai-balance-for-award");
        require(reward != 0, "no-dai-award");
        winners[token].redeemed = DAI.transferFrom(address(this), msg.sender, reward);
        emit Redeemed(token);
    }

    /**
        @dev Mint a winning token without a metadata URI. Requires auth on mint.
        @param guy          The address of the recipient
        @param badge_code   The prize code
    */
    function mintWinner(address guy, uint256 badge_code) external returns (uint256 id) {
        return mintWinner(guy, badge_code, "");
    }

    /**
        @dev Mint a winning token with a metadata URI. Requires auth on mint.
        @param guy          The address of the recipient
        @param badge_code   The prize code
        @param uri          A URL to provide a metadata url
    */
    function mintWinner(address guy, uint256 badge_code, string memory uri) public returns (uint256 id) {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        id = mint(guy, uri);
        winners[id] = Winner(true, false, uint192(badge_code));
    }

    /**
        @dev Assign a prize to an existing token
        @param tokenID      The NFT ID
        @param badge_code   The prize code
    */
    function assignWinner(uint256 tokenID, uint256 badge_code) public auth {
        require(this.ownerOf(tokenID) != address(0), "hacktoken-invalid-nft");
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        winners[tokenID] = Winner(true, false, uint192(badge_code));
    }

    function isWinner(uint256 tokenID) external view returns (bool) {
        return winners[tokenID].valid;
    }

    function isRedeemed(uint256 tokenID) external view returns (bool) {
        return (winners[tokenID].valid && winners[tokenID].redeemed);
    }

    function rewardAmount(uint256 tokenID) external view returns (uint256) {
        Winner memory prospect = winners[tokenID];
        if (prospect.valid && !prospect.redeemed) {
            return rewards[prospect.badge];
        } else {
            return 0;
        }
    }

    /**
        @dev Contract owner can withdraw unused funds.
    */
    function defund() public auth {
        DAI.transferFrom(address(this), msg.sender, DAI.balanceOf(address(this)));
    }
}