// SPDX-License-Identifier: MIT
//
//         `.--.`                                                                         ..
//    -+sdNNNNmddyo/`                               `.-----.`                            :NNy
// .smNMmhs+-.`````/my-                       .:+yhmNNNmddhhyso-                        -NMMo           `.:/+ossys+-
// `+s+-``dd        mMN:        `.-://+++/- /dNMNdyo/-.```````mNh.      `--:/+++/:.    `mMMN`      `:oymNNNNmhyo+yMNo
//       yMh      `oMMMy   ./odmmNNmmdhyso+`/dMo.``os`      .yMMM/`:+ymmNNNmdhyys+-    yMMM+      .mMMMmy/-.`  -hNm+`
//      +MM+    ./dMMMd. .dNMMMMy:-.``       `.   yMM-   ./yNMMmoymMMMMN/-..``        /MMMd`      -NMM+`     .yNNo`
//     .NMN``-+hmMMMd+`  `ohNMMN.                +MMm-/sdNMMmy/` /ydMMMo             `mMMM-        .+h.    `oNMy.
//    `yMMmsdNMMNdo-`      :MMMo                -NMMNNMMMMMy:     `dMMm`             yMMMs            `   /dMm/
//    +MMMMMNmy+-`        `mMMN:/oshhhs.       `dMMmdyo/:-oMNh.   oMMMo:+syhhy/     :MMMm`      `/yh`   -hMNo`
//    dMMNMMm+`           sMMMNmdhs+:-.  ``    sMMN.     :mMMM/  -NMMMmmhs+:-.`  ` `mMMM/     `+dMd:  `sNMh-     `.-/oyo`
//   :MMN:omMMms-`      -sMMMy:.` `.-:+yhdy/  :MMMo    -yMMMNs .+mMMN/-`  `.-+shdhooMMMy    `+mMd/` `/mMd/   .-+ydmmds/-
//   -hmo  `:yNMMd+.    /MMMN-.:oydmNNmho:.  `mMMd` `-sNMMMh:  .dMMMo.-+shmNNmds/-.NMMN.  `+mMd/`  -hMNo../shmNmyo:.
//     `      .+hNMNh/.  yNMNmNNmdyo:.`  -o: sMMM:.+hNMMNh:     :mNMdNMNmhs/-`    sMMM/ `+mMd/`  .sNMNyhdmmho:-`
//               .+hNMmy:`./oo+:.        hMd.NMMNhNMMNdo-        `:+s+:.`        `NMMh.omMd/`   /mMMNmho/-`
//                  ./ymNms.             `/yyNNNNNdy/-                           /MMNsmMd:      -+o/-`
//                     `:+yds               `.---`                               `smNNd:
//                          `                                                      `--
//
// Rebelz ERC-1155 Contract

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Counters.sol";

contract REBELZ is ERC1155, Ownable, ERC1155Burnable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_REBEL = 10000;
    uint256 public constant MAX_REBEL_PER_TX = 20;
    uint256 public constant PRICE = 0.049 ether;

    uint256 public presaleMaxRebelPerWallet = 4;

    address public constant creator1Address =
        0x156B1fD8bE08047782e46CD82d083ec0cDE56A96;
    address public constant creator2Address =
        0x04940D82F76CAac41574095dce4b745D7bE89731;
    address public constant creator3Address =
        0x0E77AB08B861732f8b2a4128974310E57C2e50ab;
    address public constant creator4Address =
        0x07B956073c58d0dd38D7744D741d540Cd213a5Ca;
    address public constant creator5Address =
        0x5d083b6C5a6EFB1c92A3aF57d0fCdb67297af5e8;

    bool public saleOpen = false;
    bool public presaleOpen = false;

    Counters.Counter private _tokenIdTracker;

    event saleStatusChange(bool pause);
    event presaleStatusChange(bool pause);
    string public name;
    string public symbol;
    string public baseTokenURI;

    mapping(address => uint256) private _whitelistMintLogs;

    address private validator_;

    constructor(string memory baseURI, address _validator) ERC1155(baseURI) {
        name = "REBELZ";
        symbol = "REBEL";
        validator_ = _validator;
        setBaseURI(baseURI);
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_REBEL, "Soldout!");
        require(saleOpen, "Sale is not open");
        _;
    }

    modifier presaleIsOpen() {
        require(totalSupply() <= MAX_REBEL, "Soldout!");
        require(presaleOpen, "Presale is not open");
        _;
    }

    function setValidator(address validator) public onlyOwner {
        validator_ = validator;
    }

    function setPresaleMaxPerWallet(uint256 newMax) public onlyOwner {
        presaleMaxRebelPerWallet = newMax;
    }

    function toBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    modifier verify(address _buyer, bytes memory _sign) {
        require(_sign.length == 65, "Invalid signature length");

        bytes memory addressBytes = toBytes(_buyer);

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("rebelznft", addressBytes))
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }

        require(ecrecover(_hash, v, r, s) == validator_, "Invalid sign");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply(), "Token not minted yet.");
        return string(abi.encodePacked(baseTokenURI, toString(_tokenId)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
     * @dev Total minted Rebel.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE * _count;
    }

    function setSaleStatus(bool _isOpen) public onlyOwner {
        saleOpen = _isOpen;
        emit saleStatusChange(saleOpen);
    }

    function setPresaleStatus(bool _isOpen) public onlyOwner {
        presaleOpen = _isOpen;
        emit presaleStatusChange(presaleOpen);
    }

    function _mintRebel(address _to, uint256 _tokenId) private {
        _mint(_to, _tokenId, 1, "");
        _tokenIdTracker.increment();
    }

    function mintPresale(uint256 _numberOfTokens, bytes memory _sign)
        public
        payable
        presaleIsOpen
        verify(msg.sender, _sign)
    {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Rebel");
        require(
            _whitelistMintLogs[wallet] + _numberOfTokens <=
                presaleMaxRebelPerWallet,
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_REBEL,
            "Purchase would exceed max supply of Rebelz"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            uint256 tokenToMint = totalSupply();
            _mintRebel(wallet, tokenToMint);
            _whitelistMintLogs[wallet] += 1;
        }
    }

    function mintSale(uint256 _numberOfTokens) public payable saleIsOpen {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Rebel");
        require(
            _numberOfTokens <= MAX_REBEL_PER_TX,
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_REBEL,
            "Purchase would exceed max supply of Rebelz"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            uint256 tokenToMint = totalSupply();
            _mintRebel(wallet, tokenToMint);
        }
    }

    function reserveRebel(uint256 _numberOfTokens) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _numberOfTokens <= MAX_REBEL);
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            uint256 tokenToMint = totalSupply();
            _mintRebel(owner(), tokenToMint);
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator5Address, (balance * 4) / 100);
        _widthdraw(creator4Address, (balance * 15) / 100);
        _widthdraw(creator3Address, (balance * 27) / 100);
        _widthdraw(creator2Address, (balance * 27) / 100);
        _widthdraw(creator1Address, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}