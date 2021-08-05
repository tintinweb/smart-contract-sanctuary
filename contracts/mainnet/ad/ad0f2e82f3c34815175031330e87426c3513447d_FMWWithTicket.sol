/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
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

    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    
    string private _name;

    
    string private _symbol;

    
    mapping(uint256 => address) private _owners;

    
    mapping(address => uint256) private _balances;

    
    mapping(uint256 => address) private _tokenApprovals;

    
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    
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

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract BOTB {
    function balanceOf(address owner) external view virtual returns (uint256 balance);
}

library Sort {
    struct BidOffer {
        address account;
        uint256 offeredPrice;
    }

    function sort(
        BidOffer[] storage arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].offeredPrice;
        while (i <= j) {
            while (arr[uint256(i)].offeredPrice < pivot) i++;
            while (pivot < arr[uint256(j)].offeredPrice) j--;
            if (i <= j) {
                (arr[uint256(i)].offeredPrice, arr[uint256(j)].offeredPrice) = (
                    arr[uint256(j)].offeredPrice,
                    arr[uint256(i)].offeredPrice
                );
                (arr[uint256(i)].account, arr[uint256(j)].account) = (arr[uint256(j)].account, arr[uint256(i)].account);
                i++;
                j--;
            }
        }
        if (left < j) sort(arr, left, j);
        if (i < right) sort(arr, i, right);
    }
}

