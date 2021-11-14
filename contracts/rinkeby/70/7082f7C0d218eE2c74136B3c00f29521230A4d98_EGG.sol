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

contract EGG is ERC1155, Ownable, ERC1155Burnable {
    using Counters for Counters.Counter;

    uint256 public constant MAX_EGG = 10000;
    uint256 public constant MAX_EGG_PER_TX = 20;

    uint256 public constant PRESALE_MAX_EGG_PER_WALLET = 2;

    uint256 public constant PRICE = 0.049 ether;

    address public constant creator1Address =
        0xF6c2D1301d6f98B271c378ffa19a8Ff9a822C2da;

    bool public saleOpen = false;
    bool public presaleOpen = false;

    mapping(address => uint256) private _whitelist;

    Counters.Counter private _claimedEgg;
    Counters.Counter private _presaleMemberTracker;
    uint256 private constant _tokenId = 1;

    string public baseTokenURI;

    event saleStatusChange(bool pause);
    event presaleStatusChange(bool pause);
    event welcomeToRebelWorld(address wallet);

    constructor(string memory baseURI) ERC1155(baseURI) {} // to-do

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_EGG, "Soldout!");
        require(saleOpen, "Sale is not open");
        _;
    }

    modifier presaleIsOpen() {
        require(totalSupply() <= MAX_EGG, "Soldout!");
        require(presaleOpen, "Presale is not open");
        _;
    }

    modifier authorizedToPresale() {
        address wallet = _msgSender();
        bool isAuthorized = _whitelist[wallet] >= 1;
        require(
            isAuthorized,
            "You are not in the whitelist or you already minted the allowed amount"
        );
        _;
    }

    modifier notAuthorizedToPresale() {
        address wallet = _msgSender();
        bool isAuthorized = _whitelist[wallet] >= 1;
        require(
            !isAuthorized,
            "You are not in the whitelist or you already minted the allowed amount"
        );
        _;
    }

    /**
     * @dev Change the URI
     */
    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    /**
     * @dev Total claimed egg.
     */
    function totalSupply() public view returns (uint256) {
        return _claimedEgg.current();
    }

    function totalPresaler() public view returns (uint256) {
        return _presaleMemberTracker.current();
    }

    function amIPresaler() public view returns (bool) {
        address wallet = _msgSender();
        return _whitelist[wallet] > 0;
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

    function setWhitelistBulk(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = PRESALE_MAX_EGG_PER_WALLET;
        }
    }

    function setWhitelist(address addr, uint256 count) external onlyOwner {
        _whitelist[addr] = count;
    }

    function _mintEgg(address _to, uint256 _numberOfTokens) private {
        _mint(_to, _tokenId, _numberOfTokens, "");
        for (uint8 i = 0; i < _numberOfTokens; i++) {
            _claimedEgg.increment();
        }
        emit welcomeToRebelWorld(_to);
    }

    function mintPresale(uint256 _numberOfTokens)
        public
        payable
        presaleIsOpen
        authorizedToPresale
    {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Eggs");
        require(
            _numberOfTokens <= _whitelist[wallet],
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_EGG,
            "Purchase would exceed max supply of Eggs"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        _mintEgg(wallet, _numberOfTokens);
        _whitelist[wallet] -= _numberOfTokens;
    }

    function mintSale(uint256 _numberOfTokens) public payable saleIsOpen {
        uint256 total = totalSupply();
        address wallet = _msgSender();
        require(_numberOfTokens > 0, "You can't mint 0 Eggs");
        require(
            _numberOfTokens <= MAX_EGG_PER_TX,
            "You can't mint more than the allowed amount"
        );
        require(
            total + _numberOfTokens <= MAX_EGG,
            "Purchase would exceed max supply of Eggs"
        );
        require(msg.value >= price(_numberOfTokens), "Value below price");
        _mintEgg(wallet, _numberOfTokens);
    }

    function reserveEgg(uint256 _numberOfTokens) public onlyOwner {
        uint256 total = totalSupply();
        require(total + _numberOfTokens <= MAX_EGG);
        _mintEgg(owner(), _numberOfTokens);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator1Address, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}