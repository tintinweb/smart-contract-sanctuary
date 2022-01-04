// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";

contract ImmortalApe is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    uint256 public maxTotalSupply = 2200;
    uint256 public maxGiftSupply = 22;
    uint256 public maxCount = 2;
    uint256 public giftCount;
    uint256 public presaleCount;
    uint256 public totalNFT;
    bool public isBurnEnabled;
    bool public PublicSaleStarted;
    bool public PreSaleStarted = false;
    uint256 public MintPrice = 100000000000000000;
    string public baseURI;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [33, 33, 33, 1];
    address[] private _team = [0xCeFdcE1Ad6FA5ce59Fb82D24D003d116093FbD93, 0xcE3bEDD26732C65f04a13884DC41904603293b14, 0x413Fa98d99f6Bb04736A0308FB4396bb27Be4E82, 0x5BbABd4C233BC292f7128f2f83A8B4d3D314b9A5];
    mapping(address => bool) private _presaleList;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _giftClaimed;
    mapping(address => uint256) public _saleClaimed;
    mapping(address => uint256) public _totalClaimed;

    enum WorkflowStatus {
        CheckOnPresale,
        Presale,
        Sale,
        SoldOut
    }
    WorkflowStatus public workflow;
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangePublicSaleStarted(bool _PublicSaleStarted);
    event ChangePreSaleStarted(bool _PreSaleStarted);
    event ChangeBaseURI(string _baseURI);
    event ChangeMintPrice(uint256 _MintPrice);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("Popila", "POP")
        PaymentSplitter(_team, _teamShares)
    {}

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function addToPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Message: Can't add a zero address"
            );
            if (_presaleList[_addresses[ind]] == false) {
                _presaleList[_addresses[ind]] = true;
            }
        }
    }

    function isOnPresaleList(address _address) external view returns (bool) {
        return _presaleList[_address];
    }

    function removeFromPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Message: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpSale(bool _PublicSaleStarted) external onlyOwner {
               PublicSaleStarted = _PublicSaleStarted;
        emit ChangePublicSaleStarted(_PublicSaleStarted);
        PublicSaleStarted = true;
        emit ChangePublicSaleStarted(true);
        maxCount = 10;
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        return MintPrice;
    } 

function setPreSaleStarted(bool _PreSaleStarted) external onlyOwner {
        PreSaleStarted = _PreSaleStarted;
        emit ChangePreSaleStarted(_PreSaleStarted);
    }

function setPublicSaleStarted(bool _PublicSaleStarted) external onlyOwner {
        PublicSaleStarted = _PublicSaleStarted;
        emit ChangePublicSaleStarted(_PublicSaleStarted);
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit ChangeIsBurnEnabled(_isBurnEnabled);
    }

      function setPrice(uint256 _amount) external onlyOwner {
        MintPrice = _amount * 10000000000000000;
        emit ChangeMintPrice(_amount * 10000000000000000);
    }

    function giftMint(address[] calldata _addresses)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            totalNFT + _addresses.length <= maxTotalSupply,
            "Message: max total supply exceeded"
        );

        require(
            giftCount + _addresses.length <= maxGiftSupply,
            "Message: max gift supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Message: recepient is the null address"
            );
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(_addresses[ind], _newItemId);
            _giftClaimed[_addresses[ind]] = _giftClaimed[_addresses[ind]] + 1;
            _totalClaimed[_addresses[ind]] = _totalClaimed[_addresses[ind]] + 1;
            totalNFT = totalNFT + 1;
            giftCount = giftCount + 1;
        }
    }

    function presaleMint(uint256 _amount) internal {
        require(
           PreSaleStarted == true,
            "You are not on the presale list."
        );
        require(
            _presaleList[msg.sender] == true,
            "You are not on the presale list"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= maxCount,
            "Message: Can only mint 2 tokens"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Message: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Message: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
            presaleCount = presaleCount + 1;
        }
        emit PresaleMint(msg.sender, _amount, _price);
    }

    function saleMint(uint256 _amount) internal {
        require(
           PublicSaleStarted == true,
            "Sale isn't started."
        );
        require(_amount > 0, "Message: zero amount");
        require(
            _amount <= maxCount,
            "Message:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Message: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Message: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
        }
        emit SaleMint(msg.sender, _amount, _price);
    }

    function mainMint(uint256 _amount) external payable whenNotPaused {
        if (PublicSaleStarted == false) {
            presaleMint(_amount);
        } else {
            saleMint(_amount);
        }
        if (totalNFT + _amount == maxTotalSupply) {
            workflow = WorkflowStatus.SoldOut;
            emit WorkflowStatusChange(
                WorkflowStatus.Sale,
                WorkflowStatus.SoldOut
            );
        }
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "Message: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Message: burn caller is not owner"
        );
        _burn(tokenId);
        totalNFT = totalNFT - 1;
    }

    function getWorkflowStatus() public view returns (uint256) {
        uint256 _status;
        if (workflow == WorkflowStatus.CheckOnPresale) {
            _status = 1;
        }
        if (workflow == WorkflowStatus.Presale) {
            _status = 2;
        }
        if (workflow == WorkflowStatus.Sale) {
            _status = 3;
        }
        if (workflow == WorkflowStatus.SoldOut) {
            _status = 4;
        }
        return _status;
    }
}