contract FMWWithTicket is Ownable, ERC721 {
    BOTB public botb;

    address[] private __payees = [
        address(0xE7c08dBa10Ce07e1b70e87A355957CC8bfc95DBC), 
        address(0x35a409031a548A02737Add2b33b37013b0AE3295), 
        address(0x1c447BD23424903610A2198315831122C99463B9), 
        address(0x04231ce30049ab88a795c3Dd10A15116E83811B7), 
        address(0x4dDd7EC653Fc4814ff11996d7d68b6625e4DFDba), 
        address(0xe6774892A893984F345975f5d4E33C44B460AB30) 
    ];

    uint256[] private __shares = [83270, 4170, 5060, 500, 3500, 3500];

    bool public _tokensLoaded = false;

    
    bool public _isTicketSeason = false;
    bool private _canOpenTicketSeason = true;
    uint256 private _ticketCounter = 0;
    
    bool private _useExternalBotbService = false;

    uint256 private maxTicketsDefaultValue = 8000;

    uint256 private ticketToTokenGap = 2000;
    uint256 private maxTickets = maxTicketsDefaultValue;

    mapping(address => uint256[]) private usersToTickets;
    

    uint256 private totalTokens;
    
    uint256 private _tokenCounter = 0;

    
    string public baseURI;

    constructor() ERC721("FloydsWorld", "FMWNFT") {
        baseURI = "https://floydnft.com/token/";
        botb = BOTB(0x3a8778A58993bA4B941f85684D74750043A4bB5f);
        ownerMint(111);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function setUseExternalBotbService(bool value) public onlyOwner {
        _useExternalBotbService = value;
    }

    uint256 private _ticketPrice = 0.11 ether;

    function openTicketSeason() public onlyOwner {
        require(_canOpenTicketSeason, "Ticket Season can't be open right now");
        _isTicketSeason = true;
        _canOpenTicketSeason = false;
    }

    function setIsTicketSeason(bool value) public onlyOwner {
        _isTicketSeason = value;
    }

    function setTicketPrice(uint256 newPrice) public onlyOwner {
        _ticketPrice = newPrice;
    }

    function closeTicketSeason() public onlyOwner {
        _isTicketSeason = false;
        if (_ticketCounter < maxTickets) {
            maxTickets = _ticketCounter;
        }
        _canOpenTicketSeason = false;
    }

    function resetCanOpenTicketSeason() public onlyOwner {
        _canOpenTicketSeason = true;
        _isTicketSeason = false;
        maxTickets = maxTicketsDefaultValue;
    }

    function buyTickets(uint256 howMany, uint256 bullsOnAccount) external payable {
        uint256 availableBulls = bullsOnAccount;
        uint256 maxTicketsPerAccount = 1;
        if (_useExternalBotbService) {
            availableBulls = botb.balanceOf(msg.sender);
        }
        if (availableBulls < 4) {
            maxTicketsPerAccount = availableBulls;
        } else {
            maxTicketsPerAccount = ((availableBulls * 70) / 100);
            if (((availableBulls * 70) % 100) > 0) {
                maxTicketsPerAccount += 1;
            }
        }
        require(_isTicketSeason, "Ticket Season is not Open");

        require(
            howMany > 0 && howMany <= (maxTicketsPerAccount - usersToTickets[msg.sender].length),
            string("Can't buy less than 1 ticket or exceed your maximum")
        );
        require(
            howMany <= (maxTickets - _ticketCounter),
            string("Can't buy less than 1 ticket or exceed the available ones")
        );
        require(msg.value == howMany * _ticketPrice, "Unmatched Ticket price");
        for (uint64 i = 0; i < howMany; i++) {
            uint256 ticketId = (ticketToTokenGap + _ticketCounter++);
            usersToTickets[msg.sender].push(ticketId);
            _safeMint(msg.sender, ticketId);
        }
    }

    function buyFloyds(uint256 howMany) external payable {
        require(_tokensLoaded, "Tokens not available yet");
        require(msg.value == howMany * 0.15 ether, "Each Floyd costs 0.15 ether");
        require(
            howMany > 0 && howMany < (totalTokens - _tokenCounter),
            string("Can't buy less than 1 token or exceed the available ones")
        );
        for (uint64 i = 0; i < howMany; i++) {
            uint256 tkId = getNextToken();
            _safeMint(msg.sender, tkId);
        }
    }

    function ownerMint(uint256 howMany) public onlyOwner {
        for (uint64 i = 0; i < howMany; i++) {
            uint256 tkId = getNextToken();
            _safeMint(msg.sender, tkId);
        }
    }

    function loadTokens(uint256 howMany) public onlyOwner {
        totalTokens = howMany;
        _tokensLoaded = true;
    }

    function getNextToken() private returns (uint256) {
        if (_tokenCounter == ticketToTokenGap) {
            _tokenCounter += maxTickets;
        }
        return _tokenCounter++;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 arrayLength = __payees.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            payable(__payees[i]).transfer((balance * __shares[i]) / 100000);
        }
        payable(owner()).transfer(balance);
    }

    using Sort for Sort.BidOffer[];

    bool public _isAuctionSeason = false;
    uint256 private _maxTokensToAuction;
    uint256 private _minBiddedValue = 2.5 ether;
    uint256 private _minAllowedValue = 0.15 ether;

    Sort.BidOffer[] private ds;

    function startAuction(uint256 howMany) public onlyOwner {
        _isAuctionSeason = true;
        _maxTokensToAuction = howMany;
    }

    function getHowManyBidsSoFar() public view onlyOwner returns (uint256) {
        return ds.length;
    }

    function bid(uint256 howMany, uint256 offeredPrice) external payable {
        require(_isAuctionSeason, "Auction is not open");
        require(
            msg.value == howMany * offeredPrice,
            "Eth sent needs to match offered price times how many times you want"
        );
        require(
            offeredPrice >= _minAllowedValue && offeredPrice <= _minBiddedValue,
            "Offered value must be between 0.15 and 2.5 Eth"
        );
        require(howMany > 0, string("Can't bid less than 1 token"));

        for (uint256 i = 0; i < howMany; i++) {
            Sort.BidOffer memory bo = Sort.BidOffer(msg.sender, offeredPrice);
            ds.push(bo);
        }
    }

    function getCurrentMinValue() public onlyOwner returns (uint256) {
        ds.sort(0, int256(ds.length - 1)); 
        uint256 startIndex = 0;
        if (ds.length > _maxTokensToAuction) {
            startIndex = ds.length - _maxTokensToAuction;
        }
        uint256 minValue = ds[startIndex].offeredPrice;
        return uint256(minValue);
    }

    function closeAuction() public onlyOwner {
        _isAuctionSeason = false;
        ds.sort(0, int256(ds.length - 1));
        uint256 startIndex = 0;
        if (ds.length > _maxTokensToAuction) {
            startIndex = ds.length - _maxTokensToAuction;
            for (uint256 i = 0; i < startIndex; i++) {
                refund(ds[i].account, ds[i].offeredPrice);
            }
        }
        uint256 minValue = ds[startIndex].offeredPrice;
        for (uint256 i = startIndex; i < ds.length; i++) {
            uint256 tkId = getNextToken();
            _safeMint(ds[i].account, tkId);
            refund(ds[i].account, ds[i].offeredPrice - minValue);
        }
    }

    function refund(address to, uint256 amount) private {
        payable(to).transfer(amount);
    }
}